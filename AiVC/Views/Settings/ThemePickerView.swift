//
//  ThemePickerView.swift
//  AiVC
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData
import Foundation

struct ThemePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]
    
    @State private var selectedTheme: String = "system"
    
    private var currentSettings: AppSettings {
        settings.first ?? AppSettings()
    }
    
    private let themes: [(String, String, String, String)] = [
        ("system", "跟随系统", "自动切换明暗主题", "gear.circle.fill"),
        ("light", "浅色模式", "始终使用浅色主题", "sun.max.circle.fill"),
        ("dark", "深色模式", "始终使用深色主题", "moon.circle.fill")
    ]
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // 主题图标和标题
                VStack(spacing: 16) {
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.pink)
                    
                    VStack(spacing: 8) {
                        Text("主题设置")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("选择您喜欢的主题模式")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 50)
                
                // 主题选项
                VStack(spacing: 16) {
                    ForEach(Array(themes.enumerated()), id: \.offset) { index, theme in
                        ThemeOptionRow(
                            theme: theme,
                            isSelected: selectedTheme == theme.0,
                            onTap: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    selectedTheme = theme.0
                                    updateTheme(theme.0)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 && abs(value.translation.height) < 50 {
                        dismiss()
                    }
                }
        )
        .navigationTitle("主题设置")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("设置")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .toolbarBackground(.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .preferredColorScheme(.dark)
        .onAppear {
            selectedTheme = currentSettings.themeMode
        }
    }
    
    private func updateTheme(_ theme: String) {
        let settingsToUpdate: AppSettings
        if let existingSettings = settings.first {
            settingsToUpdate = existingSettings
        } else {
            settingsToUpdate = AppSettings()
            modelContext.insert(settingsToUpdate)
        }
        
        settingsToUpdate.themeMode = theme
        
        do {
            try modelContext.save()
            
            // 延迟关闭以显示选中动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismiss()
            }
        } catch {
            print("保存主题设置失败: \(error)")
        }
    }
}

struct ThemeOptionRow: View {
    let theme: (String, String, String, String)
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 主题图标
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isSelected ? 
                                getThemeColors(theme.0) : 
                                [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: theme.3)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(isSelected ? .white : .gray)
                    )
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(theme.1)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(theme.2)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // 选中状态
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.blue)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                            Color.blue.opacity(0.1) :
                            Color(red: 0.12, green: 0.12, blue: 0.15)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ?
                                    Color.blue.opacity(0.3) :
                                    Color.white.opacity(0.1),
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private func getThemeColors(_ theme: String) -> [Color] {
    switch theme {
    case "light":
        return [.orange, .yellow]
    case "dark":
        return [.purple, .blue]
    default: // system
        return [.green, .blue]
    }
}

#Preview {
    ThemePickerView()
        .modelContainer(for: [AppSettings.self], inMemory: true)
}