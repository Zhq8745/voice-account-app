#!/usr/bin/env swift

import Foundation
import Security

// 检查API密钥配置状态
func checkAPIKeyStatus() {
    print("=== API密钥配置诊断报告 ===")
    print("诊断时间: \(Date())")
    print("\n1. Keychain存储状态检查")
    
    let serviceName = "AiVC_tongyi_qianwen_api_key"
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
            print("✅ 阿里云通义千问: 在Keychain中找到")
            print("   - 密钥长度: \(key.count)")
            print("   - 密钥前缀: \(key.hasPrefix("sk-") ? "正确(sk-)" : "异常")")
            print("   - 密钥预览: \(String(key.prefix(10)))...")
            
            // 验证密钥格式
            if key.hasPrefix("sk-") && key.count >= 20 && key.count <= 100 {
                print("   - 格式验证: ✅ 通过")
            } else {
                print("   - 格式验证: ❌ 失败")
            }
        } else {
            print("❌ 阿里云通义千问: Keychain中存在但无法解码")
        }
    case errSecItemNotFound:
        print("❌ 阿里云通义千问: 在Keychain中未找到")
        print("   这就是导致'API密钥未找到'错误的原因")
    default:
        print("❌ 阿里云通义千问: Keychain查询失败，错误代码: \(status)")
    }
    
    print("\n2. 问题分析")
    if status == errSecItemNotFound {
        print("🔍 问题确认: API密钥确实未配置")
        print("   - 这解释了为什么会出现'SecurityManager: 阿里云通义千问 API密钥未找到'错误")
        print("   - 当语音记账触发AI分析时，HybridParsingService会调用TongYiQianWenService")
        print("   - TongYiQianWenService通过SecurityManager查找API密钥")
        print("   - 由于Keychain中没有存储API密钥，所以抛出错误")
    } else if status == errSecSuccess {
        print("🔍 API密钥已配置，问题可能在其他地方")
    }
    
    print("\n3. 解决方案")
    if status == errSecItemNotFound {
        print("📝 需要配置阿里云通义千问API密钥:")
        print("   1. 获取阿里云通义千问API密钥")
        print("   2. 在应用中进入设置页面")
        print("   3. 找到'调试设置'部分")
        print("   4. 点击'API密钥诊断'")
        print("   5. 在诊断页面应该有配置API密钥的选项")
        print("   6. 输入以'sk-'开头的API密钥")
        print("   7. 保存配置")
    }
    
    print("\n=== 诊断报告结束 ===")
}

// 运行诊断
checkAPIKeyStatus()