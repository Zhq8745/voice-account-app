#!/usr/bin/env swift

import Foundation
import Security

// API密钥重新配置脚本
class APIKeyReconfiguration {
    private let serviceName = "AiVC-TongYiQianWen"
    private let account = "api-key"
    private let newAPIKey = "sk-7e3c8c067ea246efb655495cb7d97d4d"
    
    func run() {
        print("=== API密钥重新配置开始 ===")
        
        // 步骤1: 清除旧配置
        clearOldConfiguration()
        
        // 步骤2: 存储新密钥
        storeNewAPIKey()
        
        // 步骤3: 验证存储
        verifyStorage()
        
        // 步骤4: 测试API连接
        testAPIConnection()
        
        print("=== API密钥重新配置完成 ===")
    }
    
    private func clearOldConfiguration() {
        print("\n1. 清除旧配置...")
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess:
            print("✅ 成功删除旧的API密钥")
        case errSecItemNotFound:
            print("ℹ️ 未找到旧的API密钥（可能是首次配置）")
        default:
            print("⚠️ 删除旧密钥时出现错误: \(status)")
        }
    }
    
    private func storeNewAPIKey() {
        print("\n2. 存储新API密钥...")
        
        guard let keyData = newAPIKey.data(using: .utf8) else {
            print("❌ API密钥转换为数据失败")
            return
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            print("✅ 成功存储新的API密钥")
        case errSecDuplicateItem:
            print("ℹ️ 密钥已存在，尝试更新...")
            updateExistingKey(keyData: keyData)
        default:
            print("❌ 存储API密钥失败: \(status)")
        }
    }
    
    private func updateExistingKey(keyData: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: keyData
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        switch status {
        case errSecSuccess:
            print("✅ 成功更新API密钥")
        default:
            print("❌ 更新API密钥失败: \(status)")
        }
    }
    
    private func verifyStorage() {
        print("\n3. 验证密钥存储...")
        
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
               let retrievedKey = String(data: data, encoding: .utf8) {
                let maskedKey = maskAPIKey(retrievedKey)
                print("✅ 密钥验证成功")
                print("📋 存储的密钥: \(maskedKey)")
                print("🔍 密钥长度: \(retrievedKey.count) 字符")
                print("✅ 密钥格式: \(retrievedKey.hasPrefix("sk-") ? "正确" : "错误")")
            } else {
                print("❌ 无法解析存储的密钥数据")
            }
        case errSecItemNotFound:
            print("❌ 未找到存储的API密钥")
        default:
            print("❌ 读取API密钥失败: \(status)")
        }
    }
    
    private func testAPIConnection() {
        print("\n4. 测试API连接...")
        
        // 创建测试请求
        guard let url = URL(string: "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation") else {
            print("❌ 无效的API URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(newAPIKey)", forHTTPHeaderField: "Authorization")
        
        let testPayload: [String: Any] = [
            "model": "qwen-turbo",
            "input": [
                "messages": [
                    [
                        "role": "user",
                        "content": "测试连接"
                    ]
                ]
            ],
            "parameters": [
                "max_tokens": 10
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: testPayload)
        } catch {
            print("❌ 创建测试请求失败: \(error)")
            return
        }
        
        print("🔄 正在测试API连接...")
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            
            if let error = error {
                print("❌ 网络请求失败: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 无效的HTTP响应")
                return
            }
            
            print("📡 HTTP状态码: \(httpResponse.statusCode)")
            
            if let data = data {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 API响应: \(responseString.prefix(200))...")
                }
                
                // 解析响应
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if httpResponse.statusCode == 200 {
                            print("✅ API连接测试成功")
                            if json["output"] != nil {
                                print("🎯 API响应正常，模型可用")
                            }
                        } else {
                            print("⚠️ API返回错误状态码: \(httpResponse.statusCode)")
                            if let message = json["message"] as? String {
                                print("📝 错误信息: \(message)")
                            }
                        }
                    }
                } catch {
                    print("❌ 解析API响应失败: \(error)")
                }
            }
        }.resume()
        
        semaphore.wait()
    }
    
    private func maskAPIKey(_ key: String) -> String {
        guard key.count > 8 else { return "***" }
        let start = key.prefix(8)
        let end = key.suffix(4)
        return "\(start)***\(end)"
    }
}

// 运行配置脚本
let reconfiguration = APIKeyReconfiguration()
reconfiguration.run()