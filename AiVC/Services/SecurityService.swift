//
//  SecurityService.swift
//  语记
//
//  Created by AI Assistant on 2025/01/21.
//

import Foundation
import Network
import CryptoKit

// 安全事件类型
enum SecurityEventType: String, CaseIterable {
    case loginAttempt = "login_attempt"
    case loginSuccess = "login_success"
    case loginFailure = "login_failure"
    case accountLocked = "account_locked"
    case passwordReset = "password_reset"
    case suspiciousActivity = "suspicious_activity"
    case csrfAttempt = "csrf_attempt"
    case rateLimitExceeded = "rate_limit_exceeded"
}

// 安全事件记录
struct SecurityEvent {
    let id: UUID
    let type: SecurityEventType
    let userId: UUID?
    let ipAddress: String
    let userAgent: String
    let timestamp: Date
    let details: [String: Any]
    let severity: SecuritySeverity
    
    init(type: SecurityEventType, userId: UUID? = nil, ipAddress: String, userAgent: String, details: [String: Any] = [:], severity: SecuritySeverity = .low) {
        self.id = UUID()
        self.type = type
        self.userId = userId
        self.ipAddress = ipAddress
        self.userAgent = userAgent
        self.timestamp = Date()
        self.details = details
        self.severity = severity
    }
}

// 安全级别
enum SecuritySeverity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

// 登录失败记录
struct LoginFailureRecord {
    let ipAddress: String
    let userId: UUID?
    let timestamp: Date
    let reason: String
}

// 速率限制配置
struct RateLimitConfig {
    let maxAttempts: Int
    let timeWindow: TimeInterval // 秒
    let blockDuration: TimeInterval // 秒
}

class SecurityService {
    static let shared = SecurityService()
    
    private var loginFailures: [String: [LoginFailureRecord]] = [:] // IP地址 -> 失败记录
    private var userLoginFailures: [UUID: [LoginFailureRecord]] = [:] // 用户ID -> 失败记录
    private var blockedIPs: [String: Date] = [:] // IP地址 -> 解封时间
    private var blockedUsers: [UUID: Date] = [:] // 用户ID -> 解封时间
    private var csrfTokens: [String: Date] = [:] // CSRF令牌 -> 过期时间
    private var securityEvents: [SecurityEvent] = []
    
    // 配置
    private let ipRateLimitConfig = RateLimitConfig(maxAttempts: 5, timeWindow: 300, blockDuration: 900) // 5次/5分钟，封禁15分钟
    private let userRateLimitConfig = RateLimitConfig(maxAttempts: 3, timeWindow: 300, blockDuration: 1800) // 3次/5分钟，封禁30分钟
    private let csrfTokenExpiry: TimeInterval = 3600 // CSRF令牌1小时过期
    
    private let queue = DispatchQueue(label: "com.shengcai.security", attributes: .concurrent)
    
    init() {
        // 启动清理任务
        startCleanupTimer()
    }
    
    // MARK: - 登录失败限制
    
    /// 记录登录失败
    func recordLoginFailure(ipAddress: String, userId: UUID?, reason: String, userAgent: String) {
        queue.async(flags: .barrier) {
            let record = LoginFailureRecord(
                ipAddress: ipAddress,
                userId: userId,
                timestamp: Date(),
                reason: reason
            )
            
            // 记录IP失败
            if self.loginFailures[ipAddress] == nil {
                self.loginFailures[ipAddress] = []
            }
            self.loginFailures[ipAddress]?.append(record)
            
            // 记录用户失败
            if let userId = userId {
                if self.userLoginFailures[userId] == nil {
                    self.userLoginFailures[userId] = []
                }
                self.userLoginFailures[userId]?.append(record)
            }
            
            // 检查是否需要封禁
            self.checkAndApplyBlocks(ipAddress: ipAddress, userId: userId)
            
            // 记录安全事件
            let event = SecurityEvent(
                type: .loginFailure,
                userId: userId,
                ipAddress: ipAddress,
                userAgent: userAgent,
                details: ["reason": reason],
                severity: .medium
            )
            self.logSecurityEvent(event)
        }
    }
    
    /// 检查IP是否被封禁
    func isIPBlocked(_ ipAddress: String) -> Bool {
        return queue.sync {
            guard let unblockTime = blockedIPs[ipAddress] else {
                return false
            }
            
            if Date() >= unblockTime {
                blockedIPs.removeValue(forKey: ipAddress)
                return false
            }
            
            return true
        }
    }
    
    /// 检查用户是否被封禁
    func isUserBlocked(_ userId: UUID) -> Bool {
        return queue.sync {
            guard let unblockTime = blockedUsers[userId] else {
                return false
            }
            
            if Date() >= unblockTime {
                blockedUsers.removeValue(forKey: userId)
                return false
            }
            
            return true
        }
    }
    
    /// 获取IP剩余封禁时间
    func getIPBlockTimeRemaining(_ ipAddress: String) -> TimeInterval? {
        return queue.sync {
            guard let unblockTime = blockedIPs[ipAddress] else {
                return nil
            }
            
            let remaining = unblockTime.timeIntervalSince(Date())
            return remaining > 0 ? remaining : nil
        }
    }
    
    /// 获取用户剩余封禁时间
    func getUserBlockTimeRemaining(_ userId: UUID) -> TimeInterval? {
        return queue.sync {
            guard let unblockTime = blockedUsers[userId] else {
                return nil
            }
            
            let remaining = unblockTime.timeIntervalSince(Date())
            return remaining > 0 ? remaining : nil
        }
    }
    
    /// 清除登录失败记录（登录成功时调用）
    func clearLoginFailures(ipAddress: String, userId: UUID?) {
        queue.async(flags: .barrier) {
            self.loginFailures.removeValue(forKey: ipAddress)
            if let userId = userId {
                self.userLoginFailures.removeValue(forKey: userId)
            }
        }
    }
    
    private func checkAndApplyBlocks(ipAddress: String, userId: UUID?) {
        let now = Date()
        let timeWindow = ipRateLimitConfig.timeWindow
        
        // 检查IP封禁
        if let ipFailures = loginFailures[ipAddress] {
            let recentFailures = ipFailures.filter { now.timeIntervalSince($0.timestamp) <= timeWindow }
            if recentFailures.count >= ipRateLimitConfig.maxAttempts {
                blockedIPs[ipAddress] = now.addingTimeInterval(ipRateLimitConfig.blockDuration)
                
                let event = SecurityEvent(
                    type: .rateLimitExceeded,
                    userId: userId,
                    ipAddress: ipAddress,
                    userAgent: "",
                    details: ["type": "ip_block", "attempts": recentFailures.count],
                    severity: .high
                )
                logSecurityEvent(event)
            }
        }
        
        // 检查用户封禁
        if let userId = userId, let userFailures = userLoginFailures[userId] {
            let recentFailures = userFailures.filter { now.timeIntervalSince($0.timestamp) <= userRateLimitConfig.timeWindow }
            if recentFailures.count >= userRateLimitConfig.maxAttempts {
                blockedUsers[userId] = now.addingTimeInterval(userRateLimitConfig.blockDuration)
                
                let event = SecurityEvent(
                    type: .accountLocked,
                    userId: userId,
                    ipAddress: ipAddress,
                    userAgent: "",
                    details: ["type": "user_block", "attempts": recentFailures.count],
                    severity: .high
                )
                logSecurityEvent(event)
            }
        }
    }
    
    // MARK: - CSRF 防护
    
    /// 生成CSRF令牌
    func generateCSRFToken() -> String {
        let tokenData = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let token = tokenData.base64EncodedString()
        
        queue.async(flags: .barrier) {
            self.csrfTokens[token] = Date().addingTimeInterval(self.csrfTokenExpiry)
        }
        
        return token
    }
    
    /// 验证CSRF令牌
    func validateCSRFToken(_ token: String) -> Bool {
        return queue.sync {
            guard let expiryTime = csrfTokens[token] else {
                return false
            }
            
            if Date() >= expiryTime {
                csrfTokens.removeValue(forKey: token)
                return false
            }
            
            // 令牌使用后立即失效（一次性使用）
            csrfTokens.removeValue(forKey: token)
            return true
        }
    }
    
    /// 清理过期的CSRF令牌
    private func cleanupExpiredCSRFTokens() {
        queue.async(flags: .barrier) {
            let now = Date()
            self.csrfTokens = self.csrfTokens.filter { $0.value > now }
        }
    }
    
    // MARK: - 可疑活动检测
    
    /// 检测可疑登录活动
    func detectSuspiciousActivity(ipAddress: String, userAgent: String, userId: UUID?) -> Bool {
        // 检查是否来自新的地理位置（简化实现）
        let isSuspiciousLocation = checkSuspiciousLocation(ipAddress: ipAddress, userId: userId)
        
        // 检查是否使用新的设备/浏览器
        let isSuspiciousDevice = checkSuspiciousDevice(userAgent: userAgent, userId: userId)
        
        // 检查登录时间模式
        let isSuspiciousTime = checkSuspiciousTime(userId: userId)
        
        let isSuspicious = isSuspiciousLocation || isSuspiciousDevice || isSuspiciousTime
        
        if isSuspicious {
            let event = SecurityEvent(
                type: .suspiciousActivity,
                userId: userId,
                ipAddress: ipAddress,
                userAgent: userAgent,
                details: [
                    "suspicious_location": isSuspiciousLocation,
                    "suspicious_device": isSuspiciousDevice,
                    "suspicious_time": isSuspiciousTime
                ],
                severity: .medium
            )
            logSecurityEvent(event)
        }
        
        return isSuspicious
    }
    
    private func checkSuspiciousLocation(ipAddress: String, userId: UUID?) -> Bool {
        // 简化实现：检查IP地址是否在已知的安全范围内
        // 实际应用中可以集成地理位置API
        return false
    }
    
    private func checkSuspiciousDevice(userAgent: String, userId: UUID?) -> Bool {
        // 简化实现：检查User-Agent是否异常
        let suspiciousPatterns = ["bot", "crawler", "spider", "scraper"]
        return suspiciousPatterns.contains { userAgent.lowercased().contains($0) }
    }
    
    private func checkSuspiciousTime(userId: UUID?) -> Bool {
        // 简化实现：检查是否在异常时间登录
        let hour = Calendar.current.component(.hour, from: Date())
        return hour < 6 || hour > 23 // 凌晨6点前或晚上11点后
    }
    
    // MARK: - 安全事件日志
    
    /// 记录安全事件
    func logSecurityEvent(_ event: SecurityEvent) {
        queue.async(flags: .barrier) {
            self.securityEvents.append(event)
            
            // 保持最近1000条记录
            if self.securityEvents.count > 1000 {
                self.securityEvents.removeFirst(self.securityEvents.count - 1000)
            }
            
            // 打印高危事件
            if event.severity == .high || event.severity == .critical {
                print("[SECURITY] \(event.severity.rawValue.uppercased()): \(event.type.rawValue) from \(event.ipAddress)")
            }
        }
    }
    
    /// 获取安全事件
    func getSecurityEvents(userId: UUID? = nil, type: SecurityEventType? = nil, limit: Int = 100) -> [SecurityEvent] {
        return queue.sync {
            var events = securityEvents
            
            if let userId = userId {
                events = events.filter { $0.userId == userId }
            }
            
            if let type = type {
                events = events.filter { $0.type == type }
            }
            
            return Array(events.suffix(limit))
        }
    }
    
    // MARK: - 设备指纹
    
    /// 生成设备指纹
    func generateDeviceFingerprint(userAgent: String, ipAddress: String, additionalInfo: [String: String] = [:]) -> String {
        var fingerprintData = "\(userAgent)|\(ipAddress)"
        
        for (key, value) in additionalInfo.sorted(by: { $0.key < $1.key }) {
            fingerprintData += "|\(key):\(value)"
        }
        
        let data = fingerprintData.data(using: .utf8) ?? Data()
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - 清理任务
    
    private func startCleanupTimer() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in // 每5分钟清理一次
            self.performCleanup()
        }
    }
    
    private func performCleanup() {
        queue.async(flags: .barrier) {
            let now = Date()
            
            // 清理过期的登录失败记录
            for (ip, failures) in self.loginFailures {
                let validFailures = failures.filter { now.timeIntervalSince($0.timestamp) <= self.ipRateLimitConfig.timeWindow * 2 }
                if validFailures.isEmpty {
                    self.loginFailures.removeValue(forKey: ip)
                } else {
                    self.loginFailures[ip] = validFailures
                }
            }
            
            for (userId, failures) in self.userLoginFailures {
                let validFailures = failures.filter { now.timeIntervalSince($0.timestamp) <= self.userRateLimitConfig.timeWindow * 2 }
                if validFailures.isEmpty {
                    self.userLoginFailures.removeValue(forKey: userId)
                } else {
                    self.userLoginFailures[userId] = validFailures
                }
            }
            
            // 清理过期的封禁
            self.blockedIPs = self.blockedIPs.filter { $0.value > now }
            self.blockedUsers = self.blockedUsers.filter { $0.value > now }
            
            // 清理过期的CSRF令牌
            self.cleanupExpiredCSRFTokens()
        }
    }
    
    // MARK: - 统计信息
    
    /// 获取安全统计信息
    func getSecurityStats() -> [String: Any] {
        return queue.sync {
            return [
                "blocked_ips": blockedIPs.count,
                "blocked_users": blockedUsers.count,
                "active_csrf_tokens": csrfTokens.count,
                "total_security_events": securityEvents.count,
                "recent_login_failures": loginFailures.values.flatMap { $0 }.count,
                "high_severity_events": securityEvents.filter { $0.severity == .high || $0.severity == .critical }.count
            ]
        }
    }
}