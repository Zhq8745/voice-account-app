#!/usr/bin/env swift

import Foundation
import Security

// 模拟SecurityManager的API密钥获取逻辑
class TestSecurityManager {
    static let shared = TestSecurityManager()
    
    private let service = "com.aivc.api-keys"
    
    enum APIKeyType: String {
        case tongYiQianWen = "tongyi_qianwen_api_key"
        
        var displayName: String {
            switch self {
            case .tongYiQianWen:
                return "阿里云通义千问"
            }
        }
    }
    
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
               let apiKey = String(data: data, encoding: .utf8) {
                return apiKey
            }
        }
        
        return nil
    }
}

// 模拟TongYiQianWenService的API密钥检查逻辑
class TestTongYiQianWenService {
    private let securityManager = TestSecurityManager.shared
    
    func checkAPIKeyConfiguration() -> (hasKey: Bool, keyPreview: String?) {
        guard let apiKey = securityManager.getAPIKey(for: .tongYiQianWen) else {
            print("❌ SecurityManager: 阿里云通义千问 API密钥未找到")
            return (false, nil)
        }
        
        if apiKey.isEmpty {
            print("❌ API密钥为空")
            return (false, nil)
        }
        
        let preview = String(apiKey.prefix(8)) + "..."
        print("✅ API密钥已找到: \(preview)")
        return (true, preview)
    }
    
    func testAPIKeyAccess() {
        print("=== 运行时API密钥配置测试 ===")
        print("测试时间: \(Date())")
        print("")
        
        let result = checkAPIKeyConfiguration()
        
        if result.hasKey {
            print("✅ 测试结果: API密钥配置正常")
            print("✅ 应用应该能够正常使用AI分析功能")
        } else {
            print("❌ 测试结果: API密钥配置异常")
            print("❌ 这解释了为什么会出现'API密钥未找到'错误")
        }
        
        print("")
        print("=== Keychain详细检查 ===")
        
        // 检查Keychain中的所有相关条目
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.aivc.api-keys",
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        var keychainResult: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &keychainResult)
        
        if status == errSecSuccess {
            if let items = keychainResult as? [[String: Any]] {
                print("找到 \(items.count) 个Keychain条目:")
                for (index, item) in items.enumerated() {
                    if let account = item[kSecAttrAccount as String] as? String,
                       let data = item[kSecValueData as String] as? Data,
                       let value = String(data: data, encoding: .utf8) {
                        let preview = String(value.prefix(8)) + "..."
                        print("  \(index + 1). Account: \(account), Value: \(preview)")
                    }
                }
            }
        } else {
            print("❌ 无法访问Keychain条目，状态码: \(status)")
        }
    }
}

// 运行测试
let testService = TestTongYiQianWenService()
testService.testAPIKeyAccess()