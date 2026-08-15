//
//  AppLockFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/31.
//

import ComposableArchitecture
import Foundation
import SwiftUI

/// 帳本保護 (應用程式層鎖定) 的啟用與鎖定／解鎖狀態機
@Reducer
struct AppLockFeature {
    
    // MARK: - State
    
    /// 帳本保護狀態
    @ObservableState
    struct State: Equatable {
        
        /// 是否啟用帳本保護
        var isBiometricUnlockEnabled: Bool = false
        
        /// 內容目前是否鎖定
        var isLocked: Bool = false
        
        /// 解鎖驗證是否失敗或取消過；成功或重新嘗試後清空
        var unlockDidFail: Bool = false
        
        /// 裝置支援的生物辨識類型，供鎖定畫面與設定頁顯示
        var biometryType: BiometricAuthClient.BiometryType = .unavailable
        
        /// 啟用失敗、取消或裝置不支援時顯示的說明對話框
        @Presents var enableFailureAlert: AlertState<Action.Alert>?
        
        /// 依生物辨識類型產生解鎖按鈕文案
        var unlockButtonTitleKey: LocalizedStringKey {
            switch biometryType {
            case .faceID:
                return "使用 Face ID 解鎖"
                
            case .touchID:
                return "使用 Touch ID 解鎖"
                
            case .unavailable:
                return "解鎖"
            }
        }
        
        /// 設定頁的帳本保護說明
        var protectionDescriptionKey: LocalizedStringKey {
            switch biometryType {
            case .faceID:
                return "開啟後，App 進入背景時會鎖定畫面內容；回到前景或重新開啟時，需要通過 Face ID 或密碼驗證才能檢視內容。"
                
            case .touchID:
                return "開啟後，App 進入背景時會鎖定畫面內容；回到前景或重新開啟時，需要通過 Touch ID 或密碼驗證才能檢視內容。"
                
            case .unavailable:
                return "開啟後，App 進入背景時會鎖定畫面內容；回到前景或重新開啟時，需要通過裝置的生物辨識或密碼驗證才能檢視內容。"
            }
        }
    }
    
    // MARK: - Action
    
    /// 帳本保護可處理的事件
    @CasePathable
    enum Action: Equatable {
        
        /// 使用者切換設定頁的「帳本保護」開關
        case enableToggled(Bool)
        
        /// 啟用流程的驗證請求完成
        case enableAuthenticationFinished(BiometricAuthClient.AuthenticationResult)
        
        /// 啟用失敗說明對話框的呈現狀態
        case enableFailureAlert(PresentationAction<Alert>)
        
        /// App 離開前景 (由 scenePhase 轉為 background 觸發)
        case appDidResignActive
        
        /// App 回到前景或冷啟動後已就緒 (由 scenePhase 轉為 active 觸發)
        case appDidBecomeActive
        
        /// 使用者於鎖定畫面點擊重新驗證
        case retryUnlockTapped
        
        /// 解鎖流程的驗證請求完成
        case unlockAuthenticationFinished(BiometricAuthClient.AuthenticationResult)
        
        /// 啟用失敗說明對話框的選項 (僅關閉，無其他動作)
        @CasePathable
        enum Alert: Equatable {}
    }
    
    // MARK: - Dependency Properties
    
    /// 系統本機驗證介面
    @Dependency(BiometricAuthClient.self) private var biometricAuthClient
    
    // MARK: - Reducer Body
    
    /// 帳本保護 reducer
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .enableToggled(false):
                // 關閉不需要驗證：Non-Goal 明列關閉不留任何殘留行為
                state.isBiometricUnlockEnabled = false
                state.isLocked = false
                state.unlockDidFail = false
                return .none
                
            case .enableToggled(true):
                guard biometricAuthClient.isAvailable() else {
                    state.enableFailureAlert = Self.unsupportedDeviceAlert
                    return .none
                }
                let biometricAuthClient = biometricAuthClient
                return .run { send in
                    let result = await biometricAuthClient.authenticate(
                        String(localized: "驗證身份以啟用帳本保護")
                    )
                    await send(.enableAuthenticationFinished(result))
                }
                
            case .enableAuthenticationFinished(.success):
                state.isBiometricUnlockEnabled = true
                return .none
                
            case .enableAuthenticationFinished(.failure), .enableAuthenticationFinished(.cancelled):
                state.enableFailureAlert = Self.authenticationFailedAlert
                return .none
                
            case .enableFailureAlert:
                return .none
                
            case .appDidResignActive:
                guard state.isBiometricUnlockEnabled else {
                    return .none
                }
                state.isLocked = true
                return .none
                
            case .appDidBecomeActive:
                // 回到前景時更新生物辨識類型
                state.biometryType = biometricAuthClient.biometryType()
                guard state.isBiometricUnlockEnabled, state.isLocked else {
                    return .none
                }
                return Self.attemptUnlock(biometricAuthClient)
                
            case .retryUnlockTapped:
                guard state.isBiometricUnlockEnabled, state.isLocked else {
                    return .none
                }
                state.unlockDidFail = false
                return Self.attemptUnlock(biometricAuthClient)
                
            case .unlockAuthenticationFinished(.success):
                state.isLocked = false
                state.unlockDidFail = false
                return .none
                
            case .unlockAuthenticationFinished(.failure), .unlockAuthenticationFinished(.cancelled):
                state.unlockDidFail = true
                return .none
            }
        }
        .ifLet(\.$enableFailureAlert, action: \.enableFailureAlert)
    }
}

// MARK: - Static Properties

private extension AppLockFeature {
    
    /// 驗證失敗或取消時的說明對話框
    static var authenticationFailedAlert: AlertState<Action.Alert> {
        AlertState {
            TextState("無法啟用帳本保護")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("關閉")
            }
        } message: {
            TextState("身份驗證失敗或已取消，帳本保護未開啟。")
        }
    }
    
    /// 裝置不支援本機驗證時的說明對話框
    static var unsupportedDeviceAlert: AlertState<Action.Alert> {
        AlertState {
            TextState("無法啟用帳本保護")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("關閉")
            }
        } message: {
            TextState("此裝置目前無法使用本機驗證，帳本保護未開啟。")
        }
    }
}

// MARK: - Private Method

private extension AppLockFeature {
    
    /// 觸發一次解鎖驗證請求
    /// - Parameter biometricAuthClient: 系統本機驗證介面
    /// - Returns: 送出解鎖驗證結果的 effect
    static func attemptUnlock(_ biometricAuthClient: BiometricAuthClient) -> Effect<Action> {
        .run { send in
            let result = await biometricAuthClient.authenticate(
                String(localized: "驗證身份以檢視帳本內容")
            )
            await send(.unlockAuthenticationFinished(result))
        }
    }
}
