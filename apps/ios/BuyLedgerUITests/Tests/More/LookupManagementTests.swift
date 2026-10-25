//
//  LookupManagementTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/9/24.
//

import XCTest

/// 主檔管理頁的新增、改名、刪除與失敗流程 UI 測試
@MainActor
final class LookupManagementTests: BLUITestCase {

    /// 驗證新增「手作小物」商品類別後，清單出現該名稱
    func testAddItem_新增商品類別_清單出現新名稱() {
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
    }

    /// 驗證商品類別「服飾」改名為「衣著」後，管理清單只顯示「衣著」，不再有「服飾」
    ///
    /// - Throws: 改名前的商品類別列不存在時丟出測試錯誤
    func testRenameItem_商品類別改名_管理清單只顯示新名稱() throws {
        // Given
        let app = launch(LaunchOptions(seed: .minimalOrders))
        let lookupManagement = LookupManagementScreen(app: app)
        lookupManagement.openCategoryManagement()
        try requireCondition(
            lookupManagement.itemRow(named: "服飾").waitForExistence(timeout: 10),
            in: app,
            "改名前商品類別清單沒有「服飾」"
        )

        // When
        lookupManagement.renameItem(from: "服飾", to: "衣著")

        // Then
        let renamedRow = lookupManagement.itemRow(named: "衣著")
        if !renamedRow.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "改名後商品類別清單未出現「衣著」")
        }
        XCTAssertFalse(lookupManagement.itemRow(named: "服飾").exists, "舊名稱不應留在清單")
    }

    /// 驗證商品類別「服飾」改名為「衣著」後，新增訂單的類別選擇器只列出「衣著」，不含「服飾」
    ///
    /// - Throws: 改名未完成，或訂單分頁、新增訂單表單、類別選擇器未就緒時丟出測試錯誤
    /// - Note: 同次改名的結果須在新增訂單選擇器中讀回，後續導覽用來確認名稱已同步且舊名未殘留
    func testRenameItem_商品類別改名_新訂單選擇器只顯示新名稱() throws {
        // Given
        let app = launch(LaunchOptions(seed: .minimalOrders))
        let lookupManagement = LookupManagementScreen(app: app)
        lookupManagement.openCategoryManagement()

        // When
        lookupManagement.renameItem(from: "服飾", to: "衣著")

        // Then
        try requireCondition(
            lookupManagement.itemRow(named: "衣著").waitForExistence(timeout: 10),
            in: app,
            "改名後商品類別清單未出現「衣著」"
        )
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToOrders(), in: app, "切到訂單分頁後畫面未就緒")
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "訂單清單未出現")
        orders.tapAddOrder()
        let orderEdit = OrderEditScreen(app: app)
        try requireCondition(orderEdit.waitUntilReady(), in: app, "新增訂單編輯表單未出現")
        orderEdit.openCategoryPicker()
        let pickerRoot = app.descendants(matching: .any)[BLAccessibilityID.OptionPicker.root]
        try requireCondition(pickerRoot.waitForExistence(timeout: 10), in: app, "新訂單類別選擇器未出現")
        let newOption = app.descendants(matching: .any)[
            BLAccessibilityID.OptionPicker.optionRow("衣著")
        ]
        if !newOption.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "新訂單類別選擇器未出現「衣著」")
        }
        let oldOption = app.descendants(matching: .any)[
            BLAccessibilityID.OptionPicker.optionRow("服飾")
        ]
        XCTAssertFalse(oldOption.exists, "新訂單類別選擇器不應包含舊名稱「服飾」")
    }

    /// 驗證確認刪除「生活雜貨」商品類別後，清單不再出現該名稱
    ///
    /// - Throws: 刪除前的商品類別列不存在時丟出測試錯誤
    func testDeleteItem_確認刪除商品類別_清單移除該名稱() throws {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let lookupManagement = LookupManagementScreen(app: app)
        lookupManagement.openCategoryManagement()
        let deletedRow = lookupManagement.itemRow(named: "生活雜貨")
        try requireCondition(deletedRow.waitForExistence(timeout: 10), in: app, "刪除前商品類別清單沒有「生活雜貨」")

        // When
        lookupManagement.deleteItem(named: "生活雜貨")

        // Then
        if !deletedRow.waitForDisappearance(timeout: 10) {
            failWithDiagnostics(in: app, "確認刪除後商品類別仍留在清單")
        }
    }

    /// 驗證刪除寫入失敗時，顯示「操作失敗」提示，關閉後清單仍保留「生活雜貨」
    ///
    /// - Throws: 刪除確認流程未完成時丟出測試錯誤
    /// - Note: 關閉同次刪除失敗的提示後讀回清單，確認未成功的刪除沒有移除原項目
    func testRequestDeletion_刪除寫入失敗_顯示提示並保留項目() throws {
        // Given
        var options = LaunchOptions(seed: .lookupsOnly)
        options.shouldFailLookupWrites = true
        let app = launch(options)
        let lookupManagement = LookupManagementScreen(app: app)
        lookupManagement.openCategoryManagement()

        // When
        let isDeletionRequested = lookupManagement.requestDeletion(named: "生活雜貨")

        // Then
        try requireCondition(isDeletionRequested, in: app, "未能送出「生活雜貨」的刪除請求")
        // 刪除確認收回後才呈現失敗提示，等到提示的「知道了」出現再比對內容
        let failureAlert = app.alerts.firstMatch
        if !failureAlert.buttons["知道了"].waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "刪除寫入失敗後「操作失敗」alert 未出現")
            return
        }
        XCTAssertTrue(failureAlert.label.contains("操作失敗"), "應顯示「操作失敗」alert")
        app.tapAlertButton(label: "知道了")
        if !failureAlert.waitForDisappearance(timeout: 5) {
            failWithDiagnostics(in: app, "關閉刪除失敗提示後 alert 未收回")
        }

        XCTAssertTrue(lookupManagement.itemRow(named: "生活雜貨").exists, "刪除寫入失敗後清單應保留「生活雜貨」")
        XCTAssertFalse(lookupManagement.loadFailureMessage.exists, "刪除寫入失敗後不應留下主檔載入錯誤文字")
    }

    /// 驗證新增「失敗類別」的寫入失敗時，顯示「操作失敗」提示，清單不出現該名稱
    ///
    /// - Note: 關閉同次新增失敗的提示後讀回清單，確認失敗項目沒有被加入
    func testAddItem_新增寫入失敗_顯示提示且清單不出現新名稱() {
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

        XCTAssertFalse(lookupManagement.itemRow(named: "失敗類別").exists, "寫入失敗後清單不應出現「失敗類別」")
        XCTAssertFalse(lookupManagement.loadFailureMessage.exists, "寫入失敗後不應留下主檔載入錯誤文字")
    }

    /// 驗證主檔首次載入失敗時，類別管理頁顯示載入錯誤文字
    func testOpenCategoryManagement_首次載入失敗_顯示載入錯誤文字() {
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
    }
}
