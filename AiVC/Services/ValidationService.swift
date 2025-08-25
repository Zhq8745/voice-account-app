//
//  ValidationService.swift
//  AiVC
//
//  Created by AI Assistant
//

import Foundation

class ValidationService {
    static let shared = ValidationService()
    
    private init() {}
    
    // 验证结果结构体
    struct ValidationResult {
        let isValid: Bool
        let errors: [String]
        let message: String
        
        var errorMessage: String {
            return errors.joined(separator: "\n")
        }
        
        static func valid(_ message: String = "验证通过") -> ValidationResult {
            return ValidationResult(isValid: true, errors: [], message: message)
        }
        
        static func invalid(_ message: String) -> ValidationResult {
            return ValidationResult(isValid: false, errors: [message], message: message)
        }
        
        init(isValid: Bool, errors: [String], message: String = "") {
            self.isValid = isValid
            self.errors = errors
            self.message = message.isEmpty ? (isValid ? "验证通过" : errors.first ?? "验证失败") : message
        }
    }
    
    // 验证用户名
    func validateUsername(_ username: String) -> ValidationResult {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .invalid("用户名不能为空")
        }
        
        if trimmed.count < 3 {
            return .invalid("用户名长度不能少于3个字符")
        }
        
        if trimmed.count > 20 {
            return .invalid("用户名长度不能超过20个字符")
        }
        
        return .valid("用户名格式正确")
    }
    
    // 验证密码
    func validatePassword(_ password: String) -> ValidationResult {
        if password.isEmpty {
            return .invalid("密码不能为空")
        }
        
        if password.count < 6 {
            return .invalid("密码长度不能少于6个字符")
        }
        
        if password.count > 50 {
            return .invalid("密码长度不能超过50个字符")
        }
        
        return .valid("密码格式正确")
    }
    
    // 验证邮箱
    func validateEmail(_ email: String) -> ValidationResult {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .invalid("邮箱不能为空")
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: trimmed) {
            return .invalid("邮箱格式不正确")
        }
        
        return .valid("邮箱格式正确")
    }
    
    // 验证手机号
    func validatePhoneNumber(_ phoneNumber: String) -> Bool {
        let phoneRegex = "^1[3-9]\\d{9}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phoneNumber)
    }
    
    // 验证登录表单
    func validateLoginForm(identifier: String, password: String) -> [String: ValidationResult] {
        var results: [String: ValidationResult] = [:]
        
        // 验证标识符（用户名或邮箱）
        if identifier.contains("@") {
            results["identifier"] = validateEmail(identifier)
        } else {
            results["identifier"] = validateUsername(identifier)
        }
        
        // 验证密码
        results["password"] = validatePassword(password)
        
        return results
    }
    
    // 验证注册表单
    func validateRegisterForm(username: String, password: String, confirmPassword: String, email: String?, phoneNumber: String?) -> ValidationResult {
        var errors: [String] = []
        
        // 验证用户名
        let usernameResult = validateUsername(username)
        if !usernameResult.isValid {
            errors.append(contentsOf: usernameResult.errors)
        }
        
        // 验证密码
        let passwordResult = validatePassword(password)
        if !passwordResult.isValid {
            errors.append(contentsOf: passwordResult.errors)
        }
        
        // 验证确认密码
        if confirmPassword.isEmpty {
            errors.append("确认密码不能为空")
        } else if password != confirmPassword {
            errors.append("两次输入的密码不一致")
        }
        
        // 验证邮箱（如果提供）
        if let email = email, !email.isEmpty {
            let emailResult = validateEmail(email)
            if !emailResult.isValid {
                errors.append(contentsOf: emailResult.errors)
            }
        }
        
        // 验证手机号（如果提供）
        if let phoneNumber = phoneNumber, !phoneNumber.isEmpty {
            if !validatePhoneNumber(phoneNumber) {
                errors.append("手机号格式不正确")
            }
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
}