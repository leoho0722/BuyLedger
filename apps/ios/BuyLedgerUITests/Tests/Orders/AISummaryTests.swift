//
//  AISummaryTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// AI 商品明細總結入口的兩條分支測試
///
/// 一律以 accessibility identifier 定位、找不到 App 元素即附診斷失敗、不 skip。
/// 未開啟 AI 時點入口彈 `AlertState` 提示 (掛不上 identifier，按鈕以顯示文字定位，主回歸計畫已鎖 zh-Hant/TW)；
/// 開啟 AI 時 (`useAiSummary`) AI 走固定輸出替身，點入口推出總結 sheet、就緒後可關閉收回
final class AISummaryTests: BLUITestCase {

    // MARK: - Static Properties

    /// AI 未開啟提示 alert 的關閉按鈕文字 (``OrdersFeature`` aiDisabledAlert 的 cancel 角色按鈕)
    private static let aiDisabledCloseLabel = "關閉"

    // MARK: - Tests

    /// 未開啟 AI 時點「AI 總結」入口，彈出未開啟提示 alert；點「關閉」收回
    @MainActor
    func testAiSummaryDisabledShowsAlertThenCloses() {
        let app = launch(LaunchOptions(seed: .fullOrders))
        let orders = openOrdersList(app)

        orders.tapAiSummary()

        if !app.alertPresented() {
            failWithDiagnostics(in: app, "未開啟 AI 時點「AI 總結」，未開啟提示 alert 未呈現")
        }

        app.tapAlertButton(label: Self.aiDisabledCloseLabel)

        if !app.alertDismissed() {
            failWithDiagnostics(in: app, "點「關閉」後未開啟提示 alert 未收回")
        }
    }

    /// 開啟 AI 時點「AI 總結」入口，推出總結 sheet；就緒後點關閉收回
    @MainActor
    func testAiSummaryEnabledOpensSheetThenCloses() {
        let app = launch(LaunchOptions(seed: .fullOrders, useAiSummary: true))
        let orders = openOrdersList(app)

        orders.tapAiSummary()

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
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 呼叫端檔案，交由 XCTest 定位
    ///   - line: 呼叫端行號，交由 XCTest 定位
    /// - Returns: 已就緒的訂單清單 Page Object
    @MainActor
    func openOrdersList(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OrdersScreen {
        let root = RootNavigationScreen(app: app)
        if !root.goToOrders() {
            failWithDiagnostics(in: app, "切到訂單分頁後畫面未就緒", file: file, line: line)
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
