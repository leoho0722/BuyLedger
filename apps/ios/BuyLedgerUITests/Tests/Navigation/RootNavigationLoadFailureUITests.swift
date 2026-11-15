//
//  RootNavigationLoadFailureUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/9.
//

import XCTest

/// 訂單持續讀取失敗時，切換根分頁與離開讀取發起畫面的載入狀態 UI 測試
@MainActor
final class RootNavigationLoadFailureUITests: BLUITestCase {

    /// 驗證訂單每次讀取失敗時，依序切換分頁後訂單、總覽與分析持續顯示失敗訊息且不再載入
    ///
    /// - Throws: 切換分頁失敗，或任一頁的失敗畫面未出現、取樣期間狀態不穩定時丟出測試錯誤
    func testTabSelected_訂單每次讀取皆失敗_三頁穩定顯示失敗畫面() throws {
        // Given
        let app = try launch(LaunchOptions(loadFailure: .orders))
        let navigator = AppNavigator(app: app)

        // When
        try navigator.selectTab(.orders)
        try navigator.selectTab(.more)
        try navigator.selectTab(.orders)

        // Then
        try assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Orders.listLoadFailure,
            present: [BLAccessibilityID.Orders.listLoadFailureRetryButton],
            absent: [BLAccessibilityID.Orders.listLoading],
            context: "切換更多再返回訂單清單"
        )

        // When
        try navigator.selectTab(.dashboard)

        // Then
        try assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Dashboard.loadFailure,
            present: [BLAccessibilityID.Dashboard.loadFailureRetryButton],
            absent: [BLAccessibilityID.Dashboard.loading],
            context: "切回總覽"
        )

        // When
        try navigator.selectTab(.insights)

        // Then
        try assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Insights.loadFailure,
            present: [BLAccessibilityID.Insights.loadFailureRetryButton],
            absent: [BLAccessibilityID.Insights.loading],
            context: "切到分析"
        )
    }

    /// 驗證分析頁發起延遲讀取後，在載入中切到訂單清單仍能收到失敗結果且不再載入
    ///
    /// - Throws: 訂單未先顯示失敗、分析頁未進入載入中，或離開後的清單狀態不符預期時丟出測試錯誤
    /// - Note: 時間窗情境，載入中未出現或離開時清單已不在載入中，都視為時間窗不存在而失敗
    func testTabSelected_訂單延遲讀取中離開分析頁_清單仍收到失敗結果() throws {
        // Given
        let options = LaunchOptions(loadFailure: .ordersDelayed)
        let app = try launch(options)
        let navigator = AppNavigator(app: app)
        try navigator.selectTab(.orders)
        let orders = OrdersScreen(app: app)
        try requireCondition(
            orders.waitForLoadFailure(timeout: options.delayedReadFailureTimeout),
            in: app,
            "啟動後訂單清單未顯示第一次延遲讀取失敗"
        )

        // When
        try navigator.selectTab(.insights)
        try requireCondition(
            InsightsScreen(app: app).waitForLoading(timeout: 10),
            in: app,
            "分析頁未顯示載入中，無法確認已發起新的訂單讀取"
        )
        try navigator.selectTab(.orders)

        // Then
        try requireCondition(
            orders.waitForLoading(timeout: 1),
            in: app,
            "離開時訂單清單不在載入中，時間窗不存在"
        )
        try assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Orders.listLoadFailure,
            present: [BLAccessibilityID.Orders.listLoadFailureRetryButton],
            absent: [BLAccessibilityID.Orders.listLoading],
            context: "離開分析頁後的訂單清單",
            firstAppearanceTimeout: options.delayedReadFailureTimeout
        )
    }

    /// 驗證客戶頁發起延遲讀取後，在載入中切到訂單清單仍能收到失敗結果且不再載入
    ///
    /// - Throws: 訂單未先顯示失敗、客戶頁未進入載入中，或離開後的清單狀態不符預期時丟出測試錯誤
    /// - Note: 時間窗情境，載入中未出現或離開時清單已不在載入中，都視為時間窗不存在而失敗
    func testTabSelected_訂單延遲讀取中離開客戶頁_清單仍收到失敗結果() throws {
        // Given
        let options = LaunchOptions(loadFailure: .ordersDelayed)
        let app = try launch(options)
        let navigator = AppNavigator(app: app)
        try navigator.selectTab(.orders)
        let orders = OrdersScreen(app: app)
        try requireCondition(
            orders.waitForLoadFailure(timeout: options.delayedReadFailureTimeout),
            in: app,
            "啟動後訂單清單未顯示第一次延遲讀取失敗"
        )

        // When
        let customers = try CustomersScreen.open(in: app)
        // 剛進入時可能先顯示上一次的失敗，等 Root 讀完主檔目錄、請求訂單後才轉為載入中，5 秒為估計值
        try requireCondition(
            customers.waitForLoading(timeout: 5),
            in: app,
            "客戶頁未顯示載入中，無法確認已進入發起讀取的畫面"
        )
        try navigator.selectTab(.orders)

        // Then
        try requireCondition(
            orders.waitForLoading(timeout: 1),
            in: app,
            "離開時訂單清單不在載入中，時間窗不存在"
        )
        try assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Orders.listLoadFailure,
            present: [BLAccessibilityID.Orders.listLoadFailureRetryButton],
            absent: [BLAccessibilityID.Orders.listLoading],
            context: "離開客戶頁後的訂單清單",
            firstAppearanceTimeout: options.delayedReadFailureTimeout
        )
    }
}
