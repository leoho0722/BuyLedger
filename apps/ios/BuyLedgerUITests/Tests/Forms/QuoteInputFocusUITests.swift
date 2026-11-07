//
//  QuoteInputFocusUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/5.
//

import XCTest

/// 報價欄位取得焦點後的取代、逐欄清空、即時試算與格式回歸 UI 測試
@MainActor
final class QuoteInputFocusUITests: BLUITestCase {

    /// 驗證本金 2500 聚焦後再從左側點入輸入「1000」，欄位值為「1000」，建議售價更新為「$30」，不保留原文
    func testFocusFieldFromLeft_既有本金重新輸入_取代原值並更新售價() {
        // Given
        let app = launch(LaunchOptions(seed: .empty))
        guard let quote = openQuote(in: app), preparePrincipal(in: quote) else {
            return
        }

        // When
        guard quote.focusFieldFromLeft(quote.principalField) else {
            return
        }
        quote.principalField.typeText("1000")

        // Then
        _ = pollUntil(timeout: 3) {
            quote.principalFieldValue == "1000" && quote.suggestedPriceValue == "$30"
        }
        XCTAssertEqual(quote.principalFieldValue, "1000", "重新聚焦後應以新本金取代原值")
        XCTAssertEqual(quote.suggestedPriceValue, "$30", "本金 1000 的建議售價應為 $30")
    }

    /// 驗證本金仍聚焦時直接點當地運費，輸入取代運費原值且本金保留
    func testFocusFieldFromLeft_本金直接換到運費_運費清空後輸入且本金不變() {
        // Given
        let app = launch(LaunchOptions(seed: .empty))
        guard let quote = openQuote(in: app),
              quote.focusFieldFromLeft(quote.localShippingField) else {
            return
        }
        quote.localShippingField.typeText("30")
        quote.dismissKeyboard(for: quote.localShippingField)
        _ = pollUntil(timeout: 3) {
            quote.localShippingFieldValue == "30"
        }
        XCTAssertEqual(quote.localShippingFieldValue, "30", "前置當地運費必須先是 30")

        guard quote.focusFieldFromLeft(quote.principalField) else {
            return
        }
        quote.principalField.typeText("2500")
        _ = pollUntil(timeout: 3) {
            quote.principalFieldValue == "2500"
        }
        XCTAssertEqual(quote.principalFieldValue, "2500", "前置本金必須先是 2500")
        XCTAssertTrue(quote.isPrincipalFieldFocused(), "換欄前本金必須仍持有鍵盤焦點")

        // When
        guard quote.focusFieldFromLeft(quote.localShippingField) else {
            return
        }
        quote.localShippingField.typeText("5")

        // Then
        _ = pollUntil(timeout: 3) {
            quote.localShippingFieldValue == "5" && quote.principalFieldValue == "2500"
        }
        XCTAssertEqual(quote.localShippingFieldValue, "5", "直接換欄後應以新運費取代原值")
        XCTAssertEqual(quote.principalFieldValue, "2500", "換到當地運費時本金應保留原值")
    }

    /// 驗證只聚焦已有本金會清空草稿並顯示零提示，沒有輸入就失焦仍還原原值
    func testFocusFieldFromLeft_本金未輸入即失焦_聚焦清空且恢復原值() {
        // Given
        let app = launch(LaunchOptions(seed: .empty))
        guard let quote = openQuote(in: app), preparePrincipal(in: quote) else {
            return
        }
        XCTAssertEqual(quote.principalField.placeholderValue, "0", "本金欄提示文字應維持為 0")

        // When
        guard quote.focusFieldFromLeft(quote.principalField) else {
            return
        }
        let focusedValue = quote.principalFieldValue
        quote.dismissKeyboard(for: quote.principalField)
        _ = pollUntil(timeout: 3) {
            quote.principalFieldValue == "2500"
        }
        let finalValue = quote.principalFieldValue

        // Then
        XCTAssertEqual(focusedValue, "0", "聚焦中應清空草稿，空欄的 value 會讀到提示文字 0")
        XCTAssertEqual(finalValue, "2500", "未輸入就失焦應還原原本本金")
    }

    /// 驗證零值本金輸入時立即更新售價，不必等到收起鍵盤才試算
    func testFocusFieldFromLeft_零值本金輸入中_未失焦即更新建議售價() {
        // Given
        let app = launch(LaunchOptions(seed: .empty))
        guard let quote = openQuote(in: app) else {
            return
        }
        XCTAssertEqual(quote.principalFieldValue, "0", "初始本金應為零")

        // When
        guard quote.focusFieldFromLeft(quote.principalField) else {
            return
        }
        quote.principalField.typeText("1000")

        // Then
        _ = pollUntil(timeout: 3) {
            quote.suggestedPriceValue == "$30"
        }
        XCTAssertTrue(quote.isPrincipalFieldFocused(), "建議售價更新時本金應仍持有鍵盤焦點")
        XCTAssertEqual(quote.principalFieldValue, "1000", "輸入中應顯示新本金")
        XCTAssertEqual(quote.suggestedPriceValue, "$30", "鍵盤仍開啟時建議售價應已更新")
    }

    /// 驗證刷卡費率從零值開始輸入時不插入原文字，失焦後恢復一位小數格式
    func testFocusFieldFromLeft_零值刷卡費率輸入_取代原值並恢復一位小數() {
        // Given
        let app = launch(LaunchOptions(seed: .empty))
        guard let quote = openQuote(in: app) else {
            return
        }
        XCTAssertEqual(quote.cardFeeFieldValue, "0.0", "刷卡費率初始應顯示一位小數")

        // When
        guard quote.focusFieldFromLeft(quote.cardFeeField) else {
            return
        }
        quote.cardFeeField.typeText("5")
        _ = pollUntil(timeout: 3) {
            quote.cardFeeFieldValue == "5"
        }
        let editingValue = quote.cardFeeFieldValue
        quote.dismissKeyboard(for: quote.cardFeeField)
        _ = pollUntil(timeout: 3) {
            quote.cardFeeFieldValue == "5.0"
        }
        let finalValue = quote.cardFeeFieldValue

        // Then
        XCTAssertEqual(editingValue, "5", "費率輸入中應只顯示新輸入的文字")
        XCTAssertEqual(finalValue, "5.0", "失焦後刷卡費率應恢復一位小數")
    }

    /// 驗證報價本金可輸入小數，失焦後仍依原格式保留數值
    func testFocusFieldFromLeft_本金輸入小數_失焦後保留小數值() {
        // Given
        let app = launch(LaunchOptions(seed: .empty))
        guard let quote = openQuote(in: app) else {
            return
        }

        // When
        guard quote.focusFieldFromLeft(quote.principalField) else {
            return
        }
        quote.principalField.typeText("22.8")
        quote.dismissKeyboard(for: quote.principalField)

        // Then
        _ = pollUntil(timeout: 3) {
            quote.principalFieldValue == "22.8"
        }
        XCTAssertEqual(quote.principalFieldValue, "22.8", "本金結束編輯後應保留輸入的小數")
    }
}

// MARK: - Private Method

private extension QuoteInputFocusUITests {

    /// 從更多分頁開啟報價工具並等待根元素就緒
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的報價頁，無法開啟時附診斷並回傳缺值
    func openQuote(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> QuoteScreen? {
        let quote = QuoteScreen.open(from: app, file: file, line: line)
        guard quote.waitUntilReady() else {
            app.failWithDiagnostics("報價試算頁尚未就緒", file: file, line: line)
            return nil
        }
        return quote
    }

    /// 從左側聚焦輸入本金並收起鍵盤，確認既有本金前置值為 2500
    ///
    /// - Parameters:
    ///   - quote: 已就緒的報價頁
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 輸入後欄位值為 2500 時為真
    func preparePrincipal(
        in quote: QuoteScreen,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        guard quote.focusFieldFromLeft(quote.principalField, file: file, line: line) else {
            return false
        }
        quote.principalField.typeText("2500")
        quote.dismissKeyboard(for: quote.principalField, file: file, line: line)
        _ = pollUntil(timeout: 3) {
            quote.principalFieldValue == "2500"
        }
        let value = quote.principalFieldValue
        guard value == "2500" else {
            quote.app.failWithDiagnostics("建立既有本金的前置值必須是 2500", file: file, line: line)
            return false
        }
        return true
    }
}
