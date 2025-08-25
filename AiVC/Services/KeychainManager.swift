//
//  KeychainManager.swift
//  语记
//
//  Created by AI Assistant on 2025/01/21.
//

import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.shengcai.app"
    
    private init() {}
    
    // MARK: - 保存数据到钥匙串
    
    func save(key: String, value: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // 删除现有项目
        SecItemDelete(query as CFDictionary)
        
        // 添加新项目
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("钥匙串保存失败: \(status)")
        }
    }
    
    // MARK: - 从钥匙串加载数据
    
    func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        
        return nil
    }
    
    // MARK: - 从钥匙串删除数据
    
    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            print("钥匙串删除失败: \(status)")
        }
    }
    
    // MARK: - 清除所有钥匙串数据
    
    func clearAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            print("钥匙串清除失败: \(status)")
        }
    }
    
    // MARK: - 检查钥匙串中是否存在指定键
    
    func exists(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - 钥匙串键值枚举
    
    enum KeychainKey: String {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case appleUserIdentifier = "apple_user_identifier"
        case appleUserEmail = "apple_user_email"
        case appleUserFullName = "apple_user_full_name"
    }
    
    // MARK: - 便捷方法（使用枚举键）
    
    func save(_ value: String, for key: KeychainKey) {
        save(key: key.rawValue, value: value)
    }
    
    func load(for key: KeychainKey) -> String? {
        return load(key: key.rawValue)
    }
    
    func delete(for key: KeychainKey) {
        delete(key: key.rawValue)
    }
    
    func exists(for key: KeychainKey) -> Bool {
        return exists(key: key.rawValue)
    }
    
    // MARK: - 保存二进制数据到钥匙串
    
    func saveData(_ data: Data, for key: KeychainKey) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data
        ]
        
        // 删除现有项目
        SecItemDelete(query as CFDictionary)
        
        // 添加新项目
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("钥匙串保存数据失败: \(status)")
        }
    }
    
    // MARK: - 从钥匙串加载二进制数据
    
    func loadData(for key: KeychainKey) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data {
            return data
        }
        
        return nil
    }
    
    // MARK: - 认证令牌管理
    
    func saveAuthTokens(accessToken: String, refreshToken: String) {
        save(accessToken, for: .accessToken)
        save(refreshToken, for: .refreshToken)
    }
    
    func getAuthTokens() -> (accessToken: String?, refreshToken: String?) {
        let accessToken = load(for: .accessToken)
        let refreshToken = load(for: .refreshToken)
        return (accessToken, refreshToken)
    }
    
    func clearAuthTokens() {
        delete(for: .accessToken)
        delete(for: .refreshToken)
    }
    
    // MARK: - Apple用户信息管理
    
    func saveAppleUserIdentifier(_ identifier: String) {
        save(identifier, for: .appleUserIdentifier)
    }
    
    func getAppleUserIdentifier() -> String? {
        return load(for: .appleUserIdentifier)
    }
    
    func saveAppleUserEmail(_ email: String) {
        save(email, for: .appleUserEmail)
    }
    
    func getAppleUserEmail() -> String? {
        return load(for: .appleUserEmail)
    }
    
    func saveAppleUserFullName(_ fullName: PersonNameComponents) {
        // 将PersonNameComponents转换为字典再序列化
        let nameDict: [String: String?] = [
            "givenName": fullName.givenName,
            "familyName": fullName.familyName,
            "middleName": fullName.middleName,
            "namePrefix": fullName.namePrefix,
            "nameSuffix": fullName.nameSuffix,
            "nickname": fullName.nickname
        ]
        
        if let data = try? JSONEncoder().encode(nameDict) {
            saveData(data, for: .appleUserFullName)
        }
    }
    
    func getAppleUserFullName() -> PersonNameComponents? {
        guard let data = loadData(for: .appleUserFullName),
              let nameDict = try? JSONDecoder().decode([String: String?].self, from: data) else {
            return nil
        }
        
        var fullName = PersonNameComponents()
        fullName.givenName = nameDict["givenName"] ?? nil
        fullName.familyName = nameDict["familyName"] ?? nil
        fullName.middleName = nameDict["middleName"] ?? nil
        fullName.namePrefix = nameDict["namePrefix"] ?? nil
        fullName.nameSuffix = nameDict["nameSuffix"] ?? nil
        fullName.nickname = nameDict["nickname"] ?? nil
        
        return fullName
    }
    
    func clearAppleUserInfo() {
        delete(for: .appleUserIdentifier)
        delete(for: .appleUserEmail)
        delete(for: .appleUserFullName)
    }
}