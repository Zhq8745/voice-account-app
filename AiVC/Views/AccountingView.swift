//
//  AccountingView.swift
//  AiVC
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData
import Speech

struct AccountingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var expenses: [ExpenseRecord]
    @Query private var categories: [ExpenseCategory]
    @Query private var settings: [AppSettings]
    
    @State private var showingManualInput = false
    @State private var showingVoiceInput = false
    @State private var pulseAnimation = false
    @State private var cardScale: CGFloat = 1.0
    
    // 当前月份的支出
    private var currentMonthExpenses: [ExpenseRecord] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        
        return expenses.filter { expense in
            expense.timestamp >= startOfMonth && expense.timestamp < endOfMonth
        }
    }
    
    // 今日支出
    private var todayExpenses: [ExpenseRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        return expenses.filter { expense in
            expense.timestamp >= today && expense.timestamp < tomorrow
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    // 本月总支出
    private var monthlyTotal: Double {
        currentMonthExpenses.reduce(0) { $0 + $1.amount }
    }
    
    // 今日总支出
    private var todayTotal: Double {
        todayExpenses.reduce(0) { $0 + $1.amount }
    }
    
    // 当前设置
    private var currentSettings: AppSettings {
        settings.first ?? AppSettings()
    }
    
    var body: some View {
        GeometryReader { geometry in
                ZStack {
                    // 统一纯色背景
                    Color.black
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // 本月支出卡片
                            monthlyExpenseCard
                                .scaleEffect(cardScale)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.8),
                                    value: cardScale
                                )
                            
                            // 输入按钮区域
                            inputButtonsSection
                            
                            // 今日记录
                            todayRecordsSection
                            
                            Spacer(minLength: 100) // 为底部导航留出空间
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                    }
                }
        }
        .navigationTitle("记账")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showingManualInput) {
            ManualInputView()
        }
        .sheet(isPresented: $showingVoiceInput) {
            VoiceInputView()
        }
        .onAppear {
            initializeDefaultData()
            startAnimations()
        }
        .toolbarBackground(.visible, for: .tabBar)
    }
    
    // 本月支出卡片
    private var monthlyExpenseCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "creditcard.circle.fill")
                        .font(.title2)
                        .foregroundColor(.cyan)
                    Text("本月支出")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                Spacer()
                Text(getCurrentMonthText())
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(currentSettings.currencySymbol)\(String(format: "%.2f", monthlyTotal))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("总支出")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("+12.5%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.15))
                    )
                    
                    Text("较上月")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6).opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // 输入按钮区域
    private var inputButtonsSection: some View {
        HStack(spacing: 16) {
            // 语音输入按钮
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    cardScale = 0.95
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        cardScale = 1.0
                    }
                }
                showingVoiceInput = true
            }) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 50, height: 50)
                            .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text("语音记账")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6).opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // 手动输入按钮
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    cardScale = 0.95
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        cardScale = 1.0
                    }
                }
                showingManualInput = true
            }) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 50, height: 50)
                            .shadow(color: Color.cyan.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text("手动记账")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6).opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // 今日记录区域
    private var todayRecordsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.circle.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("今日记录")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(currentSettings.currencySymbol)\(String(format: "%.2f", todayTotal))")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text("今日总计")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            if todayExpenses.isEmpty {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray6).opacity(0.5))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "tray")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    VStack(spacing: 4) {
                        Text("今日暂无记录")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        Text("开始记录您的第一笔支出吧")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(todayExpenses, id: \.id) { expense in
                        ExpenseRowView(expense: expense, settings: currentSettings)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6).opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6).opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // 获取当前月份文本
    private func getCurrentMonthText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        return formatter.string(from: Date())
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
    
    // 初始化默认数据
    private func initializeDefaultData() {
        // 如果没有设置，创建默认设置
        if settings.isEmpty {
            let defaultSettings = AppSettings()
            modelContext.insert(defaultSettings)
        }
        
        // 如果没有分类，创建默认分类
        if categories.isEmpty {
            for category in ExpenseCategory.defaultCategories {
                modelContext.insert(category)
            }
        }
        
        // 保存上下文
        try? modelContext.save()
    }

}

// 支出记录行视图
struct ExpenseRowView: View {
    let expense: ExpenseRecord
    let settings: AppSettings
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // 分类图标
            ZStack {
                Circle()
                    .fill(expense.category?.color ?? Color.cyan)
                    .frame(width: 32, height: 32)
                    .shadow(color: (expense.category?.color ?? Color.cyan).opacity(0.3), radius: 4, x: 0, y: 2)
                
                Image(systemName: expense.category?.iconName ?? "questionmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            
            // 记录信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(expense.category?.name ?? "未分类")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    if expense.isVoiceInput {
                        Image(systemName: "mic.fill")
                            .font(.caption2)
                            .foregroundColor(Color.cyan)
                    }
                }
                
                if !expense.note.isEmpty {
                    Text(expense.note)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
                
                Text(expense.formattedTime)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // 金额
            Text("-\(settings.currencySymbol)\(expense.formattedAmount)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
    }
}

#Preview {
    AccountingView()
        .modelContainer(for: [ExpenseRecord.self, ExpenseCategory.self, AppSettings.self], inMemory: true)
}