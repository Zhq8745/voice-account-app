//
//  AppleSignInService.swift
//  AiVC
//
//  Created by AI Assistant on 2025/01/21.
//

import Foundation
import AuthenticationServices
import SwiftUI
import Combine

// MARK: - Apple Sign In Models

struct AppleSignInResult {
    let userIdentifier: String
    let email: String?
    let fullName: PersonNameComponents?
    let identityToken: Data?
    let authorizationCode: Data?
    let isNewUser: Bool
}

enum AppleSignInError: Error, LocalizedError {
    case cancelled
    case failed
    case invalidResponse
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "用户取消了Apple登录"
        case .failed:
            return "Apple登录失败"
        case .invalidResponse:
            return "Apple登录响应无效"
        case .networkError:
            return "网络连接失败"
        case .unknown:
            return "未知错误"
        }
    }
}

// MARK: - Apple Sign In Service

class AppleSignInService: NSObject, ObservableObject {
    static let shared = AppleSignInService()
    
    @Published var isLoading = false
    
    private let keychainManager = KeychainManager.shared
    private let loginLogger = LoginLogService.shared
    private var currentDelegate: AppleSignInDelegate?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// 开始Apple登录流程
    func signInWithApple() async throws -> AppleSignInResult {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                self.performAppleSignIn { result in
                    continuation.resume(with: result)
                }
            }
        }
    }
    
    /// 检查Apple登录状态
    func checkAppleSignInStatus(for userIdentifier: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        let provider = ASAuthorizationAppleIDProvider()
        
        return await withCheckedContinuation { continuation in
            provider.getCredentialState(forUserID: userIdentifier) { state, error in
                continuation.resume(returning: state)
            }
        }
    }
    
    /// 撤销Apple登录
    func revokeAppleSignIn() async throws {
        // 清除本地存储的Apple用户信息
        keychainManager.clearAppleUserInfo()
        
        // 记录撤销日志
        let savedInfo = getSavedAppleUserInfo()
        if let identifier = savedInfo.identifier {
            loginLogger.logLogout(userId: identifier, username: savedInfo.email)
        }
    }
    
    // MARK: - Private Methods
    
    private func performAppleSignIn(completion: @escaping (Result<AppleSignInResult, AppleSignInError>) -> Void) {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        
        // 请求用户信息
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        
        // 保持delegate的强引用
        currentDelegate = AppleSignInDelegate(completion: { [weak self] result in
            self?.currentDelegate = nil
            completion(result)
        })
        
        controller.delegate = currentDelegate
        controller.presentationContextProvider = AppleSignInPresentationContextProvider()
        
        isLoading = true
        controller.performRequests()
    }
    
    /// 保存Apple用户信息到Keychain
    func saveAppleUserInfo(_ result: AppleSignInResult) {
        keychainManager.saveAppleUserIdentifier(result.userIdentifier)
        
        if let email = result.email {
            keychainManager.saveAppleUserEmail(email)
        }
        
        if let fullName = result.fullName {
            keychainManager.saveAppleUserFullName(fullName)
        }
    }
    
    /// 获取保存的Apple用户信息
    func getSavedAppleUserInfo() -> (identifier: String?, email: String?, fullName: PersonNameComponents?) {
        let identifier = keychainManager.getAppleUserIdentifier()
        let email = keychainManager.getAppleUserEmail()
        let fullName = keychainManager.getAppleUserFullName()
        
        return (identifier, email, fullName)
    }
}

// MARK: - Apple Sign In Delegate

private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    private let completion: (Result<AppleSignInResult, AppleSignInError>) -> Void
    
    init(completion: @escaping (Result<AppleSignInResult, AppleSignInError>) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        DispatchQueue.main.async {
            AppleSignInService.shared.isLoading = false
        }
        
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            completion(.failure(.invalidResponse))
            return
        }
        
        let result = AppleSignInResult(
            userIdentifier: credential.user,
            email: credential.email,
            fullName: credential.fullName,
            identityToken: credential.identityToken,
            authorizationCode: credential.authorizationCode,
            isNewUser: credential.email != nil // 如果有email，通常表示是新用户
        )
        
        // 保存用户信息
        AppleSignInService.shared.saveAppleUserInfo(result)
        
        completion(.success(result))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        DispatchQueue.main.async {
            AppleSignInService.shared.isLoading = false
        }
        
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                completion(.failure(.cancelled))
            case .failed:
                completion(.failure(.failed))
            case .invalidResponse:
                completion(.failure(.invalidResponse))
            case .notHandled:
                completion(.failure(.failed))
            case .unknown:
                completion(.failure(.unknown))
            @unknown default:
                completion(.failure(.unknown))
            }
        } else {
            completion(.failure(.unknown))
        }
    }
}

// MARK: - Presentation Context Provider

private class AppleSignInPresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
}