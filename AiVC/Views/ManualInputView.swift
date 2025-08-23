//
//  ManualInputView.swift
//  AiVC
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct ManualInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [ExpenseCategory]
    @Query private var settings: [AppSettings]
    
    @State private var amount: String = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var note: String = ""
    @State private var selectedDate = Date()
    @State private var showingCategoryPicker = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private var currentSettings: AppSettings {
        settings.first ?? AppSettings()
    }
    
    private var isValidInput: Bool {
        !amount.isEmpty && Double(amount) != nil && Double(amount)! > 0
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 金额输入区域
                        amountInputSection
                        
                        // 分类选择区域
                        categorySelectionSection
                        
                        // 备注输入区域
                        noteInputSection
                        
                        // 日期选择区域
                        dateSelectionSection
                        
                        Spacer(minLength: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("手动记账")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveExpense()
                    }
                    .foregroundColor(isValidInput ? .blue : .gray)
                    .disabled(!isValidInput)
                }
            }
        }
        .alert("错误", isPresented: $showingError) {
            Button("确定") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            selectedCategory = categories.first
        }
    }
    
    // 金额输入区域
    private var amountInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("金额")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                Text(currentSettings.currencySymbol)
                    .font(.title2)
                    .foregroundColor(.gray)
                
                TextField("0.00", text: $amount)
                    .font(.title)
                    .foregroundColor(.white)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
            )
        }
    }
    
    // 分类选择区域
    private var categorySelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories, id: \.id) { category in
                        CategoryButton(
                            category: category,
                            isSelected: selectedCategory?.id == category.id
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // 备注输入区域
    private var noteInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("备注")
                .font(.headline)
                .foregroundColor(.white)
            
            TextField("添加备注信息（可选）", text: $note, axis: .vertical)
                .font(.body)
                .foregroundColor(.white)
                .textFieldStyle(PlainTextFieldStyle())
                .lineLimit(3...6)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                )
        }
    }
    
    // 日期选择区域
    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("日期")
                .font(.headline)
                .foregroundColor(.white)
            
            DatePicker(
                "选择日期",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
            .colorScheme(.dark)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
            )
        }
    }
    
    // 保存支出记录
    private func saveExpense() {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "请输入有效的金额"
            showingError = true
            return
        }
        
        let newExpense = ExpenseRecord(
            amount: amountValue,
            category: selectedCategory,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            timestamp: selectedDate,
            isVoiceInput: false
        )
        
        modelContext.insert(newExpense)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            showingError = true
        }
    }
}

// 分类按钮组件
struct CategoryButton: View {
    let category: ExpenseCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(category.color)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: category.iconName)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                    )
                
                Text(category.name)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .gray)
                    .lineLimit(1)
            }
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    ManualInputView()
        .modelContainer(for: [ExpenseRecord.self, ExpenseCategory.self, AppSettings.self], inMemory: true)
}