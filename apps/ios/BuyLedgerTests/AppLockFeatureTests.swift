//
//  AppLockFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/31.
//

import ComposableArchitecture
import Foundation
import SwiftUI
import Testing
@testable import BuyLedger

/// 驗證啟用帳本保護須先驗證成功
@MainActor
struct AppLockFeatureTests {
    
    // MARK: - Tests
    
    @Test func enablingProtectionWritesTheSettingOnlyAfterAuthenticationSucceeds() async {
        let store = TestStore(initialState: AppLockFeature.State()) {
            AppLockFeature()
        } withDependencies: {
            $0[BiometricAuthClient.self] = BiometricAuthClient(
                isAvailable: { true },
                authenticate: { _ in .success },
                biometryType: { .faceID }
            )
        }
        
        // 切換開關不會在驗證完成前寫入設定。
        await store.send(.enableToggled(true))
        await store.receive(\.enableAuthenticationFinished) {
            $0.isBiometricUnlockEnabled = true
        }
    }
    
    @Test func enablingProtectionStaysOffWhenAuthenticationFails() async {
        let store = TestStore(initialState: AppLockFeature.State()) {
            AppLockFeature()
        } withDependencies: {
            $0[BiometricAuthClient.self] = BiometricAuthClient(
                isAvailable: { true },
                authenticate: { _ in .failure },
                biometryType: { .faceID }
            )
        }
        
        await store.send(.enableToggled(true))
        await store.receive(\.enableAuthenticationFinished) {
            $0.enableFailureAlert = Self.expectedFailureAlert
        }
        
        #expect(store.state.isBiometricUnlockEnabled == false)
    }
    
    @Test func enablingProtectionStaysOffWhenAuthenticationIsCancelled() async {
        let store = TestStore(initialState: AppLockFeature.State()) {
            AppLockFeature()
        } withDependencies: {
            $0[BiometricAuthClient.self] = BiometricAuthClient(
                isAvailable: { true },
                authenticate: { _ in .cancelled },
                biometryType: { .faceID }
            )
        }
        
        await store.send(.enableToggled(true))
        await store.receive(\.enableAuthenticationFinished) {
            $0.enableFailureAlert = Self.expectedFailureAlert
        }
        
        #expect(store.state.isBiometricUnlockEnabled == false)
    }
    
    @Test func enablingProtectionStaysOffWhenDeviceIsUnsupported() async {
        let store = TestStore(initialState: AppLockFeature.State()) {
            AppLockFeature()
        } withDependencies: {
            $0[BiometricAuthClient.self] = BiometricAuthClient(
                isAvailable: { false },
                authenticate: { _ in .success },
                biometryType: { .unavailable }
            )
        }
        
        // 裝置不支援時不驗證，直接關閉並顯示對應說明。
        await store.send(.enableToggled(true)) {
            $0.enableFailureAlert = Self.expectedUnsupportedAlert
        }
        
        #expect(store.state.isBiometricUnlockEnabled == false)
    }
    
    // MARK: 鎖定與解鎖
    
    @Test func resigningActiveLocksContentWhenProtectionIsEnabled() async {
        let store = TestStore(initialState: AppLockFeature.State(isBiometricUnlockEnabled: true)) {
            AppLockFeature()
        }
        
        await store.send(.appDidResignActive) {
            $0.isLocked = true
        }
    }
    
    @Test func becomingActiveUnlocksAfterSuccessfulAuthentication() async {
        let store = TestStore(
            initialState: AppLockFeature.State(isBiometricUnlockEnabled: true, isLocked: true)
        ) {
            AppLockFeature()
        } withDependencies: {
            $0[BiometricAuthClient.self] = BiometricAuthClient(
                isAvailable: { true },
                authenticate: { _ in .success },
                biometryType: { .faceID }
            )
        }
        
        await store.send(.appDidBecomeActive) {
            $0.biometryType = .faceID
        }
        // 以替身注入不同 biometryType 測試裝置差異。
        #expect(store.state.unlockButtonTitleKey == "使用 Face ID 解鎖")
        await store.receive(\.unlockAuthenticationFinished) {
            $0.isLocked = false
        }
    }
    
    @Test func unlockButtonFallsBackToNeutralLabelWhenBiometricsAreUnavailable() async {
        let store = TestStore(
            initialState: AppLockFeature.State(
                isBiometricUnlockEnabled: true,
                isLocked: true,
                biometryType: .faceID
            )
        ) {
            AppLockFeature()
        } withDependencies: {
            $0[BiometricAuthClient.self] = BiometricAuthClient(
                isAvailable: { true },
                authenticate: { _ in .success },
                biometryType: { .unavailable }
            )
        }
        
        // 裝置僅靠裝置密碼即可通過 isAvailable，仍可能沒有生物辨識硬體。
        // 文案須退回中性的「解鎖」，不得顯示殘缺句子 (如「使用  解鎖」)
        await store.send(.appDidBecomeActive) {
            $0.biometryType = .unavailable
        }
        #expect(store.state.unlockButtonTitleKey == "解鎖")
        await store.receive(\.unlockAuthenticationFinished) {
            $0.isLocked = false
        }
    }
    
    @Test func failedUnlockCanBeRetriedUntilSuccessful() async {
        let outcome = AuthenticationOutcomeBox(.failure)
        let store = TestStore(
            initialState: AppLockFeature.State(isBiometricUnlockEnabled: true, isLocked: true)
        ) {
            AppLockFeature()
        } withDependencies: {
            $0[BiometricAuthClient.self] = BiometricAuthClient(
                isAvailable: { true },
                authenticate: { _ in outcome.value },
                biometryType: { .touchID }
            )
        }
        
        await store.send(.appDidBecomeActive) {
            $0.biometryType = .touchID
        }
        #expect(store.state.unlockButtonTitleKey == "使用 Touch ID 解鎖")
        await store.receive(\.unlockAuthenticationFinished) {
            $0.unlockDidFail = true
        }
        // 鎖定畫面仍在，且失敗只提供再次嘗試，不提供跳過
        #expect(store.state.isLocked)
        
        outcome.value = .success
        await store.send(.retryUnlockTapped) {
            $0.unlockDidFail = false
        }
        await store.receive(\.unlockAuthenticationFinished) {
            $0.isLocked = false
        }
    }
    
    // MARK: 設定頁文案依機型顯示
    
    @Test func settingsCopyNamesFaceIDWhenAvailable() async {
        let store = TestStore(initialState: AppLockFeature.State()) {
            AppLockFeature()
        } withDependencies: {
            $0[BiometricAuthClient.self] = BiometricAuthClient(
                isAvailable: { true },
                authenticate: { _ in .success },
                biometryType: { .faceID }
            )
        }
        
        // 尚未開啟保護時也要先取得生物辨識類型。
        await store.send(.appDidBecomeActive) {
            $0.biometryType = .faceID
        }
        
        // 設定頁與鎖定畫面共用解鎖文案。
        #expect(store.state.unlockButtonTitleKey == "使用 Face ID 解鎖")
        #expect(
            store.state.protectionDescriptionKey == "開啟後，離開 App 時會鎖定畫面內容；再次使用 App 時，需要通過 Face ID 或密碼驗證才能檢視內容。"
        )
    }
    
    @Test func settingsCopyNamesTouchIDWhenAvailable() async {
        let store = TestStore(initialState: AppLockFeature.State()) {
            AppLockFeature()
        } withDependencies: {
            $0[BiometricAuthClient.self] = BiometricAuthClient(
                isAvailable: { true },
                authenticate: { _ in .success },
                biometryType: { .touchID }
            )
        }
        
        // 以替身注入 Touch ID，測試不同裝置類型。
        await store.send(.appDidBecomeActive) {
            $0.biometryType = .touchID
        }
        
        #expect(store.state.unlockButtonTitleKey == "使用 Touch ID 解鎖")
        #expect(
            store.state.protectionDescriptionKey == "開啟後，離開 App 時會鎖定畫面內容；再次使用 App 時，需要通過 Touch ID 或密碼驗證才能檢視內容。"
        )
    }
    
    @Test func settingsCopyFallsBackToNeutralWordingWhenBiometricsAreUnavailable() async {
        // 初始值設為 faceID，確認查詢後會改為 unavailable。
        let store = TestStore(initialState: AppLockFeature.State(biometryType: .faceID)) {
            AppLockFeature()
        } withDependencies: {
            $0[BiometricAuthClient.self] = BiometricAuthClient(
                isAvailable: { true },
                authenticate: { _ in .success },
                biometryType: { .unavailable }
            )
        }
        
        // 裝置僅靠裝置密碼即可通過 isAvailable，仍可能沒有生物辨識硬體。
        // 文案須退回中性敘述，不得顯示殘缺句子 (如「需要通過  或密碼驗證」)
        await store.send(.appDidBecomeActive) {
            $0.biometryType = .unavailable
        }
        
        #expect(store.state.unlockButtonTitleKey == "解鎖")
        #expect(
            store.state.protectionDescriptionKey == "開啟後，離開 App 時會鎖定畫面內容；再次使用 App 時，需要通過裝置密碼驗證才能檢視內容。"
        )
    }
    
    // MARK: 保護關閉時逐項不動作
    
    @Test func resigningActiveDoesNothingWhenProtectionIsDisabled() async {
        let store = TestStore(initialState: AppLockFeature.State()) {
            AppLockFeature()
        }
        
        // 無 trailing closure：斷言完全沒有狀態變化
        await store.send(.appDidResignActive)
    }
    
    @Test func becomingActiveDoesNothingWhenProtectionIsDisabled() async {
        let store = TestStore(initialState: AppLockFeature.State()) {
            AppLockFeature()
        }
        
        // 保護關閉時不驗證，但仍更新 biometryType。
        await store.send(.appDidBecomeActive) {
            $0.biometryType = .faceID
        }
    }
    
    @Test func retryUnlockDoesNothingWhenProtectionIsDisabled() async {
        let store = TestStore(initialState: AppLockFeature.State()) {
            AppLockFeature()
        }
        
        await store.send(.retryUnlockTapped)
    }
}

/// 讓替身在同一次測試內途中改變結果的容器 (先失敗、重試後成功)
private final class AuthenticationOutcomeBox: @unchecked Sendable {
    
    // MARK: - Data Properties
    
    /// 目前替身會回傳的結果
    var value: BiometricAuthClient.AuthenticationResult
    
    // MARK: - Init
    
    /// 以初始結果建立容器
    init(_ value: BiometricAuthClient.AuthenticationResult) {
        self.value = value
    }
}

// MARK: - Static Properties

private extension AppLockFeatureTests {
    
    /// 驗證失敗或取消時的預期說明對話框
    static var expectedFailureAlert: AlertState<AppLockFeature.Action.Alert> {
        AlertState {
            TextState("無法啟用帳本保護")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("關閉")
            }
        } message: {
            TextState("身份驗證失敗或已取消，帳本保護未開啟。")
        }
    }
    
    /// 裝置不支援時的預期說明對話框
    static var expectedUnsupportedAlert: AlertState<AppLockFeature.Action.Alert> {
        AlertState {
            TextState("無法啟用帳本保護")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("關閉")
            }
        } message: {
            TextState("此裝置目前無法使用本機驗證，帳本保護未開啟。")
        }
    }
}
