//
//  AppLockFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/31.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// 驗證 App 鎖定的啟用、鎖定與解鎖流程
@MainActor
struct AppLockFeatureTests {

    // MARK: - Tests

    /// 切換時先要求驗證，成功後才啟用 App 鎖定
    @Test
    func enableToggled_驗證成功_啟用App鎖定() async {
        // Given
        let store = TestStore(initialState: AppLockFeature.State()) {
            AppLockFeature()
        } withDependencies: {
            $0.biometricAuthService.isAvailable = {
                true
            }
            $0.biometricAuthService.authenticate = { _ in
                .success
            }
        }

        // When
        await store.send(.enableToggled(true))

        // Then
        await store.receive(\.enableAuthenticationFinished) {
            $0.isBiometricUnlockEnabled = true
        }
    }

    /// 驗證失敗與取消都顯示相同的啟用失敗說明
    ///
    /// - Parameter result: 本次驗證結果
    @Test(arguments: [BiometricAuthService.AuthenticationResult.failure, .cancelled])
    func enableToggled_驗證失敗或使用者取消_維持關閉並顯示警告(
        result: BiometricAuthService.AuthenticationResult
    ) async {
        // Given
        let store = TestStore(initialState: AppLockFeature.State()) {
            AppLockFeature()
        } withDependencies: {
            $0.biometricAuthService.isAvailable = {
                true
            }
            $0.biometricAuthService.authenticate = { _ in
                result
            }
        }

        // When
        await store.send(.enableToggled(true))

        // Then
        await store.receive(\.enableAuthenticationFinished) {
            $0.enableFailureAlert = Self.expectedFailureAlert
        }
    }

    /// 裝置不支援時不發出驗證請求，直接顯示不支援說明
    ///
    /// - Note: `testValue` 的 `authenticate` 為 `unimplemented`，非預期驗證會使測試失敗
    @Test
    func enableToggled_裝置不支援驗證_維持關閉並顯示警告() async {
        // Given
        let store = TestStore(initialState: AppLockFeature.State()) {
            AppLockFeature()
        } withDependencies: {
            $0.biometricAuthService.isAvailable = {
                false
            }
        }

        // When
        await store.send(.enableToggled(true)) {
            $0.enableFailureAlert = Self.expectedUnsupportedAlert
        }

        // Then
        #expect(!store.state.isBiometricUnlockEnabled)
    }

    /// App 鎖定保護已啟用時切至背景會鎖定內容
    @Test
    func appDidResignActive_保護已啟用_鎖定內容() async {
        // Given
        let store = TestStore(initialState: AppLockFeature.State(isBiometricUnlockEnabled: true)) {
            AppLockFeature()
        }

        // When
        await store.send(.appDidResignActive) {
            $0.isLocked = true
        }

        // Then
        #expect(store.state.isLocked)
    }

    /// App 鎖定保護未啟用時切至背景維持未鎖定
    @Test
    func appDidResignActive_保護未啟用_維持未鎖定() async {
        // Given
        let store = TestStore(initialState: AppLockFeature.State()) {
            AppLockFeature()
        }

        // When
        await store.send(.appDidResignActive)

        // Then
        #expect(!store.state.isLocked)
    }

    /// 鎖定中完成驗證後解除鎖定，並依裝置類型顯示解鎖文案
    ///
    /// - Parameters:
    ///   - previousBiometryType: 更新前的生物辨識類型
    ///   - biometryType: 裝置回報的生物辨識類型
    ///   - expectedUnlockButtonTitle: 預期的解鎖按鈕文案
    @Test(arguments: [
        (
            BiometricAuthService.BiometryKind.unavailable,
            BiometricAuthService.BiometryKind.faceID,
            "使用 Face ID 解鎖"
        ),
        (.faceID, .unavailable, "解鎖"),
    ])
    func appDidBecomeActive_鎖定中驗證成功_解除鎖定並依辨識類型顯示文案(
        previousBiometryType: BiometricAuthService.BiometryKind,
        biometryType: BiometricAuthService.BiometryKind,
        expectedUnlockButtonTitle: String
    ) async {
        // Given
        let store = TestStore(
            initialState: AppLockFeature.State(
                isBiometricUnlockEnabled: true,
                isLocked: true,
                biometryType: previousBiometryType
            )
        ) {
            AppLockFeature()
        } withDependencies: {
            $0.biometricAuthService.biometryType = {
                biometryType
            }
            $0.biometricAuthService.authenticate = { _ in
                .success
            }
        }

        // When
        await store.send(.appDidBecomeActive) {
            $0.biometryType = biometryType
            $0.isUnlocking = true
        }

        // Then
        #expect(store.state.unlockButtonTitleKey == LocalizedStringKey(expectedUnlockButtonTitle))
        await store.receive(\.unlockAuthenticationFinished) {
            $0.isLocked = false
            $0.isUnlocking = false
        }
    }

    /// 解鎖驗證失敗時鎖定畫面維持，並標示失敗讓使用者重新嘗試
    @Test
    func appDidBecomeActive_鎖定中驗證失敗_維持鎖定並標示失敗() async {
        // Given
        let store = TestStore(
            initialState: AppLockFeature.State(isBiometricUnlockEnabled: true, isLocked: true)
        ) {
            AppLockFeature()
        } withDependencies: {
            $0.biometricAuthService.biometryType = {
                .touchID
            }
            $0.biometricAuthService.authenticate = { _ in
                .failure
            }
        }

        // When
        await store.send(.appDidBecomeActive) {
            $0.biometryType = .touchID
            $0.isUnlocking = true
        }

        // Then
        await store.receive(\.unlockAuthenticationFinished) {
            $0.unlockDidFail = true
            $0.isUnlocking = false
        }
    }

    /// 上次驗證失敗後重新嘗試可解除鎖定
    @Test
    func retryUnlockTapped_先前驗證失敗_解除鎖定() async {
        // Given
        let initialState = AppLockFeature.State(
            isBiometricUnlockEnabled: true,
            isLocked: true,
            unlockDidFail: true,
            biometryType: .touchID
        )
        let store = TestStore(initialState: initialState) {
            AppLockFeature()
        } withDependencies: {
            $0.biometricAuthService.authenticate = { _ in
                .success
            }
        }

        // When
        await store.send(.retryUnlockTapped) {
            $0.unlockDidFail = false
            $0.isUnlocking = true
        }

        // Then
        await store.receive(\.unlockAuthenticationFinished) {
            $0.isLocked = false
            $0.isUnlocking = false
        }
    }

    /// 依裝置生物辨識類型顯示對應的設定說明
    ///
    /// - Parameters:
    ///   - previousBiometryType: 更新前的生物辨識類型
    ///   - biometryType: 裝置回報的生物辨識類型
    ///   - expectedUnlockButtonTitle: 預期的解鎖按鈕文案
    ///   - expectedProtectionDescription: 預期的設定頁說明
    /// - Note: 三組都在保護未啟用下執行，也守住只更新生物辨識類型、不進入解鎖
    @Test(arguments: [
        (
            BiometricAuthService.BiometryKind.unavailable,
            BiometricAuthService.BiometryKind.faceID,
            "使用 Face ID 解鎖",
            "開啟後，離開 App 時會鎖定畫面內容；再次使用 App 時，需要通過 Face ID 或密碼驗證才能繼續使用。"
        ),
        (
            .unavailable,
            .touchID,
            "使用 Touch ID 解鎖",
            "開啟後，離開 App 時會鎖定畫面內容；再次使用 App 時，需要通過 Touch ID 或密碼驗證才能繼續使用。"
        ),
        (
            .faceID,
            .unavailable,
            "解鎖",
            "開啟後，離開 App 時會鎖定畫面內容；再次使用 App 時，需要通過裝置密碼驗證才能繼續使用。"
        ),
    ])
    func appDidBecomeActive_裝置生物辨識類型_顯示對應設定說明(
        previousBiometryType: BiometricAuthService.BiometryKind,
        biometryType: BiometricAuthService.BiometryKind,
        expectedUnlockButtonTitle: String,
        expectedProtectionDescription: String
    ) async {
        // Given
        let store = TestStore(
            initialState: AppLockFeature.State(biometryType: previousBiometryType)
        ) {
            AppLockFeature()
        } withDependencies: {
            $0.biometricAuthService.biometryType = {
                biometryType
            }
        }

        // When
        await store.send(.appDidBecomeActive) {
            $0.biometryType = biometryType
        }

        // Then
        #expect(store.state.unlockButtonTitleKey == LocalizedStringKey(expectedUnlockButtonTitle))
        #expect(
            store.state.protectionDescriptionKey
                == LocalizedStringKey(expectedProtectionDescription)
        )
    }

    /// 保護關閉時點擊重新驗證不會改變狀態
    @Test
    func retryUnlockTapped_保護未啟用_維持原狀() async {
        // Given
        let store = TestStore(initialState: AppLockFeature.State()) {
            AppLockFeature()
        }

        // When
        await store.send(.retryUnlockTapped)

        // Then
        #expect(!store.state.isUnlocking)
    }
}

// MARK: - Private Method

private extension AppLockFeatureTests {

    /// 驗證失敗或取消時預期顯示的說明
    static var expectedFailureAlert: AlertState<AppLockFeature.Action.Alert> {
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

    /// 裝置不支援本機驗證時預期顯示的說明
    static var expectedUnsupportedAlert: AlertState<AppLockFeature.Action.Alert> {
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
}
