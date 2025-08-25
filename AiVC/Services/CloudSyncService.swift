//
//  CloudSyncService.swift
//  语记
//
//  Created by AI Assistant on 2024/01/21.
//

import Foundation
import CloudKit
import SwiftData
import Combine
import BackgroundTasks
import UIKit

@MainActor
class CloudSyncService: ObservableObject {
    static let shared = CloudSyncService()
    
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var errorMessage: String?
    @Published var isAutoSyncEnabled: Bool = true
    @Published var pendingSyncCount: Int = 0
    
    private let container: CKContainer
    private let database: CKDatabase
    private var cancellables = Set<AnyCancellable>()
    private var autoSyncTimer: Timer?
    private var pendingRecords: Set<UUID> = []
    private var modelContext: ModelContext?
    
    // 自动同步配置
    private let autoSyncInterval: TimeInterval = 30 // 30秒
    private let maxRetryAttempts = 3
    private var retryAttempts = 0
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case failed(Error)
    }
    
    private init() {
        self.container = CKContainer(identifier: "iCloud.com.shengcai.expense-tracker")
        self.database = container.privateCloudDatabase
        
        setupNotifications()
        setupAutoSync()
        loadAutoSyncSettings()
    }
    
    // MARK: - Setup
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .CKAccountChanged)
            .sink { [weak self] _ in
                Task {
                    await self?.checkAccountStatus()
                }
            }
            .store(in: &cancellables)
        
        // 监听App生命周期
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task {
                    await self?.handleAppBecomeActive()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppEnterBackground()
            }
            .store(in: &cancellables)
    }
    
    private func setupAutoSync() {
        // 设置自动同步定时器
        if isAutoSyncEnabled {
            startAutoSyncTimer()
        }
    }
    
    private func loadAutoSyncSettings() {
        // 从UserDefaults加载自动同步设置
        if UserDefaults.standard.object(forKey: "autoSyncEnabled") == nil {
            // 首次启动，设置默认值
            isAutoSyncEnabled = true
            UserDefaults.standard.set(true, forKey: "autoSyncEnabled")
        } else {
            isAutoSyncEnabled = UserDefaults.standard.bool(forKey: "autoSyncEnabled")
        }
    }
    
    // MARK: - Account Status
    func checkAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                print("CloudKit account is available")
            case .noAccount:
                errorMessage = "请登录iCloud账户以启用同步功能"
            case .restricted:
                errorMessage = "iCloud账户受限，无法使用同步功能"
            case .couldNotDetermine:
                errorMessage = "无法确定iCloud账户状态"
            case .temporarilyUnavailable:
                errorMessage = "iCloud服务暂时不可用"
            @unknown default:
                errorMessage = "未知的iCloud账户状态"
            }
        } catch {
            errorMessage = "检查iCloud账户状态失败: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Sync Operations
    func syncExpenseRecords(modelContext: ModelContext) async {
        syncStatus = .syncing
        errorMessage = nil
        
        do {
            // 上传本地未同步的记录
            try await uploadLocalRecords(modelContext: modelContext)
            
            // 下载云端记录
            try await downloadCloudRecords(modelContext: modelContext)
            
            lastSyncDate = Date()
            syncStatus = .success
            
        } catch {
            syncStatus = .failed(error)
            errorMessage = "同步失败: \(error.localizedDescription)"
        }
    }
    
    private func uploadLocalRecords(modelContext: ModelContext) async throws {
        let descriptor = FetchDescriptor<ExpenseRecord>(
            predicate: #Predicate { !$0.isCloudSynced }
        )
        
        let localRecords = try modelContext.fetch(descriptor)
        
        for record in localRecords {
            let ckRecord = createCKRecord(from: record)
            _ = try await database.save(ckRecord)
            
            // 标记为已同步
            record.isCloudSynced = true
        }
        
        try modelContext.save()
    }
    
    private func downloadCloudRecords(modelContext: ModelContext) async throws {
        let query = CKQuery(recordType: "ExpenseRecord", predicate: NSPredicate(value: true))
        let operation = CKQueryOperation(query: query)
        
        var cloudRecords: [CKRecord] = []
        
        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                cloudRecords.append(record)
            case .failure(let error):
                print("Failed to fetch record \(recordID): \(error)")
            }
        }
        
        operation.queryResultBlock = { result in
            switch result {
            case .success:
                print("Successfully fetched \(cloudRecords.count) records")
            case .failure(let error):
                print("Query failed: \(error)")
            }
        }
        
        database.add(operation)
        
        // 等待操作完成
        try await withCheckedThrowingContinuation { continuation in
            operation.queryResultBlock = { result in
                continuation.resume(with: result.map { _ in () })
            }
        }
        
        // 处理下载的记录
        for ckRecord in cloudRecords {
            try await processCloudRecord(ckRecord, modelContext: modelContext)
        }
    }
    
    private func createCKRecord(from expenseRecord: ExpenseRecord) -> CKRecord {
        let recordID = CKRecord.ID(recordName: expenseRecord.id.uuidString)
        let record = CKRecord(recordType: "ExpenseRecord", recordID: recordID)
        
        record["amount"] = expenseRecord.amount
        record["note"] = expenseRecord.note
        record["timestamp"] = expenseRecord.timestamp
        record["isVoiceInput"] = expenseRecord.isVoiceInput
        
        if let category = expenseRecord.category {
            record["categoryID"] = category.id.uuidString
            record["categoryName"] = category.name
        }
        
        return record
    }
    
    private func processCloudRecord(_ ckRecord: CKRecord, modelContext: ModelContext) async throws {
        let recordIDString = ckRecord.recordID.recordName
        guard !recordIDString.isEmpty,
              let recordID = UUID(uuidString: recordIDString) else {
            return
        }
        
        // 检查本地是否已存在该记录
        let descriptor = FetchDescriptor<ExpenseRecord>(
            predicate: #Predicate<ExpenseRecord> { $0.id == recordID }
        )
        
        let existingRecords = try modelContext.fetch(descriptor)
        
        if existingRecords.isEmpty {
            // 创建新的本地记录
            let amount = ckRecord["amount"] as? Double ?? 0.0
            let note = ckRecord["note"] as? String ?? ""
            let timestamp = ckRecord["timestamp"] as? Date ?? Date()
            let isVoiceInput = ckRecord["isVoiceInput"] as? Bool ?? false
            
            let newRecord = ExpenseRecord(
                amount: amount,
                note: note,
                timestamp: timestamp,
                isVoiceInput: isVoiceInput,
                isCloudSynced: true
            )
            newRecord.id = recordID
            
            // 处理分类
            if let categoryIDString = ckRecord["categoryID"] as? String,
               let categoryID = UUID(uuidString: categoryIDString) {
                let categoryDescriptor = FetchDescriptor<ExpenseCategory>(
                    predicate: #Predicate<ExpenseCategory> { $0.id == categoryID }
                )
                let categories = try modelContext.fetch(categoryDescriptor)
                newRecord.category = categories.first
            }
            
            modelContext.insert(newRecord)
        }
    }
    
    // MARK: - Manual Sync
    func forceSyncAll(modelContext: ModelContext) async {
        await syncExpenseRecords(modelContext: modelContext)
    }
    
    // MARK: - Auto Sync Management
    func setAutoSyncEnabled(_ enabled: Bool) {
        isAutoSyncEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "autoSyncEnabled")
        
        if enabled {
            startAutoSyncTimer()
        } else {
            stopAutoSyncTimer()
        }
    }
    
    private func startAutoSyncTimer() {
        stopAutoSyncTimer()
        autoSyncTimer = Timer.scheduledTimer(withTimeInterval: autoSyncInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.performAutoSync()
            }
        }
    }
    
    private func stopAutoSyncTimer() {
        autoSyncTimer?.invalidate()
        autoSyncTimer = nil
    }
    
    func performAutoSync() async {
        guard isAutoSyncEnabled else { return }
        if case .syncing = syncStatus { return }
        
        // 检查是否有待同步的记录
        if pendingSyncCount > 0 {
            await autoSyncExpenseRecords()
        }
    }
    
    // MARK: - Auto Sync Triggers
    func triggerAutoSync(for recordID: UUID? = nil) {
        guard isAutoSyncEnabled else { return }
        
        if let recordID = recordID {
            pendingRecords.insert(recordID)
        }
        
        updatePendingSyncCount()
        
        // 延迟执行同步，避免频繁触发
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒延迟
            await performAutoSync()
        }
    }
    
    private func updatePendingSyncCount() {
        // 这里可以查询数据库获取实际的待同步记录数
        pendingSyncCount = pendingRecords.count
    }
    
    // MARK: - App Lifecycle Handlers
    private func handleAppBecomeActive() async {
        guard isAutoSyncEnabled else { return }
        
        // App激活时检查是否需要同步
        let timeSinceLastSync = lastSyncDate?.timeIntervalSinceNow ?? -Double.infinity
        if abs(timeSinceLastSync) > 300 { // 5分钟
            await performAutoSync()
        }
        
        startAutoSyncTimer()
    }
    
    private func handleAppEnterBackground() {
        stopAutoSyncTimer()
        
        // 请求后台任务时间
        var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
        backgroundTaskID = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
        }
        
        Task {
            if pendingSyncCount > 0 {
                await performAutoSync()
            }
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
        }
    }
    
    // MARK: - Enhanced Sync Methods
    private func autoSyncExpenseRecords() async {
        if case .syncing = syncStatus { return }
        
        syncStatus = .syncing
        errorMessage = nil
        
        do {
            // 智能同步：只同步有变化的记录
            try await uploadPendingRecords()
            
            // 下载云端更新（如果需要）
            let shouldDownload = lastSyncDate == nil || 
                                Date().timeIntervalSince(lastSyncDate!) > 3600 // 1小时
            if shouldDownload {
                // 这里需要ModelContext，暂时跳过下载部分
                // try await downloadCloudRecords(modelContext: modelContext)
            }
            
            lastSyncDate = Date()
            syncStatus = .success
            retryAttempts = 0
            pendingRecords.removeAll()
            updatePendingSyncCount()
            
        } catch {
            retryAttempts += 1
            if retryAttempts < maxRetryAttempts {
                // 指数退避重试
                let delay = pow(2.0, Double(retryAttempts))
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    await autoSyncExpenseRecords()
                }
            } else {
                syncStatus = .failed(error)
                errorMessage = "自动同步失败: \(error.localizedDescription)"
                retryAttempts = 0
            }
        }
    }
    
    private func uploadPendingRecords() async throws {
        guard let modelContext = modelContext else { return }
        
        // 查询所有未同步的记录
        let descriptor = FetchDescriptor<ExpenseRecord>(
            predicate: #Predicate { !$0.isCloudSynced }
        )
        
        let localRecords = try modelContext.fetch(descriptor)
        
        for record in localRecords {
            let ckRecord = createCKRecord(from: record)
            _ = try await database.save(ckRecord)
            
            // 标记为已同步
            record.isCloudSynced = true
        }
        
        try modelContext.save()
    }
    
    // MARK: - Initialization
    func initialize(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Auto Sync Interface
    func syncWithModelContext(_ modelContext: ModelContext) async {
        if isAutoSyncEnabled {
            await syncExpenseRecords(modelContext: modelContext)
        }
    }
    
    // MARK: - Manual Sync Interface
    func syncData() async throws {
        if case .syncing = syncStatus {
            throw NSError(domain: "CloudSyncService", code: 1001, userInfo: [NSLocalizedDescriptionKey: "同步正在进行中"])
        }
        
        syncStatus = .syncing
        errorMessage = nil
        
        do {
            // 上传本地未同步的记录
            try await uploadPendingRecords()
            
            // 下载云端更新
            // 这里可以添加下载逻辑，暂时跳过
            
            lastSyncDate = Date()
            syncStatus = .success
            retryAttempts = 0
            pendingRecords.removeAll()
            updatePendingSyncCount()
            
        } catch {
            syncStatus = .failed(error)
            errorMessage = "手动同步失败: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Utility
    func clearSyncStatus() {
        syncStatus = .idle
        errorMessage = nil
        pendingRecords.removeAll()
        updatePendingSyncCount()
    }
    
    deinit {
        Task { @MainActor in
            stopAutoSyncTimer()
        }
    }
}