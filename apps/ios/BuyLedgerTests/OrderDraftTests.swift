//
//  OrderDraftTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 驗證 `OrderDraft` 的訂單建構邏輯
struct OrderDraftTests {

    /// 編輯時空白主檔欄位回退既有值
    @Test
    func resolveWriteResult_編輯既有訂單欄位為空_沿用既有值() {
        // Given
        let existing = Self.makeOrder(
            id: "BL-001",
            customerName: "老客戶",
            orderSource: "蝦皮",
            categories: ["舊類別"],
            paymentMethod: "舊付款"
        )
        var editState = OrderEditFeature.State(
            original: existing,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        editState.draft.customerName = "   "
        editState.draft.orderSource = ""
        editState.draft.categories = []
        editState.draft.paymentMethod = ""

        // When
        let result = OrderDraft.resolveWriteResult(
            editState,
            existingOrders: [existing],
            newOrderID: { "unused" }
        )

        // Then
        #expect(result.order.customer.name == "老客戶")
        #expect(result.order.orderSource == "蝦皮")
        #expect(result.order.categories == ["舊類別"])
        #expect(result.order.paymentMethod == "舊付款")
        #expect(result.isNewOrder == false)
        #expect(result.order.id == existing.id)
    }

    /// 新建時空白欄位使用預設值；付款方式保持空白
    @Test
    func resolveWriteResult_新建訂單欄位為空_使用預設值() {
        // Given
        var editState = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        editState.draft.customerName = ""
        editState.draft.orderSource = ""
        editState.draft.categories = []
        editState.draft.paymentMethod = ""

        // When
        let result = OrderDraft.resolveWriteResult(
            editState,
            existingOrders: [],
            newOrderID: { "GENID" }
        )

        // Then
        #expect(result.order.customer.name == "未命名客戶")
        #expect(result.order.customer.initials == "未命")
        #expect(result.order.customer.tier == .new)
        #expect(result.order.orderSource == "未指定")
        #expect(result.order.categories == ["未分類"])
        #expect(result.order.paymentMethod == "")
        #expect(result.isNewOrder == true)
        #expect(result.order.id == "BL-DRAFT-GENID")
    }

    /// 非無卡付款時，無卡金額歸零且清空對帳狀態
    @Test
    func resolveWriteResult_非無卡付款_無卡金額歸零且清空對帳狀態() {
        // Given
        var editState = OrderEditFeature.State(
            id: UUID(0),
            options: OrderEditOptions(
                paymentMethods: [
                    PaymentMethodInfo(
                        name: "信用卡",
                        isCardless: false,
                        isBankTransfer: false,
                        isCashOnDelivery: false
                    ),
                ],
                calendar: TestDependencies.fixedCalendar
            ),
            currentDate: TestDependencies.fixedNow
        )
        editState.draft.paymentMethod = "信用卡"
        editState.draft.cardlessDeductionAmount = 500
        editState.draft.cardlessSupplementAmount = 300
        editState.draft.reconciliationStatus = "已對帳"

        // When
        let result = OrderDraft.resolveWriteResult(
            editState,
            existingOrders: [],
            newOrderID: { "GENID" }
        )

        // Then
        #expect(result.order.cardlessDeductionAmount == 0)
        #expect(result.order.cardlessSupplementAmount == 0)
        #expect(result.order.reconciliationStatus == "")
    }

    /// 無卡付款方式時，對帳狀態保留並去除前後空白，無卡金額維持草稿值
    @Test
    func resolveWriteResult_無卡付款_保留無卡金額與對帳狀態() {
        // Given
        var editState = OrderEditFeature.State(
            id: UUID(0),
            options: OrderEditOptions(
                paymentMethods: [
                    PaymentMethodInfo(
                        name: "無卡存款",
                        isCardless: true,
                        isBankTransfer: false,
                        isCashOnDelivery: false
                    ),
                ],
                calendar: TestDependencies.fixedCalendar
            ),
            currentDate: TestDependencies.fixedNow
        )
        editState.draft.paymentMethod = "無卡存款"
        editState.draft.chargedAmount = 1_000
        editState.draft.cardlessDeductionAmount = 500
        editState.draft.cardlessSupplementAmount = 300
        editState.draft.reconciliationStatus = " 已對帳 "

        // When
        let result = OrderDraft.resolveWriteResult(
            editState,
            existingOrders: [],
            newOrderID: { "GENID" }
        )

        // Then
        #expect(result.order.cardlessDeductionAmount == 500)
        #expect(result.order.cardlessSupplementAmount == 300)
        #expect(result.order.reconciliationStatus == "已對帳")
    }

    /// 費率超過上限時夾限為 1，負值夾限為 0
    @Test
    func resolveWriteResult_費率超出範圍_夾限在零到一之間() {
        // Given
        var editState = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        editState.draft.cardFeeRate = 1.5
        editState.draft.platformFeeRate = -0.5
        editState.draft.paymentFeeRate = 2

        // When
        let result = OrderDraft.resolveWriteResult(
            editState,
            existingOrders: [],
            newOrderID: { "GENID" }
        )

        // Then
        #expect(result.order.cardFeeRate == 1)
        #expect(result.order.platformFeeRate == 0)
        #expect(result.order.paymentFeeRate == 1)
    }

    /// 金額欄位為負值時夾限為 0
    @Test
    func resolveWriteResult_金額為負值_夾限為零() {
        // Given
        var editState = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        editState.draft.chargedAmount = -100
        editState.draft.itemCost = -50
        editState.draft.domesticShipping = -10
        editState.draft.internationalShipping = -20
        editState.draft.foreignDomesticShipping = -30

        // When
        let result = OrderDraft.resolveWriteResult(
            editState,
            existingOrders: [],
            newOrderID: { "GENID" }
        )

        // Then
        #expect(result.order.chargedAmount == 0)
        #expect(result.order.itemCost == 0)
        #expect(result.order.domesticShipping == 0)
        #expect(result.order.internationalShipping == 0)
        #expect(result.order.foreignDomesticShipping == 0)
    }

    /// 類別與開團名稱會去除前後空白、空字串與重複值，並保留原本順序
    @Test
    func resolveWriteResult_類別與開團名稱含空白或重複_正規化並保留順序() {
        // Given
        var editState = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        editState.draft.categories = [" 美妝 ", "美妝", "", "服飾"]
        editState.draft.campaignNames = ["A團", " A團 ", "", "B團"]

        // When
        let result = OrderDraft.resolveWriteResult(
            editState,
            existingOrders: [],
            newOrderID: { "GENID" }
        )

        // Then
        #expect(result.order.categories == ["美妝", "服飾"])
        #expect(result.order.campaignNames == ["A團", "B團"])
    }

    /// 備註可清空並存回空字串，不沿用既有備註
    @Test
    func resolveWriteResult_備註清空_存為空字串() {
        // Given
        let existing = Self.makeOrder(id: "BL-001", customerName: "客戶", notes: "舊備註")
        var editState = OrderEditFeature.State(
            original: existing,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        editState.draft.notes = "   "

        // When
        let result = OrderDraft.resolveWriteResult(
            editState,
            existingOrders: [existing],
            newOrderID: { "unused" }
        )

        // Then
        #expect(result.order.notes == "")
    }
}

// MARK: - Internal Method

extension OrderDraftTests {

    /// 建立僅供草稿建構測試使用的最小訂單；非相關欄位以零值或佔位值填入
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - customerName: 客戶名稱
    ///   - initials: 客戶縮寫
    ///   - tier: 客戶等級
    ///   - orderSource: 訂單來源
    ///   - categories: 商品類別
    ///   - paymentMethod: 付款方式
    ///   - notes: 備註
    /// - Returns: 建立的測試訂單
    static func makeOrder(
        id: String,
        customerName: String,
        initials: String = "XX",
        tier: CustomerTier = .regular,
        orderSource: String = "來源",
        categories: [String] = ["類別"],
        paymentMethod: String = "付款",
        notes: String = ""
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: customerName, initials: initials, tier: tier),
            status: .quoting,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: orderSource,
            categories: categories,
            paymentMethod: paymentMethod,
            notes: notes,
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
}
