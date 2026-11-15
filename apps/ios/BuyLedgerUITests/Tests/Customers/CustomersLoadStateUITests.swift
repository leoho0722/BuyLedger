//
//  CustomersLoadStateUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/11.
//

import XCTest

/// 客戶頁載入失敗與讀取中狀態的 UI 測試
@MainActor
final class CustomersLoadStateUITests: BLUITestCase {

    /// 驗證訂單讀取失敗時客戶頁顯示失敗訊息與重試鍵而非空狀態
    ///
    /// - Throws: 客戶頁或穩定載入失敗狀態未就緒時丟出測試錯誤
    func testTask_訂單每次讀取皆失敗_顯示失敗訊息與重試鍵而非空狀態()
        throws {
        // Given
        let app = try launch(LaunchOptions(loadFailure: .orders))

        // When
        let customers = try CustomersScreen.open(in: app)
        try requireCondition(
            !customers.hasEmptyState(timeout: 0),
            in: app,
            "訂單讀取失敗時顯示了尚無客戶的空狀態"
        )

        // Then
        try assertLoadFailureStaysStable(
            in: app,
            context: "訂單讀取失敗時的客戶頁"
        )
    }

    /// 驗證延遲讀取失敗後開啟客戶頁，讀取中無空狀態且完成後顯示失敗
    ///
    /// - Throws: 訂單或客戶頁未進入預期載入狀態時丟出測試錯誤
    func testTask_訂單延遲讀取失敗_讀取中顯示載入中且完成後顯示失敗訊息與重試鍵() throws {
        // Given
        let options = LaunchOptions(loadFailure: .ordersDelayed)
        let app = try launch(options)
        let orders = try OrdersScreen.open(in: app)
        try requireCondition(
            orders.waitForLoadFailure(timeout: options.delayedReadFailureTimeout),
            in: app,
            "啟動後訂單清單未顯示第一次延遲讀取失敗"
        )

        // When
        let customers = try CustomersScreen.open(in: app)
        try requireCondition(
            customers.waitForLoading(timeout: 5),
            in: app,
            "開啟客戶頁後未顯示載入中"
        )
        try requireCondition(
            !customers.hasEmptyState(timeout: 0),
            in: app,
            "訂單讀取期間顯示了尚無客戶的空狀態"
        )

        // Then
        try assertLoadFailureStaysStable(
            in: app,
            context: "訂單延遲讀取完成後的客戶頁",
            firstAppearanceTimeout: options.delayedReadFailureTimeout
        )
    }

    /// 驗證客戶頁延遲讀取失敗後重試，再次顯示載入中與失敗訊息
    ///
    /// - Throws: 訂單或客戶頁未進入預期載入狀態時丟出測試錯誤
    func testRetryTapped_訂單延遲讀取失敗後重試_重新顯示載入中且再次失敗()
        throws {
        // Given
        let options = LaunchOptions(loadFailure: .ordersDelayed)
        let app = try launch(options)
        let orders = try OrdersScreen.open(in: app)
        try requireCondition(
            orders.waitForLoadFailure(timeout: options.delayedReadFailureTimeout),
            in: app,
            "啟動後訂單清單未顯示第一次延遲讀取失敗"
        )
        let customers = try CustomersScreen.open(in: app)
        try requireCondition(
            customers.waitForLoading(timeout: 5),
            in: app,
            "開啟客戶頁後未顯示載入中"
        )
        try assertLoadFailureStaysStable(
            in: app,
            context: "客戶頁重試前的穩定失敗畫面",
            firstAppearanceTimeout: options.delayedReadFailureTimeout
        )
        try requireCondition(
            customers.rootElement.exists
                && !customers.waitForLoading(timeout: 0)
                && !customers.hasEmptyState(timeout: 0),
            in: app,
            "客戶頁重試前未穩定停留在載入失敗畫面"
        )

        // When
        try customers.tapRetry()

        // Then
        try requireCondition(
            customers.waitForLoading(timeout: options.delayedReadFailureTimeout),
            in: app,
            "點重試鍵後客戶頁未顯示載入中"
        )
        try assertLoadFailureStaysStable(
            in: app,
            context: "客戶頁重試後",
            firstAppearanceTimeout: options.delayedReadFailureTimeout
        )
    }
}

// MARK: - Private Method

private extension CustomersLoadStateUITests {

    /// 取樣客戶頁失敗畫面，確認重試鍵常駐且載入中與空狀態都不出現
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - context: 失敗訊息開頭描述的畫面
    ///   - firstAppearanceTimeout: 等待失敗畫面第一次出現的秒數
    /// - Throws: 失敗畫面未出現或取樣不符合時丟出測試錯誤
    func assertLoadFailureStaysStable(
        in app: XCUIApplication,
        context: String,
        firstAppearanceTimeout: TimeInterval = 10
    ) throws(UITestError) {
        try assertLoadStateStaysStable(
            in: app,
            waitingFor: BLAccessibilityID.Customers.listLoadFailure,
            present: [BLAccessibilityID.Customers.listLoadFailureRetryButton],
            absent: [
                BLAccessibilityID.Customers.listLoading,
                BLAccessibilityID.Customers.listEmptyState,
            ],
            context: context,
            firstAppearanceTimeout: firstAppearanceTimeout
        )
    }
}

