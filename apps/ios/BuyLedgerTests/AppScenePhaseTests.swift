//
//  AppScenePhaseTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import SwiftUI
import Testing

@testable import BuyLedger

/// 驗證系統場景階段與殼層場景階段的對應
struct AppScenePhaseTests {

    /// 三種系統階段各自保留相同的殼層語意
    ///
    /// - Parameters:
    ///   - phase: 系統回報的場景階段
    ///   - expected: 獨立列出的預期殼層階段
    @Test(arguments: [
        (ScenePhase.active, AppScenePhase.active),
        (.inactive, .inactive),
        (.background, .background),
    ])
    func init_系統場景階段_對應自訂列舉(phase: ScenePhase, expected: AppScenePhase) {
        // Given

        // When
        let result = AppScenePhase(phase)

        // Then
        #expect(result == expected)
    }
}
