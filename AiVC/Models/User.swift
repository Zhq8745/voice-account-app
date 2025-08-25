//
//  User.swift
//  AiVC
//
//  Created by AI Assistant on 2025/01/21.
//

import Foundation

// MARK: - User Model

struct User: Codable, Identifiable {
    let id: String
    let username: String
    let email: String
    let displayName: String?
    let avatar: String?
    let isEmailVerified: Bool
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    let lastLoginAt: Date?
    let profile: UserProfile?
    
    // Apple Sign In 相关字段
    let appleUserIdentifier: String?
    let loginMethod: LoginMethod
    
    enum LoginMethod: String, Codable {
        case traditional = "traditional"
        case apple = "apple"
        case biometric = "biometric"
    }
    
    init(
        id: String = UUID().uuidString,
        username: String,
        email: String,
        displayName: String? = nil,
        avatar: String? = nil,
        isEmailVerified: Bool = false,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastLoginAt: Date? = nil,
        profile: UserProfile? = nil,
        appleUserIdentifier: String? = nil,
        loginMethod: LoginMethod = .traditional
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.displayName = displayName
        self.avatar = avatar
        self.isEmailVerified = isEmailVerified
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastLoginAt = lastLoginAt
        self.profile = profile
        self.appleUserIdentifier = appleUserIdentifier
        self.loginMethod = loginMethod
    }
}

// MARK: - User Profile

struct UserProfile: Codable {
    let firstName: String?
    let lastName: String?
    let phone: String?
    let dateOfBirth: Date?
    let gender: Gender?
    let timezone: String?
    let language: String?
    let currency: String?
    
    enum Gender: String, Codable, CaseIterable {
        case male = "male"
        case female = "female"
        case other = "other"
        case preferNotToSay = "prefer_not_to_say"
    }
}

// MARK: - Authentication Models

struct LoginRequest: Codable {
    let identifier: String // 可以是用户名或邮箱
    let password: String
    let rememberMe: Bool
    let deviceInfo: [String: Any]
    let csrfToken: String
    
    enum CodingKeys: String, CodingKey {
        case identifier, password, rememberMe, csrfToken
        case deviceInfo = "device_info"
    }
    
    init(identifier: String, password: String, rememberMe: Bool = false, deviceInfo: [String: Any] = [:], csrfToken: String = "") {
        self.identifier = identifier
        self.password = password
        self.rememberMe = rememberMe
        self.deviceInfo = deviceInfo
        self.csrfToken = csrfToken
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(password, forKey: .password)
        try container.encode(rememberMe, forKey: .rememberMe)
        try container.encode(csrfToken, forKey: .csrfToken)
        
        // 将deviceInfo转换为JSON字符串
        if let data = try? JSONSerialization.data(withJSONObject: deviceInfo),
           let jsonString = String(data: data, encoding: .utf8) {
            try container.encode(jsonString, forKey: .deviceInfo)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(String.self, forKey: .identifier)
        password = try container.decode(String.self, forKey: .password)
        rememberMe = try container.decode(Bool.self, forKey: .rememberMe)
        csrfToken = try container.decode(String.self, forKey: .csrfToken)
        
        // 从JSON字符串解析deviceInfo
        if let jsonString = try? container.decode(String.self, forKey: .deviceInfo),
           let data = jsonString.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            deviceInfo = dict
        } else {
            deviceInfo = [:]
        }
    }
}

struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
    let confirmPassword: String
    let displayName: String?
    let acceptTerms: Bool
    let deviceInfo: [String: Any]
    let csrfToken: String
    
    enum CodingKeys: String, CodingKey {
        case username, email, password, confirmPassword, displayName, acceptTerms, csrfToken
        case deviceInfo = "device_info"
    }
    
    init(
        username: String,
        email: String,
        password: String,
        confirmPassword: String,
        displayName: String? = nil,
        acceptTerms: Bool = false,
        deviceInfo: [String: Any] = [:],
        csrfToken: String = ""
    ) {
        self.username = username
        self.email = email
        self.password = password
        self.confirmPassword = confirmPassword
        self.displayName = displayName
        self.acceptTerms = acceptTerms
        self.deviceInfo = deviceInfo
        self.csrfToken = csrfToken
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(username, forKey: .username)
        try container.encode(email, forKey: .email)
        try container.encode(password, forKey: .password)
        try container.encode(confirmPassword, forKey: .confirmPassword)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encode(acceptTerms, forKey: .acceptTerms)
        try container.encode(csrfToken, forKey: .csrfToken)
        
        if let data = try? JSONSerialization.data(withJSONObject: deviceInfo),
           let jsonString = String(data: data, encoding: .utf8) {
            try container.encode(jsonString, forKey: .deviceInfo)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        username = try container.decode(String.self, forKey: .username)
        email = try container.decode(String.self, forKey: .email)
        password = try container.decode(String.self, forKey: .password)
        confirmPassword = try container.decode(String.self, forKey: .confirmPassword)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        acceptTerms = try container.decode(Bool.self, forKey: .acceptTerms)
        csrfToken = try container.decode(String.self, forKey: .csrfToken)
        
        if let jsonString = try? container.decode(String.self, forKey: .deviceInfo),
           let data = jsonString.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            deviceInfo = dict
        } else {
            deviceInfo = [:]
        }
    }
}

struct LoginResult: Codable {
    let success: Bool
    let message: String?
    let user: User?
    let tokens: AuthTokens?
    let requiresEmailVerification: Bool
    let requiresTwoFactor: Bool
    
    init(
        success: Bool,
        message: String? = nil,
        user: User? = nil,
        tokens: AuthTokens? = nil,
        requiresEmailVerification: Bool = false,
        requiresTwoFactor: Bool = false
    ) {
        self.success = success
        self.message = message
        self.user = user
        self.tokens = tokens
        self.requiresEmailVerification = requiresEmailVerification
        self.requiresTwoFactor = requiresTwoFactor
    }
}

struct RegisterResult: Codable {
    let success: Bool
    let message: String?
    let user: User?
    let requiresEmailVerification: Bool
    
    init(
        success: Bool,
        message: String? = nil,
        user: User? = nil,
        requiresEmailVerification: Bool = true
    ) {
        self.success = success
        self.message = message
        self.user = user
        self.requiresEmailVerification = requiresEmailVerification
    }
}

struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
    
    init(
        accessToken: String,
        refreshToken: String,
        tokenType: String = "Bearer",
        expiresIn: Int = 3600
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.expiresIn = expiresIn
    }
}

// MARK: - Authentication Errors

enum LoginError: Error, LocalizedError {
    case invalidCredentials
    case accountLocked
    case accountNotVerified
    case tooManyAttempts
    case ipBlocked
    case suspiciousActivity
    case csrfTokenInvalid
    case networkError
    case serverError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "用户名或密码错误"
        case .accountLocked:
            return "账户已被锁定"
        case .accountNotVerified:
            return "账户尚未验证"
        case .tooManyAttempts:
            return "登录尝试次数过多"
        case .ipBlocked:
            return "IP地址已被封禁"
        case .suspiciousActivity:
            return "检测到可疑活动"
        case .csrfTokenInvalid:
            return "安全验证失败"
        case .networkError:
            return "网络连接失败"
        case .serverError:
            return "服务器错误"
        case .unknown:
            return "未知错误"
        }
    }
}

enum RegisterError: Error, LocalizedError {
    case usernameExists
    case emailExists
    case passwordTooWeak
    case passwordMismatch
    case invalidEmail
    case invalidUsername
    case termsNotAccepted
    case networkError
    case serverError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .usernameExists:
            return "用户名已存在"
        case .emailExists:
            return "邮箱已被注册"
        case .passwordTooWeak:
            return "密码强度不够"
        case .passwordMismatch:
            return "两次输入的密码不一致"
        case .invalidEmail:
            return "邮箱格式不正确"
        case .invalidUsername:
            return "用户名格式不正确"
        case .termsNotAccepted:
            return "请同意服务条款"
        case .networkError:
            return "网络连接失败"
        case .serverError:
            return "服务器错误"
        case .unknown:
            return "未知错误"
        }
    }
}

// MARK: - User Extensions

extension User {
    var fullName: String {
        if let profile = profile,
           let firstName = profile.firstName,
           let lastName = profile.lastName {
            return "\(firstName) \(lastName)"
        }
        return displayName ?? username
    }
    
    var initials: String {
        let name = fullName
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            let firstInitial = String(components[0].prefix(1))
            let lastInitial = String(components[1].prefix(1))
            return "\(firstInitial)\(lastInitial)".uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }
    
    var isProfileComplete: Bool {
        guard let profile = profile else { return false }
        return profile.firstName != nil &&
               profile.lastName != nil &&
               isEmailVerified
    }
}