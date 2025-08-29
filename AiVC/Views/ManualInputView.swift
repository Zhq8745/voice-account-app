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
    @State private var selectedDate = Date()
    @State private var note = ""
    @State private var showingDatePicker = false
    @State private var showingCategoryPicker = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var pulseAnimation = false
    @State private var cardScale: CGFloat = 1.0
    
    private var currentSettings: AppSettings {
        settings.first ?? AppSettings()
    }
    
    private var isValidInput: Bool {
        !amount.isEmpty && Double(amount) != nil && Double(amount)! > 0
    }
    
    // 日期格式化器
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }
    
    // 时间格式化器
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // 统一纯色背景
                    Color.black
                        .ignoresSafeArea()
                    
                    // 主要内容区域
                    ScrollView {
                        VStack(spacing: 20) {
                            // 金额输入卡片
                            amountInputCard
                                .scaleEffect(cardScale)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.8),
                                    value: cardScale
                                )
                            
                            // 分类选择卡片
                            categorySelectionCard
                            
                            // 备注和日期卡片
                            noteAndDateCard
                            
                            // 保存按钮 - 整合到底部布局模块中
                            bottomSaveButton
                                .padding(.top, 10)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                    }
                }
            }
            .navigationTitle("手动记账")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .preferredColorScheme(.dark)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .alert("错误", isPresented: $showingError) {
            Button("确定") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            selectedCategory = categories.first
            startAnimations()
        }
    }
    
    // 启动动画
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseAnimation.toggle()
        }
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
            cardScale = 1.0
        }
    }
    
    // 金额输入卡片 - 采用首页按钮风格
    private var amountInputCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(.green)
                            .frame(width: 32, height: 32)
                            .shadow(color: Color.green.opacity(0.3), radius: 6, x: 0, y: 3)
                        
                        Image(systemName: "yensign")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Text("输入金额")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                Spacer()
            }
            
            VStack(spacing: 16) {
                HStack(alignment: .bottom, spacing: 8) {
                    Text(currentSettings.currencySymbol)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.green.opacity(0.8))
                    
                    TextField("0.00", text: $amount)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(PlainTextFieldStyle())
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6).opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                if !amount.isEmpty {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            .green,
                                            .green.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 16, height: 16)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("金额有效")
                            .font(.caption)
                            .foregroundColor(.green)
                        Spacer()
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    // 分类选择卡片 - 采用首页按钮风格
    private var categorySelectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(.cyan)
                            .frame(width: 32, height: 32)
                            .shadow(color: Color.cyan.opacity(0.3), radius: 6, x: 0, y: 3)
                        
                        Image(systemName: "tag")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Text("选择分类")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                Spacer()
            }
            
            // 使用水平滑动布局显示分类
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(categories, id: \.id) { category in
                        CategoryButton(
                            category: category,
                            isSelected: selectedCategory?.id == category.id
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.2))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    // 备注和日期卡片 - 采用首页按钮风格
    private var noteAndDateCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 添加备注部分
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(.cyan)
                                .frame(width: 32, height: 32)
                                .shadow(color: Color.cyan.opacity(0.3), radius: 6, x: 0, y: 3)
                            
                            Image(systemName: "note.text")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Text("添加备注")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                
                TextField("添加备注信息（可选）", text: $note)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.white)
                    .font(.body)
            }
            
            // 选择日期部分
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(.cyan)
                                .frame(width: 32, height: 32)
                                .shadow(color: Color.cyan.opacity(0.3), radius: 6, x: 0, y: 3)
                            
                            Image(systemName: "calendar")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Text("选择日期")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingDatePicker.toggle()
                    }
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("日期")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            Text(dateFormatter.string(from: selectedDate))
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("时间")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            Text(timeFormatter.string(from: selectedDate))
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(Color.cyan)
                        }
                        
                        Image(systemName: showingDatePicker ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                if showingDatePicker {
                    DatePicker(
                        "选择日期和时间",
                        selection: $selectedDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                    .colorScheme(.dark)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// 分类按钮组件 - 采用首页按钮风格
struct CategoryButton: View {
    let category: ExpenseCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected ? Color.cyan : Color.white.opacity(0.1)
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? Color.clear : Color.white.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: isSelected ? Color.cyan.opacity(0.4) : Color.clear,
                            radius: isSelected ? 6 : 0,
                            x: 0,
                            y: isSelected ? 3 : 0
                        )
                    
                    Image(systemName: category.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                }
                
                Text(category.name)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

extension ManualInputView {
    // 底部保存按钮
    private var bottomSaveButton: some View {
        Button(action: { saveExpense() }) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .semibold))
                Text("保存记录")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        amount.isEmpty || selectedCategory == nil ?
                        Color.white.opacity(0.15) :
                        Color.cyan
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(
                color: (amount.isEmpty || selectedCategory == nil) ? Color.clear : Color.cyan.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(amount.isEmpty || selectedCategory == nil)
        .opacity((amount.isEmpty || selectedCategory == nil) ? 0.6 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: amount.isEmpty || selectedCategory == nil)
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



#Preview {
    ManualInputView()
        .modelContainer(for: [ExpenseRecord.self, ExpenseCategory.self, AppSettings.self], inMemory: true)
}