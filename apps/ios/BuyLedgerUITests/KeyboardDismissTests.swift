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
/// 而系統選單的 view 階層並非公開契約，只能以介面測試把「點系統文字選單不會收鍵盤」這條行為釘住
///
/// - Note: 訂單編輯表單的欄位尚未發佈 accessibilityIdentifier (待訂單區域的覆蓋 change 補齊)，
///   此處暫以欄位型別與既有 accessibility label 定位，屆時改為 identifier
final class KeyboardDismissTests: BLUITestCase {

    // MARK: - Tests

    /// 於文字欄位進入選取狀態後點擊系統文字選單，鍵盤不應收起
    @MainActor
    func testTappingSystemTextMenuKeepsKeyboardPresented() throws {
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        openNewOrderForm(in: app)

        let customerField = app.textFields.firstMatch
        if !customerField.waitForExistence(timeout: 5) {
            failWithDiagnostics(in: app, "訂單表單的文字欄位未出現")
        }

        customerField.tap()
        customerField.typeText("測試客戶")

        let keyboard = app.keyboards.firstMatch
        if !keyboard.waitForExistence(timeout: 5) {
            failWithDiagnostics(in: app, "輸入後鍵盤未呈現")
        }

        // 長按叫出系統文字選單，再點選單項目
        customerField.press(forDuration: 1.2)

        let menuItem = app.menuItems.firstMatch
        guard menuItem.waitForExistence(timeout: 3) else {
            // 系統文字選單屬外部行程 UI，環境未提供時跳過而非誤判 App 行為
            throw XCTSkip("系統文字選單未出現，可能是模擬器環境差異")
        }
        menuItem.tap()

        // 關鍵斷言：點系統選單屬文字編輯操作，不得被收鍵盤手勢攔截
        XCTAssertTrue(keyboard.exists, "點系統文字選單後鍵盤不應收起")
    }

    /// 點擊互動控制項不應收起鍵盤，收鍵盤只由背景層承接、互動元件不在背景層上
    @MainActor
    func testTappingInteractiveControlKeepsKeyboardPresented() throws {
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        openNewOrderForm(in: app)

        let customerField = app.textFields.firstMatch
        if !customerField.waitForExistence(timeout: 5) {
            failWithDiagnostics(in: app, "訂單表單的文字欄位未出現")
        }
        customerField.tap()

        let keyboard = app.keyboards.firstMatch
        if !keyboard.waitForExistence(timeout: 5) {
            failWithDiagnostics(in: app, "聚焦後鍵盤未呈現")
        }

        // 點另一個文字欄位：焦點轉移但鍵盤維持呈現
        let otherField = app.textFields.element(boundBy: 1)
        if !otherField.exists {
            failWithDiagnostics(in: app, "表單僅有一個文字欄位，無法驗證焦點轉移")
        }
        otherField.tap()

        XCTAssertTrue(keyboard.exists, "點另一個輸入欄不應收起鍵盤")
    }
}

// MARK: - Private Method

private extension KeyboardDismissTests {

    /// 切到訂單分頁並開啟新訂單表單
    ///
    /// 訂單分頁的「新增訂單」尚未發佈 identifier，暫以既有 accessibility label 定位
    /// - Parameter app: 受測 App
    @MainActor
    func openNewOrderForm(in app: XCUIApplication) {
        let root = RootNavigationScreen(app: app)
        if !root.goToOrders() {
            failWithDiagnostics(in: app, "無法切換到訂單分頁")
        }

        let newOrderButton = app.buttons["新增訂單"].firstMatch
        if !newOrderButton.waitUntilHittable(timeout: 5) {
            failWithDiagnostics(in: app, "找不到新增訂單按鈕")
        }
        newOrderButton.tap()
    }
}
