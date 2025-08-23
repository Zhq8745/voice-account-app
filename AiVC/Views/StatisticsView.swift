//
//  StatisticsView.swift
//  AiVC
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData
import Charts
import Foundation

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var expenses: [ExpenseRecord]
    @Query private var categories: [ExpenseCategory]
    @Query private var settings: [AppSettings]
    
    @State private var selectedPeriod: TimePeriod = .month
    @State private var selectedDate = Date()
    @State private var pulseAnimation = false
    @State private var cardScale: CGFloat = 1.0
    @State private var chartAnimation = false
    
    enum TimePeriod: String, CaseIterable {
        case month = "月"
        case quarter = "季度"
        case year = "年"
    }
    
    // 当前设置
    private var currentSettings: AppSettings {
        settings.first ?? AppSettings()
    }
    
    // 根据选择的时间段获取支出数据
    private var periodExpenses: [ExpenseRecord] {
        let calendar = Calendar.current
        let startDate: Date
        let endDate: Date
        
        switch selectedPeriod {
        case .month:
            let interval = calendar.dateInterval(of: .month, for: selectedDate)
            startDate = interval?.start ?? selectedDate
            endDate = interval?.end ?? selectedDate
        case .quarter:
            let interval = calendar.dateInterval(of: .quarter, for: selectedDate)
            startDate = interval?.start ?? selectedDate
            endDate = interval?.end ?? selectedDate
        case .year:
            let interval = calendar.dateInterval(of: .year, for: selectedDate)
            startDate = interval?.start ?? selectedDate
            endDate = interval?.end ?? selectedDate
        }
        
        return expenses.filter { expense in
            expense.timestamp >= startDate && expense.timestamp < endDate
        }
    }
    
    // 总支出
    private var totalExpense: Double {
        periodExpenses.reduce(0) { $0 + $1.amount }
    }
    
    // 日均支出
    private var dailyAverage: Double {
        let calendar = Calendar.current
        let days: Int
        
        switch selectedPeriod {
        case .month:
            days = calendar.range(of: .day, in: .month, for: selectedDate)?.count ?? 30
        case .quarter:
            days = 90
        case .year:
            days = calendar.range(of: .day, in: .year, for: selectedDate)?.count ?? 365
        }
        
        return totalExpense / Double(days)
    }
    
    // 分类统计数据
    private var categoryStats: [(category: ExpenseCategory, amount: Double, percentage: Double)] {
        let categoryAmounts = Dictionary(grouping: periodExpenses) { $0.category }
            .compactMapValues { expenses in
                expenses.reduce(0) { $0 + $1.amount }
            }
        
        return categoryAmounts.compactMap { (category, amount) in
            guard let cat = category else { return nil }
            let percentage = totalExpense > 0 ? (amount / totalExpense) * 100 : 0
            return (cat, amount, percentage)
        }.sorted { $0.amount > $1.amount }
    }
    
    // 趋势数据
    private var trendData: [TrendDataPoint] {
        let calendar = Calendar.current
        let groupedExpenses: [Date: Double]
        
        switch selectedPeriod {
        case .month:
            // 按天分组
            groupedExpenses = Dictionary(grouping: periodExpenses) { expense in
                calendar.startOfDay(for: expense.timestamp)
            }.mapValues { expenses in
                expenses.reduce(0) { $0 + $1.amount }
            }
        case .quarter, .year:
            // 按月分组
            let monthlyGrouped: [Date: [ExpenseRecord]] = Dictionary(grouping: periodExpenses) { expense in
                let components = calendar.dateComponents([.year, .month], from: expense.timestamp)
                return calendar.date(from: components) ?? expense.timestamp
            }
            groupedExpenses = monthlyGrouped.mapValues { expenses in
                expenses.reduce(0) { $0 + $1.amount }
            }
        }
        
        return groupedExpenses.map { TrendDataPoint(date: $0.key, amount: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 渐变背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(red: 0.05, green: 0.05, blue: 0.1),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // 装饰性元素
                GeometryReader { geometry in
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue.opacity(0.1),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                            .position(
                                x: geometry.size.width * (0.2 + Double(index) * 0.3),
                                y: geometry.size.height * (0.1 + Double(index) * 0.4)
                            )
                            .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                            .animation(
                                Animation.easeInOut(duration: 3.0 + Double(index))
                                    .repeatForever(autoreverses: true),
                                value: pulseAnimation
                            )
                    }
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 时间选择器
                        timePeriodSelector
                        
                        // 支出总览卡片
                        overviewCard
                            .scaleEffect(cardScale)
                        
                        // 趋势图表
                        trendChart
                            .opacity(chartAnimation ? 1.0 : 0.0)
                            .scaleEffect(chartAnimation ? 1.0 : 0.9)
                        
                        // 分类分布
                        categoryDistribution
                            .opacity(chartAnimation ? 1.0 : 0.0)
                            .scaleEffect(chartAnimation ? 1.0 : 0.9)
                        
                        // 分类详情列表
                        categoryDetailsList
                            .opacity(chartAnimation ? 1.0 : 0.0)
                            .scaleEffect(chartAnimation ? 1.0 : 0.9)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("统计")
            .preferredColorScheme(.dark)
            .onAppear {
                startAnimations()
            }
        }
    }
    
    private func startAnimations() {
        pulseAnimation = true
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            cardScale = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            chartAnimation = true
        }
    }
    
    // 时间选择器
    private var timePeriodSelector: some View {
        HStack(spacing: 16) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedPeriod = period
                    }
                }) {
                    Text(period.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(selectedPeriod == period ? .black : .white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Group {
                                if selectedPeriod == period {
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white,
                                            Color.white.opacity(0.9)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                } else {
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.1),
                                            Color.white.opacity(0.05)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    selectedPeriod == period ? 
                                    Color.white.opacity(0.3) : 
                                    Color.white.opacity(0.2), 
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: selectedPeriod == period ? 
                            Color.white.opacity(0.3) : 
                            Color.clear, 
                            radius: 8, x: 0, y: 4
                        )
                        .scaleEffect(selectedPeriod == period ? 1.05 : 1.0)
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // 支出总览卡片
    private var overviewCard: some View {
        VStack(spacing: 20) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("支出总览")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                Spacer()
                Text(getPeriodText())
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                    )
            }
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("总支出")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("\(currentSettings.currencySymbol)\(String(format: "%.2f", totalExpense))")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundColor(.red.opacity(0.8))
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("日均支出")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("\(currentSettings.currencySymbol)\(String(format: "%.2f", dailyAverage))")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Image(systemName: "calendar.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue.opacity(0.8))
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                HStack {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .foregroundColor(.green)
                    Text("+8.2% 同比上期")
                        .font(.caption)
                        .foregroundColor(.green)
                    Spacer()
                }
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.15),
                    Color.white.opacity(0.08)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    // 趋势图表
    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("支出趋势")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
            }
            
            if trendData.isEmpty {
                VStack(spacing: 16) {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.2),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        )
                    Text("暂无数据")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("开始记录支出后，这里将显示趋势图表")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                Chart(trendData, id: \.date) { dataPoint in
                    LineMark(
                        x: .value("日期", dataPoint.date),
                        y: .value("金额", dataPoint.amount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    
                    AreaMark(
                        x: .value("日期", dataPoint.date),
                        y: .value("金额", dataPoint.amount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.4), .cyan.opacity(0.2), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 220)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.white.opacity(0.2))
                        AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.white.opacity(0.4))
                        AxisValueLabel()
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.white.opacity(0.2))
                        AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.white.opacity(0.4))
                        AxisValueLabel()
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.12),
                    Color.white.opacity(0.06)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.08)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
    }
    
    // 分类分布饼图
    private var categoryDistribution: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                Text("分类分布")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
            }
            
            if categoryStats.isEmpty {
                VStack(spacing: 16) {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.purple.opacity(0.2),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "chart.pie")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        )
                    Text("暂无数据")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("添加支出记录后，这里将显示分类分布")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                Chart(categoryStats, id: \.category.id) { stat in
                    SectorMark(
                        angle: .value("金额", stat.amount),
                        innerRadius: .ratio(0.5),
                        angularInset: 3
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [stat.category.color, stat.category.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(0.9)
                    .shadow(color: stat.category.color.opacity(0.3), radius: 4)
                }
                .frame(height: 220)
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.12),
                    Color.white.opacity(0.06)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.08)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
    }
    
    // 分类详情列表
    private var categoryDetailsList: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "list.bullet.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("分类详情")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                if !categoryStats.isEmpty {
                    Text("\(categoryStats.count) 个分类")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                        )
                }
            }
            
            if categoryStats.isEmpty {
                VStack(spacing: 16) {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.green.opacity(0.2),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "list.bullet")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        )
                    Text("暂无数据")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("记录支出后，这里将显示详细的分类统计")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(categoryStats, id: \.category.id) { stat in
                        CategoryStatRow(stat: stat, settings: currentSettings)
                    }
                }
            }
        }
        .padding(24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.12),
                    Color.white.opacity(0.06)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.08)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 8)
    }
    
    // 获取时间段文本
    private func getPeriodText() -> String {
        let formatter = DateFormatter()
        
        switch selectedPeriod {
        case .month:
            formatter.dateFormat = "yyyy年MM月"
        case .quarter:
            let quarter = Calendar.current.component(.quarter, from: selectedDate)
            formatter.dateFormat = "yyyy年"
            return "\(formatter.string(from: selectedDate))第\(quarter)季度"
        case .year:
            formatter.dateFormat = "yyyy年"
        }
        
        return formatter.string(from: selectedDate)
    }
}

// 趋势数据点
struct TrendDataPoint {
    let date: Date
    let amount: Double
}

// 分类统计行
struct CategoryStatRow: View {
    let stat: (category: ExpenseCategory, amount: Double, percentage: Double)
    let settings: AppSettings
    
    var body: some View {
        HStack(spacing: 16) {
            // 分类图标
            Circle()
                .fill(
                    LinearGradient(
                        colors: [stat.category.color, stat.category.color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: stat.category.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                )
                .shadow(color: stat.category.color.opacity(0.3), radius: 4, x: 0, y: 2)
            
            // 分类信息
            VStack(alignment: .leading, spacing: 8) {
                Text(stat.category.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // 进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [stat.category.color, stat.category.color.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * (stat.percentage / 100), height: 6)
                            .shadow(color: stat.category.color.opacity(0.4), radius: 2, x: 0, y: 1)
                    }
                }
                .frame(height: 6)
            }
            
            Spacer()
            
            // 金额和百分比
            VStack(alignment: .trailing, spacing: 6) {
                Text("\(settings.currencySymbol)\(String(format: "%.2f", stat.amount))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(String(format: "%.1f", stat.percentage))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(stat.category.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(stat.category.color.opacity(0.15))
                    )
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.08),
                    Color.white.opacity(0.04)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: [ExpenseRecord.self, ExpenseCategory.self, AppSettings.self], inMemory: true)
}