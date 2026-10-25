//
//  AppScenePhaseTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import SwiftUI
import Testing

@testable import BuyLedger

/// `AppScenePhase` 的單元測試，以 `ScenePhase` 逐一驗證轉換後的 App 自訂場景階段
struct AppScenePhaseTests {

    /// 驗證系統的作用中、非作用中與背景三種場景階段，各自轉成對應的自訂場景階段
    ///
    /// - Parameter scenario: 系統回報的場景階段與預期的自訂場景階段
    @Test(arguments: PhaseCase.allCases)
    func init_系統場景階段_對應自訂列舉(scenario: PhaseCase) {
        // Given

        // When
        let result = AppScenePhase(scenario.phase)

        // Then
        #expect(result == scenario.expectedPhase)
    }
}

// MARK: - Nested Types

extension AppScenePhaseTests {

    /// 一組系統場景階段與其預期自訂場景階段的測試案例
    struct PhaseCase: Sendable {

        /// 作用中、非作用中與背景三種系統階段各自的預期自訂場景階段
        static let allCases = [
            Self(phase: .active, expectedPhase: .active),
            Self(phase: .inactive, expectedPhase: .inactive),
            Self(phase: .background, expectedPhase: .background),
        ]

        /// 系統回報的場景階段
        let phase: ScenePhase

        /// 預期的自訂場景階段
        let expectedPhase: AppScenePhase
    }
}
