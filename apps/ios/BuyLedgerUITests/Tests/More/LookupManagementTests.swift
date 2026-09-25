//
//  LookupManagementTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/9/24.
//

import XCTest

/// 主檔管理頁的新增、改名、刪除與失敗流程 UI 測試
final class LookupManagementTests: BLUITestCase {

    // MARK: - Tests

    /// 新增商品類別後清單出現新名稱
    @MainActor
    func testAddCategoryAddsNewName() {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let lookupManagement = LookupManagementScreen(app: app)
        lookupManagement.openCategoryManagement()

        // When
        lookupManagement.addItem(named: "手作小物")

        // Then
        let newRow = lookupManagement.itemRow(named: "手作小物")
        if !newRow.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "新增商品類別後清單未出現「手作小物」")
        }
        XCTAssertTrue(newRow.exists, "新增商品類別後應出現「手作小物」")
    }

    /// 商品類別改名後管理清單只顯示新名稱
    @MainActor
    func testRenameCategoryUpdatesLookup() {
        // Given
        let app = launch(LaunchOptions(seed: .minimalOrders))
        let lookupManagement = LookupManagementScreen(app: app)
        lookupManagement.openCategoryManagement()

        // When
        lookupManagement.renameItem(from: "服飾", to: "衣著")

        // Then
        let renamedRow = lookupManagement.itemRow(named: "衣著")
        if !renamedRow.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "改名後商品類別清單未出現「衣著」")
        }
        XCTAssertTrue(renamedRow.exists, "商品類別清單應出現新名稱「衣著」")
        XCTAssertFalse(lookupManagement.itemRow(named: "服飾").exists, "舊名稱不應留在清單")
    }

    /// 商品類別改名後新訂單選擇器只顯示新名稱
    @MainActor
    func testRenameCategoryUpdatesNewOrderPicker() {
        // Given
        let app = launch(LaunchOptions(seed: .minimalOrders))
        let lookupManagement = LookupManagementScreen(app: app)
        lookupManagement.openCategoryManagement()

        // When
        lookupManagement.renameItem(from: "服飾", to: "衣著")

        let root = RootNavigationScreen(app: app)
        if !root.goToOrders() {
            failWithDiagnostics(in: app, "切到訂單分頁後畫面未就緒")
        }

        let orders = OrdersScreen(app: app)
        if !orders.waitUntilReady() {
            failWithDiagnostics(in: app, "訂單清單未出現")
        }
        orders.tapAddOrder()

        let orderEdit = OrderEditScreen(app: app)
        if !orderEdit.waitUntilReady() {
            failWithDiagnostics(in: app, "新增訂單編輯表單未出現")
        }
        orderEdit.openCategoryPicker()

        // Then
        let pickerRoot = app.descendants(matching: .any)[BLAccessibilityID.OptionPicker.root]
        if !pickerRoot.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "新訂單類別選擇器未出現")
        }

        let newOption = app.descendants(matching: .any)[
            BLAccessibilityID.OptionPicker.optionRow("衣著")
        ]
        if !newOption.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "新訂單類別選擇器未出現「衣著」")
        }
        XCTAssertTrue(newOption.exists, "新訂單類別選擇器應包含「衣著」")

        let oldOption = app.descendants(matching: .any)[
            BLAccessibilityID.OptionPicker.optionRow("服飾")
        ]
        XCTAssertFalse(oldOption.exists, "新訂單類別選擇器不應包含舊名稱「服飾」")
    }

    /// 確認刪除商品類別後清單不再出現該名稱
    @MainActor
    func testDeleteCategoryRemovesName() {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let lookupManagement = LookupManagementScreen(app: app)
        lookupManagement.openCategoryManagement()

        // When
        lookupManagement.deleteItem(named: "生活雜貨")

        // Then
        let deletedRow = lookupManagement.itemRow(named: "生活雜貨")
        if !deletedRow.waitForDisappearance(timeout: 10) {
            failWithDiagnostics(in: app, "確認刪除後商品類別仍留在清單")
        }
        XCTAssertFalse(deletedRow.exists, "刪除後不應出現「生活雜貨」")
    }

    /// 刪除寫入失敗時顯示一次性 alert 並保留項目
    @MainActor
    func testDeleteWriteFailureShowsAlertAndLeavesListUnchanged() {
        // Given
        var options = LaunchOptions(seed: .lookupsOnly)
        options.shouldFailLookupWrites = true
        let app = launch(options)
        let lookupManagement = LookupManagementScreen(app: app)
        lookupManagement.openCategoryManagement()

        // When
        guard lookupManagement.requestDeletion(named: "生活雜貨") else {
            return
        }

        // Then
        let failureAlert = app.alerts.matching(
            NSPredicate(format: "label CONTAINS %@", "操作失敗")
        ).firstMatch
        if !failureAlert.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "刪除寫入失敗後「操作失敗」alert 未出現")
            return
        }
        app.tapAlertButton(label: "知道了")
        if !failureAlert.waitForDisappearance(timeout: 5) {
            failWithDiagnostics(in: app, "關閉刪除失敗提示後 alert 未收回")
        }

        XCTAssertTrue(
            lookupManagement.itemRow(named: "生活雜貨").exists,
            "刪除寫入失敗後清單應保留「生活雜貨」"
        )
        XCTAssertFalse(
            lookupManagement.loadFailureMessage.exists,
            "刪除寫入失敗後不應留下主檔載入錯誤文字"
        )
    }

    /// 新增寫入失敗時顯示一次性 alert 且不改變清單
    @MainActor
    func testAddWriteFailureShowsAlertAndLeavesListUnchanged() {
        // Given
        var options = LaunchOptions(seed: .lookupsOnly)
        options.shouldFailLookupWrites = true
        let app = launch(options)
        let lookupManagement = LookupManagementScreen(app: app)
        lookupManagement.openCategoryManagement()

        // When
        lookupManagement.addItem(named: "失敗類別")

        // Then
        let alert = app.alerts.firstMatch
        if !alert.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "主檔寫入失敗後「操作失敗」alert 未出現")
            return
        }
        XCTAssertTrue(alert.label.contains("操作失敗"), "應顯示「操作失敗」alert")
        app.tapAlertButton(label: "知道了")
        if !alert.waitForDisappearance(timeout: 5) {
            failWithDiagnostics(in: app, "關閉寫入失敗提示後 alert 未收回")
        }

        XCTAssertFalse(
            lookupManagement.itemRow(named: "失敗類別").exists,
            "寫入失敗後清單不應出現「失敗類別」"
        )
        XCTAssertFalse(
            lookupManagement.loadFailureMessage.exists,
            "寫入失敗後不應留下主檔載入錯誤文字"
        )
    }

    /// 主檔首次載入失敗時顯示載入錯誤文字
    @MainActor
    func testInitialLoadFailureShowsMessage() {
        // Given
        let options = LaunchOptions(seed: .lookupsOnly, loadFailure: .lookups)
        let app = launch(options)
        let lookupManagement = LookupManagementScreen(app: app)

        // When
        lookupManagement.openCategoryManagement()

        // Then
        if !lookupManagement.loadFailureMessage.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "主檔首次載入失敗時未顯示錯誤文字")
        }
        XCTAssertTrue(lookupManagement.loadFailureMessage.exists, "應顯示主檔載入失敗文字")
    }
}
