//
//  Item.swift
//  IT-Inventory Manager
//
//  Created by Minamino Shuichi on 10.02.26.
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
