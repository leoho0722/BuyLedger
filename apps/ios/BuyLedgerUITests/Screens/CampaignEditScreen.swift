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

    /// 儲存按鈕目前是否可用
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
