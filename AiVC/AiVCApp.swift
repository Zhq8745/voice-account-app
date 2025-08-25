//
//  AiVCApp.swift
//  AiVC
//
//  Created by 1234 on 2025/8/21.
//

import SwiftUI
import SwiftData
import Foundation
import Combine

@main
struct AiVCApp: App {
    @StateObject private var authManager = AuthenticationManager.shared
    private let cloudSyncService = CloudSyncService.shared
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ExpenseRecord.self,
            ExpenseCategory.self,
            AppSettings.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    ContentView()
                        .onAppear {
                            setupDefaultData()
                            setupCloudSync()
                        }
                } else {
                    LoginView()
                }
            }
            .onAppear {
                authManager.checkAuthenticationStatus()
            }
        }
        .modelContainer(sharedModelContainer)
        .environmentObject(AuthenticationManager.shared)
    }
    
    // 设置默认数据
    private func setupDefaultData() {
        let context = sharedModelContainer.mainContext
        
        // 检查是否已有默认分类
        let categoryFetch = FetchDescriptor<ExpenseCategory>()
        let existingCategories = try? context.fetch(categoryFetch)
        
        if existingCategories?.isEmpty == true {
            // 添加默认分类
            for defaultCategory in ExpenseCategory.defaultCategories {
                context.insert(defaultCategory)
            }
            
            try? context.save()
        }
        
        // 检查是否已有设置
        let settingsFetch = FetchDescriptor<AppSettings>()
        let existingSettings = try? context.fetch(settingsFetch)
        
        if existingSettings?.isEmpty == true {
            // 添加默认设置
            let defaultSettings = AppSettings()
            context.insert(defaultSettings)
            
            try? context.save()
        }
    }
    
    // 设置云同步
    private func setupCloudSync() {
        // 初始化云同步服务
        cloudSyncService.initialize(with: sharedModelContainer.mainContext)
        
        // App启动时触发一次自动同步
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Task {
                await cloudSyncService.performAutoSync()
            }
        }
    }
}
