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
    
    private let cloudSyncService = CloudSyncService.shared
    
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
            GeometryReader { geometry in
                ZStack {
                    // 背景渐变
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.95),
                            Color.blue.opacity(0.1),
                            Color.purple.opacity(0.1),
                            Color.black.opacity(0.95)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    // 装饰性背景元素
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue.opacity(0.08),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                            .offset(
                                x: CGFloat.random(in: -geometry.size.width/2...geometry.size.width/2),
                                y: CGFloat.random(in: -geometry.size.height/2...geometry.size.height/2)
                            )
                    }
                    
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
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("手动记账")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.85))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveExpense()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isValidInput ? .green : .gray)
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
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: "yensign.circle")
                    .foregroundColor(.green)
                    .font(.system(size: 20, weight: .semibold))
                Text("金额")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 6)
            
            HStack {
                Text(currentSettings.currencySymbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.green.opacity(0.8))
                
                TextField("0.00", text: $amount)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.green.opacity(0.7), lineWidth: 2)
                    )
            )
            .shadow(color: .green.opacity(0.15), radius: 6, x: 0, y: 3)
        }
    }
    
    // 分类选择区域
    private var categorySelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: "tag.circle")
                    .foregroundColor(.blue)
                    .font(.system(size: 20, weight: .semibold))
                Text("分类")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 6)
            
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
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: "note.text")
                    .foregroundColor(.orange)
                    .font(.system(size: 20, weight: .semibold))
                Text("备注")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 6)
            
            TextField("添加备注信息（可选）", text: $note, axis: .vertical)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .textFieldStyle(PlainTextFieldStyle())
                .lineLimit(3...6)
                .padding(.horizontal, 22)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.orange.opacity(0.7), lineWidth: 2)
                        )
                )
                .shadow(color: .orange.opacity(0.15), radius: 6, x: 0, y: 3)
        }
    }
    
    // 日期选择区域
    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: "calendar.circle")
                    .foregroundColor(.purple)
                    .font(.system(size: 20, weight: .semibold))
                Text("日期")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 6)
            
            DatePicker(
                "选择日期",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
            .colorScheme(.dark)
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.purple.opacity(0.7), lineWidth: 2)
                    )
            )
            .shadow(color: .purple.opacity(0.15), radius: 6, x: 0, y: 3)
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
            // 触发自动同步
            cloudSyncService.triggerAutoSync(for: newExpense.id)
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
            VStack(spacing: 10) {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                category.color.opacity(0.9),
                                category.color
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: category.iconName)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected ? Color.blue.opacity(0.8) : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 3 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? category.color.opacity(0.4) : category.color.opacity(0.2),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
                
                Text(category.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    ManualInputView()
        .modelContainer(for: [ExpenseRecord.self, ExpenseCategory.self, AppSettings.self], inMemory: true)
}