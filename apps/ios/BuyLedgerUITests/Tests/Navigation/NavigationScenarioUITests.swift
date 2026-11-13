//
//  NavigationScenarioUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/3.
//

import XCTest

/// 導覽情境的 UI 測試，涵蓋寬版批次鈕位置、收合版已選筆數、設定頁左緣返回、返回鈕標籤與 App 鎖定時的導覽診斷
///
/// - Note: 版面不適用時以版面條件宣告略過
@MainActor
final class NavigationScenarioUITests: BLUITestCase {

    /// 驗證寬版訂單多選已選取一筆訂單時，批次鈕與清單欄的已選筆數下緣都位於視窗上半部
    ///
    /// - Throws: 版面不是並排、多選無法進入、框線無法取得或位置超出上半部時丟出測試錯誤
    /// - Note: 模擬器無法真實拖曳視窗，這裡以上半部的框線作為替代證據，真實拖曳記為未驗證
    /// - Note: 只在寬版並排的訂單版面執行，收合版會略過
    func testBatchControls_寬版多選已選取訂單_批次鈕與筆數位於視窗上半部() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders, language: .traditionalChinese))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToOrders(), in: app, "切到訂單分頁失敗")
        try XCTSkipUnless(isRegularLayout(app), "批次鈕與清單欄筆數的上半部位置只在寬版並排的訂單版面適用")

        let orders = OrdersScreen(app: app)
        try orders.enterSelectionMode()
        // 多選列的 identifier 同時落在按鈕與內層摘要，取第一個點擊
        orders.orderRow(orderID: "BL-2604-018").firstMatch.tapAfterWaiting(in: app)
        let summary = app.staticTexts[BLAccessibilityID.Orders.selectionSummary]
        try requireCondition(
            summary.wait(for: NSPredicate(format: "label == %@", "已選 1 筆"), timeout: 5),
            in: app,
            "選取一筆後清單欄的已選筆數未顯示為「已選 1 筆」"
        )

        // When
        let window = try requireValidFrame(of: app.windows.firstMatch, in: app, context: "視窗")
        let batchButton = app.buttons[BLAccessibilityID.Orders.batchStatusMenuButton]
        let batchFrame = try requireValidFrame(of: batchButton, in: app, context: "多選批次狀態選單")
        let summaryFrame = try requireValidFrame(of: summary, in: app, context: "寬版清單欄的已選筆數")

        // Then
        try requireCondition(
            window.contains(batchFrame)
                && window.contains(summaryFrame)
                && batchFrame.maxY <= window.midY
                && summaryFrame.maxY <= window.midY
                && batchButton.isHittableOnScreen,
            in: app,
            """
            位置越界或不可操作：批次鈕或已選筆數不在視窗上半部，或批次鈕不可點
            批次鈕 frame = \(batchFrame)，已選筆數 frame = \(summaryFrame)，視窗 frame = \(window)
            """
        )
    }

    /// 驗證收合版訂單多選選取兩筆後，已選筆數只出現在導覽列標題，沒有移到詳情工具列或其他位置
    ///
    /// - Throws: 版面不是收合、多選無法進入、標題未顯示或筆數出現在導覽列框線之外時丟出測試錯誤
    /// - Note: 導覽列標題在可及性樹上可能同時有導覽列與文字兩個節點，兩者都位於導覽列框線內，視為同一處顯示
    /// - Note: 只在收合導覽的訂單版面執行，寬版並排的筆數位於清單欄頂部，另由寬版測試守
    func testSelectionCount_收合版多選選取兩筆_筆數只在導覽列標題出現一次() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders, language: .traditionalChinese))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToOrders(), in: app, "切到訂單分頁失敗")
        try XCTSkipUnless(isCompactLayout(app), "已選筆數只出現在收合導覽的標題，並排版面的筆數位於清單欄頂部")

        let orders = OrdersScreen(app: app)
        try orders.enterSelectionMode()

        // When
        // 多選列的 identifier 同時落在按鈕與內層摘要，取第一個點擊
        orders.orderRow(orderID: "BL-2604-018").firstMatch.tapAfterWaiting(in: app)
        orders.orderRow(orderID: "BL-2604-017").firstMatch.tapAfterWaiting(in: app)

        // Then
        let countPredicate = NSPredicate(format: "label == %@", "已選 2 筆")
        let countLabel = app.descendants(matching: .any).matching(countPredicate).firstMatch
        try requireCondition(
            countLabel.waitForExistence(timeout: 5),
            in: app,
            "選取兩筆後導覽列未顯示「已選 2 筆」"
        )
        let countTexts = app.staticTexts.matching(countPredicate)
        let navigationCountTexts = app.navigationBars.firstMatch.staticTexts
            .matching(countPredicate)
        try requireCondition(
            countTexts.count == 1 && navigationCountTexts.count == 1,
            in: app,
            """
            已選筆數未只在導覽列標題出現一次
            全畫面 \(countTexts.count) 處，導覽列內 \(navigationCountTexts.count) 處
            """
        )
    }

    /// 驗證收合版更多進入設定後，從左緣向右拖曳會經系統導覽返回入口清單，設定頁離開前景
    ///
    /// - Throws: 版面不是收合、設定頁無法開啟，或返回後入口清單與設定頁的前景狀態不符合預期時丟出測試錯誤
    /// - Note: 只在更多的收合導覽執行，寬版並排時設定頁位於詳情欄，沒有返回堆疊可驗證
    func testSettings_收合版更多進入設定_左緣拖曳返回入口清單() throws {
        // Given
        let app = launch()
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToMore(), in: app, "切到更多分頁失敗")
        try XCTSkipUnless(isMoreCompactLayout(app), "左緣返回只在更多的收合導覽中適用，並排時設定頁位於詳情欄")
        let settings = SettingsScreen.navigate(in: app)
        try requireCondition(settings.waitUntilReady(), in: app, "設定頁未就緒")

        // When
        let leadingEdge = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let trailingTarget = app.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        leadingEdge.press(forDuration: 0.1, thenDragTo: trailingTarget)

        // Then
        let moreRoot = app.descendants(matching: .any)[BLAccessibilityID.More.root]
        try requireCondition(moreRoot.waitForExistence(timeout: 10), in: app, "左緣拖曳後未回到更多入口清單")
        let settingsRoot = app.descendants(matching: .any)[BLAccessibilityID.Settings.root]
        try requireCondition(
            settingsRoot.waitForDisappearance(timeout: 10),
            in: app,
            "左緣拖曳後設定頁仍在前景"
        )
    }

    /// 驗證在設定頁切換 App 語言後返回再進入設定，返回鈕標籤顯示目前語言的「更多」，而不是切換前快取的標題
    ///
    /// - Throws: 版面不是收合、語言選單無法操作、返回鈕不唯一或標籤未在逾時前變成 More 時丟出測試錯誤
    /// - Note: 只在更多的收合導覽執行，寬版並排時設定頁位於詳情欄，沒有返回鈕
    func testBackButton_切換語言後返回再進設定_標籤為目前語言的更多() throws {
        // Given
        let app = launch(LaunchOptions(language: .traditionalChinese))
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToMore(), in: app, "切到更多分頁失敗")
        try XCTSkipUnless(isMoreCompactLayout(app), "返回鈕的標籤只在更多的收合導覽中適用，並排時設定頁位於詳情欄")
        let settings = SettingsScreen.navigate(in: app)
        try requireCondition(settings.waitUntilReady(), in: app, "設定頁未就緒")

        // When
        settings.openLanguagePicker()
        try requireCondition(
            app.tapMenuItem(
                BLAccessibilityID.Settings.languageOption(LaunchOptions.Language.english.rawValue),
                label: "English"
            ),
            in: app,
            "語言選單中找不到 English 選項"
        )
        try app.tapUniqueNativeBackButton()
        let moreRoot = app.descendants(matching: .any)[BLAccessibilityID.More.root]
        try requireCondition(moreRoot.waitForExistence(timeout: 10), in: app, "切換語言後返回未回到更多入口清單")
        let reopenedSettings = SettingsScreen.navigate(in: app)
        try requireCondition(reopenedSettings.waitUntilReady(), in: app, "再次進入設定頁未就緒")

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

    /// 驗證 App 鎖定畫面上根分頁不可用時，選取訂單分頁會記錄診斷失敗，而不是回傳成功或略過
    ///
    /// - Throws: 鎖定畫面未出現、訂單分頁意外可互動或導覽後鎖定畫面消失時丟出測試錯誤
    /// - Note: 以 `XCTExpectFailure` 的嚴格模式包住導覽呼叫，沒有記錄到預期訊息時整個測試失敗
    func testSelectTab_App鎖定時根分頁不可用_記錄診斷失敗() throws {
        // Given
        let app = launch(LaunchOptions(isAppLockEnabled: true, biometricScenario: .failure))
        let lockScreen = AppLockScreen(app: app)
        try requireCondition(lockScreen.waitUntilReady(), in: app, "帶 App 鎖定啟動後鎖定畫面未出現")
        let navigator = AppNavigator(app: app)
        try requireCondition(
            !navigator.rootTabElement(for: .orders).isHittableOnScreen,
            in: app,
            "鎖定畫面上訂單分頁不應可互動"
        )

        // When
        XCTExpectFailure(
            "App 鎖定時根分頁不可用，selectTab 應記錄診斷失敗",
            strict: true
        ) {
            navigator.selectTab(.orders)
        } issueMatcher: {
            $0.compactDescription.contains("找不到可互動的根分頁")
        }

        // Then
        try requireCondition(lockScreen.isDisplayed, in: app, "選取分頁後鎖定畫面不應消失")
    }
}
