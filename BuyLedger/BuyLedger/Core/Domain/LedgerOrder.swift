//
//  LedgerOrder.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// BuyLedger 中用於列表、詳情與彙總的訂單資料。
struct LedgerOrder: Codable, Equatable, Identifiable, Sendable {

    // MARK: - Data Properties

    /// 訂單編號。
    let id: String

    /// 訂單客戶。
    let customer: LedgerCustomer

    /// 訂單目前狀態。
    let status: OrderStatus

    /// 商品原始幣別。
    let currency: CurrencyCode

    /// 訂單建立或更新日期。
    let date: Date

    /// 訂單商品項目。
    let items: [LedgerOrderItem]

    /// 商品折合新台幣後的成本。
    let itemCost: Decimal

    /// 國內運費成本。
    let domesticShipping: Decimal

    /// 國際運費成本。
    let internationalShipping: Decimal

    /// 商品來源國當地的「國內運費」成本 (折合 TWD)。例如賣家把商品從日本國內出貨到集運倉的運送費。
    let foreignDomesticShipping: Decimal

    /// 刷卡手續費比例。
    let cardFeeRate: Decimal

    /// 平台手續費比例。
    let platformFeeRate: Decimal

    /// 金流手續費比例 (0–1，例如 0.005 = 0.5%)；用於 LINE Pay、街口、信用卡之外的第三方金流抽成。
    let paymentFeeRate: Decimal

    /// 實際向客戶收款的新台幣金額。
    let chargedAmount: Decimal

    /// 無卡折抵金額 (TWD)。
    ///
    /// 用於「無卡」類付款方式紀錄客戶以儲值金、購物金等方式折抵的金額；折抵會從 ``OrderSummary/revenue`` 中扣除。非無卡訂單一律以 `0` 帶入。
    let cardlessDeductionAmount: Decimal

    /// 無卡補款金額 (TWD)。
    ///
    /// 用於「無卡」類付款方式紀錄客戶以 ATM 轉帳等方式補繳的金額；補款會加到 ``OrderSummary/revenue`` 中。非無卡訂單一律以 `0` 帶入。
    let cardlessSupplementAmount: Decimal

    /// 訂單來源。
    let orderSource: String

    /// 商品類別。
    let category: String

    /// 付款方式。
    let paymentMethod: String

    /// 訂單備註；選填，無備註時為空字串。
    let notes: String

    /// 對帳狀態。
    ///
    /// 僅在 ``paymentMethod`` 屬於無卡或銀行匯款 (款項不會即時入帳、需事後人工對帳) 時有意義；其他付款方式一律以空字串帶入。對應可自訂主檔 ``LookupKind/verificationStatus``。
    let verificationStatus: String

    /// 歸屬的開團名稱。
    ///
    /// 沿用 ``orderSource`` 的字串名稱引用模式；空字串代表未歸屬任何開團 (散單)。開團改名時由 ``RootFeature`` 統一 cascade 更新所有相符訂單。
    let campaignName: String

    /// 收款狀態 (待收款／已收款)。
    ///
    /// 作為開團分貨清單與結團結算判定「已收款」的唯一來源；對所有付款方式皆有意義，預設為 ``PaymentReceiptStatus/pending``。
    let paymentReceiptStatus: PaymentReceiptStatus

    /// 此訂單是否以「貨到付款」類付款方式成立。
    ///
    /// 於儲存時依選到的付款方式 ``PaymentMethodInfo/isCashOnDelivery`` 快照寫入 (與無卡欄位同樣為 data-driven，``OrderSummary`` 只拿得到本型別、看不到付款方式主檔旗標)。為 `true` 時，因收款金額已含預估的三種運費，``OrderSummary`` 會在獲利中額外扣除 ``domesticShipping`` + ``internationalShipping`` + ``foreignDomesticShipping``；非貨到付款一律為 `false`，等同維持舊行為。
    let isCashOnDelivery: Bool

    // MARK: - Computed Properties

    /// 訂單的財務摘要。
    var summary: OrderSummary {
        OrderSummary(order: self)
    }

    /// 列表中顯示的商品摘要，每項商品各自一行，名稱後接購買數量 (例如「藍牙耳機 x2」)。
    var itemSummary: String {
        guard !items.isEmpty else {
            return "未命名商品"
        }

        return items.map { "\($0.name) x\($0.quantity)" }.joined(separator: "\n")
    }
}
