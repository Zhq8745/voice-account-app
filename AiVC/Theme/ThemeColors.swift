//
//  ThemeColors.swift
//  语记
//
//  Created by AI Assistant
//

import SwiftUI
import Foundation

// MARK: - 主题颜色系统
struct ThemeColors {
    
    // MARK: - 主色调系统
    static let primary = Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF
    static let primaryLight = Color(red: 0.35, green: 0.78, blue: 0.98) // #5AC8FA
    static let primaryDark = Color(red: 0.0, green: 0.35, blue: 0.8) // #0056CC
    
    // 主色调渐变
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [primary, primaryLight]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let primaryGradientReverse = LinearGradient(
        gradient: Gradient(colors: [primaryLight, primary]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - 背景色系统
    static let backgroundPrimary = Color.black
    static let backgroundSecondary = Color(red: 0.05, green: 0.05, blue: 0.08)
    static let backgroundTertiary = Color(red: 0.08, green: 0.08, blue: 0.12)
    
    // 背景渐变
    static let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [
            backgroundPrimary,
            backgroundSecondary,
            backgroundTertiary,
            backgroundPrimary
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradientLight = LinearGradient(
        gradient: Gradient(colors: [
            backgroundSecondary,
            backgroundTertiary,
            backgroundSecondary
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - 卡片背景系统
    static let cardBackground = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let cardBackgroundSecondary = Color(red: 0.15, green: 0.15, blue: 0.18)
    static let cardBackgroundTertiary = Color(red: 0.12, green: 0.12, blue: 0.15)
    
    // 卡片渐变
    static let cardGradient = LinearGradient(
        gradient: Gradient(colors: [
            cardBackgroundSecondary,
            cardBackground
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradientGlass = LinearGradient(
        gradient: Gradient(colors: [
            Color.white.opacity(0.1),
            Color.white.opacity(0.05)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - 文字颜色系统
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.8)
    static let textTertiary = Color.white.opacity(0.6)
    static let textQuaternary = Color.white.opacity(0.4)
    static let textPlaceholder = Color.white.opacity(0.3)
    
    // MARK: - 强调色系统
    static let accent = Color.cyan
    static let accentSecondary = Color.purple
    static let accentTertiary = Color.mint
    
    // 强调色渐变
    static let accentGradient = LinearGradient(
        gradient: Gradient(colors: [accent, accentSecondary]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - 状态色系统
    static let success = Color.green
    static let successLight = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let warning = Color.orange
    static let warningLight = Color(red: 1.0, green: 0.8, blue: 0.4)
    static let error = Color.red
    static let errorLight = Color(red: 1.0, green: 0.4, blue: 0.4)
    static let info = primary
    
    // MARK: - 边框色系统
    static let borderPrimary = Color.white.opacity(0.1)
    static let borderSecondary = Color.white.opacity(0.05)
    static let borderAccent = primary.opacity(0.3)
    
    // 边框渐变
    static let borderGradient = LinearGradient(
        gradient: Gradient(colors: [
            primary.opacity(0.3),
            accentSecondary.opacity(0.2)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - 阴影色系统
    static let shadowPrimary = Color.black.opacity(0.3)
    static let shadowSecondary = Color.black.opacity(0.2)
    static let shadowAccent = primary.opacity(0.2)
    
    // MARK: - 装饰性颜色
    static let decorativeBlue = Color.blue.opacity(0.1)
    static let decorativePurple = Color.purple.opacity(0.08)
    static let decorativeCyan = Color.cyan.opacity(0.12)
    static let decorativeCircle1 = Color.blue.opacity(0.15)
    
    // MARK: - 兼容性别名
    static let background = backgroundPrimary
    static let secondaryBackground = backgroundSecondary
    static let text = textPrimary
    static let secondaryText = textSecondary
    static let secondary = accentSecondary
    static let surface = cardBackground
    static let onSurface = textPrimary
    static let destructive = error
    static let shadow = shadowPrimary
    static let border = borderPrimary
    static let secondaryGradient = LinearGradient(
        colors: [Color(.systemGray6).opacity(0.3), Color(.systemGray6).opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let voiceButtonGradient = LinearGradient(
        colors: [accent, accent.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - TabBar 颜色
    static let tabBarBackground = cardBackground
    static let tabBarSelected = primary
    static let tabBarUnselected = Color.gray
}

// MARK: - 颜色扩展
extension Color {
    
    // 便捷的主题色访问
    static var themePrimary: Color { ThemeColors.primary }
    static var themeBackground: Color { ThemeColors.backgroundPrimary }
    static var themeCard: Color { ThemeColors.cardBackground }
    static var themeText: Color { ThemeColors.textPrimary }
    static var themeAccent: Color { ThemeColors.accent }
    
    // 透明度变体方法已在系统中定义，此处不再重复定义
    
    // Color扩展已在ExpenseCategory.swift中定义，此处不再重复定义
}

// MARK: - 渐变扩展
extension LinearGradient {
    
    // 便捷的主题渐变
    static var themePrimary: LinearGradient { ThemeColors.primaryGradient }
    static var themeBackground: LinearGradient { ThemeColors.backgroundGradient }
    static var themeCard: LinearGradient { ThemeColors.cardGradient }
    static var themeAccent: LinearGradient { ThemeColors.accentGradient }
    static var themeBorder: LinearGradient { ThemeColors.borderGradient }
}

// MARK: - 主题样式组件
struct ThemeButton: ButtonStyle {
    let variant: ButtonVariant
    
    enum ButtonVariant {
        case primary
        case secondary
        case accent
        case ghost
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(backgroundForVariant)
            .foregroundColor(foregroundColorForVariant)
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private var backgroundForVariant: some View {
        Group {
            switch variant {
            case .primary:
                ThemeColors.primaryGradient
            case .secondary:
                ThemeColors.cardGradient
            case .accent:
                ThemeColors.accentGradient
            case .ghost:
                Color.clear
            }
        }
    }
    
    private var foregroundColorForVariant: Color {
        switch variant {
        case .primary, .secondary, .accent:
            return ThemeColors.textPrimary
        case .ghost:
            return ThemeColors.primary
        }
    }
}

// MARK: - 主题卡片样式
struct ThemeCard: ViewModifier {
    let variant: CardVariant
    
    enum CardVariant {
        case primary
        case secondary
        case glass
        case bordered
    }
    
    func body(content: Content) -> some View {
        content
            .background(backgroundForVariant)
            .overlay(overlayForVariant)
            .cornerRadius(20)
            .shadow(
                color: ThemeColors.shadowPrimary,
                radius: 10,
                x: 0,
                y: 5
            )
    }
    
    private var backgroundForVariant: some View {
        Group {
            switch variant {
            case .primary:
                ThemeColors.cardGradient
            case .secondary:
                ThemeColors.cardBackgroundSecondary
            case .glass:
                ThemeColors.cardGradientGlass
            case .bordered:
                ThemeColors.cardBackground
            }
        }
    }
    
    @ViewBuilder
    private var overlayForVariant: some View {
        switch variant {
        case .bordered:
            RoundedRectangle(cornerRadius: 20)
                .stroke(ThemeColors.borderGradient, lineWidth: 1)
        case .glass:
            RoundedRectangle(cornerRadius: 20)
                .stroke(ThemeColors.borderPrimary, lineWidth: 0.5)
        default:
            EmptyView()
        }
    }
}

// MARK: - 使用扩展
extension View {
    
    // 应用主题卡片样式
    func themeCard(_ variant: ThemeCard.CardVariant = .primary) -> some View {
        self.modifier(ThemeCard(variant: variant))
    }
    
    // 应用主题按钮样式
    func themeButton(_ variant: ThemeButton.ButtonVariant = .primary) -> some View {
        self.buttonStyle(ThemeButton(variant: variant))
    }
}