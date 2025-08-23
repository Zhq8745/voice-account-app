//
//  CustomNumericKeypad.swift
//  AiVC
//
//  Created by AI Assistant.
//

import SwiftUI

struct CustomNumericKeypad: View {
    @Binding var amount: String
    @Binding var isShowing: Bool
    
    private let keypadButtons = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"]
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 键盘头部
            HStack {
                Button("取消") {
                    isShowing = false
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Text("数字键盘")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("完成") {
                    isShowing = false
                }
                .foregroundColor(.blue)
                .fontWeight(.semibold)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(red: 0.11, green: 0.11, blue: 0.12))
            
            // 金额显示
            VStack(spacing: 8) {
                Text("¥ " + (amount.isEmpty ? "0.00" : amount))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                Text("输入金额")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 20)
            
            // 数字键盘
            VStack(spacing: 1) {
                ForEach(0..<keypadButtons.count, id: \.self) { row in
                    HStack(spacing: 1) {
                        ForEach(0..<keypadButtons[row].count, id: \.self) { col in
                            KeypadButton(
                                text: keypadButtons[row][col],
                                action: {
                                    handleKeypadInput(keypadButtons[row][col])
                                }
                            )
                        }
                    }
                }
            }
            .background(Color(red: 0.15, green: 0.15, blue: 0.16))
        }
        .background(Color.black)
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
    
    private func handleKeypadInput(_ input: String) {
        switch input {
        case "⌫":
            if !amount.isEmpty {
                amount.removeLast()
            }
        case ".":
            if !amount.contains(".") {
                if amount.isEmpty {
                    amount = "0."
                } else {
                    amount += "."
                }
            }
        default:
            // 限制小数点后最多两位
            if amount.contains(".") {
                let components = amount.components(separatedBy: ".")
                if components.count > 1 && components[1].count >= 2 {
                    return
                }
            }
            
            // 限制总长度
            if amount.count < 10 {
                amount += input
            }
        }
    }
}

struct KeypadButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                action()
            }
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            ZStack {
                Rectangle()
                    .fill(buttonColor)
                    .frame(height: 60)
                
                if text == "⌫" {
                    Image(systemName: "delete.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                } else {
                    Text(text)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(KeypadButtonStyle())
    }
    
    private var buttonColor: Color {
        switch text {
        case "⌫":
            return Color(red: 0.2, green: 0.2, blue: 0.21)
        default:
            return Color(red: 0.11, green: 0.11, blue: 0.12)
        }
    }
}

struct KeypadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// 扩展用于圆角
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    CustomNumericKeypad(
        amount: .constant("123.45"),
        isShowing: .constant(true)
    )
}