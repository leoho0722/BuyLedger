//
//  CustomersLoadStateTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/11.
//

import XCTest

/// 訂單讀取失敗與讀取中時，客戶頁顯示載入狀態而非空狀態的 UI 測試
@MainActor
final class CustomersLoadStateTests: BLUITestCase {

    /// 驗證訂單每次讀取皆失敗時開啟客戶頁，顯示訂單讀取失敗訊息與重試鍵，且不顯示尚無客戶的空狀態
    func testOpenCustomers_訂單每次讀取皆失敗_顯示失敗訊息與重試鍵而非空狀態() {
        // Given
        let app = launch(LaunchOptions(loadFailure: .orders))

        // When
        guard openCustomersWithoutEmptyState(in: app) else {
            return
        }

        // Then
        assertLoadFailureStaysStable(
            in: app,
            context: "訂單讀取失敗時的客戶頁",
            firstAppearanceTimeout: Timing.failureAppearance
        )
    }

    /// 驗證訂單第一次延遲讀取失敗後開啟客戶頁，客戶頁發起的新讀取中顯示載入中而非空狀態，完成後顯示失敗訊息與重試鍵，重試後再次載入
    func testOpenCustomers_訂單延遲讀取失敗_讀取中顯示載入中且完成後顯示失敗訊息與重試鍵() {
        // Given
        let app = launch(LaunchOptions(loadFailure: .ordersDelayed))
        let navigator = AppNavigator(app: app)
        navigator.selectTab(.orders)
        let failure = app.descendants(matching: .any)[BLAccessibilityID.Orders.listLoadFailure]
        guard failure.waitForExistence(timeout: Timing.firstOrdersFailure) else {
            failWithDiagnostics(in: app, "啟動後訂單清單未顯示第一次延遲讀取失敗")
            return
        }

        // When
        guard openCustomersWithoutEmptyState(in: app) else {
            return
        }

        // Then
        let loading = app.descendants(matching: .any)[BLAccessibilityID.Customers.listLoading]
        guard loading.waitForExistence(timeout: Timing.loadingAppearance) else {
            failWithDiagnostics(
                in: app,
                "開啟客戶頁後未顯示載入中，訂單讀取已結束或未進行，時間窗不存在"
            )
            return
        }
        guard assertLoadFailureStaysStable(
            in: app,
            context: "訂單延遲讀取完成後的客戶頁",
            firstAppearanceTimeout: Timing.failureAppearance
        ) else {
            return
        }

        // When
        let retryButton = app.descendants(matching: .any)[
            BLAccessibilityID.Customers.listLoadFailureRetryButton
        ]
        retryButton.tapAfterWaiting(in: app)

        // Then
        guard loading.waitForExistence(timeout: Timing.retryLoadingAppearance) else {
            let seconds = Int(Timing.retryLoadingAppearance)
            failWithDiagnostics(in: app, "點重試鍵後 \(seconds) 秒內客戶頁未顯示載入中")
            return
        }
        assertLoadFailureStaysStable(
            in: app,
            context: "客戶頁重試後",
            firstAppearanceTimeout: Timing.retryFailureAppearance
        )
    }
}

// MARK: - Nested Types

extension CustomersLoadStateTests {

    /// 等待的秒數，皆為估計值
    private enum Timing {

        /// 啟動後等待訂單清單第一次延遲讀取失敗的秒數，涵蓋 App 啟動時間與 8 秒讀取延遲
        static let firstOrdersFailure: TimeInterval = 15

        /// 開啟客戶頁後等待根容器出現的秒數
        static let screenReady: TimeInterval = 5

        /// 開啟客戶頁後等待載入中指示器出現的秒數，涵蓋 Root 先讀主檔目錄再請求訂單的時間
        static let loadingAppearance: TimeInterval = 5

        /// 等待失敗畫面第一次出現的秒數，涵蓋 8 秒讀取延遲與餘裕
        static let failureAppearance: TimeInterval = 10

        /// 點重試鍵後等待載入中指示器出現的秒數
        static let retryLoadingAppearance: TimeInterval = 3

        /// 點重試鍵後等待失敗畫面第一次出現的秒數，涵蓋 8 秒讀取延遲與餘裕
        static let retryFailureAppearance: TimeInterval = 12
    }
}

// MARK: - Private Method

private extension CustomersLoadStateTests {

    /// 從更多分頁開啟客戶頁，確認畫面已切到客戶頁且沒有顯示尚無客戶的空狀態
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 客戶頁已出現且空狀態不存在
    func openCustomersWithoutEmptyState(in app: XCUIApplication) -> Bool {
        let customers = CustomersScreen.open(from: app)
        guard customers.waitUntilReady(timeout: Timing.screenReady) else {
            failWithDiagnostics(
                in: app,
                "客戶名單根 identifier「\(customers.rootIdentifier)」逾時仍未出現"
            )
            return false
        }
        let emptyState = app.descendants(matching: .any)[BLAccessibilityID.Customers.listEmptyState]
        guard !emptyState.exists else {
            failWithDiagnostics(in: app, "訂單讀取失敗時顯示了尚無客戶的空狀態")
            return false
        }
        return true
    }

    /// 等客戶頁的失敗畫面出現後持續取樣，確認重試鍵常駐且載入中與空狀態都不出現
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - context: 失敗訊息開頭描述的畫面
    ///   - firstAppearanceTimeout: 等待失敗畫面第一次出現的秒數
    /// - Returns: 第一次出現後的取樣是否全部符合
    @discardableResult
    func assertLoadFailureStaysStable(
        in app: XCUIApplication,
        context: String,
        firstAppearanceTimeout: TimeInterval
    ) -> Bool {
        assertLoadStateStaysStable(
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
