//
//  Item.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/29.
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
