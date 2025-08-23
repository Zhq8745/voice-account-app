//
//  VoiceInputView.swift
//  AiVC
//
//  Created by AI Assistant on 2025/01/21.
//

import SwiftUI
import SwiftData
import AVFoundation
import Foundation

// 导入必要的模型和服务
// 确保所有必要的类型都能被正确识别

// 工作流程状态枚举
enum VoiceWorkflowState {
    case idle           // 空闲状态
    case recording      // 录制中
    case analyzing      // AI分析中
    case editing        // 账单编辑确认
    case saving         // 保存中
    case completed      // 完成
}

struct VoiceInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [ExpenseCategory]
    @StateObject private var speechService = SpeechRecognitionService()
    @StateObject private var hybridParsingService = HybridParsingService()
    
    // 工作流程状态管理
    @State private var workflowState: VoiceWorkflowState = .idle
    @State private var analysisProgress: Double = 0.0
    
    // 原有状态变量
    @State private var isRecording = false
    @State private var recognizedText = ""
    @State private var parsedExpense: (amount: Double?, category: String?, note: String?) = (nil, nil, nil)
    @State private var parseResult: SpeechRecognitionResult?
    @State private var showingConfirmation = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var animationScale: CGFloat = 1.0
    @State private var pulseAnimation = false
    
    // 账单编辑状态
    @State private var editableAmount: String = ""
    @State private var editableCategory: String = ""
    @State private var editableNote: String = ""
    
    // AI解析结果相关状态
    @State private var parseConfidence: Double = 0.0
    @State private var parseSource: ParseSource = .local
    @State private var aiSuggestions: [String] = []
    @State private var selectedCategoryIndex: Int = 0
    
    // 计算属性：安全的进度值
    private var safeProgressValue: Double {
        if parseConfidence.isNaN || parseConfidence.isInfinite {
            return 0.0
        }
        return min(max(parseConfidence, 0.0), 1.0)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.95),
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.1),
                        Color.black.opacity(0.95)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // 装饰性背景元素
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.1),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .offset(
                            x: CGFloat.random(in: -geometry.size.width/2...geometry.size.width/2),
                            y: CGFloat.random(in: -geometry.size.height/2...geometry.size.height/2)
                        )
                        .animation(
                            .easeInOut(duration: Double.random(in: 3...6))
                            .repeatForever(autoreverses: true),
                            value: pulseAnimation
                        )
                }
                
                VStack(spacing: 20) {
                    // 顶部导航
                    getTopNavigation()
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 0)
                    
                    Spacer(minLength: 20)
                    
                    // 主要内容区域
                     Group {
                         switch workflowState {
                         case .idle:
                             getIdleView()
                                 .transition(
                                     .asymmetric(
                                         insertion: .scale(scale: 0.8).combined(with: .opacity),
                                         removal: .scale(scale: 1.2).combined(with: .opacity)
                                     )
                                 )
                         case .recording:
                             getRecordingView()
                                 .transition(
                                     .asymmetric(
                                         insertion: .scale(scale: 0.8).combined(with: .opacity),
                                         removal: .scale(scale: 0.8).combined(with: .opacity)
                                     )
                                 )
                         case .analyzing:
                             getAnalyzingView()
                                 .transition(
                                     .asymmetric(
                                         insertion: .move(edge: .bottom).combined(with: .opacity),
                                         removal: .move(edge: .top).combined(with: .opacity)
                                     )
                                 )
                         case .editing:
                             getEditingView()
                                 .transition(
                                     .asymmetric(
                                         insertion: .move(edge: .bottom).combined(with: .scale(scale: 0.9)),
                                         removal: .move(edge: .bottom).combined(with: .opacity)
                                     )
                                 )
                         case .saving, .completed:
                             getStatusView()
                                 .transition(
                                     .asymmetric(
                                         insertion: .scale(scale: 0.8).combined(with: .opacity),
                                         removal: .scale(scale: 0.8).combined(with: .opacity)
                                     )
                                 )
                         }
                     }
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.2),
                        value: workflowState
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            startPulseAnimation()
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }
    
    // MARK: - UI组件方法
    @ViewBuilder
    private func getTopNavigation() -> some View {
        HStack {
            Spacer()
            
            Text("语音记账")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            // 占位符保持对称
            Color.clear
                .frame(width: 28, height: 28)
        }
        .padding(.horizontal, 20)
        .padding(.top, 5)
    }
    
    @ViewBuilder
    private func getIdleView() -> some View {
        VStack(spacing: 25) {
            // 状态信息
            VStack(spacing: 12) {
                Image(systemName: "waveform.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.cyan)
                    .opacity(0.8)
                
                Text("点击开始语音记账")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("说出金额、类别和备注信息")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // 麦克风按钮
            getMicrophoneButton()
        }
    }
    
    @ViewBuilder
    private func getRecordingView() -> some View {
        VStack(spacing: 20) {
            // 状态文本
            VStack(spacing: 8) {
                Text("正在录制...")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("请清楚地说出您的账单信息")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // 增强的声波可视化效果
            HStack(spacing: 6) {
                ForEach(0..<7) { index in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.red.opacity(0.9),
                                    Color.orange.opacity(0.7)
                                ]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 5, height: CGFloat.random(in: 15...80))
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 0.3...0.8))
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.08),
                            value: pulseAnimation
                        )
                        .shadow(color: .red.opacity(0.3), radius: 2, x: 0, y: 1)
                }
            }
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 40)
            
            // 麦克风按钮
            getMicrophoneButton()
            
            // 实时识别文本
            if !recognizedText.isEmpty {
                Text(recognizedText)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .transition(.opacity.combined(with: .scale))
            }
        }
    }
    
    @ViewBuilder
    private func getAnalyzingView() -> some View {
        VStack(spacing: 30) {
            // AI分析图标
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: pulseAnimation
                )
            
            // 状态文本
            VStack(spacing: 8) {
                Text("AI分析中...")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("正在理解您的语音内容")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                // 显示AI服务状态
                Text(hybridParsingService.aiServiceStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 进度条
            VStack(spacing: 12) {
                ProgressView(value: analysisProgress.isNaN || analysisProgress.isInfinite ? 0.0 : min(max(analysisProgress, 0.0), 1.0))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(width: 240)
                    .scaleEffect(y: 2)
                
                let progressValue = analysisProgress.isNaN || analysisProgress.isInfinite ? 0.0 : min(max(analysisProgress, 0.0), 1.0)
                Text(String(format: "%.0f%%", progressValue * 100))
                    .font(.caption)
                    .foregroundColor(.blue.opacity(0.8))
            }
            
            // 显示降级提示
            if let errorMessage = hybridParsingService.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 20)
            }
            
            // 识别的文字显示
            if !recognizedText.isEmpty {
                Text(recognizedText)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
        }
    }
    
    @ViewBuilder
    private func getEditingView() -> some View {
        getBillEditingView()
    }
    
    @ViewBuilder
    private func getStatusView() -> some View {
        VStack(spacing: 30) {
            // 状态图标
            getStatusIcon()
                .font(.system(size: 60))
                .foregroundColor(getStatusColor())
                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: pulseAnimation
                )
            
            // 状态文本
            VStack(spacing: 8) {
                Text(getStatusTitle())
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                if workflowState == .saving {
                    Text("请稍候...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                } else if workflowState == .completed {
                    Text("账单已成功保存")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            // 完成状态的按钮
            if workflowState == .completed {
                Button("继续记账") {
                    resetToIdle()
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 10)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - 辅助方法
    private func getConfidenceColor() -> Color {
        if parseConfidence >= 0.8 {
            return .green
        } else if parseConfidence >= 0.6 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private func getConfidenceText() -> String {
        if parseConfidence >= 0.8 {
            return "高"
        } else if parseConfidence >= 0.6 {
            return "中"
        } else {
            return "低"
        }
    }
    
     private func getStatusIcon() -> Image {
         switch workflowState {
         case .idle:
             return Image(systemName: "mic.circle")
         case .recording:
             return Image(systemName: "waveform.circle.fill")
         case .analyzing:
             return Image(systemName: "brain.head.profile")
         case .editing:
             return Image(systemName: "pencil.circle")
         case .saving:
             return Image(systemName: "arrow.up.circle")
         case .completed:
             return Image(systemName: "checkmark.circle.fill")
         }
     }
     
     private func getStatusColor() -> Color {
         switch workflowState {
         case .idle:
             return .gray
         case .recording:
             return .red
         case .analyzing:
             return .blue
         case .editing:
             return .orange
         case .saving:
             return .yellow
         case .completed:
             return .green
         }
     }
     
     private func getStatusTitle() -> String {
         switch workflowState {
         case .idle:
             return "请输入语音记录"
         case .recording:
             return "正在录音..."
         case .analyzing:
             return "AI分析中..."
         case .editing:
             return "请确认账单信息"
         case .saving:
             return "正在保存..."
         case .completed:
             return "保存成功！"
         }
     }
      
      @ViewBuilder
     private func getStatusMessage() -> some View {
        VStack(spacing: 20) {
            // 状态图标和标题
            HStack(spacing: 12) {
                getStatusIcon()
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(getStatusColor())
                
                Text(getStatusTitle())
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                getStatusColor().opacity(0.15),
                                getStatusColor().opacity(0.05)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(getStatusColor().opacity(0.3), lineWidth: 1)
                    )
            )
            
            // AI分析进度条
            if workflowState == .analyzing {
                VStack(spacing: 12) {
                    ProgressView(value: analysisProgress.isNaN || analysisProgress.isInfinite ? 0.0 : min(max(analysisProgress, 0.0), 1.0))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(width: 240)
                        .scaleEffect(y: 2)
                    
                    Text("正在分析语音内容...")
                        .font(.caption)
                        .foregroundColor(.blue.opacity(0.8))
                }
                .padding(.top, 8)
            }
            
            // 识别的文字显示
            if !recognizedText.isEmpty && workflowState != .editing {
                Text(recognizedText)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .transition(.opacity.combined(with: .scale))
            }
        }
    }
    

    
    @ViewBuilder
    private func getMicrophoneButton() -> some View {
        Button(action: {
            handleMicrophoneAction()
        }) {
            ZStack {
                // 最外层声波动画（录音时）
                if workflowState == .recording {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .stroke(
                                Color.red.opacity(0.4 - Double(index) * 0.08),
                                lineWidth: 2
                            )
                            .frame(width: 160 + CGFloat(index * 25), height: 160 + CGFloat(index * 25))
                            .scaleEffect(pulseAnimation ? 1.4 : 0.7)
                            .opacity(pulseAnimation ? 0.05 : 0.7)
                            .animation(
                                .easeInOut(duration: 1.2 + Double(index) * 0.2)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.15),
                                value: pulseAnimation
                            )
                    }
                }
                
                // 外圈装饰环
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                getMicrophoneColor().opacity(0.8),
                                getMicrophoneColor().opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 150, height: 150)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .opacity(pulseAnimation ? 0.6 : 0.9)
                
                // 中间渐变圆圈
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                getMicrophoneColor().opacity(0.4),
                                getMicrophoneColor().opacity(0.1),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 130, height: 130)
                    .scaleEffect(animationScale)
                
                // 主按钮
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                getMicrophoneColor().opacity(0.8),
                                getMicrophoneColor().opacity(0.5)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                    .scaleEffect(animationScale)
                    .overlay(
                        Circle()
                            .stroke(
                                Color.white.opacity(0.3),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: getMicrophoneColor().opacity(0.5),
                        radius: 20,
                        x: 0,
                        y: 8
                    )
                
                // 麦克风图标或其他状态图标
                getMicrophoneIcon()
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                    .scaleEffect(animationScale * (workflowState == .recording ? 1.1 : 1.0))
                    .animation(.easeInOut(duration: 0.3), value: workflowState)
            }
        }
        .disabled(!canInteractWithMicrophone())
        .scaleEffect(animationScale)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animationScale)
        .padding(.vertical, 20)
        .onLongPressGesture(minimumDuration: 0) {
            // 长按结束
            addHapticFeedback()
        } onPressingChanged: { pressing in
            if canInteractWithMicrophone() {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    animationScale = pressing ? 0.92 : 1.0
                }
                if pressing {
                    addHapticFeedback()
                }
            }
        }
    }
    
    // 添加触觉反馈
    private func addHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - 工作流程管理方法
    private func handleMicrophoneAction() {
        switch workflowState {
        case .idle:
            startRecording()
        case .recording:
            stopRecording()
        case .editing:
            // 在编辑状态下，麦克风按钮可以重新录音
            resetToRecording()
        default:
            break
        }
    }
    
    private func getMicrophoneColor() -> Color {
        switch workflowState {
        case .idle:
            return .gray
        case .recording:
            return .red
        case .analyzing:
            return .blue
        case .editing:
            return .green
        case .saving:
            return .orange
        case .completed:
            return .green
        }
    }
    
    private func getMicrophoneIcon() -> Image {
        switch workflowState {
        case .idle:
            return Image(systemName: "mic")
        case .recording:
            return Image(systemName: "mic.fill")
        case .analyzing:
            return Image(systemName: "brain.head.profile")
        case .editing:
            return Image(systemName: "pencil")
        case .saving:
            return Image(systemName: "arrow.up.doc")
        case .completed:
            return Image(systemName: "checkmark")
        }
    }
    
    private func canInteractWithMicrophone() -> Bool {
        switch workflowState {
        case .idle, .recording, .editing:
            return true
        case .analyzing, .saving, .completed:
            return false
        }
    }
    

    
    @ViewBuilder
    private func getBillEditingView() -> some View {
        VStack(spacing: 18) {
            // 编辑表单
            VStack(spacing: 18) {
                    // 金额输入
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 14) {
                            Image(systemName: "yensign.circle")
                                .foregroundColor(.green)
                                .font(.system(size: 20, weight: .semibold))
                            Text("金额")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.bottom, 6)
                        
                        TextField("0.00", text: $editableAmount)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.white.opacity(0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color.green.opacity(0.7), lineWidth: 2)
                                    )
                            )
                            .shadow(color: .green.opacity(0.15), radius: 6, x: 0, y: 3)
                    }
                    
                    // 类别选择
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 14) {
                            Image(systemName: "tag.circle")
                                .foregroundColor(.blue)
                                .font(.system(size: 20, weight: .semibold))
                            Text("类别")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.bottom, 6)
                        
                        Menu {
                            ForEach(categories, id: \.id) { category in
                                Button(category.name) {
                                    editableCategory = category.name
                                }
                            }
                        } label: {
                            HStack(spacing: 18) {
                                Text(editableCategory.isEmpty ? "选择类别" : editableCategory)
                                    .foregroundColor(editableCategory.isEmpty ? .gray.opacity(0.7) : .white)
                                    .font(.system(size: 17, weight: .medium))
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.blue.opacity(0.8))
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .padding(.horizontal, 22)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.white.opacity(0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color.blue.opacity(0.7), lineWidth: 2)
                                    )
                            )
                            .shadow(color: .blue.opacity(0.15), radius: 6, x: 0, y: 3)
                        }
                    }
                    
                    // 备注输入
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 14) {
                            Image(systemName: "note.text")
                                .foregroundColor(.orange)
                                .font(.system(size: 20, weight: .semibold))
                            Text("备注")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.bottom, 6)
                        
                        Text(recognizedText.isEmpty ? "暂无语音识别内容" : recognizedText)
                            .font(.system(size: 16, weight: .medium))
                            .lineSpacing(6)
                            .foregroundColor(recognizedText.isEmpty ? .gray.opacity(0.7) : .white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .frame(minHeight: 80, maxHeight: 120)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white.opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.orange.opacity(0.7), lineWidth: 2)
                                )
                        )
                        .shadow(color: .orange.opacity(0.15), radius: 6, x: 0, y: 3)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // 如果有错误信息，显示重试按钮
                if !errorMessage.isEmpty {
                    Button("重新解析") {
                        retryAIAnalysis()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.orange.opacity(0.18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.orange.opacity(0.6), lineWidth: 1.5)
                            )
                    )
                    .shadow(color: .orange.opacity(0.1), radius: 4, x: 0, y: 2)
                    .padding(.horizontal, 24)
                }
                
                // 操作按钮
                VStack(spacing: 16) {
                    // 保存按钮
                    Button("保存账单") {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        saveBill()
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green.opacity(0.95), Color.green]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(18)
                    .shadow(color: .green.opacity(0.5), radius: 15, x: 0, y: 8)
                    
                    // 取消按钮
                    Button("取消") {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        resetToIdle()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                            )
                    )
                    .shadow(color: .white.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - 录音相关方法
    private func startRecording() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
            workflowState = .recording
        }
        isRecording = true
        recognizedText = ""
        parsedExpense = (nil, nil, nil)
        
        speechService.startRecording()
        
        // 开始脉冲动画
        withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
        
        // 监听识别结果的变化
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.monitorRecognition()
        }
    }
    
    private func monitorRecognition() {
        guard isRecording else { return }
        
        recognizedText = speechService.recognizedText
        
        if let error = speechService.errorMessage {
            isRecording = false
            errorMessage = error
            showingError = true
            return
        }
        
        // 继续监听
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.monitorRecognition()
        }
    }
    
    private func stopRecording() {
        speechService.stopRecording()
        isRecording = false
        
        // 停止脉冲动画
        withAnimation(.easeOut(duration: 0.3)) {
            pulseAnimation = false
        }
        
        // 如果识别内容，启动AI分析
        if !recognizedText.isEmpty {
            startAIAnalysis()
        } else {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                workflowState = .idle
            }
        }
    }
    
    // MARK: - AI分析相关方法
    private func startAIAnalysis() {
        withAnimation(.easeInOut(duration: 0.4)) {
            workflowState = .analyzing
        }
        analysisProgress = 0.0
        errorMessage = "" // 清除之前的错误信息
        
        // 使用HybridParsingService进行实际AI分析
        Task {
            let parseResult = await hybridParsingService.parseExpenseText(recognizedText)
            
            await MainActor.run {
                let result = SpeechRecognitionResult(
                    text: recognizedText,
                    amount: parseResult.amount,
                    category: parseResult.category,
                    note: parseResult.note,
                    confidence: Double(parseResult.confidence),
                    parseSource: parseResult.source,
                    aiSuggestions: parseResult.suggestions
                )
                
                // 检查是否有错误信息（AI服务降级）
                if let serviceError = hybridParsingService.errorMessage {
                    self.handleAIAnalysisError(serviceError, fallbackResult: result)
                } else {
                    self.completeAIAnalysis(with: result)
                }
            }
        }
    }
    
    // 处理AI分析错误
    private func handleAIAnalysisError(_ error: String, fallbackResult: SpeechRecognitionResult?) {
        // 设置错误信息
        self.errorMessage = error
        
        // 如果有降级结果，继续使用
        if let result = fallbackResult {
            self.completeAIAnalysis(with: result)
        } else {
            // 完全失败时，使用本地解析作为最后的降级
            Task {
                let localResult = await performLocalParsing()
                await MainActor.run {
                    self.completeAIAnalysis(with: localResult)
                }
            }
        }
    }
    
    // 执行本地解析作为最后的降级方案
    private func performLocalParsing() async -> SpeechRecognitionResult {
        // 使用SpeechRecognitionService的本地解析方法
        return await speechService.parseExpenseFromText(recognizedText)
    }
    
    private func simulateAIAnalysis() {
        // 模拟分析进度
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            Task { @MainActor in
                self.analysisProgress = min(self.analysisProgress + 0.05, 1.0)
                
                if self.analysisProgress >= 1.0 {
                    timer.invalidate()
                    // 创建一个默认的解析结果
                    let defaultResult = SpeechRecognitionResult(
                        text: self.recognizedText,
                        amount: nil,
                        category: nil,
                        note: nil,
                        confidence: 0.5,
                        parseSource: .local,
                        aiSuggestions: []
                    )
                    self.completeAIAnalysis(with: defaultResult)
                }
            }
        }
    }
    
    private func completeAIAnalysis(with result: SpeechRecognitionResult) {
        // 保存完整的解析结果
        parseResult = result
        parseConfidence = result.confidence
        parseSource = result.parseSource
        aiSuggestions = result.aiSuggestions ?? []
        
        // 设置可编辑的账单信息
        editableAmount = String(format: "%.2f", result.amount ?? 0.0)
        editableCategory = result.category ?? "其他"
        editableNote = result.note ?? ""
        
        // 进入编辑状态
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
            workflowState = .editing
        }
    }
    
    // MARK: - 账单保存相关方法
    private func saveBill() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
            workflowState = .saving
        }
        
        // 模拟保存过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.completeSaving()
        }
    }
    
    private func completeSaving() {
        let amount = Double(editableAmount) ?? 0.0
        
        // 查找匹配的分类
        var matchedCategory: ExpenseCategory?
        if !editableCategory.isEmpty {
            matchedCategory = categories.first { category in
                editableCategory.lowercased().contains(category.name.lowercased()) ||
                category.name.lowercased().contains(editableCategory.lowercased())
            }
        }
        
        // 如果没找到匹配的分类，使用第一个分类
        if matchedCategory == nil {
            matchedCategory = categories.first
        }
        
        // 创建新的支出记录
        let newExpense = ExpenseRecord(
            amount: amount,
            category: matchedCategory,
            note: editableNote,
            isVoiceInput: true
        )
        
        modelContext.insert(newExpense)
        
        do {
            try modelContext.save()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
                workflowState = .completed
            }
            
            // 3秒后自动重置
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.resetToIdle()
            }
        } catch {
            print("保存失败: \(error)")
            // 可以添加错误处理逻辑
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                workflowState = .editing
            }
        }
    }
    
    // MARK: - 状态重置方法
    private func resetToIdle() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
            workflowState = .idle
        }
        speechService.reset()
        hybridParsingService.reset()
        recognizedText = ""
        editableAmount = ""
        editableCategory = ""
        editableNote = ""
        analysisProgress = 0.0
        isRecording = false
        errorMessage = ""
        
        // 清除AI解析结果
        parseResult = nil
        parseConfidence = 0.0
        parseSource = ParseSource.local
        aiSuggestions = []
        
        // 停止脉冲动画
        withAnimation(.easeOut(duration: 0.3)) {
            pulseAnimation = false
        }
    }
    
    private func retryAIAnalysis() {
        errorMessage = ""
        startAIAnalysis()
    }
    
    private func resetToRecording() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
            workflowState = .idle
        }
        speechService.reset()
        hybridParsingService.reset()
        recognizedText = ""
        editableAmount = ""
        editableCategory = ""
        editableNote = ""
        analysisProgress = 0.0
        
        // 清除AI解析结果
        parseResult = nil
        parseConfidence = 0.0
        parseSource = ParseSource.local
        aiSuggestions = []
        
        // 立即开始新的录音
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.startRecording()
        }
    }
    
    // MARK: - AI解析信息卡片
    @ViewBuilder
    private func getAIParseInfoCard() -> some View {
        VStack(spacing: 16) {
            // 标题行
            HStack(spacing: 16) {
                Image(systemName: parseSource == .ai ? "brain.head.profile" : "cpu")
                    .foregroundColor(parseSource == .ai ? .blue : .orange)
                    .font(.system(size: 20, weight: .semibold))
                
                Text(parseSource == .ai ? "AI智能解析" : "本地解析")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                // 置信度显示
                HStack(spacing: 8) {
                    Text("置信度")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text(String(format: "%.0f%%", parseConfidence * 100))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(getConfidenceColor())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(getConfidenceColor().opacity(0.15))
                        )
                }
            }
            .padding(.bottom, 8)
            
            // 错误提示
            if !errorMessage.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("解析提示")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.orange)
                        
                        Text(errorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.orange.opacity(0.9))
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // 置信度进度条
            VStack(spacing: 10) {
                HStack {
                    Text("解析准确度")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(getConfidenceText())
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(getConfidenceColor())
                }
                
                ProgressView(value: safeProgressValue, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: getConfidenceColor()))
                    .scaleEffect(y: 2.5)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 5)
                    )
            }
            
            // AI建议显示
            if !aiSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 10) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 18, weight: .medium))
                        
                        Text("AI建议")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(aiSuggestions.prefix(3), id: \.self) { suggestion in
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(Color.yellow.opacity(0.8))
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 8)
                                
                                Text(suggestion)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(nil)
                                    .lineSpacing(2)
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(.leading, 12)
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.06)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    parseSource == .ai ? Color.blue.opacity(0.5) : Color.orange.opacity(0.5),
                                    parseSource == .ai ? Color.blue.opacity(0.3) : Color.orange.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(
            color: (parseSource == .ai ? Color.blue : Color.orange).opacity(0.2),
            radius: 12,
            x: 0,
            y: 6
        )
    }
}

struct VoiceInputView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceInputView()
    }
}