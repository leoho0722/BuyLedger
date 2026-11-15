//
//  LookupManagementUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/9/24.
//

import XCTest

/// 主檔管理頁的新增、改名、刪除與失敗流程 UI 測試
@MainActor
final class LookupManagementUITests: BLUITestCase {

    /// 驗證新增「手作小物」商品類別後，清單出現該名稱
    ///
    /// - Throws: 主檔管理頁未就緒或新增操作未完成時丟出測試錯誤
    func testSaveButtonTapped_新增商品類別_清單出現新名稱() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let lookupManagement = try LookupManagementScreen.open(.categories, in: app)

        // When
        try lookupManagement.addItem(named: "手作小物")

        // Then
        let newRow = lookupManagement.itemRow(named: "手作小物")
        if !newRow.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "新增商品類別後清單未出現「手作小物」")
        }
    }

    /// 驗證商品類別「服飾」改名為「衣著」後，管理清單只顯示「衣著」，不再有「服飾」
    ///
    /// - Throws: 改名前的商品類別列不存在時丟出測試錯誤
    func testSaveButtonTapped_商品類別改名_管理清單只顯示新名稱() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .minimalOrders))
        let lookupManagement = try LookupManagementScreen.open(.categories, in: app)
        try requireCondition(
            lookupManagement.itemRow(named: "服飾").waitForExistence(timeout: 10),
            in: app,
            "改名前商品類別清單沒有「服飾」"
        )

        // When
        try lookupManagement.renameItem(from: "服飾", to: "衣著")

        // Then
        let renamedRow = lookupManagement.itemRow(named: "衣著")
        if !renamedRow.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "改名後商品類別清單未出現「衣著」")
        }
        XCTAssertFalse(lookupManagement.itemRow(named: "服飾").exists, "舊名稱不應留在清單")
    }

    /// 驗證確認刪除「生活雜貨」商品類別後，清單不再出現該名稱，且列數變為 3
    ///
    /// - Throws: 刪除前的商品類別列不存在時丟出測試錯誤
    func testConfirmDelete_確認刪除商品類別_清單移除該名稱() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let lookupManagement = try LookupManagementScreen.open(.categories, in: app)
        let deletedRow = lookupManagement.itemRow(named: "生活雜貨")
        try requireCondition(deletedRow.waitForExistence(timeout: 10), in: app, "刪除前商品類別清單沒有「生活雜貨」")

        // When
        try lookupManagement.deleteItem(named: "生活雜貨")

        // Then
        if !deletedRow.waitForDisappearance(timeout: 10) {
            failWithDiagnostics(in: app, "確認刪除後商品類別仍留在清單")
        }
        try requireCondition(lookupManagement.waitForRowCount(3), in: app, "確認刪除後清單列數不為 3")
        XCTAssertEqual(lookupManagement.itemCountHeaderLabel, "目前已建立 3 項", "確認刪除後標題筆數應為 3")
    }

    /// 驗證刪除寫入失敗時，顯示「操作失敗」提示
    ///
    /// - Throws: 刪除確認流程未完成時丟出測試錯誤
    /// - Note: 失敗提示在刪除確認收回後才呈現，因此等提示出現後再比對內容
    func testConfirmDelete_刪除寫入失敗_顯示操作失敗提示() throws {
        // Given
        var options = LaunchOptions(seed: .lookupsOnly)
        options.shouldFailLookupWrites = true
        options.shouldKeepViewAnimations = true
        let app = try launch(options)
        let lookupManagement = try LookupManagementScreen.open(.categories, in: app)

        // When
        try lookupManagement.requestDeletion(named: "生活雜貨")

        // Then
        try app.assertAlertMessage(contains: "操作失敗", timeout: 10)
    }

    /// 驗證刪除寫入失敗的提示按知道了後，原列保留且列數與標題筆數不變
    ///
    /// - Throws: 刪除失敗提示未呈現時丟出測試錯誤
    /// - Note: 關閉同次刪除失敗的提示後讀回清單，確認未成功的刪除沒有移除原項目
    func testTapAlertButton_刪除失敗提示按知道了_保留項目且筆數不變() throws {
        // Given
        var options = LaunchOptions(seed: .lookupsOnly)
        options.shouldFailLookupWrites = true
        options.shouldKeepViewAnimations = true
        let app = try launch(options)
        let lookupManagement = try LookupManagementScreen.open(.categories, in: app)
        try lookupManagement.requestDeletion(named: "生活雜貨")
        try app.assertAlertMessage(contains: "操作失敗", timeout: 10)

        // When
        try app.tapAlertButton(label: "知道了")

        // Then
        if !app.alertDismissed() {
            failWithDiagnostics(in: app, "關閉刪除失敗提示後 alert 未收回")
        }
        let retainedRow = lookupManagement.itemRow(named: "生活雜貨")
        XCTAssertTrue(retainedRow.waitForExistence(timeout: 5), "刪除寫入失敗後清單應保留「生活雜貨」")
        XCTAssertFalse(lookupManagement.loadFailureMessage.exists, "刪除寫入失敗後不應留下主檔載入錯誤文字")
        try requireCondition(lookupManagement.waitForRowCount(4), in: app, "刪除寫入失敗後清單列數不為 4")
        XCTAssertEqual(lookupManagement.itemCountHeaderLabel, "目前已建立 4 項", "刪除寫入失敗後標題筆數應為 4")
    }

    /// 驗證長按列開啟內容選單刪除且寫入失敗時，顯示「操作失敗」提示
    ///
    /// - Throws: 內容選單刪除或確認流程未完成時丟出測試錯誤
    /// - Note: 內容選單的刪除鈕維持 destructive 角色，失敗提示在刪除確認收回後才呈現
    func testConfirmDelete_長按選單刪除寫入失敗_顯示操作失敗提示() throws {
        // Given
        var options = LaunchOptions(seed: .lookupsOnly)
        options.shouldFailLookupWrites = true
        options.shouldKeepViewAnimations = true
        let app = try launch(options)
        let lookupManagement = try LookupManagementScreen.open(.categories, in: app)

        // When
        try lookupManagement.requestDeletion(named: "生活雜貨", via: .contextMenu)

        // Then
        try app.assertAlertMessage(contains: "操作失敗", timeout: 10)
    }

    /// 驗證內容選單刪除寫入失敗的提示按知道了後，原列保留且列數與標題筆數不變
    ///
    /// - Throws: 內容選單刪除失敗提示未呈現時丟出測試錯誤
    func testTapAlertButton_長按選單刪除失敗提示按知道了_保留項目且筆數不變() throws {
        // Given
        var options = LaunchOptions(seed: .lookupsOnly)
        options.shouldFailLookupWrites = true
        options.shouldKeepViewAnimations = true
        let app = try launch(options)
        let lookupManagement = try LookupManagementScreen.open(.categories, in: app)
        try lookupManagement.requestDeletion(named: "生活雜貨", via: .contextMenu)
        try app.assertAlertMessage(contains: "操作失敗", timeout: 10)

        // When
        try app.tapAlertButton(label: "知道了")

        // Then
        if !app.alertDismissed() {
            failWithDiagnostics(in: app, "關閉內容選單刪除失敗提示後 alert 未收回")
        }
        let retainedRow = lookupManagement.itemRow(named: "生活雜貨")
        XCTAssertTrue(retainedRow.waitForExistence(timeout: 5), "內容選單刪除寫入失敗後清單應保留「生活雜貨」")
        try requireCondition(lookupManagement.waitForRowCount(4), in: app, "內容選單刪除寫入失敗後清單列數不為 4")
        XCTAssertEqual(lookupManagement.itemCountHeaderLabel, "目前已建立 4 項", "內容選單刪除寫入失敗後標題筆數應為 4")
    }

    /// 驗證「操作失敗」提示關閉後，再次刪除「服飾」時仍會呈現刪除確認框
    ///
    /// - Throws: 失敗提示未呈現，或刪除確認框未重新呈現時丟出測試錯誤
    /// - Note: 失敗提示與刪除確認分開呈現，收回失敗提示後之後的刪除確認仍須可以開啟
    func testDeleteButtonTapped_刪除失敗提示關閉後再刪除_重新呈現確認框() throws {
        // Given
        var options = LaunchOptions(seed: .lookupsOnly)
        options.shouldFailLookupWrites = true
        options.shouldKeepViewAnimations = true
        let app = try launch(options)
        let lookupManagement = try LookupManagementScreen.open(.categories, in: app)
        try lookupManagement.requestDeletion(named: "生活雜貨")
        try app.assertAlertMessage(contains: "操作失敗", timeout: 10)
        try app.tapAlertButton(label: "知道了")
        try requireCondition(app.alertDismissed(), in: app, "關閉刪除失敗提示後 alert 未收回")

        // When
        try lookupManagement.beginDeletion(named: "服飾")

        // Then
        try requireCondition(app.alertPresented(), in: app, "關閉失敗提示後再刪除「服飾」，刪除確認框未呈現")
    }

    /// 驗證滑動刪除後在確認對話框按取消，列仍保留且列數不變，且沒有嘗試寫入
    ///
    /// - Throws: 刪除確認對話框未出現或列數不符時丟出測試錯誤
    /// - Note: 寫入失敗旗標開啟，若取消後仍嘗試寫入會出現「操作失敗」提示
    func testTapAlertButton_刪除確認按取消_項目保留且筆數不變() throws {
        // Given
        var options = LaunchOptions(seed: .lookupsOnly)
        options.shouldFailLookupWrites = true
        let app = try launch(options)
        let lookupManagement = try LookupManagementScreen.open(.categories, in: app)
        try lookupManagement.beginDeletion(named: "生活雜貨")
        try requireCondition(app.alertPresented(), in: app, "滑動刪除後未出現刪除確認對話框")

        // When
        try app.tapAlertButton(label: "取消")

        // Then
        if !app.alertDismissed() {
            failWithDiagnostics(in: app, "取消刪除後確認對話框未收回")
        }
        XCTAssertFalse(app.alertPresented(timeout: 3), "取消刪除後不應出現操作失敗提示")
        XCTAssertTrue(
            lookupManagement.itemRow(named: "生活雜貨").waitForExistence(timeout: 5),
            "取消刪除後清單應保留「生活雜貨」"
        )
        try requireCondition(lookupManagement.waitForRowCount(4), in: app, "取消刪除後清單列數不為 4")
        XCTAssertEqual(lookupManagement.itemCountHeaderLabel, "目前已建立 4 項", "取消刪除後標題筆數應為 4")
    }

    /// 驗證新增「失敗類別」的寫入失敗時，顯示「操作失敗」提示
    ///
    /// - Throws: 新增流程未完成時丟出測試錯誤
    /// - Note: 失敗提示由寫入失敗的回應觸發，關閉後的清單內容由下一個測試驗證
    func testSaveButtonTapped_新增寫入失敗_顯示操作失敗提示() throws {
        // Given
        var options = LaunchOptions(seed: .lookupsOnly)
        options.shouldFailLookupWrites = true
        options.shouldKeepViewAnimations = true
        let app = try launch(options)
        let lookupManagement = try LookupManagementScreen.open(.categories, in: app)

        // When
        try lookupManagement.addItem(named: "失敗類別")

        // Then
        try app.assertAlertMessage(contains: "操作失敗", timeout: 10)
    }

    /// 驗證新增寫入失敗的提示按知道了後，清單不出現「失敗類別」，且不留下載入錯誤文字
    ///
    /// - Throws: 新增失敗提示未呈現時丟出測試錯誤
    /// - Note: 關閉同次新增失敗的提示後讀回清單，確認失敗項目沒有被加入
    func testTapAlertButton_新增失敗提示按知道了_清單不出現新名稱() throws {
        // Given
        var options = LaunchOptions(seed: .lookupsOnly)
        options.shouldFailLookupWrites = true
        options.shouldKeepViewAnimations = true
        let app = try launch(options)
        let lookupManagement = try LookupManagementScreen.open(.categories, in: app)
        try lookupManagement.addItem(named: "失敗類別")
        try app.assertAlertMessage(contains: "操作失敗", timeout: 10)

        // When
        try app.tapAlertButton(label: "知道了")

        // Then
        if !app.alertDismissed() {
            failWithDiagnostics(in: app, "關閉寫入失敗提示後 alert 未收回")
        }
        XCTAssertFalse(lookupManagement.itemRow(named: "失敗類別").exists, "寫入失敗後清單不應出現「失敗類別」")
        XCTAssertFalse(lookupManagement.loadFailureMessage.exists, "寫入失敗後不應留下主檔載入錯誤文字")
    }

    /// 驗證進入類別管理頁時主檔首次載入失敗，頁面顯示載入錯誤文字
    ///
    /// - Throws: App 啟動或主檔管理頁未就緒時丟出測試錯誤
    func testTask_首次載入失敗_顯示載入錯誤文字() throws {
        // Given
        let options = LaunchOptions(seed: .lookupsOnly, loadFailure: .lookups)
        let app = try launch(options)

        // When
        let lookupManagement = try LookupManagementScreen.open(.categories, in: app)

        // Then
        if !lookupManagement.loadFailureMessage.waitForExistence(timeout: 10) {
            failWithDiagnostics(in: app, "主檔首次載入失敗時未顯示錯誤文字")
        }
    }

    /// 驗證改名表單輸入後旋轉，再續輸入的草稿仍保留在同一欄，且旋轉前後只有一個 sheet
    ///
    /// - Throws: 改名表單未就緒、旋轉失敗或欄位失去焦點時丟出測試錯誤
    func testDraftName_改名表單轉向後續輸入_草稿保留且單層sheet() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .minimalOrders))
        let lookupManagement = try LookupManagementScreen.open(.categories, in: app)
        try lookupManagement.beginRename(from: "服飾")
        try lookupManagement.replaceName("衣著")

        // When
        try rotateToLandscape(app)

        // Then
        try requireCondition(lookupManagement.isNameFieldFocused(), in: app, "旋轉後改名欄失去鍵盤焦點")

        // When
        try lookupManagement.appendName("A")

        // Then
        let value = try requireValue(lookupManagement.nameFieldValue(), in: app, "旋轉後改名欄元素不存在")
        XCTAssertEqual(value, "衣著A", "旋轉後續輸入應寫回改名欄的草稿")
        XCTAssertEqual(lookupManagement.presentedSheetCount, 1, "旋轉不應疊出第二層 sheet")
    }

    /// 驗證新增表單有未儲存內容時按取消，顯示捨棄確認
    ///
    /// - Throws: 新增表單未就緒或捨棄確認未出現時丟出測試錯誤
    func testCancelButtonTapped_新增表單有未儲存內容_顯示捨棄確認() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let lookupManagement = try LookupManagementScreen.open(.categories, in: app)
        try lookupManagement.beginAddItem()
        try lookupManagement.replaceName("手作小物")

        // When
        try lookupManagement.tapNameCancel()

        // Then
        try requireCondition(app.alertPresented(), in: app, "有未儲存內容時按取消未顯示捨棄確認")
    }

    /// 驗證新增表單有未儲存內容時，捨棄確認選繼續編輯後草稿保留且仍為單層 sheet
    ///
    /// - Throws: 新增表單或捨棄確認未就緒時丟出測試錯誤
    func testTapAlertButton_捨棄確認選繼續編輯_保留草稿且單層sheet() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let lookupManagement = try LookupManagementScreen.open(.categories, in: app)
        try lookupManagement.beginAddItem()
        try lookupManagement.replaceName("手作小物")
        try lookupManagement.tapNameCancel()
        try requireCondition(app.alertPresented(), in: app, "有未儲存內容時按取消未顯示捨棄確認")

        // When
        try app.tapAlertButton(BLAccessibilityID.LookupManagement.discardAlertKeepEditingButton)

        // Then
        XCTAssertEqual(lookupManagement.nameFieldValue(), "手作小物", "選擇繼續編輯後草稿應保留")
        XCTAssertEqual(lookupManagement.presentedSheetCount, 1, "繼續編輯後新增表單應仍是唯一的 sheet")
    }

    /// 驗證新增表單有未儲存內容時確認捨棄，表單關閉且不新增任何項目
    ///
    /// - Throws: 新增表單或捨棄確認未就緒時丟出測試錯誤
    func testDiscardChangesButtonTapped_確認捨棄_關閉表單不新增項目() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let lookupManagement = try LookupManagementScreen.open(.categories, in: app)
        try lookupManagement.beginAddItem()
        try lookupManagement.replaceName("手作小物")
        try lookupManagement.tapNameCancel()
        try requireCondition(app.alertPresented(timeout: 10), in: app, "有未儲存內容時按取消未顯示捨棄確認")
        try requireCondition(lookupManagement.presentedSheetCount == 1, in: app, "捨棄前名稱表單未呈現")

        // When
        try app.tapAlertButton(BLAccessibilityID.LookupManagement.discardAlertDiscardButton)

        // Then
        if !lookupManagement.nameEditorRoot.waitForNonExistence(timeout: 10) {
            failWithDiagnostics(in: app, "確認捨棄後新增表單未關閉")
        }
        XCTAssertFalse(lookupManagement.itemRow(named: "手作小物").exists, "捨棄後清單不應新增「手作小物」")
    }
}
