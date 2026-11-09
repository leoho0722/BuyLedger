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
        let emptyState = app.descendants(matching: .any)[BLAccessibilityID.Customers.listEmptyState]
        guard emptyState.waitForExistence(timeout: 10) else {
            failWithDiagnostics(in: app, "客戶頁未顯示空狀態，無法確認已進入發起讀取的畫面")
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
}
