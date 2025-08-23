//
//  AppSettings.swift
//  AiVC
//
//  Created by AI Assistant
//

import Foundation
import SwiftData

@Model
class AppSettings {
    var id: UUID = UUID()
    var currency: String = "CNY"
    var reminderEnabled: Bool = true
    var reminderTime: Date = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
    var themeMode: String = "system"
    
    init(currency: String = "CNY", reminderEnabled: Bool = true, reminderTime: Date = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date(), themeMode: String = "system") {
        self.id = UUID()
        self.currency = currency
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.themeMode = themeMode
    }
    
    // 货币符号
    var currencySymbol: String {
        switch currency {
        case "CNY":
            return "¥"
        case "USD":
            return "$"
        case "EUR":
            return "€"
        case "JPY":
            return "¥"
        case "GBP":
            return "£"
        default:
            return "¥"
        }
    }
    
    // 格式化提醒时间
    var formattedReminderTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: reminderTime)
    }
    
    // 主题模式选项
    static let themeModes = ["system", "light", "dark"]
    
    // 货币选项
    static let currencies = [
        ("CNY", "人民币", "¥"),
        ("USD", "美元", "$"),
        ("EUR", "欧元", "€"),
        ("JPY", "日元", "¥"),
        ("GBP", "英镑", "£")
    ]
}