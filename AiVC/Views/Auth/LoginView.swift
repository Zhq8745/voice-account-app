//
//  LoginView.swift
//  语记
//
//  Created by AI Assistant on 2025/01/21.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // 顶部Logo区域
                    logoSection
                        .frame(height: geometry.size.height * 0.6)
                    
                    // Apple ID登录区域
                    appleSignInSection
                        .padding(.horizontal, 24)
                        .frame(height: geometry.size.height * 0.4)
                }
            }
            .background(Color.black)
            .overlay(
                // 装饰性背景元素
                ZStack {
                    // 装饰性元素已移除
                }
                .ignoresSafeArea()
            )
            .ignoresSafeArea(.all, edges: .top)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            // 检查是否有已保存的Apple登录状态
            checkSavedAppleSignInStatus()
        }
        .alert("登录失败", isPresented: $viewModel.showingError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("登录成功", isPresented: $viewModel.showingSuccess) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(viewModel.successMessage)
        }
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // App Logo
            Image("app_logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .shadow(color: Color.cyan.opacity(0.3), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 8) {
                // App Name
                Text("语记")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Color.white)
                
                Text("智能语音记账助手")
                    .font(.title3)
                    .foregroundColor(Color.white.opacity(0.8))
            }
            
            Spacer()
        }
    }
    
    // MARK: - Apple Sign In Section
    
    private var appleSignInSection: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("欢迎使用")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(Color.white.opacity(0.9))
                
                Text("使用您的 Apple ID 安全登录")
                    .font(.subheadline)
                    .foregroundColor(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Apple ID登录按钮
            Button(action: {
                Task {
                    await attemptAppleSignIn()
                }
            }) {
                HStack(spacing: 12) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "applelogo")
                            .font(.system(size: 18, weight: .medium))
                    }
                    
                    Text(viewModel.isLoading ? "登录中..." : "使用 Apple ID 登录")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.cyan)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.cyan.opacity(0.3), radius: 8, x: 0, y: 4)
                .scaleEffect(viewModel.isLoading ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: viewModel.isLoading)
            }
            .disabled(viewModel.isLoading)
            
            VStack(spacing: 8) {
                Text("安全 • 私密 • 便捷")
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.6))
                
                Text("您的隐私信息将受到 Apple 的保护")
                    .font(.caption2)
                    .foregroundColor(Color.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.top, 40)
    }
    
    // MARK: - Helper Methods
    
    private func attemptAppleSignIn() async {
        await viewModel.signInWithApple()
    }
    
    private func checkSavedAppleSignInStatus() {
        // 检查是否有保存的Apple用户标识符
        if let appleUserIdentifier = KeychainManager.shared.getAppleUserIdentifier() {
            Task {
                // 验证Apple登录状态
                let credentialState = await AppleSignInService.shared.checkAppleSignInStatus(for: appleUserIdentifier)
                
                DispatchQueue.main.async {
                    switch credentialState {
                    case .authorized:
                        // Apple登录状态有效，通过AuthenticationManager恢复登录状态
                        Task {
                            await AuthenticationManager.shared.checkAuthenticationStatus()
                        }
                    case .revoked, .notFound:
                        // Apple登录状态无效，清除相关数据
                        KeychainManager.shared.clearAppleUserInfo()
                    case .transferred:
                        // 账户已转移，清除相关数据
                        KeychainManager.shared.clearAppleUserInfo()
                    @unknown default:
                        // 未知状态，清除相关数据
                        KeychainManager.shared.clearAppleUserInfo()
                    }
                }
            }
        }
    }
}





// MARK: - Preview

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}