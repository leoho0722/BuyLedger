//
//  CampaignEditScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 開團新增與編輯表單的 Page Object
///
/// 以 accessibility identifier 對外暴露開團名稱輸入、訂購提醒開關與儲存／取消的語意操作，元素查詢細節不外洩給測試檔；
/// 新增與編輯共用同一組 identifier，故 Page Object 不分兩種流程
struct CampaignEditScreen: Screen {

    // MARK: - Data Properties

    /// 受測 App
    let app: XCUIApplication

    // MARK: - Computed Properties

    /// 判定編輯表單已就緒的根 identifier (表單捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.CampaignEdit.root
    }

    /// 儲存按鈕目前是否可用
    ///
    /// 讀值前先等按鈕存在，避免元素尚未出現時 `isEnabled` 回傳 `false` 被誤判為停用
    @MainActor
    var isSaveEnabled: Bool {
        let button = app.buttons[BLAccessibilityID.CampaignEdit.saveButton]
        _ = button.waitForExistence(timeout: 10)

        return button.isEnabled
    }
}

// MARK: - Internal Method

@MainActor
extension CampaignEditScreen {

    /// 清空並填入開團名稱
    /// - Parameter name: 要輸入的開團名稱 (使用者資料)
    func typeName(_ name: String) {
        let field = app.textFields[BLAccessibilityID.CampaignEdit.nameField]
        field.waitUntilHittable()
        field.clearAndType(name, in: app)
    }

    /// 切換訂購提醒開關
    func toggleReminder() {
        let toggle = app.switches[BLAccessibilityID.CampaignEdit.reminderToggle]
        toggle.waitUntilHittable()
        toggle.tap()
    }

    /// 點工具列的儲存
    func tapSave() {
        let button = app.buttons[BLAccessibilityID.CampaignEdit.saveButton]
        button.waitUntilHittable()
        button.tap()
    }

    /// 點工具列的取消
    func tapCancel() {
        let button = app.buttons[BLAccessibilityID.CampaignEdit.cancelButton]
        button.waitUntilHittable()
        button.tap()
    }
}
