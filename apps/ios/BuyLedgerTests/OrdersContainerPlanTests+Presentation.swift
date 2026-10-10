//
//  OrdersContainerPlanTests+Presentation.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrdersContainerPlanTests {

    /// 新增表單帶入傳入的識別值、現在時間與容器的預設幣別，且沒有合併來源
    ///
    /// - Throws: 目的地不是訂單編輯表單時由 `#require` 丟出
    @Test
    func newOrder_新增表單_帶入識別值現在時間與預設幣別() throws {
        // Given
        var state = Self.makeState(orders: [])
        state.defaultCurrency = .usd

        // When
        let destination = OrdersContainerPlan.newOrder(
            id: UUID(4),
            state: state,
            now: Self.now,
            calendar: Self.calendar
        )

        // Then
        let edit = try #require(Self.editState(of: destination))
        #expect(edit.id == UUID(4))
        #expect(edit.original == nil)
        #expect(edit.draft.date == Self.now)
        #expect(edit.draft.currency == .usd)
        #expect(edit.draft.status == .quoting)
        #expect(edit.draft.customerName == "")
        #expect(edit.mergeSourceIDs.isEmpty)
        #expect(edit.calendar == Self.calendar)
    }

    /// 同客戶的兩筆訂單合併成草稿時，身分欄位取主訂單，金額與項目合併計算
    @Test
    func mergeCandidateDraft_同客戶訂單_合併草稿取主訂單身分並加總金額() {
        // Given
        let state = Self.makeState(orders: [])
        let primary = LedgerOrder.fixture(
            id: "P",
            status: .confirmed,
            items: [
                LedgerOrderItem(
                    id: UUID(1),
                    name: "主品項",
                    quantity: 1,
                    unitPrice: 1_000
                ),
            ],
            itemCost: 300,
            chargedAmount: 1_000,
            orderSource: "主來源",
            categories: ["服飾", "鞋"],
            paymentMethod: "現金",
            notes: "主備註",
            campaignNames: ["春團"],
            paymentReceiptStatus: .received,
            photos: [Data([1])]
        )
        let secondary = LedgerOrder.fixture(
            id: "S",
            items: [
                LedgerOrderItem(
                    id: UUID(2),
                    name: "副品項",
                    quantity: 2,
                    unitPrice: 250
                ),
            ],
            itemCost: 200,
            chargedAmount: 500,
            orderSource: "副來源",
            categories: ["鞋", "帽"],
            paymentMethod: "現金",
            notes: "副備註",
            campaignNames: ["春團", "夏團"],
            photos: [Data([2])]
        )

        // When
        let draft = OrdersContainerPlan.mergeCandidateDraft(
            primary: primary,
            secondary: secondary,
            state: state,
            now: Self.now
        )

        // Then
        #expect(draft.customer.name == "測試客戶")
        #expect(draft.orderSource == "主來源")
        #expect(draft.status == .confirmed)
        #expect(draft.currency == .twd)
        #expect(draft.date == Self.now)
        #expect(draft.categories == ["服飾", "鞋", "帽"])
        #expect(draft.campaignNames == ["春團", "夏團"])
        #expect(draft.paymentMethod == "現金")
        #expect(draft.paymentReceiptStatus == .received)
        #expect(draft.chargedAmount == 1_500)
        #expect(draft.itemCost == 500)
        #expect(draft.items.map(\.id) == [UUID(1), UUID(2)])
        #expect(draft.notes == "主備註\n----------\n副備註")
        #expect(draft.photos == [Data([1]), Data([2])])
        #expect(draft.mergeSourceIDs == ["P", "S"])
    }

    /// 副訂單為無卡付款時，合併草稿採用副訂單的付款方式、對帳狀態與貨到付款旗標
    @Test
    func mergeCandidateDraft_副訂單為無卡付款_採用副訂單的付款欄位() {
        // Given
        let state = Self.makeState(orders: [])
        state.$lookupCatalog.withLock {
            $0.paymentMethods = [
                PaymentMethodInfo(
                    name: "無卡付款",
                    isCardless: true,
                    isBankTransfer: false,
                    isCashOnDelivery: false
                ),
            ]
        }
        let primary = LedgerOrder.fixture(id: "P", paymentMethod: "現金")
        let secondary = LedgerOrder.fixture(
            id: "S",
            paymentMethod: "無卡付款",
            reconciliationStatus: "已對帳",
            isCashOnDelivery: true
        )

        // When
        let draft = OrdersContainerPlan.mergeCandidateDraft(
            primary: primary,
            secondary: secondary,
            state: state,
            now: Self.now
        )

        // Then
        #expect(draft.paymentMethod == "無卡付款")
        #expect(draft.reconciliationStatus == "已對帳")
        #expect(draft.isCashOnDelivery)
    }

    /// 合併確認表單帶著合併來源、草稿欄位與保留的照片開啟，開啟時沒有未儲存的變更
    ///
    /// - Throws: 目的地不是訂單編輯表單時由 `#require` 丟出
    @Test
    func mergeConfirmation_合併草稿_預填表單含來源編號與保留照片() throws {
        // Given
        let state = Self.makeState(orders: [])
        let draft = Self.makeMergeDraftFixture()
        let context = OrderDateContext(now: Self.now, calendar: Self.calendar)

        // When
        let destination = OrdersContainerPlan.mergeConfirmation(
            draft: draft,
            keptPhotos: [Data([9])],
            state: state,
            formID: UUID(6),
            context: context
        )

        // Then
        let edit = try #require(Self.editState(of: destination))
        #expect(edit.id == UUID(6))
        #expect(edit.original == nil)
        #expect(edit.mergeSourceIDs == ["P", "S"])
        #expect(edit.isMergeContext)
        #expect(edit.draft.customerName == "測試客戶")
        #expect(edit.draft.orderSource == "合併來源")
        #expect(edit.draft.categories == ["服飾", "鞋"])
        #expect(edit.draft.chargedAmount == 1_500)
        #expect(edit.draft.date == Self.now)
        #expect(edit.draft.currency == .twd)
        #expect(edit.draft.paymentReceiptStatus == .pending)
        #expect(edit.draft.items.map(\.id) == [UUID(7)])
        #expect(edit.photos.draftPhotos == [Data([9])])
        #expect(!edit.isDirty)
        #expect(edit.calendar == Self.calendar)
    }
}

// MARK: - Private Method

private extension OrdersContainerPlanTests {

    /// 建立合併草稿的字面值輸入，每個欄位都寫死，不經合併規則計算
    ///
    /// - Returns: 客戶為測試客戶、金額為 1,500 且含兩個來源編號的合併草稿
    static func makeMergeDraftFixture() -> OrderMerge.Draft {
        OrderMerge.Draft(
            customer: LedgerCustomer(name: "測試客戶", initials: "TC", tier: .regular),
            orderSource: "合併來源",
            status: .confirmed,
            currency: .twd,
            date: Self.now,
            categories: ["服飾", "鞋"],
            campaignNames: ["春團"],
            paymentMethod: "現金",
            reconciliationStatus: "",
            isCashOnDelivery: false,
            paymentReceiptStatus: .pending,
            chargedAmount: 1_500,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            itemCost: 500,
            foreignDomesticShipping: 0,
            internationalShipping: 0,
            domesticShipping: 50,
            cardFeeRate: 0.02,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            items: [
                LedgerOrderItem(
                    id: UUID(7),
                    name: "合併品項",
                    quantity: 2,
                    unitPrice: 250
                ),
            ],
            notes: "合併備註",
            photos: [Data([1])],
            mergeSourceIDs: ["P", "S"]
        )
    }
}
