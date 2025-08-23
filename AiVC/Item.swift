//
//  Item.swift
//  AiVC
//
//  Created by 1234 on 2025/8/21.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
