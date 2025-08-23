#!/usr/bin/env swift

import Foundation
import Security

// 模拟APIKeyType枚举
enum APIKeyType: String, CaseIterable {
    case tongYiQianWen = "TongYiQianWen"
    case backup = "Backup"
}

// 模拟SecurityManager类
class SecurityManager {
    private let service = "com.aivc.api-keys"
    
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
        
        print("SecurityManager.getAPIKey - 查询状态: \(status)")
        
        guard status == errSecSuccess else {
            print("SecurityManager.getAPIKey - 获取失败，状态码: \(status)")
            return nil
        }
        
        guard let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            print("SecurityManager.getAPIKey - 数据转换失败")
            return nil
        }
        
        print("SecurityManager.getAPIKey - 成功获取API密钥")
        return apiKey
    }
}

// 模拟TongYiQianWenService类
class TongYiQianWenService {
    private let securityManager = SecurityManager()
    
    private func getAPIKey() -> String? {
        return securityManager.getAPIKey(for: .tongYiQianWen)
    }
    
    func testAPIKeyAccess() -> Bool {
        print("\n=== TongYiQianWenService API密钥测试 ===")
        
        guard let apiKey = getAPIKey() else {
            print("❌ TongYiQianWenService: 阿里云通义千问 API密钥未找到")
            return false
        }
        
        print("✅ TongYiQianWenService: 成功获取API密钥")
        print("API密钥长度: \(apiKey.count)")
        print("API密钥前缀: \(String(apiKey.prefix(10)))...")
        return true
    }
}

// 主测试函数
func runAPIKeyTest() {
    print("=== 阿里云通义千问API密钥配置测试 ===")
    print("测试时间: \(Date())")
    
    // 1. 检查Keychain中是否存在API密钥
    print("\n1. 检查Keychain存储状态...")
    let securityManager = SecurityManager()
    
    if let apiKey = securityManager.getAPIKey(for: .tongYiQianWen) {
        print("✅ Keychain中找到API密钥")
        print("   密钥长度: \(apiKey.count)")
        print("   密钥前缀: \(String(apiKey.prefix(10)))...")
    } else {
        print("❌ Keychain中未找到API密钥")
    }
    
    // 2. 测试TongYiQianWenService
    print("\n2. 测试TongYiQianWenService...")
    let service = TongYiQianWenService()
    let serviceResult = service.testAPIKeyAccess()
    
    // 3. 总结
    print("\n=== 测试结果总结 ===")
    if serviceResult {
        print("✅ API密钥配置正常，应用应该能够正常调用阿里云通义千问API")
    } else {
        print("❌ API密钥配置有问题，需要重新配置")
        print("\n建议解决方案:")
        print("1. 检查是否已在应用设置中配置了阿里云通义千问API密钥")
        print("2. 确认API密钥格式正确")
        print("3. 重新启动应用后再次测试")
    }
}

// 运行测试
runAPIKeyTest()