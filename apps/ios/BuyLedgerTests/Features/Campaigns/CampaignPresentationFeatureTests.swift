//
//  CampaignPresentationFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignPresentationFeature` 的單元測試，直接呼叫 `State` 方法，並以 TestStore 驗證目的地事件、一次性通知與系統設定的 `Action` 處理
struct CampaignPresentationFeatureTests {

    /// 驗證沒有呈現中的目的地時，表單直接設進目的地，不經暫存佇列
    @Test
    func present_沒有呈現中的目的地_直接設進表單() {
        // Given
        var state = CampaignPresentationFeature.State()

        // When
        state.present(Self.form)

        // Then
        #expect(state.destination == Self.form)
        #expect(state.queue.pendingNotice == nil)
        #expect(state.queue.isFormClosing == false)
    }

    /// 驗證 sheet 關閉動畫結束時，暫存的通知移進目的地，並清除關閉中旗標
    @Test
    func finishFormClosing_關閉中有暫存通知_通知移進目的地() {
        // Given
        var state = CampaignPresentationFeature.State()
        state.queue.isFormClosing = true
        state.queue.pendingNotice = Self.notice

        // When
        state.finishFormClosing()

        // Then
        #expect(state.destination == Self.notice)
        #expect(state.queue.pendingNotice == nil)
        #expect(state.queue.isFormClosing == false)
    }

    /// 驗證表單開啟中儲存被接受時，目的地清空並標記關閉中，且不留暫存通知
    @Test
    func closeFormForSave_表單開啟中_清空目的地並標記關閉中() {
        // Given
        var state = CampaignPresentationFeature.State()
        state.destination = Self.form

        // When
        state.closeFormForSave()

        // Then
        #expect(state.destination == nil)
        #expect(state.queue.isFormClosing)
        #expect(state.queue.pendingNotice == nil)
    }

    /// 驗證表單開啟中顯示名稱重複時，重名原因寫進表單，表單維持開啟，且不影響通知佇列
    @Test
    func showNameConflict_表單開啟中_寫入重名原因且表單維持開啟() {
        // Given
        var state = CampaignPresentationFeature.State()
        state.destination = Self.form
        var expectedForm = Self.formState
        expectedForm.nameConflictMessage = "campaigns.edit.message.anotherCampaignAlready"

        // When
        state.showNameConflict()

        // Then
        #expect(state.destination == .edit(expectedForm))
        #expect(state.queue.isFormClosing == false)
        #expect(state.queue.pendingNotice == nil)
    }

    /// 驗證表單被取消或下滑關閉時，目的地清空並標記關閉中
    @Test
    @MainActor
    func destination_關閉表單_清空目的地並標記關閉中() async {
        // Given
        var initial = CampaignPresentationFeature.State()
        initial.destination = Self.form
        let store = TestStore(initialState: initial) {
            CampaignPresentationFeature()
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

    /// 驗證提示 alert 被關閉時，只清空目的地，不標記表單關閉中
    @Test
    @MainActor
    func destination_關閉提示_只清空目的地() async {
        // Given
        var initial = CampaignPresentationFeature.State()
        initial.destination = Self.notice
        let store = TestStore(initialState: initial) {
            CampaignPresentationFeature()
        }

        // When
        await store.send(.destination(.dismiss)) {
            $0.destination = nil
        }

        // Then
        #expect(store.state.destination == nil)
        #expect(store.state.queue.isFormClosing == false)
    }

    /// 驗證表單以有效名稱送出時，會送出完整的儲存請求，表單本身維持開啟
    @Test
    @MainActor
    func destination_表單送出名稱_轉交儲存意圖() async {
        // Given
        var editState = Self.formState
        editState.draft.name = "春季團"
        let request = CampaignEditFeature.SaveRequest(
            original: nil,
            name: "春季團",
            draft: editState.draft
        )
        var initial = CampaignPresentationFeature.State()
        initial.destination = .edit(editState)
        let store = TestStore(initialState: initial) {
            CampaignPresentationFeature()
        }

        // When
        await store.send(.destination(.presented(.edit(.delegate(.saveRequested(request))))))

        // Then
        await store.receive(\.delegate.saveRequested, request)
        #expect(store.state.destination == .edit(editState))
    }

    /// 驗證刪除確認按下確定後，會送出要刪除的開團識別值，提示隨即關閉
    @Test
    @MainActor
    func destination_確認刪除_轉交刪除意圖() async {
        // Given
        var initial = CampaignPresentationFeature.State()
        initial.destination = Self.notice
        let store = TestStore(initialState: initial) {
            CampaignPresentationFeature()
        }

        // When
        await store.send(.destination(.presented(.alert(.confirmDelete("C1"))))) {
            $0.destination = nil
        }

        // Then
        await store.receive(\.delegate.deleteConfirmed, "C1")
        #expect(store.state.destination == nil)
    }

    /// 驗證結團確認按下確定後，會送出要結團的開團識別值，提示隨即關閉
    @Test
    @MainActor
    func destination_確認結團_轉交結團意圖() async {
        // Given
        var initial = CampaignPresentationFeature.State()
        initial.destination = Self.notice
        let store = TestStore(initialState: initial) {
            CampaignPresentationFeature()
        }

        // When
        await store.send(.destination(.presented(.alert(.confirmSettle("C1"))))) {
            $0.destination = nil
        }

        // Then
        await store.receive(\.delegate.settleConfirmed, "C1")
        #expect(store.state.destination == nil)
    }

    /// 驗證權限提示按下前往設定時，以注入的服務開啟系統設定一次，提示隨即關閉
    @Test
    @MainActor
    func destination_前往設定_呼叫開啟設定服務() async {
        // Given
        let openCount = LockIsolated(0)
        var initial = CampaignPresentationFeature.State()
        initial.destination = Self.notice
        let store = TestStore(initialState: initial) {
            CampaignPresentationFeature()
        } withDependencies: {
            $0.openSettingsService.open = {
                openCount.withValue {
                    $0 += 1
                }
            }
        }

        // When
        await store.send(.destination(.presented(.alert(.openSettings)))) {
            $0.destination = nil
        }

        // Then
        await store.finish()
        #expect(openCount.value == 1)
    }

    /// 驗證表單開啟中收到通知時，通知先暫存，正在編輯的表單保留
    @Test
    @MainActor
    func noticeRequested_表單開啟中_暫存通知且保留表單() async {
        // Given
        var initial = CampaignPresentationFeature.State()
        initial.destination = Self.form
        let store = TestStore(initialState: initial) {
            CampaignPresentationFeature()
        }

        // When
        await store.send(.noticeRequested(Self.notice)) {
            $0.queue.pendingNotice = Self.notice
        }

        // Then
        #expect(store.state.destination == Self.form)
        #expect(store.state.queue.isFormClosing == false)
    }

    /// 驗證表單關閉中收到通知時，通知先暫存，目的地維持空白
    @Test
    @MainActor
    func noticeRequested_表單關閉中_暫存通知且目的地維持空白() async {
        // Given
        var initial = CampaignPresentationFeature.State()
        initial.queue.isFormClosing = true
        let store = TestStore(initialState: initial) {
            CampaignPresentationFeature()
        }

        // When
        await store.send(.noticeRequested(Self.notice)) {
            $0.queue.pendingNotice = Self.notice
        }

        // Then
        #expect(store.state.destination == nil)
        #expect(store.state.queue.isFormClosing)
    }

    /// 驗證沒有表單且不在關閉中時，通知直接設進目的地
    @Test
    @MainActor
    func noticeRequested_沒有表單_直接呈現通知() async {
        // Given
        let store = TestStore(initialState: CampaignPresentationFeature.State()) {
            CampaignPresentationFeature()
        }

        // When
        await store.send(.noticeRequested(Self.notice)) {
            $0.destination = Self.notice
        }

        // Then
        #expect(store.state.queue.pendingNotice == nil)
        #expect(store.state.queue.isFormClosing == false)
    }
}

// MARK: - Private Method

private extension CampaignPresentationFeatureTests {

    /// 新增表單的狀態，識別值與時間皆為固定值
    static var formState: CampaignEditFeature.State {
        CampaignEditFeature.State(
            id: UUID(0),
            currentDate: Date(timeIntervalSince1970: 0),
            reminderTimestamp: Date(timeIntervalSince1970: 0)
        )
    }

    /// 開啟中的新增表單目的地
    static var form: CampaignPresentationFeature.Destination.State {
        .edit(formState)
    }

    /// 一般提示 alert，作為目前呈現中的 alert 與一次性通知使用
    static var notice: CampaignPresentationFeature.Destination.State {
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
}
