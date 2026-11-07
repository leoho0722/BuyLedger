//
//  XCUIElement+TextInput.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

// MARK: - 文字輸入與數字鍵盤收起

@MainActor
extension XCUIElement {

    /// 清空欄位既有內容後輸入新文字
    ///
    /// - Parameters:
    ///   - text: 要輸入的文字
    ///   - app: 受測 App
    ///   - timeout: 等待欄位可互動的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Note: 以欄位本身取得鍵盤焦點為準，畫面上有鍵盤不代表輸入會落在此欄位
    /// - Note: 只有未聚焦時才點擊，App 在聚焦時清空數字草稿或把文字游標放在尾端
    /// - Note: 輸入前等鍵盤就位
    /// - Note: 輸入後等欄位框線穩定
    /// - Note: 涵蓋鍵盤在打字後才升起、表單隨之上移的情況
    func clearAndType(
        _ text: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        typeInField(
            text,
            in: app,
            shouldReplaceExisting: true,
            timeout: timeout,
            file: file,
            line: line
        )
    }

    /// 依 App 的聚焦行為接續輸入文字
    ///
    /// - Parameters:
    ///   - text: 要接續輸入的文字
    ///   - app: 受測 App
    ///   - timeout: 等待欄位可互動的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Note: 文字欄由 App 在聚焦時把游標放在尾端，已聚焦時沿用目前游標而不再點擊
    /// - Note: 數字欄只有已聚焦時才接續輸入，未聚焦時 App 會先清空草稿
    /// - Note: 與 `clearAndType` 共用焦點確認與鍵盤等待，差別只在不主動刪除既有文字
    func appendText(
        _ text: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        typeInField(
            text,
            in: app,
            shouldReplaceExisting: false,
            timeout: timeout,
            file: file,
            line: line
        )
    }

    /// 收起數字鍵盤或數字 Popover，並解除欄位的鍵盤焦點
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Note: 呈現方式連續取樣都是完整鍵盤時才點完成鍵
    /// - Note: 浮動面板與 Popover 先在本欄位點兩下換成完整鍵盤
    /// - Note: 完整鍵盤點過完成鍵仍收不掉則直接附診斷失敗
    /// - Note: 不送 return
    /// - Note: 依畫面元素分流，不依裝置或系統版本分支
    func dismissNumericKeyboard(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard exists else {
            app.failWithDiagnostics("數字鍵盤目標欄位不存在，無法解除焦點", file: file, line: line)
            return
        }
        guard app.waitForNumericKeyboardPresentation(timeout: 10) else {
            app.failWithDiagnostics(
                "數字鍵盤未呈現，無法收起 (呈現方式：\(app.numericKeyboardPresentation.diagnosticName))",
                file: file,
                line: line
            )
            return
        }

        let doneButton = app.buttons[BLAccessibilityID.Common.keyboardDoneButton]
        let hasTappedDone = doneButton.tapDoneIfFullKeyboard(in: app, timeout: 1.5)

        if !app.waitForNumericKeyboardDismissal(timeout: hasTappedDone ? 3 : 0) {
            let presentation = app.numericKeyboardPresentation
            guard !hasTappedDone || presentation != .fullKeyboard else {
                app.failWithDiagnostics(
                    "數字鍵盤工具列的完成鍵未能收起鍵盤 (呈現方式：\(presentation.diagnosticName))",
                    file: file,
                    line: line
                )
                return
            }
            if presentation == .floatingPad || presentation == .popover {
                coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).doubleTap()
                _ = app.waitForFullKeyboard(timeout: 3)
            }
            doneButton.tapDoneIfFullKeyboard(in: app, timeout: 3)
        }

        guard app.waitForNumericKeyboardDismissal(timeout: 5) else {
            app.failWithDiagnostics(
                "數字鍵盤或 Popover 未能收起 (呈現方式：\(app.numericKeyboardPresentation.diagnosticName))",
                file: file,
                line: line
            )
            return
        }
        let isFocusReleased = pollUntil(timeout: 2) {
            !isKeyboardFocused
        }
        guard isFocusReleased else {
            app.failWithDiagnostics("收起數字鍵盤後欄位仍取得鍵盤焦點", file: file, line: line)
            return
        }
    }
}

// MARK: - 輸入流程與鍵盤狀態

@MainActor
private extension XCUIElement {

    /// 欄位本身是否取得鍵盤焦點，以 `hasKeyboardFocus` 鍵值判定
    var isKeyboardFocused: Bool {
        exists && NSPredicate(format: "hasKeyboardFocus == true").evaluate(with: self)
    }

    /// 必要時聚焦欄位，確認焦點與鍵盤就緒後輸入文字
    ///
    /// - Parameters:
    ///   - text: 要輸入的文字
    ///   - app: 受測 App
    ///   - shouldReplaceExisting: 是否先清除既有文字
    ///   - timeout: 等待欄位可互動的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func typeInField(
        _ text: String,
        in app: XCUIApplication,
        shouldReplaceExisting: Bool,
        timeout: TimeInterval,
        file: StaticString,
        line: UInt
    ) {
        guard waitUntilHittableOrFail(
            in: app,
            timeout: timeout,
            file: file,
            line: line
        ) else {
            return
        }
        // 表單 sheet 升起時會整個上移，點擊前等框線穩定
        _ = waitUntilStableAndHittable(timeout: 2, sampleInterval: 0.2, requiredSamples: 3)
        if !isKeyboardFocused {
            tap()
        }
        var isFocused = waitUntilKeyboardFocused(in: app, timeout: 2)
        var focusAttempts = 0
        while !isFocused && focusAttempts < 3 {
            if !isKeyboardFocused, isHittableOnScreen {
                tap()
            }
            focusAttempts += 1
            isFocused = waitUntilKeyboardFocused(in: app, timeout: 2)
        }
        let target = identifier.isEmpty
            ? "點擊無 identifier 的輸入欄"
            : "點擊 identifier 為 \(identifier) 的輸入欄"
        guard isFocused else {
            app.failWithDiagnostics(
                "\(target)後未取得鍵盤焦點，\(keyboardFocusSummary(in: app))",
                file: file,
                line: line
            )
            return
        }

        let existing = value as? String ?? ""
        let isSearchField = elementType == .searchField
        let searchPlaceholder = placeholderValue ?? ""
        if shouldReplaceExisting, isSearchField, !existing.isEmpty, existing != searchPlaceholder {
            guard clearSearchField(
                placeholder: searchPlaceholder,
                timeout: timeout,
                in: app,
                file: file,
                line: line
            ) else {
                return
            }
        }

        // 鍵盤或 Popover 未就位時輸入，字元會落到過渡中的鍵盤；逾時照樣輸入，並把鍵盤狀態附在結果中
        let isKeyboardSettled = pollFrameStable(
            requiredSamples: 3,
            sampleInterval: 0.1,
            timeout: 5
        ) {
            app.presentedKeyboardFrame
        }
        if !isKeyboardSettled {
            let attachment = XCTAttachment(string: keyboardFocusSummary(in: app))
            attachment.lifetime = .keepAlways
            XCTContext.runActivity(named: "鍵盤未就位即輸入") { $0.add(attachment) }
        }
        if shouldReplaceExisting, !isSearchField, !existing.isEmpty {
            let deletes = String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count)
            typeText(deletes)
        }
        typeText(text)
        // 打字後鍵盤才升起時表單會上移，輸入後等欄位框線連續相同才返回
        _ = pollFrameStable(requiredSamples: 2, sampleInterval: 0.2, timeout: 2) {
            snapshotFrame
        }
    }

    /// 等待欄位取得鍵盤焦點，且鍵盤或數字 Popover 已呈現，到逾時為止
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - timeout: 等待的秒數
    /// - Returns: 欄位是否在逾時前取得鍵盤焦點且鍵盤或 Popover 已呈現
    func waitUntilKeyboardFocused(in app: XCUIApplication, timeout: TimeInterval) -> Bool {
        pollUntil(timeout: timeout) {
            isKeyboardFocused && (app.keyboards.firstMatch.exists || app.isNumericPopoverPresented)
        }
    }

    /// 描述鍵盤呈現方式與取得鍵盤焦點的輸入欄，供失敗訊息帶出焦點所在欄位
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 鍵盤呈現方式與焦點所在輸入欄的描述；無輸入欄取得焦點時明列
    func keyboardFocusSummary(in app: XCUIApplication) -> String {
        let presentation = app.numericKeyboardPresentation.diagnosticName
        let inputs = app.textFields.allElementsBoundByIndex
            + app.secureTextFields.allElementsBoundByIndex
            + app.textViews.allElementsBoundByIndex
            + app.searchFields.allElementsBoundByIndex
        let focusedCandidate = inputs.first { $0.isKeyboardFocused }
        guard let focused = focusedCandidate else {
            return "鍵盤呈現方式為\(presentation)，沒有任何輸入欄取得鍵盤焦點"
        }
        let name = focused.identifier.isEmpty
            ? "無 identifier 的輸入欄"
            : "identifier 為 \(focused.identifier) 的輸入欄"
        return "鍵盤呈現方式為\(presentation)，焦點在 \(name)"
    }

    /// 用搜尋欄內建清除鈕清空文字，並恢復鍵盤焦點
    ///
    /// - Parameters:
    ///   - placeholder: 搜尋欄的 `placeholderValue`
    ///   - timeout: 等待清除鈕可互動及欄位更新的秒數
    ///   - app: 受測 App
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Returns: 搜尋欄是否已清空並保有鍵盤焦點
    func clearSearchField(
        placeholder: String,
        timeout: TimeInterval,
        in app: XCUIApplication,
        file: StaticString,
        line: UInt
    ) -> Bool {
        // 搜尋欄中央點擊會移動游標到文字中間，改用清除鈕避免刪除殘留右側文字
        let clearButton = descendants(matching: .button).firstMatch
        guard clearButton.waitUntilHittable(timeout: timeout) else {
            let currentValue = value as? String ?? ""
            let message = """
            搜尋欄清除按鈕不存在或逾時不可點 \
            (欄位目前 value: \(currentValue))
            """
            app.failWithDiagnostics(message, file: file, line: line)
            return false
        }
        clearButton.tap()

        let isSearchFieldCleared = pollUntil(timeout: timeout) {
            let current = value as? String ?? ""
            return current.isEmpty || current == placeholder
        }
        guard isSearchFieldCleared else {
            let currentValue = value as? String ?? ""
            let message = """
            搜尋欄點擊清除鈕後逾時仍有文字 \
            (欄位目前 value: \(currentValue))
            """
            app.failWithDiagnostics(message, file: file, line: line)
            return false
        }

        if !waitUntilKeyboardFocused(in: app, timeout: 1) {
            // iPadOS 27 點擊清除鈕後搜尋欄會失去鍵盤焦點，需在欄位上重新聚焦
            tap()
            guard waitUntilKeyboardFocused(in: app, timeout: 2) else {
                app.failWithDiagnostics(
                    "搜尋欄清空後重新聚焦失敗，\(keyboardFocusSummary(in: app))",
                    file: file,
                    line: line
                )
                return false
            }
        }
        return true
    }

    /// 呈現方式連續取樣都是完整鍵盤時點完成鍵
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - timeout: 等待完成鍵可點與呈現方式穩定的秒數
    /// - Returns: 是否已送出點擊
    /// - Note: 浮動面板上 XCUI 仍回報完成鍵可點，但點擊到不了按鈕，只會換成完整鍵盤
    /// - Note: 完成鍵存在但不可點時點其框線中心
    @discardableResult
    func tapDoneIfFullKeyboard(in app: XCUIApplication, timeout: TimeInterval) -> Bool {
        _ = waitUntilHittable(timeout: timeout)
        guard app.waitForStableFullKeyboard(timeout: timeout), exists else {
            return false
        }
        if isHittableOnScreen {
            tap()
        } else {
            coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        return true
    }
}

/// 以取樣間隔連續讀取框線，直到連續相同的次數達標或逾時
///
/// - Parameters:
///   - requiredSamples: 需要連續相同的取樣次數，包含第一次
///   - sampleInterval: 兩次取樣之間的間隔秒數
///   - timeout: 等待框線穩定的秒數
///   - frame: 每次取樣讀取的框線，讀不到時為 `nil`
/// - Returns: 框線是否在逾時前連續相同
@MainActor
private func pollFrameStable(
    requiredSamples: Int,
    sampleInterval: TimeInterval,
    timeout: TimeInterval,
    frame: () -> CGRect?
) -> Bool {
    let deadline = Date.now.addingTimeInterval(timeout)
    var previous: CGRect?
    var streak = 0
    while true {
        if let current = frame() {
            streak = current == previous ? streak + 1 : 1
            previous = current
            if streak >= requiredSamples {
                return true
            }
        } else {
            previous = nil
            streak = 0
        }
        guard Date.now < deadline else {
            return false
        }
        _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: sampleInterval)
    }
}
