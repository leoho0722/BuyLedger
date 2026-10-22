//
//  LookupAdditionRequest.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import Foundation

/// 一次主檔新增請求，攜帶發起表單的實例識別值，回應時據此對應回原表單
struct LookupAdditionRequest: Equatable, Sendable {

    // MARK: - Properties

    /// 發起新增的表單實例識別值，與訂單編號無關
    let id: UUID

    /// 要新增的主檔種類
    let kind: LookupKind

    /// 要新增的項目，名稱已去除頭尾空白
    let addition: LookupItemAddition

    // MARK: - Init

    /// 建立主檔新增請求，名稱去除頭尾空白後與旗標組成新增項目
    ///
    /// - Parameters:
    ///   - id: 發起新增的表單實例識別值
    ///   - kind: 要新增的主檔種類
    ///   - name: 尚未去除頭尾空白的名稱
    ///   - flags: 付款方式分類旗標；其他主檔使用 `.none`
    init(
        id: UUID,
        kind: LookupKind,
        name: String,
        flags: PaymentMethodFlags
    ) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.id = id
        self.kind = kind
        self.addition = LookupItemAddition(name: trimmed, flags: flags)
    }
}
