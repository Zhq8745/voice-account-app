#!/usr/bin/env swift

import Foundation
import Security

// 复制实际的SecurityManager实现
class TestSecurityManager {
    static let shared = TestSecurityManager()
    private let service = "com.aivc.api-keys"
    
    private init() {}
    
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
    
    func hasAPIKey(for type: APIKeyType) -> Bool {
        return getAPIKey(for: type) != nil
    }
}

// 复制实际的TongYiQianWenService实现
class TestTongYiQianWenService {
    private let securityManager = TestSecurityManager.shared
    
    enum TongYiError: Error {
        case missingAPIKey(String)
        case invalidInput(String)
        
        var localizedDescription: String {
            switch self {
            case .missingAPIKey(let message):
                return message
            case .invalidInput(let message):
                return message
            }
        }
    }
    
    private func getAPIKey() -> String? {
        return securityManager.getAPIKey(for: .tongYiQianWen)
    }
    
    // 模拟analyzeExpenseText方法的API密钥检查部分
    func testAnalyzeExpenseText(_ text: String) throws {
        print("\n🔍 TongYiQianWenService.analyzeExpenseText() 开始执行")
        print("输入文本: \"\(text)\"")
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TongYiError.invalidInput("输入文本不能为空")
        }
        
        print("\n📞 调用 getAPIKey()...")
        guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
            print("❌ API密钥获取失败，抛出 TongYiError.missingAPIKey")
            throw TongYiError.missingAPIKey("请先配置阿里云通义千问API密钥")
        }
        
        print("✅ API密钥获取成功: \(String(apiKey.prefix(8)))...")
        print("✅ 继续执行分析逻辑...")
    }
}

// 测试实际的调用流程
print("=== 模拟实际应用调用流程测试 ===")
print("测试时间: \(Date())")
print()

let service = TestTongYiQianWenService()

// 1. 测试有API密钥的情况
print("1. 检查当前API密钥状态:")
let securityManager = TestSecurityManager.shared
let hasKey = securityManager.hasAPIKey(for: .tongYiQianWen)
print("   - 是否有API密钥: \(hasKey)")

if hasKey {
    if let key = securityManager.getAPIKey(for: .tongYiQianWen) {
        print("   - 密钥长度: \(key.count)")
        print("   - 密钥前缀: \(String(key.prefix(8)))...")
    }
}

print()

// 2. 测试TongYiQianWenService的调用
print("2. 测试TongYiQianWenService.analyzeExpenseText():")

do {
    try service.testAnalyzeExpenseText("我今天买咖啡花了25元")
    print("✅ 测试成功完成")
} catch {
    print("❌ 测试捕获到错误: \(error.localizedDescription)")
}

print()

// 3. 分析问题
print("3. 问题分析:")
if hasKey {
    print("   ✅ Keychain中存在API密钥")
    print("   ✅ SecurityManager可以正确读取")
    print("   ✅ TongYiQianWenService应该能正常工作")
    print("   ❓ 如果仍然出现'API密钥未找到'错误，可能的原因:")
    print("      - 应用运行时的Keychain访问权限问题")
    print("      - 不同的应用签名或沙盒环境")
    print("      - 代码中存在其他的API密钥检查逻辑")
} else {
    print("   ❌ Keychain中不存在API密钥")
    print("   ❌ 这是导致'SecurityManager: 阿里云通义千问 API密钥未找到'的直接原因")
    print("   💡 解决方案: 在应用设置中重新配置API密钥")
}

print()
print("=== 测试完成 ===")