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
                        .padding(.horizontal, 32)
                        .frame(height: geometry.size.height * 0.4)
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color.gray.opacity(0.9)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea(.all, edges: .top)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .toolbar(.hidden, for: .tabBar)
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
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 120))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .blue.opacity(0.3), radius: 20, x: 0, y: 10)
            
            VStack(spacing: 8) {
                // App Name
                Text("语记")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("智能语音记账助手")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
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
                    .foregroundColor(.white.opacity(0.9))
                
                Text("使用您的 Apple ID 安全登录")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
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
                            .font(.system(size: 20, weight: .medium))
                    }
                    
                    Text(viewModel.isLoading ? "登录中..." : "使用 Apple ID 登录")
                        .font(.system(size: 18, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .foregroundColor(.black)
                .scaleEffect(viewModel.isLoading ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: viewModel.isLoading)
            }
            .disabled(viewModel.isLoading)
            
            VStack(spacing: 8) {
                Text("安全 • 私密 • 便捷")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                Text("您的隐私信息将受到 Apple 的保护")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
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
}





// MARK: - Preview

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}