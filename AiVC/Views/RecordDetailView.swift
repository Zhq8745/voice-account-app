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
        ZStack {
            // 纯色背景
            Color.black
                .ignoresSafeArea()
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            // 检测右滑手势
                            if value.translation.width > 100 && abs(value.translation.height) < 50 {
                                dismiss()
                            }
                        }
                )
            
            ScrollView {
                VStack(spacing: 24) {
                        // 金额显示
                        VStack(spacing: 16) {
                            Text("支出金额")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("¥\(String(format: "%.2f", record.amount))")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .modifier(ThemeCard(variant: .primary))
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
                        .modifier(ThemeCard(variant: .primary))
                        .padding(.horizontal, 20)
                        
                        // 操作按钮
                        HStack(spacing: 16) {
                            Button(action: {
                                showingEditView = true
                            }) {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text("编辑")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .cornerRadius(12)
                                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: 0.1), value: showingEditView)
                            
                            Button(action: {
                                showingDeleteAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("删除")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.red)
                                .cornerRadius(12)
                                .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: 0.1), value: showingDeleteAlert)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        
                        Spacer(minLength: 100)
                    }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6).opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("返回")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("记录详情")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("编辑") {
                    showingEditView = true
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .preferredColorScheme(.dark)
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
                .foregroundColor(.blue.opacity(0.8))
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(content)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
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