//
//  LedgerOrder.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`
//

import Foundation

/// 訂單資料
struct LedgerOrder: Codable, Equatable, Identifiable, Sendable {

    // MARK: - Data Properties

    /// 訂單編號
    let id: String

    /// 客戶資料
    let customer: LedgerCustomer

    /// 訂單目前狀態
    let status: OrderStatus

    /// 商品幣別
    let currency: CurrencyCode

    /// 訂單日期
    let date: Date

    /// 商品項目
    let items: [LedgerOrderItem]

    /// 商品成本 (TWD)
    let itemCost: Decimal

    /// 國內運費成本 (TWD)
    let domesticShipping: Decimal

    /// 國際運費成本 (TWD)
    let internationalShipping: Decimal

    /// 商品來源國的國內運費成本 (TWD)
    let foreignDomesticShipping: Decimal

    /// 刷卡手續費比例
    let cardFeeRate: Decimal

    /// 平台手續費比例
    let platformFeeRate: Decimal

    /// 金流手續費比例
    let paymentFeeRate: Decimal

    /// 向客戶收取的金額 (TWD)
    let chargedAmount: Decimal

    /// 無卡付款的折抵金額 (TWD)
    let cardlessDeductionAmount: Decimal

    /// 無卡付款的補款金額 (TWD)
    let cardlessSupplementAmount: Decimal

    /// 訂單來源
    let orderSource: String

    /// 商品類別
    let categories: [String]

    /// 付款方式
    let paymentMethod: String

    /// 訂單備註；沒有備註時為空字串
    let notes: String

    /// 對帳狀態；不需對帳時為空字串
    let reconciliationStatus: String

    /// 所屬開團名稱；空陣列表示散單
    let campaignNames: [String]

    /// 收款狀態
    let paymentReceiptStatus: PaymentReceiptStatus

    /// 是否為貨到付款
    let isCashOnDelivery: Bool

    /// 訂單照片；沒有照片時為空陣列
    let photos: [Data]

    /// 合併前的訂單編號；非合併訂單為空陣列
    let mergedSourceIDs: [String]
}
