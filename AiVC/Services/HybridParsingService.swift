//
//  HybridParsingService.swift
//  AiVC
//
//  Created by AI Assistant on 2024/01/01.
//

import Foundation

// 统一的解析结果结构
struct ParseResult {
    let amount: Double?
    let category: String?
    let note: String?
    let confidence: Float
    let source: ParseSource
    let suggestions: [String]
    let originalText: String
}

// 解析来源
enum ParseSource {
    case local
    case ai
    case hybrid
}

// 本地解析器（基于现有的SpeechRecognitionService逻辑）
class LocalExpenseParser {
    
    func parse(_ text: String) -> ParseResult {
        let lowercaseText = text.lowercased()
        
        // 提取金额
        let amount = extractAmount(from: lowercaseText)
        
        // 提取分类
        let category = extractCategory(from: lowercaseText)
        
        // 提取备注
        let note = extractNote(from: lowercaseText, amount: amount, category: category)
        
        // 计算置信度
        let confidence = calculateConfidence(amount: amount, category: category, text: text)
        
        return ParseResult(
            amount: amount,
            category: category,
            note: note,
            confidence: confidence,
            source: .local,
            suggestions: generateLocalSuggestions(text: text, amount: amount, category: category),
            originalText: text
        )
    }
    
    // 提取金额
    private func extractAmount(from text: String) -> Double? {
        // 先尝试转换中文数字
        let convertedText = convertChineseNumbers(text)
        
        // 匹配数字和货币符号的模式
        let patterns = [
            #"(\d+(?:\.\d{1,2})?)\s*[元块钱]"#,
            #"(\d+(?:\.\d{1,2})?)\s*块"#,
            #"(\d+(?:\.\d{1,2})?)[元块钱]"#,
            #"(\d+(?:\.\d{1,2})?)毛"#,
            #"(\d+(?:\.\d{1,2})?)角"#,
            #"(\d+(?:\.\d{1,2})?)分"#,
            #"花了\s*(\d+(?:\.\d{1,2})?)"#,
            #"用了\s*(\d+(?:\.\d{1,2})?)"#,
            #"买了\s*\d+.*?(\d+(?:\.\d{1,2})?)"#,
            #"付了\s*(\d+(?:\.\d{1,2})?)"#,
            #"(\d+(?:\.\d{1,2})?)\s*元"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: convertedText.utf16.count)
                if let match = regex.firstMatch(in: convertedText, options: [], range: range) {
                    if let amountRange = Range(match.range(at: 1), in: convertedText) {
                        let amountString = String(convertedText[amountRange])
                        if let amount = Double(amountString) {
                            // 处理角分单位
                            if text.contains("角") || text.contains("毛") {
                                return amount / 10.0
                            } else if text.contains("分") {
                                return amount / 100.0
                            }
                            return amount
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    private func convertChineseNumbers(_ text: String) -> String {
        let chineseToArabic: [String: String] = [
            "零": "0", "一": "1", "二": "2", "三": "3", "四": "4",
            "五": "5", "六": "6", "七": "7", "八": "8", "九": "9",
            "十": "10", "百": "100", "千": "1000", "万": "10000",
            "两": "2", "俩": "2", "半": "0.5"
        ]
        
        var result = text
        
        // 处理特殊组合
        let specialPatterns: [(String, String)] = [
            ("一十", "10"), ("二十", "20"), ("三十", "30"), ("四十", "40"), ("五十", "50"),
            ("六十", "60"), ("七十", "70"), ("八十", "80"), ("九十", "90"),
            ("十一", "11"), ("十二", "12"), ("十三", "13"), ("十四", "14"), ("十五", "15"),
            ("十六", "16"), ("十七", "17"), ("十八", "18"), ("十九", "19")
        ]
        
        // 先处理特殊组合
        for (chinese, arabic) in specialPatterns {
            result = result.replacingOccurrences(of: chinese, with: arabic)
        }
        
        // 再处理单个字符
        for (chinese, arabic) in chineseToArabic {
            result = result.replacingOccurrences(of: chinese, with: arabic)
        }
        
        return result
    }
    
    // 提取分类
    private func extractCategory(from text: String) -> String? {
        let categoryKeywords: [String: [String]] = [
            "餐饮": ["吃", "喝", "餐", "饭", "菜", "食", "饮", "咖啡", "茶", "奶茶", "外卖", "聚餐", "早餐", "午餐", "晚餐", "宵夜", "火锅", "烧烤", "麻辣烫", "面条", "米饭", "包子", "饺子", "汉堡", "披萨", "寿司", "甜品", "蛋糕", "冰淇淋", "零食", "水果", "牛奶", "酸奶", "果汁", "啤酒", "白酒", "红酒", "饮料", "矿泉水"],
            "交通": ["车", "油", "地铁", "公交", "打车", "滴滴", "出租", "停车", "加油", "高速", "过路费", "车费", "机票", "火车票", "高铁", "动车", "飞机", "船票", "摩托车", "电动车", "自行车", "共享单车", "网约车", "出行", "交通卡", "ETC", "违章", "保险", "年检", "维修"],
            "购物": ["买", "购", "商场", "超市", "淘宝", "京东", "网购", "衣服", "鞋子", "包包", "化妆品", "护肤品", "香水", "首饰", "手表", "眼镜", "帽子", "围巾", "手套", "内衣", "袜子", "裤子", "裙子", "外套", "T恤", "衬衫", "毛衣", "羽绒服", "运动鞋", "皮鞋", "凉鞋", "拖鞋"],
            "娱乐": ["电影", "游戏", "KTV", "唱歌", "旅游", "景点", "门票", "娱乐", "玩", "看电影", "演唱会", "话剧", "音乐会", "展览", "博物馆", "游乐园", "酒吧", "夜店", "桌游", "密室逃脱", "剧本杀", "网吧", "台球", "保龄球", "健身", "游泳", "瑜伽", "按摩", "SPA", "美容", "美甲"],
            "医疗": ["医院", "药", "看病", "体检", "医疗", "挂号费", "药费", "治疗", "手术", "住院", "检查", "化验", "拍片", "CT", "核磁", "B超", "心电图", "血压", "血糖", "疫苗", "打针", "输液", "牙科", "眼科", "皮肤科", "妇科", "儿科", "中医", "针灸", "推拿"],
            "教育": ["书", "课程", "培训", "学费", "教育", "学习", "考试", "报名费", "教材", "参考书", "笔记本", "文具", "笔", "橡皮", "尺子", "计算器", "电脑", "平板", "软件", "网课", "辅导班", "家教", "驾校", "证书", "考证", "英语", "托福", "雅思", "四六级"],
            "生活": ["水电费", "房租", "物业费", "网费", "话费", "生活用品", "日用品", "洗衣", "理发", "洗发水", "沐浴露", "牙膏", "牙刷", "毛巾", "纸巾", "洗衣液", "洗洁精", "垃圾袋", "电池", "灯泡", "插座", "充电器", "数据线", "家具", "电器", "维修", "搬家", "快递", "邮费"],
            "数码": ["手机", "电脑", "平板", "耳机", "音响", "相机", "摄像头", "键盘", "鼠标", "显示器", "硬盘", "内存", "CPU", "显卡", "主板", "电源", "机箱", "散热器", "风扇", "数据线", "充电器", "移动电源", "路由器", "交换机", "网线", "WiFi", "蓝牙", "智能手表", "智能手环", "无人机"]
        ]
        
        for (category, keywords) in categoryKeywords {
            for keyword in keywords {
                if text.contains(keyword) {
                    return category
                }
            }
        }
        
        return nil
    }
    
    // 提取备注
    private func extractNote(from text: String, amount: Double?, category: String?) -> String? {
        var note = text
        
        // 移除金额相关文字
        if let amount = amount {
            let amountPatterns = [
                "\(amount)元",
                "\(amount)块",
                "\(amount)钱",
                "花了\(amount)",
                "用了\(amount)",
                "付了\(amount)"
            ]
            
            for pattern in amountPatterns {
                note = note.replacingOccurrences(of: pattern, with: "")
            }
        }
        
        // 移除分类相关文字
        if let category = category {
            note = note.replacingOccurrences(of: category, with: "")
        }
        
        // 清理多余的空格和标点
        note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        note = note.replacingOccurrences(of: "  ", with: " ")
        
        return note.isEmpty ? nil : note
    }
    
    // 计算置信度
    private func calculateConfidence(amount: Double?, category: String?, text: String) -> Float {
        var confidence: Float = 0.0
        
        // 金额识别加分
        if amount != nil {
            confidence += 0.4
        }
        
        // 分类识别加分
        if category != nil {
            confidence += 0.3
        }
        
        // 文本长度和清晰度加分
        let textLength = text.count
        if textLength > 5 && textLength < 50 {
            confidence += 0.2
        }
        
        // 包含关键动词加分
        let actionWords = ["花了", "用了", "买了", "付了", "消费"]
        for word in actionWords {
            if text.contains(word) {
                confidence += 0.1
                break
            }
        }
        
        return min(1.0, confidence)
    }
    
    // 生成本地建议
    private func generateLocalSuggestions(text: String, amount: Double?, category: String?) -> [String] {
        var suggestions: [String] = []
        
        if amount == nil {
            suggestions.append("请确认金额信息")
        }
        
        if category == nil {
            suggestions.append("请选择消费分类")
        }
        
        if text.count < 5 {
            suggestions.append("语音内容过短，建议重新录制")
        }
        
        return suggestions
    }
}

// 混合解析策略服务
@MainActor
class HybridParsingService: ObservableObject {
    @Published var isProcessing = false
    @Published var lastParseResult: ParseResult?
    @Published var errorMessage: String?
    
    private let localParser = LocalExpenseParser()
    private let aiService = TongYiQianWenService()
    
    // 解析语音文本
    func parseExpenseText(_ text: String) async -> ParseResult {
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
        
        DispatchQueue.main.async {
            self.isProcessing = true
            self.errorMessage = nil
        }
        
        // 1. 本地快速解析
        let localResult = localParser.parse(text)
        
        // 2. 置信度评估
        if localResult.confidence > 0.8 {
            DispatchQueue.main.async {
                self.isProcessing = false
                self.lastParseResult = localResult
            }
            return localResult
        }
        
        // 3. AI增强解析
        do {
            let aiResult = try await aiService.analyzeExpenseText(text)
            let hybridResult = combineResults(local: localResult, ai: aiResult, originalText: text)
            
            DispatchQueue.main.async {
                self.isProcessing = false
                self.lastParseResult = hybridResult
            }
            
            return hybridResult
        } catch {
            // AI服务失败时降级到本地解析
            DispatchQueue.main.async {
                self.isProcessing = false
                self.errorMessage = "AI解析失败，使用本地解析: \(error.localizedDescription)"
                self.lastParseResult = localResult
            }
            
            return localResult
        }
    }
    
    // 结合本地和AI解析结果
    private func combineResults(local: ParseResult, ai: ExpenseAnalysisResult, originalText: String) -> ParseResult {
        // 优先使用AI结果，但保留本地解析作为备选
        let finalAmount = ai.amount ?? local.amount
        let finalCategory = ai.category.isEmpty ? local.category : ai.category
        let finalNote = ai.note.isEmpty ? local.note : ai.note
        
        // 计算混合置信度
        let hybridConfidence = calculateHybridConfidence(
            localConfidence: local.confidence,
            aiConfidence: ai.confidence,
            hasAmount: finalAmount != nil,
            hasCategory: finalCategory != nil
        )
        
        // 合并建议
        var combinedSuggestions = ai.suggestions
        for suggestion in local.suggestions {
            if !combinedSuggestions.contains(suggestion) {
                combinedSuggestions.append(suggestion)
            }
        }
        
        return ParseResult(
            amount: finalAmount,
            category: finalCategory,
            note: finalNote,
            confidence: hybridConfidence,
            source: .hybrid,
            suggestions: combinedSuggestions,
            originalText: originalText
        )
    }
    
    // 计算混合置信度
    private func calculateHybridConfidence(
        localConfidence: Float,
        aiConfidence: Float,
        hasAmount: Bool,
        hasCategory: Bool
    ) -> Float {
        // 基础置信度取AI和本地的最大值
        var confidence = max(localConfidence, aiConfidence)
        
        // AI解析成功时提升置信度
        if aiConfidence > 0.5 {
            confidence = min(1.0, confidence + 0.1)
        }
        
        // 信息完整性加分
        if hasAmount && hasCategory {
            confidence = min(1.0, confidence + 0.1)
        }
        
        return confidence
    }
    
    // 重置状态
    func reset() {
        errorMessage = nil
        isProcessing = false
        lastParseResult = nil
        aiService.reset()
    }
    
    // 获取AI服务状态
    var aiServiceStatus: String {
        if aiService.isProcessing {
            return "AI解析中..."
        } else if aiService.errorMessage != nil {
            return "AI服务异常"
        } else {
            return "AI服务就绪"
        }
    }
}