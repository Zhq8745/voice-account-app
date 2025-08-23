//
//  TongYiQianWenService.swift
//  AiVC
//
//  Created by AI Assistant on 2024/01/01.
//

import Foundation

// 阿里云通义千问分析结果结构
struct ExpenseAnalysisResult {
    let amount: Double?
    let category: String
    let note: String
    let confidence: Float
    let suggestions: [String]
}

// 阿里云通义千问API响应结构
struct TongYiResponse: Codable {
    let output: TongYiOutput
    let usage: TongYiUsage?
    let requestId: String?
    
    enum CodingKeys: String, CodingKey {
        case output
        case usage
        case requestId = "request_id"
    }
}

struct TongYiOutput: Codable {
    let text: String?
    let choices: [TongYiChoice]?
}

struct TongYiChoice: Codable {
    let message: TongYiMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case message
        case finishReason = "finish_reason"
    }
}

struct TongYiMessage: Codable {
    let role: String
    let content: String
}

struct TongYiUsage: Codable {
    let inputTokens: Int?
    let outputTokens: Int?
    let totalTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case totalTokens = "total_tokens"
    }
}

// 解析结果JSON结构
struct ParsedExpenseResult: Codable {
    let amount: Double?
    let category: String
    let note: String
    let confidence: Float
    let suggestions: [String]
}

// 阿里云通义千问服务类
@MainActor
class TongYiQianWenService: ObservableObject {
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    private let baseURL = "https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation"
    private let model = "qwen-turbo"
    private let timeout: TimeInterval = 30.0
    
    // 硬编码的API密钥 - 开发者统一配置
    private let apiKey = "sk-7e3c8c067ea246efb655495cb7d97d4d"
    
    private func getAPIKey() -> String? {
        return apiKey
    }
    
    // 分析语音文本为记账数据
    func analyzeExpenseText(_ text: String) async throws -> ExpenseAnalysisResult {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TongYiError.invalidInput("输入文本不能为空")
        }
        
        guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
            throw TongYiError.missingAPIKey("API密钥配置错误")
        }
        
        DispatchQueue.main.async {
            self.isProcessing = true
            self.errorMessage = nil
        }
        
        do {
            let prompt = buildPrompt(for: text)
            let response = try await sendRequest(prompt: prompt, apiKey: apiKey)
            let result = try parseResponse(response)
            
            DispatchQueue.main.async {
                self.isProcessing = false
            }
            
            return result
        } catch {
            DispatchQueue.main.async {
                self.isProcessing = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // 构建智能提示词
    private func buildPrompt(for text: String) -> String {
        return """
        你是一个专业的记账助手，请分析以下语音转文本的记账信息，准确提取关键信息。
        
        语音文本："\(text)"
        
        请严格按照以下JSON格式返回，不要添加任何其他内容：
        {
          "amount": 金额数字(必须是数字类型，如果无法确定则为null),
          "category": "分类名称",
          "note": "备注信息",
          "confidence": 置信度(0.0-1.0之间的小数),
          "suggestions": ["可能的修正建议1", "建议2"]
        }
        
        分类规则：
        - 餐饮：吃饭、喝咖啡、外卖、聚餐、早餐、午餐、晚餐、宵夜、火锅、烧烤、奶茶、甜品等
        - 交通：打车、地铁、公交、加油、停车、滴滴、出租车、机票、火车票、高铁等
        - 购物：买衣服、日用品、电子产品、化妆品、鞋子、包包、超市购物等
        - 娱乐：电影、游戏、KTV、旅游、景点门票、演唱会、健身、按摩、美容等
        - 医疗：看病、买药、体检、挂号费、药费、治疗费、牙科、眼科等
        - 教育：培训、书籍、课程、学费、教材、文具、网课、辅导班等
        - 生活：房租、水电费、物业费、网费、话费、生活用品、理发、洗衣等
        - 数码：手机、电脑、平板、耳机、相机、软件、充电器、数据线等
        - 其他：无法明确分类的支出
        
        金额提取规则：
        1. 识别"元"、"块"、"钱"等货币单位
        2. 处理"毛"、"角"(除以10)、"分"(除以100)等小额单位
        3. 转换中文数字：一、二、三、四、五、六、七、八、九、十、百、千、万
        4. 识别"花了"、"用了"、"买了"、"付了"等动词后的金额
        5. 如果文本中没有明确金额，amount设为null
        
        注意：
        1. 置信度基于文本清晰度和信息完整性评估
        2. 如果信息不完整或模糊，降低置信度
        3. 提供实用的修正建议
        4. 严格按照JSON格式返回，不要有多余的文字
        """
    }
    
    // 发送API请求
    private func sendRequest(prompt: String, apiKey: String) async throws -> Data {
        guard let url = URL(string: baseURL) else {
            throw TongYiError.invalidURL("API URL无效")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("AiVC/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = timeout
        
        let requestBody: [String: Any] = [
            "model": model,
            "input": [
                "messages": [
                    ["role": "user", "content": prompt]
                ]
            ],
            "parameters": [
                "result_format": "message",
                "temperature": 0.1,
                "max_tokens": 500,
                "top_p": 0.8
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw TongYiError.encodingError("请求数据编码失败: \(error.localizedDescription)")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw TongYiError.authenticationError("API密钥无效或已过期")
                case 429:
                    throw TongYiError.rateLimitError("API调用频率超限，请稍后重试")
                case 500...599:
                    throw TongYiError.serverError("服务器错误，请稍后重试")
                default:
                    throw TongYiError.httpError("HTTP错误: \(httpResponse.statusCode)")
                }
            }
            
            return data
        } catch let error as TongYiError {
            throw error
        } catch {
            throw TongYiError.networkError("网络请求失败: \(error.localizedDescription)")
        }
    }
    
    // 解析API响应
    private func parseResponse(_ data: Data) throws -> ExpenseAnalysisResult {
        do {
            let response = try JSONDecoder().decode(TongYiResponse.self, from: data)
            
            guard let content = response.output.choices?.first?.message.content ?? response.output.text else {
                throw TongYiError.parseError("API响应中没有找到内容")
            }
            
            // 提取JSON部分
            let jsonContent = extractJSON(from: content)
            
            guard let jsonData = jsonContent.data(using: .utf8) else {
                throw TongYiError.parseError("无法将响应内容转换为数据")
            }
            
            let parsedResult = try JSONDecoder().decode(ParsedExpenseResult.self, from: jsonData)
            
            return ExpenseAnalysisResult(
                amount: parsedResult.amount,
                category: parsedResult.category.isEmpty ? "其他" : parsedResult.category,
                note: parsedResult.note,
                confidence: max(0.0, min(1.0, parsedResult.confidence)),
                suggestions: parsedResult.suggestions
            )
            
        } catch let error as TongYiError {
            throw error
        } catch {
            throw TongYiError.parseError("解析API响应失败: \(error.localizedDescription)")
        }
    }
    
    // 从响应中提取JSON内容
    private func extractJSON(from content: String) -> String {
        // 查找JSON开始和结束位置
        if let startRange = content.range(of: "{"),
           let endRange = content.range(of: "}", options: .backwards) {
            let jsonRange = startRange.lowerBound..<content.index(after: endRange.lowerBound)
            return String(content[jsonRange])
        }
        
        // 如果没有找到完整的JSON，返回原内容
        return content
    }
    
    // 重置状态
    func reset() {
        errorMessage = nil
        isProcessing = false
    }
}

// 错误类型定义
enum TongYiError: LocalizedError {
    case missingAPIKey(String)
    case invalidInput(String)
    case invalidURL(String)
    case encodingError(String)
    case networkError(String)
    case authenticationError(String)
    case rateLimitError(String)
    case serverError(String)
    case httpError(String)
    case parseError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let message),
             .invalidInput(let message),
             .invalidURL(let message),
             .encodingError(let message),
             .networkError(let message),
             .authenticationError(let message),
             .rateLimitError(let message),
             .serverError(let message),
             .httpError(let message),
             .parseError(let message):
            return message
        }
    }
}