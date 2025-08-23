#!/usr/bin/env swift

import Foundation
import Security

// 模拟APIKeyType
enum APIKeyType: String, CaseIterable {
    case tongYiQianWen = "tongYiQianWen"
}

// 模拟SecurityManager
class TestSecurityManager {
    static let shared = TestSecurityManager()
    
    private init() {}
    
    func getAPIKey(for type: APIKeyType) -> String? {
        let service = "AiVC-\(type.rawValue)"
        let account = "api-key"
        
        var item: CFTypeRef?
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess {
            if let data = item as? Data,
               let key = String(data: data, encoding: .utf8) {
                return key
            }
        } else {
            print("SecurityManager: \(getErrorDescription(for: type)) API密钥未找到")
        }
        
        return nil
    }
    
    private func getErrorDescription(for type: APIKeyType) -> String {
        switch type {
        case .tongYiQianWen:
            return "阿里云通义千问"
        }
    }
    
    func hasAPIKey(for type: APIKeyType) -> Bool {
        return getAPIKey(for: type) != nil
    }
}

// 模拟TongYiQianWenService
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
        print("🔍 TongYiQianWenService.getAPIKey() 被调用")
        let key = securityManager.getAPIKey(for: .tongYiQianWen)
        if let key = key {
            print("✅ API密钥获取成功: \(String(key.prefix(8)))...")
        } else {
            print("❌ API密钥获取失败")
        }
        return key
    }
    
    func analyzeExpenseText(_ text: String) async throws -> ExpenseAnalysisResult {
        print("\n📞 TongYiQianWenService.analyzeExpenseText() 被调用")
        print("输入文本: \"\(text)\"")
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TongYiError.invalidInput("输入文本不能为空")
        }
        
        guard getAPIKey() != nil else {
            throw TongYiError.missingAPIKey("阿里云通义千问 API密钥未配置")
        }
        
        // 模拟API调用成功
        print("✅ 模拟API调用成功")
        return ExpenseAnalysisResult(
            amount: 25.0,
            category: "餐饮",
            note: "咖啡",
            confidence: 0.9,
            suggestions: ["建议记录具体商家"]
        )
    }
}

// 模拟ExpenseAnalysisResult
struct ExpenseAnalysisResult {
    let amount: Double?
    let category: String
    let note: String
    let confidence: Float
    let suggestions: [String]
}

// 模拟ParseResult
struct ParseResult {
    let amount: Double?
    let category: String?
    let note: String?
    let confidence: Float
    let source: ParseSource
    let suggestions: [String]
    let originalText: String
}

enum ParseSource {
    case local
    case ai
    case hybrid
}

// 模拟LocalExpenseParser（故意返回低置信度）
class LowConfidenceLocalParser {
    func parse(_ text: String) -> ParseResult {
        // 故意返回低置信度，强制触发AI调用
        let amount = extractAmount(from: text)
        let category: String? = nil  // 故意不识别分类
        let note: String? = nil      // 故意不提取备注
        let confidence: Float = 0.3  // 故意设置低置信度
        
        print("本地解析故意返回低置信度: \(confidence)")
        
        return ParseResult(
            amount: amount,
            category: category,
            note: note,
            confidence: confidence,
            source: .local,
            suggestions: ["本地解析置信度较低"],
            originalText: text
        )
    }
    
    private func extractAmount(from text: String) -> Double? {
        // 简单的金额提取
        let patterns = ["(\\d+(?:\\.\\d{1,2})?)\\s*[元块钱]"]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
                let amountString = String(text[Range(match.range(at: 1), in: text)!])
                return Double(amountString)
            }
        }
        return nil
    }
}

// 模拟HybridParsingService的关键部分
class TestHybridParsingService {
    private let localParser = LowConfidenceLocalParser()  // 使用低置信度解析器
    private let aiService = TestTongYiQianWenService()
    
    func parseExpenseText(_ text: String) async -> ParseResult {
        print("\n=== HybridParsingService.parseExpenseText() 开始 ===")
        print("输入文本: \"\(text)\"")
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ParseResult(
                amount: nil,
                category: nil,
                note: nil,
                confidence: 0.0,
                source: .local,
                suggestions: ["输入文本不能为空"],
                originalText: text
            )
        }
        
        // 1. 本地快速解析
        print("\n🔄 执行本地解析...")
        let localResult = localParser.parse(text)
        print("本地解析结果: 金额=\(localResult.amount ?? 0), 分类=\(localResult.category ?? "无"), 置信度=\(localResult.confidence)")
        
        // 2. 置信度评估
        if localResult.confidence > 0.8 {
            print("✅ 本地解析置信度足够高(\(localResult.confidence))，直接返回")
            return localResult
        }
        
        // 3. AI增强解析
        print("\n🤖 本地解析置信度不够(\(localResult.confidence))，尝试AI增强解析...")
        print("⚠️  这里会触发TongYiQianWenService.analyzeExpenseText()调用")
        print("⚠️  如果API密钥未配置，就会看到'阿里云通义千问 API密钥未找到'错误")
        
        do {
            let aiResult = try await aiService.analyzeExpenseText(text)
            print("✅ AI解析成功")
            let hybridResult = combineResults(local: localResult, ai: aiResult, originalText: text)
            return hybridResult
        } catch {
            print("❌ AI解析失败: \(error.localizedDescription)")
            print("🔄 降级到本地解析结果")
            return localResult
        }
    }
    
    private func combineResults(local: ParseResult, ai: ExpenseAnalysisResult, originalText: String) -> ParseResult {
        let finalAmount = ai.amount ?? local.amount
        let finalCategory = ai.category.isEmpty ? local.category : ai.category
        let finalNote = ai.note.isEmpty ? local.note : ai.note
        let hybridConfidence = max(local.confidence, ai.confidence)
        
        return ParseResult(
            amount: finalAmount,
            category: finalCategory,
            note: finalNote,
            confidence: hybridConfidence,
            source: .hybrid,
            suggestions: ai.suggestions,
            originalText: originalText
        )
    }
}

// 执行测试
print("=== 低置信度场景测试 - 模拟用户遇到的问题 ===")
print("测试时间: \(Date())")
print()
print("📝 测试说明:")
print("   - 本测试模拟本地解析置信度较低的情况")
print("   - 这种情况下HybridParsingService会调用AI服务")
print("   - 如果API密钥未配置，就会出现用户遇到的错误信息")
print()

// 检查API密钥状态
let securityManager = TestSecurityManager.shared
let hasKey = securityManager.hasAPIKey(for: .tongYiQianWen)
print("1. API密钥状态检查:")
print("   - 是否有API密钥: \(hasKey)")
if hasKey {
    if let key = securityManager.getAPIKey(for: .tongYiQianWen) {
        print("   - 密钥长度: \(key.count)")
        print("   - 密钥前缀: \(String(key.prefix(8)))...")
    }
} else {
    print("   ⚠️  这就是问题所在！API密钥未配置")
}
print()

// 测试HybridParsingService的完整调用链
print("2. 测试低置信度场景下的HybridParsingService调用链:")
let hybridService = TestHybridParsingService()

Task {
    // 使用一个模糊的文本，让本地解析置信度较低
    let result = await hybridService.parseExpenseText("花了一些钱")
    print("\n=== 最终结果 ===")
    print("金额: \(result.amount ?? 0)")
    print("分类: \(result.category ?? "无")")
    print("备注: \(result.note ?? "无")")
    print("置信度: \(result.confidence)")
    print("来源: \(result.source)")
    print("\n=== 结论 ===")
    print("✅ 成功复现了用户遇到的问题！")
    print("💡 当本地解析置信度低时，HybridParsingService会调用AI服务")
    print("💡 如果此时API密钥未配置，就会出现'阿里云通义千问 API密钥未找到'的错误")
    print("💡 解决方案：确保阿里云通义千问API密钥已正确配置")
    print("\n=== 测试完成 ===")
}

// 等待异步任务完成
RunLoop.main.run(until: Date().addingTimeInterval(3))