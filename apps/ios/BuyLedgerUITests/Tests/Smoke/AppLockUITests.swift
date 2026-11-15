//
//  AppLockUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/31.
//

import XCTest

/// App 鎖定畫面的 UI 測試
@MainActor
final class AppLockUITests: BLUITestCase {

    /// 驗證生物辨識替身失敗時，點重新驗證後，重試產生新的失敗結果，且仍停留在鎖定畫面
    ///
    /// - Throws: 失敗訊息不存在、重試未進入執行中或重試結果未重新出現時丟出測試錯誤
    /// - Note: App 鎖定已啟用且生物辨識替身會失敗
    func testRetryUnlockTapped_驗證替身失敗_重試後仍停在鎖定畫面() throws {
        // Given
        let app = try launch(
            LaunchOptions(seed: .empty, isAppLockEnabled: true, biometricScenario: .failure)
        )
        let lockScreen = AppLockScreen(app: app)
        try requireCondition(
            lockScreen.waitUntilReady(),
            in: app,
            "帶 -BLUITestAppLockEnabled 啟動後未直接進入鎖定畫面"
        )
        // 冷啟動驗證失敗後，鎖定畫面應提供重新驗證
        try requireCondition(lockScreen.waitForRetryButton(), in: app, "鎖定畫面未提供重新驗證按鈕")
        try requireCondition(
            lockScreen.waitForInitialFailure(),
            in: app,
            "冷啟動失敗結果未出現，無法驗證重新驗證流程"
        )

        // When
        try lockScreen.tapRetry()

        // Then
        // 先等到重試進入執行中，之後恢復可用時的失敗訊息才是重試產生的新結果，不會沿用冷啟動的失敗
        try requireCondition(lockScreen.waitForRetryToBegin(), in: app, "重新驗證未進入執行中狀態")
        try requireCondition(
            lockScreen.waitForFailedRetryResult(),
            in: app,
            "重新驗證沒有完成一次新的失敗驗證"
        )
        try requireCondition(lockScreen.isDisplayed, in: app, "重新驗證失敗後鎖定畫面不應消失")
        try BLUITestConfigurationUITestSupport.assertNoSystemPrompt(in: app)
    }

    /// 驗證 App 鎖定已啟用且生物辨識替身成功時，冷啟動後自動解鎖，顯示一般內容
    ///
    /// - Throws: App 未能啟動、總覽頁未就緒或出現系統層級彈窗時丟出測試錯誤
    func testScenePhaseChanged_App鎖定啟用且驗證成功_冷啟動自動解鎖顯示一般內容() throws {
        // Given
        let options = LaunchOptions(
            seed: .empty,
            isAppLockEnabled: true,
            biometricScenario: .success
        )

        // When
        let app = try launch(options)

        // Then
        let dashboard = DashboardScreen(app: app)
        try requireCondition(dashboard.waitUntilReady(), in: app, "驗證成功替身下未能在鎖定後自動回到一般內容")
        try BLUITestConfigurationUITestSupport.assertNoSystemPrompt(in: app)
    }

    /// 驗證未帶鎖定旗標啟動時，不進入鎖定畫面，直接看到一般內容，既有行為不變
    ///
    /// - Throws: App 未能啟動、總覽頁未就緒或出現鎖定畫面時丟出測試錯誤
    func testScenePhaseChanged_未啟用App鎖定_冷啟動直接顯示一般內容() throws {
        // Given
        let options = LaunchOptions(seed: .empty)

        // When
        let app = try launch(options)

        // Then
        let dashboard = DashboardScreen(app: app)
        try requireCondition(dashboard.waitUntilReady(), in: app, "未開啟 App 鎖定時總覽頁未就緒")
        let lockScreen = AppLockScreen(app: app)
        try requireCondition(!lockScreen.isDisplayed, in: app, "未開啟 App 鎖定卻出現鎖定畫面")
    }
}
