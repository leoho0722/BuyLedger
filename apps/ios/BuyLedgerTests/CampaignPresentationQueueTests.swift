//
//  CampaignPresentationQueueTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 驗證開團通知佇列的三態：表單開啟、關閉中、已關閉
struct CampaignPresentationQueueTests {

    /// 表單已關閉時，通知直接設進目的地，不經暫存
    @Test
    func present_表單已關閉_直接設進目的地() {
        // Given
        var queue = CampaignPresentationQueue()
        var destination: CampaignPresentationFeature.Destination.State?

        // When
        queue.present(Self.firstNotice, in: &destination)

        // Then
        #expect(destination == Self.firstNotice)
        #expect(queue.pendingNotice == nil)
        #expect(queue.isFormClosing == false)
    }

    /// 表單已關閉且另一個提示顯示中時，新通知直接取代它
    @Test
    func present_表單已關閉且提示顯示中_直接取代原提示() {
        // Given
        var queue = CampaignPresentationQueue()
        var destination: CampaignPresentationFeature.Destination.State? = Self.firstNotice

        // When
        queue.present(Self.secondNotice, in: &destination)

        // Then
        #expect(destination == Self.secondNotice)
        #expect(queue.pendingNotice == nil)
    }

    /// 表單開啟中，通知先暫存，不取代使用者正在編輯的表單
    @Test
    func present_表單開啟中_暫存通知且表單維持開啟() {
        // Given
        var queue = CampaignPresentationQueue()
        var destination: CampaignPresentationFeature.Destination.State? = Self.openForm

        // When
        queue.present(Self.firstNotice, in: &destination)

        // Then
        #expect(destination == Self.openForm)
        #expect(queue.pendingNotice == Self.firstNotice)
        #expect(queue.isFormClosing == false)
    }

    /// 表單關閉中，目的地已清空也先暫存通知，避免設進正在關閉的 sheet
    @Test
    func present_表單關閉中_暫存通知而不設進目的地() {
        // Given
        var queue = CampaignPresentationQueue()
        queue.isFormClosing = true
        var destination: CampaignPresentationFeature.Destination.State?

        // When
        queue.present(Self.firstNotice, in: &destination)

        // Then
        #expect(destination == nil)
        #expect(queue.pendingNotice == Self.firstNotice)
        #expect(queue.isFormClosing)
    }

    /// 表單關閉中連續到達兩則通知，只保留最新一則
    @Test
    func present_關閉中連續兩則_只保留最新一則() {
        // Given
        var queue = CampaignPresentationQueue()
        queue.isFormClosing = true
        var destination: CampaignPresentationFeature.Destination.State?
        queue.pendingNotice = Self.firstNotice

        // When
        queue.present(Self.secondNotice, in: &destination)

        // Then
        #expect(queue.pendingNotice == Self.secondNotice)
        #expect(destination == nil)
    }

    /// 父層接受儲存後標記表單關閉中
    @Test
    func beginFormClosing_父層接受儲存_標記關閉中() {
        // Given
        var queue = CampaignPresentationQueue()

        // When
        queue.beginFormClosing()

        // Then
        #expect(queue.isFormClosing)
        #expect(queue.pendingNotice == nil)
    }

    /// 關閉事件送達時目的地仍是表單 (取消無變更、確認捨棄、下滑關閉)，標記關閉中
    @Test
    func markFormClosing_目的地仍是表單_標記關閉中() {
        // Given
        var queue = CampaignPresentationQueue()

        // When
        queue.markFormClosing(dismissing: Self.openForm)

        // Then
        #expect(queue.isFormClosing)
    }

    /// 關閉的是提示而不是表單時，不進入關閉中
    @Test
    func markFormClosing_目的地是提示_維持已關閉() {
        // Given
        var queue = CampaignPresentationQueue()

        // When
        queue.markFormClosing(dismissing: Self.firstNotice)

        // Then
        #expect(queue.isFormClosing == false)
    }

    /// 目的地已經清空 (儲存後 sheet 回報關閉) 時，不重複標記也不誤標
    @Test
    func markFormClosing_目的地已清空_維持已關閉() {
        // Given
        var queue = CampaignPresentationQueue()

        // When
        queue.markFormClosing(dismissing: nil)

        // Then
        #expect(queue.isFormClosing == false)
    }

    /// sheet 關閉動畫結束後，暫存的通知移進目的地並清空暫存
    @Test
    func finishFormClosing_有暫存通知_移進目的地並清空暫存() {
        // Given
        var queue = CampaignPresentationQueue()
        queue.isFormClosing = true
        queue.pendingNotice = Self.firstNotice
        var destination: CampaignPresentationFeature.Destination.State?

        // When
        queue.finishFormClosing(into: &destination)

        // Then
        #expect(destination == Self.firstNotice)
        #expect(queue.pendingNotice == nil)
        #expect(queue.isFormClosing == false)
    }

    /// 沒有暫存通知時，只清除關閉旗標，目的地保持原樣
    @Test
    func finishFormClosing_沒有暫存通知_只清除關閉旗標() {
        // Given
        var queue = CampaignPresentationQueue()
        queue.isFormClosing = true
        var destination: CampaignPresentationFeature.Destination.State?

        // When
        queue.finishFormClosing(into: &destination)

        // Then
        #expect(destination == nil)
        #expect(queue.pendingNotice == nil)
        #expect(queue.isFormClosing == false)
    }

    /// 通知移出後再次收到關閉回呼，不會把已關閉的通知重新設回目的地
    @Test
    func finishFormClosing_通知已移出後再次呼叫_目的地維持清空() {
        // Given
        var queue = CampaignPresentationQueue()
        var destination: CampaignPresentationFeature.Destination.State?

        // When
        queue.finishFormClosing(into: &destination)

        // Then
        #expect(destination == nil)
        #expect(queue.pendingNotice == nil)
    }

    /// 關閉回呼前又開了新的表單時，暫存的通知繼續等到那個表單關閉
    @Test
    func finishFormClosing_目的地又開了新表單_暫存通知繼續等待() {
        // Given
        var queue = CampaignPresentationQueue()
        queue.isFormClosing = true
        queue.pendingNotice = Self.firstNotice
        var destination: CampaignPresentationFeature.Destination.State? = Self.openForm

        // When
        queue.finishFormClosing(into: &destination)

        // Then
        #expect(destination == Self.openForm)
        #expect(queue.pendingNotice == Self.firstNotice)
        #expect(queue.isFormClosing == false)
    }
}

// MARK: - Private Method

private extension CampaignPresentationQueueTests {

    /// 提示「操作失敗」的 alert，內文為開團儲存失敗
    static var firstNotice: CampaignPresentationFeature.Destination.State {
        .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState("操作失敗")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("知道了")
                }
            } message: {
                TextState("開團儲存失敗，請稍後再試。")
            }
        )
    }

    /// 第二則測試通知，內容與第一則不同
    static var secondNotice: CampaignPresentationFeature.Destination.State {
        .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState("操作失敗")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("知道了")
                }
            } message: {
                TextState("結團失敗，請稍後再試。")
            }
        )
    }

    /// 開啟中的新增表單
    static var openForm: CampaignPresentationFeature.Destination.State {
        .edit(
            CampaignEditFeature.State(
                id: UUID(0),
                currentDate: Date(timeIntervalSince1970: 0),
                reminderTimestamp: Date(timeIntervalSince1970: 0)
            )
        )
    }
}
