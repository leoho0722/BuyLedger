//
//  OrdersNavigationUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/27.
//

import XCTest

/// 訂單清單的原生選取與返回、搜尋與篩選後的選取狀態，以及新增與編輯表單取消後返回的 UI 測試
@MainActor
final class OrdersNavigationUITests: BLUITestCase {

    /// 驗證收合版選取 Mika 周的 BL-2604-017 後，詳情顯示該訂單與營收 $4,980，原生返回後詳情退出且 path 清空
    ///
    /// - Throws: 版面不適用、訂單清單、詳情或原生返回按鈕不符合預期時丟出測試錯誤
    /// - Note: 只適用 Orders 收合導覽，並排版面沒有原生返回按鈕
    func testDetailSelectionChanged_收合版選取訂單後原生返回_詳情顯示營收4980且path清空() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .compact,
            "原生 Back 案例只適用 Orders collapsed 導覽"
        )
        try requireCondition(
            orders.hasOrder(orderID: "BL-2604-017", timeout: 10),
            in: app,
            "找不到訂單 BL-2604-017 的清單列"
        )

        // When
        let detail = try orders.tapOrder(orderID: "BL-2604-017")

        // Then
        try requireCondition(
            detail.moreButton.waitUntilHittable(timeout: 10),
            in: app,
            "詳情更多操作按鈕未進入可互動狀態"
        )
        let displayedOrderID = detail.displayedOrderID()
        try requireCondition(
            displayedOrderID == "BL-2604-017",
            in: app,
            "訂單詳情顯示的編號應為 BL-2604-017 (實際：\(displayedOrderID ?? "缺值"))"
        )
        let title = orders.navigationBarTitle("Mika 周")
        try requireCondition(
            title == "Mika 周",
            in: app,
            "訂單詳情導覽列未顯示真實客戶 Mika 周 (實際：\(title ?? "缺值"))"
        )
        let revenue = try requireValue(detail.summaryValue(.revenue), in: app, "訂單營收摘要卡不存在")
        try requireCondition(revenue == "$4,980", in: app, "訂單營收摘要「\(revenue)」非預期的 $4,980")

        // When
        try app.tapUniqueNativeBackButton()

        // Then
        try requireCondition(
            detail.rootElement.waitForDisappearance(timeout: 5),
            in: app,
            "原生返回後訂單詳情未退出"
        )
        try requireCondition(orders.waitUntilReady(), in: app, "原生返回後訂單清單未就緒")
        try requireCondition(
            orders.hasOrder(orderID: "BL-2604-017"),
            in: app,
            "原生返回後訂單清單中未找到 BL-2604-017"
        )
        let selectedOrderID = try requireValue(
            orders.pathProjectedOrderID(),
            in: app,
            "原生返回後 Orders path 識別標記不存在"
        )
        try requireCondition(
            selectedOrderID.isEmpty,
            in: app,
            "原生 Back 後 path 選取應為空，實際為 \(selectedOrderID)"
        )
    }

    /// 驗證在訂單清單選取 BL-2604-017 後，Orders path 投影與詳情根的值都是 BL-2604-017
    ///
    /// - Throws: 訂單清單、path 標記或詳情狀態不符時丟出測試錯誤
    /// - Note: 首次未選取的斷言由 `OrdersAdaptiveLayoutUITests` 負責
    func testDetailSelectionChanged_選取訂單_path與詳情同步() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let orders = try OrdersScreen.open(in: app)
        try assertOrdersLayoutIsRecognized(in: app)

        // When
        let detail = try orders.tapOrder(orderID: "BL-2604-017")

        // Then
        let selectedOrderID = try requireValue(
            orders.pathProjectedOrderID(),
            in: app,
            "選取訂單後 Orders path 標記不存在"
        )
        try requireCondition(
            selectedOrderID == "BL-2604-017",
            in: app,
            "Orders path 應投影 BL-2604-017，實際為 \(selectedOrderID)"
        )
        let displayedOrderID = detail.displayedOrderID()
        try requireCondition(
            displayedOrderID == "BL-2604-017",
            in: app,
            "詳情根的值應為 BL-2604-017 (實際：\(displayedOrderID ?? "缺值"))"
        )
    }

    /// 驗證並排版面先選 BL-2604-017 再改選 Joyce 的 BL-2604-015 後，path、詳情根的值與更多操作都對應新訂單
    ///
    /// - Throws: 版面不適用、清單、path 或詳情不符合預期時丟出測試錯誤
    /// - Note: 只適用 Orders 清單與詳情並排，收合版改選會先返回清單
    func testDetailSelectionChanged_改選另一筆訂單_path與詳情同步() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            "改選第二筆訂單需 Orders 清單與詳情並排"
        )
        let detail = try orders.tapOrder(orderID: "BL-2604-017")

        // When
        try orders.tapOrder(orderID: "BL-2604-015")

        // Then
        let selectedOrderID = try requireValue(
            orders.pathProjectedOrderID(),
            in: app,
            "替換選取後 Orders path 標記不存在"
        )
        try requireCondition(
            selectedOrderID == "BL-2604-015",
            in: app,
            "替換後 Orders path 應為 BL-2604-015，實際為 \(selectedOrderID)"
        )
        try requireCondition(detail.waitUntilReady(), in: app, "Joyce 訂單詳情未就緒")
        try requireCondition(
            detail.moreButton.waitUntilHittable(timeout: 10),
            in: app,
            "替換訂單後詳情更多操作不可互動"
        )
        let displayedOrderID = detail.displayedOrderID()
        try requireCondition(
            displayedOrderID == "BL-2604-015",
            in: app,
            "詳情內容未顯示 BL-2604-015 (實際：\(displayedOrderID ?? "缺值"))"
        )
    }

    /// 驗證並排版面搜尋排除目前詳情後 path 清空並顯示無選取提示，搜尋結果恢復時不自動選取首筆
    ///
    /// - Throws: 版面不適用、搜尋、path 或無選取詳情提示不符合預期時丟出測試錯誤
    /// - Note: 只適用 Orders 清單與詳情並排，才有詳情欄的無選取提示
    func testSearchTextChanged_搜尋排除詳情後恢復結果_清除path且不自動選取() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            "同步搜尋與詳情需 Orders 欄位並排"
        )
        try orders.tapOrder(orderID: "BL-2604-017")

        // When
        try orders.search("Mika")
        try orders.search("ZZZ-NO-SUCH-ORDER")

        // Then
        let emptySelection = try requireValue(
            orders.pathProjectedOrderID(),
            in: app,
            "搜尋排除詳情後 Orders path 標記不存在"
        )
        try requireCondition(emptySelection.isEmpty, in: app, "搜尋排除詳情後 path 應清空")
        try assertEmptyState(BLAccessibilityID.Orders.listEmptyState, in: app)
        try requireCondition(
            orders.hasDetailEmptyState(),
            in: app,
            "搜尋排除詳情後未顯示無選取提示"
        )

        // When
        try orders.search("Mika")

        // Then
        let restoredSelection = try requireValue(
            orders.pathProjectedOrderID(),
            in: app,
            "搜尋恢復後 Orders path 標記不存在"
        )
        try requireCondition(restoredSelection.isEmpty, in: app, "搜尋恢復結果後不應自動選取首筆訂單")
        try requireCondition(orders.hasOrder(orderID: "BL-2604-017"), in: app, "搜尋結果未恢復")
    }

    /// 驗證並排版面的類別篩選排除目前詳情、path 清空後，按清除篩選時訂單回到清單且仍不自動選取
    ///
    /// - Throws: 版面不適用、篩選、清除或 path 不符合預期時丟出測試錯誤
    /// - Note: 只適用 Orders regular 清單欄，才有清除篩選按鈕
    func testClearFiltersTapped_類別篩選已排除詳情_清除後不自動選取訂單() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            "類別篩選案例需 Orders regular 清單欄"
        )
        try orders.tapOrder(orderID: "BL-2604-017")
        let picker = try orders.openCategoryPicker()
        try picker.tapPickerCategory("美妝")
        try picker.tapPickerDone()
        let filteredSelection = try requireValue(
            orders.pathProjectedOrderID(),
            in: app,
            "類別篩選排除詳情後 Orders path 標記不存在"
        )
        try requireCondition(filteredSelection.isEmpty, in: app, "排除詳情的類別篩選應清空 path")

        // When
        try orders.tapRegularClearFilters()

        // Then
        try requireCondition(
            orders.hasOrder(orderID: "BL-2604-017"),
            in: app,
            "清除篩選後 Mika 訂單應重新出現在清單"
        )
        let clearedSelection = try requireValue(
            orders.pathProjectedOrderID(),
            in: app,
            "清除篩選後 Orders path 標記不存在"
        )
        try requireCondition(clearedSelection.isEmpty, in: app, "清除篩選後不應自動選取訂單")
    }

    /// 驗證從訂單詳情開啟單一編輯 sheet 後點取消，表單關閉並回到同一筆訂單詳情
    ///
    /// - Throws: 訂單詳情、編輯表單或取消動作不符合預期時丟出測試錯誤
    /// - Note: Given 確認畫面上只有一層編輯表單，且客戶欄位帶入該訂單的客戶名稱
    func testCancelTapped_由詳情開啟編輯後取消_返回同筆詳情() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let orders = try OrdersScreen.open(in: app)
        let detail = try orders.tapOrder(orderID: "BL-2604-017")
        let edit = try detail.openEdit()
        try requireCondition(
            edit.presentedRootCount == 1,
            in: app,
            "畫面上應有且僅有 1 個 orderEdit.root，實際為 \(edit.presentedRootCount)"
        )
        try requireCondition(
            edit.customerField.waitUntilHittable(timeout: 10),
            in: app,
            "編輯表單客戶欄位不可互動"
        )
        let customerValue = edit.customerValue
        try requireCondition(
            customerValue == "Mika 周",
            in: app,
            "編輯表單客戶欄位值「\(customerValue ?? "缺值")」非 Mika 周"
        )

        // When
        try edit.tapCancel()

        // Then
        try requireCondition(
            edit.rootElement.waitForDisappearance(timeout: 5),
            in: app,
            "取消編輯後表單 sheet 未消失"
        )
        try requireCondition(detail.waitUntilReady(), in: app, "取消編輯後未回到訂單詳情")
        try requireCondition(
            detail.moreButton.waitUntilHittable(timeout: 10),
            in: app,
            "取消編輯後未回到可互動的訂單詳情"
        )
        let displayedOrderID = detail.displayedOrderID()
        try requireCondition(
            displayedOrderID == "BL-2604-017",
            in: app,
            "取消編輯後回到詳情非同筆訂單 BL-2604-017 (實際：\(displayedOrderID ?? "缺值"))"
        )
    }

    /// 驗證在訂單清單點新增訂單後，畫面上只呈現一層編輯表單 sheet
    ///
    /// - Throws: 訂單清單或新增表單不符合預期時丟出測試錯誤
    func testNewOrderTapped_訂單清單點新增_只呈現一層表單() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let orders = try OrdersScreen.open(in: app)

        // When
        let edit = try orders.tapAddOrder()

        // Then
        try requireCondition(edit.waitUntilReady(), in: app, "新增訂單表單根未就緒")
        try requireCondition(
            edit.presentedRootCount == 1,
            in: app,
            "畫面上應有且僅有 1 個 orderEdit.root，實際為 \(edit.presentedRootCount)"
        )
    }

    /// 驗證新增訂單表單未修改任何欄位就點取消時，表單 sheet 關閉並回到訂單清單
    ///
    /// - Throws: 訂單清單、新增表單或取消動作不符合預期時丟出測試錯誤
    func testCancelTapped_新增表單未修改取消_回到訂單清單() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .fullOrders))
        let orders = try OrdersScreen.open(in: app)
        let edit = try orders.tapAddOrder()

        // When
        try edit.tapCancel()

        // Then
        try requireCondition(
            edit.rootElement.waitForDisappearance(timeout: 5),
            in: app,
            "取消新增後表單 sheet 未消失"
        )
        try requireCondition(orders.waitUntilReady(), in: app, "取消新增後訂單清單未就緒")
    }
}
