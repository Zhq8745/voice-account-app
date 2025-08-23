//
//  ReminderSettingsView.swift
//  AiVC
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct ReminderSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]
    
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Date()
    
    private var currentSettings: AppSettings {
        settings.first ?? AppSettings()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // 开关设置
                    VStack(spacing: 0) {
                        HStack {
                            Text("记账提醒")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        
                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "bell")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                                    .frame(width: 24, height: 24)
                                
                                Text("启用提醒")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Toggle("", isOn: $reminderEnabled)
                                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                        )
                    }
                    
                    // 时间设置
                    if reminderEnabled {
                        VStack(spacing: 0) {
                            HStack {
                                Text("提醒时间")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                            
                            VStack(spacing: 0) {
                                HStack {
                                    Image(systemName: "clock")
                                        .font(.system(size: 18))
                                        .foregroundColor(.blue)
                                        .frame(width: 24, height: 24)
                                    
                                    Text("每日提醒时间")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                
                                Divider()
                                    .background(Color.gray.opacity(0.3))
                                    .padding(.horizontal, 16)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("提醒说明")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    Text("每天在设定时间提醒您记录当日支出，帮助养成良好的记账习惯。")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(nil)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                            )
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .navigationTitle("记账提醒")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("保存") {
                    saveSettings()
                }
                .foregroundColor(.blue)
            )
            .preferredColorScheme(.dark)
        }
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        let settings = currentSettings
        reminderEnabled = settings.reminderEnabled
        reminderTime = settings.reminderTime
    }
    
    private func saveSettings() {
        if let existingSettings = settings.first {
            existingSettings.reminderEnabled = reminderEnabled
            existingSettings.reminderTime = reminderTime
        } else {
            let newSettings = AppSettings()
            newSettings.reminderEnabled = reminderEnabled
            newSettings.reminderTime = reminderTime
            modelContext.insert(newSettings)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    ReminderSettingsView()
        .modelContainer(for: [AppSettings.self], inMemory: true)
}