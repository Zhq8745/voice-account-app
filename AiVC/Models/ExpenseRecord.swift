//
//  ExpenseRecord.swift
//  AiVC
//
//  Created by AI Assistant
//

import Foundation
import SwiftData
import CloudKit

@Model
class ExpenseRecord {
    var id: UUID = UUID()
    var amount: Double = 0.0
    var note: String = ""
    var timestamp: Date = Date()
    var isVoiceInput: Bool = false
    var isCloudSynced: Bool = false
    var category: ExpenseCategory?
    
    init(amount: Double, category: ExpenseCategory? = nil, note: String = "", timestamp: Date = Date(), isVoiceInput: Bool = false, isCloudSynced: Bool = false) {
        self.id = UUID()
        self.amount = amount
        self.category = category
        self.note = note
        self.timestamp = timestamp
        self.isVoiceInput = isVoiceInput
        self.isCloudSynced = isCloudSynced
    }
    
    // 格式化金额显示
    var formattedAmount: String {
        return String(format: "%.2f", amount)
    }
    
    // 格式化时间显示
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
    
    // 格式化日期显示
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: timestamp)
    }
}