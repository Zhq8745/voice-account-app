//
//  MockDataService.swift
//  AiVC
//
//  Created by AI Assistant
//

import Foundation
import SwiftData

// 模拟数据服务
class MockDataService {
    
    // 创建模拟的支出记录
    static func createMockExpenseRecords(with categories: [ExpenseCategory]) -> [ExpenseRecord] {
        let calendar = Calendar.current
        let now = Date()
        
        var records: [ExpenseRecord] = []
        
        // 今天的记录
        let todayRecords = [
            ExpenseRecord(amount: 25.50, category: categories.first { $0.name == "餐饮" }, note: "午餐", timestamp: calendar.date(byAdding: .hour, value: -2, to: now) ?? now, isVoiceInput: true),
            ExpenseRecord(amount: 12.00, category: categories.first { $0.name == "交通" }, note: "地铁", timestamp: calendar.date(byAdding: .hour, value: -4, to: now) ?? now, isVoiceInput: false),
            ExpenseRecord(amount: 8.50, category: categories.first { $0.name == "餐饮" }, note: "咖啡", timestamp: calendar.date(byAdding: .hour, value: -6, to: now) ?? now, isVoiceInput: true)
        ]
        records.append(contentsOf: todayRecords)
        
        // 昨天的记录
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let yesterdayRecords = [
            ExpenseRecord(amount: 89.00, category: categories.first { $0.name == "购物" }, note: "超市购物", timestamp: calendar.date(bySettingHour: 19, minute: 30, second: 0, of: yesterday) ?? yesterday, isVoiceInput: false),
            ExpenseRecord(amount: 35.00, category: categories.first { $0.name == "餐饮" }, note: "晚餐", timestamp: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: yesterday) ?? yesterday, isVoiceInput: true),
            ExpenseRecord(amount: 15.00, category: categories.first { $0.name == "交通" }, note: "打车", timestamp: calendar.date(bySettingHour: 14, minute: 20, second: 0, of: yesterday) ?? yesterday, isVoiceInput: false)
        ]
        records.append(contentsOf: yesterdayRecords)
        
        // 本周的其他记录
        for i in 2...6 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let dayRecords = [
                ExpenseRecord(amount: Double.random(in: 20...80), category: categories.randomElement(), note: "随机支出\(i)", timestamp: calendar.date(bySettingHour: Int.random(in: 9...20), minute: Int.random(in: 0...59), second: 0, of: date) ?? date, isVoiceInput: Bool.random()),
                ExpenseRecord(amount: Double.random(in: 10...50), category: categories.randomElement(), note: "日常消费", timestamp: calendar.date(bySettingHour: Int.random(in: 9...20), minute: Int.random(in: 0...59), second: 0, of: date) ?? date, isVoiceInput: Bool.random())
            ]
            records.append(contentsOf: dayRecords)
        }
        
        // 上个月的记录
        for i in 7...30 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let record = ExpenseRecord(
                amount: Double.random(in: 15...120),
                category: categories.randomElement(),
                note: "历史记录\(i)",
                timestamp: calendar.date(bySettingHour: Int.random(in: 8...22), minute: Int.random(in: 0...59), second: 0, of: date) ?? date,
                isVoiceInput: Bool.random()
            )
            records.append(record)
        }
        
        return records
    }
    
    // 创建默认设置
    static func createDefaultSettings() -> AppSettings {
        return AppSettings(
            currency: "CNY",
            reminderEnabled: true,
            reminderTime: Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date(),
            themeMode: "dark"
        )
    }
    
    // 初始化模拟数据
    static func initializeMockData(modelContext: ModelContext) {
        // 检查是否已有数据
        let descriptor = FetchDescriptor<ExpenseCategory>()
        let existingCategories = try? modelContext.fetch(descriptor)
        
        if existingCategories?.isEmpty ?? true {
            // 添加默认分类
            for category in ExpenseCategory.defaultCategories {
                modelContext.insert(category)
            }
            
            // 保存分类
            try? modelContext.save()
            
            // 获取保存后的分类
            let savedCategories = try? modelContext.fetch(descriptor)
            
            // 添加模拟记录
            if let categories = savedCategories {
                let mockRecords = createMockExpenseRecords(with: categories)
                for record in mockRecords {
                    modelContext.insert(record)
                }
            }
            
            // 添加默认设置
            let settings = createDefaultSettings()
            modelContext.insert(settings)
            
            // 保存所有数据
            try? modelContext.save()
        }
    }
    
    // 获取统计数据
    static func getStatisticsData(records: [ExpenseRecord]) -> StatisticsData {
        let calendar = Calendar.current
        let now = Date()
        
        // 本月数据
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let monthlyRecords = records.filter { $0.timestamp >= startOfMonth }
        let monthlyTotal = monthlyRecords.reduce(0) { $0 + $1.amount }
        
        // 今日数据
        let startOfDay = calendar.startOfDay(for: now)
        let dailyRecords = records.filter { $0.timestamp >= startOfDay }
        let dailyTotal = dailyRecords.reduce(0) { $0 + $1.amount }
        
        // 分类统计
        var categoryStats: [CategoryStatistic] = []
        let groupedByCategory = Dictionary(grouping: monthlyRecords) { $0.category?.name ?? "其他" }
        
        for (categoryName, categoryRecords) in groupedByCategory {
            let total = categoryRecords.reduce(0) { $0 + $1.amount }
            let percentage = monthlyTotal > 0 ? (total / monthlyTotal) * 100 : 0
            categoryStats.append(CategoryStatistic(
                name: categoryName,
                amount: total,
                percentage: percentage,
                color: categoryRecords.first?.category?.color ?? .gray
            ))
        }
        
        categoryStats.sort { $0.amount > $1.amount }
        
        // 趋势数据（最近7天）
        var trendData: [DailyExpense] = []
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
            
            let dayRecords = records.filter { $0.timestamp >= dayStart && $0.timestamp < dayEnd }
            let dayTotal = dayRecords.reduce(0) { $0 + $1.amount }
            
            trendData.append(DailyExpense(date: date, amount: dayTotal))
        }
        
        trendData.reverse() // 按时间正序排列
        
        return StatisticsData(
            monthlyTotal: monthlyTotal,
            dailyTotal: dailyTotal,
            recordCount: monthlyRecords.count,
            averageDaily: monthlyTotal / Double(calendar.component(.day, from: now)),
            categoryStats: categoryStats,
            trendData: trendData
        )
    }
}

// 统计数据结构
struct StatisticsData {
    let monthlyTotal: Double
    let dailyTotal: Double
    let recordCount: Int
    let averageDaily: Double
    let categoryStats: [CategoryStatistic]
    let trendData: [DailyExpense]
}

// 分类统计
struct CategoryStatistic: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let percentage: Double
    let color: Color
}

// 日支出数据
struct DailyExpense: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

import SwiftUI