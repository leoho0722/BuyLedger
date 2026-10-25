//
//  AISummaryTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// AI 商品明細總結入口的 UI 測試，分別涵蓋未開啟與已開啟兩條分支
@MainActor
final class AISummaryTests: BLUITestCase {

    // MARK: - Properties

    /// AI 未開啟提示 alert 的關閉按鈕文字
    private static let aiDisabledCloseLabel = "關閉"

    /// 驗證未開啟 AI 時點「AI 總結」，彈出未開啟提示 alert，且可關閉
    ///
    /// - Note: 關閉同次操作顯示的提示並確認收回，避免入口能顯示提示卻讓使用者無法離開
    func testTapAISummary_AI未開啟_顯示提示且可關閉() {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let orders = openOrdersList(app)

        // When
        orders.tapAISummary()

        // Then
        if !app.alertPresented() {
            failWithDiagnostics(in: app, "未開啟 AI 時點「AI 總結」，未開啟提示 alert 未呈現")
        }

        app.tapAlertButton(label: Self.aiDisabledCloseLabel)

        if !app.alertDismissed() {
            failWithDiagnostics(in: app, "點「關閉」後未開啟提示 alert 未收回")
        }
    }

    /// 驗證開啟 AI 時點「AI 總結」，呈現總結 sheet，且可關閉
    ///
    /// - Note: 關閉同次操作推出的總結並確認收回，避免入口能推出 sheet 卻讓使用者無法返回
    func testTapAISummary_AI已開啟_推出總結且可關閉() {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders, shouldUseAISummary: true))
        let orders = openOrdersList(app)

        // When
        orders.tapAISummary()

        // Then
        let summary = AISummaryScreen(app: app)
        if !summary.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "點「AI 總結」後總結 sheet 根 identifier「\(summary.rootIdentifier)」逾時仍未出現"
            )
        }

        summary.tapClose()

        let summaryRoot = app.descendants(matching: .any)[BLAccessibilityID.AISummary.root]
        if !summaryRoot.waitForDisappearance() {
            failWithDiagnostics(in: app, "點關閉後總結 sheet 未收回")
        }
    }
}

// MARK: - Private Method

private extension AISummaryTests {

    /// 切到訂單分頁並等清單就緒，回傳訂單清單 Page Object
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Returns: 已就緒的訂單清單 Page Object
    func openOrdersList(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OrdersScreen {
        let root = RootNavigationScreen(app: app)
        if !root.goToOrders(file: file, line: line) {
            failWithDiagnostics(
                in: app,
                "切到訂單分頁後畫面未就緒",
                file: file,
                line: line
            )
        }

        let orders = OrdersScreen(app: app)
        if !orders.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "訂單清單根 identifier「\(orders.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }
        return orders
    }
}
