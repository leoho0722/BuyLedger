//
//  SettingsFeatureAppLockTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `SettingsFeature` 的單元測試，涵蓋 App 鎖定開關的身分驗證、偏好保存與失敗說明
@MainActor
struct SettingsFeatureAppLockTests {

    /// 驗證 App 鎖定只在身分驗證成功後才啟用，保存完整偏好並送出同一份快照給父層
    @Test
    func appLockToggled_驗證成功_啟用儲存並回報偏好() async {
        // Given
        let saved = LockIsolated<[SettingsSnapshot]>([])
        let initial = SettingsFeature.State(snapshot: Self.appLockSnapshot(isEnabled: false))
        let expected = Self.appLockSnapshot(isEnabled: true)
        let store = TestStore(initialState: initial) {
            SettingsFeature()
        } withDependencies: {
            $0.settingsService.save = { snapshot in
                saved.withValue {
                    $0.append(snapshot)
                }
            }
            $0.biometricAuthService.isAvailable = {
                true
            }
            $0.biometricAuthService.authenticate = { _ in
                .success
            }
        }

        // When
        await store.send(.view(.appLockToggled(true)))

        // Then
        await store.receive(\.appLockAuthenticationResponse) {
            $0.isBiometricUnlockEnabled = true
        }
        await store.receive(\.delegate.preferencesChanged, expected)
        await store.finish()
        #expect(saved.value == [expected])
    }

    /// 驗證身分驗證失敗或取消時，App 鎖定維持關閉並顯示失敗說明，不儲存偏好，也不回報偏好變更
    ///
    /// - Parameter result: 啟用驗證的失敗或取消結果
    @Test(arguments: [BiometricAuthService.AuthenticationResult.failure, .cancelled])
    func appLockToggled_驗證失敗或取消_維持關閉並顯示提示(result: BiometricAuthService.AuthenticationResult) async {
        // Given
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.biometricAuthService.isAvailable = {
                true
            }
            $0.biometricAuthService.authenticate = { _ in
                result
            }
        }

        // When
        await store.send(.view(.appLockToggled(true)))

        // Then
        await store.receive(\.appLockAuthenticationResponse) {
            $0.destination = Self.expectedAuthenticationFailure
        }
        await store.finish()
        #expect(!store.state.isBiometricUnlockEnabled)
    }

    /// 驗證裝置不支援時，直接顯示說明提示，不請求身分驗證、不儲存偏好，也不回報偏好變更
    @Test
    func appLockToggled_裝置不支援_維持關閉並顯示提示() async {
        // Given
        let store = TestStore(initialState: SettingsFeature.State()) {
            SettingsFeature()
        } withDependencies: {
            $0.biometricAuthService.isAvailable = {
                false
            }
        }

        // When
        await store.send(.view(.appLockToggled(true))) {
            $0.destination = Self.expectedUnsupportedDevice
        }

        // Then
        await store.finish()
        #expect(!store.state.isBiometricUnlockEnabled)
    }

    /// 驗證關閉 App 鎖定時不經驗證，立即保存完整偏好並送出同一份快照給父層
    @Test
    func appLockToggled_關閉_立即儲存並回報偏好() async {
        // Given
        let saved = LockIsolated<[SettingsSnapshot]>([])
        let initial = SettingsFeature.State(snapshot: Self.appLockSnapshot(isEnabled: true))
        let expected = Self.appLockSnapshot(isEnabled: false)
        let store = TestStore(initialState: initial) {
            SettingsFeature()
        } withDependencies: {
            $0.settingsService.save = { snapshot in
                saved.withValue {
                    $0.append(snapshot)
                }
            }
        }

        // When
        await store.send(.view(.appLockToggled(false))) {
            $0.isBiometricUnlockEnabled = false
        }

        // Then
        await store.receive(\.delegate.preferencesChanged, expected)
        await store.finish()
        #expect(saved.value == [expected])
    }
}

// MARK: - Private Method

private extension SettingsFeatureAppLockTests {

    /// 身分驗證失敗或取消時預期的完整 alert
    static var expectedAuthenticationFailure: SettingsFeature.Destination.State {
        .alert(
            AlertState<SettingsFeature.Destination.Alert> {
                TextState("settings.preference.label.unableEnableApp")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("common.action.label.close")
                }
            } message: {
                TextState("settings.preference.message.authenticationFailedCancelled")
            }
        )
    }

    /// 裝置不支援時預期的完整 alert
    static var expectedUnsupportedDevice: SettingsFeature.Destination.State {
        .alert(
            AlertState<SettingsFeature.Destination.Alert> {
                TextState("settings.preference.label.unableEnableApp")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("common.action.label.close")
                }
            } message: {
                TextState("settings.preference.message.deviceCannotCurrently")
            }
        )
    }

    /// 建立帶非預設值的完整偏好快照，供確認 App 鎖定的寫入不遺失其他設定
    ///
    /// - Parameter isEnabled: 此快照的 App 鎖定啟用值
    /// - Returns: 語言、幣別、目標與模型皆固定的偏好快照
    static func appLockSnapshot(isEnabled: Bool) -> SettingsSnapshot {
        SettingsSnapshot(
            language: .english,
            defaultCurrency: .usd,
            monthlyProfitGoalTWD: 120_000,
            isAISummaryEnabled: true,
            aiSummaryModel: "deepseek-v3.1:671b",
            isBiometricUnlockEnabled: isEnabled
        )
    }
}
