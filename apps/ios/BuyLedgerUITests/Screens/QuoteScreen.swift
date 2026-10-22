//
//  QuoteScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 報價試算頁的 Page Object
struct QuoteScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Computed Properties

extension QuoteScreen {

    /// 判定報價頁已就緒的根 identifier (捲動容器)
    ///
    /// - Returns: 報價頁根容器的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Quote.root
    }

    /// 建議售價 hero 卡的 accessibility value
    ///
    /// - Returns: 建議售價的 accessibility value；元素不存在時為 `nil`
    var suggestedPriceValue: String? {
        // 合併朗讀的卡片在 XCUITest 歸為 staticText，故以 any 查詢而非 otherElements
        let element = app.descendants(matching: .any)[BLAccessibilityID.Quote.suggestedPriceValue]
        guard element.waitForExistence(timeout: 10) else {
            return nil
        }
        return element.value as? String
    }

    /// 來源幣別按鈕的 ISO 代碼
    ///
    /// - Returns: 來源幣別代碼；元素不存在時為 `nil`
    @MainActor
    var sourceCurrencyCode: String? {
        let element = app.descendants(matching: .any)[BLAccessibilityID.Quote.currencyPickerButton]
        guard element.waitForExistence(timeout: 10) else {
            return nil
        }
        return element.value as? String
    }

    /// 匯率不可用橫幅是否存在
    ///
    /// - Returns: 匯率不可用橫幅是否存在
    var statusBannerExists: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Quote.statusBanner].exists
    }
}

// MARK: - Internal Method

@MainActor
extension QuoteScreen {

    /// 從更多分頁導到報價頁
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 報價頁的 Page Object
    static func open(
        from app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> QuoteScreen {
        let root = RootNavigationScreen(app: app)
        root.goToMore(file: file, line: line)

        let entry = app.descendants(matching: .any)[BLAccessibilityID.More.row(.quote)]
        entry.tapAfterWaiting(in: app, file: file, line: line)

        return QuoteScreen(app: app)
    }

    /// 開啟來源幣別選擇器
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func openCurrencyPicker(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.descendants(matching: .any)[BLAccessibilityID.Quote.currencyPickerButton]
        if !button.isHittable {
            app.scrollToHittable(button, within: rootElement)
        }
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 填入商品本金後收起數字鍵盤
    ///
    /// - Parameters:
    ///   - amount: 要輸入的本金字串
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func typePrincipal(
        _ amount: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let field = app.textFields[BLAccessibilityID.Quote.principalField]
        app.scrollToHittable(field, within: rootElement)
        field.clearAndType(
            amount,
            in: app,
            file: file,
            line: line
        )
        field.dismissNumericKeyboard(in: app, file: file, line: line)
    }

    /// 點匯率不可用橫幅的重試
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapRetry(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.Quote.retryButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }
}
