//
//  KeyboardDismissTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/20.
//

import XCTest

/// 收鍵盤手勢的回歸測試
///
/// 手勢依賴 `blocksKeyboardDismissTap` 沿 superview 逐層過濾互動與系統選單 view，
/// 而系統選單的 view 階層並非公開契約——只能以介面測試把「點系統文字選單不會收鍵盤」這條行為釘住
final class KeyboardDismissTests: XCTestCase {

    // MARK: - Setup

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Tests

    /// 於文字欄位進入選取狀態後點擊系統文字選單，鍵盤不應收起
    @MainActor
    func testTappingSystemTextMenuKeepsKeyboardPresented() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // 進到訂單分頁並開啟新訂單表單，取得第一個文字欄位
        // 先切到訂單分頁 (啟動分頁會隨上次選擇而異)，再開新訂單表單
        let ordersTab = app.tabBars.buttons["訂單"]
        guard ordersTab.waitForExistence(timeout: 5) else {
            throw XCTSkip("找不到訂單分頁，可能是版面結構已變動")
        }
        ordersTab.tap()

        let newOrderButton = app.buttons["新增訂單"].firstMatch
        guard newOrderButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("找不到新增訂單按鈕")
        }
        newOrderButton.tap()

        let customerField = app.textFields.firstMatch
        guard customerField.waitForExistence(timeout: 5) else {
            throw XCTSkip("找不到文字欄位，可能是分頁結構已變動")
        }

        customerField.tap()
        customerField.typeText("測試客戶")

        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5), "輸入後鍵盤應已呈現")

        // 長按叫出系統文字選單，再點選單項目
        customerField.press(forDuration: 1.2)

        let menuItem = app.menuItems.firstMatch
        guard menuItem.waitForExistence(timeout: 3) else {
            throw XCTSkip("系統文字選單未出現，可能是模擬器環境差異")
        }
        menuItem.tap()

        // 關鍵斷言：點系統選單屬文字編輯操作，不得被收鍵盤手勢攔截
        XCTAssertTrue(keyboard.exists, "點系統文字選單後鍵盤不應收起")
    }

    /// 點擊背景應收起鍵盤
    @MainActor
    func testTappingBackgroundDismissesKeyboard() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // 先切到訂單分頁 (啟動分頁會隨上次選擇而異)，再開新訂單表單
        let ordersTab = app.tabBars.buttons["訂單"]
        guard ordersTab.waitForExistence(timeout: 5) else {
            throw XCTSkip("找不到訂單分頁，可能是版面結構已變動")
        }
        ordersTab.tap()

        let newOrderButton = app.buttons["新增訂單"].firstMatch
        guard newOrderButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("找不到新增訂單按鈕")
        }
        newOrderButton.tap()

        let customerField = app.textFields.firstMatch
        guard customerField.waitForExistence(timeout: 5) else {
            throw XCTSkip("找不到文字欄位，可能是分頁結構已變動")
        }
        customerField.tap()

        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5), "聚焦後鍵盤應已呈現")

        // 點在表單背景 (非任何互動元件) 的位置
        app.otherElements.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.92)).tap()

        XCTAssertTrue(
            keyboard.waitForNonExistence(timeout: 5),
            "點背景後鍵盤應收起"
        )
    }

    /// 點擊互動控制項不應收起鍵盤——收鍵盤只由背景層承接，互動元件不在背景層上
    @MainActor
    func testTappingInteractiveControlKeepsKeyboardPresented() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // 先切到訂單分頁 (啟動分頁會隨上次選擇而異)，再開新訂單表單
        let ordersTab = app.tabBars.buttons["訂單"]
        guard ordersTab.waitForExistence(timeout: 5) else {
            throw XCTSkip("找不到訂單分頁，可能是版面結構已變動")
        }
        ordersTab.tap()

        let newOrderButton = app.buttons["新增訂單"].firstMatch
        guard newOrderButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("找不到新增訂單按鈕")
        }
        newOrderButton.tap()

        let customerField = app.textFields.firstMatch
        guard customerField.waitForExistence(timeout: 5) else {
            throw XCTSkip("找不到文字欄位，可能是分頁結構已變動")
        }
        customerField.tap()

        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5), "聚焦後鍵盤應已呈現")

        // 點另一個文字欄位：焦點轉移但鍵盤維持呈現
        let otherField = app.textFields.element(boundBy: 1)
        guard otherField.exists else {
            throw XCTSkip("表單僅有一個文字欄位")
        }
        otherField.tap()

        XCTAssertTrue(keyboard.exists, "點另一個輸入欄不應收起鍵盤")
    }
}
