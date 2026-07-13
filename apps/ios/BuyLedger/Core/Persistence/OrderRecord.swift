//
//  OrderRecord.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/2.
//

import Foundation
import SwiftData

/// SwiftData 持久化用的訂單記錄
///
/// 與領域型別 ``LedgerOrder`` 一一對應，但採 `@Model class` 形式以滿足 SwiftData 要求；同名欄位之間透過 ``OrderPersistence`` 進行雙向 mapping
///
/// 設計重點 (保留與 CloudKit 同步相容的限制，便於日後直接打開)：
/// - 不使用 `@Attribute(.unique)`，因為 CloudKit 不支援 unique constraint；改用「id 為平凡 String，由 actor 進行 upsert 檢查」
/// - 嵌入式型別 (``LedgerCustomer`` / `[LedgerOrderItem]`) 透過 Codable 以 transformable 形式儲存，避免引入 optional relationship 對 CloudKit 同步的限制
@Model
final class OrderRecord {

    // MARK: - Data Properties

    /// 訂單編號 (領域層級的 stable id)
    var id: String

    /// 客戶資料 (嵌入式 Codable 儲存)
    var customer: LedgerCustomer

    /// 訂單目前狀態
    var status: OrderStatus

    /// 商品原始幣別 (以 ISO 4217 code 字串存放)
    ///
    /// 之所以使用 `String` 而非 ``CurrencyCode``：``CurrencyCode`` 從 `enum String` 改成 `struct` 後，SwiftData 會把它視為複合型別、把 `rawValue` 展開成子 attribute，造成舊 store (直接 String column) 升級時找不到對應的 destination 屬性而 migration 失敗
    ///
    /// 直接存 String 可維持 column 形狀與舊 enum 的 `rawValue` 相同，免去自訂 migration plan
    var currency: String

    /// 訂單建立或更新日期
    var date: Date

    /// 商品項目 (嵌入式 Codable 陣列儲存)
    var items: [LedgerOrderItem]

    /// 商品折合 TWD 後的成本
    var itemCost: Decimal

    /// 國內運費成本
    var domesticShipping: Decimal

    /// 國際運費成本
    var internationalShipping: Decimal

    /// 商品來源國當地的國內運費成本 (TWD)；帶 default 0 走 SwiftData lightweight migration
    var foreignDomesticShipping: Decimal = 0

    /// 刷卡手續費比例
    var cardFeeRate: Decimal

    /// 平台手續費比例
    var platformFeeRate: Decimal

    /// 金流手續費比例；帶 default 0 走 SwiftData lightweight migration
    var paymentFeeRate: Decimal = 0

    /// 實際向客戶收款的新台幣金額
    var chargedAmount: Decimal

    /// 無卡折抵金額 (TWD)；用於「無卡」類付款方式紀錄客戶使用儲值金、購物金等折抵的金額
    ///
    /// 帶 default `0` 走 SwiftData lightweight migration；只有當 ``paymentMethod`` 對應的 ``PaymentMethodRecord/isCardless`` 為 `true` 時，編輯表單才會顯示並寫入此值
    var cardlessDeductionAmount: Decimal = 0

    /// 無卡補款金額 (TWD)；用於「無卡」類付款方式紀錄客戶以 ATM 轉帳等方式補繳的金額
    ///
    /// 帶 default `0` 走 SwiftData lightweight migration；行為與 ``cardlessDeductionAmount`` 相同，只在無卡類付款方式才會被使用者編輯
    var cardlessSupplementAmount: Decimal = 0

    /// 訂單來源
    ///
    /// 帶 default value 讓 SwiftData 對既有資料庫做 lightweight migration：舊 row 升級時自動填空字串，不需要寫顯式 migration plan
    var orderSource: String = ""

    /// 商品類別清單 (V11 起為字串陣列；至少一個，由編輯流程守門)
    var categories: [String] = []

    /// 付款方式
    ///
    /// 帶 default value 讓 SwiftData 對既有資料庫做 lightweight migration：舊 row 升級時自動填空字串，不需要寫顯式 migration plan
    var paymentMethod: String = ""

    /// 訂單備註
    ///
    /// 帶 default value 讓 SwiftData 對既有資料庫做 lightweight migration：舊 row 升級時自動填空字串，不需要寫顯式 migration plan
    var notes: String = ""

    /// 對帳狀態
    ///
    /// 帶 default value 讓 SwiftData 對既有資料庫做 lightweight migration：舊 row 升級時自動填空字串
    ///
    /// 僅在 ``paymentMethod`` 對應的付款方式屬於無卡或銀行匯款時，編輯表單才會顯示並寫入此值
    var verificationStatus: String = ""

    /// 歸屬的開團名稱清單 (V11 起為字串陣列；空陣列代表未歸團)
    var campaignNames: [String] = []

    /// 收款狀態的 rawValue (待收款／已收款)
    ///
    /// 比照 ``currency`` 以 String 儲存 (而非 enum)，避免日後改動 enum 破壞 schema 指紋；帶 default value 走 lightweight migration，舊 row 升級時自動填 ``PaymentReceiptStatus/pending``
    var paymentReceiptStatus: String = PaymentReceiptStatus.pending.rawValue

    /// 此訂單是否以「貨到付款」類付款方式成立
    ///
    /// 帶 default `false` 走 SwiftData lightweight migration；只有當 ``paymentMethod`` 對應的 ``PaymentMethodRecord/isCashOnDelivery`` 為 `true` 時，儲存表單才會寫入 `true`
    ///
    /// 為 `true` 時 ``OrderSummary`` 會在獲利中額外扣除三種運費
    var isCashOnDelivery: Bool = false

    /// 訂單照片 (已正規化的 JPEG data，嵌入式 Codable 陣列儲存)
    ///
    /// 帶 default 空陣列走 SwiftData lightweight migration：舊 row 升級時自動填空陣列
    ///
    /// 張數上限由 ``LedgerOrder/maxPhotoCount`` 於編輯流程守門，持久層不重複驗證
    var photos: [Data] = []

    /// 合併來源訂單編號 (V11 新增)
    ///
    /// 由「合併訂單」產生的新訂單記錄兩筆來源訂單 id；非合併產生的訂單一律為空陣列
    var mergedSourceIDs: [String] = []

    // MARK: - Init

    /// 依領域型別 ``LedgerOrder`` 建立持久化記錄
    /// - Parameter order: 對應的領域訂單
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
        self.cardlessDeductionAmount = order.cardlessDeductionAmount
        self.cardlessSupplementAmount = order.cardlessSupplementAmount
        self.orderSource = order.orderSource
        self.categories = order.categories
        self.paymentMethod = order.paymentMethod
        self.notes = order.notes
        self.verificationStatus = order.verificationStatus
        self.campaignNames = order.campaignNames
        self.paymentReceiptStatus = order.paymentReceiptStatus.rawValue
        self.isCashOnDelivery = order.isCashOnDelivery
        self.photos = order.photos
        self.mergedSourceIDs = order.mergedSourceIDs
    }
}

// MARK: - Internal Method

extension OrderRecord {

    // MARK: Mapping

    /// 將 SwiftData 記錄轉回領域型別
    /// - Returns: 對應的 ``LedgerOrder``
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
            cardlessDeductionAmount: cardlessDeductionAmount,
            cardlessSupplementAmount: cardlessSupplementAmount,
            orderSource: orderSource,
            categories: categories,
            paymentMethod: paymentMethod,
            notes: notes,
            verificationStatus: verificationStatus,
            campaignNames: campaignNames,
            paymentReceiptStatus: PaymentReceiptStatus(rawValue: paymentReceiptStatus) ?? .pending,
            isCashOnDelivery: isCashOnDelivery,
            photos: photos,
            mergedSourceIDs: mergedSourceIDs
        )
    }

    /// 將領域型別的內容套用到本記錄 (用於 upsert 流程的更新分支)
    /// - Parameter order: 來源 ``LedgerOrder``
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
        self.cardlessDeductionAmount = order.cardlessDeductionAmount
        self.cardlessSupplementAmount = order.cardlessSupplementAmount
        self.orderSource = order.orderSource
        self.categories = order.categories
        self.paymentMethod = order.paymentMethod
        self.notes = order.notes
        self.verificationStatus = order.verificationStatus
        self.campaignNames = order.campaignNames
        self.paymentReceiptStatus = order.paymentReceiptStatus.rawValue
        self.isCashOnDelivery = order.isCashOnDelivery
        self.photos = order.photos
        self.mergedSourceIDs = order.mergedSourceIDs
    }
}
