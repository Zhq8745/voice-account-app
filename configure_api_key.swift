#!/usr/bin/env swift

import Foundation
import Security

// API密钥配置助手
class APIKeyConfigurator {
    private let service = "com.aivc.apikeys"
    
    func showConfigurationGuide() {
        print("\n🔧 通义千问API密钥配置指南")
        print(String(repeating: "=", count: 50))
        
        print("\n📋 当前状态检查:")
        checkCurrentStatus()
        
        print("\n📝 获取API密钥步骤:")
        print("1. 访问阿里云控制台: https://dashscope.console.aliyun.com/")
        print("2. 登录您的阿里云账号")
        print("3. 进入 '模型服务灵积' -> 'API-KEY管理'")
        print("4. 创建新的API-KEY或使用现有的")
        print("5. 复制API密钥（格式类似: sk-xxxxxxxxxxxxxxxxxx）")
        
        print("\n⚠️  重要提醒:")
        print("• API密钥必须以 'sk-' 开头")
        print("• 确保账户有足够的余额或免费额度")
        print("• 不要与他人分享您的API密钥")
        
        print("\n🔄 配置新密钥:")
        print("请运行以下命令来配置新的API密钥:")
        print("swift configure_api_key.swift set <您的API密钥>")
        print("\n示例:")
        print("swift configure_api_key.swift set sk-1234567890abcdef1234567890abcdef")
        
        print("\n🧪 测试配置:")
        print("配置完成后，运行以下命令测试:")
        print("swift configure_api_key.swift test")
    }
    
    func setAPIKey(_ key: String) {
        print("\n🔧 配置API密钥...")
        
        // 验证密钥格式
        guard validateKeyFormat(key) else {
            print("❌ API密钥格式无效")
            print("   密钥必须以 'sk-' 开头且长度至少20个字符")
            return
        }
        
        // 删除旧密钥
        deleteExistingKey()
        
        // 存储新密钥
        if storeNewKey(key) {
            print("✅ API密钥配置成功")
            print("   密钥: \(maskKey(key))")
            
            // 立即测试新密钥
            print("\n🧪 测试新配置的API密钥...")
            testAPIKey()
        } else {
            print("❌ API密钥存储失败")
        }
    }
    
    func testAPIKey() {
        print("\n🧪 测试API密钥连接...")
        
        guard let apiKey = getCurrentAPIKey() else {
            print("❌ 未找到API密钥，请先配置")
            return
        }
        
        print("   使用密钥: \(maskKey(apiKey))")
        
        // 创建测试请求
        let url = URL(string: "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let testBody: [String: Any] = [
            "model": "qwen-turbo",
            "input": [
                "messages": [
                    [
                        "role": "user",
                        "content": "你好，请回复'测试成功'"
                    ]
                ]
            ],
            "parameters": [
                "result_format": "message",
                "max_tokens": 10
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: testBody)
        } catch {
            print("❌ 请求构建失败: \(error)")
            return
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            
            if let error = error {
                print("❌ 网络错误: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 无效响应")
                return
            }
            
            print("   HTTP状态码: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                print("✅ API密钥测试成功！")
                print("   连接正常，可以正常使用AI分析功能")
            } else {
                print("❌ API密钥测试失败")
                
                if let data = data,
                   let errorMessage = String(data: data, encoding: .utf8) {
                    print("   错误详情: \(errorMessage)")
                    
                    if errorMessage.contains("InvalidApiKey") {
                        print("\n💡 解决建议:")
                        print("   1. 检查API密钥是否正确")
                        print("   2. 确认密钥是否已激活")
                        print("   3. 检查阿里云账户余额")
                        print("   4. 重新生成API密钥")
                    }
                }
            }
        }
        
        task.resume()
        semaphore.wait()
    }
    
    private func checkCurrentStatus() {
        if let currentKey = getCurrentAPIKey() {
            print("   ✅ 已配置API密钥: \(maskKey(currentKey))")
            
            if validateKeyFormat(currentKey) {
                print("   ✅ 密钥格式正确")
            } else {
                print("   ❌ 密钥格式异常")
            }
        } else {
            print("   ❌ 未配置API密钥")
        }
    }
    
    private func validateKeyFormat(_ key: String) -> Bool {
        return key.hasPrefix("sk-") && key.count >= 20
    }
    
    private func deleteExistingKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "tongYiQianWen"
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    private func storeNewKey(_ key: String) -> Bool {
        guard let keyData = key.data(using: .utf8) else {
            return false
        }
        
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "tongYiQianWen",
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(attributes as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func getCurrentAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "tongYiQianWen",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let key = String(data: data, encoding: .utf8) {
            return key
        }
        
        return nil
    }
    
    private func maskKey(_ key: String) -> String {
        guard key.count > 8 else { return "***" }
        let start = String(key.prefix(4))
        let end = String(key.suffix(4))
        return "\(start)***\(end)"
    }
}

// 主程序
let configurator = APIKeyConfigurator()
let arguments = CommandLine.arguments

if arguments.count < 2 {
    configurator.showConfigurationGuide()
} else {
    let command = arguments[1]
    
    switch command {
    case "set":
        if arguments.count >= 3 {
            let apiKey = arguments[2]
            configurator.setAPIKey(apiKey)
        } else {
            print("❌ 请提供API密钥")
            print("用法: swift configure_api_key.swift set <API密钥>")
        }
        
    case "test":
        configurator.testAPIKey()
        
    case "guide":
        configurator.showConfigurationGuide()
        
    default:
        print("❌ 未知命令: \(command)")
        print("可用命令: set, test, guide")
    }
}