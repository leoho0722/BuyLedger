//
//  RootFeatureAppShellTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試，以 TestStore 驗證設定頁的改動同步到殼層偏好、更多頁、總覽目標與 App 鎖定投影
@MainActor
struct RootFeatureAppShellTests {

    /// 驗證設定頁改語言時只保存一次，並同步更新根偏好與更多頁的設定，根偏好的語言改為英文
    @Test
    func more_設定改語言_殼層偏好與更多頁投影同步() async {
        // Given
        let saved = LockIsolated<[SettingsSnapshot]>([])
        var initial = RootFeature.State()
        initial.more.showSettings()
        var expected = initial.preferences
        expected.language = .english
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.settingsService.save = { snapshot in
                saved.withValue {
                    $0.append(snapshot)
                }
            }
        }

        // When
        await store.send(
            .more(.path(.element(id: 0, action: .settings(.binding(.set(\.language, .english))))))
        ) {
            $0.more.path[id: 0, case: \.settings]?.language = .english
        }

        // Then
        await store.receive(\.more.path[id: 0].settings.delegate.preferencesChanged, expected)
        await store.receive(\.more.delegate.preferencesChanged, expected) {
            $0.preferences = expected
            $0.more.preferences = expected
        }
        await store.finish()
        #expect(saved.value == [expected])
        #expect(store.state.preferences.language == .english)
    }

    /// 驗證設定頁修改月目標後，根偏好與總覽頁的目標同步更新，不必重新載入
    @Test
    func more_設定改月目標_總覽目標同步() async {
        // Given
        let saved = LockIsolated<[SettingsSnapshot]>([])
        var initial = RootFeature.State()
        initial.more.showSettings()
        var expected = initial.preferences
        expected.monthlyProfitGoalTWD = 120_000
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.settingsService.save = { snapshot in
                saved.withValue {
                    $0.append(snapshot)
                }
            }
        }

        // When
        await store.send(
            .more(
                .path(
                    .element(
                        id: 0,
                        action: .settings(.binding(.set(\.monthlyProfitGoalTWD, 120_000)))
                    )
                )
            )
        ) {
            $0.more.path[id: 0, case: \.settings]?.monthlyProfitGoalTWD = 120_000
        }

        // Then
        await store.receive(\.more.path[id: 0].settings.delegate.preferencesChanged, expected)
        await store.receive(\.more.delegate.preferencesChanged, expected) {
            $0.preferences = expected
            $0.more.preferences = expected
            $0.dashboard.monthlyProfitGoalTWD = 120_000
        }
        await store.finish()
        #expect(saved.value == [expected])
        #expect(store.state.dashboard.monthlyProfitGoalTWD == 120_000)
    }

    /// 驗證 App 已解鎖且無解鎖失敗紀錄時，設定頁關閉生物辨識解鎖，只同步設定與鎖定投影，不改動鎖定與失敗狀態
    ///
    /// - Throws: 解鎖失敗的紀錄已存在時由 `try #require` 丟出
    @Test
    func more_設定關閉App鎖定_鎖定投影同步為關閉() async throws {
        // Given
        var preferences = SettingsSnapshot.default
        preferences.isBiometricUnlockEnabled = true
        var initial = RootFeature.State(preferences: preferences)
        initial.appLock.isLocked = false
        initial.more.showSettings()
        try #require(!initial.appLock.unlockDidFail)
        let saved = LockIsolated<[SettingsSnapshot]>([])
        var expected = preferences
        expected.isBiometricUnlockEnabled = false
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.settingsService.save = { snapshot in
                saved.withValue {
                    $0.append(snapshot)
                }
            }
        }

        // When
        await store.send(
            .more(.path(.element(id: 0, action: .settings(.view(.appLockToggled(false))))))
        ) {
            $0.more.path[id: 0, case: \.settings]?.isBiometricUnlockEnabled = false
        }

        // Then
        await store.receive(\.more.path[id: 0].settings.delegate.preferencesChanged, expected)
        await store.receive(\.more.delegate.preferencesChanged, expected) {
            $0.preferences = expected
            $0.more.preferences = expected
            $0.appLock.isBiometricUnlockEnabled = false
        }
        await store.finish()
        #expect(saved.value == [expected])
        #expect(!store.state.appLock.isLocked)
        #expect(!store.state.appLock.unlockDidFail)
    }
}
