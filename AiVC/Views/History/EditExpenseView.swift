//
//  EditExpenseView.swift
//  AiVC
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct EditExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [ExpenseCategory]
    
    let expense: ExpenseRecord
    
    @State private var amount: String
    @State private var selectedCategory: ExpenseCategory?
    @State private var note: String
    @State private var selectedDate: Date
    @State private var showingDeleteAlert = false
    
    init(expense: ExpenseRecord) {
        self.expense = expense
        self._amount = State(initialValue: String(format: "%.2f", expense.amount))
        self._note = State(initialValue: expense.note)
        self._selectedDate = State(initialValue: expense.timestamp)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 金额输入
                        amountInput
                        
                        // 分类选择
                        categorySelection
                        
                        // 备注输入
                        noteInput
                        
                        // 日期选择
                        dateSelection
                        
                        // 删除按钮
                        deleteButton
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("编辑支出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("保存") {
                    saveChanges()
                }
                .foregroundColor(.blue)
                .disabled(!isValidInput)
            )
            .preferredColorScheme(.dark)
        }
        .onAppear {
            setupInitialCategory()
        }
        .alert("删除记录", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteExpense()
            }
        } message: {
            Text("确定要删除这条支出记录吗？删除后无法恢复。")
        }
    }
    
    // 验证输入是否有效
    private var isValidInput: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        guard selectedCategory != nil else { return false }
        return true
    }
    
    // 金额输入
    private var amountInput: some View {
        VStack(spacing: 0) {
            HStack {
                Text("金额")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "yensign.circle")
                        .font(.system(size: 18))
                        .foregroundColor(.green)
                        .frame(width: 24, height: 24)
                    
                    TextField("0.00", text: $amount)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.white)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.title2)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
            )
        }
    }
    
    // 分类选择
    private var categorySelection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("分类")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
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
                .padding(.horizontal, 16)
            }
            .frame(height: 80)
        }
    }
    
    // 备注输入
    private var noteInput: some View {
        VStack(spacing: 0) {
            HStack {
                Text("备注")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    Image(systemName: "note.text")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                        .frame(width: 24, height: 24)
                        .padding(.top, 2)
                    
                    TextField("添加备注（可选）", text: $note, axis: .vertical)
                        .foregroundColor(.white)
                        .textFieldStyle(PlainTextFieldStyle())
                        .lineLimit(3...6)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
            )
        }
    }
    
    // 日期选择
    private var dateSelection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("日期")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                        .frame(width: 24, height: 24)
                    
                    DatePicker(
                        "选择日期",
                        selection: $selectedDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                    .colorScheme(.dark)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
            )
        }
    }
    
    // 删除按钮
    private var deleteButton: some View {
        Button(action: {
            showingDeleteAlert = true
        }) {
            HStack {
                Image(systemName: "trash")
                    .font(.system(size: 18))
                Text("删除记录")
                    .font(.headline)
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 设置初始分类
    private func setupInitialCategory() {
        if let category = expense.category {
            selectedCategory = categories.first { $0.id == category.id }
        }
    }
    
    // 保存更改
    private func saveChanges() {
        guard let amountValue = Double(amount), amountValue > 0,
              let category = selectedCategory else { return }
        
        expense.amount = amountValue
        expense.category = category
        expense.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        expense.timestamp = selectedDate
        
        try? modelContext.save()
        dismiss()
    }
    
    // 删除支出记录
    private func deleteExpense() {
        modelContext.delete(expense)
        try? modelContext.save()
        dismiss()
    }
}



#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ExpenseRecord.self, ExpenseCategory.self, configurations: config)
    
    let sampleExpense = ExpenseRecord(
        amount: 25.50,
        category: nil,
        note: "午餐",
        timestamp: Date(),
        isVoiceInput: false
    )
    
    EditExpenseView(expense: sampleExpense)
        .modelContainer(container)
}