//
//  MainTabView.swift
//  AiVC
//
//  Created by AI Assistant
//

import SwiftUI
import Foundation
import Combine

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 记账页面
            NavigationStack {
                AccountingView()
            }
            .tabItem {
                Image(systemName: selectedTab == 0 ? "plus.circle.fill" : "plus.circle")
                Text("记账")
            }
            .tag(0)
            
            // 统计页面
            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Image(systemName: selectedTab == 1 ? "chart.pie.fill" : "chart.pie")
                Text("统计")
            }
            .tag(1)
            
            // 历史页面
            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Image(systemName: selectedTab == 2 ? "clock.fill" : "clock")
                Text("历史")
            }
            .tag(2)
            
            // 设置页面
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Image(systemName: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                Text("设置")
            }
            .tag(3)
        }
        .accentColor(Color.cyan)
        .preferredColorScheme(.dark)
        .onAppear {
            // 设置TabBar样式
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color(.systemGray6))
            
            // 设置选中状态的颜色
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.cyan)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.cyan)]
            
            // 设置未选中状态的颜色
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.white.opacity(0.8))
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.white.opacity(0.8))]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [ExpenseRecord.self, ExpenseCategory.self, AppSettings.self], inMemory: true)
}