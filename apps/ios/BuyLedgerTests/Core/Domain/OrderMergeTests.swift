//
//  OrderMergeTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/6/6.
//

import Foundation
import Testing

@testable import BuyLedger

/// `OrderMerge` 的單元測試，涵蓋草稿金額、費率、備註、付款方式與品項的合併規則
struct OrderMergeTests {

    // MARK: - Properties

    /// 固定的合併當下時間
    private static let mergeDate = Date(timeIntervalSince1970: 1_777_000_000)

    /// 驗證主副金額欄位合併時各自加總
    @Test
    func makeDraft_主副金額欄位_各項加總() {
        // Given
        let primary = Self.makeOrder(
            id: "P",
            chargedAmount: 1_000,
            itemCost: 600,
            domesticShipping: 60,
            internationalShipping: 100,
            foreignDomesticShipping: 30,
            cardlessDeductionAmount: 50,
            cardlessSupplementAmount: 20
        )
        let secondary = Self.makeOrder(
            id: "S",
            chargedAmount: 2_000,
            itemCost: 900,
            domesticShipping: 80,
            internationalShipping: 200,
            foreignDomesticShipping: 40,
            cardlessDeductionAmount: 10,
            cardlessSupplementAmount: 5
        )

        // When
        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Self.mergeDate
        ) { _ in false }

        // Then
        #expect(draft.chargedAmount == 3_000)
        #expect(draft.itemCost == 1_500)
        #expect(draft.domesticShipping == 140)
        #expect(draft.internationalShipping == 300)
        #expect(draft.foreignDomesticShipping == 70)
        #expect(draft.cardlessDeductionAmount == 60)
        #expect(draft.cardlessSupplementAmount == 25)
    }

    /// 驗證主訂單實付 1,000、費率 1.5%，副訂單實付 3,000、費率 2% 時，合併的刷卡費率依兩筆實付金額加權平均
    @Test
    func makeDraft_主副刷卡費率_依實付金額加權平均() {
        // Given
        // 使用可精確表示的加權結果，避免循環小數造成精度差異
        let primary = Self.makeOrder(
            id: "P",
            chargedAmount: 1_000,
            cardFeeRate: Self.decimal("0.015")
        )
        let secondary = Self.makeOrder(
            id: "S",
            chargedAmount: 3_000,
            cardFeeRate: Self.decimal("0.02")
        )
        let expected = Self.decimal("0.01875")

        // When
        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Self.mergeDate
        ) { _ in false }

        // Then
        #expect(draft.cardFeeRate == expected)
    }

    /// 驗證副訂單實付為零時，其 3% 刷卡費率不影響合併結果，仍沿用主訂單的 1.5%
    @Test
    func makeDraft_副訂單實付為零_費率沿用主訂單() {
        // Given
        let primary = Self.makeOrder(
            id: "P",
            chargedAmount: 1_000,
            cardFeeRate: Self.decimal("0.015")
        )
        let secondary = Self.makeOrder(id: "S", chargedAmount: 0, cardFeeRate: Self.decimal("0.03"))

        // When
        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Self.mergeDate
        ) { _ in false }

        // Then
        #expect(draft.cardFeeRate == Self.decimal("0.015"))
    }

    /// 驗證主副實付皆為零時，費率沿用主訂單比例且不產生非數值
    @Test
    func makeDraft_主副實付皆為零_費率沿用主訂單() {
        // Given
        // 兩筆實付皆為 0 時分母為 0，沿用主訂單比例、不得產生 NaN
        let primary = Self.makeOrder(
            id: "P",
            chargedAmount: 0,
            cardFeeRate: Self.decimal("0.015"),
            platformFeeRate: Self.decimal("0.03"),
            paymentFeeRate: Self.decimal("0.005")
        )
        let secondary = Self.makeOrder(id: "S", chargedAmount: 0, cardFeeRate: Self.decimal("0.03"))

        // When
        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Self.mergeDate
        ) { _ in false }

        // Then
        #expect(draft.cardFeeRate == Self.decimal("0.015"))
        #expect(draft.platformFeeRate == Self.decimal("0.03"))
        #expect(draft.paymentFeeRate == Self.decimal("0.005"))
    }

    /// 驗證商品類別與開團名稱依主訂單在前的順序取聯集
    @Test
    func makeDraft_主副商品類別與開團_依序取聯集() {
        // Given
        let primary = Self.makeOrder(id: "P", categories: ["beauty"], campaignNames: ["May-JP"])
        let secondary = Self.makeOrder(
            id: "S",
            categories: ["snacks", "beauty"],
            campaignNames: ["June-KR"]
        )

        // When
        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Self.mergeDate
        ) { _ in false }

        // Then
        #expect(draft.categories == ["beauty", "snacks"])
        #expect(draft.campaignNames == ["May-JP", "June-KR"])
    }

    /// 驗證主副訂單備註依規則合併：兩邊都有備註時以分隔線串接，只有一邊有備註時沿用該邊
    ///
    /// - Parameter scenario: 主訂單與副訂單的備註，以及預期的合併結果
    @Test(arguments: [
        NotesCase(primaryNotes: "急件", secondaryNotes: "含贈品", expected: "急件\n----------\n含贈品"),
        NotesCase(primaryNotes: "急件", secondaryNotes: "", expected: "急件"),
        NotesCase(primaryNotes: "", secondaryNotes: "含贈品", expected: "含贈品"),
        NotesCase(primaryNotes: "", secondaryNotes: "", expected: ""),
    ])
    func makeDraft_主副備註組合_依規則合併(scenario: NotesCase) {
        // Given
        let primary = Self.makeOrder(id: "P", notes: scenario.primaryNotes)
        let secondary = Self.makeOrder(id: "S", notes: scenario.secondaryNotes)

        // When
        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Self.mergeDate
        ) { _ in false }

        // Then
        #expect(draft.notes == scenario.expected)
    }

    /// 驗證主訂單為信用卡、副訂單為無卡付款的全家好開店時，付款方式、對帳狀態與貨到付款旗標都取副訂單
    @Test
    func makeDraft_僅副訂單為無卡_付款資訊取副訂單() {
        // Given
        let primary = Self.makeOrder(
            id: "P",
            paymentMethod: "信用卡",
            reconciliationStatus: "",
            isCashOnDelivery: false
        )
        let secondary = Self.makeOrder(
            id: "S",
            paymentMethod: "全家好開店",
            reconciliationStatus: "待對帳",
            isCashOnDelivery: true
        )

        // When
        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Self.mergeDate
        ) { $0 == "全家好開店" }

        // Then
        #expect(draft.paymentMethod == "全家好開店")
        #expect(draft.reconciliationStatus == "待對帳")
        #expect(draft.isCashOnDelivery == true)
    }

    /// 驗證兩筆訂單都使用信用卡時，合併付款方式仍為信用卡，對帳狀態取主訂單的「主對帳」
    @Test
    func makeDraft_付款方式相同_取該值且對帳狀態隨主訂單() {
        // Given
        let primary = Self.makeOrder(id: "P", paymentMethod: "信用卡", reconciliationStatus: "主對帳")
        let secondary = Self.makeOrder(id: "S", paymentMethod: "信用卡", reconciliationStatus: "副對帳")

        // When
        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Self.mergeDate
        ) { _ in false }

        // Then
        #expect(draft.paymentMethod == "信用卡")
        #expect(draft.reconciliationStatus == "主對帳")
    }

    /// 驗證信用卡與銀行轉帳都判定為非無卡付款時，合併付款方式保留主訂單的信用卡
    @Test
    func makeDraft_付款方式不同且皆非無卡_取主訂單付款方式() {
        // Given
        let primary = Self.makeOrder(id: "P", paymentMethod: "信用卡")
        let secondary = Self.makeOrder(id: "S", paymentMethod: "銀行轉帳")

        // When
        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Self.mergeDate
        ) { _ in false }

        // Then
        #expect(draft.paymentMethod == "信用卡")
    }

    /// 驗證主副訂單皆為無卡且付款方式不同時，仍保留主訂單的全家好開店付款方式
    @Test
    func makeDraft_兩筆皆無卡且不同_仍取主訂單付款方式() {
        // Given
        let primary = Self.makeOrder(id: "P", paymentMethod: "全家好開店")
        let secondary = Self.makeOrder(id: "S", paymentMethod: "7-11 賣貨便")

        // When
        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Self.mergeDate
        ) { _ in true }

        // Then
        #expect(draft.paymentMethod == "全家好開店")
    }

    /// 驗證合併結果沿用主訂單的客戶、來源、幣別與狀態，日期為合併當下時間
    @Test
    func makeDraft_沿用主訂單欄位_日期為合併當下() {
        // Given
        let primary = Self.makeOrder(id: "P", status: .shipping, paymentReceiptStatus: .received)
        let secondary = Self.makeOrder(
            id: "S",
            status: .purchased,
            paymentReceiptStatus: .pending,
            customerName: "另一位客戶",
            orderSource: "Instagram",
            currency: .twd
        )

        // When
        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Self.mergeDate
        ) { _ in false }

        // Then
        #expect(draft.customer == primary.customer)
        #expect(draft.orderSource == primary.orderSource)
        #expect(draft.status == .shipping)
        #expect(draft.currency == primary.currency)
        #expect(draft.paymentReceiptStatus == .received)
        #expect(draft.date == Self.mergeDate)
        #expect(draft.mergeSourceIDs == ["P", "S"])
    }

    /// 驗證品項與照片依主訂單在前的順序串接
    @Test
    func makeDraft_品項與照片_主訂單在前串接() {
        // Given
        let photoP = Data([0x01])
        let photoS1 = Data([0x02])
        let photoS2 = Data([0x03])
        let primary = Self.makeOrder(
            id: "P",
            items: [LedgerOrderItem(name: "主商品", quantity: 1, unitPrice: 100)],
            photos: [photoP]
        )
        let secondary = Self.makeOrder(
            id: "S",
            items: [LedgerOrderItem(name: "副商品", quantity: 2, unitPrice: 200)],
            photos: [photoS1, photoS2]
        )

        // When
        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Self.mergeDate
        ) { _ in false }

        // Then
        #expect(draft.items.map(\.name) == ["主商品", "副商品"])
        #expect(draft.photos == [photoP, photoS1, photoS2])
    }
}

// MARK: - Nested Types

extension OrderMergeTests {

    /// 備註合併的測試案例：主副訂單備註與預期的合併結果
    struct NotesCase: Sendable {

        /// 主訂單的備註
        let primaryNotes: String

        /// 副訂單的備註
        let secondaryNotes: String

        /// 預期合併後的備註
        let expected: String
    }
}

// MARK: - Private Method

private extension OrderMergeTests {

    /// 以固定字串建立 `Decimal`，避免浮點誤差
    ///
    /// - Parameter value: 要轉換的十進位字串
    /// - Returns: 解析後的 `Decimal`；無法解析時為 `0`
    static func decimal(_ value: String) -> Decimal {
        Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }

    /// 建立測試訂單；未指定的欄位使用中性預設值
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - status: 訂單狀態
    ///   - chargedAmount: 客戶實付金額
    ///   - itemCost: 商品成本
    ///   - domesticShipping: 國內運費
    ///   - internationalShipping: 國際運費
    ///   - foreignDomesticShipping: 國外境內運費
    ///   - cardFeeRate: 刷卡費率
    ///   - platformFeeRate: 平台費率
    ///   - paymentFeeRate: 付款費率
    ///   - cardlessDeductionAmount: 無卡折抵金額
    ///   - cardlessSupplementAmount: 無卡補收金額
    ///   - categories: 商品類別
    ///   - campaignNames: 開團名稱
    ///   - paymentMethod: 付款方式
    ///   - reconciliationStatus: 對帳狀態
    ///   - notes: 備註
    ///   - paymentReceiptStatus: 付款收據狀態
    ///   - isCashOnDelivery: 是否為貨到付款
    ///   - customerName: 客戶名稱
    ///   - orderSource: 訂單來源
    ///   - currency: 幣別
    ///   - items: 訂單品項
    ///   - photos: 訂單照片
    /// - Returns: 建立的測試訂單
    static func makeOrder(
        id: String,
        status: OrderStatus = .purchased,
        chargedAmount: Decimal = 0,
        itemCost: Decimal = 0,
        domesticShipping: Decimal = 0,
        internationalShipping: Decimal = 0,
        foreignDomesticShipping: Decimal = 0,
        cardFeeRate: Decimal = 0,
        platformFeeRate: Decimal = 0,
        paymentFeeRate: Decimal = 0,
        cardlessDeductionAmount: Decimal = 0,
        cardlessSupplementAmount: Decimal = 0,
        categories: [String] = ["美妝"],
        campaignNames: [String] = [],
        paymentMethod: String = "信用卡",
        reconciliationStatus: String = "",
        notes: String = "",
        paymentReceiptStatus: PaymentReceiptStatus = .pending,
        isCashOnDelivery: Bool = false,
        customerName: String = "同一位客戶",
        orderSource: String = "蝦皮",
        currency: CurrencyCode = .jpy,
        items: [LedgerOrderItem] = [],
        photos: [Data] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: customerName, initials: "SC", tier: .regular),
            status: status,
            currency: currency,
            date: Date(timeIntervalSince1970: 1_770_000_000),
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
            reconciliationStatus: reconciliationStatus,
            campaignNames: campaignNames,
            paymentReceiptStatus: paymentReceiptStatus,
            isCashOnDelivery: isCashOnDelivery,
            photos: photos,
            mergedSourceIDs: []
        )
    }
}
