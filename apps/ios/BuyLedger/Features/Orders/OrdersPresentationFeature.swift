//
//  OrdersPresentationFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI

/// 訂單呈現子 Feature，管理表單、alert、一次性通知與合併轉場，本身不持有 View
@Reducer
struct OrdersPresentationFeature {

    // MARK: - State

    /// 呈現子層的目的地與一次性通知佇列
    @ObservableState
    struct State: Equatable {

        /// 目前呈現的表單或 alert，同一時間只有一個目的地
        @Presents var destination: Destination.State?

        /// sheet 關閉與合併轉場期間的一次性通知佇列
        var queue = OrdersPresentationQueue()

        /// 同一次更新內直接呈現表單或 alert，不經佇列
        ///
        /// - Parameter destination: 要呈現的目的地
        mutating func present(_ destination: Destination.State) {
            self.destination = destination
        }

        /// 表單關閉動畫完成後，依佇列先呈現就緒的合併確認，其次取出暫存通知
        mutating func finishFormClosing() {
            var current = destination
            queue.finishFormClosing(into: &current)
            destination = current
        }

        /// 呈現合併候選完成後的確認表單，等候選關閉後才呈現
        ///
        /// - Parameter confirmation: 已建立的合併確認表單
        mutating func presentMergeConfirmation(_ confirmation: Destination.State) {
            var current = destination
            queue.presentMergeConfirmation(confirmation, in: &current)
            destination = current
        }

        /// 套用訂單寫入結果，刪除正在編輯的訂單時關閉表單
        ///
        /// - Parameter outcome: 寫入子層的結果計畫
        mutating func apply(_ outcome: OrdersWriteOutcome) {
            if let id = outcome.closesEditOf,
               let original = destination?.edit?.original,
               original.id == id {
                destination = nil
                queue.beginFormClosing()
            }
        }

        /// 主檔新增成功時套用到來源表單，失敗時沿呈現佇列回報通知
        ///
        /// - Parameters:
        ///   - request: 保留發起表單識別值的新增請求
        ///   - isStored: 是否寫入成功
        /// - Returns: 寫入失敗時送出一次性通知，成功時不送出事件
        mutating func applyOptionAddition(
            _ request: LookupAdditionRequest,
            isStored: Bool
        ) -> Effect<Action> {
            if !isStored {
                let message = OrderWriteOperations.Failure.option(request.kind).message
                return .send(
                    .noticeRequested(.writeFailure(TextState(LocalizedStringKey(message))))
                )
            }
            guard destination?.edit?.id == request.id else {
                return .none
            }
            destination?.modify(\.edit) {
                $0.applyAddedOption(request)
            }
            return .none
        }
    }

    // MARK: - Action

    /// 呈現子層的事件，依來源分成父層委派、目的地事件與內部事件
    enum Action {

        /// 交給父層處理的意圖，本層收到後不做事
        ///
        /// - Parameter action: 要交給容器的意圖
        case delegate(Delegate)

        /// 表單與 alert 的呈現、關閉與目的地內部事件
        ///
        /// - Parameter action: 目的地內部事件或關閉事件
        case destination(PresentationAction<Destination.Action>)

        /// 容器算好合併草稿後啟動轉場，500ms 後送出合併確認
        ///
        /// - Parameters:
        ///   - draft: 合併後的訂單草稿
        ///   - keptPhotos: 保留的照片資料
        case mergeCandidateCompleted(draft: OrderMerge.Draft, keptPhotos: [Data])

        /// 寫入失敗等一次性通知，等關閉動畫結束後才呈現
        ///
        /// - Parameter notice: 要呈現的通知目的地
        case noticeRequested(Destination.State)

        /// 呈現子層交給容器的意圖
        @CasePathable
        enum Delegate: Equatable {

            /// 表單請求存檔，容器轉交寫入子層
            ///
            /// - Parameter edit: 送出存檔時的表單狀態
            case saveRequested(OrderEditFeature.State)

            /// 表單請求新增主檔選項，容器經根功能轉交主檔端
            ///
            /// - Parameter request: 新增選項的請求
            case optionAddRequested(LookupAdditionRequest)

            /// 使用者確認刪除指定訂單
            ///
            /// - Parameter id: 要刪除的訂單識別值
            case deleteConfirmed(LedgerOrder.ID)

            /// 要求開啟設定頁以啟用 AI 商品明細總結
            case aiSettingsRequested

            /// 合併候選選取完成，容器需計算合併草稿
            ///
            /// - Parameters:
            ///   - primary: 主訂單
            ///   - secondary: 副訂單
            ///   - keptPhotos: 保留的照片資料
            case mergeCandidatesCompleted(primary: LedgerOrder, secondary: LedgerOrder, keptPhotos: [Data])

            /// 合併轉場結束，容器需建立合併確認表單
            ///
            /// - Parameters:
            ///   - draft: 合併後的訂單草稿
            ///   - keptPhotos: 保留的照片資料
            case mergeConfirmationDue(draft: OrderMerge.Draft, keptPhotos: [Data])
        }
    }

    // MARK: - Dependencies

    /// 合併轉場的 500ms 延遲時脈，測試可注入 immediate clock
    @Dependency(\.continuousClock) private var clock

    // MARK: - Body

    /// 組合目的地與事件處理，本層自己的邏輯放在 `core(state:action:)`
    var body: some ReducerOf<Self> {
        Reduce(core)
            .ifLet(\.$destination, action: \.destination)
    }
}

// MARK: - Private Method

private extension OrdersPresentationFeature {

    /// 依收到的 Action 更新呈現狀態，並回傳要執行的 Effect
    ///
    /// - Parameters:
    ///   - state: 呈現子層的狀態，直接就地修改
    ///   - action: 這次收到的事件
    /// - Returns: 接下來要執行的 Effect，沒有就回 `.none`
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .delegate:
            return .none

        case .destination(.dismiss):
            state.queue.markFormClosing(dismissing: state.destination)
            return .none

        case .destination(.presented(.edit(.delegate(.saveRequested)))):
            guard let edit = state.destination?.edit else {
                return .none
            }
            return .send(.delegate(.saveRequested(edit)))

        case .destination(.presented(.edit(.delegate(.addOptionRequested(
            let kind,
            let name,
            let flags
        ))))):
            guard let formID = state.destination?.edit?.id else {
                return .none
            }
            let request = LookupAdditionRequest(
                id: formID,
                kind: kind,
                name: name,
                flags: flags
            )
            return .send(.delegate(.optionAddRequested(request)))

        case .destination(.presented(.merge(.delegate(.completed(
            let primary,
            let secondary,
            let keptPhotos
        ))))):
            return .send(
                .delegate(
                    .mergeCandidatesCompleted(
                        primary: primary,
                        secondary: secondary,
                        keptPhotos: keptPhotos
                    )
                )
            )

        case .destination(.presented(.alert(.confirmDelete(let id)))):
            return .send(.delegate(.deleteConfirmed(id)))

        case .destination(.presented(.alert(.goToAISettings))):
            return .send(.delegate(.aiSettingsRequested))

        case .destination:
            return .none

        case .mergeCandidateCompleted(let draft, let keptPhotos):
            state.destination = nil
            state.queue.beginMergeTransition()
            return .run { [clock] send in
                do {
                    try await clock.sleep(for: .milliseconds(500))
                } catch {
                    return
                }
                await send(.delegate(.mergeConfirmationDue(draft: draft, keptPhotos: keptPhotos)))
            }

        case .noticeRequested(let notice):
            var current = state.destination
            state.queue.present(notice, in: &current)
            state.destination = current
            return .none
        }
    }
}
