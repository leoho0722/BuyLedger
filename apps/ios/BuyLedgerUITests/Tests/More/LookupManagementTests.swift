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

        // When
        let root = RootNavigationScreen(app: app)
        try requireCondition(root.goToOrders(), in: app, "切到訂單分頁後畫面未就緒")
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "訂單清單未出現")
        orders.tapAddOrder()
        let orderEdit = OrderEditScreen(app: app)
        try requireCondition(orderEdit.waitUntilReady(), in: app, "新增訂單編輯表單未出現")
        orderEdit.openCategoryPicker()

        // Then
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

    /// 驗證確認刪除「生活雜貨」商品類別後，清單不再出現該名稱，且列數變為 3
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
        try requireCondition(lookupManagement.waitForRowCount(3), in: app, "確認刪除後清單列數不為 3")
        XCTAssertEqual(lookupManagement.itemCountHeaderLabel, "目前已建立 3 項", "確認刪除後標題筆數應為 3")
    }

    /// 驗證刪除寫入失敗時，顯示「操作失敗」提示，關閉後清單仍保留「生活雜貨」且列數為 4
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

        // When
        app.tapAlertButton(label: "知道了")

        // Then
        if !failureAlert.waitForDisappearance(timeout: 5) {
            failWithDiagnostics(in: app, "關閉刪除失敗提示後 alert 未收回")
        }

        let retainedRow = lookupManagement.itemRow(named: "生活雜貨")
        XCTAssertTrue(retainedRow.waitForExistence(timeout: 5), "刪除寫入失敗後清單應保留「生活雜貨」")
        XCTAssertFalse(lookupManagement.loadFailureMessage.exists, "刪除寫入失敗後不應留下主檔載入錯誤文字")
        try requireCondition(lookupManagement.waitForRowCount(4), in: app, "刪除寫入失敗後清單列數不為 4")
        XCTAssertEqual(lookupManagement.itemCountHeaderLabel, "目前已建立 4 項", "刪除寫入失敗後標題筆數應為 4")
    }

    /// 驗證長按列開啟內容選單刪除且寫入失敗時，關閉提示後原列保留，列數與標題筆數不變
    ///
    /// - Throws: 內容選單刪除或確認流程未完成時丟出測試錯誤
    /// - Note: 內容選單的刪除鈕維持 destructive 角色
    func testRequestDeletion_長按選單刪除寫入失敗_項目保留且筆數不變() throws {
        // Given
        var options = LaunchOptions(seed: .lookupsOnly)
        options.shouldFailLookupWrites = true
        let app = launch(options)
        let lookupManagement = LookupManagementScreen(app: app)
        lookupManagement.openCategoryManagement()

        // When
        let isDeletionRequested = lookupManagement.requestDeletion(named: "生活雜貨", via: .contextMenu)

        // Then
        try requireCondition(isDeletionRequested, in: app, "未能經內容選單送出「生活雜貨」的刪除請求")
        // 刪除確認收回後才呈現失敗提示，等到提示的「知道了」出現再比對內容
        let failureAlert = app.alerts.firstMatch
        if !failureAlert.buttons["知道了"].waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "內容選單刪除寫入失敗後「操作失敗」alert 未出現")
            return
        }
        XCTAssertTrue(failureAlert.label.contains("操作失敗"), "應顯示「操作失敗」alert")

        // When
        app.tapAlertButton(label: "知道了")

        // Then
        if !failureAlert.waitForDisappearance(timeout: 5) {
            failWithDiagnostics(in: app, "關閉內容選單刪除失敗提示後 alert 未收回")
        }
        let retainedRow = lookupManagement.itemRow(named: "生活雜貨")
        XCTAssertTrue(retainedRow.waitForExistence(timeout: 5), "內容選單刪除寫入失敗後清單應保留「生活雜貨」")
        try requireCondition(lookupManagement.waitForRowCount(4), in: app, "內容選單刪除寫入失敗後清單列數不為 4")
        XCTAssertEqual(lookupManagement.itemCountHeaderLabel, "目前已建立 4 項", "內容選單刪除寫入失敗後標題筆數應為 4")
    }

    /// 驗證「操作失敗」提示關閉後，再次刪除「服飾」時仍會呈現刪除確認框，取消後清單保留「服飾」
    ///
    /// - Throws: 刪除確認、失敗提示或取消後的畫面未符合預期時丟出測試錯誤
    /// - Note: 失敗提示與刪除確認分開呈現，收回失敗提示後之後的刪除確認仍須可以開啟
    func testRequestDeletion_寫入失敗提示關閉後再刪除_重新呈現確認框() throws {
        // Given
        var options = LaunchOptions(seed: .lookupsOnly)
        options.shouldFailLookupWrites = true
        let app = launch(options)
        let lookupManagement = LookupManagementScreen(app: app)
        lookupManagement.openCategoryManagement()
        let failureAlert = app.alerts.firstMatch

        // When
        let isDeletionRequested = lookupManagement.requestDeletion(named: "生活雜貨")

        // Then
        try requireCondition(isDeletionRequested, in: app, "未能送出「生活雜貨」的刪除請求")
        // 刪除確認收回後才呈現失敗提示，等到提示的「知道了」出現再關閉
        if !failureAlert.buttons["知道了"].waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "刪除寫入失敗後「操作失敗」alert 未出現")
            return
        }

        // When
        app.tapAlertButton(label: "知道了")

        // Then
        if !failureAlert.waitForDisappearance(timeout: 5) {
            failWithDiagnostics(in: app, "關閉刪除失敗提示後 alert 未收回")
        }

        // When
        let isConfirmationShown = lookupManagement.beginDeletion(named: "服飾")

        // Then
        try requireCondition(isConfirmationShown, in: app, "關閉失敗提示後未能再次開啟「服飾」的刪除確認")
        let confirmationAlert = app.alerts.firstMatch
        try requireCondition(
            confirmationAlert.buttons["取消"].waitForExistence(timeout: 5),
            in: app,
            "關閉失敗提示後再刪除「服飾」，刪除確認缺少「取消」按鈕"
        )

        // When
        app.tapAlertButton(label: "取消")

        // Then
        if !confirmationAlert.waitForDisappearance(timeout: 5) {
            failWithDiagnostics(in: app, "取消再次刪除後確認對話框未收回")
        }
        XCTAssertTrue(
            lookupManagement.itemRow(named: "服飾").waitForExistence(timeout: 5),
            "取消再次刪除後清單應保留「服飾」"
        )
    }

    /// 驗證滑動刪除後在確認對話框按取消，列仍保留且列數不變，且沒有嘗試寫入
    ///
    /// - Throws: 刪除確認對話框未出現或列數不符時丟出測試錯誤
    /// - Note: 寫入失敗旗標開啟，若取消後仍嘗試寫入會出現「操作失敗」提示
    func testRequestDeletion_滑動刪除後取消_項目保留且筆數不變() throws {
        // Given
        var options = LaunchOptions(seed: .lookupsOnly)
        options.shouldFailLookupWrites = true
        let app = launch(options)
        let lookupManagement = LookupManagementScreen(app: app)
        lookupManagement.openCategoryManagement()
        let confirmationAlert = app.alerts.firstMatch

        // When
        let isConfirmationShown = lookupManagement.beginDeletion(named: "生活雜貨")

        // Then
        try requireCondition(isConfirmationShown, in: app, "未能開啟「生活雜貨」的刪除確認")

        // When
        app.tapAlertButton(label: "取消")

        // Then
        if !confirmationAlert.waitForDisappearance(timeout: 5) {
            failWithDiagnostics(in: app, "取消刪除後確認對話框未收回")
        }
        XCTAssertFalse(app.alerts.firstMatch.waitForExistence(timeout: 3), "取消刪除後不應出現操作失敗提示")
        XCTAssertTrue(
            lookupManagement.itemRow(named: "生活雜貨").waitForExistence(timeout: 5),
            "取消刪除後清單應保留「生活雜貨」"
        )
        try requireCondition(lookupManagement.waitForRowCount(4), in: app, "取消刪除後清單列數不為 4")
        XCTAssertEqual(lookupManagement.itemCountHeaderLabel, "目前已建立 4 項", "取消刪除後標題筆數應為 4")
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

        // When
        app.tapAlertButton(label: "知道了")

        // Then
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

    /// 驗證改名表單輸入後旋轉，再續輸入的草稿仍保留在同一欄，且旋轉前後只有一個 sheet
    ///
    /// - Throws: 改名表單未就緒、旋轉失敗或欄位失去焦點時丟出測試錯誤
    func testRenameForm_旋轉後續輸入_草稿保留且單層sheet() throws {
        // Given
        let app = launch(LaunchOptions(seed: .minimalOrders))
        let lookupManagement = LookupManagementScreen(app: app)
        lookupManagement.openCategoryManagement()
        lookupManagement.beginRename(from: "服飾")
        lookupManagement.replaceName("衣著")

        // When
        try rotateToLandscape(app)

        // Then
        try requireCondition(lookupManagement.isNameFieldFocused(), in: app, "旋轉後改名欄失去鍵盤焦點")

        // When
        lookupManagement.appendName("A")

        // Then
        let value = try requireValue(lookupManagement.nameFieldValue, in: app, "旋轉後改名欄元素不存在")
        XCTAssertEqual(value, "衣著A", "旋轉後續輸入應寫回改名欄的草稿")
        XCTAssertEqual(lookupManagement.presentedSheetCount, 1, "旋轉不應疊出第二層 sheet")
    }

    /// 驗證新增表單有未儲存內容時按取消會跳出捨棄確認，選擇繼續編輯後草稿保留
    ///
    /// - Throws: 新增表單或捨棄確認未就緒時丟出測試錯誤
    func testAddForm_未儲存取消_顯示捨棄確認且繼續編輯保留草稿() throws {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let lookupManagement = LookupManagementScreen(app: app)
        lookupManagement.openCategoryManagement()
        lookupManagement.beginAddItem()
        lookupManagement.replaceName("手作小物")

        // When
        lookupManagement.tapNameCancel()

        // Then
        try requireCondition(app.alertPresented(), in: app, "有未儲存內容時按取消未顯示捨棄確認")

        // When
        app.tapAlertButton(label: "繼續編輯")

        // Then
        XCTAssertEqual(lookupManagement.nameFieldValue, "手作小物", "選擇繼續編輯後草稿應保留")
        XCTAssertEqual(lookupManagement.presentedSheetCount, 1, "繼續編輯後新增表單應仍是唯一的 sheet")
    }

    /// 驗證新增表單有未儲存內容時確認捨棄，表單關閉且不新增任何項目
    ///
    /// - Throws: 新增表單或捨棄確認未就緒時丟出測試錯誤
    func testAddForm_確認捨棄_關閉表單不新增項目() throws {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        let lookupManagement = LookupManagementScreen(app: app)
        lookupManagement.openCategoryManagement()
        lookupManagement.beginAddItem()
        lookupManagement.replaceName("手作小物")
        lookupManagement.tapNameCancel()
        try requireCondition(
            app.alerts.firstMatch.waitForExistence(timeout: 10),
            in: app,
            "有未儲存內容時按取消未顯示捨棄確認"
        )
        try requireCondition(lookupManagement.presentedSheetCount == 1, in: app, "捨棄前名稱表單未呈現")

        // When
        app.tapAlertButton(label: "捨棄變更")

        // Then
        if !lookupManagement.nameEditorRoot.waitForNonExistence(timeout: 10) {
            failWithDiagnostics(in: app, "確認捨棄後新增表單未關閉")
        }
        XCTAssertFalse(lookupManagement.itemRow(named: "手作小物").exists, "捨棄後清單不應新增「手作小物」")
    }
}
