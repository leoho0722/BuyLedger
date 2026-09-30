//
//  CampaignEditScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 開團新增與編輯表單的 Page Object
struct CampaignEditScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定編輯表單已就緒的根 identifier (表單捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.CampaignEdit.root
    }
}

// MARK: - Internal Method

@MainActor
extension CampaignEditScreen {

    /// 儲存按鈕目前是否可用
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 儲存按鈕是否可用
    func isSaveEnabled(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
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
    func typeName(
        _ name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let field = app.textFields[BLAccessibilityID.CampaignEdit.nameField]
        field.clearAndType(
            name,
            in: app,
            file: file,
            line: line
        )
    }

    /// 切換訂購提醒開關
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func toggleReminder(file: StaticString = #filePath, line: UInt = #line) {
        let toggle = app.switches[BLAccessibilityID.CampaignEdit.reminderToggle]
        toggle.tapAfterWaiting(in: app, file: file, line: line)
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
