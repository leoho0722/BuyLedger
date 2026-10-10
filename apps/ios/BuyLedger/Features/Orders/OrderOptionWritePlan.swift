//
//  OrderOptionWritePlan.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import Foundation

/// 訂單表單的主檔新增請求與成功回應，保留原表單識別值和付款旗標
struct OrderOptionWritePlan: Equatable, Sendable {

    // MARK: - Properties

    /// 發起新增的表單實例識別值，與訂單編號無關
    let formID: UUID

    /// 要新增的主檔種類
    let kind: LookupKind

    /// 已去除頭尾空白的名稱
    let name: String

    /// 付款方式分類旗標，其他主檔使用 `.none`
    let flags: PaymentMethodFlags

    // MARK: - Init

    /// 建立可跨持久化效果傳遞的新增請求
    ///
    /// - Parameters:
    ///   - formID: 原表單的實例識別值
    ///   - kind: 要新增的主檔種類
    ///   - name: 尚未去除頭尾空白的名稱
    ///   - flags: 付款方式分類旗標
    init(
        formID: UUID,
        kind: LookupKind,
        name: String,
        flags: PaymentMethodFlags
    ) {
        self.formID = formID
        self.kind = kind
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.flags = flags
    }
}
