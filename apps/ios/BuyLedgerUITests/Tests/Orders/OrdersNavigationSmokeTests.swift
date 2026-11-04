//
//  OrdersNavigationSmokeTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/27.
//

import XCTest

/// 訂單分欄、原生選取、返回與單一表單 sheet 的 UI 驗收
@MainActor
final class OrdersNavigationSmokeTests: BLUITestCase {

    /// 驗證選取 Mika 周的 BL-2604-017 後營收為 $4,980，原生返回清空 path
    ///
    /// - Throws: 訂單清單、詳情或原生返回按鈕不符合預期時丟出測試錯誤
    func testOrders_選取訂單詳情與原生返回_Mika周017營收4980且path清空() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        try requireCondition(navigator.tapRootTab(.orders), in: app, "點選原生訂單分頁失敗")
        let ordersScreen = OrdersScreen(app: app)
        try requireCondition(ordersScreen.waitUntilReady(), in: app, "訂單清單根未就緒")

        let orderRow017 = ordersScreen.orderRow(orderID: "BL-2604-017")
        try requireCondition(
            orderRow017.waitForExistence(timeout: 10),
            in: app,
            "找不到訂單 BL-2604-017 的清單列"
        )
        try XCTSkipUnless(isCompactLayout(app), "原生 Back 案例只適用 Orders collapsed 導覽")

        // When
        ordersScreen.tapOrder(orderID: "BL-2604-017")

        // Then
        let detailScreen = OrderDetailScreen(app: app)
        try requireCondition(detailScreen.waitUntilReady(), in: app, "點選訂單後詳情根未就緒")
        let detailMoreButton = app.buttons[BLAccessibilityID.Orders.detailMoreButton].firstMatch
        try requireCondition(
            detailMoreButton.waitUntilHittable(timeout: 10),
            in: app,
            "詳情更多操作按鈕未進入可互動狀態"
        )

        let detailRootID = BLAccessibilityID.Orders.detailRoot
        let detailRoot = app.descendants(matching: .any)[detailRootID].firstMatch
        let detailLabels = detailRoot.staticTexts.allElementsBoundByIndex.map(\.label)
        try requireCondition(
            detailLabels.contains("BL-2604-017"),
            in: app,
            "訂單詳情內容中未包含編號 BL-2604-017 (可見標籤：\(detailLabels))"
        )

        let detailNavBar = app.navigationBars.containing(
            .button,
            identifier: BLAccessibilityID.Orders.detailMoreButton
        )
            .firstMatch
        let navLabels = detailNavBar.staticTexts.allElementsBoundByIndex.map(\.label)
        try requireCondition(
            detailNavBar.identifier == "Mika 周" || navLabels.contains("Mika 周"),
            in: app,
            "訂單詳情導覽列未顯示真實客戶 Mika 周 (title=\(detailNavBar.identifier))"
        )

        let revenue = try requireValue(detailScreen.summaryValue(.revenue), in: app, "訂單營收摘要卡不存在")
        try requireCondition(revenue == "$4,980", in: app, "訂單營收摘要「\(revenue)」非預期的 $4,980")

        // When
        try app.tapUniqueNativeBackButton()

        // Then
        try requireCondition(detailRoot.waitForDisappearance(timeout: 5), in: app, "原生返回後訂單詳情未退出")
        try requireCondition(ordersScreen.waitUntilReady(), in: app, "原生返回後訂單清單未就緒")
        try requireCondition(
            ordersScreen.hasOrder(orderID: "BL-2604-017"),
            in: app,
            "原生返回後訂單清單中未找到 BL-2604-017"
        )
        let selectedOrderID = try requireValue(
            ordersScreen.pathProjectedOrderID,
            in: app,
            "原生返回後 Orders path 識別標記不存在"
        )
        try requireCondition(
            selectedOrderID.isEmpty,
            in: app,
            "原生 Back 後 path 選取應為空，實際為 \(selectedOrderID)"
        )
    }

    /// 驗證選取訂單後 path 與詳情顯示同一筆資料
    ///
    /// - Throws: 訂單清單、path 標記或詳情狀態不符時丟出測試錯誤
    /// - Note: 首次未選取的斷言由 `AdaptiveNavigationContinuityUITests` 負責
    func testOrders_選取訂單後_path與詳情同步() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        try requireCondition(navigator.tapRootTab(.orders), in: app, "切到訂單分頁失敗")
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "訂單清單根未就緒")
        try assertOrdersLayoutIsRecognized(in: app)

        // When
        orders.tapOrder(orderID: "BL-2604-017")

        // Then
        let selectedOrderID = try requireValue(
            orders.pathProjectedOrderID,
            in: app,
            "選取訂單後 Orders path 標記不存在"
        )
        try requireCondition(
            selectedOrderID == "BL-2604-017",
            in: app,
            "Orders path 應投影 BL-2604-017，實際為 \(selectedOrderID)"
        )
        try requireCondition(OrderDetailScreen(app: app).waitUntilReady(), in: app, "選取訂單後詳情根未就緒")
    }

    /// 驗證 regular 清單改選 Joyce 訂單後，path、詳情識別值與更多操作維持同步
    ///
    /// - Throws: 清單、path 或詳情不符合預期時丟出測試錯誤
    func testOrders_改選另一筆訂單_path與詳情同步() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        try requireCondition(navigator.tapRootTab(.orders), in: app, "切到訂單分頁失敗")
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "訂單清單根未就緒")

        orders.tapOrder(orderID: "BL-2604-017")
        let detail = OrderDetailScreen(app: app)
        try requireCondition(detail.waitUntilReady(), in: app, "Mika 訂單詳情未就緒")
        try XCTSkipUnless(isRegularLayout(app), "改選第二筆訂單需 Orders 清單與詳情並排")

        // When
        orders.tapOrder(orderID: "BL-2604-015")

        // Then
        let selectedOrderID = try requireValue(
            orders.pathProjectedOrderID,
            in: app,
            "替換選取後 Orders path 標記不存在"
        )
        try requireCondition(
            selectedOrderID == "BL-2604-015",
            in: app,
            "替換後 Orders path 應為 BL-2604-015，實際為 \(selectedOrderID)"
        )
        try requireCondition(detail.waitUntilReady(), in: app, "Joyce 訂單詳情未就緒")
        let moreButton = app.buttons[BLAccessibilityID.Orders.detailMoreButton].firstMatch
        try requireCondition(moreButton.waitUntilHittable(timeout: 10), in: app, "替換訂單後詳情更多操作不可互動")
        let detailRoot = app.descendants(matching: .any)[BLAccessibilityID.Orders.detailRoot]
        let detailLabels = detailRoot.staticTexts.allElementsBoundByIndex.map(\.label)
        try requireCondition(detailLabels.contains("BL-2604-015"), in: app, "詳情內容未顯示 BL-2604-015")
    }

    /// 驗證搜尋排除目前詳情後清空 path，結果回來時不自動選取首筆
    ///
    /// - Throws: 搜尋、path 或無選取詳情提示不符合預期時丟出測試錯誤
    func testOrders_搜尋排除詳情後清除path_恢復結果不自動選取() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        try requireCondition(navigator.tapRootTab(.orders), in: app, "切到訂單分頁失敗")
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "訂單清單根未就緒")
        orders.tapOrder(orderID: "BL-2604-017")
        try requireCondition(OrderDetailScreen(app: app).waitUntilReady(), in: app, "搜尋前訂單詳情未就緒")
        try XCTSkipUnless(isRegularLayout(app), "同步搜尋與詳情需 Orders 欄位並排")

        // When
        try orders.search("Mika")
        try orders.search("ZZZ-NO-SUCH-ORDER")

        // Then
        let emptySelection = try requireValue(
            orders.pathProjectedOrderID,
            in: app,
            "搜尋排除詳情後 Orders path 標記不存在"
        )
        try requireCondition(emptySelection.isEmpty, in: app, "搜尋排除詳情後 path 應清空")
        let listEmptyState = app.descendants(matching: .any)[
            BLAccessibilityID.Orders.listEmptyState
        ].firstMatch
        try requireCondition(
            listEmptyState.waitForExistence(timeout: 10),
            in: app,
            "無符合搜尋結果時清單未顯示空狀態"
        )
        let detailPrompt = app.descendants(matching: .any)[
            BLAccessibilityID.Orders.detailEmptyState
        ].firstMatch
        try requireCondition(
            detailPrompt.waitForExistence(timeout: 10) && detailPrompt.snapshotFrame != nil,
            in: app,
            "搜尋排除詳情後未顯示無選取提示"
        )

        // When
        try orders.search("Mika")

        // Then
        let restoredSelection = try requireValue(
            orders.pathProjectedOrderID,
            in: app,
            "搜尋恢復後 Orders path 標記不存在"
        )
        try requireCondition(restoredSelection.isEmpty, in: app, "搜尋恢復結果後不應自動選取首筆訂單")
        try requireCondition(orders.hasOrder(orderID: "BL-2604-017"), in: app, "搜尋結果未恢復")
    }

    /// 驗證清除排除詳情的類別篩選後，path 仍不會自動選取首筆訂單
    ///
    /// - Throws: 篩選、清除或 path 不符合預期時丟出測試錯誤
    func testOrders_清除排除詳情的類別篩選_不自動選取訂單() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        try requireCondition(navigator.tapRootTab(.orders), in: app, "切到訂單分頁失敗")
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "訂單清單根未就緒")
        orders.tapOrder(orderID: "BL-2604-017")
        try requireCondition(OrderDetailScreen(app: app).waitUntilReady(), in: app, "套用類別篩選前詳情未就緒")
        try XCTSkipUnless(isRegularLayout(app), "類別篩選案例需 Orders regular 清單欄")

        // When
        let picker = OrderCategoryPickerScreen(app: app)
        orders.openCategoryPicker()
        picker.tapPickerCategory("美妝")
        picker.tapPickerDone()

        // Then
        let filteredSelection = try requireValue(
            orders.pathProjectedOrderID,
            in: app,
            "類別篩選排除詳情後 Orders path 標記不存在"
        )
        try requireCondition(filteredSelection.isEmpty, in: app, "排除詳情的類別篩選應清空 path")

        // When
        orders.tapRegularClearFilters()

        // Then
        try requireCondition(
            orders.hasOrder(orderID: "BL-2604-017"),
            in: app,
            "清除篩選後 Mika 訂單應重新出現在清單"
        )
        let clearedSelection = try requireValue(
            orders.pathProjectedOrderID,
            in: app,
            "清除篩選後 Orders path 標記不存在"
        )
        try requireCondition(clearedSelection.isEmpty, in: app, "清除篩選後不應自動選取訂單")
    }

    /// 驗證編輯草稿、焦點與單一表單 sheet 在方向改變後保留
    ///
    /// - Throws: 表單、草稿、鍵盤或 Orders path 不符合預期時丟出測試錯誤
    func testOrders_編輯草稿與焦點_方向改變後保留單一Sheet() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        try requireCondition(navigator.tapRootTab(.orders), in: app, "切到訂單分頁失敗")
        let orders = OrdersScreen(app: app)
        try requireCondition(orders.waitUntilReady(), in: app, "訂單清單根未就緒")
        orders.tapOrder(orderID: "BL-2604-017")
        let detail = OrderDetailScreen(app: app)
        try requireCondition(detail.waitUntilReady(), in: app, "訂單詳情未就緒")
        detail.openMoreMenu()
        try requireCondition(detail.tapEdit(), in: app, "詳情更多選單未能開啟編輯表單")
        let edit = OrderEditScreen(app: app)
        try requireCondition(edit.waitUntilReady(), in: app, "編輯表單根未就緒")
        edit.typeCustomerName("DuoDraft")
        let customerField = app.textFields[BLAccessibilityID.OrderEdit.customerField].firstMatch
        let keyboard = app.keyboards.firstMatch
        try requireCondition(keyboard.waitForExistence(timeout: 10), in: app, "客戶欄位鍵盤未出現")
        try requireCondition(customerField.value as? String == "DuoDraft", in: app, "編輯草稿初始值非預期")

        // When
        try rotateToLandscape(app)

        // Then
        try assertSingleEditSheet(
            edit,
            customerField: customerField,
            expectedDraft: "DuoDraft",
            in: app
        )
        try requireCondition(keyboard.waitForExistence(timeout: 10), in: app, "轉向後編輯表單鍵盤未保留")

        // When
        customerField.typeText("X")

        // Then
        try requireCondition(
            customerField.value as? String == "DuoDraftX",
            in: app,
            "轉向後客戶欄位未保留焦點並接續輸入"
        )

        // When
        try rotateToPortrait(app)

        // Then
        try assertSingleEditSheet(
            edit,
            customerField: customerField,
            expectedDraft: "DuoDraftX",
            in: app
        )
        try requireCondition(keyboard.waitForExistence(timeout: 10), in: app, "轉回直向後編輯表單鍵盤未保留")
        let selectedOrderID = try requireValue(
            orders.pathProjectedOrderID,
            in: app,
            "方向改變後 Orders path 標記不存在"
        )
        try requireCondition(selectedOrderID == "BL-2604-017", in: app, "方向改變後 Orders path 選取不應改變")

        // When
        edit.tapCancel()

        // Then
        try requireCondition(
            app.alerts.firstMatch.waitForExistence(timeout: 10),
            in: app,
            "取消修改草稿後未顯示既有捨棄確認"
        )
    }

    /// 驗證從訂單詳情開啟單一編輯 sheet，取消後返回同筆訂單詳情
    ///
    /// - Throws: 訂單詳情、編輯表單或取消動作不符合預期時丟出測試錯誤
    func testOrders_編輯訂單取消_返回同筆詳情() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        try requireCondition(navigator.tapRootTab(.orders), in: app, "點選原生訂單分頁失敗")
        let ordersScreen = OrdersScreen(app: app)
        try requireCondition(ordersScreen.waitUntilReady(), in: app, "訂單清單根未就緒")

        ordersScreen.tapOrder(orderID: "BL-2604-017")
        let detailScreen = OrderDetailScreen(app: app)
        try requireCondition(detailScreen.waitUntilReady(), in: app, "訂單詳情未就緒")

        // When
        detailScreen.openMoreMenu()
        let isEditTapped = detailScreen.tapEdit()
        try requireCondition(isEditTapped, in: app, "點選詳情更多選單中的編輯按鈕失敗")

        // Then
        let editScreen = OrderEditScreen(app: app)
        try requireCondition(editScreen.waitUntilReady(), in: app, "編輯表單根未就緒")

        let editRoots = app.descendants(matching: .any)
            .matching(identifier: BLAccessibilityID.OrderEdit.root)
            .allElementsBoundByIndex
        try requireCondition(
            editRoots.count == 1,
            in: app,
            "畫面上應有且僅有 1 個 orderEdit.root，實際為 \(editRoots.count)"
        )

        let customerField = app.textFields[BLAccessibilityID.OrderEdit.customerField].firstMatch
        try requireCondition(customerField.waitUntilHittable(timeout: 10), in: app, "編輯表單客戶欄位不可互動")
        let customerValue = customerField.value as? String
        try requireCondition(
            customerValue == "Mika 周",
            in: app,
            "編輯表單客戶欄位值「\(String(describing: customerValue))」非 Mika 周"
        )

        // When
        editScreen.tapCancel()

        // Then
        let editRoot = app.descendants(matching: .any)[BLAccessibilityID.OrderEdit.root].firstMatch
        try requireCondition(
            editRoot.waitForDisappearance(timeout: 5),
            in: app,
            "取消編輯後表單 sheet 未消失"
        )
        try requireCondition(detailScreen.waitUntilReady(), in: app, "取消編輯後未回到訂單詳情")
        let detailMoreButtonAfterCancel = app.buttons[
            BLAccessibilityID.Orders.detailMoreButton
        ].firstMatch
        try requireCondition(
            detailMoreButtonAfterCancel.waitUntilHittable(timeout: 10),
            in: app,
            "取消編輯後未回到可互動的訂單詳情"
        )

        let detailRootID = BLAccessibilityID.Orders.detailRoot
        let detailRoot = app.descendants(matching: .any)[detailRootID].firstMatch
        let labelsAfterCancel = detailRoot.staticTexts.allElementsBoundByIndex.map(\.label)
        try requireCondition(
            labelsAfterCancel.contains("BL-2604-017"),
            in: app,
            "取消編輯後回到詳情非同筆訂單 BL-2604-017"
        )
    }

    /// 驗證從訂單清單點選新增訂單彈出單一 sheet，點選取消後關閉 sheet 並回到訂單清單
    ///
    /// - Throws: 訂單清單、新增表單或取消動作不符合預期時丟出測試錯誤
    func testOrders_新增訂單單一Sheet_取消後回到訂單清單() throws {
        // Given
        let app = launch(LaunchOptions(seed: .fullOrders))
        let navigator = AppNavigator(app: app)
        try requireCondition(navigator.tapRootTab(.orders), in: app, "點選原生訂單分頁失敗")
        let ordersScreen = OrdersScreen(app: app)
        try requireCondition(ordersScreen.waitUntilReady(), in: app, "訂單清單根未就緒")

        // When
        ordersScreen.tapAddOrder()

        // Then
        let editScreen = OrderEditScreen(app: app)
        try requireCondition(editScreen.waitUntilReady(), in: app, "新增訂單表單根未就緒")

        let editRoots = app.descendants(matching: .any)
            .matching(identifier: BLAccessibilityID.OrderEdit.root)
            .allElementsBoundByIndex
        try requireCondition(
            editRoots.count == 1,
            in: app,
            "畫面上應有且僅有 1 個 orderEdit.root，實際為 \(editRoots.count)"
        )

        // When
        editScreen.tapCancel()

        // Then
        let editRoot = app.descendants(matching: .any)[BLAccessibilityID.OrderEdit.root].firstMatch
        try requireCondition(
            editRoot.waitForDisappearance(timeout: 5),
            in: app,
            "取消新增後表單 sheet 未消失"
        )
        try requireCondition(ordersScreen.waitUntilReady(), in: app, "取消新增後訂單清單未就緒")
    }
}
