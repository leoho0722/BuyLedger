//
//  OrderEditFeatureTests+Reconciliation.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrderEditFeatureTests {

    /// 新增對帳狀態時只轉送請求，清單與草稿等寫入完成才變更
    @Test
    func pickers_新增對帳狀態尚未落盤_保留草稿與選項() async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.pickers.availableReconciliationStatuses = ["待對帳"]
        initial.draft.reconciliationStatus = "待對帳"
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
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
        #expect(store.state.pickers.availableReconciliationStatuses == ["待對帳"])
        #expect(store.state.draft.reconciliationStatus == "待對帳")
    }

    /// 既有訂單的對帳狀態帶入草稿；不在可選清單時補進清單
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
        #expect(state.pickers.availableReconciliationStatuses == ["待對帳"])
    }

    /// 尚未開啟選擇器時，點選對帳狀態按鈕會推入對帳狀態選擇器
    @Test
    func pickers_點選對帳狀態按鈕時尚未開啟選擇器_推入對帳狀態選擇器() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.pickers(.view(.reconciliationStatusPickerTapped))) {
            $0.pickers.pickerRoute = .reconciliationStatus
        }

        // Then
        #expect(store.state.pickers.pickerRoute == .reconciliationStatus)
    }

    /// 草稿尚無對帳狀態時，選取狀態會寫入名稱
    @Test
    func pickers_選取對帳狀態且草稿尚無對帳狀態_更新草稿() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
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
