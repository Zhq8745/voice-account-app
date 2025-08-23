//
//  SpeechRecognitionService.swift
//  AiVC
//
//  Created by AI Assistant on 2024/01/01.
//

import Foundation
import Speech
import AVFoundation
import SwiftUI

// 语音识别结果结构
struct SpeechRecognitionResult {
    let text: String
    let amount: Double?
    let category: String?
    let note: String?
    let confidence: Double
    let parseSource: ParseSource
    let aiSuggestions: [String]?
}

// 语音识别服务类
@MainActor
class SpeechRecognitionService: ObservableObject {
    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var isAuthorized = false
    @Published var errorMessage: String?
    
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        requestAuthorization()
    }
    
    // 请求权限
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self?.isAuthorized = true
                case .denied, .restricted, .notDetermined:
                    self?.isAuthorized = false
                    self?.errorMessage = "语音识别权限被拒绝，请在设置中开启权限"
                @unknown default:
                    self?.isAuthorized = false
                }
            }
        }
        
        // 请求麦克风权限
        AVAudioApplication.requestRecordPermission { granted in
            if !granted {
                DispatchQueue.main.async {
                    self.errorMessage = "麦克风权限被拒绝，请在设置中开启权限"
                }
            }
        }
    }
    
    // 开始录音和识别
    func startRecording() {
        guard isAuthorized else {
            DispatchQueue.main.async {
                self.errorMessage = "语音识别未授权，请在设置中开启麦克风权限"
            }
            return
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            DispatchQueue.main.async {
                self.errorMessage = "语音识别服务不可用"
            }
            return
        }
        
        // 停止之前的任务
        stopRecording()
        
        // 重置错误信息
        errorMessage = nil
        
        do {
            // 配置音频会话 (仅在iOS上)
            #if os(iOS)
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            #endif
            
            // 创建识别请求
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                DispatchQueue.main.async {
                    self.errorMessage = "无法创建语音识别请求"
                }
                return
            }
            
            recognitionRequest.shouldReportPartialResults = true
            
            // 配置音频引擎
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            // 检查音频格式
            guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
                DispatchQueue.main.async {
                    self.errorMessage = "音频格式无效"
                }
                return
            }
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            // 开始识别
            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = "语音识别错误: \(error.localizedDescription)"
                        self?.stopRecording()
                        return
                    }
                    
                    if let result = result {
                        self?.recognizedText = result.bestTranscription.formattedString
                        
                        if result.isFinal {
                            self?.stopRecording()
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.isRecording = true
                self.recognizedText = "正在听..."
            }
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "音频引擎启动失败: \(error.localizedDescription)"
            }
        }
    }
    
    // 停止录音
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
    }
    
    // 解析语音文本为记账数据
    func parseExpenseFromText(_ text: String) async -> SpeechRecognitionResult {
        // 使用混合解析策略
        let hybridService = HybridParsingService()
        let parseResult = await hybridService.parseExpenseText(text)
        
        return SpeechRecognitionResult(
            text: text,
            amount: parseResult.amount,
            category: parseResult.category,
            note: parseResult.note,
            confidence: Double(parseResult.confidence),
            parseSource: parseResult.source,
            aiSuggestions: parseResult.suggestions
        )
    }
    
    // 保留原有的本地解析方法作为备用
    func parseExpenseFromTextLocal(_ text: String) -> SpeechRecognitionResult {
        let lowercaseText = text.lowercased()
        
        // 提取金额
        let amount = extractAmount(from: lowercaseText)
        
        // 提取分类
        let category = extractCategory(from: lowercaseText)
        
        // 提取备注
        let note = extractNote(from: lowercaseText, amount: amount, category: category)
        
        return SpeechRecognitionResult(
            text: text,
            amount: amount,
            category: category,
            note: note,
            confidence: 0.8, // 简化的置信度
            parseSource: .local,
            aiSuggestions: nil
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
            #"买了\s*\d+.*?(\d+(?:\.\d{1,2})?)"#
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
            ("一十", "10"),
            ("二十", "20"),
            ("三十", "30"),
            ("四十", "40"),
            ("五十", "50"),
            ("六十", "60"),
            ("七十", "70"),
            ("八十", "80"),
            ("九十", "90"),
            ("十一", "11"),
            ("十二", "12"),
            ("十三", "13"),
            ("十四", "14"),
            ("十五", "15"),
            ("十六", "16"),
            ("十七", "17"),
            ("十八", "18"),
            ("十九", "19")
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
            "生活": ["水电费", "房租", "物业费", "网费", "话费", "生活用品", "日用品", "洗衣", "理发", "洗发水", "沐浴露", "牙膏", "牙刷", "毛巾", "纸巾", "洗衣液", "洗洁精", "垃圾袋", "电池", "灯泡", "插座", "充电器", "数据线", "家具", "电器", "维修", "搬家", "快递", "邮费"],
            "医疗": ["医院", "药", "看病", "体检", "医疗", "挂号费", "药费", "治疗", "手术", "住院", "检查", "化验", "拍片", "CT", "核磁", "B超", "心电图", "血压", "血糖", "疫苗", "打针", "输液", "牙科", "眼科", "皮肤科", "妇科", "儿科", "中医", "针灸", "推拿"],
            "学习": ["书", "课程", "培训", "学费", "教育", "学习", "考试", "报名费", "教材", "参考书", "笔记本", "文具", "笔", "橡皮", "尺子", "计算器", "电脑", "平板", "软件", "网课", "辅导班", "家教", "驾校", "证书", "考证", "英语", "托福", "雅思", "四六级"],
            "数码": ["手机", "电脑", "平板", "耳机", "音响", "相机", "摄像头", "键盘", "鼠标", "显示器", "硬盘", "内存", "CPU", "显卡", "主板", "电源", "机箱", "散热器", "风扇", "数据线", "充电器", "移动电源", "路由器", "交换机", "网线", "WiFi", "蓝牙", "智能手表", "智能手环", "无人机"],
            "家居": ["家具", "沙发", "床", "桌子", "椅子", "柜子", "衣柜", "书柜", "鞋柜", "茶几", "餐桌", "床垫", "枕头", "被子", "床单", "窗帘", "地毯", "灯具", "台灯", "吊灯", "装修", "油漆", "瓷砖", "地板", "墙纸", "五金", "工具", "螺丝", "钉子", "胶水"]
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
                "用了\(amount)"
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
    
    // 重置状态
    func reset() {
        recognizedText = ""
        errorMessage = nil
    }
}

// 语音识别权限状态
enum SpeechAuthorizationStatus {
    case notDetermined
    case denied
    case restricted
    case authorized
}