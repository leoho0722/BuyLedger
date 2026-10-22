//
//  AppLockFeatureTests+Formatters.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension AppLockFeatureTests {

    /// 保護未啟用也會回報回前景委派，並依裝置類型提供對應的解鎖文案與設定說明
    ///
    /// - Parameter scenario: 更新前後的辨識類型與獨立指定的預期字面值
    @Test(arguments: BiometryCase.allCases)
    func scenePhaseChanged_裝置生物辨識類型_顯示對應設定說明(scenario: BiometryCase) async {
        // Given
        let initial = AppLockFeature.State(biometryType: scenario.previousBiometryType)
        let store = TestStore(initialState: initial) {
            AppLockFeature()
        } withDependencies: {
            $0.biometricAuthService.biometryType = {
                scenario.biometryType
            }
        }

        // When
        await store.send(.view(.scenePhaseChanged(.active))) {
            $0.biometryType = scenario.biometryType
        }

        // Then
        await store.receive(\.delegate.didBecomeActive)
        await store.finish()
        let descriptionKey = AppLockFormatters.protectionDescription(for: store.state.biometryType)
        let titleKey = AppLockFormatters.unlockTitle(for: store.state.biometryType)
        #expect(titleKey == LocalizedStringKey(scenario.expectedTitle))
        #expect(descriptionKey == LocalizedStringKey(scenario.expectedDescription))
    }
}

// MARK: - Nested Types

extension AppLockFeatureTests {

    /// 更新前後的辨識類型與獨立指定的解鎖文案、設定說明
    struct BiometryCase: Sendable {

        /// 裝置回報臉部、指紋與不可用三種辨識類型各自的預期字面值
        static let allCases = [
            Self(
                previousBiometryType: .unavailable,
                biometryType: .faceID,
                expectedTitle: "settings.preference.label.unlockFaceId",
                expectedDescription: "settings.preference.message.whenEnabled"
            ),
            Self(
                previousBiometryType: .unavailable,
                biometryType: .touchID,
                expectedTitle: "settings.preference.label.unlockTouchId",
                expectedDescription: "settings.preference.message.whenEnabledLeaving"
            ),
            Self(
                previousBiometryType: .faceID,
                biometryType: .unavailable,
                expectedTitle: "settings.preference.label.unlock",
                expectedDescription: "settings.preference.message.whenEnabledLeavingThe"
            ),
        ]

        /// 更新前的辨識類型
        let previousBiometryType: BiometricAuthService.BiometryKind

        /// 裝置回報的辨識類型
        let biometryType: BiometricAuthService.BiometryKind

        /// 解鎖按鈕的預期字面值
        let expectedTitle: String

        /// 設定說明的預期字面值
        let expectedDescription: String
    }
}
