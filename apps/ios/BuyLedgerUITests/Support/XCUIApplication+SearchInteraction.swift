//
//  XCUIApplication+SearchInteraction.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/14.
//

import XCTest

// MARK: - 搜尋欄互動

/// 集中查詢與操作目前前景畫面的搜尋欄
@MainActor
extension XCUIApplication {

    /// 目前第一個可互動的系統搜尋欄；沒有時為 `nil`
    var firstHittableSearchField: XCUIElement? {
        searchFields.allElementsBoundByIndex.first(where: \.isHittableOnScreen)
    }

    /// 目前是否有可互動的系統搜尋欄
    var hasHittableSearchField: Bool {
        firstHittableSearchField != nil
    }

    /// 等待並取得目前前景可互動的系統搜尋欄
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 目前可互動的搜尋欄
    /// - Throws: 搜尋欄逾時仍不可互動時丟出測試錯誤
    func hittableSearchField(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> XCUIElement {
        var field: XCUIElement?
        let hasField = Polling.wait(timeout: 10) {
            field = firstHittableSearchField
            return field != nil
        }
        guard hasField, let field else {
            try stopWithDiagnostics("找不到元素：可互動的搜尋欄", file: file, line: line)
        }
        return field
    }

    /// 在搜尋欄逐字輸入文字，先清除既有內容
    ///
    /// - Parameters:
    ///   - text: 要輸入的搜尋文字
    ///   - field: 搜尋欄
    ///   - clearButton: 搜尋欄的清除鈕，存在時代表欄位有文字
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    /// - Note: 注音鍵盤在輸入一個數字後會切回注音面板，整段 `typeText` 只會輸入到第一個數字，
    ///   因此逐字呼叫 `typeText`
    func typeSearchText(
        _ text: String,
        into field: XCUIElement,
        clearButton: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try field.tapAfterWaiting(in: self, file: file, line: line)
        // 點擊後等鍵盤出現才開始輸入，最多重新點擊三次
        var isKeyboardVisible = keyboards.firstMatch.waitForExistence(timeout: 2)
        var focusAttempts = 0
        while !isKeyboardVisible && focusAttempts < 3 {
            field.tap()
            focusAttempts += 1
            isKeyboardVisible = keyboards.firstMatch.waitForExistence(timeout: 2)
        }
        if !isKeyboardVisible {
            try stopWithDiagnostics("點擊搜尋欄後鍵盤未出現", file: file, line: line)
        }
        if clearButton.exists, let existing = field.value as? String, !existing.isEmpty {
            let deletes = String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count)
            field.typeText(deletes)
        }
        for character in text {
            field.typeText(String(character))
        }
    }

    /// 以 Return 收起指定搜尋欄的鍵盤，等待焦點解除
    ///
    /// - Parameters:
    ///   - field: 要解除焦點的搜尋欄；未指定時使用目前可互動的系統搜尋欄
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 找不到搜尋欄或鍵盤焦點未解除時丟出測試錯誤
    func dismissSearchKeyboard(
        in field: XCUIElement? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let searchField: XCUIElement
        if let field {
            searchField = field
        } else {
            searchField = try hittableSearchField(file: file, line: line)
        }
        try searchField.dismissKeyboardByReturn(in: self, file: file, line: line)
        let hasDismissed = Polling.wait(timeout: 5) {
            !searchField.hasKeyboardFocus && !keyboards.firstMatch.exists
        }
        guard hasDismissed else {
            try stopWithDiagnostics("收鍵盤後搜尋欄仍持有焦點", file: file, line: line)
        }
    }

    /// 收起搜尋鍵盤並確認原有文字與失焦狀態
    ///
    /// - Parameters:
    ///   - text: 收鍵盤後應保留的文字
    ///   - field: 已取得的搜尋欄
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 鍵盤未收起、文字未保留或焦點未解除時丟出測試錯誤
    func dismissSearchKeyboard(
        keeping text: String,
        in field: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try dismissSearchKeyboard(in: field, file: file, line: line)
        guard field.value as? String == text else {
            try stopWithDiagnostics("收鍵盤後搜尋欄應保留既有文字", file: file, line: line)
        }
        guard !field.hasKeyboardFocus else {
            try stopWithDiagnostics("收鍵盤後搜尋欄應已失焦", file: file, line: line)
        }
    }

    /// 點目前搜尋欄的系統清除鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 搜尋欄或清除鈕無法互動時丟出測試錯誤
    func clearSearchText(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let field = try hittableSearchField(file: file, line: line)
        try field.buttons.firstMatch.tapAfterWaiting(in: self, file: file, line: line)
    }

    /// 點窄版導覽列的系統搜尋結束鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 系統結束鈕無法互動時丟出測試錯誤
    func tapSearchEndButton(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        // 系統搜尋結束鈕不帶出 identifier，測試計畫已鎖定正體中文
        try navigationBars.buttons["關閉"].firstMatch.tapAfterWaiting(
            in: self,
            file: file,
            line: line
        )
    }
}
