//
//  XCUIApplication+TextInput.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

// MARK: - 數字鍵盤呈現方式

@MainActor
extension XCUIApplication {

    /// 數字鍵盤的呈現方式，iPadOS 27 不固定為單一樣式
    enum NumericKeyboardPresentation: Equatable {

        /// 完整軟體鍵盤，工具列有完成鍵
        case fullKeyboard

        /// 底部浮動數字面板，沒有工具列完成鍵
        case floatingPad

        /// 貼在欄位旁的 Popover 數字鍵盤
        case popover

        /// 沒有數字鍵盤呈現
        case absent

        /// 診斷訊息用的中文名稱
        var diagnosticName: String {
            switch self {
            case .fullKeyboard:
                return "完整鍵盤"

            case .floatingPad:
                return "浮動數字面板"

            case .popover:
                return "數字 Popover"

            case .absent:
                return "未呈現"
            }
        }
    }
}

// MARK: - 鍵盤狀態讀取

@MainActor
extension XCUIApplication {

    /// 數字 Popover 是否呈現，以 Popover 與全螢幕關閉區域同時出現判定
    var isNumericPopoverPresented: Bool {
        guard popovers.firstMatch.exists else {
            return false
        }
        return descendants(matching: .any)
            .matching(identifier: SystemAccessibilityID.popoverDismissRegion)
            .firstMatch
            .exists
    }

    /// 目前數字鍵盤的呈現方式；Popover 以可及性元素判定，系統鍵盤依框線高度區分
    ///
    /// - Note: iPhone 橫向鍵盤即使較窄，只要高度足夠仍屬完整鍵盤
    /// - Note: 取不到鍵盤框線時沿用 `.fullKeyboard`，由有值斷言的呼叫端捕捉錯誤分類
    var numericKeyboardPresentation: NumericKeyboardPresentation {
        if isNumericPopoverPresented {
            return .popover
        }
        let keyboard = keyboards.firstMatch
        guard keyboard.exists else {
            return .absent
        }
        guard let keyboardFrame = keyboard.snapshotFrame else {
            return .fullKeyboard
        }
        return isFloatingPadFrame(keyboardFrame) ? .floatingPad : .fullKeyboard
    }

    /// 目前呈現中的鍵盤或數字 Popover 框線；完整鍵盤尚未落在視窗內時為 `nil`
    var presentedKeyboardFrame: CGRect? {
        if isNumericPopoverPresented {
            return popovers.firstMatch.snapshotFrame
        }
        let keyboard = keyboards.firstMatch
        guard keyboard.exists,
              let keyboardFrame = keyboard.snapshotFrame,
              let windowFrame = windows.firstMatch.snapshotFrame else {
            return nil
        }
        let isFloatingPad = isFloatingPadFrame(keyboardFrame)
        guard isFloatingPad || windowFrame.contains(keyboardFrame) else {
            return nil
        }
        return keyboardFrame
    }
}

// MARK: - 等待鍵盤狀態

@MainActor
extension XCUIApplication {

    /// 等待數字鍵盤或數字 Popover 任一呈現到逾時
    ///
    /// - Parameter timeout: 等待呈現的秒數
    /// - Returns: 是否在逾時前呈現
    func waitForNumericKeyboardPresentation(timeout: TimeInterval) -> Bool {
        Polling.wait(timeout: timeout) {
            numericKeyboardPresentation != .absent
        }
    }

    /// 等待數字鍵盤與數字 Popover 都收起到逾時
    ///
    /// - Parameter timeout: 等待收起的秒數
    /// - Returns: 是否在逾時前全部收起
    func waitForNumericKeyboardDismissal(timeout: TimeInterval) -> Bool {
        Polling.wait(timeout: timeout) {
            numericKeyboardPresentation == .absent
        }
    }

    /// 等待數字鍵盤換成完整鍵盤到逾時
    ///
    /// - Parameter timeout: 等待的秒數
    /// - Returns: 是否在逾時前換成完整鍵盤
    func waitForFullKeyboard(timeout: TimeInterval) -> Bool {
        Polling.wait(timeout: timeout) {
            numericKeyboardPresentation == .fullKeyboard
        }
    }

    /// 等待呈現方式連續取樣都是完整鍵盤到逾時
    ///
    /// - Parameter timeout: 等待的秒數
    /// - Returns: 是否在逾時前連續取樣都是完整鍵盤
    /// - Note: 呈現方式會在輸入前後轉換，單次讀取可能正在轉換中
    func waitForStableFullKeyboard(timeout: TimeInterval) -> Bool {
        var streak = 0
        return Polling.wait(timeout: timeout) {
            streak = numericKeyboardPresentation == .fullKeyboard ? streak + 1 : 0
            return streak >= 3
        }
    }
}

// MARK: - 注音鍵盤輸入

/// 查詢或點擊無法由 App 設定 identifier 的系統鍵盤項目
@MainActor
extension XCUIApplication {

    /// 等待系統鍵盤出現指定標籤的按鍵
    ///
    /// - Parameters:
    ///   - label: 系統鍵盤顯示的按鍵標籤
    ///   - timeout: 等待按鍵出現的秒數
    /// - Returns: 按鍵是否在逾時前出現
    func waitForKeyboardKey(_ label: String, timeout: TimeInterval) -> Bool {
        let key = keyboards.keys[label].firstMatch
        return Polling.wait(timeout: timeout) {
            key.exists
        }
    }

    /// 點擊系統鍵盤上指定標籤的按鍵
    ///
    /// - Parameters:
    ///   - label: 系統鍵盤顯示的按鍵標籤
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 按鍵不存在或逾時仍不可點時丟出 `UITestError.stopped`
    func tapKeyboardKey(
        _ label: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let key = keyboards.keys[label].firstMatch
        guard key.waitUntilHittable(timeout: 10) else {
            try stopWithDiagnostics("系統鍵盤按鍵「\(label)」不存在或不可點", file: file, line: line)
        }
        key.tap()
    }

    /// 點擊系統鍵盤上符合文字的候選字
    ///
    /// - Parameters:
    ///   - text: 候選字顯示的文字
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 候選字不存在或逾時仍不可點時丟出 `UITestError.stopped`
    func tapKeyboardCandidate(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let candidate = cells[text].firstMatch
        guard candidate.waitUntilHittable(timeout: 10) else {
            try stopWithDiagnostics("系統鍵盤候選字「\(text)」不存在或不可點", file: file, line: line)
        }
        candidate.tap()
    }
}

// MARK: - 浮動面板與 Popover 判定

@MainActor
private extension XCUIApplication {

    /// 浮動數字面板的最大高度
    ///
    /// - Note: 浮動面板遠低於完整鍵盤
    /// - Note: 完整鍵盤約 279 高，依 iPad Air 5 失敗附件實測
    static var floatingPadMaximumHeight: CGFloat {
        120
    }

    /// 判斷鍵盤框線高度是否低於浮動數字面板的高度門檻
    ///
    /// - Parameter keyboardFrame: Keyboard 元素的框線
    /// - Returns: 是否為浮動數字面板
    func isFloatingPadFrame(_ keyboardFrame: CGRect) -> Bool {
        keyboardFrame.height < Self.floatingPadMaximumHeight
    }
}
