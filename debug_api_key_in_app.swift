#!/usr/bin/env swift

import Foundation
import Security

// API密钥类型枚举
enum APIKeyType: String, CaseIterable {
    case tongYiQianWen = "TongYiQianWen"
    case backup = "Backup"
    
    var displayName: String {
        switch self {
        case .tongYiQianWen:
            return "阿里云通义千问"
        case .backup:
            return "备用服务"
        }
    }
}

// 模拟SecurityManager的实际实现
class DebugSecurityManager {
    static let shared = DebugSecurityManager()
    private let service = "com.aivc.api-keys"
    
    private init() {}
    
    // 从Keychain获取API密钥 - 完全复制SecurityManager的实现
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
        
        print("🔍 Keychain查询参数:")
        print("   - Service: \(service)")
        print("   - Account: \(type.rawValue)")
        print("   - 查询状态码: \(status)")
        
        if status == errSecSuccess {
            if let data = result as? Data,
               let key = String(data: data, encoding: .utf8) {
                print("✅ 成功获取API密钥: \(String(key.prefix(8)))...")
                return key
            } else {
                print("❌ 数据转换失败")
            }
        } else if status == errSecItemNotFound {
            print("❌ SecurityManager: \(type.displayName) API密钥未找到")
        } else {
            print("❌ SecurityManager: 获取\(type.displayName) API密钥失败，错误代码: \(status)")
        }
        
        return nil
    }
    
    // 检查所有相关的Keychain条目
    func debugKeychainEntries() {
        print("\n🔍 检查Keychain中的所有相关条目:")
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        print("查询状态码: \(status)")
        
        if status == errSecSuccess {
            if let items = result as? [[String: Any]] {
                print("找到 \(items.count) 个条目:")
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

// 模拟TongYiQianWenService的API密钥检查
class DebugTongYiQianWenService {
    private let securityManager = DebugSecurityManager.shared
    
    private func getAPIKey() -> String? {
        print("\n🔍 TongYiQianWenService.getAPIKey() 调用:")
        let key = securityManager.getAPIKey(for: .tongYiQianWen)
        if let key = key {
            print("✅ 获取到API密钥: \(String(key.prefix(8)))...")
        } else {
            print("❌ 未获取到API密钥")
        }
        return key
    }
    
    func simulateAnalyzeExpenseText() {
        print("\n🎯 模拟 analyzeExpenseText 方法调用:")
        
        guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
            print("❌ 抛出错误: TongYiError.missingAPIKey(\"请先配置阿里云通义千问API密钥\")")
            return
        }
        
        print("✅ API密钥验证通过，可以继续执行AI分析")
    }
}

print("=== 应用内API密钥调试测试 ===")
print("测试时间: \(Date())")

let debugManager = DebugSecurityManager.shared
let debugService = DebugTongYiQianWenService()

// 1. 检查Keychain中的所有条目
debugManager.debugKeychainEntries()

// 2. 直接测试SecurityManager的getAPIKey方法
print("\n🔍 直接测试SecurityManager.getAPIKey():")
let directResult = debugManager.getAPIKey(for: .tongYiQianWen)
if let key = directResult {
    print("✅ 直接调用成功: \(String(key.prefix(8)))...")
} else {
    print("❌ 直接调用失败")
}

// 3. 模拟TongYiQianWenService的调用流程
debugService.simulateAnalyzeExpenseText()

print("\n=== 调试测试完成 ===")