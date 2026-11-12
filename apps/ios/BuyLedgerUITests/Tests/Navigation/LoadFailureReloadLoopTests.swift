//
//  LoadFailureReloadLoopTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/9.
//

import XCTest

/// 訂單持續讀取失敗時，切換分頁與離開讀取發起畫面的載入狀態測試
@MainActor
final class LoadFailureReloadLoopTests: BLUITestCase {

    /// 驗證訂單每次讀取失敗時，依序切換分頁後訂單、總覽與分析持續顯示失敗訊息且不再載入
    func testTabSwitch_訂單每次讀取皆失敗_三頁穩定顯示失敗畫面() {
        // Given
        let app = launch(LaunchOptions(loadFailure: .orders))
        let navigator = AppNavigator(app: app)

        // When
        navigator.selectTab(.orders)
        navigator.selectTab(.more)
        navigator.selectTab(.orders)

        // Then
        guard assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Orders.listLoadFailure,
            present: [BLAccessibilityID.Orders.listLoadFailureRetryButton],
            absent: [BLAccessibilityID.Orders.listLoading],
            context: "切換更多再返回訂單清單"
        ) else {
            return
        }

        // When
        navigator.selectTab(.dashboard)

        // Then
        guard assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Dashboard.loadFailure,
            present: [BLAccessibilityID.Dashboard.loadFailureRetryButton],
            absent: [BLAccessibilityID.Dashboard.loading],
            context: "切回總覽"
        ) else {
            return
        }

        // When
        navigator.selectTab(.insights)

        // Then
        assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Insights.loadFailure,
            present: [BLAccessibilityID.Insights.loadFailureRetryButton],
            absent: [BLAccessibilityID.Insights.loading],
            context: "切到分析"
        )
    }

    /// 驗證分析頁發起延遲讀取後，在載入中切到訂單清單仍能收到失敗結果且不再載入
    func testLeaveInsights_訂單延遲讀取失敗_離開後清單仍收到失敗結果() {
        // Given
        let app = launch(LaunchOptions(loadFailure: .ordersDelayed))
        let navigator = AppNavigator(app: app)
        navigator.selectTab(.orders)
        let failure = app.descendants(matching: .any)[BLAccessibilityID.Orders.listLoadFailure]
        guard failure.waitForExistence(timeout: 15) else {
            failWithDiagnostics(in: app, "啟動後訂單清單未顯示第一次延遲讀取失敗")
            return
        }

        // When
        navigator.selectTab(.insights)
        let insightsLoading = app.descendants(matching: .any)[BLAccessibilityID.Insights.loading]
        guard insightsLoading.waitForExistence(timeout: 10) else {
            failWithDiagnostics(in: app, "分析頁未顯示載入中，無法確認已發起新的訂單讀取")
            return
        }
        navigator.selectTab(.orders)

        // Then
        let ordersLoading = app.descendants(matching: .any)[BLAccessibilityID.Orders.listLoading]
        guard ordersLoading.waitForExistence(timeout: 1) else {
            failWithDiagnostics(in: app, "離開時訂單清單不在載入中，時間窗不存在")
            return
        }
        assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Orders.listLoadFailure,
            present: [BLAccessibilityID.Orders.listLoadFailureRetryButton],
            absent: [BLAccessibilityID.Orders.listLoading],
            context: "離開分析頁後的訂單清單"
        )
    }

    /// 驗證客戶頁發起延遲讀取後，在載入中切到訂單清單仍能收到失敗結果且不再載入
    func testLeaveCustomers_訂單延遲讀取失敗_離開後清單仍收到失敗結果() {
        // Given
        let app = launch(LaunchOptions(loadFailure: .ordersDelayed))
        let navigator = AppNavigator(app: app)
        navigator.selectTab(.orders)
        let failure = app.descendants(matching: .any)[BLAccessibilityID.Orders.listLoadFailure]
        guard failure.waitForExistence(timeout: 15) else {
            failWithDiagnostics(in: app, "啟動後訂單清單未顯示第一次延遲讀取失敗")
            return
        }

        // When
        _ = CustomersScreen.open(from: app)
        // 剛進入時可能先顯示上一次的失敗，等 Root 讀完主檔目錄、請求訂單後才轉為載入中，5 秒為估計值
        let customersLoading = app.descendants(matching: .any)[
            BLAccessibilityID.Customers.listLoading
        ]
        guard customersLoading.waitForExistence(timeout: 5) else {
            failWithDiagnostics(in: app, "客戶頁未顯示載入中，無法確認已進入發起讀取的畫面")
            return
        }
        navigator.selectTab(.orders)

        // Then
        let ordersLoading = app.descendants(matching: .any)[BLAccessibilityID.Orders.listLoading]
        guard ordersLoading.waitForExistence(timeout: 1) else {
            failWithDiagnostics(in: app, "離開時訂單清單不在載入中，時間窗不存在")
            return
        }
        assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Orders.listLoadFailure,
            present: [BLAccessibilityID.Orders.listLoadFailureRetryButton],
            absent: [BLAccessibilityID.Orders.listLoading],
            context: "離開客戶頁後的訂單清單"
        )
    }

    /// 驗證冷啟動解鎖發生在訂單讀取期間，總覽仍收到失敗結果且不再回到載入中
    ///
    /// - Note: 情境測試，固定 app-lock 規格的冷啟動解鎖範例
    func testColdStartUnlock_訂單延遲讀取失敗_解鎖後總覽收到失敗結果() {
        // Given
        let app = launch(
            LaunchOptions(
                loadFailure: .ordersDelayed,
                isAppLockEnabled: true,
                biometricScenario: .successDelayed
            )
        )
        let lockScreen = AppLockScreen(app: app)
        guard lockScreen.waitUntilReady(timeout: 1) else {
            failWithDiagnostics(in: app, "啟動後鎖定畫面不在驗證成功前的時間窗內，時間窗不存在")
            return
        }

        // When
        let dashboardLoading = app.descendants(matching: .any)[BLAccessibilityID.Dashboard.loading]
        guard dashboardLoading.waitForExistence(timeout: 8) else {
            failWithDiagnostics(in: app, "解鎖後總覽未顯示載入中，訂單讀取已結束或未進行，時間窗不存在")
            return
        }

        // Then
        assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Dashboard.loadFailure,
            present: [BLAccessibilityID.Dashboard.loadFailureRetryButton],
            absent: [BLAccessibilityID.Dashboard.loading],
            context: "冷啟動解鎖後的總覽",
            firstAppearanceTimeout: 7
        )
    }

    /// 驗證 App 進入背景上鎖後，在訂單讀取期間回前景解鎖，總覽仍收到失敗結果且不再回到載入中
    ///
    /// - Note: 情境測試，固定 app-lock 規格的背景上鎖範例
    func testBackgroundLock_訂單延遲讀取失敗_回前景解鎖後總覽收到失敗結果() {
        // Given
        let app = launch(
            LaunchOptions(
                loadFailure: .ordersDelayed,
                isAppLockEnabled: true,
                biometricScenario: .success
            )
        )
        let dashboardLoading = app.descendants(matching: .any)[BLAccessibilityID.Dashboard.loading]
        guard dashboardLoading.waitForExistence(timeout: 5) else {
            failWithDiagnostics(in: app, "啟動後總覽未顯示載入中，訂單讀取已結束或未進行，時間窗不存在")
            return
        }
        let loadingSeenAt = Date()

        // When
        XCUIDevice.shared.press(.home)
        guard waitUntilInBackground(app, timeout: 5) else {
            failWithDiagnostics(in: app, "按下 Home 後 App 未進入背景，沒有上鎖")
            return
        }
        // 從看到載入中起算 3 秒後才回前景 (對齊規格範例)，進入背景前已經過的時間要扣除
        let backgroundDuration: TimeInterval = 3
        let remainingDuration = backgroundDuration - Date().timeIntervalSince(loadingSeenAt)
        if remainingDuration > 0 {
            _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: remainingDuration)
        }
        app.activate()

        // Then
        guard dashboardLoading.waitForExistence(timeout: 3) else {
            failWithDiagnostics(in: app, "回前景解鎖後總覽未顯示載入中，訂單讀取已結束或被取消，時間窗不存在")
            return
        }
        assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Dashboard.loadFailure,
            present: [BLAccessibilityID.Dashboard.loadFailureRetryButton],
            absent: [BLAccessibilityID.Dashboard.loading],
            context: "背景上鎖並解鎖後的總覽",
            firstAppearanceTimeout: 5
        )
    }
}

// MARK: - Private Method

private extension LoadFailureReloadLoopTests {

    /// 輪詢等待 App 離開前景
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - timeout: 等待進入背景的秒數
    /// - Returns: App 是否在逾時前進入 `runningBackground` 或 `runningBackgroundSuspended`
    func waitUntilInBackground(_ app: XCUIApplication, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if app.state == .runningBackground || app.state == .runningBackgroundSuspended {
                return true
            }
            _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: 0.2)
        } while Date() < deadline
        return false
    }
}
