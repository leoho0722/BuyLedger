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

/// `CampaignPresentationQueue` 的單元測試，涵蓋目的地開啟、表單關閉中與可呈現時的通知流程
struct CampaignPresentationQueueTests {

    /// 驗證沒有目的地且表單未關閉時，通知直接設進獨立通知狀態，不經暫存
    @Test
    func present_沒有目的地_直接呈現通知() {
        // Given
        var queue = CampaignPresentationQueue()
        let destination: CampaignPresentationFeature.Destination.State? = nil
        var notice: AlertState<CampaignPresentationFeature.Destination.Alert>?

        // When
        queue.present(Self.firstNotice, while: destination, into: &notice)

        // Then
        #expect(notice == Self.firstNotice)
        #expect(queue.pendingNotice == nil)
        #expect(queue.isFormClosing == false)
    }

    /// 驗證沒有目的地且另一個提示顯示中時，新通知直接取代原提示
    @Test
    func present_沒有目的地且提示顯示中_直接取代原提示() {
        // Given
        var queue = CampaignPresentationQueue()
        let destination: CampaignPresentationFeature.Destination.State? = nil
        var notice: AlertState<CampaignPresentationFeature.Destination.Alert>? = Self.firstNotice

        // When
        queue.present(Self.secondNotice, while: destination, into: &notice)

        // Then
        #expect(notice == Self.secondNotice)
        #expect(queue.pendingNotice == nil)
    }

    /// 驗證表單開啟中時，通知先暫存，不取代使用者正在編輯的表單，表單維持開啟
    @Test
    func present_表單開啟中_暫存通知且表單維持開啟() {
        // Given
        var queue = CampaignPresentationQueue()
        let destination: CampaignPresentationFeature.Destination.State? = Self.openForm
        var notice: AlertState<CampaignPresentationFeature.Destination.Alert>?

        // When
        queue.present(Self.firstNotice, while: destination, into: &notice)

        // Then
        #expect(notice == nil)
        #expect(queue.pendingNotice == Self.firstNotice)
        #expect(queue.isFormClosing == false)
    }

    /// 驗證確認 alert 開啟中收到通知時留在佇列，不進入通知狀態
    @Test
    func present_確認框開啟中_暫存通知且確認框保留() {
        // Given
        var queue = CampaignPresentationQueue()
        let destination = CampaignFeatureTestSupport.deletionAlert(id: "C1", name: "開團")
        var notice: AlertState<CampaignPresentationFeature.Destination.Alert>?

        // When
        queue.present(Self.firstNotice, while: destination, into: &notice)

        // Then
        #expect(notice == nil)
        #expect(queue.pendingNotice == Self.firstNotice)
        #expect(queue.isFormClosing == false)
    }

    /// 驗證表單關閉中時，即使目的地已清空，通知也先暫存，避免設進正在關閉的 sheet
    @Test
    func present_表單關閉中_暫存通知而不設進目的地() {
        // Given
        var queue = CampaignPresentationQueue()
        queue.isFormClosing = true
        let destination: CampaignPresentationFeature.Destination.State? = nil
        var notice: AlertState<CampaignPresentationFeature.Destination.Alert>?

        // When
        queue.present(Self.firstNotice, while: destination, into: &notice)

        // Then
        #expect(notice == nil)
        #expect(queue.pendingNotice == Self.firstNotice)
        #expect(queue.isFormClosing)
    }

    /// 驗證表單關閉中連續收到兩則通知時，暫存只保留最新一則
    @Test
    func present_關閉中連續兩則_只保留最新一則() {
        // Given
        var queue = CampaignPresentationQueue()
        queue.isFormClosing = true
        let destination: CampaignPresentationFeature.Destination.State? = nil
        var notice: AlertState<CampaignPresentationFeature.Destination.Alert>?
        queue.pendingNotice = Self.firstNotice

        // When
        queue.present(Self.secondNotice, while: destination, into: &notice)

        // Then
        #expect(queue.pendingNotice == Self.secondNotice)
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

    /// 驗證目的地為空時，不進入表單關閉中
    @Test
    func markFormClosing_目的地為空_維持已關閉() {
        // Given
        var queue = CampaignPresentationQueue()

        // When
        queue.markFormClosing(dismissing: nil)

        // Then
        #expect(queue.isFormClosing == false)
    }

    /// 驗證 sheet 關閉動畫結束時，暫存的通知移進通知狀態並清空暫存
    @Test
    func finishFormClosing_有暫存通知_移進通知並清空暫存() {
        // Given
        var queue = CampaignPresentationQueue()
        queue.isFormClosing = true
        queue.pendingNotice = Self.firstNotice
        var notice: AlertState<CampaignPresentationFeature.Destination.Alert>?
        let destination: CampaignPresentationFeature.Destination.State? = nil

        // When
        queue.finishFormClosing(into: &notice, while: destination)

        // Then
        #expect(notice == Self.firstNotice)
        #expect(queue.pendingNotice == nil)
        #expect(queue.isFormClosing == false)
    }

    /// 驗證沒有暫存通知時，只清除關閉中旗標，通知狀態保持原樣
    @Test
    func finishFormClosing_沒有暫存通知_只清除關閉旗標() {
        // Given
        var queue = CampaignPresentationQueue()
        queue.isFormClosing = true
        var notice: AlertState<CampaignPresentationFeature.Destination.Alert>?
        let destination: CampaignPresentationFeature.Destination.State? = nil

        // When
        queue.finishFormClosing(into: &notice, while: destination)

        // Then
        #expect(notice == nil)
        #expect(queue.pendingNotice == nil)
        #expect(queue.isFormClosing == false)
    }

    /// 驗證暫存通知已移出後再次收到關閉回呼時，通知維持呈現，不被清空
    @Test
    func finishFormClosing_通知已移出後再次呼叫_維持原通知() {
        // Given
        var queue = CampaignPresentationQueue()
        let destination: CampaignPresentationFeature.Destination.State? = nil
        var notice: AlertState<CampaignPresentationFeature.Destination.Alert>? = Self.firstNotice

        // When
        queue.finishFormClosing(into: &notice, while: destination)

        // Then
        #expect(notice == Self.firstNotice)
        #expect(queue.pendingNotice == nil)
    }

    /// 驗證關閉回呼前又開了新表單時，暫存的通知繼續等到那個表單關閉
    @Test
    func finishFormClosing_目的地又開了新表單_暫存通知繼續等待() {
        // Given
        var queue = CampaignPresentationQueue()
        queue.isFormClosing = true
        queue.pendingNotice = Self.firstNotice
        let destination: CampaignPresentationFeature.Destination.State? = Self.openForm
        var notice: AlertState<CampaignPresentationFeature.Destination.Alert>?

        // When
        queue.finishFormClosing(into: &notice, while: destination)

        // Then
        #expect(notice == nil)
        #expect(queue.pendingNotice == Self.firstNotice)
        #expect(queue.isFormClosing == false)
    }

    /// 驗證表單關閉回呼遇到確認 alert 時，暫存通知繼續等待 alert 關閉
    @Test
    func finishFormClosing_確認框仍開啟_暫存通知繼續等待() {
        // Given
        var queue = CampaignPresentationQueue()
        queue.isFormClosing = true
        queue.pendingNotice = Self.firstNotice
        let destination = CampaignFeatureTestSupport.deletionAlert(id: "C1", name: "開團")
        var notice: AlertState<CampaignPresentationFeature.Destination.Alert>?

        // When
        queue.finishFormClosing(into: &notice, while: destination)

        // Then
        #expect(notice == nil)
        #expect(queue.pendingNotice == Self.firstNotice)
        #expect(queue.isFormClosing == false)
    }

    /// 驗證目的地清空後，暫存通知移進通知狀態並清空佇列
    @Test
    func presentPendingNotice_目的地已關閉_呈現通知並清空佇列() {
        // Given
        var queue = CampaignPresentationQueue()
        queue.pendingNotice = Self.firstNotice
        var notice: AlertState<CampaignPresentationFeature.Destination.Alert>?

        // When
        queue.presentPendingNotice(into: &notice, while: nil)

        // Then
        #expect(notice == Self.firstNotice)
        #expect(queue.pendingNotice == nil)
        #expect(queue.isFormClosing == false)
    }
}

// MARK: - Private Method

private extension CampaignPresentationQueueTests {

    /// 提示「操作失敗」的 alert，內文為開團儲存失敗
    static var firstNotice: AlertState<CampaignPresentationFeature.Destination.Alert> {
        AlertState {
            TextState("orders.list.label.operationFailed")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("orders.merge.label.ok")
            }
        } message: {
            TextState("campaigns.general.message.campaignSavedTry")
        }
    }

    /// 第二則測試通知，內容與第一則不同
    static var secondNotice: AlertState<CampaignPresentationFeature.Destination.Alert> {
        AlertState {
            TextState("orders.list.label.operationFailed")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("orders.merge.label.ok")
            }
        } message: {
            TextState("campaigns.general.message.campaignSettledTry")
        }
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
