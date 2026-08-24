//
//  PaymentMethodInfo.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/23.
//

import Foundation

// MARK: - Init

extension PaymentMethodInfo {

    /// 以名稱與分類旗標建立付款方式資訊
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

// MARK: - Internal Method

extension PaymentMethodInfo {

    /// 取得付款方式目前的分類旗標
    /// - Returns: 付款方式目前的分類旗標
    var currentFlags: PaymentMethodFlags {
        PaymentMethodFlags(
            isCardless: isCardless,
            isBankTransfer: isBankTransfer,
            isCashOnDelivery: isCashOnDelivery
        )
    }
}
