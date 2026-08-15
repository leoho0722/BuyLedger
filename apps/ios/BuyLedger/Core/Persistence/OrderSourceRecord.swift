//
//  OrderSourceRecord.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation
import SwiftData

/// SwiftData 持久化的「訂單來源主檔」記錄
@Model
final class OrderSourceRecord {
    
    // MARK: - Data Properties
    
    /// 以訂單來源名稱建立索引，供查詢與更新
    #Index<OrderSourceRecord>([\.name])
    
    /// 訂單來源名稱；同時作為 upsert 識別值
    var name: String
    
    // MARK: - Init
    
    /// 建立指定名稱的訂單來源記錄
    /// - Parameter name: 訂單來源名稱
    init(name: String) {
        self.name = name
    }
}

// MARK: - NameLookupRecord

extension OrderSourceRecord: NameLookupRecord {
    
    /// 以訂單來源名稱比對的查詢條件
    /// - Parameter name: 要比對的訂單來源名稱
    /// - Returns: 供 `FetchDescriptor` 使用的查詢條件
    static func matchingName(_ name: String) -> Predicate<OrderSourceRecord> {
        #Predicate { $0.name == name }
    }
}
