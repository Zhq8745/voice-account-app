//
//  ThemePickerView.swift
//  AiVC
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct ThemePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]
    
    private var currentSettings: AppSettings {
        settings.first ?? AppSettings()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                List {
                    ForEach(["自动", "浅色", "深色"], id: \.self) { theme in
                        Button(action: {
                            updateTheme(theme)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(theme)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    Text(getThemeDescription(theme))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                if currentSettings.themeMode == theme {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowBackground(Color(red: 0.11, green: 0.11, blue: 0.12))
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("主题模式")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    private func getThemeDescription(_ theme: String) -> String {
        switch theme {
        case "自动":
            return "跟随系统设置"
        case "浅色":
            return "始终使用浅色主题"
        case "深色":
            return "始终使用深色主题"
        default:
            return ""
        }
    }
    
    private func updateTheme(_ theme: String) {
        if let existingSettings = settings.first {
            existingSettings.themeMode = theme
        } else {
            let newSettings = AppSettings()
            newSettings.themeMode = theme
            modelContext.insert(newSettings)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    ThemePickerView()
        .modelContainer(for: [AppSettings.self], inMemory: true)
}