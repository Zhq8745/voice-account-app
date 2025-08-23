//
//  CloudSyncService.swift
//  AiVC
//
//  Created by AI Assistant on 2024/01/21.
//

import Foundation
import CloudKit
import SwiftData
import Combine

@MainActor
class CloudSyncService: ObservableObject {
    static let shared = CloudSyncService()
    
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var errorMessage: String?
    
    private let container: CKContainer
    private let database: CKDatabase
    private var cancellables = Set<AnyCancellable>()
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case failed(Error)
    }
    
    private init() {
        self.container = CKContainer(identifier: "iCloud.com.aivc.expense-tracker")
        self.database = container.privateCloudDatabase
        
        setupNotifications()
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
    
    // MARK: - Utility
    func clearSyncStatus() {
        syncStatus = .idle
        errorMessage = nil
    }
}