//
//  CurrencyPickerView.swift
//  AiVC
//
//  Created by AI Assistant
//

import SwiftUI
import SwiftData

struct CurrencyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]
    
    @State private var selectedCurrency: String = "CNY"
    // @State private var pulseAnimation = false // 已移除动画状态
    
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
            // 深色背景
            Color.black
                .ignoresSafeArea()
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            // 检测右滑手势
                            if value.translation.width > 100 && abs(value.translation.height) < 50 {
                                dismiss()
                            }
                        }
                )
                
                VStack(spacing: 24) {
                    // 货币列表
                    VStack(spacing: 0) {
                        ForEach(Array(AppSettings.currencies.enumerated()), id: \.offset) { index, currency in
                            let (code, name, symbol) = currency
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    selectedCurrency = code
                                    updateCurrency(code)
                                }
                            }) {
                                HStack(spacing: 16) {
                                    // 货币符号
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: selectedCurrency == code ? 
                                                    [Color.green, Color.mint] : 
                                                    [Color(.systemGray6).opacity(0.3), Color(.systemGray6).opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Text(symbol)
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(selectedCurrency == code ? .white : .gray)
                                        )
                                        .scaleEffect(selectedCurrency == code ? 1.1 : 1.0)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(name)
                                            .font(.headline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        Text(code)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    // 选中状态
                                    if selectedCurrency == code {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [Color.green, Color.mint],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            selectedCurrency == code ?
                                                LinearGradient(
                                                    colors: [
                                                        Color.green.opacity(0.1),
                                                        Color.mint.opacity(0.05)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ) :
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
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    selectedCurrency == code ?
                                                        LinearGradient(
                                                            colors: [Color.green.opacity(0.3), Color.mint.opacity(0.2)],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ) :
                                                        LinearGradient(
                                                            colors: [Color.white.opacity(0.1), Color.clear],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ),
                                                    lineWidth: 1
                                                )
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if index < AppSettings.currencies.count - 1 {
                                Divider()
                                    .background(Color(.systemGray6).opacity(0.2))
                                    .padding(.horizontal, 20)
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
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
            }
            .navigationTitle("货币单位")
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
            .toolbar(.hidden, for: .tabBar)
            .preferredColorScheme(.dark)
            .onAppear {
                selectedCurrency = currentSettings.currency
            }
    }
    
    // private func startAnimations() {
    //     withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
    //         pulseAnimation = true
    //     }
    // } // 已移除动画函数
    
    private func updateCurrency(_ currency: String) {
        currentSettings.currency = currency
        
        do {
            try modelContext.save()
            
            // 延迟关闭以显示选中动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismiss()
            }
        } catch {
            print("保存货币设置失败: \(error)")
        }
    }
}

#Preview {
    CurrencyPickerView()
        .modelContainer(for: [AppSettings.self], inMemory: true)
}