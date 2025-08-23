#!/usr/bin/env swift

import Foundation
import Security

// 模拟SecurityManager的核心功能
class SecurityManager {
    private let service = "AiVC.APIKeys"
    
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
    
    // 从Keychain获取API密钥
    func getAPIKey(for type: APIKeyType) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: type.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    // 检查API密钥是否存在
    func hasAPIKey(for type: APIKeyType) -> Bool {
        return getAPIKey(for: type) != nil
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
            let middle = String(repeating: "*", count: max(0, key.count - 8))
            return "\(prefix)\(middle)\(suffix)"
        }
    }
    
    // 计算配置进度
    var configurationProgress: Double {
        let totalTypes = APIKeyType.allCases.count
        let configuredCount = APIKeyType.allCases.filter { hasAPIKey(for: $0) }.count
        return Double(configuredCount) / Double(totalTypes)
    }
    
    // 获取配置建议
    var configurationSuggestions: [String] {
        var suggestions: [String] = []
        
        if !hasAPIKey(for: .tongYiQianWen) {
            suggestions.append("请配置阿里云通义千问API密钥以启用AI分析功能")
        }
        
        if !hasAPIKey(for: .backup) {
            suggestions.append("建议配置备用API服务以提高系统可靠性")
        }
        
        if suggestions.isEmpty {
            suggestions.append("所有API密钥已配置完成")
        }
        
        return suggestions
    }
}

// 主检查函数
func checkAPIConfiguration() {
    let securityManager = SecurityManager()
    
    print("=== 阿里云通义千问API密钥配置检查 ===")
    print()
    
    // 1. 检查是否已配置API密钥
    let hasKey = securityManager.hasAPIKey(for: .tongYiQianWen)
    print("1. API密钥配置状态: \(hasKey ? "✅ 已配置" : "❌ 未配置")")
    
    // 2. 如果已配置，显示掩码后的密钥
    if let maskedKey = securityManager.getMaskedAPIKey(for: .tongYiQianWen) {
        print("2. 当前密钥 (掩码): \(maskedKey)")
    } else {
        print("2. 当前密钥: 无")
    }
    
    // 3. 配置进度
    let progress = securityManager.configurationProgress
    print("3. 配置进度: \(Int(progress * 100))%")
    
    // 4. 配置建议
    print("4. 配置建议:")
    for suggestion in securityManager.configurationSuggestions {
        print("   • \(suggestion)")
    }
    
    print()
    print("=== SecurityManager方法测试 ===")
    
    // 测试hasAPIKey方法
    print("hasAPIKey(for: .tongYiQianWen): \(securityManager.hasAPIKey(for: .tongYiQianWen))")
    print("hasAPIKey(for: .backup): \(securityManager.hasAPIKey(for: .backup))")
    
    // 测试getAPIKey方法
    if let key = securityManager.getAPIKey(for: .tongYiQianWen) {
        print("getAPIKey返回的密钥长度: \(key.count) 字符")
        print("密钥前缀: \(key.hasPrefix("sk-") ? "sk-" : "其他")")
    } else {
        print("getAPIKey返回: nil")
    }
    
    print()
    print("=== 检查完成 ===")
}

// 运行检查
checkAPIConfiguration()