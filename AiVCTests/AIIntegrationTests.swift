//
//  AIIntegrationTests.swift
//  AiVCTests
//
//  Created by AI Assistant
//  AI功能集成测试
//

import XCTest
import Foundation
@testable import AiVC

class AIIntegrationTests: XCTestCase {
    
    // MARK: - HybridParsingService 本地解析测试
    
    func testLocalParsingBasicAmount() async {
        let service = HybridParsingService()
        
        let testText = "今天买菜花了50元"
        let result = await service.parseExpenseText(testText)
        
        XCTAssertEqual(result.amount, 50.0)
        XCTAssertEqual(result.source, ParseSource.local)
        XCTAssertEqual(result.originalText, testText)
        XCTAssertGreaterThan(result.confidence ?? 0, 0.5)
    }
    
    func testLocalParsingComplexText() async {
        let service = HybridParsingService()
        
        let testText = "午餐在餐厅吃了一顿，花费85.5元，味道不错"
        let result = await service.parseExpenseText(testText)
        
        XCTAssertEqual(result.amount, 85.5)
        XCTAssertTrue(result.category?.contains("餐") == true || result.category?.contains("食") == true)
        XCTAssertTrue(result.note?.contains("味道") == true)
        XCTAssertEqual(result.source, ParseSource.local)
    }
    
    func testLocalParsingNoAmount() async {
        let service = HybridParsingService()
        
        let testText = "今天天气很好"
        let result = await service.parseExpenseText(testText)
        
        XCTAssertTrue(result.amount == nil || result.amount == 0.0)
        XCTAssertLessThan(result.confidence ?? 1.0, 0.5)
        XCTAssertEqual(result.source, ParseSource.local)
    }
    
    // MARK: - SecurityManager 测试
    
    func testSecurityManagerAPIKeyManagement() {
        let securityManager = SecurityManager.shared
        
        // 测试设置和获取API密钥
        let testAPIKey = "sk-test-api-key-12345"
        let success = securityManager.storeAPIKey(testAPIKey, for: .tongYiQianWen)
        XCTAssertTrue(success)
        
        let retrievedKey = securityManager.getAPIKey(for: .tongYiQianWen)
        XCTAssertEqual(retrievedKey, testAPIKey)
    }
    
    func testSecurityManagerAPIKeyValidation() {
        let securityManager = SecurityManager.shared
        
        // 测试有效密钥
        let validKey = "sk-1234567890abcdef1234567890"
        let validResult = securityManager.validateAPIKey(validKey, for: .tongYiQianWen)
        XCTAssertTrue(validResult.isValid)
        
        // 测试无效密钥
        let invalidKey = "invalid-key"
        let invalidResult = securityManager.validateAPIKey(invalidKey, for: .tongYiQianWen)
        XCTAssertFalse(invalidResult.isValid)
        
        // 测试空密钥
        let emptyResult = securityManager.validateAPIKey("", for: .tongYiQianWen)
        XCTAssertFalse(emptyResult.isValid)
    }
    
    // MARK: - TongYiQianWenService 模拟测试
    
    func testTongYiQianWenServiceWithoutAPIKey() async {
        let tongYiQianWen = TongYiQianWenService()
        
        do {
            _ = try await tongYiQianWen.analyzeExpenseText("测试文本")
            XCTFail("应该抛出API密钥缺失错误")
        } catch TongYiError.missingAPIKey {
            // 预期的错误
            XCTAssertTrue(true)
        } catch {
            XCTFail("意外的错误类型: \(error)")
        }
    }
    
    // MARK: - HybridParsingService 降级机制测试
    
    func testHybridServiceFallbackMechanism() async {
        let service = HybridParsingService()
        
        // 清除API密钥以触发降级
        SecurityManager.shared.deleteAPIKey(for: .tongYiQianWen)
        
        let testText = "买咖啡花了25元"
        
        let result = await service.parseExpenseText(testText)
        
        // 验证降级到本地解析
        XCTAssertEqual(result.amount, 25.0)
        XCTAssertEqual(result.category, "餐饮")
        XCTAssertEqual(result.source, ParseSource.local)
    }
    
    func testHybridServiceResetFunctionality() async {
        let service = HybridParsingService()
        
        // 清除API密钥
        SecurityManager.shared.deleteAPIKey(for: .tongYiQianWen)
        
        let testText = "测试文本"
        
        _ = await service.parseExpenseText(testText)
        
        // 验证有错误信息（因为没有API密钥）
        let errorMessage = await service.errorMessage
        XCTAssertNotNil(errorMessage)
        
        // 重置服务
        await service.reset()
        
        // 验证状态已重置
        let resetErrorMessage = await service.errorMessage
        XCTAssertNil(resetErrorMessage)
    }
    
    // MARK: - SpeechRecognitionService 集成测试
    
    func testSpeechRecognitionServiceIntegration() async {
        let speechService = SpeechRecognitionService()
        
        let testText = "午餐花了25元"
        let result = await speechService.parseExpenseFromText(testText)
        
        XCTAssertEqual(result.text, testText)
        XCTAssertEqual(result.amount, 25.0)
        XCTAssertNotNil(result.category)
        XCTAssertGreaterThan(result.confidence, 0.0)
    }
    
    // MARK: - 边界情况测试
    
    func testEmptyText() async {
        let service = HybridParsingService()
        
        let result = await service.parseExpenseText("")
        
        XCTAssertTrue(result.amount == nil || result.amount == 0.0)
        XCTAssertLessThan(result.confidence ?? 1.0, 0.5)
        XCTAssertEqual(result.originalText, "")
    }
    
    func testSpecialCharactersText() async {
        let service = HybridParsingService()
        
        let specialText = "买了@#$%^&*()咖啡☕️花费￥25.50元！！！"
        let result = await service.parseExpenseText(specialText)
        
        XCTAssertEqual(result.amount, 25.50)
        XCTAssertEqual(result.originalText, specialText)
    }
    
    // MARK: - 数据一致性测试
    
    func testDataConsistency() async {
        let service = HybridParsingService()
        let testText = "午餐花了35元"
        
        let result1 = await service.parseExpenseText(testText)
        let result2 = await service.parseExpenseText(testText)
        
        XCTAssertEqual(result1.amount, result2.amount)
        XCTAssertEqual(result1.category, result2.category)
        XCTAssertEqual(result1.source, result2.source)
        XCTAssertLessThan(abs((result1.confidence ?? 0) - (result2.confidence ?? 0)), 0.1)
    }
}