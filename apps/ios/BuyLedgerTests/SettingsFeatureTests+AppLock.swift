//
//  SettingsFeatureTests+AppLock.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension SettingsFeatureTests {

    /// 驗證成功後才啟用 App 鎖定，保存完整偏好並回報同一份快照
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

    /// 驗證失敗或取消維持關閉，只顯示驗證失敗說明，不保存或送出偏好委派
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

    /// 裝置不支援直接顯示說明，不請求驗證、不保存或送出偏好委派
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

    /// 關閉 App 鎖定不經驗證，立即保存完整偏好並回報同一份快照
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

private extension SettingsFeatureTests {

    /// 驗證失敗或取消時預期的完整 alert
    static var expectedAuthenticationFailure: SettingsFeature.Destination.State {
        .alert(
            AlertState<SettingsFeature.Destination.Alert> {
                TextState("無法啟用 App 鎖定")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("關閉")
                }
            } message: {
                TextState("身份驗證失敗或已取消，App 鎖定未啟用。")
            }
        )
    }

    /// 裝置不支援時預期的完整 alert
    static var expectedUnsupportedDevice: SettingsFeature.Destination.State {
        .alert(
            AlertState<SettingsFeature.Destination.Alert> {
                TextState("無法啟用 App 鎖定")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("關閉")
                }
            } message: {
                TextState("此裝置目前無法使用本機驗證，App 鎖定未啟用。")
            }
        )
    }

    /// 帶有非預設值的完整偏好，確認 App 鎖定的寫入不遺失其他設定
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
