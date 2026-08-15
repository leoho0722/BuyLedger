//
//  CategoryRecord.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation
import SwiftData

/// SwiftData 持久化的「商品類別主檔」記錄
@Model
final class CategoryRecord {
    
    // MARK: - Data Properties
    
    /// 以類別名稱建立索引，供查詢與更新
    #Index<CategoryRecord>([\.name])
    
    /// 類別名稱；同時作為 upsert 識別值
    var name: String
    
    // MARK: - Init
    
    /// 建立指定名稱的類別記錄
    /// - Parameter name: 類別名稱
    init(name: String) {
        self.name = name
    }
}

// MARK: - NameLookupRecord

extension CategoryRecord: NameLookupRecord {
    
    /// 以類別名稱比對的查詢條件
    /// - Parameter name: 要比對的類別名稱
    /// - Returns: 供 `FetchDescriptor` 使用的查詢條件
    static func matchingName(_ name: String) -> Predicate<CategoryRecord> {
        #Predicate { $0.name == name }
    }
}
