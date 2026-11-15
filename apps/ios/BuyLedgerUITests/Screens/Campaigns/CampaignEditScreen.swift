//
//  CampaignEditScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 開團新增與編輯表單的 Page Object
struct CampaignEditScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Computed Properties

@MainActor
extension CampaignEditScreen {

    /// 開團名稱輸入欄位
    var nameField: XCUIElement {
        app.textFields[BLAccessibilityID.CampaignEdit.nameField]
    }

    /// 開團多行備註輸入欄位
    var notesField: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.CampaignEdit.notesField].firstMatch
    }

    /// 備註欄目前的原始文字值
    var notesValue: String? {
        notesField.value as? String
    }

    /// 開團資訊區段中名稱欄下方的開團日期列
    var openDatePicker: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.CampaignEdit.openDatePicker]
    }

    /// 開團資訊區段中緊接開團日期的結單日期列
    var closeDatePicker: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.CampaignEdit.closeDatePicker]
    }

    /// 訂購提醒時間選擇器，提醒開啟時才出現
    var reminderDatePicker: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.CampaignEdit.reminderDatePicker]
    }
}

// MARK: - Internal Method

@MainActor
extension CampaignEditScreen {

    /// 以 return 收起名稱欄鍵盤並確認焦點解除
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 找不到名稱欄或 Return 後焦點未解除時丟出測試錯誤
    func dismissNameKeyboard(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try nameField.dismissKeyboardByReturn(in: app, file: file, line: line)
    }

    /// 捲動露出欄位後從左側取得焦點
    ///
    /// - Parameters:
    ///   - field: 要聚焦的文字欄位
    ///   - isSwipingUp: 是否向上滑動以尋找表單下方欄位
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func focusFromLeft(
        _ field: XCUIElement,
        isSwipingUp: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        guard revealField(field, isSwipingUp: isSwipingUp) else {
            try app.stopWithDiagnostics(
                "開團文字欄位未能捲到可點位置",
                file: file,
                line: line
            )
        }
        try field.tapLeftToFocus(in: app, file: file, line: line)
    }

    /// 捲出多行備註後點左上方的第一行取得焦點並等待鍵盤穩定
    ///
    /// - Parameters:
    ///   - timeout: 等待欄位與鍵盤就緒的秒數
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 欄位無法捲到可點位置、不可點或點擊後鍵盤未就緒時丟出測試錯誤
    func focusNotesFromFirstLine(
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        guard revealField(notesField, isSwipingUp: true) else {
            try app.stopWithDiagnostics("開團備註未能捲到可點位置", file: file, line: line)
        }
        try notesField.focusFromFirstLine(in: app, timeout: timeout, file: file, line: line)
    }

    /// 判定儲存按鈕目前是否可用
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 儲存按鈕是否可用
    /// - Throws: 找不到儲存按鈕時丟出測試錯誤
    func isSaveEnabled(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> Bool {
        let button = app.buttons[BLAccessibilityID.CampaignEdit.saveButton]
        if !button.waitForExistence(timeout: 10) {
            let saveButtonID = BLAccessibilityID.CampaignEdit.saveButton
            try app.stopWithDiagnostics(
                "找不到 identifier 為 \(saveButtonID) 的儲存按鈕",
                file: file,
                line: line
            )
        }

        return button.isEnabled
    }

    /// 清空並填入開團名稱
    ///
    /// - Parameters:
    ///   - name: 要填入的開團名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func typeName(
        _ name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = app.textFields[BLAccessibilityID.CampaignEdit.nameField]
        try field.clearAndType(
            name,
            in: app,
            file: file,
            line: line
        )
    }

    /// 取得名稱欄目前的文字值
    ///
    /// - Returns: 名稱欄的文字值；欄位不存在或值不是字串時為 `nil`
    func nameFieldValue() -> String? {
        app.textFields[BLAccessibilityID.CampaignEdit.nameField].value as? String
    }

    /// 判定名稱欄是否取得鍵盤焦點，以 `hasKeyboardFocus` 鍵值判定
    ///
    /// - Returns: 名稱欄是否為鍵盤焦點
    func isNameFieldFocused() -> Bool {
        nameField.hasKeyboardFocus
    }

    /// 依 App 的聚焦行為接續輸入，不清空既有內容
    ///
    /// - Parameters:
    ///   - text: 要續打的文字
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Note: 欄位已聚焦時不再點擊；未聚焦時由共用輸入 helper 取得焦點
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func appendName(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = app.textFields[BLAccessibilityID.CampaignEdit.nameField]
        try field.appendText(
            text,
            in: app,
            file: file,
            line: line
        )
    }

    /// 切換訂購提醒開關，點內層原生開關並確認值已改變
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Note: 外層開關涵蓋整列，點它的中心會落在標題文字上而不切換
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func toggleReminder(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let toggle = app.switches[BLAccessibilityID.CampaignEdit.reminderToggle]
        guard toggle.waitForExistence(timeout: 10) else {
            try app.stopWithDiagnostics("找不到訂購提醒開關", file: file, line: line)
        }
        let previousValue = toggle.value as? String ?? ""
        try toggle.switches.firstMatch.tapAfterWaiting(in: app, file: file, line: line)
        let changed = NSPredicate(format: "value != %@", previousValue)
        guard toggle.wait(for: changed, timeout: 5) else {
            try app.stopWithDiagnostics(
                "點擊後訂購提醒開關的值沒有改變",
                file: file,
                line: line
            )
        }
    }

    /// 點工具列的儲存
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapSave(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let button = app.buttons[BLAccessibilityID.CampaignEdit.saveButton]
        try button.tapAfterWaiting(in: app, file: file, line: line)
    }
}

// MARK: - ScreenProtocol

extension CampaignEditScreen: ScreenProtocol {

    /// 判定編輯表單已就緒的根 identifier (表單捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.CampaignEdit.root
    }
}

// MARK: - Private Method

@MainActor
private extension CampaignEditScreen {

    /// 以左緣的慢速拖曳露出文字欄位，位置不再變化時停止
    ///
    /// - Parameters:
    ///   - field: 要露出的文字欄位
    ///   - isSwipingUp: 是否向上滑動以尋找表單下方欄位
    /// - Returns: 欄位是否已穩定且完整呈現在表單內
    func revealField(_ field: XCUIElement, isSwipingUp: Bool) -> Bool {
        guard rootElement.waitForExistence(timeout: 10) else {
            return false
        }
        var previous = stableFormPositionSignature()
        for _ in 0..<20 {
            if isFieldVisible(field) {
                return true
            }
            let start = rootElement.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.45))
            let end = rootElement.coordinate(
                withNormalizedOffset: CGVector(dx: 0.05, dy: isSwipingUp ? 0.25 : 0.65)
            )
            start.press(
                forDuration: 0.1,
                thenDragTo: end,
                withVelocity: .slow,
                thenHoldForDuration: 0.2
            )
            if isFieldVisible(field) {
                return true
            }
            let current = stableFormPositionSignature()
            if let current, current == previous {
                break
            }
            previous = current
        }
        return isFieldVisible(field)
    }

    /// 取得穩定的位置簽章，避免版面移動時誤判捲動盡頭
    ///
    /// - Returns: 穩定的位置簽章，逾時或表單內容尚未就緒時為 `nil`
    func stableFormPositionSignature() -> String? {
        var previous: String?
        var matchingSamples = 0
        let isStable = Polling.wait(timeout: 3) {
            guard let current = app.scrollPositionSignature(in: rootElement) else {
                previous = nil
                matchingSamples = 0
                return false
            }
            matchingSamples = current == previous ? matchingSamples + 1 : 1
            previous = current
            return matchingSamples >= 2
        }
        return isStable ? previous : nil
    }

    /// 判斷欄位是否穩定可點且完整落在表單的垂直範圍內
    ///
    /// - Parameter field: 要判斷的欄位
    /// - Returns: 欄位是否完整可見
    func isFieldVisible(_ field: XCUIElement) -> Bool {
        guard field.waitUntilStableAndHittable(timeout: 1),
              let frame = field.snapshotFrame,
              frame.isUsableFrame,
              let formFrame = rootElement.snapshotFrame,
              formFrame.isUsableFrame else {
            return false
        }
        return frame.minY >= formFrame.minY && frame.maxY <= formFrame.maxY
    }
}
