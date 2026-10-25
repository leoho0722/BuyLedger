//
//  OrdersFeatureMergeTimingTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrdersFeature` 的單元測試，以 TestStore 逐步驗證合併確認與失敗通知在表單轉場中的呈現順序
@MainActor
struct OrdersFeatureMergeTimingTests {

    /// 驗證合併轉場中到達的失敗通知先暫存在 `pendingNotice`，`destination` 維持 `nil`，不論候選表單是否仍在關閉動畫中
    ///
    /// - Parameter isFormClosing: 候選表單是否仍在關閉動畫中
    @Test(arguments: [true, false])
    func presentation_合併轉場中到達失敗通知_暫存通知不搶先呈現(isFormClosing: Bool) async {
        // Given
        let fixture = Self.makeMergeTimingFixture()
        var initial = fixture.initial
        initial.presentation.destination = nil
        initial.presentation.queue.isFormClosing = isFormClosing
        initial.presentation.queue.isAwaitingMergeConfirmation = true
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(
            .presentation(.noticeRequested(OrdersFeatureTestSupport.failureNotice("轉場中失敗")))
        ) {
            $0.presentation.queue.pendingNotice = OrdersFeatureTestSupport.failureNotice("轉場中失敗")
        }

        // Then
        #expect(store.state.presentation.destination == nil)
        #expect(
            store.state.presentation.queue.pendingNotice
                == OrdersFeatureTestSupport.failureNotice("轉場中失敗")
        )
    }

    /// 驗證合併轉場中候選表單的關閉回呼先到時，500ms 到期前暫存的通知不呈現；到期後先開啟確認表單，通知繼續暫存
    @Test
    func formSheetDismissed_合併轉場中關閉回呼先到_到期後先開啟確認表單() async {
        // Given
        let clock = TestClock()
        let requestedDelays = LockIsolated<[Duration]>([])
        let fixture = Self.makeMergeTimingFixture()
        var initial = fixture.initial
        initial.presentation.queue.pendingNotice = OrdersFeatureTestSupport.failureNotice("延遲期間失敗")
        let store = Self.makeStore(
            initial: initial,
            clock: RecordingClock(base: clock, requestedDelays: requestedDelays)
        )
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

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.queue.isFormClosing = false
        }

        // Then
        await clock.advance(by: .milliseconds(500))
        await store.receive(\.presentation.delegate.mergeConfirmationDue) {
            $0.presentation.destination = .edit(fixture.confirmation)
            $0.presentation.queue.isAwaitingMergeConfirmation = false
        }
        #expect(requestedDelays.value == [.milliseconds(500)])
        #expect(store.state.presentation.destination?.edit?.mergeSourceIDs == ["A", "B"])
        #expect(
            store.state.presentation.queue.pendingNotice
                == OrdersFeatureTestSupport.failureNotice("延遲期間失敗")
        )
        await store.finish()
    }

    /// 驗證合併確認表單開啟中到達的失敗通知只存入 `pendingNotice`，不取代目前開啟的確認表單
    @Test
    func presentation_合併確認表單開啟中到達失敗通知_暫存通知並保留表單() async {
        // Given
        let fixture = Self.makeMergeTimingFixture()
        var initial = fixture.initial
        initial.presentation.destination = .edit(fixture.confirmation)
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(
            .presentation(.noticeRequested(OrdersFeatureTestSupport.failureNotice("確認表單開啟後失敗")))
        ) {
            $0.presentation.queue.pendingNotice = OrdersFeatureTestSupport.failureNotice(
                "確認表單開啟後失敗"
            )
        }

        // Then
        #expect(store.state.presentation.destination == .edit(fixture.confirmation))
        #expect(
            store.state.presentation.queue.pendingNotice
                == OrdersFeatureTestSupport.failureNotice("確認表單開啟後失敗")
        )
    }

    /// 驗證關閉合併確認表單時，`destination` 清空並標記表單關閉中，暫存通知仍保留
    @Test
    func presentation_關閉合併確認表單_標記關閉中並保留暫存通知() async {
        // Given
        let fixture = Self.makeMergeTimingFixture()
        var initial = fixture.initial
        initial.presentation.destination = .edit(fixture.confirmation)
        initial.presentation.queue.pendingNotice = OrdersFeatureTestSupport.failureNotice(
            "確認表單開啟後失敗"
        )
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.presentation(.destination(.dismiss))) {
            $0.presentation.destination = nil
            $0.presentation.queue.isFormClosing = true
        }

        // Then
        #expect(store.state.presentation.destination == nil)
        #expect(
            store.state.presentation.queue.pendingNotice
                == OrdersFeatureTestSupport.failureNotice("確認表單開啟後失敗")
        )
    }

    /// 驗證合併確認表單關閉中有暫存通知時，表單關好後該通知改為目前呈現的 `destination`，`pendingNotice` 與關閉中的標記一併清空
    @Test
    func formSheetDismissed_合併確認表單關閉中有暫存通知_關好後呈現通知() async {
        // Given
        let fixture = Self.makeMergeTimingFixture()
        var initial = fixture.initial
        initial.presentation.destination = nil
        initial.presentation.queue.isFormClosing = true
        initial.presentation.queue.pendingNotice = OrdersFeatureTestSupport.failureNotice(
            "確認表單開啟後失敗"
        )
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.destination = OrdersFeatureTestSupport.failureNotice("確認表單開啟後失敗")
            $0.presentation.queue.isFormClosing = false
            $0.presentation.queue.pendingNotice = nil
        }

        // Then
        #expect(
            store.state.presentation.destination
                == OrdersFeatureTestSupport.failureNotice("確認表單開啟後失敗")
        )
        #expect(store.state.presentation.queue.isFormClosing == false)
        #expect(store.state.presentation.queue.isAwaitingMergeConfirmation == false)
        #expect(store.state.presentation.queue.pendingNotice == nil)
        #expect(store.state.presentation.queue.pendingMergeConfirmation == nil)
    }

    /// 驗證合併候選完成且關閉回呼未到時，500ms 到期後確認表單暫存為 `pendingMergeConfirmation`，不呈現為 `destination`
    @Test
    func presentation_合併候選完成且關閉回呼未到_到期時暫存確認表單() async {
        // Given
        let clock = TestClock()
        let requestedDelays = LockIsolated<[Duration]>([])
        let fixture = Self.makeMergeTimingFixture()
        let store = Self.makeStore(
            initial: fixture.initial,
            clock: RecordingClock(base: clock, requestedDelays: requestedDelays)
        )

        // When
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

        // Then
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
        #expect(requestedDelays.value == [.milliseconds(500)])
        #expect(store.state.presentation.destination == nil)
        await store.finish()
    }

    /// 驗證確認表單已暫存、候選表單的關閉回呼才到時，改由關閉回呼開啟確認表單，暫存通知繼續等待
    @Test
    func formSheetDismissed_延遲先完成關閉回呼晚到_仍優先開啟確認表單() async {
        // Given
        let fixture = Self.makeMergeTimingFixture()
        var initial = fixture.initial
        initial.presentation.destination = nil
        initial.presentation.queue.isFormClosing = true
        initial.presentation.queue.isAwaitingMergeConfirmation = true
        initial.presentation.queue.pendingMergeConfirmation = .edit(fixture.confirmation)
        initial.presentation.queue.pendingNotice = OrdersFeatureTestSupport.failureNotice(
            "500ms 後失敗"
        )
        let store = Self.makeStore(initial: initial)

        // When
        await store.send(.view(.formSheetDismissed)) {
            $0.presentation.destination = .edit(fixture.confirmation)
            $0.presentation.queue.isFormClosing = false
            $0.presentation.queue.isAwaitingMergeConfirmation = false
            $0.presentation.queue.pendingMergeConfirmation = nil
        }

        // Then
        #expect(store.state.presentation.destination == .edit(fixture.confirmation))
        #expect(
            store.state.presentation.queue.pendingNotice
                == OrdersFeatureTestSupport.failureNotice("500ms 後失敗")
        )
    }
}

// MARK: - Nested Types

private extension OrdersFeatureMergeTimingTests {

    /// 合併轉場測試的固定資料，裝起始狀態、來源訂單與預期確認表單，由 `makeMergeTimingFixture()` 組出
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

    /// 記錄每次 `sleep` 要求的延遲時長，再交給 `TestClock` 實際等待的時脈替身
    struct RecordingClock: Clock {

        /// 實際控制時間推進的測試時脈
        let base: TestClock<Swift.Duration>

        /// 每次 `sleep` 要求的延遲時長，以呼叫當下的時間為起點
        let requestedDelays: LockIsolated<[Swift.Duration]>

        /// 測試時脈目前的時間
        var now: TestClock<Swift.Duration>.Instant {
            base.now
        }

        /// 測試時脈的最小解析度
        var minimumResolution: Swift.Duration {
            base.minimumResolution
        }

        /// 記錄要求的延遲時長，再交給 `TestClock` 等待
        ///
        /// - Parameters:
        ///   - deadline: 要等到的時間點
        ///   - tolerance: 允許的誤差
        /// - Throws: 等待中的工作被取消時丟出取消錯誤
        func sleep(
            until deadline: TestClock<Swift.Duration>.Instant,
            tolerance: Swift.Duration?
        ) async throws {
            requestedDelays.withValue {
                $0.append(base.now.duration(to: deadline))
            }
            try await base.sleep(until: deadline, tolerance: tolerance)
        }
    }
}

// MARK: - Private Method

private extension OrdersFeatureMergeTimingTests {

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

    /// 建立注入測試時脈與固定識別值、日期的訂單分頁 `TestStore`
    ///
    /// - Parameters:
    ///   - initial: 訂單分頁初始狀態
    ///   - clock: 控制合併轉場 500ms 延遲的時脈
    /// - Returns: 合併轉場測試使用的 store
    static func makeStore(
        initial: OrdersFeature.State,
        clock: any Clock<Duration> = TestClock()
    ) -> TestStoreOf<OrdersFeature> {
        TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.continuousClock = clock
            $0.uuid = .constant(UUID(1))
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
    }
}
