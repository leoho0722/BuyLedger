//
//  PersistenceFailureFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/26.
//

import ComposableArchitecture
import Foundation

/// 持久層無法開啟時的全畫面阻斷與使用者確認復原流程
@Reducer
struct PersistenceFailureFeature {

    // MARK: - State

    /// 持久層失敗畫面的狀態
    @ObservableState
    struct State: Equatable {

        /// 畫面目前所處的復原階段
        var phase: Phase = .blocked

        /// 使用者確認搬移檔案前顯示的二次確認 alert
        @Presents var destination: Destination.State?

        /// 搬移失敗時的可讀原因；失敗後仍維持阻斷狀態
        var recoveryFailureReason: String?
    }

    // MARK: - Action

    /// 持久層失敗畫面的操作、確認視窗事件與復原回應
    enum Action {

        /// 阻斷畫面送出的使用者操作
        ///
        /// - Parameter action: 使用者點擊復原入口
        case view(View)

        /// 二次確認 alert 的呈現事件
        ///
        /// - Parameter action: alert 被關閉或使用者確認搬移隔離備份
        case destination(PresentationAction<Destination.Action>)

        /// 隔離備份搬移完成的單一回應
        ///
        /// - Parameter result: 搬移成功或持久層復原錯誤
        case recoveryResponse(Result<Void, PersistenceRecoveryError>)

        /// 使用者在阻斷畫面上的操作
        @CasePathable
        enum View: Equatable {

            /// 使用者點擊「改用空白資料庫繼續」，開啟二次確認 alert
            case recoveryTapped
        }
    }

    // MARK: - Dependencies

    /// 搬移 SwiftData store 與附屬檔 (`-wal`、`-shm`) 到隔離備份的 Service
    @Dependency(\.persistenceRecoveryService) private var persistenceRecoveryService

    // MARK: - Body

    /// 組合復原邏輯與確認視窗，具體事件由 `core(state:action:)` 處理
    var body: some Reducer<State, Action> {
        Reduce(core)
            .ifLet(\.$destination, action: \.destination)
    }
}

// MARK: - Nested Types

extension PersistenceFailureFeature {

    /// 復原流程唯一可呈現的二次確認視窗
    @Reducer
    enum Destination {

        /// 使用者確認搬移隔離備份前顯示的 alert
        ///
        /// - Parameter state: 確認視窗的標題、訊息與按鈕
        @ReducerCaseIgnored case alert(AlertState<Alert>)

        /// 二次確認視窗送回的事件
        @CasePathable
        enum Action {

            /// alert 被關閉或選擇確認復原
            ///
            /// - Parameter action: 使用者選取的確認選項
            case alert(Alert)
        }

        /// 二次確認 alert 的選項
        @CasePathable
        enum Alert: Equatable {

            /// 使用者確認搬移檔案並繼續
            case confirmRecovery
        }
    }

    /// 失敗畫面的復原階段
    enum Phase: Equatable {

        /// 原始資料仍留在原處，使用者尚未確認復原
        case blocked

        /// store 已搬入隔離備份，必須重新啟動後才可使用新的空白資料庫
        case relaunchRequired
    }
}

// MARK: - Equatable

extension PersistenceFailureFeature.Destination.State: Equatable {}

// MARK: - Private Method

private extension PersistenceFailureFeature {

    /// 復原前的二次確認內容，說明資料只搬到備份、不會被刪除
    var recoveryConfirmation: AlertState<Destination.Alert> {
        AlertState {
            TextState("common.general.label.continueBlankDatabase")
        } actions: {
            ButtonState(role: .destructive, action: .confirmRecovery) {
                TextState("common.general.label.keepBackupContinue")
            }
            ButtonState(role: .cancel) {
                TextState("common.action.cancel")
            }
        } message: {
            TextState("common.general.message.movesDataCannot")
        }
    }

    /// 依畫面操作、確認與復原結果更新阻斷畫面的狀態
    ///
    /// - Parameters:
    ///   - state: 目前的復原階段與確認視窗
    ///   - action: 畫面操作、確認選項或復原回應
    /// - Returns: 確認搬移後執行復原，其他事件只更新畫面
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .view(.recoveryTapped):
            state.destination = .alert(recoveryConfirmation)
            return .none

        case .destination(.presented(.alert(.confirmRecovery))):
            return recoverStore()

        case .destination:
            return .none

        case .recoveryResponse(.success):
            state.phase = .relaunchRequired
            return .none

        case .recoveryResponse(.failure(let error)):
            state.recoveryFailureReason = error.localizedDescription
            return .none
        }
    }

    /// 搬移資料庫到隔離備份，以單一回應回報成功或原始錯誤
    ///
    /// - Returns: 執行搬移並回報復原結果的效果
    func recoverStore() -> Effect<Action> {
        let persistenceRecoveryService = persistenceRecoveryService
        return .run { send in
            do throws(PersistenceRecoveryError) {
                try await persistenceRecoveryService.quarantineStore()
                await send(.recoveryResponse(.success(())))
            } catch {
                await send(.recoveryResponse(.failure(error)))
            }
        }
    }
}
