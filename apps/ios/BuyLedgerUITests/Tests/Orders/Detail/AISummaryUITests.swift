//
//  AISummaryUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// AI 商品明細總結的提示、呈現與關閉 UI 測試
@MainActor
final class AISummaryUITests: BLUITestCase {

    // MARK: - Properties

    /// AI 未開啟提示 alert 的關閉按鈕文字
    private static let aiDisabledCloseLabel = "關閉"

    /// 驗證未開啟 AI 時點總結入口會呈現提示，按關閉後可返回原畫面
    ///
    /// - Throws: 必要的 UI 操作或提示未呈現時丟出 UITestError.stopped
    func testAiSummaryTapped_AI未開啟_顯示提示且可關閉() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let orders = try OrdersScreen.open(in: app)

        // When
        try orders.tapAISummary()
        try requireCondition(app.alertPresented(), in: app, "未開啟 AI 時點總結入口，提示 alert 未呈現")
        try app.tapAlertButton(label: Self.aiDisabledCloseLabel)

        // Then
        XCTAssertTrue(app.alertDismissed(), "點「關閉」後未開啟提示 alert 未收回")
    }

    /// 驗證開啟 AI 時點總結入口會呈現總結 sheet，關閉後可返回原畫面
    ///
    /// - Throws: 必要的 UI 操作或總結未就緒時丟出 UITestError.stopped
    func testAiSummaryTapped_AI已開啟_推出總結且可關閉() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders, shouldUseAISummary: true))
        let orders = try OrdersScreen.open(in: app)

        // When
        let summary = try orders.openAISummary()
        try summary.tapClose()

        // Then
        XCTAssertTrue(summary.rootElement.waitForDisappearance(), "點關閉後總結 sheet 未收回")
    }
}
