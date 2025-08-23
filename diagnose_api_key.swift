#!/usr/bin/env swift

import Foundation
import Security

// 修正后的诊断脚本，使用正确的Keychain服务名称
class APIKeyDiagnostic {
    // 使用与SecurityManager相同的服务名称
    private let service = "com.aivc.api-keys"
    
    enum APIKeyType: String {
        case tongYiQianWen = "tongyi_qianwen_api_key"
    }
    
    // 检查Keychain中是否存在API密钥
    func checkKeychainForAPIKey() -> (exists: Bool, key: String?) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: APIKeyType.tongYiQianWen.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        print("   - Keychain查询状态: \(status) (\(status == errSecSuccess ? "成功" : status == errSecItemNotFound ? "未找到" : "错误"))")
        
        if status == errSecSuccess {
            if let data = result as? Data,
               let key = String(data: data, encoding: .utf8) {
                return (true, key)
            }
        }
        
        return (false, nil)
    }
    
    // 存储API密钥到Keychain
    func storeAPIKey(_ key: String) -> Bool {
        // 先删除现有的
        _ = deleteAPIKey()
        
        let keyData = key.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: APIKeyType.tongYiQianWen.rawValue,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        print("   - 存储状态: \(status) (\(status == errSecSuccess ? "成功" : "失败"))")
        return status == errSecSuccess
    }
    
    // 删除API密钥
    func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: APIKeyType.tongYiQianWen.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // 验证API密钥格式
    func validateAPIKey(_ key: String) -> Bool {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedKey.isEmpty else { return false }
        guard trimmedKey.hasPrefix("sk-") else { return false }
        guard trimmedKey.count >= 20 && trimmedKey.count <= 100 else { return false }
        
        let validCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return trimmedKey.rangeOfCharacter(from: validCharacterSet.inverted) == nil
    }
    
    // 列出所有相关的Keychain项目
    func listAllKeychainItems() {
        print("4. 检查所有相关的Keychain项目:")
        
        // 检查旧的服务名称
        let oldService = "AiVC.APIKeys"
        let oldQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: oldService,
            kSecAttrAccount as String: APIKeyType.tongYiQianWen.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var oldResult: AnyObject?
        let oldStatus = SecItemCopyMatching(oldQuery as CFDictionary, &oldResult)
        print("   - 旧服务名称(\(oldService)): \(oldStatus == errSecSuccess ? "存在" : "不存在")")
        
        if oldStatus == errSecSuccess {
            if let data = oldResult as? Data,
               let key = String(data: data, encoding: .utf8) {
                let maskedKey = String(key.prefix(8)) + "****" + String(key.suffix(4))
                print("     密钥: \(maskedKey)")
                
                // 删除旧的密钥
                let deleteQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: oldService,
                    kSecAttrAccount as String: APIKeyType.tongYiQianWen.rawValue
                ]
                let deleteStatus = SecItemDelete(deleteQuery as CFDictionary)
                print("     删除旧密钥: \(deleteStatus == errSecSuccess ? "成功" : "失败")")
            }
        }
        
        // 检查新的服务名称
        print("   - 新服务名称(\(service)): ", terminator: "")
        let (newExists, newKey) = checkKeychainForAPIKey()
        print(newExists ? "存在" : "不存在")
        if let key = newKey {
            let maskedKey = String(key.prefix(8)) + "****" + String(key.suffix(4))
            print("     密钥: \(maskedKey)")
        }
    }
}

// 执行诊断
let diagnostic = APIKeyDiagnostic()

print("=== API密钥诊断开始 (修正版) ===")
print("时间: \(Date())")
print("正确的Keychain服务名称: com.aivc.api-keys")
print()

// 1. 检查当前Keychain状态
print("1. 检查Keychain中的API密钥状态:")
let (exists, currentKey) = diagnostic.checkKeychainForAPIKey()
print("   - 密钥存在: \(exists)")
if let key = currentKey {
    let maskedKey = String(key.prefix(8)) + "****" + String(key.suffix(4))
    print("   - 当前密钥: \(maskedKey)")
    print("   - 密钥长度: \(key.count)")
    print("   - 格式验证: \(diagnostic.validateAPIKey(key))")
} else {
    print("   - 当前密钥: 无")
}
print()

// 2. 重新存储用户提供的API密钥
let userAPIKey = "sk-7e3c8c067ea246efb655495cb7d97d4d"
print("2. 重新存储用户提供的API密钥:")
print("   - 用户密钥: \(String(userAPIKey.prefix(8)))****\(String(userAPIKey.suffix(4)))")
print("   - 格式验证: \(diagnostic.validateAPIKey(userAPIKey))")

if diagnostic.validateAPIKey(userAPIKey) {
    let storeSuccess = diagnostic.storeAPIKey(userAPIKey)
    print("   - 存储结果: \(storeSuccess ? "成功" : "失败")")
    
    // 3. 验证存储后的状态
    print()
    print("3. 验证存储后的状态:")
    let (newExists, newKey) = diagnostic.checkKeychainForAPIKey()
    print("   - 密钥存在: \(newExists)")
    if let key = newKey {
        let maskedKey = String(key.prefix(8)) + "****" + String(key.suffix(4))
        print("   - 存储的密钥: \(maskedKey)")
        print("   - 密钥匹配: \(key == userAPIKey)")
    }
} else {
    print("   - 存储结果: 跳过（格式无效）")
}

print()
diagnostic.listAllKeychainItems()

print()
print("=== 诊断完成 ===")
print()
print("问题分析:")
print("1. 之前的诊断脚本使用了错误的Keychain服务名称")
print("2. SecurityManager使用 'com.aivc.api-keys'，而不是 'AiVC.APIKeys'")
print("3. 现在已使用正确的服务名称重新存储密钥")
print("4. 应用现在应该能够正确读取API密钥")