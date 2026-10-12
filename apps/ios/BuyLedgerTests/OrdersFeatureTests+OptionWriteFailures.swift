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
    func presentation_新增類別寫入失敗_資料不變且暫存失敗通知() async {
        // Given
        let calls = LockIsolated<[String]>([])
        let failingAdd: CategoryService.AddCategory = { name throws(PersistenceError) in
            calls.withValue {
                $0.append(name)
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "失敗"))
        }
        let initialState = Self.makeOptionState()
        let initialEdit = initialState.presentation.destination?.edit
        let store = TestStore(initialState: initialState) {
            OrdersFeature()
        } withDependencies: {
            $0.categoryService.addCategory = failingAdd
        }
        let plan = OrderOptionWritePlan(
            formID: UUID(0),
            kind: .category,
            name: "香氛",
            flags: .none
        )

        // When
        await store.send(
            .presentation(
                .destination(.presented(.edit(.pickers(.view(.addCategoryTapped("香氛"))))))
            )
        )

        // Then
        await store.receive(
            \.presentation.destination.presented.edit.pickers.delegate,
            .addOptionRequested(kind: .category, name: "香氛", flags: .none)
        )
        await store.receive(
            \.presentation.destination.presented.edit.delegate,
            .addOptionRequested(kind: .category, name: "香氛", flags: .none)
        )
        await store.receive(\.presentation.delegate, .optionAddRequested(plan))
        await store.receive(\.writes.optionAddRequested, plan)
        await store.receive(\.writes.optionResponse)
        await store.receive(\.writes.delegate, .failed(.option(.category)))
        await store.receive(\.presentation.noticeRequested, Self.failureNotice("orders.general.message.categoryAddedTry")) {
            $0.presentation.queue.pendingNotice = Self.failureNotice("orders.general.message.categoryAddedTry")
        }
        #expect(store.state.lookupCatalog.categories == ["美妝"])
        #expect(store.state.presentation.destination?.edit == initialEdit)
        #expect(store.state.presentation.destination?.alert == nil)
        #expect(calls.value == ["香氛"])
        await store.finish()
    }

    /// 新增類別的失敗通知在表單關好後才呈現，呈現後暫存欄位清空
    @Test
    func formSheetDismissed_新增類別寫入失敗後表單關好_才呈現失敗通知() async {
        // Given
        var initial = Self.makeOptionState()
        initial.presentation.destination = nil
        initial.presentation.queue.isFormClosing = true
        initial.presentation.queue.pendingNotice = Self.failureNotice("orders.general.message.categoryAddedTry")
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.queue.isFormClosing = false
            $0.presentation.queue.pendingNotice = nil
            $0.presentation.destination = Self.failureNotice("orders.general.message.categoryAddedTry")
        }

        // Then
        #expect(store.state.presentation.destination == Self.failureNotice("orders.general.message.categoryAddedTry"))
        #expect(store.state.presentation.queue.pendingNotice == nil)
    }
}
