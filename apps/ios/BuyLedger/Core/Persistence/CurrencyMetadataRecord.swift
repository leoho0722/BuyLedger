//
//  CurrencyMetadataRecord.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation
import SwiftData

/// SwiftData 持久化的「ExchangeRate-API 支援幣別」單筆紀錄
@Model
final class CurrencyMetadataRecord {
    
    // MARK: - Data Properties
    
    /// 以幣別代碼建立索引，供查詢與更新
    #Index<CurrencyMetadataRecord>([\.code])
    
    /// ISO 4217 幣別代碼，例如 `"TWD"`、`"USD"`
    var code: String
    
    /// 該筆 cache 的寫入時間
    var lastUpdated: Date
    
    // MARK: - Init
    
    /// 建立指定 code 與更新時間的紀錄
    /// - Parameters:
    ///   - code: ISO 4217 三位代碼
    ///   - lastUpdated: 寫入時間
    init(code: String, lastUpdated: Date) {
        self.code = code
        self.lastUpdated = lastUpdated
    }
}
