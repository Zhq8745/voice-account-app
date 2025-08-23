//
//  MainTabView.swift
//  AiVC
//
//  Created by AI Assistant
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 记账页面
            AccountingView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "plus.circle.fill" : "plus.circle")
                    Text("记账")
                }
                .tag(0)
            
            // 统计页面
            StatisticsView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "chart.pie.fill" : "chart.pie")
                    Text("统计")
                }
                .tag(1)
            
            // 历史页面
            HistoryView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "clock.fill" : "clock")
                    Text("历史")
                }
                .tag(2)
            
            // 设置页面
            SettingsView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                    Text("设置")
                }
                .tag(3)
        }
        .accentColor(.blue)
        .preferredColorScheme(.dark)
        .onAppear {
            // 设置TabBar样式
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
            
            // 设置选中状态的颜色
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
            
            // 设置未选中状态的颜色
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [ExpenseRecord.self, ExpenseCategory.self, AppSettings.self], inMemory: true)
}