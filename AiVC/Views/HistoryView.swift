//
//  HistoryView.swift
//  AiVC
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var expenses: [ExpenseRecord]
    @Query private var categories: [ExpenseCategory]
    @Query private var settings: [AppSettings]
    
    @State private var searchText = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var showingEditSheet = false
    @State private var editingExpense: ExpenseRecord?
    
    // 动画状态
    @State private var pulseAnimation = false
    @State private var cardScale: CGFloat = 0.95
    @State private var listAnimation = false
    
    // 当前设置
    private var currentSettings: AppSettings {
        settings.first ?? AppSettings()
    }
    
    // 筛选后的支出记录
    private var filteredExpenses: [ExpenseRecord] {
        var filtered = expenses
        
        // 按搜索文本筛选
        if !searchText.isEmpty {
            filtered = filtered.filter { expense in
                expense.note.localizedCaseInsensitiveContains(searchText) ||
                expense.category?.name.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // 按分类筛选
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category?.id == selectedCategory.id }
        }
        
        return filtered.sorted { $0.timestamp > $1.timestamp }
    }
    
    // 按日期分组的支出记录
    private var groupedExpenses: [(date: Date, expenses: [ExpenseRecord])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredExpenses) { expense in
            calendar.startOfDay(for: expense.timestamp)
        }
        
        return grouped.map { (date: $0.key, expenses: $0.value.sorted { $0.timestamp > $1.timestamp }) }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 渐变背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.08),
                        Color(red: 0.12, green: 0.12, blue: 0.15),
                        Color(red: 0.08, green: 0.08, blue: 0.12)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // 装饰性圆形
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.15),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .position(x: UIScreen.main.bounds.width * 0.8, y: 100)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .opacity(pulseAnimation ? 0.6 : 0.3)
                    .animation(
                        Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.purple.opacity(0.1),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .position(x: UIScreen.main.bounds.width * 0.2, y: UIScreen.main.bounds.height * 0.7)
                    .scaleEffect(pulseAnimation ? 0.8 : 1.1)
                    .opacity(pulseAnimation ? 0.4 : 0.2)
                    .animation(
                        Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                VStack(spacing: 24) {
                    // 搜索栏
                    searchBar
                        .scaleEffect(cardScale)
                        .opacity(listAnimation ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.1), value: listAnimation)
                    
                    // 分类筛选
                    categoryFilter
                        .scaleEffect(cardScale)
                        .opacity(listAnimation ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.2), value: listAnimation)
                    
                    // 历史记录列表
                    historyList
                        .scaleEffect(cardScale)
                        .opacity(listAnimation ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.3), value: listAnimation)
                }
            }
            .navigationTitle("历史")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .onAppear {
                startAnimations()
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let expense = editingExpense {
                EditExpenseView(expense: expense)
            }
        }
    }
    
    private func startAnimations() {
        pulseAnimation = true
        
        withAnimation(.easeOut(duration: 0.8)) {
            cardScale = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            listAnimation = true
        }
    }
    
    // 搜索栏
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
            
            TextField("搜索记录...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
                .font(.system(size: 16))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.15, green: 0.15, blue: 0.18),
                            Color(red: 0.12, green: 0.12, blue: 0.15)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.3),
                                    Color.purple.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
        .padding(.horizontal, 16)
    }
    
    // 分类筛选
    private var categoryFilter: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.blue)
                
                Text("分类筛选")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // 全部分类按钮
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = nil
                        }
                    }) {
                        Text("全部")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedCategory == nil ? .black : .white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        selectedCategory == nil ?
                                        LinearGradient(
                                            gradient: Gradient(colors: [.blue, .purple]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.15, green: 0.15, blue: 0.18),
                                                Color(red: 0.12, green: 0.12, blue: 0.15)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                selectedCategory == nil ?
                                                Color.clear :
                                                Color.gray.opacity(0.3),
                                                lineWidth: 1
                                            )
                                    )
                                    .shadow(
                                        color: selectedCategory == nil ?
                                        Color.blue.opacity(0.3) :
                                        Color.black.opacity(0.2),
                                        radius: selectedCategory == nil ? 6 : 3,
                                        x: 0,
                                        y: selectedCategory == nil ? 3 : 2
                                    )
                            )
                    }
                    .scaleEffect(selectedCategory == nil ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: selectedCategory == nil)
                    
                    // 分类按钮
                    ForEach(categories, id: \.id) { category in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = selectedCategory?.id == category.id ? nil : category
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: category.iconName)
                                    .font(.system(size: 12, weight: .medium))
                                Text(category.name)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(selectedCategory?.id == category.id ? .black : .white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        selectedCategory?.id == category.id ?
                                        LinearGradient(
                                            gradient: Gradient(colors: [category.color, category.color.opacity(0.8)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ) :
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.15, green: 0.15, blue: 0.18),
                                                Color(red: 0.12, green: 0.12, blue: 0.15)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                selectedCategory?.id == category.id ?
                                                Color.clear :
                                                Color.gray.opacity(0.3),
                                                lineWidth: 1
                                            )
                                    )
                                    .shadow(
                                        color: selectedCategory?.id == category.id ?
                                        category.color.opacity(0.4) :
                                        Color.black.opacity(0.2),
                                        radius: selectedCategory?.id == category.id ? 6 : 3,
                                        x: 0,
                                        y: selectedCategory?.id == category.id ? 3 : 2
                                    )
                            )
                        }
                        .scaleEffect(selectedCategory?.id == category.id ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: selectedCategory?.id == category.id)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.15, green: 0.15, blue: 0.18),
                            Color(red: 0.12, green: 0.12, blue: 0.15)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.3),
                                    Color.purple.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.3),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
        .padding(.horizontal, 16)
    }
    
    // 历史记录列表
    private var historyList: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.blue)
                
                Text("历史记录")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                if !groupedExpenses.isEmpty {
                    Text("(\(groupedExpenses.count)天)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // 记录内容
            if groupedExpenses.isEmpty {
                VStack(spacing: 20) {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.3),
                                    Color.purple.opacity(0.1),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(.blue)
                        )
                    
                    VStack(spacing: 8) {
                        Text(searchText.isEmpty ? "暂无历史记录" : "未找到相关记录")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(searchText.isEmpty ? "开始记录您的第一笔支出吧" : "尝试调整搜索条件")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(groupedExpenses, id: \.date) { group in
                            HistoryGroupView(
                                date: group.date,
                                expenses: group.expenses,
                                settings: currentSettings,
                                onEdit: { expense in
                                    editingExpense = expense
                                    showingEditSheet = true
                                },
                                onDelete: { expense in
                                    deleteExpense(expense)
                                }
                            )
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.15, green: 0.15, blue: 0.18),
                            Color(red: 0.12, green: 0.12, blue: 0.15)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.3),
                                    Color.purple.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.3),
                    radius: 12,
                    x: 0,
                    y: 6
                )
        )
        .padding(.horizontal, 16)
    }
    
    // 删除支出记录
    private func deleteExpense(_ expense: ExpenseRecord) {
        withAnimation {
            modelContext.delete(expense)
            try? modelContext.save()
        }
    }
}

// 历史记录分组视图
struct HistoryGroupView: View {
    let date: Date
    let expenses: [ExpenseRecord]
    let settings: AppSettings
    let onEdit: (ExpenseRecord) -> Void
    let onDelete: (ExpenseRecord) -> Void
    
    @State private var isExpanded = true
    @State private var headerScale: CGFloat = 1.0
    
    // 当日总支出
    private var dayTotal: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    // 格式化日期
    private var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            formatter.dateFormat = "MM月dd日 EEEE"
            return formatter.string(from: date)
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // 日期头部
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                
                // 按钮按压动画
                withAnimation(.easeInOut(duration: 0.1)) {
                    headerScale = 0.98
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        headerScale = 1.0
                    }
                }
            }) {
                HStack(spacing: 16) {
                    // 日期图标
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "calendar")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        )
                        .shadow(
                            color: Color.blue.opacity(0.3),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(formattedDate)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 8) {
                            Text("\(expenses.count)笔")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.2))
                                )
                            
                            Text("\(settings.currencySymbol)\(String(format: "%.2f", dayTotal))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    // 展开/收起图标
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.2, green: 0.2, blue: 0.25),
                                    Color(red: 0.15, green: 0.15, blue: 0.18)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                                .rotationEffect(.degrees(isExpanded ? 0 : 180))
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.18, green: 0.18, blue: 0.22),
                                    Color(red: 0.15, green: 0.15, blue: 0.18)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.blue.opacity(0.3),
                                            Color.purple.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: Color.black.opacity(0.2),
                            radius: 6,
                            x: 0,
                            y: 3
                        )
                )
            }
            .scaleEffect(headerScale)
            .buttonStyle(PlainButtonStyle())
            
            // 记录列表
            if isExpanded {
                VStack(spacing: 1) {
                    ForEach(expenses.indices, id: \.self) { index in
                        HistoryRowView(
                            expense: expenses[index],
                            settings: settings,
                            onEdit: { onEdit(expenses[index]) },
                            onDelete: { onDelete(expenses[index]) }
                        )
                        .background(
                            RoundedRectangle(cornerRadius: index == 0 ? 12 : (index == expenses.count - 1 ? 12 : 0))
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.16, green: 0.16, blue: 0.20),
                                            Color(red: 0.13, green: 0.13, blue: 0.16)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        
                        if index < expenses.count - 1 {
                            Divider()
                                .background(Color.gray.opacity(0.2))
                                .padding(.horizontal, 20)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.16, green: 0.16, blue: 0.20),
                                    Color(red: 0.13, green: 0.13, blue: 0.16)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    Color.gray.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: Color.black.opacity(0.2),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                )
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .offset(y: -10)),
                        removal: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .offset(y: -10))
                    )
                )
            }
        }
    }
}

// 历史记录行视图
struct HistoryRowView: View {
    let expense: ExpenseRecord
    let settings: AppSettings
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingActionSheet = false
    @State private var rowScale: CGFloat = 1.0
    @State private var iconScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            // 按钮按压动画
            withAnimation(.easeInOut(duration: 0.1)) {
                rowScale = 0.98
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    rowScale = 1.0
                }
                showingActionSheet = true
            }
        }) {
            HStack(spacing: 16) {
                // 分类图标
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                expense.category?.color ?? .gray,
                                (expense.category?.color ?? .gray).opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.clear
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .overlay(
                        Image(systemName: expense.category?.iconName ?? "questionmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .scaleEffect(iconScale)
                    )
                    .shadow(
                        color: (expense.category?.color ?? .gray).opacity(0.4),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
                
                // 记录信息
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(expense.category?.name ?? "未分类")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                        
                        if expense.isVoiceInput {
                            HStack(spacing: 4) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.blue)
                                
                                Text("语音")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.2))
                            )
                        }
                        
                        Spacer()
                    }
                    
                    if !expense.note.isEmpty {
                        Text(expense.note)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text(expense.formattedTime)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                }
                
                // 金额
                VStack(alignment: .trailing, spacing: 4) {
                    Text("-\(settings.currencySymbol)\(expense.formattedAmount)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    // 金额标签
                    Text("支出")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.2))
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .scaleEffect(rowScale)
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // 图标动画
            withAnimation(
                .easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true)
            ) {
                iconScale = 1.1
            }
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("操作选项"),
                message: Text("选择要执行的操作"),
                buttons: [
                    .default(Text("✏️ 编辑记录")) {
                        onEdit()
                    },
                    .destructive(Text("🗑️ 删除记录")) {
                        onDelete()
                    },
                    .cancel(Text("取消"))
                ]
            )
        }
    }
}



#Preview {
    HistoryView()
        .modelContainer(for: [ExpenseRecord.self, ExpenseCategory.self, AppSettings.self], inMemory: true)
}