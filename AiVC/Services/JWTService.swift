//
//  JWTService.swift
//  语记
//
//  Created by AI Assistant on 2025/01/21.
//

import Foundation
import CryptoKit

// JWT载荷
struct JWTPayload: Codable {
    let sub: String // 用户ID
    let iat: TimeInterval // 签发时间
    let exp: TimeInterval // 过期时间
    let jti: String // JWT ID
    let type: TokenType // 令牌类型
    let deviceId: String? // 设备ID
    let sessionId: String? // 会话ID
    
    enum TokenType: String, Codable {
        case access = "access"
        case refresh = "refresh"
    }
}

// JWT头部
struct JWTHeader: Codable {
    let alg: String = "HS256"
    let typ: String = "JWT"
}

// 令牌对
struct TokenPair {
    let accessToken: String
    let refreshToken: String
    let expiresIn: TimeInterval
    let tokenType: String = "Bearer"
}

// JWT验证结果
struct JWTValidationResult {
    let isValid: Bool
    let payload: JWTPayload?
    let error: JWTError?
}

// JWT错误类型
enum JWTError: Error, LocalizedError {
    case invalidFormat
    case invalidHeader
    case invalidPayload
    case invalidSignature
    case tokenExpired
    case tokenNotYetValid
    case missingClaims
    case invalidTokenType
    case signingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "JWT格式无效"
        case .invalidHeader:
            return "JWT头部无效"
        case .invalidPayload:
            return "JWT载荷无效"
        case .invalidSignature:
            return "JWT签名无效"
        case .tokenExpired:
            return "令牌已过期"
        case .tokenNotYetValid:
            return "令牌尚未生效"
        case .missingClaims:
            return "缺少必要的声明"
        case .invalidTokenType:
            return "令牌类型无效"
        case .signingFailed:
            return "签名失败"
        }
    }
}

class JWTService {
    static let shared = JWTService()
    
    private let secretKey: String
    private let accessTokenExpiry: TimeInterval = 15 * 60 // 15分钟
    private let refreshTokenExpiry: TimeInterval = 7 * 24 * 60 * 60 // 7天
    
    // 黑名单令牌（用于登出）
    private var blacklistedTokens: Set<String> = []
    private let blacklistQueue = DispatchQueue(label: "com.shengcai.jwt.blacklist", attributes: .concurrent)
    
    private init() {
        // 在实际应用中，密钥应该从安全的地方获取（如Keychain、环境变量等）
        self.secretKey = "your-super-secret-jwt-key-change-this-in-production"
        
        // 启动清理任务
        startBlacklistCleanup()
    }
    
    // MARK: - 令牌生成
    
    /// 生成访问令牌和刷新令牌对
    func generateTokenPair(userId: UUID, deviceId: String? = nil, sessionId: String? = nil) -> TokenPair? {
        guard let accessToken = generateAccessToken(userId: userId, deviceId: deviceId, sessionId: sessionId),
              let refreshToken = generateRefreshToken(userId: userId, deviceId: deviceId, sessionId: sessionId) else {
            return nil
        }
        
        return TokenPair(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: accessTokenExpiry
        )
    }
    
    /// 生成访问令牌
    func generateAccessToken(userId: UUID, deviceId: String? = nil, sessionId: String? = nil) -> String? {
        let now = Date().timeIntervalSince1970
        let payload = JWTPayload(
            sub: userId.uuidString,
            iat: now,
            exp: now + accessTokenExpiry,
            jti: UUID().uuidString,
            type: .access,
            deviceId: deviceId,
            sessionId: sessionId
        )
        
        return generateJWT(payload: payload)
    }
    
    /// 生成刷新令牌
    func generateRefreshToken(userId: UUID, deviceId: String? = nil, sessionId: String? = nil) -> String? {
        let now = Date().timeIntervalSince1970
        let payload = JWTPayload(
            sub: userId.uuidString,
            iat: now,
            exp: now + refreshTokenExpiry,
            jti: UUID().uuidString,
            type: .refresh,
            deviceId: deviceId,
            sessionId: sessionId
        )
        
        return generateJWT(payload: payload)
    }
    
    private func generateJWT(payload: JWTPayload) -> String? {
        do {
            // 编码头部
            let header = JWTHeader()
            let headerData = try JSONEncoder().encode(header)
            let headerBase64 = headerData.base64URLEncodedString()
            
            // 编码载荷
            let payloadData = try JSONEncoder().encode(payload)
            let payloadBase64 = payloadData.base64URLEncodedString()
            
            // 创建签名
            let message = "\(headerBase64).\(payloadBase64)"
            guard let signature = sign(message: message) else {
                return nil
            }
            
            return "\(message).\(signature)"
        } catch {
            print("JWT生成失败: \(error)")
            return nil
        }
    }
    
    // MARK: - 令牌验证
    
    /// 验证JWT令牌
    func validateToken(_ token: String, expectedType: JWTPayload.TokenType? = nil) -> JWTValidationResult {
        // 检查黑名单
        if isTokenBlacklisted(token) {
            return JWTValidationResult(isValid: false, payload: nil, error: .tokenExpired)
        }
        
        // 分割令牌
        let components = token.components(separatedBy: ".")
        guard components.count == 3 else {
            return JWTValidationResult(isValid: false, payload: nil, error: .invalidFormat)
        }
        
        let headerBase64 = components[0]
        let payloadBase64 = components[1]
        let signature = components[2]
        
        // 验证签名
        let message = "\(headerBase64).\(payloadBase64)"
        guard verifySignature(message: message, signature: signature) else {
            return JWTValidationResult(isValid: false, payload: nil, error: .invalidSignature)
        }
        
        // 解码载荷
        guard let payloadData = Data(base64URLEncoded: payloadBase64) else {
            return JWTValidationResult(isValid: false, payload: nil, error: .invalidPayload)
        }
        
        do {
            let payload = try JSONDecoder().decode(JWTPayload.self, from: payloadData)
            
            // 验证时间
            let now = Date().timeIntervalSince1970
            if payload.exp < now {
                return JWTValidationResult(isValid: false, payload: payload, error: .tokenExpired)
            }
            
            if payload.iat > now + 60 { // 允许1分钟的时钟偏差
                return JWTValidationResult(isValid: false, payload: payload, error: .tokenNotYetValid)
            }
            
            // 验证令牌类型
            if let expectedType = expectedType, payload.type != expectedType {
                return JWTValidationResult(isValid: false, payload: payload, error: .invalidTokenType)
            }
            
            return JWTValidationResult(isValid: true, payload: payload, error: nil)
        } catch {
            return JWTValidationResult(isValid: false, payload: nil, error: .invalidPayload)
        }
    }
    
    /// 刷新访问令牌
    func refreshAccessToken(_ refreshToken: String) -> String? {
        let result = validateToken(refreshToken, expectedType: .refresh)
        guard result.isValid, let payload = result.payload else {
            return nil
        }
        
        guard let userId = UUID(uuidString: payload.sub) else {
            return nil
        }
        
        return generateAccessToken(
            userId: userId,
            deviceId: payload.deviceId,
            sessionId: payload.sessionId
        )
    }
    
    // MARK: - 令牌管理
    
    /// 将令牌加入黑名单（用于登出）
    func blacklistToken(_ token: String) {
        blacklistQueue.async(flags: .barrier) {
            self.blacklistedTokens.insert(token)
        }
    }
    
    /// 检查令牌是否在黑名单中
    func isTokenBlacklisted(_ token: String) -> Bool {
        return blacklistQueue.sync {
            return blacklistedTokens.contains(token)
        }
    }
    
    /// 从令牌中提取用户ID
    func extractUserId(from token: String) -> UUID? {
        let result = validateToken(token)
        guard result.isValid, let payload = result.payload else {
            return nil
        }
        
        return UUID(uuidString: payload.sub)
    }
    
    /// 从令牌中提取会话ID
    func extractSessionId(from token: String) -> String? {
        let result = validateToken(token)
        guard result.isValid, let payload = result.payload else {
            return nil
        }
        
        return payload.sessionId
    }
    
    /// 检查令牌是否即将过期（5分钟内）
    func isTokenExpiringSoon(_ token: String, threshold: TimeInterval = 300) -> Bool {
        let result = validateToken(token)
        guard result.isValid, let payload = result.payload else {
            return true
        }
        
        let now = Date().timeIntervalSince1970
        return payload.exp - now <= threshold
    }
    
    // MARK: - 签名和验证
    
    private func sign(message: String) -> String? {
        guard let messageData = message.data(using: .utf8),
              let keyData = secretKey.data(using: .utf8) else {
            return nil
        }
        
        let key = SymmetricKey(data: keyData)
        let signature = HMAC<SHA256>.authenticationCode(for: messageData, using: key)
        
        return Data(signature).base64URLEncodedString()
    }
    
    private func verifySignature(message: String, signature: String) -> Bool {
        guard let expectedSignature = sign(message: message) else {
            return false
        }
        
        return expectedSignature == signature
    }
    
    // MARK: - 清理任务
    
    private func startBlacklistCleanup() {
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in // 每小时清理一次
            self.cleanupBlacklist()
        }
    }
    
    private func cleanupBlacklist() {
        blacklistQueue.async(flags: .barrier) {
            // 移除已过期的令牌（无法验证的令牌认为已过期）
            self.blacklistedTokens = self.blacklistedTokens.filter { token in
                let result = self.validateToken(token)
                return result.isValid || result.error == .tokenExpired
            }
        }
    }
}

// MARK: - Base64URL 编码扩展

extension Data {
    func base64URLEncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    init?(base64URLEncoded string: String) {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // 添加必要的填充
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        self.init(base64Encoded: base64)
    }
}