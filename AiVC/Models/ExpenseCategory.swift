//
//  ExpenseCategory.swift
//  AiVC
//
//  Created by AI Assistant
//

import Foundation
import SwiftData
import SwiftUI
import CloudKit

@Model
class ExpenseCategory {
    var id: UUID = UUID()
    var name: String = ""
    var iconName: String = ""
    var colorHex: String = "#A8A8A8"
    var isDefault: Bool = false
    var isCloudSynced: Bool = false
    
    // 反向关系：一个分类可以有多个支出记录
    @Relationship(deleteRule: .nullify, inverse: \ExpenseRecord.category)
    var expenseRecords: [ExpenseRecord]?
    
    init(name: String, iconName: String, colorHex: String, isDefault: Bool = false, isCloudSynced: Bool = false) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.isDefault = isDefault
        self.isCloudSynced = isCloudSynced
    }
    
    // 获取颜色对象
    var color: Color {
        return Color(hex: colorHex) ?? .blue
    }
    
    // 默认分类数据
    static let defaultCategories: [ExpenseCategory] = [
        ExpenseCategory(name: "餐饮", iconName: "fork.knife", colorHex: "#FF6B6B", isDefault: true),
        ExpenseCategory(name: "交通", iconName: "car.fill", colorHex: "#4ECDC4", isDefault: true),
        ExpenseCategory(name: "购物", iconName: "bag.fill", colorHex: "#45B7D1", isDefault: true),
        ExpenseCategory(name: "娱乐", iconName: "gamecontroller.fill", colorHex: "#96CEB4", isDefault: true),
        ExpenseCategory(name: "医疗", iconName: "cross.case.fill", colorHex: "#FFEAA7", isDefault: true),
        ExpenseCategory(name: "教育", iconName: "book.fill", colorHex: "#DDA0DD", isDefault: true),
        ExpenseCategory(name: "住房", iconName: "house.fill", colorHex: "#98D8C8", isDefault: true),
        ExpenseCategory(name: "其他", iconName: "ellipsis.circle.fill", colorHex: "#A8A8A8", isDefault: true)
    ]
}

// Color扩展，支持十六进制颜色
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}