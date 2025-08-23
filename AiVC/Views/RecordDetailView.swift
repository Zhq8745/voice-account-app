//
//  RecordDetailView.swift
//  AiVC
//
//  Created by AI Assistant on 2024/01/01.
//

import SwiftUI
import SwiftData

struct RecordDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let record: ExpenseRecord
    
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部标题栏
                HStack {
                    Button("返回") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("记录详情")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("编辑") {
                        showingEditView = true
                    }
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color.gray.opacity(0.3))
                        .offset(y: 15)
                )
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 金额显示
                        VStack(spacing: 16) {
                            Text("支出金额")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text("¥\(String(format: "%.2f", record.amount))")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        
                        // 详细信息卡片
                        VStack(spacing: 0) {
                            // 分类信息
                            DetailRowView(
                                icon: "tag.fill",
                                title: "分类",
                                content: "\(record.category?.iconName ?? "📝") \(record.category?.name ?? "未分类")"
                            )
                            
                            Divider()
                                .padding(.leading, 52)
                            
                            // 记录时间
                            DetailRowView(
                                icon: "clock.fill",
                                title: "时间",
                                content: formatDateTime(record.timestamp)
                            )
                            
                            Divider()
                                .padding(.leading, 52)
                            
                            // 输入方式
                            DetailRowView(
                                icon: record.isVoiceInput ? "mic.fill" : "keyboard.fill",
                                title: "输入方式",
                                content: record.isVoiceInput ? "语音输入" : "手动输入"
                            )
                            
                            if !record.note.isEmpty {
                                Divider()
                                    .padding(.leading, 52)
                                
                                // 备注信息
                                DetailRowView(
                                    icon: "note.text",
                                    title: "备注",
                                    content: record.note
                                )
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                        .padding(.horizontal, 20)
                        
                        // 操作按钮
                        VStack(spacing: 12) {
                            Button(action: {
                                showingEditView = true
                            }) {
                                HStack {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("编辑记录")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue)
                                )
                            }
                            
                            Button(action: {
                                showingDeleteAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("删除记录")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.1))
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .background(Color.gray.opacity(0.1))
        }
        .sheet(isPresented: $showingEditView) {
            // EditRecordView(record: record)
            Text("编辑功能开发中")
                .padding()
        }
        .alert("删除记录", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteRecord()
            }
        } message: {
            Text("确定要删除这条记录吗？此操作无法撤销。")
        }
    }
    
    private func deleteRecord() {
        modelContext.delete(record)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("删除记录失败: \(error)")
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: date)
    }
}

// 详情行视图组件
struct DetailRowView: View {
    let icon: String
    let title: String
    let content: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(content)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview {
    let category = ExpenseCategory(name: "餐饮", iconName: "fork.knife", colorHex: "#FF6B6B")
    let record = ExpenseRecord(
        amount: 25.50,
        category: category,
        note: "午餐 - 麦当劳",
        timestamp: Date(),
        isVoiceInput: true
    )
    
    RecordDetailView(record: record)
        .modelContainer(for: [ExpenseRecord.self, ExpenseCategory.self], inMemory: true)
}