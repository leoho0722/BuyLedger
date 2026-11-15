//
//  PaymentMethodInfo.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/23.
//

import Foundation

/// 付款方式與無卡、銀行匯款、貨到付款三個旗標，避免只憑名稱判斷類型
struct PaymentMethodInfo: Codable, Equatable, Hashable, Sendable {

    // MARK: - Properties

    /// 付款方式名稱，也是主檔識別值
    let name: String

    /// 是否為無卡付款
    let isCardless: Bool

    /// 是否為銀行匯款
    let isBankTransfer: Bool

    /// 是否為貨到付款
    let isCashOnDelivery: Bool

    // MARK: - Init

    /// 以名稱與三個旗標建立付款方式資訊
    ///
    /// - Parameters:
    ///   - name: 付款方式名稱
    ///   - isCardless: 是否為無卡付款
    ///   - isBankTransfer: 是否為銀行匯款
    ///   - isCashOnDelivery: 是否為貨到付款
    init(
        name: String,
        isCardless: Bool,
        isBankTransfer: Bool,
        isCashOnDelivery: Bool
    ) {
        self.name = name
        self.isCardless = isCardless
        self.isBankTransfer = isBankTransfer
        self.isCashOnDelivery = isCashOnDelivery
    }

    /// 以名稱與分類旗標建立付款方式資訊
    ///
    /// - Parameters:
    ///   - name: 付款方式名稱
    ///   - flags: 付款方式分類旗標
    init(name: String, flags: PaymentMethodFlags) {
        self.init(
            name: name,
            isCardless: flags.isCardless,
            isBankTransfer: flags.isBankTransfer,
            isCashOnDelivery: flags.isCashOnDelivery
        )
    }
}

// MARK: - Computed Properties

extension PaymentMethodInfo {

    /// 付款方式目前的分類旗標
    var currentFlags: PaymentMethodFlags {
        PaymentMethodFlags(
            isCardless: isCardless,
            isBankTransfer: isBankTransfer,
            isCashOnDelivery: isCashOnDelivery
        )
    }
}
