//
//  SettingsView.swift
//  AiVC
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]
    @Query private var categories: [ExpenseCategory]
    
    @State private var showingCategoryManager = false
    @State private var showingAddCategory = false
    @State private var editingCategory: ExpenseCategory?
    @State private var showingAPIKeyDiagnostic = false
    // @State private var showingAPIKeyConfig = false // 已移除API密钥配置
    @State private var diagnosticResult = ""
    
    // 动画状态
    @State private var pulseAnimation = false
    @State private var cardScale: CGFloat = 0.95
    @State private var listAnimation = false
    
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
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.1),
                                Color.clear
                            ]),
                            center: .topTrailing,
                            startRadius: 50,
                            endRadius: 200
                        )
                    )
                    .frame(width: 300, height: 300)
                    .position(x: UIScreen.main.bounds.width - 50, y: 100)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 3.0)
                            .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.purple.opacity(0.08),
                                Color.clear
                            ]),
                            center: .bottomLeading,
                            startRadius: 30,
                            endRadius: 150
                        )
                    )
                    .frame(width: 200, height: 200)
                    .position(x: 50, y: UIScreen.main.bounds.height - 200)
                    .scaleEffect(pulseAnimation ? 0.9 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.5)
                            .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
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
                                    .delay(0.2),
                                value: listAnimation
                            )
                        
                        // 调试设置
                        debugSettings
                            .scaleEffect(cardScale)
                            .opacity(listAnimation ? 1 : 0)
                            .animation(
                                Animation.spring(response: 0.8, dampingFraction: 0.8)
                                    .delay(0.25),
                                value: listAnimation
                            )
                        
                        // 关于信息
                        aboutSection
                            .scaleEffect(cardScale)
                            .opacity(listAnimation ? 1 : 0)
                            .animation(
                                Animation.spring(response: 0.8, dampingFraction: 0.8)
                                    .delay(0.3),
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
            .onAppear {
                startAnimations()
            }
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
        .sheet(isPresented: $showingAPIKeyDiagnostic) {
            APIKeyDiagnosticView(diagnosticResult: $diagnosticResult)
        }
        // API密钥配置已移除，开发者统一配置
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
                            .fill(Color.gray.opacity(0.2))
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
                        LinearGradient(
                            colors: [Color.clear, Color.gray.opacity(0.3), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
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
                        LinearGradient(
                            colors: [Color.clear, Color.gray.opacity(0.3), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.horizontal, 16)
                
                // 主题模式
                SettingsRow(
                    icon: "moon",
                    title: "主题模式",
                    value: currentSettings.themeMode
                ) {
                    ThemePickerView()
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.12, blue: 0.15),
                                Color(red: 0.08, green: 0.08, blue: 0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.1),
                                        Color.clear,
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(0.3),
                        radius: 10,
                        x: 0,
                        y: 5
                    )
            )
        }
    }
    
    // 分类管理
    private var categoryManagement: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Image(systemName: "folder.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
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
                            .fill(Color.gray.opacity(0.2))
                    )
                
                Button(action: {
                    showingAddCategory = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                if categories.isEmpty {
                    VStack(spacing: 16) {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.orange.opacity(0.3),
                                        Color.orange.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.orange, Color.red],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
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
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
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
                                    LinearGradient(
                                        colors: [Color.clear, Color.gray.opacity(0.3), Color.clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
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
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.blue, Color.cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
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
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.12, blue: 0.15),
                                Color(red: 0.08, green: 0.08, blue: 0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.1),
                                        Color.clear,
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(0.3),
                        radius: 10,
                        x: 0,
                        y: 5
                    )
            )
        }
    }
    
    // 关于信息
    private var aboutSection: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.green, Color.mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("关于")
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
                            .fill(Color.gray.opacity(0.2))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                // 版本信息
                HStack(spacing: 12) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
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
                                .fill(Color.gray.opacity(0.2))
                        )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                    .background(
                        LinearGradient(
                            colors: [Color.clear, Color.gray.opacity(0.3), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.horizontal, 16)
                
                // 隐私政策
                HStack(spacing: 12) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
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
                
                Divider()
                    .background(
                        LinearGradient(
                            colors: [Color.clear, Color.gray.opacity(0.3), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.horizontal, 16)
                
                // 用户协议
                HStack(spacing: 12) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
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
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.12, blue: 0.15),
                                Color(red: 0.08, green: 0.08, blue: 0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.1),
                                        Color.clear,
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(0.3),
                        radius: 10,
                        x: 0,
                        y: 5
                    )
            )
        }
    }
    
    // 删除分类
    private func deleteCategory(_ category: ExpenseCategory) {
        withAnimation {
            modelContext.delete(category)
            try? modelContext.save()
        }
    }
    
    // 调试设置
    private var debugSettings: some View {
        VStack(spacing: 0) {
            // 标题
            HStack {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("调试设置")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("1")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                // API密钥诊断
                Button(action: {
                    APIKeyDiagnostic.runDiagnostic()
                    showingAPIKeyDiagnostic = true
                }) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "key.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            )
                        
                        Text("API密钥诊断")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("检查配置")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.gray.opacity(0.2))
                            )
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.12, blue: 0.15),
                                Color(red: 0.08, green: 0.08, blue: 0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.1),
                                        Color.clear,
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(0.3),
                        radius: 10,
                        x: 0,
                        y: 5
                    )
            )
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
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
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
                                .fill(Color.gray.opacity(0.2))
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
    @State private var iconScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            showingActionSheet = true
        }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                category.color,
                                category.color.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .overlay(
                        Image(systemName: category.iconName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .scaleEffect(iconScale)
                    )
                    .shadow(
                        color: category.color.opacity(0.3),
                        radius: 4,
                        x: 0,
                        y: 2
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
                                .fill(Color.gray.opacity(0.3))
                        )
                        .foregroundColor(.gray)
                }
                
                Circle()
                    .fill(Color.gray.opacity(0.2))
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
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                iconScale = 1.1
            }
        }
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