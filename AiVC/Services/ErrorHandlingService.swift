//
//  ErrorHandlingService.swift
//  语记
//
//  Created by AI Assistant
//

import Foundation
import os.log

class ErrorHandlingService {
    static let shared = ErrorHandlingService()
    
    private let logger = Logger(subsystem: "com.shengcai.app", category: "ErrorHandling")
    
    private init() {}
    
    // 应用错误类型
    enum AppError: Error, LocalizedError {
        case networkError(String)
        case authenticationError(String)
        case validationError(String)
        case dataError(String)
        case unknownError(String)
        
        var errorDescription: String? {
            switch self {
            case .networkError(let message):
                return "网络错误: \(message)"
            case .authenticationError(let message):
                return "认证错误: \(message)"
            case .validationError(let message):
                return "验证错误: \(message)"
            case .dataError(let message):
                return "数据错误: \(message)"
            case .unknownError(let message):
                return "未知错误: \(message)"
            }
        }
        
        var localizedDescription: String {
            return errorDescription ?? "发生了未知错误"
        }
    }
    
    // 处理错误
    func handleError(_ error: Error, context: String = "") {
        let errorMessage = formatErrorMessage(error, context: context)
        logger.error("\(errorMessage)")
        
        // 在调试模式下打印到控制台
        #if DEBUG
        print("[ERROR] \(errorMessage)")
        #endif
    }
    
    // 格式化错误消息
    private func formatErrorMessage(_ error: Error, context: String) -> String {
        let contextPrefix = context.isEmpty ? "" : "[\(context)] "
        
        if let appError = error as? AppError {
            return "\(contextPrefix)\(appError.localizedDescription)"
        } else {
            return "\(contextPrefix)\(error.localizedDescription)"
        }
    }
    
    // 将通用错误转换为应用错误
    func mapToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        // 根据错误类型进行映射
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("network") || errorDescription.contains("internet") {
            return .networkError(error.localizedDescription)
        } else if errorDescription.contains("unauthorized") || errorDescription.contains("authentication") {
            return .authenticationError(error.localizedDescription)
        } else if errorDescription.contains("validation") || errorDescription.contains("invalid") {
            return .validationError(error.localizedDescription)
        } else if errorDescription.contains("data") || errorDescription.contains("decode") {
            return .dataError(error.localizedDescription)
        } else {
            return .unknownError(error.localizedDescription)
        }
    }
    
    // 创建用户友好的错误消息
    func createUserFriendlyMessage(for error: Error) -> String {
        let appError = mapToAppError(error)
        
        switch appError {
        case .networkError(_):
            return "网络连接异常，请检查网络设置后重试"
        case .authenticationError(_):
            return "登录信息已过期，请重新登录"
        case .validationError(let message):
            return message
        case .dataError(_):
            return "数据处理异常，请稍后重试"
        case .unknownError(_):
            return "操作失败，请稍后重试"
        }
    }
    
    // 记录错误并返回用户友好消息
    func logAndGetUserMessage(for error: Error, context: String = "") -> String {
        handleError(error, context: context)
        return createUserFriendlyMessage(for: error)
    }
    
    // 处理验证错误
    func handleValidationError(_ context: String, message: String) {
        let error = AppError.validationError(message)
        handleError(error, context: context)
    }
    
    // 处理认证错误
    func handleAuthenticationError(_ context: String, message: String) {
        let error = AppError.authenticationError(message)
        handleError(error, context: context)
    }
    
    // 处理网络错误
    func handleNetworkError(_ context: String, message: String) {
        let error = AppError.networkError(message)
        handleError(error, context: context)
    }
    
    // 处理数据错误
    func handleDataError(_ context: String, message: String) {
        let error = AppError.dataError(message)
        handleError(error, context: context)
    }
}