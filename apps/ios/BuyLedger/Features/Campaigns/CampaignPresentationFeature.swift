//
//  CampaignPresentationFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture

/// 開團的呈現子 Feature：持有編輯表單與 alert 的目的地，以及一次性通知的佇列，使用者意圖交給容器
@Reducer
struct CampaignPresentationFeature {

    // MARK: - State

    /// 呈現狀態：同一時間只會有一個表單或 alert，通知在表單開啟或關閉期間先暫存
    @ObservableState
    struct State: Equatable {

        /// 目前呈現中的編輯表單或 alert；`nil` 表示沒有呈現
        @Presents var destination: Destination.State?

        /// 表單開啟與關閉期間到達的一次性通知暫存，表單關好後才呈現
        var queue = CampaignPresentationQueue()

        /// 直接呈現使用者觸發的表單或 alert，不經暫存佇列
        ///
        /// - Parameter destination: 要呈現的目的地
        mutating func present(_ destination: Destination.State) {
            self.destination = destination
        }

        /// sheet 關閉動畫結束後清除關閉旗標，並把暫存的通知移進目的地
        mutating func finishFormClosing() {
            var current = destination
            queue.finishFormClosing(into: &current)
            destination = current
        }

        /// 容器接受儲存後關閉表單，並標記表單開始關閉
        mutating func closeFormForSave() {
            destination = nil
            queue.beginFormClosing()
        }

        /// 容器判定名稱重名時，把原因寫回表單並維持開啟
        mutating func showNameConflict() {
            destination?.modify(\.edit) {
                $0.nameConflictMessage = "已有其他開團使用這個名稱，請改用不同名稱。"
            }
        }
    }

    // MARK: - Action

    /// 呈現子 Feature 的事件：目的地的呈現與關閉、一次性通知與交給容器的委派
    enum Action {

        /// 交給容器處理的使用者意圖
        ///
        /// - Parameter action: 要交給容器的意圖
        case delegate(Delegate)

        /// 編輯表單或 alert 的事件
        ///
        /// - Parameter action: 目的地的呈現、關閉或內部事件
        case destination(PresentationAction<Destination.Action>)

        /// 一次性通知，表單開啟或關閉中先暫存
        ///
        /// - Parameter notice: 要呈現的通知
        case noticeRequested(Destination.State)

        /// 交給容器的使用者意圖
        @CasePathable
        enum Delegate: Equatable {

            /// 表單的名稱通過本地驗證，請容器判定重名後決定是否儲存
            ///
            /// - Parameter request: 原開團、去空白名稱與完整草稿
            case saveRequested(CampaignEditFeature.SaveRequest)

            /// 使用者確認刪除指定開團
            ///
            /// - Parameter id: 要刪除的開團識別值
            case deleteConfirmed(Campaign.ID)

            /// 使用者確認結團
            ///
            /// - Parameter id: 要結團的開團識別值
            case settleConfirmed(Campaign.ID)
        }
    }

    // MARK: - Dependencies

    /// 開啟本 App 系統設定頁的能力；權限被拒提示的「前往設定」使用
    @Dependency(\.openSettingsService) private var openSettingsService

    // MARK: - Body

    /// 組合目的地，呈現與關閉的邏輯在 `core(state:action:)`
    var body: some Reducer<State, Action> {
        Reduce(core)
            .ifLet(\.$destination, action: \.destination)
    }
}

// MARK: - Private Method

private extension CampaignPresentationFeature {

    /// 依收到的事件更新呈現狀態，需要容器判斷的意圖轉成 delegate
    ///
    /// - Parameters:
    ///   - state: 呈現子層狀態，直接就地修改
    ///   - action: 目的地、通知或委派事件
    /// - Returns: 交給容器的 delegate 或系統設定的效果，沒有就回 `.none`
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .delegate:
            return .none

        case .destination(.dismiss):
            state.queue.markFormClosing(dismissing: state.destination)
            return .none

        case .destination(.presented(.edit(.delegate(.saveRequested(let request))))):
            return .send(.delegate(.saveRequested(request)))

        case .destination(.presented(.alert(.confirmDelete(let id)))):
            return .send(.delegate(.deleteConfirmed(id)))

        case .destination(.presented(.alert(.confirmSettle(let id)))):
            return .send(.delegate(.settleConfirmed(id)))

        case .destination(.presented(.alert(.openSettings))):
            return .run { [openSettingsService] _ in
                await openSettingsService.open()
            }

        case .destination:
            return .none

        case .noticeRequested(let notice):
            var current = state.destination
            state.queue.present(notice, in: &current)
            state.destination = current
            return .none
        }
    }
}
