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
        @Presents var confirmation: AlertState<Action.Confirmation>?
        
        /// 搬移失敗時的可讀原因；失敗後仍維持阻斷狀態
        var recoveryFailureReason: String?
    }
    
    // MARK: - Action
    /// 持久層失敗畫面的事件
    @CasePathable
    enum Action: Equatable {
        
        /// 使用者點擊「改用空白資料庫繼續」，開啟二次確認 alert
        case recoveryTapped
        
        /// 二次確認 alert 的呈現狀態與使用者選擇
        case confirmation(PresentationAction<Confirmation>)
        
        /// 隔離備份搬移完成，切到待重啟階段
        case recoverySucceeded
        
        /// 隔離備份搬移失敗，附上可讀原因
        case recoveryFailed(String)
        
        /// 二次確認 alert 的選項
        @CasePathable
        enum Confirmation: Equatable {
            
            /// 使用者確認搬移檔案並繼續
            case confirmRecovery
        }
    }
    
    // MARK: - Dependency Properties
    
    /// SwiftData store 與 sidecar 檔案搬移到隔離備份的依賴介面
    @Dependency(PersistenceStoreQuarantineClient.self)
    private var persistenceStoreQuarantine
    
    // MARK: - Reducer Body
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .recoveryTapped:
                state.confirmation = AlertState {
                    TextState("改用空白資料庫繼續")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmRecovery) {
                        TextState("保留備份並繼續")
                    }
                    ButtonState(role: .cancel) {
                        TextState("取消")
                    }
                } message: {
                    TextState("這會將目前無法開啟的資料搬到裝置上的備份目錄。資料不會被刪除。完成後請關閉並重新開啟 App。")
                }
                return .none
                
            case .confirmation(.presented(.confirmRecovery)):
                let persistenceStoreQuarantine = persistenceStoreQuarantine
                return .run { send in
                    do {
                        try persistenceStoreQuarantine.quarantine()
                        await send(.recoverySucceeded)
                    } catch {
                        await send(.recoveryFailed(error.localizedDescription))
                    }
                }
                
            case .confirmation:
                return .none
                
            case .recoverySucceeded:
                state.phase = .relaunchRequired
                return .none
                
            case let .recoveryFailed(reason):
                state.recoveryFailureReason = reason
                return .none
            }
        }
        .ifLet(\.$confirmation, action: \.confirmation)
    }
}

// MARK: - Nested Types

extension PersistenceFailureFeature {
    
    /// 失敗畫面的復原階段
    enum Phase: Equatable {
        
        /// 原始資料仍留在原處，使用者尚未確認復原
        case blocked
        
        /// store 已搬入隔離備份，必須重新啟動後才可使用新的空白資料庫
        case relaunchRequired
    }
}
