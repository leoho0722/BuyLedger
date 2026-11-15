//
//  SettingsLanguageUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/15.
//

import XCTest

/// 設定頁切換 App 語言後，返回鈕標籤跟著目前語言的 UI 測試
///
/// - Note: 版面不適用時以版面條件宣告略過
@MainActor
final class SettingsLanguageUITests: BLUITestCase {

    /// 驗證在設定頁切換 App 語言後返回再進入設定，返回鈕標籤顯示目前語言的「更多」，而不是切換前快取的標題
    ///
    /// - Throws: 版面不是收合、語言選單無法操作、返回鈕不唯一或標籤未在逾時前變成 More 時丟出測試錯誤
    /// - Note: 只在更多的收合導覽執行，寬版並排時設定頁位於詳情欄，沒有返回鈕
    func testOpenLanguagePicker_切換語言後返回再進設定_標籤為目前語言的更多() throws {
        // Given
        let app = try launch(LaunchOptions(language: .traditionalChinese))
        let settings = try SettingsScreen.open(in: app)
        try XCTSkipUnless(
            try moreLayout(in: app) == .compact,
            "返回鈕的標籤只在更多的收合導覽中適用，並排時設定頁位於詳情欄"
        )

        // When
        try settings.openLanguagePicker()
        try app.tapMenuItem(
            BLAccessibilityID.Settings.languageOption(LaunchOptions.Language.english.rawValue),
            label: "English"
        )
        try app.tapUniqueNativeBackButton()
        let moreRoot = app.descendants(matching: .any)[BLAccessibilityID.More.root]
        try requireCondition(
            moreRoot.waitForExistence(timeout: 10),
            in: app,
            "切換語言後返回未回到更多入口清單"
        )
        try SettingsScreen.open(in: app)

        // Then
        let backButton = app.navigationBars.buttons
            .matching(identifier: SystemAccessibilityID.backButton)
            .firstMatch
        try requireCondition(backButton.waitForExistence(timeout: 10), in: app, "設定頁的返回鈕不存在")
        let matchesMoreTitle = backButton.wait(
            for: NSPredicate(format: "label == %@", "More"),
            timeout: 5
        )
        try requireCondition(
            matchesMoreTitle,
            in: app,
            "返回鈕標籤不是目前語言的 More，實際為「\(backButton.label)」"
        )
    }
}
