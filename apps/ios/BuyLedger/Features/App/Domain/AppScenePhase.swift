//
//  AppScenePhase.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

import SwiftUI

/// 殼層處理的場景階段，避免 reducer 依賴 SwiftUI 的場景型別
enum AppScenePhase: CaseIterable, Equatable, Sendable {

    /// App 在前景可互動
    case active

    /// App 暫時無法互動，不觸發上鎖或解鎖
    case inactive

    /// App 已進入背景
    case background

    // MARK: - Init

    /// 把系統場景階段轉成殼層值，未知階段視為非作用中
    ///
    /// - Parameter phase: 系統回報的場景階段
    init(_ phase: ScenePhase) {
        switch phase {
        case .active:
            self = .active

        case .inactive:
            self = .inactive

        case .background:
            self = .background

        @unknown default:
            self = .inactive
        }
    }
}
