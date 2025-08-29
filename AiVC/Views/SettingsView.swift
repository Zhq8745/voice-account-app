//
//  SettingsView.swift
//  语记
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData
import Foundation
import Combine

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authManager: AuthenticationManager
    @Query private var settings: [AppSettings]
    @Query private var categories: [ExpenseCategory]
    
    @State private var showingCategoryManager = false
    @State private var showingAddCategory = false
    @State private var editingCategory: ExpenseCategory?
    @State private var showingLogoutAlert = false
    // @State private var showingAPIKeyConfig = false // 已移除API密钥配置
    

    
    // 动画状态
    @State private var pulseAnimation = false
    @State private var cardScale: CGFloat = 0.95
    @State private var listAnimation = false
    
    // 云同步服务
    private let cloudSyncService = CloudSyncService.shared
    
    // 当前设置
    private var currentSettings: AppSettings {
        if let existing = settings.first {
            return existing
        } else {
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
            return newSettings
        }
    }
    
    var body: some View {
        ZStack {
            // 统一纯色背景
            Color.black
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 基本设置
                        basicSettings
                            .scaleEffect(cardScale)
                            .opacity(listAnimation ? 1 : 0)
                            .animation(
                                Animation.spring(response: 0.8, dampingFraction: 0.8)
                                    .delay(0.1),
                                value: listAnimation
                            )
                        

                        
                        // 分类管理
                        categoryManagement
                            .scaleEffect(cardScale)
                            .opacity(listAnimation ? 1 : 0)
                            .animation(
                                Animation.spring(response: 0.8, dampingFraction: 0.8)
                                    .delay(0.25),
                                value: listAnimation
                            )
                        
                        // 账户管理
                        accountSection
                            .scaleEffect(cardScale)
                            .opacity(listAnimation ? 1 : 0)
                            .animation(
                                Animation.spring(response: 0.8, dampingFraction: 0.8)
                                    .delay(0.35),
                                value: listAnimation
                            )
                        
                        // 调试设置

                        
                        // 关于信息
                        aboutSection
                            .scaleEffect(cardScale)
                            .opacity(listAnimation ? 1 : 0)
                            .animation(
                                Animation.spring(response: 0.8, dampingFraction: 0.8)
                                    .delay(0.45),
                                value: listAnimation
                            )
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
        .toolbar(.visible, for: .tabBar)
        .onAppear {
            startAnimations()
        }
        .sheet(isPresented: $showingCategoryManager) {
            CategoryManagerView()
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView()
        }
        .sheet(item: $editingCategory) { category in
            EditCategoryView(category: category)
        }
        .alert("确认注销", isPresented: $showingLogoutAlert) {
            Button("取消", role: .cancel) { }
            Button("注销", role: .destructive) {
                Task {
                    await performLogout()
                }
            }
        } message: {
            Text("注销后将清除所有本地数据，确定要继续吗？")
        }
        // 移除API密钥配置相关的sheet
    }
    
    // 执行注销
    private func performLogout() async {
        do {
            await authManager.logout()
            // 注销成功，AuthenticationManager会自动更新认证状态
            // 语记App会监听到状态变化并自动切换到登录界面
        } catch {
            // 处理注销错误（如果需要的话）
            print("注销失败: \(error.localizedDescription)")
        }
    }
    
    // 启动动画
    private func startAnimations() {
        pulseAnimation = true
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            cardScale = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            listAnimation = true
        }
    }
    
    // 基本设置
    private var basicSettings: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("基本设置")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("3")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray6).opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                // 货币单位
                SettingsRow(
                    icon: "dollarsign.circle",
                    title: "货币单位",
                    value: currentSettings.currency
                ) {
                    CurrencyPickerView()
                }
                
                Divider()
                    .background(
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(.systemGray6).opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 1)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 16)
                
                // 记账提醒
                SettingsRow(
                    icon: "bell",
                    title: "记账提醒",
                    value: currentSettings.reminderEnabled ? "已开启" : "已关闭"
                ) {
                    ReminderSettingsView()
                }
                
                Divider()
                            .background(
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color(.systemGray6).opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 1)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 16)
                
                // 主题模式设置已隐藏
                // SettingsRow(
                //     icon: "moon",
                //     title: "主题模式",
                //     value: currentSettings.themeMode
                // ) {
                //     ThemePickerView()
                // }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6).opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    // 分类管理
    private var categoryManagement: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Image(systemName: "folder.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.orange)
                
                Text("分类管理")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(categories.count)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray6).opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                
                Button(action: {
                    showingAddCategory = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color(.systemGray6).opacity(0.2))
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                if categories.isEmpty {
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color(.systemGray6).opacity(0.2))
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(.orange)
                            )
                        
                        VStack(spacing: 8) {
                            Text("暂无自定义分类")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            Text("创建分类来更好地管理您的支出")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button("添加分类") {
                            showingAddCategory = true
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.8))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(categories, id: \.id) { category in
                        CategoryRow(
                            category: category,
                            onEdit: {
                                editingCategory = category
                            },
                            onDelete: {
                                deleteCategory(category)
                            }
                        )
                        
                        if category.id != categories.last?.id {
                            Divider()
                                .background(
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color(.systemGray6).opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 1)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                                .padding(.horizontal, 16)
                        }
                    }
                    
                    // 查看全部按钮
                    Button(action: {
                        showingCategoryManager = true
                    }) {
                        HStack {
                            Text("管理所有分类")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6).opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    // 账户管理
    private var accountSection: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.blue)
                
                Text("账户管理")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("2")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray6).opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                // 当前用户信息
                HStack(spacing: 12) {
                    Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    )
                    
                    Text("当前用户")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(authManager.currentUser?.username ?? "未知用户")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray6).opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                    .background(
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(.systemGray6).opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 1)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 16)
                
                // 注销按钮
                Button(action: {
                    showingLogoutAlert = true
                }) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            )
                        
                        Text("注销登录")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6).opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    // 关于信息
    private var aboutSection: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.green)
                
                Text("关于")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("4")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray6).opacity(0.2))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                // 应用LOGO
                HStack(spacing: 12) {
                    Image("app_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                    
                    Text("应用图标")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("蓝色麦克风")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray6).opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                    .background(
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(.systemGray6).opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 1)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 16)
                
                // 版本信息
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "info.circle")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        )
                    
                    Text("版本")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray6).opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                    .background(
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(.systemGray6).opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 1)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 16)
                
                // 隐私政策
                NavigationLink(destination: PrivacyPolicyView()) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "hand.raised")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            )
                        
                        Text("隐私政策")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                
                Divider()
                    .background(
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(.systemGray6).opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 1)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 16)
                
                // 用户协议
                NavigationLink(destination: TermsOfServiceView()) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "doc.text")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            )
                        
                        Text("用户协议")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6).opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    // 删除分类
    private func deleteCategory(_ category: ExpenseCategory) {
        withAnimation {
            modelContext.delete(category)
            try? modelContext.save()
        }
    }
}

// 设置行组件
struct SettingsRow<Destination: View>: View {
    let icon: String
    let title: String
    let value: String
    let destination: () -> Destination
    
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    )
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                if !value.isEmpty {
                    Text(value)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray6).opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// 分类行组件
struct CategoryRow: View {
    let category: ExpenseCategory
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingActionSheet = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            showingActionSheet = true
        }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(category.color)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: category.iconName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    )
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("分类")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if category.isDefault {
                    Text("默认")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6).opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.gray)
                }
                
                Circle()
                    .fill(Color(.systemGray6).opacity(0.2))
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .foregroundColor(.gray)
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})

        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text(category.name),
                buttons: category.isDefault ? [
                    .cancel(Text("取消"))
                ] : [
                    .default(Text("✏️ 编辑分类")) {
                        onEdit()
                    },
                    .destructive(Text("🗑️ 删除分类")) {
                        onDelete()
                    },
                    .cancel(Text("取消"))
                ]
            )
        }
    }
}



#Preview {
    SettingsView()
        .modelContainer(for: [ExpenseRecord.self, ExpenseCategory.self, AppSettings.self], inMemory: true)
}