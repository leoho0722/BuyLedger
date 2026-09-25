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
}

// MARK: - Computed Properties

extension FxScreen {

    /// 判定匯率頁已就緒的根 identifier (捲動容器)
    ///
    /// - Returns: 匯率頁根容器的 identifier
    var rootIdentifier: String {
        BLAccessibilityID.Fx.root
    }

    /// 載入或錯誤狀態橫幅是否存在
    ///
    /// - Returns: 狀態橫幅是否存在
    var statusBannerExists: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Fx.statusBanner].exists
    }

    /// 換算後 TWD 結果的 accessibility value
    ///
    /// - Returns: 換算結果的 accessibility value；元素不存在時為 `nil`
    var convertedValue: String? {
        // 合併朗讀的卡片在 XCUITest 歸為 staticText，故以 any 查詢而非 otherElements
        let element = app.descendants(matching: .any)[BLAccessibilityID.Fx.convertedValue]
        guard element.waitForExistence(timeout: 10) else {
            return nil
        }
        return element.value as? String
    }

    /// 換算結果卡片合併朗讀後的完整 accessibility text
    ///
    /// - Returns: 包含來源幣別與匯率資訊的完整文字；元素不存在時為 `nil`
    @MainActor
    var conversionSummary: String? {
        let element = app.descendants(matching: .any)[BLAccessibilityID.Fx.convertedValue]
        guard element.waitForExistence(timeout: 10) else {
            return nil
        }
        return element.combinedText
    }
}

// MARK: - Internal Method

@MainActor
extension FxScreen {

    /// 從更多分頁導到匯率頁
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 匯率頁的 Page Object
    static func open(
        from app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> FxScreen {
        let root = RootNavigationScreen(app: app)
        root.goToMore(file: file, line: line)

        let entry = app.descendants(matching: .any)[BLAccessibilityID.More.row(.fx)]
        entry.tapAfterWaiting(in: app, file: file, line: line)

        return FxScreen(app: app)
    }

    /// 開啟來源幣別選擇器
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func openCurrencyPicker(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.descendants(matching: .any)[BLAccessibilityID.Fx.currencyPickerButton]
        if !button.isHittable {
            app.scrollToHittable(button, within: rootElement)
        }
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 填入換算金額後收起數字鍵盤
    ///
    /// - Parameters:
    ///   - amount: 要輸入的金額字串
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func typeAmount(
        _ amount: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let field = app.textFields[BLAccessibilityID.Fx.amountField]
        app.scrollToHittable(field, within: rootElement)
        field.clearAndType(
            amount,
            in: app,
            file: file,
            line: line
        )
        field.dismissNumericKeyboard(in: app, file: file, line: line)
    }
}
