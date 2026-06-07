//
//  PaymentMethodInfo.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation

/// 付款方式主檔的領域型別。
///
/// 將 ``PaymentMethodRecord/name``、``PaymentMethodRecord/isCardless``、``PaymentMethodRecord/isBankTransfer`` 與 ``PaymentMethodRecord/isCashOnDelivery`` 一併傳遞給 reducer / view，避免上層只拿到名稱字串卻需要另外查詢「該方式是否屬於無卡類、銀行匯款或貨到付款」。
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

    /// 是否屬於「貨到付款」類付款方式。
    ///
    /// 與 ``isCardless``、``isBankTransfer`` 平行的獨立旗標；編輯訂單時若選到 `isCashOnDelivery == true` 的付款方式，會把該訂單標記為貨到付款 (``LedgerOrder/isCashOnDelivery``)。由於貨到付款收取的金額已含預估的三種運費，``OrderSummary`` 會在獲利中額外扣除國內／國際／來源國當地國內運費。
    let isCashOnDelivery: Bool
}
