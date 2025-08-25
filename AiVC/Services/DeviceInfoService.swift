//
//  DeviceInfoService.swift
//  AiVC
//
//  Created by AI Assistant on 2025/01/21.
//

import UIKit
import Foundation

// MARK: - Device Info Service

struct DeviceInfoService {
    static func getDeviceInfo() -> [String: Any] {
        return [
            "deviceModel": UIDevice.current.model,
            "systemName": UIDevice.current.systemName,
            "systemVersion": UIDevice.current.systemVersion,
            "deviceId": UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        ]
    }
}

// MARK: - Network Info Service

struct NetworkInfoService {
    static func getNetworkInfo() -> [String: Any] {
        // 简化实现，实际应用中可以获取更详细的网络信息
        return [
            "connectionType": "wifi", // 可以通过Network框架获取实际连接类型
            "timestamp": Date().timeIntervalSince1970
        ]
    }
}