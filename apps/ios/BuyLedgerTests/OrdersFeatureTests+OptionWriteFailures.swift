//
//  OrdersFeatureTests+OptionWriteFailures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension OrdersFeatureTests {

    /// 新增類別寫入失敗時，類別清單與表單內容都維持原樣，失敗通知先暫存等表單關好
    @Test
    func rootRequest_新增類別寫入失敗_資料不變且暫存失敗通知() async {
        // Given
        let initialState = Self.makeOptionState()
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
        let notice = Self.failureNotice("orders.general.message.categoryAddedTry")

        // When
        await store.send(.rootRequest(.optionAdditionCompleted(request, isStored: false)))

        // Then
        await store.receive(\.presentation.noticeRequested, notice) {
            $0.presentation.queue.pendingNotice = notice
        }
        #expect(store.state.lookupCatalog.categories == ["美妝"])
        #expect(store.state.presentation.destination?.edit == initialEdit)
        #expect(store.state.presentation.destination?.alert == nil)
        await store.finish()
    }

    /// 新增類別的失敗通知在表單關好後才呈現，呈現後暫存欄位清空
    @Test
    func formSheetDismissed_新增類別寫入失敗後表單關好_才呈現失敗通知() async {
        // Given
        let notice = Self.failureNotice("orders.general.message.categoryAddedTry")
        var initial = Self.makeOptionState()
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
