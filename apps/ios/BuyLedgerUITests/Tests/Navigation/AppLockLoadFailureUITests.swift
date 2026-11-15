//
//  AppLockLoadFailureUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/15.
//

import XCTest

/// 訂單延遲讀取期間發生 App 解鎖時，總覽載入狀態的 UI 測試
@MainActor
final class AppLockLoadFailureUITests: BLUITestCase {

    /// 驗證冷啟動解鎖發生在訂單讀取期間，總覽仍收到失敗結果且不再回到載入中
    ///
    /// - Throws: 鎖定畫面不在時間窗內、總覽未進入載入中或失敗畫面取樣不穩定時丟出測試錯誤
    /// - Note: 情境測試，固定 app-lock 規格的冷啟動解鎖範例
    func testScenePhaseChanged_冷啟動解鎖時訂單延遲讀取失敗_總覽收到失敗結果() throws {
        // Given
        let options = LaunchOptions(
            loadFailure: .ordersDelayed,
            isAppLockEnabled: true,
            biometricScenario: .successDelayed
        )
        let app = try launch(options)
        let lockScreen = AppLockScreen(app: app)
        try requireCondition(
            lockScreen.waitUntilReady(timeout: 1),
            in: app,
            "啟動後鎖定畫面不在驗證成功前的時間窗內，時間窗不存在"
        )

        // When
        try requireCondition(
            DashboardScreen(app: app).waitForLoading(timeout: 8),
            in: app,
            "解鎖後總覽未顯示載入中，訂單讀取已結束或未進行，時間窗不存在"
        )

        // Then
        try assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Dashboard.loadFailure,
            present: [BLAccessibilityID.Dashboard.loadFailureRetryButton],
            absent: [BLAccessibilityID.Dashboard.loading],
            context: "冷啟動解鎖後的總覽",
            firstAppearanceTimeout: options.delayedReadFailureTimeout
        )
    }

    /// 驗證 App 進入背景上鎖後，在訂單讀取期間回前景解鎖，總覽仍收到失敗結果且不再回到載入中
    ///
    /// - Throws: 總覽未進入載入中、App 未進入背景或失敗畫面取樣不穩定時丟出測試錯誤
    /// - Note: 情境測試，固定 app-lock 規格的背景上鎖範例
    func testScenePhaseChanged_背景上鎖回前景解鎖_總覽收到失敗結果() throws {
        // Given
        let options = LaunchOptions(
            loadFailure: .ordersDelayed,
            isAppLockEnabled: true,
            biometricScenario: .success
        )
        let app = try launch(options)
        let dashboard = DashboardScreen(app: app)
        try requireCondition(
            dashboard.waitForLoading(timeout: 5),
            in: app,
            "啟動後總覽未顯示載入中，訂單讀取已結束或未進行，時間窗不存在"
        )
        let loadingSeenAt = Date.now

        // When
        XCUIDevice.shared.press(.home)
        try requireCondition(
            waitUntilInBackground(app, timeout: 5),
            in: app,
            "按下 Home 後 App 未進入背景，沒有上鎖"
        )
        // 從看到載入中起算 3 秒後才回前景 (對齊規格範例)，進入背景前已經過的時間要扣除
        let backgroundDuration: TimeInterval = 3
        let remainingDuration = backgroundDuration - Date.now.timeIntervalSince(loadingSeenAt)
        Polling.pause(for: remainingDuration) // App 需在背景停留滿 3 秒，剩餘時間不大於零時不等待
        app.activate()

        // Then
        try requireCondition(
            dashboard.waitForLoading(timeout: 3),
            in: app,
            "回前景解鎖後總覽未顯示載入中，訂單讀取已結束或被取消，時間窗不存在"
        )
        try assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Dashboard.loadFailure,
            present: [BLAccessibilityID.Dashboard.loadFailureRetryButton],
            absent: [BLAccessibilityID.Dashboard.loading],
            context: "背景上鎖並解鎖後的總覽",
            firstAppearanceTimeout: options.delayedReadFailureTimeout
        )
    }
}

// MARK: - Private Method

private extension AppLockLoadFailureUITests {

    /// 輪詢等待 App 離開前景
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - timeout: 等待進入背景的秒數
    /// - Returns: App 是否在逾時前進入 `runningBackground` 或 `runningBackgroundSuspended`
    func waitUntilInBackground(_ app: XCUIApplication, timeout: TimeInterval) -> Bool {
        Polling.wait(timeout: timeout) {
            app.state == .runningBackground || app.state == .runningBackgroundSuspended
        }
    }
}
