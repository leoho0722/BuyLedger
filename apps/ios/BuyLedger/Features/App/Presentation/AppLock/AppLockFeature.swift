//
//  AppLockFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/31.
//

import ComposableArchitecture
import Foundation

/// 離開前景上鎖、回到前景或冷啟動時驗證解鎖
@Reducer
struct AppLockFeature {

    // MARK: - State

    /// 殼層常駐的 App 鎖定狀態
    @ObservableState
    struct State: Equatable {

        /// 根功能依偏好同步的鎖定啟用投影
        var isBiometricUnlockEnabled: Bool = false

        /// 內容是否鎖住；已啟用鎖定時，冷啟動與進入背景會鎖住
        var isLocked: Bool = false

        /// 解鎖驗證是否失敗或取消過，成功或重試時清空
        var unlockDidFail: Bool = false

        /// 是否正在等待解鎖驗證結果
        var isUnlocking: Bool = false

        /// 裝置支援的辨識類型，供鎖定畫面與設定頁使用
        var biometryType: BiometricAuthService.BiometryKind = .unavailable
    }

    // MARK: - Action

    /// 鎖定畫面、場景生命週期與驗證結果的事件
    enum Action: Equatable {

        /// 鎖定畫面與系統場景轉換送出的事件
        ///
        /// - Parameter action: 重試或場景階段改變
        case view(View)

        /// 交由殼層處理的生命週期通知
        ///
        /// - Parameter action: 回到前景的通知
        case delegate(Delegate)

        /// 解鎖驗證完成
        ///
        /// - Parameter result: 成功、失敗或取消的驗證結果
        case unlockResponse(BiometricAuthService.AuthenticationResult)

        /// 鎖定畫面與 App 入口可以送出的操作
        @CasePathable
        enum View: Equatable {

            /// 使用者點擊重新驗證
            case retryUnlockTapped

            /// App 入口回報系統場景階段
            ///
            /// - Parameter phase: 系統階段對應的殼層值
            case scenePhaseChanged(AppScenePhase)
        }

        /// 交由根功能處理的通知
        @CasePathable
        enum Delegate: Equatable {

            /// App 已回到前景，辨識類型已更新
            case didBecomeActive
        }
    }

    // MARK: - Dependencies

    /// 讀取辨識類型與請求本機驗證的 Service
    @Dependency(\.biometricAuthService) private var biometricAuthService

    // MARK: - Body

    /// 組合鎖定與解鎖邏輯，不參與設定頁的啟用驗證或持久化
    var body: some ReducerOf<Self> {
        Reduce(core)
    }
}

// MARK: - Private Method

private extension AppLockFeature {

    /// 依場景與驗證事件更新鎖定狀態
    ///
    /// - Parameters:
    ///   - state: 要就地更新的鎖定狀態
    ///   - action: 重試、場景轉換或驗證結果
    /// - Returns: 回到前景的委派或解鎖驗證效果
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .view(.retryUnlockTapped):
            guard state.isBiometricUnlockEnabled, state.isLocked else {
                return .none
            }
            state.unlockDidFail = false
            state.isUnlocking = true
            return attemptUnlock()

        case .view(.scenePhaseChanged(.active)):
            state.biometryType = biometricAuthService.biometryType()
            guard state.isBiometricUnlockEnabled, state.isLocked else {
                return .send(.delegate(.didBecomeActive))
            }
            state.isUnlocking = true
            return .merge(.send(.delegate(.didBecomeActive)), attemptUnlock())

        case .view(.scenePhaseChanged(.inactive)):
            return .none

        case .view(.scenePhaseChanged(.background)):
            guard state.isBiometricUnlockEnabled else {
                return .none
            }
            state.isLocked = true
            return .none

        case .delegate:
            return .none

        case .unlockResponse(.success):
            state.isLocked = false
            state.unlockDidFail = false
            state.isUnlocking = false
            return .none

        case .unlockResponse(.failure), .unlockResponse(.cancelled):
            state.unlockDidFail = true
            state.isUnlocking = false
            return .none
        }
    }

    /// 請求一次本機驗證，並以單一回應回報結果
    ///
    /// - Returns: 送出解鎖結果的效果
    func attemptUnlock() -> Effect<Action> {
        let biometricAuthService = biometricAuthService
        return .run { send in
            let result = await biometricAuthService.authenticate(String(localized: "settings.preference.label.authenticateUnlockApp"))
            await send(.unlockResponse(result))
        }
    }
}
