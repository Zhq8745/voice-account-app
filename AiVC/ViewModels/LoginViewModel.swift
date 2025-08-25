//
//  LoginViewModel.swift
//  语记
//
//  Created by AI Assistant on 2025/01/21.
//

import SwiftUI
import Combine
import Foundation
import Security

// 导入服务类型定义
// 确保所有服务类型都能被正确识别

@MainActor
class LoginViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var identifier: String = ""
    @Published var password: String = ""
    @Published var rememberMe: Bool = false
    
    @Published var isLoading: Bool = false
    @Published var showingError: Bool = false
    @Published var showingSuccess: Bool = false
    @Published var errorMessage: String = ""
    @Published var successMessage: String = ""
    @Published var validationErrors: [String: ValidationService.ValidationResult] = [:]
    
    // MARK: - Services
    
    private let authService = AuthService.shared
    private let authManager = AuthenticationManager.shared
    private let securityService = SecurityService()
    private let validationService = ValidationService.shared
    private let errorHandler = ErrorHandlingService.shared
    private let loginLogger = LoginLogService.shared
    
    // MARK: - Computed Properties
    
    var canLogin: Bool {
        !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        !isLoading
    }
    
    var isValidEmail: Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: identifier)
    }
    
    // MARK: - Login Methods
    
    func login() async {
        guard canLogin else { return }
        
        clearMessages()
        
        // 表单验证
        let validationResults = validationService.validateLoginForm(
            identifier: identifier,
            password: password
        )
        
        validationErrors = validationResults
        
        // 检查是否有验证错误
        let hasErrors = validationResults.values.contains { !$0.isValid }
        if hasErrors {
            if let firstError = validationResults.values.first(where: { !$0.isValid }) {
                errorHandler.handleValidationError("登录表单", message: firstError.message)
            }
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        do {
            // 准备登录请求
            let request = LoginRequest(
                identifier: identifier.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                rememberMe: rememberMe,
                deviceInfo: getDeviceInfo(),
                csrfToken: await generateCSRFToken()
            )
            
            // 执行登录
            let result = try await authService.login(request: request)
            
            // 处理登录结果
            await handleLoginResult(result)
            
        } catch {
            await handleLoginError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    private func handleLoginResult(_ result: LoginResult) async {
        if result.success {
            successMessage = result.message ?? "登录成功！"
            
            // 更新全局认证状态
            if let user = result.user, let tokens = result.tokens {
                authManager.login(with: tokens, user: user)
            }
            
            // 显示成功消息
            showingSuccess = true
            
            // 清空表单
            clearForm()
            
        } else {
            // 显示错误消息
            errorMessage = result.message ?? "登录失败"
            showingError = true
            
            // 如果是密码错误，清空密码字段
            if errorMessage.contains("密码") {
                password = ""
            }
        }
    }
    
    private func handleLoginError(_ error: Error) async {
        // 记录失败登录日志
        if let loginError = error as? LoginError {
            let failureReason = getFailureReason(for: loginError)
            loginLogger.logLogin(
                userId: nil,
                username: identifier.contains("@") ? nil : identifier,
                email: identifier.contains("@") ? identifier : nil,
                success: false,
                failureReason: failureReason
            )
            
            // 使用错误处理服务
            let appError = mapToAppError(loginError)
            errorHandler.handleError(appError)
        }
        
        if let loginError = error as? LoginError {
            switch loginError {
            case .invalidCredentials:
                errorMessage = "用户名或密码错误"
                password = ""
                
            case .accountLocked:
                errorMessage = "账户已被锁定，请稍后再试或联系客服"
                
            case .accountNotVerified:
                errorMessage = "账户尚未验证，请检查邮箱并完成验证"
                
            case .tooManyAttempts:
                errorMessage = "登录尝试次数过多，请稍后再试"
                
            case .ipBlocked:
                errorMessage = "您的IP地址已被暂时封禁"
                
            case .suspiciousActivity:
                errorMessage = "检测到可疑活动，请稍后再试"
                
            case .csrfTokenInvalid:
                errorMessage = "安全验证失败，请刷新页面重试"
                
            case .networkError:
                errorMessage = "网络连接失败，请检查网络设置"
                
            case .serverError:
                errorMessage = "服务器错误，请稍后再试"
                
            case .unknown:
                errorMessage = "未知错误，请重试"
            }
        } else {
            errorMessage = "登录失败：\(error.localizedDescription)"
        }
        
        showingError = true
    }
    
    private func saveAuthenticationData(_ result: LoginResult) async {
        guard let tokens = result.tokens else { return }
        
        // 保存到 Keychain
        KeychainManager.shared.saveAuthTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
        
        // 保存用户信息到 UserDefaults
        if let user = result.user {
            UserDefaults.standard.set(user.id, forKey: "currentUserId")
            UserDefaults.standard.set(user.username, forKey: "currentUsername")
            UserDefaults.standard.set(user.email, forKey: "currentUserEmail")
        }
        
        // 如果选择了记住我，保存登录状态
        if rememberMe {
            UserDefaults.standard.set(true, forKey: "rememberMe")
            UserDefaults.standard.set(identifier, forKey: "savedIdentifier")
        }
        
        // 记录登录成功日志
        let securityEvent = SecurityEvent(
            type: SecurityEventType.loginSuccess,
            userId: result.user?.id != nil ? UUID(uuidString: result.user!.id) : nil,
            ipAddress: "127.0.0.1", // 本地应用
            userAgent: "语记-iOS",
            details: [
                "identifier": identifier,
                "rememberMe": String(rememberMe)
            ],
            severity: SecuritySeverity.low
        )
        securityService.logSecurityEvent(securityEvent)
    }
    
    private func clearForm() {
        if !rememberMe {
            identifier = ""
        }
        password = ""
        validationErrors.removeAll()
    }
    
    private func clearMessages() {
        errorMessage = ""
        successMessage = ""
        validationErrors.removeAll()
    }
    
    // MARK: - Validation Methods
    
    func validateField(_ field: String) {
        switch field {
        case "identifier":
            if identifier.contains("@") {
                validationErrors["identifier"] = validationService.validateEmail(identifier)
            } else {
                validationErrors["identifier"] = validationService.validateUsername(identifier)
            }
        case "password":
            if password.isEmpty {
                validationErrors["password"] = ValidationService.ValidationResult.invalid("密码不能为空")
             } else {
                 validationErrors["password"] = .valid()
            }
        default:
            break
        }
    }
    
    func getValidationMessage(for field: String) -> String? {
        guard let result = validationErrors[field], !result.isValid else { return nil }
        return result.message
    }
    
    func isFieldValid(_ field: String) -> Bool {
        return validationErrors[field]?.isValid ?? true
    }
    
    // MARK: - Error Mapping
    
    private func getFailureReason(for error: LoginError) -> String {
        switch error {
        case .invalidCredentials: return "invalid_credentials"
        case .accountLocked: return "account_locked"
        case .accountNotVerified: return "account_not_verified"
        case .tooManyAttempts: return "too_many_attempts"
        case .networkError: return "network_error"
        case .serverError: return "server_error"
        case .csrfTokenInvalid: return "invalid_csrf"
        case .ipBlocked: return "ip_blocked"
        case .suspiciousActivity: return "suspicious_activity"
        case .unknown: return "unknown"
        }
    }
    
    private func mapToAppError(_ error: Error) -> ErrorHandlingService.AppError {
        if let loginError = error as? LoginError {
            switch loginError {
            case .invalidCredentials:
                return ErrorHandlingService.AppError.authenticationError("用户名或密码错误")
             case .accountLocked:
                 return ErrorHandlingService.AppError.authenticationError("账户已被锁定")
             case .accountNotVerified:
                 return ErrorHandlingService.AppError.authenticationError("账户尚未验证")
             case .tooManyAttempts:
                 return ErrorHandlingService.AppError.authenticationError("登录尝试次数过多")
             case .networkError:
                 return ErrorHandlingService.AppError.networkError("网络连接失败，请检查网络设置")
             case .serverError:
                 return ErrorHandlingService.AppError.unknownError("服务器错误，请稍后重试")
             case .csrfTokenInvalid, .ipBlocked, .suspiciousActivity:
                 return ErrorHandlingService.AppError.unknownError("安全验证失败")
             case .unknown:
                 return ErrorHandlingService.AppError.unknownError("登录失败，请稍后重试")
            }
        } else {
            return ErrorHandlingService.AppError.unknownError("未知错误")
        }
    }
    
    private func getDeviceInfo() -> [String: Any] {
        return [
            "platform": "iOS",
            "version": UIDevice.current.systemVersion,
            "model": UIDevice.current.model,
            "name": UIDevice.current.name
        ]
    }
    
    private func generateCSRFToken() async -> String {
        return await securityService.generateCSRFToken()
    }
    
    // MARK: - Auto-fill Methods
    
    func loadSavedCredentials() {
        if UserDefaults.standard.bool(forKey: "rememberMe") {
            identifier = UserDefaults.standard.string(forKey: "savedIdentifier") ?? ""
            rememberMe = true
        }
    }
    
    // MARK: - Validation Methods
    
    func validateInput() -> String? {
        let trimmedIdentifier = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedIdentifier.isEmpty {
            return "请输入用户名或邮箱"
        }
        
        if password.isEmpty {
            return "请输入密码"
        }
        
        if password.count < 6 {
            return "密码长度不能少于6位"
        }
        
        // 如果输入的是邮箱格式，验证邮箱格式
        if trimmedIdentifier.contains("@") && !isValidEmail {
            return "请输入有效的邮箱地址"
        }
        
        return nil
    }
    
    // MARK: - Quick Login Methods
    
    func quickLogin() async {
        guard !isLoading else { return }
        
        isLoading = true
        
        // 使用AuthenticationManager检查认证状态
        authManager.checkAuthenticationStatus()
        
        if authManager.isAuthenticated {
            showingSuccess = true
        } else {
            errorMessage = "快速登录失败，请重新登录"
            showingError = true
        }
        
        isLoading = false
    }
    
    func signInWithApple() async {
        isLoading = true
        clearMessages()
        
        do {
            let result = try await AppleSignInService.shared.signInWithApple()
            
            // 创建或更新用户信息
            let user = User(
                id: result.userIdentifier,
                username: result.email ?? "apple_user_\(result.userIdentifier.prefix(8))",
                email: result.email ?? "",
                displayName: result.fullName?.formatted() ?? "",
                isEmailVerified: true, // Apple ID 默认已验证
                appleUserIdentifier: result.userIdentifier,
                loginMethod: .apple
            )
            
            // 保存用户信息到认证管理器
            await authManager.saveUser(user)
            
            isLoading = false
            successMessage = "Apple ID 登录成功"
            showingSuccess = true
            
            // 记录登录日志
            loginLogger.logLogin(
                userId: user.id,
                username: user.username,
                email: user.email,
                success: true,
                failureReason: nil
            )
            
        } catch {
            isLoading = false
            
            if let appleError = error as? AppleSignInError {
                switch appleError {
                case .cancelled:
                    // 用户取消，不显示错误
                    return
                case .failed:
                    errorMessage = "Apple 登录失败"
                case .invalidResponse:
                    errorMessage = "Apple 登录响应无效"
                case .networkError:
                    errorMessage = "网络连接失败"
                case .unknown:
                    errorMessage = "未知错误"
                }
            } else {
                errorMessage = "Apple 登录失败：\(error.localizedDescription)"
            }
            
            showingError = true
            
            // 记录失败日志
            loginLogger.logLogin(
                userId: nil,
                username: nil,
                email: nil,
                success: false,
                failureReason: errorMessage
            )
        }
    }
}