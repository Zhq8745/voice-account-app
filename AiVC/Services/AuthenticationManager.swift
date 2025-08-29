//
//  AuthenticationManager.swift
//  AiVC
//
//  Created by AI Assistant on 2025/01/21.
//

import SwiftUI
import Foundation
import Combine

@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authTokens: AuthTokens?
    
    private let authService = AuthService.shared
    private let keychain = KeychainManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupAuthStateListener()
    }
    
    // MARK: - Public Methods
    
    /// 检查认证状态
    func checkAuthenticationStatus() {
        // 首先检查Apple登录状态
        if let appleUserIdentifier = keychain.getAppleUserIdentifier() {
            // 验证Apple登录状态
            Task {
                await checkAppleSignInStatus(appleUserIdentifier: appleUserIdentifier)
            }
            return
        }
        
        // 检查是否有保存的令牌
        let tokens = keychain.getAuthTokens()
        if let accessToken = tokens.accessToken, let refreshToken = tokens.refreshToken {
            authTokens = AuthTokens(
                accessToken: accessToken,
                refreshToken: refreshToken,
                tokenType: "Bearer",
                expiresIn: 3600
            )
            
            // 验证令牌是否有效
            Task {
                await validateAndRefreshTokens()
            }
        } else {
            // 没有保存的令牌，用户未登录
            logout()
        }
    }
    
    /// 登录
    func login(with tokens: AuthTokens, user: User) {
        self.authTokens = tokens
        self.currentUser = user
        self.isAuthenticated = true
        
        // 保存令牌到钥匙串
         keychain.saveAuthTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
        
        // 保存用户信息到UserDefaults
        saveUserToDefaults(user)
        
        // 记录登录日志
        Task {
            await LoginLogService.shared.logLogin(
                userId: user.id,
                username: user.username,
                email: user.email,
                success: true,
                failureReason: nil
            )
        }
    }
    
    /// 注销
    func logout() {
        // 记录注销日志
        if let user = currentUser {
            Task {
                await LoginLogService.shared.logLogout(
                    userId: user.id,
                    username: user.username
                )
            }
        }
        
        // 清除认证状态
        self.isAuthenticated = false
        self.currentUser = nil
        self.authTokens = nil
        
        // 清除保存的数据
         keychain.clearAuthTokens()
        clearUserFromDefaults()
        
        // 清除其他用户相关数据
        clearUserData()
    }
    
    /// 刷新令牌
    func refreshTokens() async -> Bool {
        guard let currentTokens = authTokens else {
            logout()
            return false
        }
        
        let refreshToken = currentTokens.refreshToken
        
        do {
            let newTokens = try await authService.refreshToken(refreshToken: refreshToken)
            
            // 更新令牌
             self.authTokens = newTokens
             keychain.saveAuthTokens(accessToken: newTokens.accessToken, refreshToken: newTokens.refreshToken)
            
            return true
        } catch {
            // 刷新失败，注销用户
            logout()
            return false
        }
    }
    
    /// 更新用户信息
    func updateUser(_ user: User) {
        self.currentUser = user
        saveUserToDefaults(user)
    }
    
    /// 保存用户信息（用于Apple登录等第三方登录）
    func saveUser(_ user: User) async {
        self.currentUser = user
        self.isAuthenticated = true
        
        // 保存用户信息到UserDefaults
        saveUserToDefaults(user)
        
        // 如果是Apple登录，保存Apple用户标识符
        if let appleUserIdentifier = user.appleUserIdentifier {
            keychain.saveAppleUserIdentifier(appleUserIdentifier)
        }
        
        // 记录登录日志
        await LoginLogService.shared.logLogin(
            userId: user.id,
            username: user.username,
            email: user.email,
            success: true,
            failureReason: nil
        )
    }
    
    /// 检查令牌是否即将过期
    func isTokenExpiringSoon() -> Bool {
        guard let tokens = authTokens else { return true }
        
        // 简化处理，假设令牌在创建时间基础上加上expiresIn秒后过期
        let expirationDate = Date().addingTimeInterval(TimeInterval(tokens.expiresIn))
        let timeUntilExpiration = expirationDate.timeIntervalSinceNow
        
        // 如果令牌在5分钟内过期，认为即将过期
        return timeUntilExpiration < 300
    }
    
    /// 检查Apple登录状态
    private func checkAppleSignInStatus(appleUserIdentifier: String) async {
        let credentialState = await AppleSignInService.shared.checkAppleSignInStatus(for: appleUserIdentifier)
        
        switch credentialState {
        case .authorized:
            // Apple登录状态有效，恢复用户登录状态
            if let savedUser = loadUserFromDefaults() {
                DispatchQueue.main.async {
                    self.currentUser = savedUser
                    self.isAuthenticated = true
                }
            } else {
                // 没有保存的用户信息，清除Apple登录状态
                keychain.clearAppleUserInfo()
                DispatchQueue.main.async {
                    self.logout()
                }
            }
        case .revoked, .notFound:
            // Apple登录状态无效，清除相关数据并注销
            keychain.clearAppleUserInfo()
            DispatchQueue.main.async {
                self.logout()
            }
        case .transferred:
            // 用户ID已转移，需要重新登录
            keychain.clearAppleUserInfo()
            DispatchQueue.main.async {
                self.logout()
            }
        @unknown default:
            // 未知状态，清除相关数据并注销
            keychain.clearAppleUserInfo()
            DispatchQueue.main.async {
                self.logout()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAuthStateListener() {
        // 监听应用状态变化
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.checkAuthenticationStatus()
                }
            }
            .store(in: &cancellables)
        
        // 监听内存警告
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    // 在内存警告时清理不必要的数据
                    self?.cleanupMemory()
                }
            }
            .store(in: &cancellables)
    }
    
    private func validateAndRefreshTokens() async {
        guard let tokens = authTokens else {
            logout()
            return
        }
        
        // 检查访问令牌是否过期（简化处理，假设令牌在1小时后过期）
        // 在实际应用中，应该从JWT token中解析过期时间
        let expirationDate = Date().addingTimeInterval(TimeInterval(tokens.expiresIn))
        
        if expirationDate <= Date() {
            // 令牌已过期，尝试刷新
            let refreshSuccess = await refreshTokens()
            if !refreshSuccess {
                return // 刷新失败，已在refreshTokens中处理注销
            }
        }
        
        // 令牌有效，恢复用户状态
        if let savedUser = loadUserFromDefaults() {
            self.currentUser = savedUser
            self.isAuthenticated = true
        } else {
            // 没有保存的用户信息，需要重新登录
            logout()
        }
    }
    
    private func saveUserToDefaults(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }
    
    private func loadUserFromDefaults() -> User? {
        guard let data = UserDefaults.standard.data(forKey: "currentUser"),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return nil
        }
        return user
    }
    
    private func clearUserFromDefaults() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    private func clearUserData() {
        // 清除用户相关的缓存数据
        // 这里可以添加清除其他用户相关数据的逻辑
        
        // 清除通知
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    private func cleanupMemory() {
        // 在内存警告时清理不必要的数据
        // 这里可以添加清理缓存等逻辑
    }
}