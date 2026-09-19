//
//  PaymentMethodFlags.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/08/23.
//

import Foundation

/// 付款方式的分類旗標集合
struct PaymentMethodFlags: Codable, Equatable, Hashable, Sendable {

    // MARK: - Properties

    /// 三個分類旗標皆關閉的預設值
    static let none = Self(
        isCardless: false,
        isBankTransfer: false,
        isCashOnDelivery: false
    )

    /// 是否屬於無卡類付款方式
    let isCardless: Bool

    /// 是否屬於銀行匯款類付款方式
    let isBankTransfer: Bool

    /// 是否屬於貨到付款類付款方式
    let isCashOnDelivery: Bool
}
