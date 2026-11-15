//
//  RootNavigationMoreUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/29.
//

import XCTest

/// 「更多」分頁的入口選取與目前工具的分欄、堆疊導覽 UI 測試
@MainActor
final class RootNavigationMoreUITests: BLUITestCase {

    /// 驗證寬版再次點選已開啟的匯率頁時保留既有工具，點選其他工具時替換根目的地
    ///
    /// - Throws: 版面不符、入口列或工具根不存在時丟出測試錯誤
    /// - Note: 對應驗收矩陣 N5
    func testEntrySelected_寬版同工具重開保留_不同工具替換() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "根導覽未就緒，總覽頁根 identifier 逾時仍未出現")
        try root.goToMore()
        try XCTSkipUnless(
            try moreLayout(in: app) == .regular,
            "同工具重開只在並排的寬版可再次點選入口列；收合版入口清單在工具開啟時不可見"
        )

        let fxRow = app.descendants(matching: .any)[BLAccessibilityID.More.row(.fx)].firstMatch
        let quoteRow = app.descendants(matching: .any)[
            BLAccessibilityID.More.row(.quote)
        ].firstMatch
        let fx = FxScreen(app: app)
        let quote = QuoteScreen(app: app)

        try requireCondition(fxRow.waitUntilHittable(timeout: 10), in: app, "更多頁匯率入口列未就緒")
        fxRow.tap()
        try requireCondition(fx.waitUntilReady(), in: app, "點選匯率入口後匯率頁未出現")

        // When
        fxRow.tap()

        // Then
        try requireCondition(
            fx.isDisplayed && fxRow.isSelected,
            in: app,
            "再次點選已開啟的匯率入口後匯率頁應保留且入口列維持已選取"
        )

        // When
        try requireCondition(quoteRow.waitUntilHittable(timeout: 10), in: app, "更多頁報價入口列未就緒")
        quoteRow.tap()

        // Then
        try requireCondition(quote.waitUntilReady(), in: app, "點選報價入口後報價頁未出現")
        try requireCondition(!fx.isDisplayed, in: app, "點選其他工具後匯率頁應被替換，不應殘留在根目的地")
    }

    /// 驗證收合版選取設定後以原生返回回到入口清單，且返回後入口列不再選取
    ///
    /// - Throws: 版面不符、入口列或原生返回鍵不存在時丟出測試錯誤
    /// - Note: 對應驗收矩陣 N3
    func testEntrySelected_收合版原生返回_清空目前工具() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.waitUntilReady(), in: app, "根導覽未就緒，總覽頁根 identifier 逾時仍未出現")
        try root.goToMore()
        try XCTSkipUnless(try moreLayout(in: app) == .compact, "原生返回只存在於收合版的堆疊導覽；並排的寬版沒有返回鍵")

        let settingsRow = app.descendants(matching: .any)[
            BLAccessibilityID.More.row(.settings)
        ].firstMatch
        let settings = SettingsScreen(app: app)
        let fxRow = app.descendants(matching: .any)[BLAccessibilityID.More.row(.fx)].firstMatch

        try requireCondition(settingsRow.waitUntilHittable(timeout: 10), in: app, "設定入口列未就緒")
        settingsRow.tap()
        try requireCondition(settings.waitUntilReady(), in: app, "設定頁未出現")

        // When
        try app.tapUniqueNativeBackButton()

        // Then
        try requireCondition(fxRow.waitUntilHittable(timeout: 10), in: app, "原生返回後入口清單未回到前景")
        try requireCondition(!settingsRow.isSelected, in: app, "原生返回後設定入口列不應維持已選取")
    }
}
