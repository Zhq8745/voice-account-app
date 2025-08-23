//
//  AiVCApp.swift
//  AiVC
//
//  Created by 1234 on 2025/8/21.
//

import SwiftUI
import SwiftData

@main
struct AiVCApp: App {
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
            ContentView()
                .onAppear {
                    setupDefaultData()
                }
        }
        .modelContainer(sharedModelContainer)
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
}
