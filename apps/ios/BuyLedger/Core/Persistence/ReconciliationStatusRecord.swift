//
//  ReconciliationStatusRecord.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/29.
//

import Foundation
import SwiftData

/// SwiftData 持久化的「對帳狀態主檔」記錄
@Model
final class ReconciliationStatusRecord {
    
    // MARK: - Data Properties
    
    /// 以對帳狀態名稱建立索引，供查詢與更新
    #Index<ReconciliationStatusRecord>([\.name])
    
    /// 對帳狀態名稱；同時作為 upsert 識別值
    var name: String
    
    // MARK: - Init
    
    /// 建立指定名稱的對帳狀態記錄
    /// - Parameter name: 對帳狀態名稱
    init(name: String) {
        self.name = name
    }
}

// MARK: - NameLookupRecord

extension ReconciliationStatusRecord: NameLookupRecord {
    
    /// 以對帳狀態名稱比對的查詢條件
    /// - Parameter name: 要比對的對帳狀態名稱
    /// - Returns: 供 `FetchDescriptor` 使用的查詢條件
    static func matchingName(_ name: String) -> Predicate<ReconciliationStatusRecord> {
        #Predicate { $0.name == name }
    }
}
