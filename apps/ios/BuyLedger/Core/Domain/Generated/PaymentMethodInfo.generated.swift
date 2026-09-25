//
//  PaymentMethodInfo.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import Foundation

/// 付款方式與無卡、銀行匯款、貨到付款三個旗標，避免只憑名稱判斷類型
struct PaymentMethodInfo: Codable, Equatable, Hashable, Sendable {

    // MARK: - Data Properties

    /// 付款方式名稱，也是主檔識別值
    let name: String

    /// 是否為無卡付款
    let isCardless: Bool

    /// 是否為銀行匯款
    let isBankTransfer: Bool

    /// 是否為貨到付款
    let isCashOnDelivery: Bool
}
