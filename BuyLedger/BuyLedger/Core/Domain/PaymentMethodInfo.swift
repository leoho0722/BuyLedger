//
//  PaymentMethodInfo.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation

/// 付款方式主檔的領域型別。
///
/// 將 ``PaymentMethodRecord/name``、``PaymentMethodRecord/isCardless`` 與 ``PaymentMethodRecord/isBankTransfer`` 一併傳遞給 reducer / view，避免上層只拿到名稱字串卻需要另外查詢「該方式是否屬於無卡類或銀行匯款」。
struct PaymentMethodInfo: Equatable, Hashable, Sendable {

    // MARK: - Data Properties

    /// 付款方式名稱；同時作為主檔 upsert 識別值。
    let name: String

    /// 是否屬於「無卡」類付款方式 (例如「無卡」「無卡存款」)。
    ///
    /// 編輯訂單時若選到 `isCardless == true` 的付款方式，會啟用「無卡折抵金額」與「無卡補款金額」兩個欄位，並把這兩個值計入 ``OrderSummary/revenue``。
    let isCardless: Bool

    /// 是否屬於「銀行匯款」類付款方式。
    ///
    /// 與 ``isCardless`` 平行的獨立旗標；編輯訂單時若選到 `isCardless` 或 `isBankTransfer` 為 `true` 的付款方式，會在「付款方式」row 底下顯示「對帳狀態」row，供店主事後人工標記對帳結果。
    let isBankTransfer: Bool
}
