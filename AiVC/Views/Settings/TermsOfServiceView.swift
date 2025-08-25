//
//  TermsOfServiceView.swift
//  AiVC
//
//  Created by Assistant on 2024/12/21.
//

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var animationOffset: CGFloat = 0
    @State private var pulseAnimation: Bool = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 24) {

                        
                // 用户协议内容
                ScrollView {
                    VStack(spacing: 24) {
                        termsSection(
                            title: "服务条款",
                            icon: "checkmark.seal.fill",
                            content: "欢迎使用AI语音记账应用。通过下载、安装或使用本应用，您同意遵守以下条款：\n\n• 本应用仅供个人记账使用\n• 禁止将应用用于非法目的\n• 用户对其账户安全负责\n• 我们保留修改服务的权利\n\n请仔细阅读并理解这些条款。"
                        )
                        
                        termsSection(
                            title: "使用许可",
                            icon: "key.fill",
                            content: "我们授予您有限的、非独占的、不可转让的许可来使用本应用：\n\n• 仅限个人非商业用途\n• 不得逆向工程或反编译\n• 不得复制或分发应用\n• 不得修改应用代码\n\n违反许可条款将导致使用权终止。"
                        )
                        
                        termsSection(
                            title: "用户责任",
                            icon: "person.fill.checkmark",
                            content: "作为用户，您需要：\n\n• 提供准确的记账信息\n• 保护您的设备和账户安全\n• 遵守当地法律法规\n• 不滥用应用功能\n• 及时更新应用版本\n\n您对使用应用产生的后果承担全部责任。"
                        )
                        
                        termsSection(
                            title: "服务可用性",
                            icon: "wifi.circle.fill",
                            content: "关于服务可用性：\n\n• 我们努力保持服务稳定运行\n• 可能因维护而暂时中断服务\n• 不保证服务100%可用\n• 第三方服务可能影响功能\n• 网络问题可能影响同步\n\n我们会尽力提前通知重大服务变更。"
                        )
                        
                        termsSection(
                            title: "免责声明",
                            icon: "exclamationmark.triangle.fill",
                            content: "本应用按\"现状\"提供，我们不承担以下责任：\n\n• 数据丢失或损坏\n• 服务中断造成的损失\n• 第三方服务的问题\n• 设备兼容性问题\n• 用户操作错误\n\n请定期备份重要数据。"
                        )
                        
                        termsSection(
                            title: "协议变更",
                            icon: "arrow.triangle.2.circlepath",
                            content: "我们可能会更新本协议：\n\n• 重大变更会通过应用通知\n• 继续使用表示接受新条款\n• 建议定期查看协议内容\n• 不同意变更可停止使用\n\n最新版本的协议始终在应用内可查看。"
                        )
                        
                        termsSection(
                            title: "争议解决",
                            icon: "scale.3d",
                            content: "如发生争议：\n\n• 优先通过友好协商解决\n• 适用中华人民共和国法律\n• 由开发者所在地法院管辖\n• 保留追究法律责任的权利\n\n我们致力于公平合理地解决任何问题。"
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
        .navigationTitle("用户协议")
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
    
    private func termsSection(title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.green, Color.mint],
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
    TermsOfServiceView()
}