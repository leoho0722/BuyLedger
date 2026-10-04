//
//  AppLockTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/31.
//

import XCTest

/// App 鎖定畫面的介面測試
final class AppLockTests: BLUITestCase {

    /// 失敗替身讓自動解鎖停留在鎖定畫面
    ///
    /// - Throws: 失敗訊息不存在或重試結果未重新出現時拋出測試錯誤
    /// - Note: App 鎖定已啟用且生物辨識替身會失敗，點擊重新驗證後，重試完成會收到新的失敗結果且仍停留在鎖定畫面
    @MainActor
    func testAppLockEnabledStartsLockedAndStaysLockedWhenAuthenticationFails() throws(any Error) {
        // Given
        let app = launch(
            LaunchOptions(seed: .empty, isAppLockEnabled: true, biometricScenario: .failure)
        )
        let lockScreen = AppLockScreen(app: app)

        if !lockScreen.waitUntilReady() {
            failWithDiagnostics(in: app, "帶 -BLUITestAppLockEnabled 啟動後未直接進入鎖定畫面")
        }

        // 冷啟動驗證失敗後，鎖定畫面應提供重新驗證
        let retryButton = app.buttons[BLAccessibilityID.AppLock.retryButton]
        if !retryButton.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "鎖定畫面未提供重新驗證按鈕")
        }
        try requireCondition(lockScreen.waitForInitialFailure(), in: app, "冷啟動失敗結果未出現，無法驗證重新驗證流程")

        // When
        lockScreen.tapRetry(file: #filePath, line: #line)

        try requireCondition(lockScreen.waitForRetryToBegin(), in: app, "重新驗證未進入執行中狀態")

        // Then
        try requireCondition(lockScreen.waitForFailedRetryResult(), in: app, "重新驗證沒有完成一次新的失敗驗證")
        if !lockScreen.isDisplayed {
            failWithDiagnostics(in: app, "重新驗證失敗後鎖定畫面不應消失")
        }

        assertNoSystemBiometricPrompt(in: app)
    }

    /// 冷啟動自動解鎖成功後顯示一般內容
    @MainActor
    func testAppLockEnabledUnlocksAutomaticallyWhenAuthenticationSucceeds() {
        // Given
        let options = LaunchOptions(
            seed: .empty,
            isAppLockEnabled: true,
            biometricScenario: .success
        )

        // When
        let app = launch(options)

        // Then
        let dashboard = DashboardScreen(app: app)

        if !dashboard.waitUntilReady() {
            failWithDiagnostics(in: app, "驗證成功替身下未能在鎖定後自動回到一般內容")
        }

        assertNoSystemBiometricPrompt(in: app)
    }

    /// 未帶旗標時的既有行為不變：不進入鎖定畫面，直接看到一般內容
    @MainActor
    func testProtectionDisabledByDefaultShowsNormalContentDirectly() {
        // Given
        let options = LaunchOptions(seed: .empty)

        // When
        let app = launch(options)

        // Then
        let dashboard = DashboardScreen(app: app)

        if !dashboard.waitUntilReady() {
            failWithDiagnostics(in: app, "未開啟 App 鎖定時總覽頁未就緒")
        }

        let lockScreen = AppLockScreen(app: app)
        if lockScreen.isDisplayed {
            failWithDiagnostics(in: app, "未開啟 App 鎖定卻出現鎖定畫面")
        }
    }
}

// MARK: - Private Method

private extension AppLockTests {

    /// 驗證 SpringBoard 沒有系統生物辨識提示
    ///
    /// - Parameter app: 受測 App，用於附上失敗診斷
    @MainActor
    func assertNoSystemBiometricPrompt(in app: XCUIApplication) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.alerts.count > 0 {
            failWithDiagnostics(in: app, "出現系統層級彈窗，本機驗證替身未接管授權")
        }
    }
}
