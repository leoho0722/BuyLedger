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

    /// 呈現狀態：編輯表單與確認 alert 留在目的地，通知使用獨立狀態
    @ObservableState
    struct State: Equatable {

        /// 目前呈現中的編輯表單或 alert；`nil` 表示沒有呈現
        @Presents var destination: Destination.State?

        /// 與目的地分開呈現的一次性通知
        @Presents var notice: AlertState<Destination.Alert>?

        /// 目的地開啟或表單關閉期間到達的一次性通知暫存
        var queue = CampaignPresentationQueue()

        /// 直接呈現使用者觸發的表單或 alert，不經暫存佇列
        ///
        /// - Parameter destination: 要呈現的目的地
        mutating func present(_ destination: Destination.State) {
            self.destination = destination
        }

        /// sheet 關閉動畫結束後清除關閉旗標，並把暫存的通知移進通知狀態
        mutating func finishFormClosing() {
            var currentNotice = notice
            queue.finishFormClosing(into: &currentNotice, while: destination)
            notice = currentNotice
        }

        /// 目的地 reducer 清空目的地後，呈現可顯示的暫存通知
        mutating func presentPendingNoticeIfPossible() {
            var currentNotice = notice
            queue.presentPendingNotice(into: &currentNotice, while: destination)
            notice = currentNotice
        }

        /// 容器接受儲存後關閉表單，並標記表單開始關閉
        mutating func closeFormForSave() {
            destination = nil
            queue.beginFormClosing()
        }

        /// 直接呈現通知，或依目的地與表單關閉狀態交給佇列暫存
        ///
        /// - Parameter notice: 要呈現的通知
        mutating func presentNotice(_ notice: AlertState<Destination.Alert>) {
            var currentNotice = self.notice
            queue.present(notice, while: destination, into: &currentNotice)
            self.notice = currentNotice
        }

        /// 容器判定名稱重名時，把原因寫回表單並維持開啟
        mutating func showNameConflict() {
            destination?.modify(\.edit) {
                $0.nameConflictMessage = "campaigns.edit.message.anotherCampaignAlready"
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

        /// 獨立通知的呈現、關閉或按鈕事件
        ///
        /// - Parameter action: 通知的呈現、關閉或內部事件
        case notice(PresentationAction<Destination.Alert>)

        /// 一次性通知，目的地開啟或表單關閉中先暫存
        ///
        /// - Parameter notice: 要呈現的 alert
        case noticeRequested(AlertState<Destination.Alert>)

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

    /// 組合目的地與通知，並在目的地 reducer 清空後呈現暫存通知
    var body: some ReducerOf<Self> {
        Reduce(core)
            .ifLet(\.$destination, action: \.destination)
            .ifLet(\.$notice, action: \.notice)
        Reduce(releasePendingNotice)
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

        case .notice(.presented(.openSettings)):
            return .run { [openSettingsService] _ in
                await openSettingsService.open()
            }

        case .destination:
            return .none

        case .notice:
            return .none

        case .noticeRequested(let notice):
            state.presentNotice(notice)
            return .none
        }
    }

    /// 在前一段呈現 reducer 清空目的地後，釋出暫存通知
    ///
    /// - Parameters:
    ///   - state: 要更新的開團呈現狀態
    ///   - action: 這次收到的呈現事件，此處只檢查目的地處理後的狀態
    /// - Returns: 沒有後續操作，固定回 `.none`
    func releasePendingNotice(state: inout State, action: Action) -> Effect<Action> {
        state.presentPendingNoticeIfPossible()
        return .none
    }
}
