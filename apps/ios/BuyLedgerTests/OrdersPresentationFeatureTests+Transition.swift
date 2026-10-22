//
//  OrdersPresentationFeatureTests+Transition.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrdersPresentationFeatureTests {

    /// 表單 sheet 被關閉時清空目的地，並標記關閉中以等待關閉回呼
    @Test
    func destination_表單關閉_清空目的地並標記關閉中() async {
        // Given
        let initial = Self.makeState(destination: .edit(Self.editState()))
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

    /// 提示 alert 被關閉時只清空目的地，不標記表單關閉中
    @Test
    func destination_提示關閉_只清空目的地() async {
        // Given
        let initial = Self.makeState(destination: Self.failureNotice("寫入失敗"))
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

    /// 表單開啟中收到通知，先暫存且表單維持開啟
    @Test
    func noticeRequested_表單開啟中_暫存通知且表單維持開啟() async {
        // Given
        let notice = Self.failureNotice("寫入失敗")
        let form = OrdersPresentationFeature.Destination.State.edit(Self.editState())
        let initial = Self.makeState(destination: form)
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

    /// 合併候選表單開啟中收到通知，同樣先暫存而不覆蓋候選表單
    @Test
    func noticeRequested_合併候選開啟中_暫存通知且表單維持開啟() async {
        // Given
        let notice = Self.failureNotice("寫入失敗")
        let merge = Self.mergeDestination()
        let initial = Self.makeState(destination: merge)
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

    /// 表單開啟中已有暫存通知時，新通知取代舊通知，只保留最新一則
    @Test
    func noticeRequested_表單開啟中已有暫存_只保留最新一則() async {
        // Given
        let second = Self.failureNotice("第二則失敗")
        let initial = Self.makeState(
            destination: .edit(Self.editState()),
            queue: OrdersPresentationQueue(pendingNotice: Self.failureNotice("第一則失敗"))
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

    /// 表單關閉中收到通知，暫存且目的地維持清空，等關閉動畫結束才呈現
    @Test
    func noticeRequested_表單關閉中_暫存通知且目的地維持清空() async {
        // Given
        let notice = Self.failureNotice("寫入失敗")
        let initial = Self.makeState(queue: OrdersPresentationQueue(isFormClosing: true))
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

    /// 沒有表單且沒有等候中的轉場時，通知直接呈現在目的地
    @Test
    func noticeRequested_無表單_直接呈現通知() async {
        // Given
        let notice = Self.failureNotice("寫入失敗")
        let store = TestStore(initialState: Self.makeState()) {
            OrdersPresentationFeature()
        }

        // When
        await store.send(.noticeRequested(notice)) {
            $0.destination = notice
        }

        // Then
        #expect(store.state.queue.pendingNotice == nil)
    }

    /// 合併候選完成時清空目的地並標記轉場，500ms 到達後送出合併確認
    @Test
    func mergeCandidateCompleted_合併候選完成_清空目的地並於500ms後送出確認() async {
        // Given
        let clock = TestClock()
        let draft = Self.mergeDraft()
        let initial = Self.makeState(destination: Self.mergeDestination())
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

    /// 500ms 以前到達的通知先暫存，合併確認要等到 500ms 才送出
    @Test
    func noticeRequested_500ms前到達的通知_暫存且確認尚未送出() async {
        // Given
        let clock = TestClock()
        let draft = Self.mergeDraft()
        let notice = Self.failureNotice("延遲期間失敗")
        let initial = Self.makeState(destination: Self.mergeDestination())
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
        await clock.advance(by: .milliseconds(499))

        // When
        await store.send(.noticeRequested(notice)) {
            $0.queue.pendingNotice = notice
        }

        // Then
        await clock.advance(by: .milliseconds(1))
        await store.receive(\.delegate, .mergeConfirmationDue(draft: draft, keptPhotos: []))
        await store.finish()
    }
}
