//
//  SecurityManager.swift
//  AiVC
//
//  Created by AI Assistant on 2024/01/01.
//

import Foundation
import Security
import SwiftUI
import Combine

// 安全管理器，负责API密钥的安全存储和管理
class SecurityManager: ObservableObject {
    static let shared = SecurityManager()
    
    // 发布配置状态变化
    @Published private(set) var configurationChanged = false
    
    private init() {}
    
    // Keychain服务标识符
    private let service = "com.aivc.api-keys"
    
    // API密钥类型
    enum APIKeyType: String, CaseIterable {
        case tongYiQianWen = "tongyi_qianwen_api_key"
        case backup = "backup_api_key"
        
        var displayName: String {
            switch self {
            case .tongYiQianWen:
                return "阿里云通义千问"
            case .backup:
                return "备用API服务"
            }
        }
    }
    
    // 存储API密钥到Keychain
    func storeAPIKey(_ key: String, for type: APIKeyType) -> Bool {
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("SecurityManager: API密钥不能为空")
            return false
        }
        
        // 删除现有密钥（如果存在）
        let _ = deleteAPIKey(for: type)
        
        // 准备存储数据
        let keyData = key.data(using: .utf8)!
        
        // Keychain查询字典
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: type.rawValue,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // 添加到Keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("SecurityManager: \(type.displayName) API密钥存储成功")
            DispatchQueue.main.async {
                self.configurationChanged.toggle()
            }
            return true
        } else {
            print("SecurityManager: \(type.displayName) API密钥存储失败，错误代码: \(status)")
            return false
        }
    }
    
    // 从Keychain获取API密钥（开发者统一配置模式）
    func getAPIKey(for type: APIKeyType) -> String? {
        // 开发者统一配置模式：通义千问API密钥已硬编码到服务中
        switch type {
        case .tongYiQianWen:
            // 返回固定值表示已配置（实际密钥在TongYiQianWenService中硬编码）
            return "sk-configured-by-developer"
        case .backup:
            // 备用服务仍使用原有逻辑
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: type.rawValue,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]
            
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            
            if status == errSecSuccess {
                if let data = result as? Data,
                   let key = String(data: data, encoding: .utf8) {
                    return key
                }
            } else if status == errSecItemNotFound {
                print("SecurityManager: \(type.displayName) API密钥未找到")
            } else {
                print("SecurityManager: 获取\(type.displayName) API密钥失败，错误代码: \(status)")
            }
            
            return nil
        }
    }
    
    // 删除API密钥
    func deleteAPIKey(for type: APIKeyType) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: type.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            print("SecurityManager: \(type.displayName) API密钥删除成功")
            DispatchQueue.main.async {
                self.configurationChanged.toggle()
            }
            return true
        } else {
            print("SecurityManager: 删除\(type.displayName) API密钥失败，错误代码: \(status)")
            return false
        }
    }
    
    // 更新API密钥
    func updateAPIKey(_ newKey: String, for type: APIKeyType) -> Bool {
        guard !newKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("SecurityManager: 新API密钥不能为空")
            return false
        }
        
        // 检查是否已存在
        if getAPIKey(for: type) != nil {
            // 更新现有密钥
            let keyData = newKey.data(using: .utf8)!
            
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: type.rawValue
            ]
            
            let updateAttributes: [String: Any] = [
                kSecValueData as String: keyData
            ]
            
            let status = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
            
            if status == errSecSuccess {
                print("SecurityManager: \(type.displayName) API密钥更新成功")
                DispatchQueue.main.async {
                    self.configurationChanged.toggle()
                }
                return true
            } else {
                print("SecurityManager: 更新\(type.displayName) API密钥失败，错误代码: \(status)")
                return false
            }
        } else {
            // 创建新密钥
            return storeAPIKey(newKey, for: type)
        }
    }
    
    // 检查API密钥是否存在（开发者统一配置模式）
    func hasAPIKey(for type: APIKeyType) -> Bool {
        switch type {
        case .tongYiQianWen:
            // 通义千问API密钥由开发者统一配置，始终返回true
            return true
        case .backup:
            // 备用服务仍使用原有逻辑
            return getAPIKey(for: type) != nil
        }
    }
    
    // 验证API密钥格式
    func validateAPIKey(_ key: String, for type: APIKeyType) -> ValidationResult {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 基本验证
        guard !trimmedKey.isEmpty else {
            return ValidationResult(isValid: false, message: "API密钥不能为空")
        }
        
        guard trimmedKey.count >= 10 else {
            return ValidationResult(isValid: false, message: "API密钥长度过短")
        }
        
        // 根据不同类型进行特定验证
        switch type {
        case .tongYiQianWen:
            return validateTongYiQianWenKey(trimmedKey)
        case .backup:
            return ValidationResult(isValid: true, message: "备用密钥格式正确")
        }
    }
    
    // 验证通义千问API密钥格式
    private func validateTongYiQianWenKey(_ key: String) -> ValidationResult {
        // 通义千问API密钥通常以sk-开头
        if key.hasPrefix("sk-") {
            if key.count >= 20 && key.count <= 100 {
                // 检查是否包含有效字符
                let validCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
                if key.rangeOfCharacter(from: validCharacterSet.inverted) == nil {
                    return ValidationResult(isValid: true, message: "通义千问API密钥格式正确")
                } else {
                    return ValidationResult(isValid: false, message: "API密钥包含无效字符")
                }
            } else {
                return ValidationResult(isValid: false, message: "API密钥长度不符合要求")
            }
        } else {
            return ValidationResult(isValid: false, message: "通义千问API密钥应以'sk-'开头")
        }
    }
    
    // 获取所有已配置的API密钥状态
    func getAllAPIKeyStatus() -> [APIKeyStatus] {
        return APIKeyType.allCases.map { type in
            APIKeyStatus(
                type: type,
                isConfigured: hasAPIKey(for: type),
                lastUpdated: getAPIKeyLastUpdated(for: type)
            )
        }
    }
    
    // 获取API密钥最后更新时间（模拟实现）
    private func getAPIKeyLastUpdated(for type: APIKeyType) -> Date? {
        // 在实际实现中，可以在Keychain中存储时间戳
        // 这里返回nil表示未知
        return hasAPIKey(for: type) ? Date() : nil
    }
    
    // 清除所有API密钥
    func clearAllAPIKeys() -> Bool {
        var allSuccess = true
        
        for type in APIKeyType.allCases {
            if !deleteAPIKey(for: type) {
                allSuccess = false
            }
        }
        
        return allSuccess
    }
    
    // 导出配置（不包含实际密钥，仅配置状态）
    func exportConfiguration() -> [String: Any] {
        let status = getAllAPIKeyStatus()
        return [
            "configured_services": status.filter { $0.isConfigured }.map { $0.type.rawValue },
            "total_services": APIKeyType.allCases.count,
            "export_date": ISO8601DateFormatter().string(from: Date())
        ]
    }
    
    // 生成API密钥掩码（用于显示）
    func getMaskedAPIKey(for type: APIKeyType) -> String? {
        guard let key = getAPIKey(for: type) else {
            return nil
        }
        
        if key.count <= 8 {
            return String(repeating: "*", count: key.count)
        } else {
            let prefix = String(key.prefix(4))
            let suffix = String(key.suffix(4))
            let middle = String(repeating: "*", count: key.count - 8)
            return "\(prefix)\(middle)\(suffix)"
        }
    }
}

// 验证结果结构
struct ValidationResult {
    let isValid: Bool
    let message: String
}

// API密钥状态结构
struct APIKeyStatus {
    let type: SecurityManager.APIKeyType
    let isConfigured: Bool
    let lastUpdated: Date?
    
    var displayStatus: String {
        if isConfigured {
            if let date = lastUpdated {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                return "已配置 (\(formatter.string(from: date)))"
            } else {
                return "已配置"
            }
        } else {
            return "未配置"
        }
    }
}

// SecurityManager扩展：便捷方法
extension SecurityManager {
    
    // 快速设置通义千问API密钥
    func setupTongYiQianWenAPI(key: String) -> (success: Bool, message: String) {
        let validation = validateAPIKey(key, for: .tongYiQianWen)
        
        guard validation.isValid else {
            return (false, validation.message)
        }
        
        let success = storeAPIKey(key, for: .tongYiQianWen)
        let message = success ? "通义千问API密钥配置成功" : "通义千问API密钥配置失败"
        
        return (success, message)
    }
    
    // 检查是否已完成基本配置
    var isBasicConfigurationComplete: Bool {
        return hasAPIKey(for: .tongYiQianWen)
    }
    
    // 获取配置完成度
    var configurationProgress: Float {
        let configuredCount = getAllAPIKeyStatus().filter { $0.isConfigured }.count
        let totalCount = APIKeyType.allCases.count
        return Float(configuredCount) / Float(totalCount)
    }
    
    // 获取配置建议（开发者统一配置模式）
    var configurationSuggestions: [String] {
        var suggestions: [String] = []
        
        // 通义千问API密钥由开发者统一配置，无需用户配置
        if !hasAPIKey(for: .backup) {
            suggestions.append("备用API服务可选配置")
        }
        
        if suggestions.isEmpty {
            suggestions.append("AI功能已就绪，无需额外配置")
        }
        
        return suggestions
    }
}