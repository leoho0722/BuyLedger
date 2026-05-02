//
//  OrderRecord.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import Foundation
import SwiftData

/// SwiftData 持久化用的訂單記錄。
///
/// 與領域型別 ``LedgerOrder`` 一一對應，但採 `@Model class` 形式以滿足 SwiftData 要求；同名欄位之間透過 ``OrderPersistence`` 進行雙向 mapping。
///
/// 設計重點（為了未來無痛打開 CloudKit 同步）：
/// - 不使用 `@Attribute(.unique)`，因為 CloudKit 不支援 unique constraint；改用「id 為平凡 String，由 actor 進行 upsert 檢查」
/// - 嵌入式型別（``LedgerCustomer`` / `[LedgerOrderItem]`）透過 Codable 以 transformable 形式儲存，避免引入 optional relationship 對 CloudKit 同步的限制
@Model
final class OrderRecord {

    // MARK: - Data Properties

    /// 訂單編號（領域層級的 stable id）。
    var id: String

    /// 客戶資料（嵌入式 Codable 儲存）。
    var customer: LedgerCustomer

    /// 訂單目前狀態。
    var status: OrderStatus

    /// 商品原始幣別。
    var currency: CurrencyCode

    /// 訂單建立或更新日期。
    var date: Date

    /// 商品項目（嵌入式 Codable 陣列儲存）。
    var items: [LedgerOrderItem]

    /// 商品折合 TWD 後的成本。
    var itemCost: Decimal

    /// 國內運費成本。
    var domesticShipping: Decimal

    /// 國際集運成本。
    var internationalShipping: Decimal

    /// 刷卡手續費比例。
    var cardFeeRate: Decimal

    /// 平台手續費比例。
    var platformFeeRate: Decimal

    /// 實際向客戶收款的新台幣金額。
    var chargedAmount: Decimal

    /// 商品類別。
    var category: String

    // MARK: - Init

    /// 依領域型別 ``LedgerOrder`` 建立持久化記錄。
    /// - Parameter order: 對應的領域訂單。
    init(order: LedgerOrder) {
        self.id = order.id
        self.customer = order.customer
        self.status = order.status
        self.currency = order.currency
        self.date = order.date
        self.items = order.items
        self.itemCost = order.itemCost
        self.domesticShipping = order.domesticShipping
        self.internationalShipping = order.internationalShipping
        self.cardFeeRate = order.cardFeeRate
        self.platformFeeRate = order.platformFeeRate
        self.chargedAmount = order.chargedAmount
        self.category = order.category
    }
}

// MARK: - View Method

extension OrderRecord {

    // MARK: - Mapping

    /// 將 SwiftData 記錄轉回領域型別。
    /// - Returns: 對應的 ``LedgerOrder``。
    func toDomain() -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: customer,
            status: status,
            currency: currency,
            date: date,
            items: items,
            itemCost: itemCost,
            domesticShipping: domesticShipping,
            internationalShipping: internationalShipping,
            cardFeeRate: cardFeeRate,
            platformFeeRate: platformFeeRate,
            chargedAmount: chargedAmount,
            category: category
        )
    }

    /// 將領域型別的內容套用到本記錄（用於 upsert 流程的更新分支）。
    /// - Parameter order: 來源 ``LedgerOrder``。
    func apply(_ order: LedgerOrder) {
        self.customer = order.customer
        self.status = order.status
        self.currency = order.currency
        self.date = order.date
        self.items = order.items
        self.itemCost = order.itemCost
        self.domesticShipping = order.domesticShipping
        self.internationalShipping = order.internationalShipping
        self.cardFeeRate = order.cardFeeRate
        self.platformFeeRate = order.platformFeeRate
        self.chargedAmount = order.chargedAmount
        self.category = order.category
    }
}
