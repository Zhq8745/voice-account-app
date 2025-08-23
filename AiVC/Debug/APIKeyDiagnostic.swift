//
//  APIKeyDiagnostic.swift
//  AiVC
//
//  Created by AI Assistant on 2024/01/01.
//

import Foundation
import Security

// API密钥诊断工具
class APIKeyDiagnostic {
    
    static let shared = APIKeyDiagnostic()
    private let securityManager = SecurityManager.shared
    
    private init() {}
    
    // 运行完整诊断
    @MainActor static func runDiagnostic() {
        let diagnostic = APIKeyDiagnostic.shared
        diagnostic.performFullDiagnostic()
    }
    
    // 执行完整的API密钥诊断
    @MainActor func performFullDiagnostic() {
        print("\n=== API密钥配置诊断报告 ===")
        print("诊断时间: \(Date())")
        print("\n1. SecurityManager状态检查")
        checkSecurityManagerStatus()
        
        print("\n2. Keychain存储状态检查")
        checkKeychainStatus()
        
        print("\n3. TongYiQianWenService状态检查")
        checkTongYiServiceStatus()
        
        print("\n4. API密钥验证测试")
        testAPIKeyValidation()
        
        print("\n5. 配置建议")
        provideConfigurationSuggestions()
        
        print("\n=== 诊断报告结束 ===")
    }
    
    // 检查SecurityManager状态
    private func checkSecurityManagerStatus() {
        let allStatus = securityManager.getAllAPIKeyStatus()
        
        for status in allStatus {
            print("- \(status.type.displayName): \(status.displayStatus)")
            
            if status.isConfigured {
                if let maskedKey = securityManager.getMaskedAPIKey(for: status.type) {
                    print("  掩码密钥: \(maskedKey)")
                }
            }
        }
        
        print("配置完成度: \(Int(securityManager.configurationProgress * 100))%")
        print("基本配置完成: \(securityManager.isBasicConfigurationComplete ? "是" : "否")")
    }
    
    // 检查Keychain存储状态
    private func checkKeychainStatus() {
        for type in SecurityManager.APIKeyType.allCases {
            let serviceName = "AiVC_\(type.rawValue)"
            let account = "api_key"
            
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: account,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]
            
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            
            switch status {
            case errSecSuccess:
                if let data = result as? Data,
                   let key = String(data: data, encoding: .utf8) {
                    print("- \(type.displayName): 在Keychain中找到 (长度: \(key.count))")
                    
                    // 验证密钥格式
                    let validation = securityManager.validateAPIKey(key, for: type)
                    print("  格式验证: \(validation.isValid ? "通过" : "失败") - \(validation.message)")
                } else {
                    print("- \(type.displayName): Keychain中存在但无法解码")
                }
            case errSecItemNotFound:
                print("- \(type.displayName): 在Keychain中未找到")
            default:
                print("- \(type.displayName): Keychain查询失败，错误代码: \(status)")
            }
        }
    }
    
    // 检查TongYiQianWenService状态
    @MainActor private func checkTongYiServiceStatus() {
        let service = TongYiQianWenService()
        
        // 检查服务是否能获取API密钥
        let hasKey = securityManager.hasAPIKey(for: SecurityManager.APIKeyType.tongYiQianWen)
        print("- TongYiQianWenService可以获取API密钥: \(hasKey ? "是" : "否")")
        
        if hasKey {
            if let key = securityManager.getAPIKey(for: SecurityManager.APIKeyType.tongYiQianWen) {
                print("- 获取到的密钥长度: \(key.count)")
                print("- 密钥前缀检查: \(key.hasPrefix("sk-") ? "正确(sk-)" : "异常")")
            }
        }
        
        print("- 服务处理状态: \(service.isProcessing ? "处理中" : "空闲")")
        if let error = service.errorMessage {
            print("- 服务错误信息: \(error)")
        }
    }
    
    // 测试API密钥验证
    private func testAPIKeyValidation() {
        let testCases = [
            ("", "空密钥"),
            ("sk-", "仅前缀"),
            ("sk-123456789012345678901234567890", "有效格式"),
            ("invalid-key", "无效前缀"),
            ("sk-short", "过短密钥")
        ]
        
        for (testKey, description) in testCases {
            let validation = securityManager.validateAPIKey(testKey, for: SecurityManager.APIKeyType.tongYiQianWen)
            print("- \(description): \(validation.isValid ? "通过" : "失败") - \(validation.message)")
        }
    }
    
    // 提供配置建议
    private func provideConfigurationSuggestions() {
        let suggestions = securityManager.configurationSuggestions
        
        for suggestion in suggestions {
            print("- \(suggestion)")
        }
        
        if !securityManager.hasAPIKey(for: SecurityManager.APIKeyType.tongYiQianWen) {
            print("\n配置步骤:")
            print("1. 获取阿里云通义千问API密钥")
            print("2. 确保密钥以'sk-'开头")
            print("3. 在应用设置中配置API密钥")
            print("4. 验证配置是否成功")
        }
    }
    
    // 模拟API密钥配置测试
    func testAPIKeyConfiguration(testKey: String) {
        print("\n=== API密钥配置测试 ===")
        print("测试密钥: \(testKey.prefix(10))...")
        
        // 验证密钥格式
        let validation = securityManager.validateAPIKey(testKey, for: SecurityManager.APIKeyType.tongYiQianWen)
        print("格式验证: \(validation.isValid ? "通过" : "失败") - \(validation.message)")
        
        if validation.isValid {
            // 尝试存储密钥
            let storeResult = securityManager.storeAPIKey(testKey, for: SecurityManager.APIKeyType.tongYiQianWen)
            print("存储结果: \(storeResult ? "成功" : "失败")")
            
            if storeResult {
                // 验证存储后的状态
                let hasKey = securityManager.hasAPIKey(for: SecurityManager.APIKeyType.tongYiQianWen)
                print("存储验证: \(hasKey ? "成功" : "失败")")
                
                if let retrievedKey = securityManager.getAPIKey(for: SecurityManager.APIKeyType.tongYiQianWen) {
                    print("密钥一致性: \(retrievedKey == testKey ? "一致" : "不一致")")
                }
            }
        }
        
        print("=== 配置测试结束 ===")
    }
    
    // 清理测试数据
    func cleanupTestData() {
        print("\n=== 清理测试数据 ===")
        let result = securityManager.clearAllAPIKeys()
        print("清理结果: \(result ? "成功" : "失败")")
        print("=== 清理完成 ===")
    }
}

// 诊断扩展：便捷方法
extension APIKeyDiagnostic {
    
    // 快速检查通义千问API密钥状态
    func quickCheckTongYiAPIKey() -> (configured: Bool, valid: Bool, message: String) {
        let hasKey = securityManager.hasAPIKey(for: SecurityManager.APIKeyType.tongYiQianWen)
        
        guard hasKey else {
            return (false, false, "阿里云通义千问API密钥未配置")
        }
        
        guard let key = securityManager.getAPIKey(for: SecurityManager.APIKeyType.tongYiQianWen) else {
            return (false, false, "无法从Keychain获取API密钥")
        }
        
        let validation = securityManager.validateAPIKey(key, for: SecurityManager.APIKeyType.tongYiQianWen)
        
        if validation.isValid {
            return (true, true, "API密钥配置正确")
        } else {
            return (true, false, "API密钥格式无效: \(validation.message)")
        }
    }
    
    // 生成诊断报告摘要
    func generateDiagnosticSummary() -> String {
        let (configured, valid, message) = quickCheckTongYiAPIKey()
        let progress = Int(securityManager.configurationProgress * 100)
        
        return """
        API密钥诊断摘要:
        - 配置状态: \(configured ? "已配置" : "未配置")
        - 有效性: \(valid ? "有效" : "无效")
        - 详细信息: \(message)
        - 整体进度: \(progress)%
        """
    }
}