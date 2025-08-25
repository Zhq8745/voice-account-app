//
//  AuthService.swift
//  AiVC
//
//  Created by AI Assistant on 2025/01/21.
//

import Foundation
import Combine
import CryptoKit

// MARK: - Authentication Service

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    
    private let keychainManager = KeychainManager.shared
    private let securityService = SecurityService.shared
    private let loginLogger = LoginLogService.shared
    private let jwtService = JWTService.shared
    
    // 模拟用户数据库
    private var users: [String: User] = [:]
    private var userPasswords: [String: String] = [:]
    
    private init() {
        checkAuthenticationStatus()
        createMockUsers()
    }
    
    // MARK: - Authentication Status
    
    private func checkAuthenticationStatus() {
        if let accessToken = keychainManager.load(for: .accessToken) {
            let validationResult = jwtService.validateToken(accessToken)
            if validationResult.isValid {
                // 从token中提取用户信息
                if let userId = jwtService.extractUserId(from: accessToken),
                   let user = users[userId.uuidString] {
                    currentUser = user
                    isAuthenticated = true
                } else {
                    // Token有效但用户不存在，清除认证信息
                    clearAuthenticationData()
                }
            } else {
                // Token无效，尝试刷新
                Task {
                    await attemptTokenRefresh()
                }
            }
        }
    }
    
    private func attemptTokenRefresh() async {
        guard let refreshToken = keychainManager.load(for: .refreshToken) else {
            clearAuthenticationData()
            return
        }
        
        do {
            let newTokens = try await self.refreshToken(refreshToken: refreshToken)
            keychainManager.saveAuthTokens(accessToken: newTokens.accessToken, refreshToken: newTokens.refreshToken)
            
            // 重新检查认证状态
            checkAuthenticationStatus()
        } catch {
            clearAuthenticationData()
        }
    }
    
    // MARK: - Login
    
    func login(request: LoginRequest) async throws -> LoginResult {
        isLoading = true
        defer { isLoading = false }
        
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 验证CSRF令牌
        guard !request.csrfToken.isEmpty else {
            throw LoginError.csrfTokenInvalid
        }
        
        // 查找用户
        let user = findUser(by: request.identifier)
        guard let user = user else {
            loginLogger.logLogin(
                userId: nil,
                username: request.identifier.contains("@") ? nil : request.identifier,
                email: request.identifier.contains("@") ? request.identifier : nil,
                success: false,
                failureReason: "用户不存在"
            )
            throw LoginError.invalidCredentials
        }
        
        // 检查账户状态
        guard user.isActive else {
            loginLogger.logLogin(
                userId: user.id,
                username: user.username,
                email: user.email,
                success: false,
                failureReason: "账户已禁用"
            )
            throw LoginError.accountLocked
        }
        
        // 验证密码
        guard let storedPassword = userPasswords[user.id],
              verifyPassword(request.password, against: storedPassword) else {
            loginLogger.logLogin(
                userId: user.id,
                username: user.username,
                email: user.email,
                success: false,
                failureReason: "密码错误"
            )
            throw LoginError.invalidCredentials
        }
        
        // 检查邮箱验证状态
        if !user.isEmailVerified {
            return LoginResult(
                success: false,
                message: "请先验证您的邮箱地址",
                user: user,
                requiresEmailVerification: true
            )
        }
        
        // 生成访问令牌
        let tokens = try generateTokens(for: user)
        
        // 保存认证信息
        keychainManager.saveAuthTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
        
        // 更新用户最后登录时间
        var updatedUser = user
        updatedUser = User(
            id: user.id,
            username: user.username,
            email: user.email,
            displayName: user.displayName,
            avatar: user.avatar,
            isEmailVerified: user.isEmailVerified,
            isActive: user.isActive,
            createdAt: user.createdAt,
            updatedAt: Date(),
            lastLoginAt: Date(),
            profile: user.profile
        )
        users[user.id] = updatedUser
        
        // 更新当前用户状态
        await MainActor.run {
            currentUser = updatedUser
            isAuthenticated = true
        }
        
        // 记录成功登录
        loginLogger.logLogin(
            userId: user.id,
            username: user.username,
            email: user.email,
            success: true
        )
        
        return LoginResult(
            success: true,
            message: "登录成功",
            user: updatedUser,
            tokens: tokens
        )
    }
    
    // MARK: - Register
    
    func register(request: RegisterRequest) async throws -> RegisterResult {
        isLoading = true
        defer { isLoading = false }
        
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        // 验证输入
        try validateRegistrationRequest(request)
        
        // 检查用户名是否已存在
        if users.values.contains(where: { $0.username.lowercased() == request.username.lowercased() }) {
            throw RegisterError.usernameExists
        }
        
        // 检查邮箱是否已存在
        if users.values.contains(where: { $0.email.lowercased() == request.email.lowercased() }) {
            throw RegisterError.emailExists
        }
        
        // 创建新用户
        let userId = UUID().uuidString
        let hashedPassword = hashPassword(request.password)
        
        let newUser = User(
            id: userId,
            username: request.username,
            email: request.email,
            displayName: request.displayName,
            isEmailVerified: false, // 需要邮箱验证
            isActive: true
        )
        
        // 保存用户
        users[userId] = newUser
        userPasswords[userId] = hashedPassword
        
        // 记录注册日志
        loginLogger.logRegistration(
            userId: userId,
            username: request.username,
            email: request.email,
            success: true
        )
        
        // 发送验证邮件（模拟）
        await sendVerificationEmail(to: newUser)
        
        return RegisterResult(
            success: true,
            message: "注册成功，请检查邮箱并完成验证",
            user: newUser,
            requiresEmailVerification: true
        )
    }
    
    // MARK: - Logout
    
    func logout() async {
        if let user = currentUser {
            loginLogger.logLogout(userId: user.id, username: user.username)
        }
        
        await MainActor.run {
            clearAuthenticationData()
        }
    }
    
    private func clearAuthenticationData() {
        currentUser = nil
        isAuthenticated = false
        keychainManager.clearAuthTokens()
        
        // 清除UserDefaults中的用户信息
        UserDefaults.standard.removeObject(forKey: "currentUserId")
        UserDefaults.standard.removeObject(forKey: "currentUsername")
        UserDefaults.standard.removeObject(forKey: "currentUserEmail")
        UserDefaults.standard.removeObject(forKey: "rememberMe")
        UserDefaults.standard.removeObject(forKey: "savedIdentifier")
    }
    
    // MARK: - Token Management
    
    func refreshToken(refreshToken: String) async throws -> AuthTokens {
        // 验证刷新令牌
        let validationResult = jwtService.validateToken(refreshToken)
        guard validationResult.isValid else {
            throw LoginError.unknown
        }
        
        // 从刷新令牌中提取用户ID
        guard let userId = jwtService.extractUserId(from: refreshToken),
              let user = users[userId.uuidString] else {
            throw LoginError.unknown
        }
        
        // 生成新的令牌对
        return try generateTokens(for: user)
    }
    
    private func generateTokens(for user: User) throws -> AuthTokens {
        guard let accessToken = jwtService.generateAccessToken(
            userId: UUID(uuidString: user.id)!,
            sessionId: UUID().uuidString
        ) else {
            throw LoginError.unknown
        }
        
        guard let refreshToken = jwtService.generateRefreshToken(
            userId: UUID(uuidString: user.id)!,
            sessionId: UUID().uuidString
        ) else {
            throw LoginError.unknown
        }
        
        return AuthTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
            tokenType: "Bearer",
            expiresIn: 3600
        )
    }
    
    // MARK: - User Management
    
    private func findUser(by identifier: String) -> User? {
        return users.values.first { user in
            user.username.lowercased() == identifier.lowercased() ||
            user.email.lowercased() == identifier.lowercased()
        }
    }
    
    func getCurrentUser() -> User? {
        return currentUser
    }
    
    func updateUser(_ user: User) async throws {
        guard currentUser?.id == user.id else {
            throw NSError(domain: "AuthService", code: 403, userInfo: [NSLocalizedDescriptionKey: "无权限更新此用户"])
        }
        
        users[user.id] = user
        await MainActor.run {
            currentUser = user
        }
    }
    
    // MARK: - Email Verification
    
    func sendVerificationEmail(to user: User) async {
        // 模拟发送验证邮件
        print("发送验证邮件到: \(user.email)")
        // 在实际应用中，这里会调用邮件服务API
    }
    
    func verifyEmail(userId: String, verificationCode: String) async throws -> Bool {
        // 模拟邮箱验证
        guard var user = users[userId] else {
            return false
        }
        
        // 在实际应用中，这里会验证验证码
        user = User(
            id: user.id,
            username: user.username,
            email: user.email,
            displayName: user.displayName,
            avatar: user.avatar,
            isEmailVerified: true,
            isActive: user.isActive,
            createdAt: user.createdAt,
            updatedAt: Date(),
            lastLoginAt: user.lastLoginAt,
            profile: user.profile
        )
        
        users[userId] = user
        
        if currentUser?.id == userId {
            await MainActor.run {
                currentUser = user
            }
        }
        
        return true
    }
    
    // MARK: - Password Management
    
    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func verifyPassword(_ password: String, against hashedPassword: String) -> Bool {
        return hashPassword(password) == hashedPassword
    }
    
    func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let user = currentUser else {
            throw NSError(domain: "AuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "未登录"])
        }
        
        guard let storedPassword = userPasswords[user.id],
              verifyPassword(currentPassword, against: storedPassword) else {
            throw NSError(domain: "AuthService", code: 400, userInfo: [NSLocalizedDescriptionKey: "当前密码错误"])
        }
        
        userPasswords[user.id] = hashPassword(newPassword)
    }
    
    // MARK: - Validation
    
    private func validateRegistrationRequest(_ request: RegisterRequest) throws {
        // 验证用户名
        guard request.username.count >= 3 && request.username.count <= 20 else {
            throw RegisterError.invalidUsername
        }
        
        // 验证邮箱格式
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: request.email) else {
            throw RegisterError.invalidEmail
        }
        
        // 验证密码强度
        guard request.password.count >= 8 else {
            throw RegisterError.passwordTooWeak
        }
        
        // 验证密码确认
        guard request.password == request.confirmPassword else {
            throw RegisterError.passwordMismatch
        }
        
        // 验证服务条款
        guard request.acceptTerms else {
            throw RegisterError.termsNotAccepted
        }
    }
    
    // MARK: - Mock Data
    
    private func createMockUsers() {
        // 创建测试用户
        let testUser = User(
            id: "test-user-1",
            username: "testuser",
            email: "test@example.com",
            displayName: "测试用户",
            isEmailVerified: true,
            isActive: true,
            profile: UserProfile(
                firstName: "测试",
                lastName: "用户",
                phone: nil,
                dateOfBirth: nil,
                gender: nil,
                timezone: "Asia/Shanghai",
                language: "zh-CN",
                currency: "CNY"
            )
        )
        
        users[testUser.id] = testUser
        userPasswords[testUser.id] = hashPassword("password123")
    }
}

// MARK: - UserLoginService Compatibility

// 为了兼容现有的LoginViewModel，创建一个别名
typealias UserLoginService = AuthService