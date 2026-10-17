//
//  AppLockFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/31.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// 驗證場景轉換的鎖定、解鎖與回前景委派
@MainActor
struct AppLockFeatureTests {

    /// 保護已啟用時進入背景會鎖定內容，不請求驗證
    @Test
    func scenePhaseChanged_進入背景且保護已啟用_鎖定內容() async {
        // Given
        let store = TestStore(initialState: AppLockFeature.State(isBiometricUnlockEnabled: true)) {
            AppLockFeature()
        }

        // When
        await store.send(.view(.scenePhaseChanged(.background))) {
            $0.isLocked = true
        }

        // Then
        await store.finish()
        #expect(store.state.isLocked)
    }

    /// 保護未啟用時進入背景不鎖定，也不發出回前景委派
    @Test
    func scenePhaseChanged_進入背景且保護未啟用_維持未鎖定() async {
        // Given
        let store = TestStore(initialState: AppLockFeature.State()) {
            AppLockFeature()
        }

        // When
        await store.send(.view(.scenePhaseChanged(.background)))

        // Then
        await store.finish()
        #expect(!store.state.isLocked)
    }

    /// 回到前景先通知殼層，驗證成功後解除鎖定並清除先前的失敗標記
    ///
    /// - Parameter biometryType: 裝置回報的生物辨識類型
    @Test(arguments: [BiometricAuthService.BiometryKind.faceID, .touchID, .unavailable])
    func scenePhaseChanged_回到前景且鎖定中驗證成功_解除鎖定並送出回前景委派(
        biometryType: BiometricAuthService.BiometryKind
    ) async {
        // Given
        let reasons = LockIsolated<[String]>([])
        let initial = AppLockFeature.State(
            isBiometricUnlockEnabled: true,
            isLocked: true,
            unlockDidFail: true
        )
        let store = TestStore(initialState: initial) {
            AppLockFeature()
        } withDependencies: {
            $0.biometricAuthService.biometryType = {
                biometryType
            }
            $0.biometricAuthService.authenticate = { reason in
                reasons.withValue {
                    $0.append(reason)
                }
                return .success
            }
        }

        // When
        await store.send(.view(.scenePhaseChanged(.active))) {
            $0.biometryType = biometryType
            $0.isUnlocking = true
        }

        // Then
        await store.receive(\.delegate.didBecomeActive)
        await store.receive(\.unlockResponse) {
            $0.isLocked = false
            $0.unlockDidFail = false
            $0.isUnlocking = false
        }
        await store.finish()
        #expect(reasons.value.count == 1)
    }

    /// 解鎖失敗或取消時仍通知殼層回到前景，內容維持鎖定並標記失敗
    ///
    /// - Parameter result: 驗證失敗或取消的結果
    @Test(arguments: [BiometricAuthService.AuthenticationResult.failure, .cancelled])
    func scenePhaseChanged_回到前景且鎖定中驗證失敗_維持鎖定並標示失敗(
        result: BiometricAuthService.AuthenticationResult
    ) async {
        // Given
        let initial = AppLockFeature.State(isBiometricUnlockEnabled: true, isLocked: true)
        let store = TestStore(initialState: initial) {
            AppLockFeature()
        } withDependencies: {
            $0.biometricAuthService.biometryType = {
                .touchID
            }
            $0.biometricAuthService.authenticate = { _ in
                result
            }
        }

        // When
        await store.send(.view(.scenePhaseChanged(.active))) {
            $0.biometryType = .touchID
            $0.isUnlocking = true
        }

        // Then
        await store.receive(\.delegate.didBecomeActive)
        await store.receive(\.unlockResponse) {
            $0.unlockDidFail = true
            $0.isUnlocking = false
        }
        await store.finish()
        #expect(store.state.isLocked)
    }

    /// 內容已解鎖時回到前景只更新辨識類型與送出委派，不再請求驗證
    @Test
    func scenePhaseChanged_回到前景且未鎖定_只更新辨識類型並送出回前景委派() async {
        // Given
        let initial = AppLockFeature.State(isBiometricUnlockEnabled: true)
        let store = TestStore(initialState: initial) {
            AppLockFeature()
        } withDependencies: {
            $0.biometricAuthService.biometryType = {
                .faceID
            }
        }

        // When
        await store.send(.view(.scenePhaseChanged(.active))) {
            $0.biometryType = .faceID
        }

        // Then
        await store.receive(\.delegate.didBecomeActive)
        await store.finish()
        #expect(!store.state.isUnlocking)
    }

    /// 非作用中不改鎖定或驗證狀態，也不送出委派
    @Test
    func scenePhaseChanged_轉為非作用中_狀態不變也不送委派() async {
        // Given
        let initial = AppLockFeature.State(isBiometricUnlockEnabled: true, isLocked: true)
        let store = TestStore(initialState: initial) {
            AppLockFeature()
        }

        // When
        await store.send(.view(.scenePhaseChanged(.inactive)))

        // Then
        await store.finish()
        #expect(store.state == initial)
    }

    /// 上次驗證失敗後重試會清空失敗標記，成功後解除鎖定
    @Test
    func retryUnlockTapped_先前驗證失敗_解除鎖定() async {
        // Given
        let initial = AppLockFeature.State(
            isBiometricUnlockEnabled: true,
            isLocked: true,
            unlockDidFail: true,
            biometryType: .touchID
        )
        let store = TestStore(initialState: initial) {
            AppLockFeature()
        } withDependencies: {
            $0.biometricAuthService.authenticate = { _ in
                .success
            }
        }

        // When
        await store.send(.view(.retryUnlockTapped)) {
            $0.unlockDidFail = false
            $0.isUnlocking = true
        }

        // Then
        await store.receive(\.unlockResponse) {
            $0.isLocked = false
            $0.isUnlocking = false
        }
        await store.finish()
    }

    /// 保護未啟用時重試不呼叫驗證，也不改狀態
    @Test
    func retryUnlockTapped_保護未啟用_維持原狀() async {
        // Given
        let store = TestStore(initialState: AppLockFeature.State()) {
            AppLockFeature()
        }

        // When
        await store.send(.view(.retryUnlockTapped))

        // Then
        await store.finish()
        #expect(!store.state.isUnlocking)
    }
}
