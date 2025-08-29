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
        ZStack {
            // 统一纯色背景
            Color.black
                .ignoresSafeArea()
            
            ScrollView {
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
                    
                    Spacer(minLength: 150)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("历史")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
        .onAppear {
            startAnimations()
        }
        .toolbar(.visible, for: .tabBar)
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
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6).opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 24)
    }
    
    // 分类筛选
    private var categoryFilter: some View {
        categoryFilterContent
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6).opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 24)
    }
    
    private var categoryFilterContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            categoryFilterHeader
            categoryFilterButtons
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    private var categoryFilterHeader: some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.blue)
            
            Text("分类筛选")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
        }
    }
    
    private var categoryFilterButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                allCategoriesButton
                categoryButtons
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var allCategoriesButton: some View {
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
                            AnyShapeStyle(Color.cyan.opacity(0.8)) :
                            AnyShapeStyle(Color(.systemGray6).opacity(0.2))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    selectedCategory == nil ?
                                    Color.clear :
                                    Color(.systemGray6).opacity(0.3),
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
    }
    
    private var categoryButtons: some View {
        ForEach(categories, id: \.id) { category in
            CategoryButton(
                category: category,
                isSelected: selectedCategory?.id == category.id,
                onTap: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = selectedCategory?.id == category.id ? nil : category
                    }
                }
            )
        }
    }
    
    private struct CategoryButton: View {
        let category: ExpenseCategory
        let isSelected: Bool
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                categoryButtonContent
            }
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        
        private var categoryButtonContent: some View {
            HStack(spacing: 8) {
                Image(systemName: category.iconName)
                    .font(.system(size: 12, weight: .medium))
                Text(category.name)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(categoryButtonBackground)
        }
        
        private var categoryButtonBackground: some View {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    isSelected ?
                    AnyShapeStyle(category.color) :
                    AnyShapeStyle(Color(.systemGray6).opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? Color.clear : Color(.systemGray6).opacity(0.3),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: isSelected ? category.color.opacity(0.4) : Color.black.opacity(0.2),
                    radius: isSelected ? 6 : 3,
                    x: 0,
                    y: isSelected ? 3 : 2
                )
        }
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
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            // 记录内容
            if groupedExpenses.isEmpty {
                VStack(spacing: 20) {
                    Circle()
                        .fill(Color(.systemGray6).opacity(0.3))
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
                }
                .padding(.horizontal, 24)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6).opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 24)
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
        VStack(spacing: 20) {
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
                        .fill(Color.cyan.opacity(0.8))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "calendar")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        )
                        .shadow(
                            color: Color.cyan.opacity(0.3),
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
                                .foregroundColor(Color.cyan)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                            Capsule()
                                .fill(Color.cyan.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                            
                            Text("\(settings.currencySymbol)\(String(format: "%.2f", dayTotal))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    // 展开/收起图标
                    Circle()
                        .fill(Color(.systemGray6).opacity(0.2))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
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
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6).opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            .scaleEffect(headerScale)
            .buttonStyle(PlainButtonStyle())
            
            // 记录列表
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(expenses.indices, id: \.self) { index in
                        HistoryRowView(
                            expense: expenses[index],
                            settings: settings,
                            onEdit: { onEdit(expenses[index]) },
                            onDelete: { onDelete(expenses[index]) }
                        )
                        
                        if index < expenses.count - 1 {
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.horizontal, 24)
                        }
                    }
                }
                .padding(.bottom, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6).opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
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
                    .fill(expense.category?.color ?? .gray)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
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
                                    .foregroundColor(Color.cyan)
                                
                                Text("语音")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color.cyan)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.cyan.opacity(0.2))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
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
                        .foregroundColor(Color.red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                }
            }
            .padding(.horizontal, 24)
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