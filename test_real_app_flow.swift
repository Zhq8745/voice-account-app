#!/usr/bin/env swift

import Foundation
import Security

// 完全复制项目中的结构定义
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

struct ExpenseAnalysisResult {
    let amount: Double?
    let category: String
    let note: String
    let confidence: Float
    let suggestions: [String]
}

enum TongYiError: Error {
    case missingAPIKey(String)
    case invalidInput(String)
    case networkError(String)
    case authenticationError(String)
    case parseError(String)
    case rateLimitError(String)
    case serverError(String)
    case httpError(String)
    case invalidURL(String)
    case encodingError(String)
}

// 完全复制SecurityManager的实现
class RealSecurityManager {
    static let shared = RealSecurityManager()
    
    private let service = "com.aivc.api-keys"
    
    private init() {}
    
    // 从Keychain获取API密钥（与项目中完全相同）
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
}

// 完全复制TongYiQianWenService的关键部分
class RealTongYiQianWenService {
    private let securityManager = RealSecurityManager.shared
    
    private func getAPIKey() -> String? {
        return securityManager.getAPIKey(for: .tongYiQianWen)
    }
    
    // 模拟analyzeExpenseText方法的关键检查逻辑
    func analyzeExpenseText(_ text: String) async throws -> ExpenseAnalysisResult {
        print("🔍 TongYiQianWenService.analyzeExpenseText() 开始")
        print("   输入文本: \"\(text)\"")
        
        // 第一个检查：输入文本验证
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("   ❌ 输入文本为空")
            throw TongYiError.invalidInput("输入文本不能为空")
        }
        print("   ✅ 输入文本验证通过")
        
        // 第二个检查：API密钥获取和验证
        print("   🔑 正在获取API密钥...")
        guard let apiKey = getAPIKey() else {
            print("   ❌ API密钥获取失败 - getAPIKey() 返回 nil")
            throw TongYiError.missingAPIKey("请先配置阿里云通义千问API密钥")
        }
        print("   ✅ API密钥获取成功，长度: \(apiKey.count)")
        
        // 第三个检查：API密钥非空验证
        guard !apiKey.isEmpty else {
            print("   ❌ API密钥为空字符串")
            throw TongYiError.missingAPIKey("请先配置阿里云通义千问API密钥")
        }
        print("   ✅ API密钥非空验证通过")
        
        print("   🎉 所有验证通过，模拟API调用成功")
        
        // 返回模拟结果
        return ExpenseAnalysisResult(
            amount: 25.0,
            category: "餐饮",
            note: "AI分析结果",
            confidence: 0.85,
            suggestions: ["建议添加具体商家信息"]
        )
    }
}

// 模拟HybridParsingService的调用
class RealHybridParsingService {
    private let aiService = RealTongYiQianWenService()
    
    func parseExpenseText(_ text: String) async -> (amount: Double, category: String, note: String, confidence: Float, source: String) {
        print("🔄 HybridParsingService.parseExpenseText() 开始")
        print("   输入文本: \"\(text)\"")
        
        // 模拟本地解析（故意设置低置信度以触发AI调用）
        let localConfidence: Float = 0.3
        print("   📊 本地解析置信度: \(localConfidence)")
        
        if localConfidence >= 0.7 {
            print("   ✅ 本地解析置信度足够，直接返回本地结果")
            return (amount: 0.0, category: "无", note: "本地解析", confidence: localConfidence, source: "local")
        } else {
            print("   🤖 本地解析置信度不足，尝试AI增强解析...")
            
            do {
                let aiResult = try await aiService.analyzeExpenseText(text)
                print("   ✅ AI分析成功")
                return (
                    amount: aiResult.amount ?? 0.0,
                    category: aiResult.category,
                    note: aiResult.note,
                    confidence: aiResult.confidence,
                    source: "ai"
                )
            } catch {
                print("   ❌ AI分析失败: \(error.localizedDescription)")
                print("   🔄 降级到本地解析结果")
                return (amount: 0.0, category: "无", note: "降级解析", confidence: localConfidence, source: "local_fallback")
            }
        }
    }
}

// 主测试函数
func runRealAppFlowTest() {
    print("=== 真实应用流程测试 - 复现用户问题 ===")
    print("测试时间: \(Date())")
    print()
    
    // 1. 检查当前API密钥状态
    print("📋 1. 当前API密钥状态检查")
    let securityManager = RealSecurityManager.shared
    
    if let apiKey = securityManager.getAPIKey(for: .tongYiQianWen) {
        print("   ✅ Keychain中存在API密钥")
        print("   密钥长度: \(apiKey.count) 字符")
        print("   密钥前缀: \(apiKey.hasPrefix("sk-") ? "sk-" : "其他")")
    } else {
        print("   ❌ Keychain中没有API密钥")
    }
    print()
    
    // 2. 测试TongYiQianWenService直接调用
    print("🤖 2. 直接测试TongYiQianWenService")
    let tongYiService = RealTongYiQianWenService()
    
    Task {
        do {
            let result = try await tongYiService.analyzeExpenseText("花了25块钱吃饭")
            print("   ✅ TongYiQianWenService调用成功")
            print("   结果: 金额=\(result.amount ?? 0), 分类=\(result.category)")
        } catch {
            print("   ❌ TongYiQianWenService调用失败: \(error.localizedDescription)")
            if let tongYiError = error as? TongYiError {
                switch tongYiError {
                case .missingAPIKey(let message):
                    print("   🔍 这就是用户看到的错误！错误信息: \(message)")
                default:
                    print("   🔍 其他类型的错误: \(tongYiError)")
                }
            }
        }
        
        print()
        
        // 3. 测试HybridParsingService调用链
        print("🔗 3. 测试HybridParsingService完整调用链")
        let hybridService = RealHybridParsingService()
        
        let hybridResult = await hybridService.parseExpenseText("花了一些钱")
        print("   📊 HybridParsingService结果:")
        print("      金额: \(hybridResult.amount)")
        print("      分类: \(hybridResult.category)")
        print("      备注: \(hybridResult.note)")
        print("      置信度: \(hybridResult.confidence)")
        print("      来源: \(hybridResult.source)")
        
        print()
        print("=== 测试完成 ===")
        
        // 4. 总结分析
        print()
        print("💡 问题分析总结:")
        if securityManager.getAPIKey(for: .tongYiQianWen) != nil {
            print("   ✅ API密钥已配置")
            print("   🤔 如果仍然出现错误，可能的原因:")
            print("      1. 多线程访问问题")
            print("      2. Keychain访问权限问题")
            print("      3. 应用沙盒环境差异")
            print("      4. 不同实例间的状态不一致")
        } else {
            print("   ❌ API密钥未配置")
            print("   💡 这就是问题的根本原因")
        }
        
        exit(0)
    }
    
    // 保持程序运行以等待异步任务完成
    RunLoop.main.run()
}

// 运行测试
runRealAppFlowTest()