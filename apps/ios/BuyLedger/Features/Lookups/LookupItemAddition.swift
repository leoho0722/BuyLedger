//
//  LookupItemAddition.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/24.
//

import Foundation

/// 一次新增主檔項目的名稱與付款方式旗標
struct LookupItemAddition: Equatable, Sendable {

    // MARK: - Properties

    /// 去除前後空白後的新主檔名稱
    let name: String

    /// 新付款方式的分類旗標；名稱型主檔一律為 `.none`
    let flags: PaymentMethodFlags
}
