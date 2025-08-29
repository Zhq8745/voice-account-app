//
//  EditRecordView.swift
//  AiVC
//
//  Created by AI Assistant on 2024/01/01.
//

import SwiftUI
import SwiftData

struct EditRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [ExpenseCategory]
    
    let record: ExpenseRecord
    private let cloudSyncService = CloudSyncService.shared
    
    @State private var amount: String = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var note: String = ""
    @State private var recordDate: Date = Date()
    @State private var showingCategoryPicker = false
    
    var body: some View {
        ZStack {
            // 背景
            Color.black
                .ignoresSafeArea()
            
            NavigationView {
                VStack(spacing: 0) {
                    // 顶部标题栏
                    HStack {
                        Button("取消") {
                            dismiss()
                        }
                        .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Text("编辑记录")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("保存") {
                            saveRecord()
                        }
                        .foregroundColor(.blue)
                        .disabled(!isValidInput)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .frame(height: 0.5)
                            .foregroundColor(Color(.systemGray6).opacity(0.3))
                            .offset(y: 15)
                    )
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 金额输入
                        VStack(alignment: .leading, spacing: 12) {
                            Text("支出金额")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text("¥")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                TextField("0.00", text: $amount)
                                    .font(.system(size: 20, weight: .medium))
                                    .keyboardType(.decimalPad)
                            }
                            .modifier(ThemeCard(variant: .primary))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        
                        // 分类选择
                        VStack(alignment: .leading, spacing: 12) {
                            Text("支出分类")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            Button(action: {
                                showingCategoryPicker = true
                            }) {
                                HStack {
                                    if let category = selectedCategory {
                                        Text(category.iconName)
                                            .font(.system(size: 20))
                                        Text(category.name)
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                    } else {
                                        Text("选择分类")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .modifier(ThemeCard(variant: .primary))
                        .padding(.horizontal, 20)
                        
                        // 记录时间
                        VStack(alignment: .leading, spacing: 12) {
                            Text("记录时间")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            DatePicker(
                                "",
                                selection: $recordDate,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .colorScheme(.dark)
                        }
                        .modifier(ThemeCard(variant: .primary))
                        .padding(.horizontal, 20)
                        
                        // 备注输入
                        VStack(alignment: .leading, spacing: 12) {
                            Text("备注信息")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            TextField("添加备注（可选）", text: $note, axis: .vertical)
                                .font(.system(size: 16))
                                .lineLimit(3...6)
                                .foregroundColor(.white)
                        }
                        .modifier(ThemeCard(variant: .primary))
                        .padding(.horizontal, 20)
                        
                        // 输入方式显示
                        VStack(alignment: .leading, spacing: 12) {
                            Text("输入方式")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            HStack {
                                Image(systemName: record.isVoiceInput ? "mic.fill" : "keyboard.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.blue)
                                
                                Text(record.isVoiceInput ? "语音输入" : "手动输入")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Spacer()
                            }
                        }
                        .modifier(ThemeCard(variant: .primary))
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
                }
                .background(Color.black)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showingCategoryPicker) {
            EditCategoryPickerView(selectedCategory: $selectedCategory, categories: Array(categories))
        }
        .onAppear {
            // 初始化数据
            amount = String(format: "%.2f", record.amount)
            selectedCategory = record.category
            note = record.note
            recordDate = record.timestamp
        }
    }
    
    private var isValidInput: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else {
            return false
        }
        return selectedCategory != nil
    }
    
    private func saveRecord() {
        guard let amountValue = Double(amount),
              let category = selectedCategory else {
            return
        }
        
        // 更新记录信息
        record.amount = amountValue
        record.category = category
        record.note = note.trimmingCharacters(in: .whitespaces)
        record.timestamp = recordDate
        
        do {
            try modelContext.save()
            // 触发自动同步
            cloudSyncService.triggerAutoSync(for: record.id)
            dismiss()
        } catch {
            print("更新记录失败: \(error)")
        }
    }
}

// 编辑用分类选择器视图
struct EditCategoryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCategory: ExpenseCategory?
    let categories: [ExpenseCategory]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部标题栏
                HStack {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("选择分类")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("确定") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6).opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color(.systemGray6).opacity(0.3))
                        .offset(y: 15)
                )
                
                if categories.isEmpty {
                    // 空状态
                    VStack(spacing: 16) {
                        Image(systemName: "folder")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("暂无分类")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("请先在设置中添加支出分类")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 分类列表
                    List {
                        ForEach(categories) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                HStack(spacing: 12) {
                                    Text(category.iconName)
                                        .font(.system(size: 24))
                                    
                                    Text(category.name)
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if selectedCategory?.id == category.id {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .background(Color.black)
        }
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
    
    EditRecordView(record: record)
        .modelContainer(for: [ExpenseRecord.self, ExpenseCategory.self], inMemory: true)
}