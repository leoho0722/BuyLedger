//
//  AppLockTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/31.
//

import XCTest

/// App 鎖定畫面的 UI 測試
@MainActor
final class AppLockTests: BLUITestCase {

    /// 驗證生物辨識替身失敗時，點重新驗證後，重試產生新的失敗結果，且仍停留在鎖定畫面
    ///
    /// - Throws: 失敗訊息不存在、重試未進入執行中或重試結果未重新出現時丟出測試錯誤
    /// - Note: App 鎖定已啟用且生物辨識替身會失敗
    func testTapRetry_驗證替身失敗_重試後仍停在鎖定畫面() throws {
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
        lockScreen.tapRetry()

        // Then
        // 先等到重試進入執行中，之後恢復可用時的失敗訊息才是重試產生的新結果，不會沿用冷啟動的失敗
        try requireCondition(lockScreen.waitForRetryToBegin(), in: app, "重新驗證未進入執行中狀態")
        try requireCondition(lockScreen.waitForFailedRetryResult(), in: app, "重新驗證沒有完成一次新的失敗驗證")
        if !lockScreen.isDisplayed {
            failWithDiagnostics(in: app, "重新驗證失敗後鎖定畫面不應消失")
        }

        assertNoSystemBiometricPrompt(in: app)
    }

    /// 驗證 App 鎖定已啟用且生物辨識替身成功時，冷啟動後自動解鎖，顯示一般內容
    func testLaunch_App鎖定啟用且驗證成功_自動解鎖顯示一般內容() {
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

    /// 驗證未帶鎖定旗標啟動時，不進入鎖定畫面，直接看到一般內容，既有行為不變
    func testLaunch_未啟用App鎖定_直接顯示一般內容() {
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

    /// 確認 SpringBoard 沒有系統生物辨識彈窗，有則附診斷失敗
    ///
    /// - Parameter app: 受測 App，用於附上失敗診斷
    func assertNoSystemBiometricPrompt(in app: XCUIApplication) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.alerts.count > 0 {
            failWithDiagnostics(in: app, "出現系統層級彈窗，本機驗證替身未接管授權")
        }
    }
}
