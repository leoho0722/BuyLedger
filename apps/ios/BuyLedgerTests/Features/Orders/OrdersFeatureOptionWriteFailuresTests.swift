//
//  OrdersFeatureOptionWriteFailuresTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrdersFeature` 的單元測試，以 TestStore 逐步驗證主檔選項寫入失敗時的資料與通知處理
@MainActor
struct OrdersFeatureOptionWriteFailuresTests {

    /// 驗證根功能送來的 `optionAdditionCompleted` 回報類別未儲存時，類別清單與編輯表單都維持原樣，失敗通知暫存在 `pendingNotice`
    @Test
    func rootRequest_新增類別寫入失敗_資料不變且暫存失敗通知() async {
        // Given
        let initialState = OrdersFeatureTestSupport.makeOptionState()
        let initialEdit = initialState.presentation.destination?.edit
        let store = TestStore(initialState: initialState) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        let request = LookupAdditionRequest(
            id: UUID(0),
            kind: .category,
            name: "香氛",
            flags: .none
        )
        let notice = OrdersFeatureTestSupport.failureNotice(
            "orders.general.message.categoryAddedTry"
        )

        // When
        await store.send(.rootRequest(.optionAdditionCompleted(request, isStored: false)))

        // Then
        await store.receive(\.presentation.noticeRequested, notice) {
            $0.presentation.queue.pendingNotice = notice
        }
        #expect(store.state.lookupCatalog.categories == ["美妝"])
        #expect(store.state.presentation.destination?.edit == initialEdit)
        await store.finish()
    }

    /// 驗證新增類別寫入失敗後，表單關好時失敗通知改為目前呈現的 `destination`，`pendingNotice` 清空
    @Test
    func formSheetDismissed_新增類別寫入失敗後表單關好_才呈現失敗通知() async {
        // Given
        let notice = OrdersFeatureTestSupport.failureNotice(
            "orders.general.message.categoryAddedTry"
        )
        var initial = OrdersFeatureTestSupport.makeOptionState()
        initial.presentation.destination = nil
        initial.presentation.queue.isFormClosing = true
        initial.presentation.queue.pendingNotice = notice
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.queue.isFormClosing = false
            $0.presentation.queue.pendingNotice = nil
            $0.presentation.destination = notice
        }

        // Then
        #expect(store.state.presentation.destination == notice)
        #expect(store.state.presentation.queue.pendingNotice == nil)
    }
}
