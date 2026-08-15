//
//  AppScenePhaseCoordinator.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/1.
//

import SwiftUI

/// 將場景階段轉換轉成 ``AppLockFeature`` 動作
@MainActor
enum AppScenePhaseCoordinator {}

// MARK: - Internal Method

@MainActor
extension AppScenePhaseCoordinator {
    
    /// 依新場景階段轉送對應的 ``AppLockFeature/Action``
    /// - Parameters:
    ///   - newPhase: `\.scenePhase` 轉換後的新階段
    ///   - send: 送出 AppLockFeature action
    static func handle(
        newPhase: ScenePhase,
        send: (AppLockFeature.Action) -> Void
    ) {
        switch newPhase {
        case .background:
            send(.appDidResignActive)
            
        case .active:
            send(.appDidBecomeActive)
            
        case .inactive:
            break
            
        @unknown default:
            break
        }
    }
}
