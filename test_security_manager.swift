#!/usr/bin/env swift

import Foundation
import Security

// 模拟SecurityManager的完整实现来测试API密钥读取
class TestSecurityManager {
    static let shared = TestSecurityManager()
    
    private init() {}
    
    // 使用与实际SecurityManager相同的服务标识符
    private let service = "com.aivc.api-keys"
    
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
    
    // 从Keychain获取API密钥（与SecurityManager完全相同的实现）
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
            let middle = String(repeating: "*", count: max(4, key.count - 8))
            return prefix + middle + suffix
        }
    }
}

// 模拟TongYiQianWenService的API密钥获取
class TestTongYiQianWenService {
    private let securityManager = TestSecurityManager.shared
    
    private func getAPIKey() -> String? {
        return securityManager.getAPIKey(for: .tongYiQianWen)
    }
    
    func testAPIKeyAccess() -> (hasKey: Bool, keyPreview: String?) {
        let key = getAPIKey()
        let hasKey = key != nil
        let keyPreview = hasKey ? securityManager.getMaskedAPIKey(for: .tongYiQianWen) : nil
        
        if hasKey {
            print("✅ TongYiQianWenService: API密钥获取成功")
        } else {
            print("❌ TongYiQianWenService: API密钥未找到")
        }
        
        return (hasKey, keyPreview)
    }
}

// 执行测试
print("=== SecurityManager API密钥读取测试 ===")
print("时间: \(Date())")
print()

let securityManager = TestSecurityManager.shared
let tongYiService = TestTongYiQianWenService()

// 1. 测试SecurityManager直接读取
print("1. SecurityManager直接读取测试:")
let hasKey = securityManager.hasAPIKey(for: .tongYiQianWen)
print("   - 密钥存在: \(hasKey)")

if hasKey {
    if let maskedKey = securityManager.getMaskedAPIKey(for: .tongYiQianWen) {
        print("   - 掩码密钥: \(maskedKey)")
    }
    
    if let fullKey = securityManager.getAPIKey(for: .tongYiQianWen) {
        print("   - 密钥长度: \(fullKey.count)")
        print("   - 密钥前缀: \(fullKey.hasPrefix("sk-") ? "正确(sk-)" : "错误")")
    }
} else {
    print("   - 状态: 未找到API密钥")
}

print()

// 2. 测试TongYiQianWenService读取
print("2. TongYiQianWenService读取测试:")
let (serviceHasKey, serviceKeyPreview) = tongYiService.testAPIKeyAccess()
print("   - 服务层密钥状态: \(serviceHasKey ? "可用" : "不可用")")
if let preview = serviceKeyPreview {
    print("   - 服务层密钥预览: \(preview)")
}

print()

// 3. 模拟应用启动时的检查
print("3. 模拟应用启动检查:")
if securityManager.hasAPIKey(for: .tongYiQianWen) {
    print("   ✅ 应用启动: 阿里云通义千问API密钥配置正常")
    print("   ✅ 语音识别和AI分析功能可用")
} else {
    print("   ❌ 应用启动: 阿里云通义千问API密钥未配置")
    print("   ❌ 需要用户配置API密钥")
}

print()
print("=== 测试完成 ===")
print()
print("结论:")
if hasKey && serviceHasKey {
    print("🎉 API密钥配置完全正常！")
    print("   - SecurityManager可以正确读取密钥")
    print("   - TongYiQianWenService可以正确获取密钥")
    print("   - 应用应该不再显示'API密钥未找到'错误")
    print("   - 所有AI功能应该正常工作")
} else {
    print("⚠️  仍存在问题，需要进一步检查")
}