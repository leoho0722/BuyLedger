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

/// `OrdersPresentationFeature` 的單元測試，直接呼叫同步方法，斷言目的地與暫存佇列的變化
struct OrdersPresentationFeatureTests {

    /// 驗證目的地為空時，`present` 直接設定表單，不經暫存佇列，`pendingNotice` 為 `nil`、`isFormClosing` 為 `false`
    @Test
    func present_無目的地_直接設定表單() {
        // Given
        var state = OrdersPresentationFeatureTestSupport.makeState()
        let form = OrdersPresentationFeatureTestSupport.editState()

        // When
        state.present(.edit(form))

        // Then
        #expect(state.destination == .edit(form))
        #expect(state.queue.pendingNotice == nil)
        #expect(state.queue.isFormClosing == false)
    }

    /// 驗證表單關閉動畫結束時，暫存的通知移進 `destination` 呈現，`pendingNotice` 清空，`isFormClosing` 回到 `false`
    @Test
    func finishFormClosing_有暫存通知_呈現通知並清空暫存() {
        // Given
        let notice = OrdersPresentationFeatureTestSupport.failureNotice("寫入失敗")
        var state = OrdersPresentationFeatureTestSupport.makeState(
            queue: OrdersPresentationQueue(isFormClosing: true, pendingNotice: notice)
        )

        // When
        state.finishFormClosing()

        // Then
        #expect(state.destination == notice)
        #expect(state.queue.pendingNotice == nil)
        #expect(state.queue.isFormClosing == false)
    }

    /// 驗證關閉動畫結束且沒有暫存通知時，`destination` 維持 `nil`，只把 `isFormClosing` 改為 `false`
    @Test
    func finishFormClosing_無暫存通知_目的地維持清空() {
        // Given
        var state = OrdersPresentationFeatureTestSupport.makeState(
            queue: OrdersPresentationQueue(isFormClosing: true)
        )

        // When
        state.finishFormClosing()

        // Then
        #expect(state.destination == nil)
        #expect(state.queue.pendingNotice == nil)
        #expect(state.queue.isFormClosing == false)
    }

    /// 驗證關閉動畫結束且合併確認表單已就緒時，先把確認表單設為 `destination`，暫存通知繼續留在 `pendingNotice`
    @Test
    func finishFormClosing_確認表單已就緒且有暫存通知_先呈現確認表單() {
        // Given
        let confirmation = OrdersPresentationFeatureTestSupport.editState(id: UUID(1))
        let notice = OrdersPresentationFeatureTestSupport.failureNotice("寫入失敗")
        var state = OrdersPresentationFeatureTestSupport.makeState(
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

    /// 驗證仍在等候合併確認時，關閉動畫結束也不呈現暫存通知，`destination` 維持 `nil`，`pendingNotice` 保留
    @Test
    func finishFormClosing_等候合併確認中_不呈現暫存通知() {
        // Given
        let notice = OrdersPresentationFeatureTestSupport.failureNotice("寫入失敗")
        var state = OrdersPresentationFeatureTestSupport.makeState(
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

    /// 驗證關閉動畫進行中呈現合併確認時，先暫存確認表單，`destination` 維持 `nil`
    @Test
    func presentMergeConfirmation_關閉中_確認表單等候關閉完成() {
        // Given
        let confirmation = OrdersPresentationFeatureTestSupport.editState(id: UUID(1))
        var state = OrdersPresentationFeatureTestSupport.makeState(
            queue: OrdersPresentationQueue(isFormClosing: true, isAwaitingMergeConfirmation: true)
        )

        // When
        state.presentMergeConfirmation(.edit(confirmation))

        // Then
        #expect(state.destination == nil)
        #expect(state.queue.pendingMergeConfirmation == .edit(confirmation))
        #expect(state.queue.isAwaitingMergeConfirmation)
    }

    /// 驗證關閉已完成時呈現合併確認，立即開啟確認表單並結束等待
    @Test
    func presentMergeConfirmation_關閉已完成_直接呈現確認表單() {
        // Given
        let confirmation = OrdersPresentationFeatureTestSupport.editState(id: UUID(1))
        var state = OrdersPresentationFeatureTestSupport.makeState(
            queue: OrdersPresentationQueue(isAwaitingMergeConfirmation: true)
        )

        // When
        state.presentMergeConfirmation(.edit(confirmation))

        // Then
        #expect(state.destination == .edit(confirmation))
        #expect(state.queue.isAwaitingMergeConfirmation == false)
        #expect(state.queue.pendingMergeConfirmation == nil)
    }

    /// 驗證寫入結果要求關閉的訂單 A 正是表單編輯中的原訂單時，清空 `destination` 並標記關閉中
    @Test
    func apply_關閉原訂單的表單_清空目的地並標記關閉中() {
        // Given
        var state = OrdersPresentationFeatureTestSupport.makeState(
            destination: .edit(
                OrdersPresentationFeatureTestSupport.editState(
                    original: LedgerOrder.fixture(id: "A")
                )
            )
        )

        // When
        state.apply(OrdersWriteOutcome(closesEditOf: "A"))

        // Then
        #expect(state.destination == nil)
        #expect(state.queue.isFormClosing)
    }

    /// 驗證寫入結果要求關閉的訂單 B 不是表單原訂單 A 時，表單維持開啟，`isFormClosing` 保持 `false`
    @Test
    func apply_關閉其他訂單_表單維持開啟() {
        // Given
        let form = OrdersPresentationFeature.Destination.State.edit(
            OrdersPresentationFeatureTestSupport.editState(original: LedgerOrder.fixture(id: "A"))
        )
        var state = OrdersPresentationFeatureTestSupport.makeState(destination: form)

        // When
        state.apply(OrdersWriteOutcome(closesEditOf: "B"))

        // Then
        #expect(state.destination == form)
        #expect(state.queue.isFormClosing == false)
    }

    /// 驗證新增選項的表單識別值與目前表單相符時，選項寫回該表單，草稿的訂單來源改為新選項「蝦皮」
    @Test
    func applyOptionAddition_新增選項且表單識別值相符_寫回來源表單() {
        // Given
        var state = OrdersPresentationFeatureTestSupport.makeState(
            destination: .edit(OrdersPresentationFeatureTestSupport.editState())
        )
        let request = LookupAdditionRequest(
            id: UUID(0),
            kind: .orderSource,
            name: "蝦皮",
            flags: .none
        )

        // When
        _ = state.applyOptionAddition(request, isStored: true)

        // Then
        #expect(state.destination?.edit?.draft.orderSource == "蝦皮")
    }

    /// 驗證新增選項的表單識別值與目前表單不符時，表單內容維持原樣，不寫回新選項
    @Test
    func applyOptionAddition_新增選項且表單識別值不符_表單內容不變() {
        // Given
        let form = OrdersPresentationFeature.Destination.State.edit(
            OrdersPresentationFeatureTestSupport.editState()
        )
        var state = OrdersPresentationFeatureTestSupport.makeState(destination: form)
        let request = LookupAdditionRequest(
            id: UUID(1),
            kind: .orderSource,
            name: "蝦皮",
            flags: .none
        )

        // When
        _ = state.applyOptionAddition(request, isStored: true)

        // Then
        #expect(state.destination == form)
    }
}
