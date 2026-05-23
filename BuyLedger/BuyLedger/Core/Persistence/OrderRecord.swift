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
/// 設計重點（保留與 CloudKit 同步相容的限制，便於日後直接打開）：
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

    /// 商品原始幣別（以 ISO 4217 code 字串存放）。
    ///
    /// 之所以使用 `String` 而非 ``CurrencyCode``：``CurrencyCode`` 從 `enum String` 改成 `struct` 後，SwiftData 會把它視為複合型別、把 `rawValue` 展開成子 attribute，造成舊 store（直接 String column）升級時找不到對應的 destination 屬性而 migration 失敗。直接存 String 可維持 column 形狀與舊 enum 的 `rawValue` 相同，免去自訂 migration plan。
    var currency: String

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

    /// 商品來源國當地的國內運費成本（TWD）；帶 default 0 走 SwiftData lightweight migration。
    var foreignDomesticShipping: Decimal = 0

    /// 刷卡手續費比例。
    var cardFeeRate: Decimal

    /// 平台手續費比例。
    var platformFeeRate: Decimal

    /// 金流手續費比例；帶 default 0 走 SwiftData lightweight migration。
    var paymentFeeRate: Decimal = 0

    /// 實際向客戶收款的新台幣金額。
    var chargedAmount: Decimal

    /// 商品類別。
    var category: String

    /// 付款方式。
    ///
    /// 帶 default value 讓 SwiftData 對既有資料庫做 lightweight migration：舊 row 升級時自動填空字串，不需要寫顯式 migration plan。
    var paymentMethod: String = ""

    // MARK: - Init

    /// 依領域型別 ``LedgerOrder`` 建立持久化記錄。
    /// - Parameter order: 對應的領域訂單。
    init(order: LedgerOrder) {
        self.id = order.id
        self.customer = order.customer
        self.status = order.status
        self.currency = order.currency.rawValue
        self.date = order.date
        self.items = order.items
        self.itemCost = order.itemCost
        self.domesticShipping = order.domesticShipping
        self.internationalShipping = order.internationalShipping
        self.foreignDomesticShipping = order.foreignDomesticShipping
        self.cardFeeRate = order.cardFeeRate
        self.platformFeeRate = order.platformFeeRate
        self.paymentFeeRate = order.paymentFeeRate
        self.chargedAmount = order.chargedAmount
        self.category = order.category
        self.paymentMethod = order.paymentMethod
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
            currency: CurrencyCode(rawValue: currency),
            date: date,
            items: items,
            itemCost: itemCost,
            domesticShipping: domesticShipping,
            internationalShipping: internationalShipping,
            foreignDomesticShipping: foreignDomesticShipping,
            cardFeeRate: cardFeeRate,
            platformFeeRate: platformFeeRate,
            paymentFeeRate: paymentFeeRate,
            chargedAmount: chargedAmount,
            category: category,
            paymentMethod: paymentMethod
        )
    }

    /// 將領域型別的內容套用到本記錄（用於 upsert 流程的更新分支）。
    /// - Parameter order: 來源 ``LedgerOrder``。
    func apply(_ order: LedgerOrder) {
        self.customer = order.customer
        self.status = order.status
        self.currency = order.currency.rawValue
        self.date = order.date
        self.items = order.items
        self.itemCost = order.itemCost
        self.domesticShipping = order.domesticShipping
        self.internationalShipping = order.internationalShipping
        self.foreignDomesticShipping = order.foreignDomesticShipping
        self.cardFeeRate = order.cardFeeRate
        self.platformFeeRate = order.platformFeeRate
        self.paymentFeeRate = order.paymentFeeRate
        self.chargedAmount = order.chargedAmount
        self.category = order.category
        self.paymentMethod = order.paymentMethod
    }
}
