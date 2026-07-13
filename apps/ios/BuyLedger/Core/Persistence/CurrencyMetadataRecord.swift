//
//  CurrencyMetadataRecord.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation
import SwiftData

/// SwiftData 持久化的「ExchangeRate-API 支援幣別」單筆紀錄
///
/// 用來 cache ``ExchangeRateClient/fetchSupportedCodes`` 的結果，避免每次開 App 都打 `/codes` (ExchangeRate-API 免費方案有每月配額)
///
/// - 只存 ISO 4217 code，name 在 view 端透過 `Locale.localizedString(forCurrencyCode:)` 動態取得
/// - ``lastUpdated`` 同時記錄該筆的更新時間；以「最新一次更新」推算 TTL 是否過期
@Model
final class CurrencyMetadataRecord {

    // MARK: - Data Properties

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
