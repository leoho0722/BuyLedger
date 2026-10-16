//
//  SnapshotTests+More.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import BuyLedger

extension SnapshotTests {

    /// 「更多」分頁的入口清單，列出工具、管理項目與設定入口
    ///
    /// - Note: 清單本身即含 `NavigationStack`，與分頁內容相同
    /// - Note: 使用 `EmptyReducer`，畫面不會送出任何 Service 呼叫
    /// - Note: 尺寸為 iPhone 直向 393 × 852，入口清單完整落在畫面內
    @Test
    func moreView_預設清單_顯示各入口() {
        TestDependencies.withFixedNow {
            // Given
            let state = MoreFeature.State(appVersion: "1.0")

            // When
            let view = MoreView(
                store: Store(initialState: state) {
                    EmptyReducer()
                },
                language: .traditionalChinese
            )
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 設定頁以預設偏好開啟時，依序顯示語言、AI 摘要、預設幣別、月度目標、App 鎖定與版本等區段
    ///
    /// - Note: 包在 `NavigationStack` 內，與從「更多」推入後的畫面相同
    /// - Note: 使用 `EmptyReducer`，`.task` 不會呼叫 Service
    /// - Note: 版本以字面值 "1.0" 注入，不讀取 `Bundle`
    /// - Note: 表單共六個區段，高度加到 1800 露出全部列
    @Test
    func settingsView_預設偏好_顯示版本與偏好列() {
        TestDependencies.withFixedNow {
            // Given
            let state = SettingsFeature.State(appVersion: "1.0")

            // When
            let view = NavigationStack {
                SettingsView(
                    store: Store(initialState: state) {
                        EmptyReducer()
                    }
                )
            }
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .frame(width: 393, height: 1_800)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 設定頁開啟 AI 摘要與 App 鎖定後，兩個開關皆為開啟，App 鎖定以 Face ID 的文案呈現
    ///
    /// - Note: 以預設偏好改寫 AI 摘要與 App 鎖定兩個欄位，其餘欄位維持預設值
    /// - Note: `biometryType` 以字面值 `.faceID` 注入
    /// - Note: 包在 `NavigationStack` 內
    /// - Note: 使用 `EmptyReducer`
    /// - Note: 尺寸與預設偏好的設定頁相同，為 393 × 1800
    @Test
    func settingsView_開啟AI摘要與生物辨識_顯示對應列() {
        TestDependencies.withFixedNow {
            // Given
            var snapshot = SettingsSnapshot.default
            snapshot.isAISummaryEnabled = true
            snapshot.isBiometricUnlockEnabled = true
            let state = SettingsFeature.State(
                snapshot: snapshot,
                appVersion: "1.0",
                biometryType: .faceID
            )

            // When
            let view = NavigationStack {
                SettingsView(
                    store: Store(initialState: state) {
                        EmptyReducer()
                    }
                )
            }
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .frame(width: 393, height: 1_800)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// App 鎖定畫面在已啟用生物辨識且尚未驗證失敗時，顯示鎖頭、說明文字與 Face ID 解鎖鈕
    ///
    /// - Note: 解鎖鈕為 `.borderedProminent`，離屏渲染會整張變黑，改於 key window 渲染
    /// - Note: 尺寸為 iPhone 直向 393 × 852
    /// - Note: `AppLockView` 不依尺寸分類分流
    @Test
    func appLockView_生物辨識解鎖_顯示解鎖鈕() {
        TestDependencies.withFixedNow {
            // Given
            let state = AppLockFeature.State(
                isBiometricUnlockEnabled: true,
                isLocked: true,
                biometryType: .faceID
            )

            // When
            let view = AppLockView(
                store: Store(initialState: state) {
                    EmptyReducer()
                }
            )
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// App 鎖定畫面在驗證失敗後，於解鎖鈕上方顯示失敗說明，解鎖鈕仍可再次點按
    ///
    /// - Note: 失敗狀態只設定 `unlockDidFail`，`isUnlocking` 維持 `false`，解鎖鈕為可用狀態
    /// - Note: 解鎖鈕為 `.borderedProminent`，於 key window 渲染
    /// - Note: 尺寸為 iPhone 直向 393 × 852
    @Test
    func appLockView_解鎖失敗_顯示失敗訊息與重試鈕() {
        TestDependencies.withFixedNow {
            // Given
            let state = AppLockFeature.State(
                isBiometricUnlockEnabled: true,
                isLocked: true,
                unlockDidFail: true,
                biometryType: .faceID
            )

            // When
            let view = AppLockView(
                store: Store(initialState: state) {
                    EmptyReducer()
                }
            )
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }
}
