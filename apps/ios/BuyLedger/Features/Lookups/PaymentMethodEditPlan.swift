//
//  PaymentMethodEditPlan.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/24.
//

import Foundation

/// 付款方式編輯操作使用的固定資料快照
struct PaymentMethodEditPlan: Equatable, Sendable {

    // MARK: - Properties

    /// 原付款方式名稱
    let originalName: String

    /// 新付款方式名稱
    let newName: String

    /// 使用者確認後要寫入的分類旗標
    let flags: PaymentMethodFlags

    /// 旗標是否變更；只改名時不需確認
    let hasChangedFlags: Bool

    /// 已改名並依共用規則正規化的受影響訂單
    let affectedOrders: [LedgerOrder]
}
