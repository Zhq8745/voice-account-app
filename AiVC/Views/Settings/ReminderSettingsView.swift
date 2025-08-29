//
//  ReminderSettingsView.swift
//  AiVC
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData
import UserNotifications

struct ReminderSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]
    
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    @State private var showingPermissionAlert = false
    @State private var animationOffset: CGFloat = 0
    @State private var pulseAnimation: Bool = false
    
    private var currentSettings: AppSettings {
        settings.first ?? AppSettings()
    }
    
    var body: some View {
        ZStack {
            // 深色背景
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // 提醒开关
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
                            .onChange(of: reminderEnabled) { _, newValue in
                                if newValue {
                                    saveSettings()
                                } else {
                                    saveSettings()
                                }
                            }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6).opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
                
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
                                    .onChange(of: reminderTime) { _, _ in
                                        saveSettings()
                                    }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            
                            Divider()
                                .background(Color(.systemGray6).opacity(0.3))
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
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6).opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
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
        .navigationTitle("记账提醒")
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
            loadCurrentSettings()
        }
        .alert("需要通知权限", isPresented: $showingPermissionAlert) {
            Button("去设置") {
                openAppSettings()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("请在设置中允许通知权限，以便接收记账提醒。")
        }
    }
    
    private func loadCurrentSettings() {
        reminderEnabled = currentSettings.reminderEnabled
        reminderTime = currentSettings.reminderTime
    }
    
    private func saveSettings() {
        if reminderEnabled {
            requestNotificationPermission { granted in
                DispatchQueue.main.async {
                    if granted {
                        updateSettings()
                        scheduleNotification()
                    } else {
                        showingPermissionAlert = true
                    }
                }
            }
        } else {
            updateSettings()
            cancelNotification()
        }
    }
    
    private func updateSettings() {
        let settingsToUpdate: AppSettings
        if let existingSettings = settings.first {
            settingsToUpdate = existingSettings
        } else {
            settingsToUpdate = AppSettings()
            modelContext.insert(settingsToUpdate)
        }
        
        settingsToUpdate.reminderEnabled = reminderEnabled
        settingsToUpdate.reminderTime = reminderTime
        
        do {
            try modelContext.save()
        } catch {
            print("保存提醒设置失败: \(error)")
        }
    }
    
    private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            completion(granted)
        }
    }
    
    private func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        
        // 取消现有通知
        center.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
        
        // 创建新通知
        let content = UNMutableNotificationContent()
        content.title = "记账提醒"
        content.body = "别忘了记录今天的支出哦！"
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("添加通知失败: \(error)")
            }
        }
    }
    
    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            openURL(settingsUrl)
        }
    }
}

#Preview {
    ReminderSettingsView()
        .modelContainer(for: [AppSettings.self], inMemory: true)
}