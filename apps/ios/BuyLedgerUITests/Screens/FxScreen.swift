//
//  FxScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 匯率工具頁的 Page Object
struct FxScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定匯率頁已就緒的根 identifier (捲動容器)
    /// - Returns: 匯率頁根容器的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Fx.root
    }

    /// 載入或錯誤狀態橫幅是否存在
    /// - Returns: 狀態橫幅是否存在
    var statusBannerExists: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Fx.statusBanner].exists
    }

    /// 換算後 TWD 結果的 accessibility value
    /// - Returns: 換算結果的 accessibility value；元素不存在時為空字串
    var convertedValue: String {
        // 合併朗讀的卡片在 XCUITest 歸為 staticText，故以 any 查詢而非 otherElements
        let element = app.descendants(matching: .any)[BLAccessibilityID.Fx.convertedValue]
        guard element.waitForExistence(timeout: 10) else {
            return ""
        }
        return (element.value as? String) ?? ""
    }
}

// MARK: - Internal Method

@MainActor
extension FxScreen {

    /// 從更多分頁導到匯率頁
    /// - Parameter app: 受測 App
    /// - Returns: 匯率頁的 Page Object
    static func open(from app: XCUIApplication) -> FxScreen {
        let root = RootNavigationScreen(app: app)
        root.goToMore()

        let entry = app.descendants(matching: .any)[BLAccessibilityID.More.row(.fx)]
        entry.waitUntilHittable()
        entry.tap()

        return FxScreen(app: app)
    }

    /// 開啟來源幣別選擇器
    func openCurrencyPicker() {
        let button = app.descendants(matching: .any)[BLAccessibilityID.Fx.currencyPickerButton]
        if !button.isHittable {
            app.scrollToHittable(button, within: rootElement)
        }
        button.waitUntilHittable()
        button.tap()
    }

    /// 填入換算金額後收起數字鍵盤
    /// - Parameters:
    ///   - amount: 要輸入的金額字串
    ///   - app: 受測 App
    func typeAmount(_ amount: String, in app: XCUIApplication) {
        let field = app.textFields[BLAccessibilityID.Fx.amountField]
        app.scrollToHittable(field, within: rootElement)
        field.waitUntilHittable()
        // decimalPad 出現後 SwiftUI 會把此欄捲到鍵盤上方，聚焦與輸入才成立
        field.tap()
        if let existing = field.value as? String, existing != amount {
            let deletes = String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count)
            field.typeText(deletes)
        }
        field.typeText(amount)
        field.dismissNumericKeyboard(in: app)
    }
}
