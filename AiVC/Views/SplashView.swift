//
//  SplashView.swift
//  AiVC
//
//  Created by Assistant on 2025/1/21.
//

import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var opacity = 0.0
    
    var body: some View {
        ZStack {
            // 背景
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App Logo
                Image("app_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false), value: isAnimating)
                
                VStack(spacing: 12) {
                    Text("AI语音记账")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(opacity)
                    
                    Text("智能语音，轻松记账")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(opacity)
                }
                
                // 加载指示器
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    Text("正在启动...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(opacity)
                }
                .padding(.top, 40)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                opacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: 1.5).delay(0.5)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    SplashView()
}