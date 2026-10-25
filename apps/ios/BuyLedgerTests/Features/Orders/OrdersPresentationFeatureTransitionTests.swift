//
//  OrdersPresentationFeatureTransitionTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrdersPresentationFeature` 的單元測試，以 TestStore 逐步驗證表單關閉、通知暫存與合併確認的轉場
@MainActor
struct OrdersPresentationFeatureTransitionTests {

    /// 驗證表單 sheet 被關閉時，`destination` 清空並把 `isFormClosing` 標為 `true`
    @Test
    func destination_表單關閉_清空目的地並標記關閉中() async {
        // Given
        let initial = OrdersPresentationFeatureTestSupport.makeState(
            destination: .edit(OrdersPresentationFeatureTestSupport.editState())
        )
        let store = TestStore(initialState: initial) {
            OrdersPresentationFeature()
        }

        // When
        await store.send(.destination(.dismiss)) {
            $0.destination = nil
            $0.queue.isFormClosing = true
        }

        // Then
        #expect(store.state.destination == nil)
        #expect(store.state.queue.isFormClosing)
    }

    /// 驗證提示 alert 被關閉時只清空 `destination`，`isFormClosing` 保持 `false`
    @Test
    func destination_提示關閉_只清空目的地() async {
        // Given
        let initial = OrdersPresentationFeatureTestSupport.makeState(
            destination: OrdersPresentationFeatureTestSupport.failureNotice("寫入失敗")
        )
        let store = TestStore(initialState: initial) {
            OrdersPresentationFeature()
        }

        // When
        await store.send(.destination(.dismiss)) {
            $0.destination = nil
        }

        // Then
        #expect(store.state.destination == nil)
        #expect(store.state.queue.isFormClosing == false)
    }

    /// 驗證表單開啟中收到通知時，通知存入 `pendingNotice`，`destination` 的表單維持開啟
    @Test
    func noticeRequested_表單開啟中_暫存通知且表單維持開啟() async {
        // Given
        let notice = OrdersPresentationFeatureTestSupport.failureNotice("寫入失敗")
        let form = OrdersPresentationFeature.Destination.State.edit(
            OrdersPresentationFeatureTestSupport.editState()
        )
        let initial = OrdersPresentationFeatureTestSupport.makeState(destination: form)
        let store = TestStore(initialState: initial) {
            OrdersPresentationFeature()
        }

        // When
        await store.send(.noticeRequested(notice)) {
            $0.queue.pendingNotice = notice
        }

        // Then
        #expect(store.state.destination == form)
    }

    /// 驗證合併候選表單開啟中收到通知時，通知存入 `pendingNotice`，不覆蓋候選表單
    @Test
    func noticeRequested_合併候選開啟中_暫存通知且表單維持開啟() async {
        // Given
        let notice = OrdersPresentationFeatureTestSupport.failureNotice("寫入失敗")
        let merge = OrdersPresentationFeatureTestSupport.mergeDestination()
        let initial = OrdersPresentationFeatureTestSupport.makeState(destination: merge)
        let store = TestStore(initialState: initial) {
            OrdersPresentationFeature()
        }

        // When
        await store.send(.noticeRequested(notice)) {
            $0.queue.pendingNotice = notice
        }

        // Then
        #expect(store.state.destination == merge)
    }

    /// 驗證暫存通知已有一則時再收到新通知，新通知取代舊的「第一則失敗」，`pendingNotice` 只留最新一則
    @Test
    func noticeRequested_表單開啟中已有暫存_只保留最新一則() async {
        // Given
        let second = OrdersPresentationFeatureTestSupport.failureNotice("第二則失敗")
        let initial = OrdersPresentationFeatureTestSupport.makeState(
            destination: .edit(OrdersPresentationFeatureTestSupport.editState()),
            queue: OrdersPresentationQueue(
                pendingNotice: OrdersPresentationFeatureTestSupport.failureNotice("第一則失敗")
            )
        )
        let store = TestStore(initialState: initial) {
            OrdersPresentationFeature()
        }

        // When
        await store.send(.noticeRequested(second)) {
            $0.queue.pendingNotice = second
        }

        // Then
        #expect(store.state.queue.pendingNotice == second)
    }

    /// 驗證表單關閉中收到通知時，通知存入 `pendingNotice`，`destination` 維持 `nil`，表單仍標為關閉中
    @Test
    func noticeRequested_表單關閉中_暫存通知且目的地維持清空() async {
        // Given
        let notice = OrdersPresentationFeatureTestSupport.failureNotice("寫入失敗")
        let initial = OrdersPresentationFeatureTestSupport.makeState(
            queue: OrdersPresentationQueue(isFormClosing: true)
        )
        let store = TestStore(initialState: initial) {
            OrdersPresentationFeature()
        }

        // When
        await store.send(.noticeRequested(notice)) {
            $0.queue.pendingNotice = notice
        }

        // Then
        #expect(store.state.destination == nil)
        #expect(store.state.queue.isFormClosing)
    }

    /// 驗證沒有表單且沒有等候中的轉場時，收到通知直接設為 `destination`，`pendingNotice` 不留下
    @Test
    func noticeRequested_無表單_直接呈現通知() async {
        // Given
        let notice = OrdersPresentationFeatureTestSupport.failureNotice("寫入失敗")
        let store = TestStore(initialState: OrdersPresentationFeatureTestSupport.makeState()) {
            OrdersPresentationFeature()
        }

        // When
        await store.send(.noticeRequested(notice)) {
            $0.destination = notice
        }

        // Then
        #expect(store.state.queue.pendingNotice == nil)
    }

    /// 驗證合併候選完成時清空目的地、標記表單關閉中並等待合併確認，500ms 後送出確認通知
    @Test
    func mergeCandidateCompleted_合併候選完成_清空目的地並於500ms後送出確認() async {
        // Given
        let clock = TestClock()
        let draft = Self.mergeDraft()
        let initial = OrdersPresentationFeatureTestSupport.makeState(
            destination: OrdersPresentationFeatureTestSupport.mergeDestination()
        )
        let store = TestStore(initialState: initial) {
            OrdersPresentationFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }

        // When
        await store.send(.mergeCandidateCompleted(draft: draft, keptPhotos: [])) {
            $0.destination = nil
            $0.queue.isFormClosing = true
            $0.queue.isAwaitingMergeConfirmation = true
        }

        // Then
        await clock.advance(by: .milliseconds(500))
        await store.receive(\.delegate, .mergeConfirmationDue(draft: draft, keptPhotos: []))
        await store.finish()
    }

    /// 驗證 500ms 以前收到通知時先存入 `pendingNotice`，合併確認要等 500ms 到達才送出
    @Test
    func noticeRequested_500ms前到達的通知_暫存且確認尚未送出() async {
        // Given
        let clock = TestClock()
        let draft = Self.mergeDraft()
        let notice = OrdersPresentationFeatureTestSupport.failureNotice("延遲期間失敗")
        let initial = OrdersPresentationFeatureTestSupport.makeState(
            destination: OrdersPresentationFeatureTestSupport.mergeDestination()
        )
        let store = TestStore(initialState: initial) {
            OrdersPresentationFeature()
        } withDependencies: {
            $0.continuousClock = clock
        }
        await store.send(.mergeCandidateCompleted(draft: draft, keptPhotos: [])) {
            $0.destination = nil
            $0.queue.isFormClosing = true
            $0.queue.isAwaitingMergeConfirmation = true
        }

        // When
        await store.send(.noticeRequested(notice)) {
            $0.queue.pendingNotice = notice
        }

        // Then
        await clock.advance(by: .milliseconds(500))
        await store.receive(\.delegate, .mergeConfirmationDue(draft: draft, keptPhotos: []))
        await store.finish()
    }
}

// MARK: - Private Method

private extension OrdersPresentationFeatureTransitionTests {

    /// 以字面值建立來源為 A 與 B 的合併草稿，供轉場輸入與通知內容比對
    ///
    /// - Returns: 合併後的草稿值，作為測試的輸入
    static func mergeDraft() -> OrderMerge.Draft {
        OrderMerge.Draft(
            customer: LedgerCustomer(name: "測試客戶", initials: "TC", tier: .regular),
            orderSource: "測試來源",
            status: .confirmed,
            currency: .twd,
            date: TestDependencies.fixedNow,
            categories: [],
            campaignNames: [],
            paymentMethod: "測試付款方式",
            reconciliationStatus: "",
            isCashOnDelivery: false,
            paymentReceiptStatus: .pending,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            itemCost: 0,
            foreignDomesticShipping: 0,
            internationalShipping: 0,
            domesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            items: [],
            notes: "",
            photos: [],
            mergeSourceIDs: ["A", "B"]
        )
    }
}
