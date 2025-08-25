//
//  PrivacyPolicyView.swift
//  AiVC
//
//  Created by Assistant on 2024/12/21.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var animationOffset: CGFloat = 0
    @State private var pulseAnimation: Bool = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 24) {

                
                // 隐私政策内容
                ScrollView {
                    VStack(spacing: 24) {
                            privacySection(
                                title: "信息收集",
                                icon: "doc.text.fill",
                                content: "我们收集您主动提供的信息，包括：\n\n• 支出记录数据（金额、分类、备注等）\n• 语音输入数据（仅用于转换为文本）\n• 应用使用偏好设置\n\n我们不会收集您的个人身份信息，如姓名、电话号码或邮箱地址。"
                            )
                            
                            privacySection(
                                title: "信息使用",
                                icon: "gear.circle.fill",
                                content: "我们使用收集的信息用于：\n\n• 提供核心记账功能\n• 生成支出分析和统计\n• 改善应用性能和用户体验\n• 提供个性化设置\n\n我们不会将您的数据用于广告投放或营销目的。"
                            )
                            
                            privacySection(
                                title: "数据存储",
                                icon: "externaldrive.fill",
                                content: "您的数据存储方式：\n\n• 本地存储：数据主要存储在您的设备上\n• 云同步：如启用，数据会加密同步到iCloud\n• 第三方服务：语音识别功能使用系统API\n\n我们采用行业标准的加密技术保护您的数据安全。"
                            )
                            
                            privacySection(
                                title: "数据共享",
                                icon: "person.2.fill",
                                content: "我们承诺：\n\n• 不会向第三方出售您的个人数据\n• 不会与广告商分享您的信息\n• 仅在法律要求时才会披露数据\n• 使用匿名化数据改善服务质量\n\n您的隐私是我们的首要关注。"
                            )
                            
                            privacySection(
                                title: "您的权利",
                                icon: "hand.raised.fill",
                                content: "您有权：\n\n• 随时删除您的所有数据\n• 导出您的数据\n• 关闭云同步功能\n• 禁用语音输入功能\n• 联系我们了解数据处理情况\n\n您可以在应用设置中管理这些选项。"
                            )
                            
                            privacySection(
                                title: "联系我们",
                                icon: "envelope.fill",
                                content: "如果您对本隐私政策有任何疑问或建议，请通过以下方式联系我们：\n\n• 应用内反馈功能\n• App Store评论\n• 开发者支持页面\n\n我们会在收到您的询问后尽快回复。"
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 25)
                    .padding(.bottom, 20)
                }
                
                Spacer()
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 && abs(value.translation.height) < 50 {
                        dismiss()
                    }
                }
        )
        .navigationTitle("隐私政策")
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
    }
    
    private func privacySection(title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.gray)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
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
                                colors: [Color.white.opacity(0.1), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            animationOffset = -5
        }
        
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }
}

#Preview {
    PrivacyPolicyView()
}