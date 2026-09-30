//
//  AppLockFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/31.
//

import ComposableArchitecture
import SwiftUI

/// App 鎖定的啟用流程，以及離開前景後上鎖、回來時解鎖的流程
@Reducer
struct AppLockFeature {

    // MARK: - State

    /// App 鎖定狀態
    @ObservableState
    struct State: Equatable {

        /// 是否已啟用 App 鎖定，開啟時須先通過一次驗證
        var isBiometricUnlockEnabled: Bool = false

        /// 內容目前是否鎖住；已啟用鎖定時，冷啟動與離開前景會鎖住，驗證成功或關閉鎖定後解除
        var isLocked: Bool = false

        /// 解鎖驗證是否失敗或取消過；成功或重新嘗試後清空
        var unlockDidFail: Bool = false

        /// 是否正在等待解鎖驗證結果
        var isUnlocking: Bool = false

        /// 裝置支援的生物辨識類型，供鎖定畫面與設定頁顯示
        var biometryType: BiometricAuthService.BiometryKind = .unavailable

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

        /// 設定頁的 App 鎖定說明
        var protectionDescriptionKey: LocalizedStringKey {
            switch biometryType {
            case .faceID:
                return "開啟後，離開 App 時會鎖定畫面內容；再次使用 App 時，需要通過 Face ID 或密碼驗證才能繼續使用。"

            case .touchID:
                return "開啟後，離開 App 時會鎖定畫面內容；再次使用 App 時，需要通過 Touch ID 或密碼驗證才能繼續使用。"

            case .unavailable:
                return "開啟後，離開 App 時會鎖定畫面內容；再次使用 App 時，需要通過裝置密碼驗證才能繼續使用。"
            }
        }
    }

    // MARK: - Action

    /// App 鎖定可處理的事件
    @CasePathable
    enum Action: Equatable {

        /// 使用者切換設定頁的「App 鎖定」開關
        ///
        /// - Parameter isEnabled: 切換後的開關狀態，`true` 代表要啟用
        case enableToggled(Bool)

        /// 啟用流程的驗證請求完成
        ///
        /// - Parameter authenticationResult: 這次驗證的結果 (成功、失敗或取消)
        case enableAuthenticationFinished(BiometricAuthService.AuthenticationResult)

        /// 啟用失敗說明對話框送回的事件
        ///
        /// - Parameter action: 對話框被關閉；`Alert` 沒有其他選項
        case enableFailureAlert(PresentationAction<Alert>)

        /// App 離開前景 (由 `scenePhase` 轉為 `background` 觸發)
        case appDidResignActive

        /// App 回到前景或冷啟動後已就緒 (由 `scenePhase` 轉為 `active` 觸發)
        case appDidBecomeActive

        /// 使用者於鎖定畫面點擊重新驗證
        case retryUnlockTapped

        /// 解鎖流程的驗證請求完成
        ///
        /// - Parameter authenticationResult: 這次驗證的結果 (成功、失敗或取消)
        case unlockAuthenticationFinished(BiometricAuthService.AuthenticationResult)

        /// 啟用失敗說明對話框的選項 (僅關閉，無其他動作)
        @CasePathable
        enum Alert: Equatable {}
    }

    // MARK: - Dependencies

    /// 檢查裝置是否支援本機驗證、讀取生物辨識類型，並在啟用與解鎖時請求驗證的 Service
    @Dependency(\.biometricAuthService) private var biometricAuthService

    // MARK: - Body

    /// 依事件更新鎖定狀態：切換開關時先驗證才啟用，離開前景時上鎖，回到前景或重試時嘗試解鎖
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
                if !biometricAuthService.isAvailable() {
                    state.enableFailureAlert = Self.unsupportedDeviceAlert
                    return .none
                }
                let biometricAuthService = biometricAuthService
                return .run { send in
                    let result = await biometricAuthService.authenticate(
                        String(localized: "驗證身份以解鎖 App")
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
                state.biometryType = biometricAuthService.biometryType()
                guard state.isBiometricUnlockEnabled, state.isLocked else {
                    return .none
                }
                state.isUnlocking = true
                return Self.attemptUnlock(biometricAuthService)

            case .retryUnlockTapped:
                guard state.isBiometricUnlockEnabled, state.isLocked else {
                    return .none
                }
                state.unlockDidFail = false
                state.isUnlocking = true
                return Self.attemptUnlock(biometricAuthService)

            case .unlockAuthenticationFinished(.success):
                state.isLocked = false
                state.unlockDidFail = false
                state.isUnlocking = false
                return .none

            case .unlockAuthenticationFinished(.failure), .unlockAuthenticationFinished(.cancelled):
                state.unlockDidFail = true
                state.isUnlocking = false
                return .none
            }
        }
        .ifLet(\.$enableFailureAlert, action: \.enableFailureAlert)
    }
}

// MARK: - Private Method

private extension AppLockFeature {

    /// 驗證失敗或取消時的說明對話框
    static var authenticationFailedAlert: AlertState<Action.Alert> {
        AlertState {
            TextState("無法啟用 App 鎖定")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("關閉")
            }
        } message: {
            TextState("身份驗證失敗或已取消，App 鎖定未啟用。")
        }
    }

    /// 裝置不支援本機驗證時的說明對話框
    static var unsupportedDeviceAlert: AlertState<Action.Alert> {
        AlertState {
            TextState("無法啟用 App 鎖定")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("關閉")
            }
        } message: {
            TextState("此裝置目前無法使用本機驗證，App 鎖定未啟用。")
        }
    }

    /// 觸發一次解鎖驗證請求
    ///
    /// - Parameter biometricAuthService: 用來請求驗證的 Service
    /// - Returns: 送出解鎖驗證結果的 `Effect`
    static func attemptUnlock(_ biometricAuthService: BiometricAuthService) -> Effect<Action> {
        .run { send in
            let result = await biometricAuthService.authenticate(String(localized: "驗證身份以解鎖 App"))
            await send(.unlockAuthenticationFinished(result))
        }
    }
}
