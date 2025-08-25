//
//  LoginLogService.swift
//  AiVC
//
//  Created by AI Assistant on 2025/01/21.
//

import Foundation
import Network
import UIKit

// MARK: - Login Log Service

class LoginLogService {
    static let shared = LoginLogService()
    
    private let userDefaults = UserDefaults.standard
    private let logKey = "LoginLogs"
    private let maxLogCount = 1000
    
    private init() {
        setupNetworkMonitoring()
    }
    
    // MARK: - Log Models
    
    struct LoginLog: Codable, Identifiable {
        let id: String
        let userId: String?
        let username: String?
        let email: String?
        let action: LogAction
        let result: LogResult
        let timestamp: Date
        let deviceInfo: DeviceInfo
        let networkInfo: NetworkInfo
        let securityInfo: SecurityInfo
        let metadata: [String: String]
        
        init(
            userId: String? = nil,
            username: String? = nil,
            email: String? = nil,
            action: LogAction,
            result: LogResult,
            deviceInfo: DeviceInfo = DeviceInfo.current(),
            networkInfo: NetworkInfo = NetworkInfo.current(),
            securityInfo: SecurityInfo = SecurityInfo.current(),
            metadata: [String: String] = [:]
        ) {
            self.id = UUID().uuidString
            self.userId = userId
            self.username = username
            self.email = email
            self.action = action
            self.result = result
            self.timestamp = Date()
            self.deviceInfo = deviceInfo
            self.networkInfo = networkInfo
            self.securityInfo = securityInfo
            self.metadata = metadata
        }
    }
    
    enum LogAction: String, Codable, CaseIterable {
        case login = "LOGIN"
        case logout = "LOGOUT"
        case register = "REGISTER"
        case passwordReset = "PASSWORD_RESET"
        case passwordChange = "PASSWORD_CHANGE"
        case emailVerification = "EMAIL_VERIFICATION"
        case tokenRefresh = "TOKEN_REFRESH"
        case accountLock = "ACCOUNT_LOCK"
        case accountUnlock = "ACCOUNT_UNLOCK"
        case suspiciousActivity = "SUSPICIOUS_ACTIVITY"
        case securityAlert = "SECURITY_ALERT"
        case sessionExpired = "SESSION_EXPIRED"
        case deviceRegistration = "DEVICE_REGISTRATION"
        case twoFactorAuth = "TWO_FACTOR_AUTH"
        case apiAccess = "API_ACCESS"
        
        var displayName: String {
            switch self {
            case .login: return "登录"
            case .logout: return "登出"
            case .register: return "注册"
            case .passwordReset: return "密码重置"
            case .passwordChange: return "密码修改"
            case .emailVerification: return "邮箱验证"
            case .tokenRefresh: return "令牌刷新"
            case .accountLock: return "账户锁定"
            case .accountUnlock: return "账户解锁"
            case .suspiciousActivity: return "可疑活动"
            case .securityAlert: return "安全警报"
            case .sessionExpired: return "会话过期"
            case .deviceRegistration: return "设备注册"
            case .twoFactorAuth: return "双因素认证"
            case .apiAccess: return "API访问"
            }
        }
    }
    
    enum LogResult: String, Codable {
        case success = "SUCCESS"
        case failure = "FAILURE"
        case blocked = "BLOCKED"
        case warning = "WARNING"
        case info = "INFO"
        
        var displayName: String {
            switch self {
            case .success: return "成功"
            case .failure: return "失败"
            case .blocked: return "被阻止"
            case .warning: return "警告"
            case .info: return "信息"
            }
        }
        
        var severity: Int {
            switch self {
            case .success: return 1
            case .info: return 2
            case .warning: return 3
            case .failure: return 4
            case .blocked: return 5
            }
        }
    }
    
    struct DeviceInfo: Codable {
        let deviceId: String
        let deviceName: String
        let systemName: String
        let systemVersion: String
        let model: String
        let appVersion: String
        let buildNumber: String
        let locale: String
        let timezone: String
        
        static func current() -> DeviceInfo {
            let device = UIDevice.current
            let bundle = Bundle.main
            let locale = Locale.current
            let timezone = TimeZone.current
            
            return DeviceInfo(
                deviceId: device.identifierForVendor?.uuidString ?? "unknown",
                deviceName: device.name,
                systemName: device.systemName,
                systemVersion: device.systemVersion,
                model: device.model,
                appVersion: bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                buildNumber: bundle.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
                locale: locale.identifier,
                timezone: timezone.identifier
            )
        }
    }
    
    struct NetworkInfo: Codable {
        let ipAddress: String?
        let connectionType: String
        let isVPN: Bool
        let carrier: String?
        
        static func current() -> NetworkInfo {
            return NetworkInfo(
                ipAddress: getIPAddress(),
                connectionType: getConnectionType(),
                isVPN: isUsingVPN(),
                carrier: getCarrierName()
            )
        }
        
        private static func getIPAddress() -> String? {
            var address: String?
            var ifaddr: UnsafeMutablePointer<ifaddrs>?
            
            if getifaddrs(&ifaddr) == 0 {
                var ptr = ifaddr
                while ptr != nil {
                    defer { ptr = ptr?.pointee.ifa_next }
                    
                    let interface = ptr?.pointee
                    let addrFamily = interface?.ifa_addr.pointee.sa_family
                    
                    if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                        let name = String(cString: (interface?.ifa_name)!)
                        if name == "en0" || name == "pdp_ip0" {
                            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                            getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                            address = String(cString: hostname)
                        }
                    }
                }
                freeifaddrs(ifaddr)
            }
            
            return address
        }
        
        private static func getConnectionType() -> String {
            // 简化的网络类型检测
            return "WiFi" // 在实际应用中需要更复杂的检测逻辑
        }
        
        private static func isUsingVPN() -> Bool {
            // 简化的VPN检测
            return false // 在实际应用中需要检测VPN连接
        }
        
        private static func getCarrierName() -> String? {
            // 简化的运营商检测
            return nil // 在实际应用中需要使用CoreTelephony框架
        }
    }
    
    struct SecurityInfo: Codable {
        let isJailbroken: Bool
        let isDebuggerAttached: Bool
        let isSimulator: Bool
        let hasPasscode: Bool
        let biometricType: String?
        let riskScore: Int
        
        static func current() -> SecurityInfo {
            return SecurityInfo(
                isJailbroken: isDeviceJailbroken(),
                isDebuggerAttached: isDebuggerPresent(),
                isSimulator: isRunningOnSimulator(),
                hasPasscode: hasDevicePasscode(),
                biometricType: getBiometricType(),
                riskScore: calculateRiskScore()
            )
        }
        
        private static func isDeviceJailbroken() -> Bool {
            // 简化的越狱检测
            let jailbreakPaths = [
                "/Applications/Cydia.app",
                "/Library/MobileSubstrate/MobileSubstrate.dylib",
                "/bin/bash",
                "/usr/sbin/sshd",
                "/etc/apt"
            ]
            
            for path in jailbreakPaths {
                if FileManager.default.fileExists(atPath: path) {
                    return true
                }
            }
            
            return false
        }
        
        private static func isDebuggerPresent() -> Bool {
            var info = kinfo_proc()
            var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
            var size = MemoryLayout<kinfo_proc>.stride
            
            let result = sysctl(&mib, u_int(mib.count), &info, &size, nil, 0)
            
            return result == 0 && (info.kp_proc.p_flag & P_TRACED) != 0
        }
        
        private static func isRunningOnSimulator() -> Bool {
            #if targetEnvironment(simulator)
            return true
            #else
            return false
            #endif
        }
        
        private static func hasDevicePasscode() -> Bool {
            // 简化的密码检测
            return true // 在实际应用中需要使用LocalAuthentication框架
        }
        
        private static func getBiometricType() -> String? {
            // 简化的生物识别检测
            return "TouchID" // 在实际应用中需要使用LocalAuthentication框架
        }
        
        private static func calculateRiskScore() -> Int {
            var score = 0
            
            if isDeviceJailbroken() { score += 50 }
            if isDebuggerPresent() { score += 30 }
            if isRunningOnSimulator() { score += 20 }
            if !hasDevicePasscode() { score += 20 }
            
            return min(score, 100)
        }
    }
    
    // MARK: - Network Monitoring
    
    private var networkMonitor: NWPathMonitor?
    private var currentNetworkPath: NWPath?
    
    private func setupNetworkMonitoring() {
        networkMonitor = NWPathMonitor()
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            self?.currentNetworkPath = path
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor?.start(queue: queue)
    }
    
    // MARK: - Logging Methods
    
    func logLogin(userId: String?, username: String?, email: String?, success: Bool, failureReason: String? = nil) {
        let result: LogResult = success ? .success : .failure
        var metadata: [String: String] = [:]
        
        if let reason = failureReason {
            metadata["failure_reason"] = reason
        }
        
        let log = LoginLog(
            userId: userId,
            username: username,
            email: email,
            action: .login,
            result: result,
            metadata: metadata
        )
        
        saveLog(log)
        
        // 检查可疑活动
        if !success {
            checkSuspiciousActivity(username: username, email: email)
        }
    }
    
    func logLogout(userId: String, username: String?) {
        let log = LoginLog(
            userId: userId,
            username: username,
            email: nil,
            action: .logout,
            result: .success
        )
        
        saveLog(log)
    }
    
    func logRegistration(userId: String?, username: String?, email: String?, success: Bool, failureReason: String? = nil) {
        let result: LogResult = success ? .success : .failure
        var metadata: [String: String] = [:]
        
        if let reason = failureReason {
            metadata["failure_reason"] = reason
        }
        
        let log = LoginLog(
            userId: userId,
            username: username,
            email: email,
            action: .register,
            result: result,
            metadata: metadata
        )
        
        saveLog(log)
    }
    
    func logPasswordReset(email: String, success: Bool, step: String) {
        let result: LogResult = success ? .success : .failure
        let metadata = ["step": step]
        
        let log = LoginLog(
            userId: nil,
            username: nil,
            email: email,
            action: .passwordReset,
            result: result,
            metadata: metadata
        )
        
        saveLog(log)
    }
    
    func logSecurityEvent(userId: String?, action: LogAction, result: LogResult, details: [String: String] = [:]) {
        let log = LoginLog(
            userId: userId,
            username: nil,
            email: nil,
            action: action,
            result: result,
            metadata: details
        )
        
        saveLog(log)
        
        // 高风险事件立即处理
        if result == .blocked || action == .suspiciousActivity {
            handleHighRiskEvent(log)
        }
    }
    
    func logAPIAccess(userId: String?, endpoint: String, method: String, statusCode: Int) {
        let result: LogResult
        switch statusCode {
        case 200...299: result = .success
        case 400...499: result = .failure
        case 500...599: result = .failure
        default: result = .info
        }
        
        let metadata = [
            "endpoint": endpoint,
            "method": method,
            "status_code": String(statusCode)
        ]
        
        let log = LoginLog(
            userId: userId,
            username: nil,
            email: nil,
            action: .apiAccess,
            result: result,
            metadata: metadata
        )
        
        saveLog(log)
    }
    
    // MARK: - Log Management
    
    private func saveLog(_ log: LoginLog) {
        var logs = getLogs()
        logs.insert(log, at: 0)
        
        // 限制日志数量
        if logs.count > maxLogCount {
            logs = Array(logs.prefix(maxLogCount))
        }
        
        if let data = try? JSONEncoder().encode(logs) {
            userDefaults.set(data, forKey: logKey)
        }
        
        // 打印到控制台（开发环境）
        printLog(log)
        
        // 发送到远程日志服务（生产环境）
        sendToRemoteLogging(log)
    }
    
    func getLogs(limit: Int? = nil) -> [LoginLog] {
        guard let data = userDefaults.data(forKey: logKey),
              let logs = try? JSONDecoder().decode([LoginLog].self, from: data) else {
            return []
        }
        
        if let limit = limit {
            return Array(logs.prefix(limit))
        }
        
        return logs
    }
    
    func getLogsForUser(_ userId: String, limit: Int = 50) -> [LoginLog] {
        return getLogs()
            .filter { $0.userId == userId }
            .prefix(limit)
            .map { $0 }
    }
    
    func getLogsByAction(_ action: LogAction, limit: Int = 50) -> [LoginLog] {
        return getLogs()
            .filter { $0.action == action }
            .prefix(limit)
            .map { $0 }
    }
    
    func getLogsByDateRange(from startDate: Date, to endDate: Date) -> [LoginLog] {
        return getLogs()
            .filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }
    
    func clearLogs() {
        userDefaults.removeObject(forKey: logKey)
    }
    
    // MARK: - Security Analysis
    
    private func checkSuspiciousActivity(username: String?, email: String?) {
        let recentLogs = getLogs(limit: 100)
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        
        // 检查一小时内的失败登录次数
        let recentFailures = recentLogs.filter { log in
            log.timestamp >= oneHourAgo &&
            log.action == .login &&
            log.result == .failure &&
            (log.username == username || log.email == email)
        }
        
        if recentFailures.count >= 5 {
            logSecurityEvent(
                userId: nil,
                action: .suspiciousActivity,
                result: .warning,
                details: [
                    "type": "multiple_failed_logins",
                    "count": String(recentFailures.count),
                    "username": username ?? "",
                    "email": email ?? ""
                ]
            )
        }
        
        // 检查来自不同设备的登录尝试
        let uniqueDevices = Set(recentFailures.map { $0.deviceInfo.deviceId })
        if uniqueDevices.count >= 3 {
            logSecurityEvent(
                userId: nil,
                action: .suspiciousActivity,
                result: .warning,
                details: [
                    "type": "multiple_devices",
                    "device_count": String(uniqueDevices.count)
                ]
            )
        }
    }
    
    private func handleHighRiskEvent(_ log: LoginLog) {
        // 在实际应用中，这里可以:
        // 1. 发送安全警报邮件
        // 2. 触发账户保护措施
        // 3. 通知安全团队
        // 4. 自动锁定账户
        
        print("🚨 HIGH RISK EVENT DETECTED: \(log.action.displayName) - \(log.result.displayName)")
    }
    
    // MARK: - Logging Output
    
    private func printLog(_ log: LoginLog) {
        let timestamp = DateFormatter.logFormatter.string(from: log.timestamp)
        let deviceInfo = "\(log.deviceInfo.deviceName) (\(log.deviceInfo.systemName) \(log.deviceInfo.systemVersion))"
        let networkInfo = log.networkInfo.ipAddress ?? "unknown"
        
        print("""
        📝 [LOGIN_LOG] \(timestamp)
        Action: \(log.action.displayName)
        Result: \(log.result.displayName)
        User: \(log.username ?? log.email ?? "unknown")
        Device: \(deviceInfo)
        IP: \(networkInfo)
        Risk Score: \(log.securityInfo.riskScore)
        Metadata: \(log.metadata)
        """)
    }
    
    private func sendToRemoteLogging(_ log: LoginLog) {
        // 在实际应用中，这里会发送到远程日志服务
        // 例如: Elasticsearch, Splunk, CloudWatch等
    }
    
    // MARK: - Statistics
    
    func getLoginStatistics(for userId: String, days: Int = 30) -> LoginStatistics {
        let startDate = Date().addingTimeInterval(-TimeInterval(days * 24 * 3600))
        let userLogs = getLogsForUser(userId)
            .filter { $0.timestamp >= startDate }
        
        let loginLogs = userLogs.filter { $0.action == .login }
        let successfulLogins = loginLogs.filter { $0.result == .success }
        let failedLogins = loginLogs.filter { $0.result == .failure }
        
        let uniqueDevices = Set(loginLogs.map { $0.deviceInfo.deviceId })
        let uniqueIPs = Set(loginLogs.compactMap { $0.networkInfo.ipAddress })
        
        return LoginStatistics(
            totalLogins: loginLogs.count,
            successfulLogins: successfulLogins.count,
            failedLogins: failedLogins.count,
            uniqueDevices: uniqueDevices.count,
            uniqueIPs: uniqueIPs.count,
            lastLoginDate: successfulLogins.first?.timestamp,
            averageRiskScore: loginLogs.map { $0.securityInfo.riskScore }.reduce(0, +) / max(loginLogs.count, 1)
        )
    }
    
    struct LoginStatistics {
        let totalLogins: Int
        let successfulLogins: Int
        let failedLogins: Int
        let uniqueDevices: Int
        let uniqueIPs: Int
        let lastLoginDate: Date?
        let averageRiskScore: Int
        
        var successRate: Double {
            guard totalLogins > 0 else { return 0 }
            return Double(successfulLogins) / Double(totalLogins)
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}