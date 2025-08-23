#!/usr/bin/env swift

import Foundation
import Security

// 完全复制项目中的APIKeyType定义
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

// 完全复制项目中的SecurityManager实现
class DiagnosticSecurityManager {
    static let shared = DiagnosticSecurityManager()
    
    private let service = "com.aivc.api-keys"
    
    private init() {}
    
    // 从Keychain获取API密钥（与项目中完全相同的实现）
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
            let middle = String(repeating: "*", count: key.count - 8)
            return "\(prefix)\(middle)\(suffix)"
        }
    }
    
    // 存储API密钥到Keychain（用于测试）
    func storeAPIKey(_ key: String, for type: APIKeyType) -> Bool {
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("SecurityManager: API密钥不能为空")
            return false
        }
        
        // 删除现有密钥（如果存在）
        deleteAPIKey(for: type)
        
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
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("SecurityManager: \(type.displayName) API密钥存储成功")
            return true
        } else {
            print("SecurityManager: 存储\(type.displayName) API密钥失败，错误代码: \(status)")
            return false
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
            return true
        } else {
            print("SecurityManager: 删除\(type.displayName) API密钥失败，错误代码: \(status)")
            return false
        }
    }
}

// 模拟TongYiQianWenService的API密钥检查
class DiagnosticTongYiQianWenService {
    private let securityManager = DiagnosticSecurityManager.shared
    
    func getAPIKey() -> String? {
        return securityManager.getAPIKey(for: .tongYiQianWen)
    }
    
    func analyzeExpenseText(_ text: String) throws -> String {
        guard let apiKey = getAPIKey() else {
            throw NSError(domain: "TongYiQianWenService", code: 1001, userInfo: [NSLocalizedDescriptionKey: "API密钥未配置"])
        }
        
        // 模拟API调用成功
        return "模拟AI分析结果"
    }
}

// 主诊断函数
func runDiagnostic() {
    print("=== 阿里云通义千问API密钥配置诊断 ===")
    print("诊断时间: \(Date())")
    print("服务标识: com.aivc.api-keys")
    print("账户标识: tongyi_qianwen_api_key")
    print()
    
    let securityManager = DiagnosticSecurityManager.shared
    let tongYiService = DiagnosticTongYiQianWenService()
    
    // 1. 检查Keychain中的API密钥状态
    print("📋 1. Keychain存储状态检查")
    print("   正在查询Keychain...")
    
    let hasKey = securityManager.hasAPIKey(for: .tongYiQianWen)
    print("   结果: \(hasKey ? "✅ 找到API密钥" : "❌ 未找到API密钥")")
    
    if hasKey {
        if let maskedKey = securityManager.getMaskedAPIKey(for: .tongYiQianWen) {
            print("   密钥预览: \(maskedKey)")
        }
    }
    print()
    
    // 2. 测试SecurityManager的getAPIKey方法
    print("🔐 2. SecurityManager.getAPIKey() 测试")
    if let apiKey = securityManager.getAPIKey(for: .tongYiQianWen) {
        print("   ✅ SecurityManager成功获取到API密钥")
        print("   密钥长度: \(apiKey.count) 字符")
        print("   密钥前缀: \(apiKey.hasPrefix("sk-") ? "sk-" : "其他")")
    } else {
        print("   ❌ SecurityManager无法获取API密钥")
        print("   这就是导致'阿里云通义千问 API密钥未找到'错误的原因")
    }
    print()
    
    // 3. 测试TongYiQianWenService的API密钥获取
    print("🤖 3. TongYiQianWenService.getAPIKey() 测试")
    if let serviceKey = tongYiService.getAPIKey() {
        print("   ✅ TongYiQianWenService成功获取到API密钥")
    } else {
        print("   ❌ TongYiQianWenService无法获取API密钥")
        print("   这会导致AI分析功能失败")
    }
    print()
    
    // 4. 模拟AI分析调用
    print("🧠 4. 模拟AI分析调用测试")
    do {
        let result = try tongYiService.analyzeExpenseText("测试文本")
        print("   ✅ AI分析调用成功: \(result)")
    } catch {
        print("   ❌ AI分析调用失败: \(error.localizedDescription)")
        print("   这就是用户在语音录制后看到错误的原因")
    }
    print()
    
    // 5. 提供解决方案
    print("💡 5. 问题诊断和解决方案")
    if !hasKey {
        print("   🔍 问题确认: Keychain中确实没有存储阿里云通义千问API密钥")
        print("   📝 解决步骤:")
        print("      1. 获取有效的阿里云通义千问API密钥")
        print("      2. 确保密钥以'sk-'开头")
        print("      3. 在应用中配置API密钥")
        print("      4. 验证配置是否成功")
        print()
        print("   🧪 测试配置功能:")
        print("      如果您有API密钥，可以测试存储功能...")
        
        // 询问是否要测试存储功能
        print("      输入测试密钥 (或按回车跳过): ", terminator: "")
        if let testKey = readLine(), !testKey.isEmpty {
            print("      正在测试存储...")
            if securityManager.storeAPIKey(testKey, for: .tongYiQianWen) {
                print("      ✅ 测试密钥存储成功")
                print("      🔄 重新检查...")
                
                if securityManager.hasAPIKey(for: .tongYiQianWen) {
                    print("      ✅ 确认: 现在可以从Keychain读取密钥")
                    
                    // 测试AI服务
                    do {
                        let result = try tongYiService.analyzeExpenseText("测试文本")
                        print("      ✅ AI分析现在可以正常工作: \(result)")
                    } catch {
                        print("      ❌ AI分析仍然失败: \(error.localizedDescription)")
                    }
                    
                    // 清理测试密钥
                    print("      🧹 清理测试密钥...")
                    _ = securityManager.deleteAPIKey(for: .tongYiQianWen)
                    print("      ✅ 测试密钥已清理")
                } else {
                    print("      ❌ 存储后仍无法读取，可能存在系统问题")
                }
            } else {
                print("      ❌ 测试密钥存储失败")
            }
        }
    } else {
        print("   ✅ API密钥配置正常")
        print("   如果仍然出现错误，可能是其他问题导致的")
    }
    
    print()
    print("=== 诊断完成 ===")
}

// 运行诊断
runDiagnostic()