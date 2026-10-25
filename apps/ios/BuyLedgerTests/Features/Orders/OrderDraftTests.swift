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

/// `OrderDraft.resolveWriteResult` 的單元測試，涵蓋空白欄位的回退與預設、數值夾限與正規化
struct OrderDraftTests {

    /// 驗證編輯既有訂單時，草稿中空白的客戶名稱、來源、類別與付款方式都沿用原值，訂單編號也不變
    @Test
    func resolveWriteResult_編輯既有訂單欄位為空_沿用既有值() {
        // Given
        let existing = OrderDraftTestSupport.makeOrder(
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
        let result = OrderDraft.resolveWriteResult(editState, existingOrders: [existing]) {
            "unused"
        }

        // Then
        #expect(result.order.customer.name == "老客戶")
        #expect(result.order.orderSource == "蝦皮")
        #expect(result.order.categories == ["舊類別"])
        #expect(result.order.paymentMethod == "舊付款")
        #expect(result.isNewOrder == false)
        #expect(result.order.id == existing.id)
    }

    /// 驗證新建訂單時，空白的客戶、來源與類別改用預設值，付款方式則保持空白
    @Test
    func resolveWriteResult_新建訂單欄位為空_使用預設值() {
        // Given
        var editState = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        editState.draft.customerName = ""
        editState.draft.orderSource = ""
        editState.draft.categories = []
        editState.draft.paymentMethod = ""

        // When
        let result = OrderDraft.resolveWriteResult(editState, existingOrders: []) { "GENID" }

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

    /// 驗證付款方式不是無卡時，無卡扣抵與補足金額歸零，對帳狀態也清空
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
        let result = OrderDraft.resolveWriteResult(editState, existingOrders: []) { "GENID" }

        // Then
        #expect(result.order.cardlessDeductionAmount == 0)
        #expect(result.order.cardlessSupplementAmount == 0)
        #expect(result.order.reconciliationStatus == "")
    }

    /// 驗證付款方式為無卡時，無卡扣抵與補足金額保留草稿值，對帳狀態去除前後空白後存入
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
        let result = OrderDraft.resolveWriteResult(editState, existingOrders: []) { "GENID" }

        // Then
        #expect(result.order.cardlessDeductionAmount == 500)
        #expect(result.order.cardlessSupplementAmount == 300)
        #expect(result.order.reconciliationStatus == "已對帳")
    }

    /// 驗證費率超過上限時夾限為 1，負值夾限為 0，結果一律落在零到一之間
    @Test
    func resolveWriteResult_費率超出範圍_夾限在零到一之間() {
        // Given
        var editState = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        editState.draft.cardFeeRate = 1.5
        editState.draft.platformFeeRate = -0.5
        editState.draft.paymentFeeRate = 2

        // When
        let result = OrderDraft.resolveWriteResult(editState, existingOrders: []) { "GENID" }

        // Then
        #expect(result.order.cardFeeRate == 1)
        #expect(result.order.platformFeeRate == 0)
        #expect(result.order.paymentFeeRate == 1)
    }

    /// 驗證金額欄位為負值時夾限為 0，涵蓋收款金額、商品金額與三種運費
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
        let result = OrderDraft.resolveWriteResult(editState, existingOrders: []) { "GENID" }

        // Then
        #expect(result.order.chargedAmount == 0)
        #expect(result.order.itemCost == 0)
        #expect(result.order.domesticShipping == 0)
        #expect(result.order.internationalShipping == 0)
        #expect(result.order.foreignDomesticShipping == 0)
    }

    /// 驗證類別與開團名稱去除前後空白與空字串，重複的值只留第一次出現，並保留原本的順序
    @Test
    func resolveWriteResult_類別與開團名稱含空白或重複_正規化並保留順序() {
        // Given
        var editState = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        editState.draft.categories = [" 美妝 ", "美妝", "", "服飾"]
        editState.draft.campaignNames = ["A團", " A團 ", "", "B團"]

        // When
        let result = OrderDraft.resolveWriteResult(editState, existingOrders: []) { "GENID" }

        // Then
        #expect(result.order.categories == ["美妝", "服飾"])
        #expect(result.order.campaignNames == ["A團", "B團"])
    }

    /// 驗證草稿備註只有空白時存為空字串，不沿用既有的備註
    @Test
    func resolveWriteResult_備註清空_存為空字串() {
        // Given
        let existing = OrderDraftTestSupport.makeOrder(
            id: "BL-001",
            customerName: "客戶",
            notes: "舊備註"
        )
        var editState = OrderEditFeature.State(
            original: existing,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        editState.draft.notes = "   "

        // When
        let result = OrderDraft.resolveWriteResult(editState, existingOrders: [existing]) {
            "unused"
        }

        // Then
        #expect(result.order.notes == "")
    }
}
