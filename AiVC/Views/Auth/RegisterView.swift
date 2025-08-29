//
//  RegisterView.swift
//  语记
//
//  Created by AI Assistant on 2025/01/21.
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = RegisterViewModel()
    @FocusState private var focusedField: Field?
    
    enum Field {
        case username, email, password, confirmPassword
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // 顶部标题区域
                        headerSection
                            .frame(height: geometry.size.height * 0.25)
                        
                        // 注册表单
                        registerForm
                            .padding(.horizontal, 24)
                            .frame(minHeight: geometry.size.height * 0.75)
                    }
                }
            }
            .background(Color.black)
            .ignoresSafeArea(.all, edges: .top)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .toolbar(.hidden, for: .tabBar)
        .alert("注册失败", isPresented: $viewModel.showingError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .alert("注册成功", isPresented: $viewModel.showingSuccess) {
            Button("确定") {
                dismiss()
            }
        } message: {
            Text(viewModel.successMessage)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Spacer()
            
            // 注册图标
            Image(systemName: "person.badge.plus.fill")
                .font(.system(size: 60))
                .foregroundColor(Color.cyan)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 8) {
                Text("创建账户")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.white)
                
                Text("加入语记，开始智能记账之旅")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Register Form
    
    private var registerForm: some View {
        VStack(spacing: 20) {
            // 输入字段
            VStack(spacing: 16) {
                // 用户名输入
                CustomTextField(
                    title: "用户名",
                    text: $viewModel.username,
                    placeholder: "请输入用户名",
                    icon: "person.circle",
                    textContentType: .username
                )
                .focused($focusedField, equals: .username)
                .onSubmit {
                    focusedField = .email
                }
                
                // 验证提示
                if !viewModel.username.isEmpty {
                    ValidationIndicator(
                        isValid: viewModel.isUsernameValid,
                        message: viewModel.isUsernameValid ? "用户名可用" : "用户名长度需要3-20个字符"
                    )
                }
                
                // 邮箱输入
                CustomTextField(
                    title: "邮箱地址",
                    text: $viewModel.email,
                    placeholder: "请输入邮箱地址",
                    icon: "envelope.circle",
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress
                )
                .focused($focusedField, equals: .email)
                .onSubmit {
                    focusedField = .password
                }
                
                // 邮箱验证提示
                if !viewModel.email.isEmpty {
                    ValidationIndicator(
                        isValid: viewModel.isEmailValid,
                        message: viewModel.isEmailValid ? "邮箱格式正确" : "请输入有效的邮箱地址"
                    )
                }
                
                // 密码输入
                CustomSecureField(
                    title: "密码",
                    text: $viewModel.password,
                    placeholder: "请输入密码",
                    icon: "lock.circle"
                )
                .focused($focusedField, equals: .password)
                .onSubmit {
                    focusedField = .confirmPassword
                }
                
                // 密码强度指示器
                if !viewModel.password.isEmpty {
                    PasswordStrengthIndicator(password: viewModel.password)
                }
                
                // 确认密码输入
                CustomSecureField(
                    title: "确认密码",
                    text: $viewModel.confirmPassword,
                    placeholder: "请再次输入密码",
                    icon: "lock.circle"
                )
                .focused($focusedField, equals: .confirmPassword)
                .onSubmit {
                    focusedField = nil
                    Task {
                        await viewModel.register()
                    }
                }
                
                // 密码匹配提示
                if !viewModel.confirmPassword.isEmpty {
                    ValidationIndicator(
                        isValid: viewModel.passwordsMatch,
                        message: viewModel.passwordsMatch ? "密码匹配" : "两次输入的密码不一致"
                    )
                }
            }
            
            // 服务条款和隐私政策
            VStack(spacing: 12) {
                HStack {
                    Button(action: {
                        viewModel.agreeToTerms.toggle()
                    }) {
                        Image(systemName: viewModel.agreeToTerms ? "checkmark.square.fill" : "square")
                            .foregroundColor(viewModel.agreeToTerms ? Color.cyan : .gray)
                    }
                    
                    Text("我已阅读并同意")
                        .font(.subheadline)
                        .foregroundColor(Color.white)
                    
                    Button("服务条款") {
                        // 显示服务条款
                    }
                    .font(.subheadline)
                    .foregroundColor(Color.cyan)
                    
                    Text("和")
                        .font(.subheadline)
                        .foregroundColor(Color.white)
                    
                    Button("隐私政策") {
                        // 显示隐私政策
                    }
                    .font(.subheadline)
                    .foregroundColor(Color.cyan)
                    
                    Spacer()
                }
                
                HStack {
                    Button(action: {
                        viewModel.subscribeToNewsletter.toggle()
                    }) {
                        Image(systemName: viewModel.subscribeToNewsletter ? "checkmark.square.fill" : "square")
                            .foregroundColor(viewModel.subscribeToNewsletter ? Color.cyan : .gray)
                    }
                    
                    Text("订阅产品更新和优惠信息")
                        .font(.subheadline)
                        .foregroundColor(Color.white)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 4)
            
            // 注册按钮
            Button(action: {
                focusedField = nil
                Task {
                    await viewModel.register()
                }
            }) {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(viewModel.isLoading ? "注册中..." : "创建账户")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(viewModel.canRegister ? Color.cyan : Color(.systemGray6).opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: viewModel.canRegister ? Color.cyan.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            }
            .disabled(!viewModel.canRegister)
            
            // 分隔线
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(.systemGray6).opacity(0.3))
                
                Text("或")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(.systemGray6).opacity(0.3))
            }
            .padding(.vertical, 8)
            
            // 第三方注册选项
            VStack(spacing: 12) {
                // Apple ID 注册
                Button(action: {
                    // 实现Apple ID注册
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "applelogo")
                            .font(.system(size: 16, weight: .medium))
                        Text("使用Apple ID注册")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6).opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                    .foregroundColor(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                
                // Google 注册
                Button(action: {
                    // 实现Google注册
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                            .font(.system(size: 16, weight: .medium))
                        Text("使用Google注册")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.red.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
            
            // 登录链接
            HStack {
                Text("已有账户？")
                    .foregroundColor(.gray)
                
                Button("立即登录") {
                    dismiss()
                }
                .foregroundColor(Color.cyan)
                .fontWeight(.medium)
            }
            .font(.subheadline)
            .padding(.top, 16)
            
            Spacer(minLength: 20)
        }
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6).opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
    }
}

// MARK: - Validation Indicator

struct ValidationIndicator: View {
    let isValid: Bool
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isValid ? .green : .red)
                .font(.caption)
            
            Text(message)
                .font(.caption)
                .foregroundColor(isValid ? .green : .red)
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Password Strength Indicator

struct PasswordStrengthIndicator: View {
    let password: String
    
    private var strength: PasswordStrength {
        PasswordValidator.checkStrength(password)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("密码强度:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(strength.description)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(strength.color)
                
                Spacer()
            }
            
            // 强度条
            HStack(spacing: 4) {
                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .frame(height: 4)
                        .foregroundColor(index < strength.level ? strength.color : Color(.systemGray6).opacity(0.3))
                        .cornerRadius(2)
                }
            }
            
            // 密码要求
            VStack(alignment: .leading, spacing: 4) {
                PasswordRequirement("至少8个字符", isMet: password.count >= 8)
                PasswordRequirement("包含大写字母", isMet: password.range(of: "[A-Z]", options: .regularExpression) != nil)
                PasswordRequirement("包含小写字母", isMet: password.range(of: "[a-z]", options: .regularExpression) != nil)
                PasswordRequirement("包含数字", isMet: password.range(of: "[0-9]", options: .regularExpression) != nil)
                PasswordRequirement("包含特殊字符", isMet: password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil)
            }
        }
        .padding(.horizontal, 4)
    }
}

struct PasswordRequirement: View {
    let text: String
    let isMet: Bool
    
    init(_ text: String, isMet: Bool) {
        self.text = text
        self.isMet = isMet
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : .gray)
                .font(.caption2)
            
            Text(text)
                .font(.caption2)
                .foregroundColor(isMet ? .green : .gray)
        }
    }
}

// MARK: - Password Validator

struct PasswordValidator {
    static func checkStrength(_ password: String) -> PasswordStrength {
        var score = 0
        
        if password.count >= 8 { score += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[a-z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil { score += 1 }
        
        switch score {
        case 0...1:
            return .weak
        case 2...3:
            return .medium
        case 4:
            return .strong
        case 5:
            return .veryStrong
        default:
            return .weak
        }
    }
}

enum PasswordStrength {
    case weak, medium, strong, veryStrong
    
    var description: String {
        switch self {
        case .weak: return "弱"
        case .medium: return "中等"
        case .strong: return "强"
        case .veryStrong: return "很强"
        }
    }
    
    var color: Color {
        switch self {
        case .weak: return Color.red
        case .medium: return Color.orange
        case .strong: return Color.cyan
        case .veryStrong: return .green
        }
    }
    
    var level: Int {
        switch self {
        case .weak: return 1
        case .medium: return 2
        case .strong: return 3
        case .veryStrong: return 4
        }
    }
}

// MARK: - Register ViewModel

@MainActor
class RegisterViewModel: ObservableObject {
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var agreeToTerms = false
    @Published var subscribeToNewsletter = false
    
    @Published var isLoading = false
    @Published var showingError = false
    @Published var showingSuccess = false
    @Published var errorMessage = ""
    @Published var successMessage = ""
    
    private let authService = AuthService.shared
    
    var isUsernameValid: Bool {
        username.count >= 3 && username.count <= 20
    }
    
    var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    var isPasswordValid: Bool {
        password.count >= 8
    }
    
    var passwordsMatch: Bool {
        password == confirmPassword && !password.isEmpty
    }
    
    var canRegister: Bool {
        isUsernameValid && isEmailValid && isPasswordValid && passwordsMatch && agreeToTerms && !isLoading
    }
    
    func register() async {
        guard canRegister else { return }
        
        isLoading = true
        
        let request = RegisterRequest(
            username: username,
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            displayName: nil,
            acceptTerms: agreeToTerms,
            deviceInfo: [:],
            csrfToken: ""
        )
        
        do {
            let result = try await authService.register(request: request)
            
            if result.success {
                successMessage = result.message ?? "注册成功"
                showingSuccess = true
            } else {
                errorMessage = result.message ?? "注册失败"
                showingError = true
            }
        } catch {
            errorMessage = "注册失败: \(error.localizedDescription)"
            showingError = true
        }
        
        isLoading = false
    }
}

// MARK: - Preview

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}