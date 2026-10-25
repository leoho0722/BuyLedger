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

/// `CampaignPresentationQueue` 的單元測試，涵蓋表單開啟、關閉中與已關閉三種狀態下的通知呈現
struct CampaignPresentationQueueTests {

    /// 驗證表單已關閉時，通知直接設進目的地，不經暫存
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

    /// 驗證表單已關閉且另一個提示顯示中時，新通知直接取代原提示
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

    /// 驗證表單開啟中時，通知先暫存，不取代使用者正在編輯的表單，表單維持開啟
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

    /// 驗證表單關閉中時，即使目的地已清空，通知也先暫存，避免設進正在關閉的 sheet
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

    /// 驗證表單關閉中連續收到兩則通知時，暫存只保留最新一則
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

    /// 驗證儲存被接受時標記表單關閉中，暫存通知為空
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

    /// 驗證關閉事件送達時目的地仍是表單 (取消無變更、確認捨棄、下滑關閉)，標記關閉中
    @Test
    func markFormClosing_目的地仍是表單_標記關閉中() {
        // Given
        var queue = CampaignPresentationQueue()

        // When
        queue.markFormClosing(dismissing: Self.openForm)

        // Then
        #expect(queue.isFormClosing)
    }

    /// 驗證關閉的是提示而不是表單時，不進入關閉中
    @Test
    func markFormClosing_目的地是提示_維持已關閉() {
        // Given
        var queue = CampaignPresentationQueue()

        // When
        queue.markFormClosing(dismissing: Self.firstNotice)

        // Then
        #expect(queue.isFormClosing == false)
    }

    /// 驗證目的地已清空 (儲存後 sheet 回報關閉) 時，不重複標記也不誤標
    @Test
    func markFormClosing_目的地已清空_維持已關閉() {
        // Given
        var queue = CampaignPresentationQueue()

        // When
        queue.markFormClosing(dismissing: nil)

        // Then
        #expect(queue.isFormClosing == false)
    }

    /// 驗證 sheet 關閉動畫結束時，暫存的通知移進目的地並清空暫存
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

    /// 驗證沒有暫存通知時，只清除關閉中旗標，目的地保持原樣
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

    /// 驗證暫存通知已移出後再次收到關閉回呼時，目的地維持呈現中的提示，不被清空
    @Test
    func finishFormClosing_通知已移出後再次呼叫_維持目的地原提示() {
        // Given
        var queue = CampaignPresentationQueue()
        var destination: CampaignPresentationFeature.Destination.State? = Self.firstNotice

        // When
        queue.finishFormClosing(into: &destination)

        // Then
        #expect(destination == Self.firstNotice)
        #expect(queue.pendingNotice == nil)
    }

    /// 驗證關閉回呼前又開了新表單時，暫存的通知繼續等到那個表單關閉
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
                TextState("orders.list.label.operationFailed")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("orders.merge.label.ok")
                }
            } message: {
                TextState("campaigns.general.message.campaignSavedTry")
            }
        )
    }

    /// 第二則測試通知，內容與第一則不同
    static var secondNotice: CampaignPresentationFeature.Destination.State {
        .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState("orders.list.label.operationFailed")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("orders.merge.label.ok")
                }
            } message: {
                TextState("campaigns.general.message.campaignSettledTry")
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
