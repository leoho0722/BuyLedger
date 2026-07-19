//
//  OrderMergeTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/6/6.
//

import Foundation
import Testing
@testable import BuyLedger

@MainActor
struct OrderMergeTests {

    // MARK: - Tests

    @Test func amountFieldsAreSummed() {
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

        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Self.mergeDate,
            isCardless: { _ in false }
        )

        #expect(draft.chargedAmount == 3_000)
        #expect(draft.itemCost == 1_500)
        #expect(draft.domesticShipping == 140)
        #expect(draft.internationalShipping == 300)
        #expect(draft.foreignDomesticShipping == 70)
        #expect(draft.cardlessDeductionAmount == 60)
        #expect(draft.cardlessSupplementAmount == 25)
    }

    @Test func feeRatesUseChargedAmountWeightedAverage() {
        // (1.5% × 1000 + 2% × 2000) ÷ 3000 ≈ 1.83%
        let primary = Self.makeOrder(id: "P", chargedAmount: 1_000, cardFeeRate: Self.decimal("0.015"))
        let secondary = Self.makeOrder(id: "S", chargedAmount: 2_000, cardFeeRate: Self.decimal("0.02"))

        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Self.mergeDate,
            isCardless: { _ in false }
        )

        let expected = (Self.decimal("0.015") * 1_000 + Self.decimal("0.02") * 2_000) / 3_000
        #expect(draft.cardFeeRate == expected)
    }

    @Test func feeRatesFallBackToPrimaryWhenOneSideHasZeroCharge() {
        // 副訂單實付 0：加權平均退化為主訂單值仍正確 ((1.5%×1000 + 3%×0) ÷ 1000 = 1.5%)
        let primary = Self.makeOrder(id: "P", chargedAmount: 1_000, cardFeeRate: Self.decimal("0.015"))
        let secondary = Self.makeOrder(id: "S", chargedAmount: 0, cardFeeRate: Self.decimal("0.03"))

        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Self.mergeDate,
            isCardless: { _ in false }
        )

        #expect(draft.cardFeeRate == Self.decimal("0.015"))
    }

    @Test func feeRatesUsePrimaryWhenBothChargesAreZero() {
        // 兩筆實付皆 0：分母為 0，沿用主訂單比例、不得產生 NaN
        let primary = Self.makeOrder(id: "P", chargedAmount: 0, cardFeeRate: Self.decimal("0.015"), platformFeeRate: Self.decimal("0.03"), paymentFeeRate: Self.decimal("0.005"))
        let secondary = Self.makeOrder(id: "S", chargedAmount: 0, cardFeeRate: Self.decimal("0.03"))

        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Self.mergeDate,
            isCardless: { _ in false }
        )

        #expect(draft.cardFeeRate == Self.decimal("0.015"))
        #expect(draft.platformFeeRate == Self.decimal("0.03"))
        #expect(draft.paymentFeeRate == Self.decimal("0.005"))
    }

    @Test func categoriesAndCampaignsTakeOrderedUnion() {
        let primary = Self.makeOrder(id: "P", categories: ["beauty"], campaignNames: ["May-JP"])
        let secondary = Self.makeOrder(id: "S", categories: ["snacks", "beauty"], campaignNames: ["June-KR"])

        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Self.mergeDate,
            isCardless: { _ in false }
        )

        #expect(draft.categories == ["beauty", "snacks"])
        #expect(draft.campaignNames == ["May-JP", "June-KR"])
    }

    @Test func notesJoinWithDashSeparatorLine() {
        // (主, 副) → 合併備註的三種組合
        let cases: [(String, String, String)] = [
            ("急件", "含贈品", "急件\n----------\n含贈品"),
            ("急件", "", "急件"),
            ("", "含贈品", "含贈品"),
            ("", "", ""),
        ]

        for (primaryNotes, secondaryNotes, expected) in cases {
            let draft = OrderMerge.makeDraft(
                primary: Self.makeOrder(id: "P", notes: primaryNotes),
                secondary: Self.makeOrder(id: "S", notes: secondaryNotes),
                now: Self.mergeDate,
                isCardless: { _ in false }
            )
            #expect(draft.notes == expected)
        }
    }

    @Test func cardlessPaymentMethodWinsOnConflict() {
        // 恰有一筆 (副) 屬無卡：付款方式取副訂單，對帳狀態與貨到付款隨之
        let primary = Self.makeOrder(id: "P", paymentMethod: "信用卡", reconciliationStatus: "", isCashOnDelivery: false)
        let secondary = Self.makeOrder(id: "S", paymentMethod: "全家好開店", reconciliationStatus: "待對帳", isCashOnDelivery: true)

        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Self.mergeDate,
            isCardless: { $0 == "全家好開店" }
        )

        #expect(draft.paymentMethod == "全家好開店")
        #expect(draft.reconciliationStatus == "待對帳")
        #expect(draft.isCashOnDelivery == true)
    }

    @Test func primaryPaymentMethodWinsWhenSameOrNoCardlessConflict() {
        // 兩筆相同：取該值、對帳狀態隨主訂單
        let same = OrderMerge.makeDraft(
            primary: Self.makeOrder(id: "P", paymentMethod: "信用卡", reconciliationStatus: "主對帳"),
            secondary: Self.makeOrder(id: "S", paymentMethod: "信用卡", reconciliationStatus: "副對帳"),
            now: Self.mergeDate,
            isCardless: { _ in false }
        )
        #expect(same.paymentMethod == "信用卡")
        #expect(same.reconciliationStatus == "主對帳")

        // 不同且皆非無卡：取主訂單
        let neither = OrderMerge.makeDraft(
            primary: Self.makeOrder(id: "P", paymentMethod: "信用卡"),
            secondary: Self.makeOrder(id: "S", paymentMethod: "銀行轉帳"),
            now: Self.mergeDate,
            isCardless: { _ in false }
        )
        #expect(neither.paymentMethod == "信用卡")

        // 兩筆皆無卡且不同：仍取主訂單 (「恰有一筆無卡」才換邊)
        let bothCardless = OrderMerge.makeDraft(
            primary: Self.makeOrder(id: "P", paymentMethod: "全家好開店"),
            secondary: Self.makeOrder(id: "S", paymentMethod: "7-11 賣貨便"),
            now: Self.mergeDate,
            isCardless: { _ in true }
        )
        #expect(bothCardless.paymentMethod == "全家好開店")
    }

    @Test func passthroughFieldsFollowPrimaryAndDateIsMergeTime() {
        let primary = Self.makeOrder(id: "P", status: .shipping, paymentReceiptStatus: .received)
        let secondary = Self.makeOrder(id: "S", status: .purchased, paymentReceiptStatus: .pending)

        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Self.mergeDate,
            isCardless: { _ in false }
        )

        #expect(draft.customer == primary.customer)
        #expect(draft.orderSource == primary.orderSource)
        #expect(draft.status == .shipping)
        #expect(draft.currency == primary.currency)
        #expect(draft.paymentReceiptStatus == .received)
        #expect(draft.date == Self.mergeDate)
        #expect(draft.mergeSourceIDs == ["P", "S"])
    }

    @Test func itemsAndPhotosConcatenatePrimaryFirst() {
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

        let draft = OrderMerge.makeDraft(
            primary: primary,
            secondary: secondary,
            now: Self.mergeDate,
            isCardless: { _ in false }
        )

        #expect(draft.items.map(\.name) == ["主商品", "副商品"])
        #expect(draft.photos == [photoP, photoS1, photoS2])
    }
}

// MARK: - Helpers

private extension OrderMergeTests {

    /// 固定的合併當下時間
    static let mergeDate = Date(timeIntervalSince1970: 1_777_000_000)

    /// 以固定字串建立 `Decimal`，避免浮點誤差
    static func decimal(_ value: String) -> Decimal {
        Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }

    /// 建立測試訂單；未指定的欄位使用中性預設值
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
        items: [LedgerOrderItem] = [],
        photos: [Data] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "同一位客戶", initials: "SC", tier: .regular),
            status: status,
            currency: .jpy,
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
            orderSource: "蝦皮",
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
