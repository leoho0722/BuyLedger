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
    /// - Returns: 名稱欄與鍵盤是否已解除焦點
    func dismissNameKeyboard(file: StaticString = #filePath, line: UInt = #line) -> Bool {
        let predicate = NSPredicate(format: "hasKeyboardFocus == true")
        guard nameField.waitForExistence(timeout: 10) else {
            app.failWithDiagnostics("找不到開團名稱欄位", file: file, line: line)
            return false
        }
        if predicate.evaluate(with: nameField) {
            nameField.typeText(XCUIKeyboardKey.return.rawValue)
        }
        let hasDismissed = pollUntil(timeout: 10) {
            !predicate.evaluate(with: nameField)
                && !app.keyboards.firstMatch.exists
                && !app.isNumericPopoverPresented
        }
        guard hasDismissed else {
            app.failWithDiagnostics("開團名稱欄的鍵盤或焦點仍未解除", file: file, line: line)
            return false
        }
        return true
    }

    /// 捲動露出欄位後從左側取得焦點
    ///
    /// - Parameters:
    ///   - field: 要聚焦的文字欄位
    ///   - isScrollingDown: 是否向表單下方尋找欄位
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 欄位是否已取得焦點且鍵盤就緒
    func focusFromLeft(
        _ field: XCUIElement,
        isScrollingDown: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        guard revealField(field, isScrollingDown: isScrollingDown) else {
            app.failWithDiagnostics("開團文字欄位未能捲到可點位置", file: file, line: line)
            return false
        }
        return field.tapLeftToFocus(in: app, file: file, line: line)
    }

    /// 點多行備註左上方的第一行取得焦點並等待鍵盤穩定
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 備註欄位是否已取得焦點且鍵盤就緒
    func focusNotesFromFirstLine(file: StaticString = #filePath, line: UInt = #line) -> Bool {
        guard revealField(notesField, isScrollingDown: true),
              notesField.waitUntilStableAndHittable(
                timeout: 10,
                sampleInterval: 0.2,
                requiredSamples: 3
              ) else {
            app.failWithDiagnostics("開團備註第一行未能穩定呈現在可點位置", file: file, line: line)
            return false
        }
        notesField.coordinate(withNormalizedOffset: CGVector(dx: 0.04, dy: 0.1)).tap()
        let predicate = NSPredicate(format: "hasKeyboardFocus == true")
        var previousFrame: CGRect?
        var matchingFrames = 0
        let isReady = pollUntil(timeout: 10) {
            guard predicate.evaluate(with: notesField),
                  let frame = app.presentedKeyboardFrame else {
                previousFrame = nil
                matchingFrames = 0
                return false
            }
            matchingFrames = frame == previousFrame ? matchingFrames + 1 : 1
            previousFrame = frame
            return matchingFrames >= 3
        }
        guard isReady else {
            app.failWithDiagnostics("點開團備註第一行後焦點或鍵盤未就緒", file: file, line: line)
            return false
        }
        return true
    }

    /// 判定儲存按鈕目前是否可用
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 儲存按鈕是否可用
    func isSaveEnabled(file: StaticString = #filePath, line: UInt = #line) -> Bool {
        let button = app.buttons[BLAccessibilityID.CampaignEdit.saveButton]
        if !button.waitForExistence(timeout: 10) {
            let saveButtonID = BLAccessibilityID.CampaignEdit.saveButton
            app.failWithDiagnostics(
                "找不到 identifier 為 \(saveButtonID) 的儲存按鈕",
                file: file,
                line: line
            )
            return false
        }

        return button.isEnabled
    }

    /// 清空並填入開團名稱
    ///
    /// - Parameters:
    ///   - name: 要填入的開團名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func typeName(_ name: String, file: StaticString = #filePath, line: UInt = #line) {
        let field = app.textFields[BLAccessibilityID.CampaignEdit.nameField]
        field.clearAndType(
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
        let field = app.textFields[BLAccessibilityID.CampaignEdit.nameField]
        return field.exists
            && NSPredicate(format: "hasKeyboardFocus == true").evaluate(with: field)
    }

    /// 點名稱欄取得焦點後續打文字，不清空既有內容
    ///
    /// - Parameters:
    ///   - text: 要續打的文字
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func appendName(_ text: String, file: StaticString = #filePath, line: UInt = #line) {
        let field = app.textFields[BLAccessibilityID.CampaignEdit.nameField]
        field.appendText(
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
    func toggleReminder(file: StaticString = #filePath, line: UInt = #line) {
        let toggle = app.switches[BLAccessibilityID.CampaignEdit.reminderToggle]
        if !toggle.waitForExistence(timeout: 10) {
            app.failWithDiagnostics("找不到訂購提醒開關", file: file, line: line)
            return
        }
        let previousValue = toggle.value as? String ?? ""
        toggle.switches.firstMatch.tapAfterWaiting(in: app, file: file, line: line)
        let changed = NSPredicate(format: "value != %@", previousValue)
        if !toggle.wait(for: changed, timeout: 5) {
            app.failWithDiagnostics("點擊後訂購提醒開關的值沒有改變", file: file, line: line)
        }
    }

    /// 點工具列的儲存
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapSave(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.CampaignEdit.saveButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點工具列的取消
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapCancel(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.CampaignEdit.cancelButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }
}

// MARK: - Screen

extension CampaignEditScreen: Screen {

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
    ///   - isScrollingDown: 是否向表單下方尋找欄位
    /// - Returns: 欄位是否已穩定且完整呈現在表單內
    func revealField(_ field: XCUIElement, isScrollingDown: Bool) -> Bool {
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
                withNormalizedOffset: CGVector(dx: 0.05, dy: isScrollingDown ? 0.25 : 0.65)
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

    /// 取得連續兩次相同的表單內容位置簽章，避免在版面移動中誤判捲動盡頭
    ///
    /// - Returns: 穩定的位置簽章，逾時或表單內容尚未就緒時為 `nil`
    func stableFormPositionSignature() -> String? {
        var previous: String?
        var matchingSamples = 0
        let isStable = pollUntil(timeout: 3) {
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
              let formFrame = rootElement.snapshotFrame else {
            return false
        }
        return frame.minY >= formFrame.minY && frame.maxY <= formFrame.maxY
    }
}
