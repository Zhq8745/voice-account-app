#!/usr/bin/env swift

import Foundation
import Security

// 模拟SecurityManager类
class SecurityManager {
    static let shared = SecurityManager()
    private let serviceName = "AiVC-TongYiQianWen"
    private let account = "api-key"
    
    private init() {}
    
    func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            print("SecurityManager: 阿里云通义千问 API密钥未找到")
            return nil
        }
        
        return apiKey
    }
    
    func hasAPIKey() -> Bool {
        return getAPIKey() != nil
    }
}

// 模拟TongYiQianWenService类
class TongYiQianWenService {
    private let securityManager = SecurityManager.shared
    
    func analyzeExpenseText(_ text: String) async throws -> String {
        print("\n=== TongYiQianWenService.analyzeExpenseText 调用 ===")
        print("输入文本: \(text)")
        
        // 检查API密钥
        guard let apiKey = securityManager.getAPIKey() else {
            let error = "API密钥未配置"
            print("❌ \(error)")
            throw NSError(domain: "TongYiQianWenService", code: 1001, userInfo: [NSLocalizedDescriptionKey: error])
        }
        
        let maskedKey = maskAPIKey(apiKey)
        print("✅ 成功获取API密钥: \(maskedKey)")
        print("🔍 密钥长度: \(apiKey.count) 字符")
        print("✅ 密钥格式: \(apiKey.hasPrefix("sk-") ? "正确" : "错误")")
        
        // 模拟API调用
        print("🔄 正在调用阿里云通义千问API...")
        
        return "模拟分析结果: 餐饮支出 50元"
    }
    
    private func maskAPIKey(_ key: String) -> String {
        guard key.count > 8 else { return "***" }
        let start = key.prefix(8)
        let end = key.suffix(4)
        return "\(start)***\(end)"
    }
}

// 模拟HybridParsingService类
class HybridParsingService {
    private let aiService = TongYiQianWenService()
    
    func parseExpenseText(_ text: String) async -> String {
        print("\n=== HybridParsingService.parseExpenseText 调用 ===")
        print("输入文本: \(text)")
        
        // 检查SecurityManager状态
        let hasKey = SecurityManager.shared.hasAPIKey()
        print("SecurityManager.hasAPIKey(): \(hasKey)")
        
        if hasKey {
            print("✅ SecurityManager确认有API密钥")
        } else {
            print("❌ SecurityManager确认无API密钥")
            return "本地解析结果: 无法进行AI增强"
        }
        
        // 尝试AI增强解析
        do {
            let result = try await aiService.analyzeExpenseText(text)
            print("✅ AI增强解析成功")
            return result
        } catch {
            print("❌ AI增强解析失败: \(error.localizedDescription)")
            return "本地解析结果: AI服务不可用"
        }
    }
}

// 测试应用服务
class AppServiceTester {
    func runTests() async {
        print("=== 应用服务API密钥测试开始 ===")
        
        // 测试1: SecurityManager直接测试
        print("\n📋 测试1: SecurityManager直接测试")
        let securityManager = SecurityManager.shared
        
        if let apiKey = securityManager.getAPIKey() {
            let maskedKey = maskAPIKey(apiKey)
            print("✅ SecurityManager.getAPIKey() 成功: \(maskedKey)")
        } else {
            print("❌ SecurityManager.getAPIKey() 失败")
        }
        
        let hasKey = securityManager.hasAPIKey()
        print("SecurityManager.hasAPIKey(): \(hasKey)")
        
        // 测试2: TongYiQianWenService测试
        print("\n📋 测试2: TongYiQianWenService测试")
        let tongYiService = TongYiQianWenService()
        
        do {
            let result = try await tongYiService.analyzeExpenseText("今天午餐花了50元")
            print("✅ TongYiQianWenService测试成功")
            print("📄 分析结果: \(result)")
        } catch {
            print("❌ TongYiQianWenService测试失败: \(error.localizedDescription)")
        }
        
        // 测试3: HybridParsingService测试
        print("\n📋 测试3: HybridParsingService测试")
        let hybridService = HybridParsingService()
        
        let hybridResult = await hybridService.parseExpenseText("今天午餐花了50元")
        print("📄 混合解析结果: \(hybridResult)")
        
        print("\n=== 应用服务API密钥测试完成 ===")
    }
    
    private func maskAPIKey(_ key: String) -> String {
        guard key.count > 8 else { return "***" }
        let start = key.prefix(8)
        let end = key.suffix(4)
        return "\(start)***\(end)"
    }
}

// 运行测试
Task {
    let tester = AppServiceTester()
    await tester.runTests()
    exit(0)
}

// 保持程序运行
RunLoop.main.run()