//
//  QuoteInputFocusUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/5.
//

import XCTest

/// 報價欄位聚焦後取代輸入、還原與即時試算的 UI 測試
@MainActor
final class QuoteInputFocusUITests: BLUITestCase {

    /// 驗證本金 2500 聚焦後再從左側點入輸入「1000」，欄位值為「1000」，建議售價更新為「$30」，不保留原文
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusFieldFromLeft_既有本金重新輸入_取代原值並更新售價() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let quote = try QuoteScreen.open(in: app)
        try preparePrincipal(in: quote)

        // When
        try quote.focusFieldFromLeft(quote.principalField)
        quote.principalField.typeText("1000")

        // Then
        _ = Polling.wait(timeout: 3) {
            quote.principalFieldValue() == "1000" && quote.suggestedPriceValue() == "$30"
        }
        XCTAssertEqual(quote.principalFieldValue(), "1000", "重新聚焦後應以新本金取代原值")
        XCTAssertEqual(quote.suggestedPriceValue(), "$30", "本金 1000 的建議售價應為 $30")
    }

    /// 驗證本金仍聚焦時直接點當地運費，輸入取代運費原值且本金保留
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusFieldFromLeft_本金直接換到運費_運費清空後輸入且本金不變() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let quote = try QuoteScreen.open(in: app)
        try quote.focusFieldFromLeft(quote.localShippingField)
        quote.localShippingField.typeText("30")
        try quote.dismissKeyboard(for: quote.localShippingField)
        _ = Polling.wait(timeout: 3) {
            quote.localShippingFieldValue() == "30"
        }
        try requireCondition(
            quote.localShippingFieldValue() == "30",
            in: app,
            "前置當地運費必須先是 30 (實際：\(String(describing: quote.localShippingFieldValue())))"
        )

        try quote.focusFieldFromLeft(quote.principalField)
        quote.principalField.typeText("2500")
        _ = Polling.wait(timeout: 3) {
            quote.principalFieldValue() == "2500"
        }
        try requireCondition(
            quote.principalFieldValue() == "2500",
            in: app,
            "前置本金必須先是 2500 (實際：\(String(describing: quote.principalFieldValue())))"
        )
        try requireCondition(quote.isPrincipalFieldFocused(), in: app, "換欄前本金必須仍持有鍵盤焦點")

        // When
        try quote.focusFieldFromLeft(quote.localShippingField)
        quote.localShippingField.typeText("5")

        // Then
        _ = Polling.wait(timeout: 3) {
            quote.localShippingFieldValue() == "5" && quote.principalFieldValue() == "2500"
        }
        XCTAssertEqual(quote.localShippingFieldValue(), "5", "直接換欄後應以新運費取代原值")
        XCTAssertEqual(quote.principalFieldValue(), "2500", "換到當地運費時本金應保留原值")
    }

    /// 驗證只聚焦已有本金會清空草稿並顯示零提示，沒有輸入就失焦仍還原原值
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusFieldFromLeft_本金未輸入即失焦_聚焦清空且恢復原值() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let quote = try QuoteScreen.open(in: app)
        try preparePrincipal(in: quote)
        try requireCondition(
            quote.principalField.placeholderValue == "0",
            in: app,
            "本金欄提示文字應維持為 0 (實際：\(String(describing: quote.principalField.placeholderValue)))"
        )

        // When
        try quote.focusFieldFromLeft(quote.principalField)
        let focusedValue = quote.principalFieldValue()
        try quote.dismissKeyboard(for: quote.principalField)
        _ = Polling.wait(timeout: 3) {
            quote.principalFieldValue() == "2500"
        }
        let finalValue = quote.principalFieldValue()

        // Then
        XCTAssertEqual(focusedValue, "0", "聚焦中應清空草稿，空欄的 value 會讀到提示文字 0")
        XCTAssertEqual(finalValue, "2500", "未輸入就失焦應還原原本本金")
    }

    /// 驗證零值本金輸入時立即更新售價，不必等到收起鍵盤才試算
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusFieldFromLeft_零值本金輸入中_未失焦即更新建議售價() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let quote = try QuoteScreen.open(in: app)
        try requireCondition(
            quote.principalFieldValue() == "0",
            in: app,
            "初始本金應為零 (實際：\(String(describing: quote.principalFieldValue())))"
        )

        // When
        try quote.focusFieldFromLeft(quote.principalField)
        quote.principalField.typeText("1000")

        // Then
        _ = Polling.wait(timeout: 3) {
            quote.suggestedPriceValue() == "$30"
        }
        XCTAssertTrue(quote.isPrincipalFieldFocused(), "建議售價更新時本金應仍持有鍵盤焦點")
        XCTAssertEqual(quote.principalFieldValue(), "1000", "輸入中應顯示新本金")
        XCTAssertEqual(quote.suggestedPriceValue(), "$30", "鍵盤仍開啟時建議售價應已更新")
    }

    /// 驗證刷卡費率從零值開始輸入時不插入原文字，失焦後恢復一位小數格式
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusFieldFromLeft_零值刷卡費率輸入_取代原值並恢復一位小數() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let quote = try QuoteScreen.open(in: app)
        try requireCondition(
            quote.cardFeeFieldValue() == "0.0",
            in: app,
            "刷卡費率初始應顯示一位小數 (實際：\(String(describing: quote.cardFeeFieldValue())))"
        )

        // When
        try quote.focusFieldFromLeft(quote.cardFeeField)
        quote.cardFeeField.typeText("5")
        _ = Polling.wait(timeout: 3) {
            quote.cardFeeFieldValue() == "5"
        }
        let editingValue = quote.cardFeeFieldValue()
        try quote.dismissKeyboard(for: quote.cardFeeField)
        _ = Polling.wait(timeout: 3) {
            quote.cardFeeFieldValue() == "5.0"
        }
        let finalValue = quote.cardFeeFieldValue()

        // Then
        XCTAssertEqual(editingValue, "5", "費率輸入中應只顯示新輸入的文字")
        XCTAssertEqual(finalValue, "5.0", "失焦後刷卡費率應恢復一位小數")
    }

    /// 驗證報價本金可輸入小數，失焦後仍依原格式保留數值
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusFieldFromLeft_本金輸入小數_失焦後保留小數值() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .empty))
        let quote = try QuoteScreen.open(in: app)

        // When
        try quote.focusFieldFromLeft(quote.principalField)
        quote.principalField.typeText("22.8")
        try quote.dismissKeyboard(for: quote.principalField)

        // Then
        _ = Polling.wait(timeout: 3) {
            quote.principalFieldValue() == "22.8"
        }
        XCTAssertEqual(quote.principalFieldValue(), "22.8", "本金結束編輯後應保留輸入的小數")
    }
}

// MARK: - Private Method

private extension QuoteInputFocusUITests {

    /// 從左側聚焦輸入本金並收起鍵盤，確認既有本金為 2500
    ///
    /// - Parameters:
    ///   - quote: 已就緒的報價頁
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: UI 操作失敗或本金前置不符時丟出 UITestError.stopped
    func preparePrincipal(
        in quote: QuoteScreen,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try quote.focusFieldFromLeft(quote.principalField, file: file, line: line)
        quote.principalField.typeText("2500")
        try quote.dismissKeyboard(for: quote.principalField, file: file, line: line)
        _ = Polling.wait(timeout: 3) {
            quote.principalFieldValue() == "2500"
        }
        let value = quote.principalFieldValue()
        try requireCondition(
            value == "2500",
            in: quote.app,
            "建立既有本金的前置值必須是 2500，實際為 \(String(describing: value))",
            file: file,
            line: line
        )
    }
}
