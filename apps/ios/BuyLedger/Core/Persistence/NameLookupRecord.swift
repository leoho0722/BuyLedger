//
//  NameLookupRecord.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/1.
//

import Foundation
import SwiftData

/// 只有名稱欄位主檔的共用協定
protocol NameLookupRecord: PersistentModel {
    
    // MARK: - Data Properties
    
    /// 主檔名稱；同時作為 upsert 識別值
    var name: String { get set }
    
    // MARK: - Init
    
    /// 以名稱建立記錄
    /// - Parameter name: 主檔名稱
    init(name: String)
    
    // MARK: - Internal Method
    
    /// 以名稱比對的查詢條件
    /// - Parameter name: 要比對的名稱
    /// - Returns: 供 `FetchDescriptor` 使用的查詢條件
    static func matchingName(_ name: String) -> Predicate<Self>
}
