//
//  FxScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 匯率工具頁的 Page Object
///
/// 以 accessibility identifier 對外暴露狀態橫幅、幣別選擇器入口、金額輸入與換算結果的語意操作，元素查詢細節不外洩給測試檔；
/// 匯率頁是「更多」分頁下的 push 目的地，導航封裝在 ``open(from:)``
struct FxScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定匯率頁已就緒的根 identifier (捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.Fx.root
    }

    /// 載入或錯誤狀態橫幅是否存在
    ///
    /// 橫幅是合併朗讀的容器，XCUITest 常歸為 staticText，故以 any 查詢而非 otherElements
    var statusBannerExists: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Fx.statusBanner].exists
    }

    /// 換算後 TWD 結果的 accessibility value
    ///
    /// 結果卡是合併朗讀的單一元素，主要數值放在該元素的 value；元素不存在時回傳空字串
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
    ///
    /// 匯率工具是「更多」分頁下的 push 目的地：先切到更多分頁再點匯率列；
    /// 是否成功抵達交由呼叫端以 ``Screen/waitUntilReady(timeout:)`` 判定並附診斷
    /// - Parameter app: 受測 App
    /// - Returns: 匯率頁 Page Object
    static func open(from app: XCUIApplication) -> FxScreen {
        let root = RootNavigationScreen(app: app)
        root.goToMore()

        let entry = app.descendants(matching: .any)[BLAccessibilityID.More.row(.fx)]
        entry.waitUntilHittable()
        entry.tap()

        return FxScreen(app: app)
    }

    /// 開啟來源幣別選擇器
    ///
    /// 幣別入口是自繪 `Button`，XCUITest 可能歸為 button 或 staticText，故以 any 查詢；離屏時先捲入可點位置
    func openCurrencyPicker() {
        let button = app.descendants(matching: .any)[BLAccessibilityID.Fx.currencyPickerButton]
        if !button.isHittable {
            app.scrollToHittable(button, within: rootElement)
        }
        button.waitUntilHittable()
        button.tap()
    }

    /// 填入換算金額後收起數字鍵盤
    ///
    /// 金額欄為 `decimalPad`，無 return 鍵，輸入後以鍵盤工具列完成鍵收起；離屏時先在捲動容器內捲到可點
    /// - Parameters:
    ///   - amount: 要輸入的金額字串
    ///   - app: 受測 App，供收數字鍵盤時定位鍵盤工具列
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
