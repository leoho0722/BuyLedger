//
//  OrdersFeatureTests+MergeTiming.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension OrdersFeatureTests {

    /// 合併候選表單關閉前後，以及 500ms 延遲期間到達的失敗，都要等確認表單關好才顯示
    @Test
    func formSheetDismissed_合併轉場前後到達通知_確認表單優先且關好才顯示最新通知() async {
        // Given
        let clock = TestClock()
        let fixture = Self.makeMergeTimingFixture()
        let store = TestStore(initialState: fixture.initial) {
            OrdersFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.uuid = .constant(UUID(1))
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        await store.send(
            .presentation(
                .destination(
                    .presented(
                        .merge(
                            .delegate(
                                .completed(
                                    primary: fixture.primary,
                                    secondary: fixture.secondary,
                                    keptPhotos: []
                                )
                            )
                        )
                    )
                )
            )
        )
        await store.receive(
            \.presentation.delegate,
            .mergeCandidatesCompleted(
                primary: fixture.primary,
                secondary: fixture.secondary,
                keptPhotos: []
            )
        )
        await store.receive(\.presentation.mergeCandidateCompleted) {
            $0.$orders.withLock {
                $0 = [fixture.primary, fixture.secondary]
            }
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
            $0.presentation.queue.isAwaitingMergeConfirmation = true
        }
        await store.send(.presentation(.noticeRequested(Self.failureNotice("關閉回呼前失敗")))) {
            $0.presentation.queue.pendingNotice = Self.failureNotice("關閉回呼前失敗")
        }
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.queue.isFormClosing = false
        }
        await clock.advance(by: .milliseconds(499))
        let destinationBeforeConfirmation = store.state.presentation.destination
        await store.send(.presentation(.noticeRequested(Self.failureNotice("延遲期間失敗")))) {
            $0.presentation.queue.pendingNotice = Self.failureNotice("延遲期間失敗")
        }

        await clock.advance(by: .milliseconds(1))
        await store.receive(\.presentation.delegate.mergeConfirmationDue) {
            $0.presentation.destination = .edit(fixture.confirmation)
            $0.presentation.queue.isAwaitingMergeConfirmation = false
        }
        let sourceIDs = store.state.presentation.destination?.edit?.mergeSourceIDs
        await store.send(.presentation(.noticeRequested(Self.failureNotice("確認表單開啟後失敗")))) {
            $0.presentation.queue.pendingNotice = Self.failureNotice("確認表單開啟後失敗")
        }
        let destinationWithPendingNotice = store.state.presentation.destination
        await store.send(.presentation(.destination(.dismiss))) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.destination = Self.failureNotice("確認表單開啟後失敗")
            $0.presentation.queue.isFormClosing = false
            $0.presentation.queue.pendingNotice = nil
        }

        // Then
        #expect(destinationBeforeConfirmation == nil)
        #expect(sourceIDs == ["A", "B"])
        #expect(destinationWithPendingNotice == .edit(fixture.confirmation))
        #expect(store.state.presentation.destination == Self.failureNotice("確認表單開啟後失敗"))
        #expect(store.state.presentation.queue == OrdersPresentationQueue())
        await store.finish()
    }

    /// 500ms 已到，但合併候選表單還在關閉中時，確認表單與通知都先等候，表單關好後才依序顯示
    @Test
    func formSheetDismissed_延遲先完成關閉回呼晚到_仍優先開啟確認表單() async {
        // Given
        let clock = TestClock()
        let fixture = Self.makeMergeTimingFixture()
        let store = TestStore(initialState: fixture.initial) {
            OrdersFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.uuid = .constant(UUID(1))
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        await store.send(
            .presentation(
                .destination(
                    .presented(
                        .merge(
                            .delegate(
                                .completed(
                                    primary: fixture.primary,
                                    secondary: fixture.secondary,
                                    keptPhotos: []
                                )
                            )
                        )
                    )
                )
            )
        )
        await store.receive(
            \.presentation.delegate,
            .mergeCandidatesCompleted(
                primary: fixture.primary,
                secondary: fixture.secondary,
                keptPhotos: []
            )
        )
        await store.receive(\.presentation.mergeCandidateCompleted) {
            $0.$orders.withLock {
                $0 = [fixture.primary, fixture.secondary]
            }
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
            $0.presentation.queue.isAwaitingMergeConfirmation = true
        }
        await clock.advance(by: .milliseconds(500))
        await store.receive(\.presentation.delegate.mergeConfirmationDue) {
            $0.presentation.queue.pendingMergeConfirmation = .edit(fixture.confirmation)
        }
        await store.send(.presentation(.noticeRequested(Self.failureNotice("500ms 後失敗")))) {
            $0.presentation.queue.pendingNotice = Self.failureNotice("500ms 後失敗")
        }
        let destinationBeforeDismiss = store.state.presentation.destination

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.destination = .edit(fixture.confirmation)
            $0.presentation.queue.isFormClosing = false
            $0.presentation.queue.isAwaitingMergeConfirmation = false
            $0.presentation.queue.pendingMergeConfirmation = nil
        }

        // Then
        #expect(store.state.presentation.destination == .edit(fixture.confirmation))
        #expect(store.state.presentation.queue.pendingNotice == Self.failureNotice("500ms 後失敗"))
        #expect(destinationBeforeDismiss == nil)
        await store.finish()
    }
}

// MARK: - Nested Types

private extension OrdersFeatureTests {

    /// 合併轉場測試的起始狀態、來源訂單與預期確認表單
    struct MergeTimingFixture {

        /// 已放入兩筆來源訂單、並開著合併候選表單的訂單分頁初始狀態
        let initial: OrdersFeature.State

        /// 合併來源的第一筆訂單 (A)
        let primary: LedgerOrder

        /// 合併來源的第二筆訂單 (B)
        let secondary: LedgerOrder

        /// 金額寫死為 1,500、來源為 A 與 B 的預期確認表單狀態
        let confirmation: OrderEditFeature.State
    }
}

// MARK: - Private Method

private extension OrdersFeatureTests {

    /// 建立合併轉場測試用的兩筆來源訂單，以及金額寫死的預期確認表單
    ///
    /// - Returns: 訂單分頁初始狀態、兩筆來源訂單與合併金額 1,500 的確認表單
    static func makeMergeTimingFixture() -> MergeTimingFixture {
        let primary = LedgerOrder.fixture(
            id: "A",
            date: TestDependencies.fixedNow,
            chargedAmount: 1_200,
            orderSource: "",
            paymentMethod: ""
        )
        let secondary = LedgerOrder.fixture(
            id: "B",
            date: TestDependencies.fixedNow,
            chargedAmount: 300,
            orderSource: "",
            paymentMethod: ""
        )
        let initial = withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
            $0.uuid = .constant(UUID(0))
        } operation: {
            var state = OrdersFeature.State()
            state.refreshDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            state.presentation.destination = .merge(
                OrderMergeFeature.State(
                    primary: primary,
                    orders: [primary, secondary],
                    dateContext: OrderDateContext(
                        now: TestDependencies.fixedNow,
                        calendar: TestDependencies.fixedCalendar
                    )
                )
            )
            return state
        }
        initial.$orders.withLock {
            $0 = [primary, secondary]
        }
        var draft = OrderDraft(original: primary, currentDate: TestDependencies.fixedNow)
        draft.chargedAmount = 1_500
        let confirmation = OrderEditFeature.State(
            id: UUID(1),
            options: OrderEditOptions(calendar: TestDependencies.fixedCalendar),
            currentDate: TestDependencies.fixedNow,
            prefill: OrderEditFeature.State.Prefill(
                draft: draft,
                mergeSourceIDs: ["A", "B"],
                keptPhotos: []
            )
        )
        return MergeTimingFixture(
            initial: initial,
            primary: primary,
            secondary: secondary,
            confirmation: confirmation
        )
    }
}
