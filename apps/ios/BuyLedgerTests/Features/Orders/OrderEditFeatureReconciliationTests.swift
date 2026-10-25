//
//  OrderEditFeatureReconciliationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderEditFeature` 的單元測試，涵蓋對帳狀態新增請求、既有值補入選項，以及選擇器推入與選取
struct OrderEditFeatureReconciliationTests {

    // MARK: - Properties

    /// 對帳狀態不在可選清單中的既有訂單樣本
    private static let orderWithReconciliationStatus = LedgerOrder(
        id: "BL-TEST-RS",
        customer: LedgerCustomer(name: "對帳測試", initials: "RS", tier: .regular),
        status: .confirmed,
        currency: .twd,
        date: Date(timeIntervalSince1970: 0),
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
        orderSource: "蝦皮",
        categories: ["美妝"],
        paymentMethod: "orders.edit.label.bankTransfer",
        notes: "",
        reconciliationStatus: "待對帳",
        campaignNames: [],
        paymentReceiptStatus: .pending,
        isCashOnDelivery: false,
        photos: [],
        mergedSourceIDs: []
    )

    /// 驗證新增對帳狀態時，請求只往上送出，落盤前選項與草稿都保持原值
    @Test
    @MainActor
    func pickers_新增對帳狀態尚未落盤_保留草稿與選項() async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.pickers.options.reconciliationStatuses = ["待對帳"]
        initial.draft.reconciliationStatus = "待對帳"
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.pickers(.view(.addReconciliationStatusTapped("對帳成功"))))

        // Then
        await store.receive(
            \.pickers.delegate,
            .addOptionRequested(kind: .reconciliationStatus, name: "對帳成功", flags: .none)
        )
        await store.receive(
            \.delegate,
            .addOptionRequested(kind: .reconciliationStatus, name: "對帳成功", flags: .none)
        )
        #expect(store.state.pickers.options.reconciliationStatuses == ["待對帳"])
        #expect(store.state.draft.reconciliationStatus == "待對帳")
    }

    /// 驗證既有訂單的對帳狀態不在可選清單時，草稿仍帶入該值，並把它補進選項
    ///
    /// - Note: 舊資料中的對帳狀態不能因主檔清單未載入而消失
    @Test
    func init_既有訂單對帳狀態不在清單_帶入草稿並補進選項() {
        // Given
        let original = Self.orderWithReconciliationStatus

        // When
        let state = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )

        // Then
        #expect(state.draft.reconciliationStatus == "待對帳")
        #expect(state.pickers.options.reconciliationStatuses == ["待對帳"])
    }

    /// 驗證尚未開啟選擇器時，點選對帳狀態按鈕會推入對帳狀態選擇器，並把 `pickerRoute` 設為 `.reconciliationStatus`
    @Test
    @MainActor
    func pickers_點選對帳狀態按鈕時尚未開啟選擇器_推入對帳狀態選擇器() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.pickers(.view(.reconciliationStatusPickerTapped))) {
            $0.pickers.pickerRoute = .reconciliationStatus
        }

        // Then
        #expect(store.state.pickers.pickerRoute == .reconciliationStatus)
    }

    /// 驗證草稿尚無對帳狀態時，選取後草稿的 `reconciliationStatus` 寫入所選名稱
    @Test
    @MainActor
    func pickers_選取對帳狀態且草稿尚無對帳狀態_更新草稿() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.pickers(.view(.reconciliationStatusSelected("待對帳"))))

        // Then
        await store.receive(\.pickers.delegate.reconciliationStatusSelected, "待對帳") {
            $0.draft.reconciliationStatus = "待對帳"
        }
        #expect(store.state.draft.reconciliationStatus == "待對帳")
    }
}
