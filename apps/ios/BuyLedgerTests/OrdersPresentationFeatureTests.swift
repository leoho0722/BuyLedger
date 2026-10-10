//
//  OrdersPresentationFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrdersPresentationFeature` 的單元測試，驗證同步方法對目的地與暫存佇列的影響
@MainActor
struct OrdersPresentationFeatureTests {

    /// 使用者觸發的表單直接設進目的地，不經暫存佇列
    @Test
    func present_無目的地_直接設定表單() {
        // Given
        var state = Self.makeState()
        let form = Self.editState()

        // When
        state.present(.edit(form))

        // Then
        #expect(state.destination == .edit(form))
        #expect(state.queue.pendingNotice == nil)
        #expect(state.queue.isFormClosing == false)
    }

    /// 表單關閉動畫結束時，暫存的通知移進目的地並清空暫存
    @Test
    func finishFormClosing_有暫存通知_呈現通知並清空暫存() {
        // Given
        let notice = Self.failureNotice("寫入失敗")
        var state = Self.makeState(
            queue: OrdersPresentationQueue(isFormClosing: true, pendingNotice: notice)
        )

        // When
        state.finishFormClosing()

        // Then
        #expect(state.destination == notice)
        #expect(state.queue.pendingNotice == nil)
        #expect(state.queue.isFormClosing == false)
    }

    /// 關閉動畫結束且沒有暫存通知時，目的地維持清空，只清除關閉旗標
    @Test
    func finishFormClosing_無暫存通知_目的地維持清空() {
        // Given
        var state = Self.makeState(queue: OrdersPresentationQueue(isFormClosing: true))

        // When
        state.finishFormClosing()

        // Then
        #expect(state.destination == nil)
        #expect(state.queue.pendingNotice == nil)
        #expect(state.queue.isFormClosing == false)
    }

    /// 確認表單已就緒時先呈現確認表單，暫存通知繼續等待下一次關閉
    @Test
    func finishFormClosing_確認表單已就緒且有暫存通知_先呈現確認表單() {
        // Given
        let confirmation = Self.editState(id: UUID(1))
        let notice = Self.failureNotice("寫入失敗")
        var state = Self.makeState(
            queue: OrdersPresentationQueue(
                isFormClosing: true,
                isAwaitingMergeConfirmation: true,
                pendingNotice: notice,
                pendingMergeConfirmation: .edit(confirmation)
            )
        )

        // When
        state.finishFormClosing()

        // Then
        #expect(state.destination == .edit(confirmation))
        #expect(state.queue.pendingMergeConfirmation == nil)
        #expect(state.queue.isAwaitingMergeConfirmation == false)
        #expect(state.queue.pendingNotice == notice)
        #expect(state.queue.isFormClosing == false)
    }

    /// 仍在等候合併確認時，關閉動畫結束也不呈現暫存通知
    @Test
    func finishFormClosing_等候合併確認中_不呈現暫存通知() {
        // Given
        let notice = Self.failureNotice("寫入失敗")
        var state = Self.makeState(
            queue: OrdersPresentationQueue(
                isFormClosing: true,
                isAwaitingMergeConfirmation: true,
                pendingNotice: notice
            )
        )

        // When
        state.finishFormClosing()

        // Then
        #expect(state.destination == nil)
        #expect(state.queue.pendingNotice == notice)
        #expect(state.queue.isAwaitingMergeConfirmation)
        #expect(state.queue.isFormClosing == false)
    }

    /// 關閉動畫進行中收到合併確認，確認表單先等候，不搶先設進目的地
    @Test
    func presentMergeConfirmation_關閉中_確認表單等候關閉完成() {
        // Given
        let confirmation = Self.editState(id: UUID(1))
        var state = Self.makeState(
            queue: OrdersPresentationQueue(isFormClosing: true, isAwaitingMergeConfirmation: true)
        )

        // When
        state.presentMergeConfirmation(.edit(confirmation))

        // Then
        #expect(state.destination == nil)
        #expect(state.queue.pendingMergeConfirmation == .edit(confirmation))
        #expect(state.queue.isAwaitingMergeConfirmation)
    }

    /// 關閉已完成時，合併確認表單直接呈現並解除等候
    @Test
    func presentMergeConfirmation_關閉已完成_直接呈現確認表單() {
        // Given
        let confirmation = Self.editState(id: UUID(1))
        var state = Self.makeState(
            queue: OrdersPresentationQueue(isAwaitingMergeConfirmation: true)
        )

        // When
        state.presentMergeConfirmation(.edit(confirmation))

        // Then
        #expect(state.destination == .edit(confirmation))
        #expect(state.queue.isAwaitingMergeConfirmation == false)
        #expect(state.queue.pendingMergeConfirmation == nil)
    }

    /// 刪除的訂單正是表單編輯中的原訂單時，清空表單並標記關閉中
    @Test
    func apply_關閉原訂單的表單_清空目的地並標記關閉中() {
        // Given
        var state = Self.makeState(
            destination: .edit(Self.editState(original: LedgerOrder.fixture(id: "A")))
        )

        // When
        state.apply(OrdersWriteOutcome(closesEditOf: "A"))

        // Then
        #expect(state.destination == nil)
        #expect(state.queue.isFormClosing)
    }

    /// 刪除的不是表單原訂單時，表單維持開啟且不標記關閉中
    @Test
    func apply_關閉其他訂單_表單維持開啟() {
        // Given
        let form = OrdersPresentationFeature.Destination.State.edit(
            Self.editState(original: LedgerOrder.fixture(id: "A"))
        )
        var state = Self.makeState(destination: form)

        // When
        state.apply(OrdersWriteOutcome(closesEditOf: "B"))

        // Then
        #expect(state.destination == form)
        #expect(state.queue.isFormClosing == false)
    }

    /// 新增的主檔選項寫回表單識別值相符的表單，草稿的訂單來源改為新選項
    @Test
    func apply_新增選項且表單識別值相符_寫回來源表單() {
        // Given
        var state = Self.makeState(destination: .edit(Self.editState()))
        let plan = OrderOptionWritePlan(
            formID: UUID(0),
            kind: .orderSource,
            name: "蝦皮",
            flags: .none
        )

        // When
        state.apply(OrdersWriteOutcome(addedOption: plan))

        // Then
        #expect(state.destination?.edit?.draft.orderSource == "蝦皮")
    }

    /// 新增選項的表單識別值不符時，表單內容保持不變
    @Test
    func apply_新增選項且表單識別值不符_表單內容不變() {
        // Given
        let form = OrdersPresentationFeature.Destination.State.edit(Self.editState())
        var state = Self.makeState(destination: form)
        let plan = OrderOptionWritePlan(
            formID: UUID(1),
            kind: .orderSource,
            name: "蝦皮",
            flags: .none
        )

        // When
        state.apply(OrdersWriteOutcome(addedOption: plan))

        // Then
        #expect(state.destination == form)
    }
}
