//
//  OrderDraft.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/2.
//

import ComposableArchitecture
import Foundation

/// 訂單編輯表單的草稿值型別
@ObservableState
struct OrderDraft: Equatable, Sendable {

    // MARK: - Properties

    /// 客戶名稱草稿
    var customerName: String

    /// 訂單來源草稿
    var orderSource: String

    /// 商品類別草稿；一般編輯單選，合併時可多選
    var categories: [String]

    /// 訂單狀態草稿
    var status: OrderStatus

    /// 商品幣別草稿
    var currency: CurrencyCode

    /// 客戶收款金額草稿 (新台幣)
    var chargedAmount: Decimal

    /// 無卡折抵金額；不可超過實付金額
    var cardlessDeductionAmount: Decimal

    /// 無卡補款金額草稿 (TWD)
    var cardlessSupplementAmount: Decimal

    /// 商品折合 TWD 後的成本草稿
    var itemCost: Decimal

    /// 國內運費草稿 (TWD)
    var domesticShipping: Decimal

    /// 國際運費草稿 (TWD)
    var internationalShipping: Decimal

    /// 外國國內運費草稿 (TWD)
    var foreignDomesticShipping: Decimal

    /// 刷卡手續費比例草稿 (0–1，例如 0.015 = 1.5%)
    var cardFeeRate: Decimal

    /// 平台手續費比例草稿 (0–1，例如 0.03 = 3%)
    var platformFeeRate: Decimal

    /// 金流手續費比例草稿 (0–1)
    var paymentFeeRate: Decimal

    /// 商品明細草稿；可在編輯表單內新增、刪除、修改
    var items: [LedgerOrderItem]

    /// 訂單備註草稿；對應 ``LedgerOrder/notes``，留空代表無備註
    var notes: String

    /// 訂購日期草稿
    var date: Date

    /// 付款方式草稿
    var paymentMethod: String

    /// 對帳狀態草稿；僅在無卡或銀行匯款付款方式下於 UI 顯示與編輯
    var reconciliationStatus: String

    /// 歸屬開團名稱草稿；空陣列代表未歸團 (散單)
    var campaignNames: [String]

    /// 收款狀態草稿 (待收款／已收款)
    var paymentReceiptStatus: PaymentReceiptStatus

    // MARK: - Init

    /// 依原始訂單建立草稿；`original` 為 `nil` 時各欄位採新訂單預設值
    ///
    /// - Parameters:
    ///   - original: 要編輯的訂單；`nil` 表示新訂單
    ///   - currentDate: 新訂單的預設日期
    ///   - defaultCurrency: 新訂單的預設幣別；既有訂單沿用原幣別
    init(original: LedgerOrder?, currentDate: Date, defaultCurrency: CurrencyCode = .twd) {
        self.customerName = original?.customer.name ?? ""
        self.orderSource = original?.orderSource ?? ""
        self.categories = original?.categories ?? []
        self.status = original?.status ?? .quoting
        self.currency = original?.currency ?? defaultCurrency
        self.chargedAmount = original?.chargedAmount ?? 0
        // 載入時把折抵金額限制在實付金額內
        let originalCardlessDeduction = original?.cardlessDeductionAmount ?? 0
        self.cardlessDeductionAmount = min(
            originalCardlessDeduction,
            max(0, original?.chargedAmount ?? 0)
        )
        self.cardlessSupplementAmount = original?.cardlessSupplementAmount ?? 0
        self.itemCost = original?.itemCost ?? 0
        self.domesticShipping = original?.domesticShipping ?? 0
        self.internationalShipping = original?.internationalShipping ?? 0
        self.foreignDomesticShipping = original?.foreignDomesticShipping ?? 0
        self.cardFeeRate = original?.cardFeeRate ?? 0
        self.platformFeeRate = original?.platformFeeRate ?? 0
        self.paymentFeeRate = original?.paymentFeeRate ?? 0
        self.items = original?.items ?? []
        self.notes = original?.notes ?? ""
        self.date = original?.date ?? currentDate
        self.paymentMethod = original?.paymentMethod ?? ""
        self.reconciliationStatus = original?.reconciliationStatus ?? ""
        self.campaignNames = original?.campaignNames ?? []
        self.paymentReceiptStatus = original?.paymentReceiptStatus ?? .pending
    }
}
