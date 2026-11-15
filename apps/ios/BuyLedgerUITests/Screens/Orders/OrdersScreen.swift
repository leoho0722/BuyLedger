//
//  OrdersScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單清單頁的 Page Object
struct OrdersScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Computed Properties

@MainActor
extension OrdersScreen {

    /// regular 版面的付款方式入口
    var paymentMethodTrigger: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.paymentMethodMenuButton]
    }

    /// regular 版面的類別入口
    var categoryTrigger: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.categoryFilterButton]
    }

    /// regular 版面的清除篩選按鈕
    var regularClearFiltersButton: XCUIElement {
        app.buttons[BLAccessibilityID.Orders.clearFiltersButton].firstMatch
    }

    /// 清單工具列的新增訂單按鈕
    var addButton: XCUIElement {
        addButtonElements(matching: .button).firstMatch
    }

    /// 清單工具列的更多操作選單
    var batchMenuButton: XCUIElement {
        app.buttons[BLAccessibilityID.Orders.batchMenuButton].firstMatch
    }

    /// 清單目前顯示的訂單筆數
    var orderCountLabel: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.orderCountLabel].firstMatch
    }

    /// 多選模式目前已選取的訂單筆數
    var selectionSummary: XCUIElement {
        app.staticTexts[BLAccessibilityID.Orders.selectionSummary]
    }

    /// 多選模式的批次狀態選單
    var batchStatusMenuButton: XCUIElement {
        app.buttons[BLAccessibilityID.Orders.batchStatusMenuButton]
    }

    /// 多選模式的全選按鈕
    var selectAllButton: XCUIElement {
        app.buttons[BLAccessibilityID.Orders.selectAllButton]
    }

    /// 多選模式的完成按鈕
    var selectionDoneButton: XCUIElement {
        app.buttons[BLAccessibilityID.Orders.selectionDoneButton].firstMatch
    }

    /// 可及性樹中符合訂單清單根識別值的元素數量
    var listRootCount: Int {
        listRootElements.count
    }

    /// 可及性樹中符合訂單詳情根識別值的元素數量
    var detailRootCount: Int {
        detailRootElements.count
    }

    /// regular 版面的清除篩選按鈕是否可互動；無篩選條件時停用
    var isRegularClearFiltersEnabled: Bool {
        regularClearFiltersButton.isEnabled
    }
}

// MARK: - Internal Method

@MainActor
extension OrdersScreen {

    /// 等待訂單清單的載入失敗狀態出現
    ///
    /// - Parameter timeout: 等待失敗狀態出現的秒數
    /// - Returns: 失敗狀態是否在逾時前出現
    func waitForLoadFailure(timeout: TimeInterval = 10) -> Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.listLoadFailure]
            .waitForExistence(timeout: timeout)
    }

    /// 等待訂單清單的載入中狀態出現
    ///
    /// - Parameter timeout: 等待載入中狀態出現的秒數
    /// - Returns: 載入中狀態是否在逾時前出現
    func waitForLoading(timeout: TimeInterval = 10) -> Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.listLoading]
            .waitForExistence(timeout: timeout)
    }

    /// 點擊訂單清單載入失敗後的重試按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 重試按鈕無法互動時丟出 UITestError.stopped
    func tapRetry(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let button = retryButtonElements(matching: .button).firstMatch
        try button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 等待訂單清單空狀態出現，逾時設為零時立即判斷
    ///
    /// - Parameter timeout: 等待空狀態出現的秒數
    /// - Returns: 空狀態是否在逾時前出現
    func hasEmptyState(timeout: TimeInterval = 10) -> Bool {
        let element = listEmptyStateElements.firstMatch
        return timeout <= 0 ? element.exists : element.waitForExistence(timeout: timeout)
    }

    /// 等待詳情欄的未選取提示出現，並確認可取得有效的快照框線
    ///
    /// - Parameter timeout: 等待未選取提示出現的秒數；零表示立即判斷
    /// - Returns: 提示是否存在且具有有效的快照框線
    func hasDetailEmptyState(timeout: TimeInterval = 10) -> Bool {
        let element = detailEmptyStateElement
        let exists = timeout <= 0 ? element.exists : element.waitForExistence(timeout: timeout)
        return exists && element.snapshotFrame != nil
    }

    /// 等待詳情欄的未選取提示消失
    ///
    /// - Parameter timeout: 等待提示消失的秒數
    /// - Returns: 提示是否在逾時前消失
    func waitForDetailEmptyStateDismissal(timeout: TimeInterval = 10) -> Bool {
        detailEmptyStateElement.waitForDisappearance(timeout: timeout)
    }

    /// 取得指定狀態的瀏覽膠囊
    ///
    /// - Parameter filterID: 狀態篩選識別值
    /// - Returns: 對應的狀態膠囊元素
    func statusChip(_ filterID: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.statusChip(filterID)].firstMatch
    }

    /// 取得 regular 版面指定期間的日期膠囊
    ///
    /// - Parameter periodID: 日期期間識別值
    /// - Returns: 對應的日期膠囊元素
    func dateChip(_ periodID: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.dateChip(periodID)].firstMatch
    }

    /// 點擊 regular 清單欄標頭中清除篩選按鈕右側的空白
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 必要元素缺少、框線無效或右側空白不足時丟出 UITestError.stopped
    func tapRegularHeaderGap(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let list = listRootElements.firstMatch
        guard list.waitForExistence(timeout: 10) else {
            try app.stopWithDiagnostics("找不到訂單清單捲動範圍", file: file, line: line)
        }
        let listFrame = list.frame
        guard listFrame.isUsableFrame else {
            try app.stopWithDiagnostics("訂單清單捲動範圍的框線無效", file: file, line: line)
        }
        let clearButton = regularClearFiltersButton
        guard clearButton.waitUntilHittable(timeout: 10) else {
            try app.stopWithDiagnostics("清除篩選按鈕無法互動", file: file, line: line)
        }
        let clearFrame = clearButton.frame
        guard clearFrame.isUsableFrame else {
            try app.stopWithDiagnostics("清除篩選按鈕的框線無效", file: file, line: line)
        }
        let blankX = listFrame.maxX - 8
        guard blankX - clearFrame.maxX >= 20 else {
            try app.stopWithDiagnostics(
                "前提不成立：清除篩選鈕右側空白不足，鈕 frame = \(clearFrame)，清單 frame = \(listFrame)",
                file: file,
                line: line
            )
        }
        let blankOffset = CGVector(dx: blankX, dy: clearFrame.midY)
        app.coordinate(withNormalizedOffset: .zero).withOffset(blankOffset).tap()
    }

    /// 等待 compact 版面的整合篩選入口出現
    ///
    /// - Parameter timeout: 等待入口出現的秒數；零表示立即判斷
    /// - Returns: 篩選入口是否在逾時前出現
    func hasFilterTrigger(timeout: TimeInterval = 10) -> Bool {
        let element = filterTrigger
        return timeout <= 0 ? element.exists : element.waitForExistence(timeout: timeout)
    }

    /// 等待任一訂單列可互動
    ///
    /// - Parameter timeout: 等待訂單列可互動的秒數；零表示立即判斷
    /// - Returns: 是否至少有一筆可互動的訂單列
    func hasHittableOrderRow(timeout: TimeInterval = 10) -> Bool {
        Polling.wait(timeout: timeout) {
            orderRows.allElementsBoundByIndex.contains { $0.isHittableOnScreen }
        }
    }

    /// 切到訂單分頁，等待目前的前景內容、空狀態、失敗或已推入詳情就緒
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已進入前景的訂單畫面
    /// - Throws: 分頁無法切換或目的地未就緒時丟出測試錯誤
    @discardableResult
    static func open(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> OrdersScreen {
        let screen = OrdersScreen(app: app)
        if !screen.isForegroundReady {
            try AppNavigator(app: app).tapRootTab(.orders, file: file, line: line)
        }
        let isReady = Polling.wait(timeout: 10) { screen.isForegroundReady }
        guard isReady else {
            try app.stopWithDiagnostics("訂單分頁的前景內容未就緒", file: file, line: line)
        }
        return screen
    }

    /// 目前路徑投影到畫面的訂單識別碼，連續三次取樣相同才回傳
    ///
    /// - Returns: 穩定的訂單識別碼；逾時時回傳最後一次取樣
    /// - Note: 詳情根的值是顯示中的訂單識別碼；只見清單或詳情空狀態時為空字串；三者都不存在時為 `nil`
    /// - Note: 根分頁徽章會覆寫訂單分頁內容最外層節點的 value，路徑因此改由詳情根的值投影
    /// - Note: 連續取樣避開推入與返回動畫期間詳情根短暫殘留的值
    /// - Note: 5 秒內未穩定時回傳最後一次取樣，由呼叫端的預期值斷言判定
    func pathProjectedOrderID() -> String? {
        var previous: String??
        var projection: String?
        var stableSamples = 0
        _ = Polling.wait(timeout: 5, interval: 0.25) { // 逾時仍保留最後取樣，由呼叫端的預期值斷言判定
            let current = currentPathProjection
            stableSamples = previous == .some(current) ? stableSamples + 1 : 1
            previous = current
            projection = current
            return stableSamples >= 3 && current != nil
        }
        return projection
    }

    /// 篩選入口目前的標題，例如「篩選：本月 · 2 項類別」
    ///
    /// - Returns: 入口元素目前的可及性標籤
    func filterTriggerLabel() -> String {
        filterTrigger.label
    }

    /// regular 版面類別觸發鈕目前的標題，例如「類別：2 項」
    ///
    /// - Returns: 入口元素目前的可及性標籤
    func categoryTriggerLabel() -> String {
        categoryTrigger.label
    }

    /// regular 版面付款方式 Menu 目前的標題，例如「付款方式：信用卡」
    ///
    /// - Returns: 入口元素目前的可及性標籤
    func paymentMethodTriggerLabel() -> String {
        paymentMethodTrigger.label
    }

    /// 從清單更多選單進入多選並等到完成鈕可互動
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 必要選單或完成鈕無法互動時丟出測試錯誤
    func enterSelectionMode(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let menu = batchMenuButton
        try menu.requireHittable(
            in: app,
            timeout: 10,
            elementName: "訂單清單更多選單",
            file: file,
            line: line
        )
        menu.tap()
        try app.tapMenuItem(BLAccessibilityID.Orders.selectionModeButton, file: file, line: line)
        let done = selectionDoneButton
        try done.requireHittable(
            in: app,
            timeout: 10,
            elementName: "訂單多選完成鈕",
            file: file,
            line: line
        )
    }

    /// 點工具列的新增訂單
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的目的地 Page Object
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    @discardableResult
    func tapAddOrder(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> OrderEditScreen {
        let button = addButton
        try button.tapAfterWaiting(in: app, file: file, line: line)
        let screen = OrderEditScreen(app: app)
        try screen.requireReady(file: file, line: line)
        return screen
    }

    /// 選取指定狀態瀏覽膠囊
    ///
    /// - Parameters:
    ///   - filterID: 狀態篩選的 identifier
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func selectStatusChip(
        filterID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let chip = statusChip(filterID)
        try chip.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 把指定狀態膠囊完整捲入視窗可視範圍，對包含該膠囊的水平捲動容器做小幅拖曳
    ///
    /// - Parameters:
    ///   - filterID: 狀態篩選的 identifier
    ///   - window: 判定可視範圍的視窗元素
    ///   - maxDrags: 拖曳次數上限，超過仍未完整露出即停止測試
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 膠囊無法完整捲入視窗時丟出測試錯誤
    func revealStatusChipFully(
        filterID: String,
        in window: XCUIElement,
        maxDrags: Int = 6,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let chipID = BLAccessibilityID.Orders.statusChip(filterID)
        let chip = statusChip(filterID)
        let scrollView = app.scrollViews.containing(.button, identifier: chipID).firstMatch
        for attempt in 0...maxDrags {
            guard let windowFrame = window.snapshotFrame, let chipFrame = chip.snapshotFrame else {
                try app.stopWithDiagnostics("取不到狀態膠囊或視窗框線", file: file, line: line)
            }
            if windowFrame.contains(chipFrame) {
                return
            }
            guard attempt < maxDrags, scrollView.exists else {
                break
            }
            let isBeyondTrailingEdge = chipFrame.maxX > windowFrame.maxX
            let startX: CGFloat = isBeyondTrailingEdge ? 0.7 : 0.3
            let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: startX, dy: 0.5))
            let end = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            start.press(forDuration: 0.1, thenDragTo: end)
        }
        try app.stopWithDiagnostics("狀態膠囊未能完整露出", file: file, line: line)
    }

    /// 判斷狀態膠囊是否完整落在指定視窗內
    ///
    /// - Parameters:
    ///   - filterID: 狀態篩選識別值
    ///   - window: 用來比較可見範圍的視窗
    /// - Returns: 膠囊與視窗框線有效且完整包含時為真
    func isStatusChipFullyVisible(filterID: String, in window: XCUIElement) -> Bool {
        let chip = statusChip(filterID)
        guard let windowFrame = window.snapshotFrame, let chipFrame = chip.snapshotFrame else {
            return false
        }
        return windowFrame.contains(chipFrame)
    }

    /// 讀取包含指定文字的訂單導覽列標題
    ///
    /// - Parameters:
    ///   - title: 預期定位的導覽列標題
    ///   - timeout: 等待標題出現的秒數
    /// - Returns: 實際標題文字；導覽列未出現時為缺值
    func navigationBarTitle(_ title: String, timeout: TimeInterval = 10) -> String? {
        guard app.waitForNavigationBarTitle(title, timeout: timeout) else {
            return nil
        }
        let bar = app.navigationBar(containingTitle: title)
        let text = bar.staticTexts.matching(NSPredicate(format: "label == %@", title)).firstMatch
        if text.exists {
            return text.label
        }
        return bar.identifier == title ? bar.identifier : bar.label
    }

    /// 依客戶名稱查詢動態訂單列，僅在訂單列 identifier 前綴內比對使用者資料
    ///
    /// - Parameter customerName: 要尋找的客戶名稱
    /// - Returns: identifier 前綴與客戶名稱皆相符的第一筆訂單列
    func orderRow(customerName: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@ AND label CONTAINS %@",
                BLAccessibilityID.Orders.row(orderID: ""),
                customerName
            )
        ).firstMatch
    }

    /// 逐字輸入搜尋文字後以 Return 收起鍵盤
    ///
    /// - Parameters:
    ///   - text: 要搜尋的文字
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 搜尋欄不可互動或鍵盤焦點未解除時丟出測試錯誤
    func searchAndDismissKeyboard(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = try app.hittableSearchField(file: file, line: line)
        try app.typeSearchText(
            text,
            into: field,
            clearButton: field.buttons.firstMatch,
            file: file,
            line: line
        )
        try app.dismissSearchKeyboard(in: field, file: file, line: line)
    }

    /// 在系統搜尋欄輸入關鍵字
    ///
    /// - Parameters:
    ///   - text: 要輸入的搜尋文字
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 找不到可互動的搜尋欄時丟出測試錯誤
    func search(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = try app.hittableSearchField(file: file, line: line)
        try field.clearAndType(
            text,
            in: app,
            file: file,
            line: line
        )
    }

    /// 點指定訂單編號的清單列進入詳情
    ///
    /// - Parameters:
    ///   - orderID: 訂單編號
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的目的地 Page Object
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    @discardableResult
    func tapOrder(
        orderID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> OrderDetailScreen {
        let row = orderRow(orderID: orderID)
        // 列在可視區上方時往回輕拖，位於下方或尚未建立時以滑動載入；列已可點時不捲動
        if !row.isHittableOnScreen,
           app.stableVisibleFrame(of: row, within: rootElement) == nil {
            try app.stopWithDiagnostics("捲動後訂單列 \(orderID) 仍不可點", file: file, line: line)
        }
        try row.tapAfterWaiting(in: app, file: file, line: line)
        let screen = OrderDetailScreen(app: app)
        try screen.requireReady(file: file, line: line)
        let isExpectedOrder = Polling.wait(timeout: 5) { screen.displayedOrderID() == orderID }
        guard isExpectedOrder else {
            try app.stopWithDiagnostics("訂單詳情未顯示指定訂單 \(orderID)", file: file, line: line)
        }
        return screen
    }

    /// 等待指定訂單編號的列出現於清單
    ///
    /// - Parameters:
    ///   - orderID: 訂單編號
    ///   - timeout: 等待訂單列出現的秒數
    /// - Returns: 訂單列是否在逾時前出現
    func hasOrder(orderID: String, timeout: TimeInterval = 5) -> Bool {
        orderRow(orderID: orderID).waitForExistence(timeout: timeout)
    }

    /// 取指定訂單編號的清單列
    ///
    /// - Parameter orderID: 訂單編號
    /// - Returns: 對應的訂單列元素
    func orderRow(orderID: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.row(orderID: orderID)]
    }

    /// 開啟整合篩選 sheet (compact 版面工具列入口)
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的目的地 Page Object
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func openFilterSheet(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> OrderFilterSheetScreen {
        let button = filterTrigger
        try button.tapAfterWaiting(in: app, file: file, line: line)
        let screen = OrderFilterSheetScreen(app: app)
        try screen.requireReady(file: file, line: line)
        return screen
    }

    /// 點工具列的 AI 商品明細總結入口
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 選單或總結項目無法點擊時丟出 `UITestError.stopped`
    /// - Note: AI 未開啟時呈現提示 alert；已開啟要取得總結 sheet 時改用
    ///   `openAISummary`
    func tapAISummary(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        try tapAISummaryMenuItem(file: file, line: line)
    }

    /// 點 AI 總結入口並取得已就緒的總結畫面
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的 AI 總結畫面
    /// - Throws: 選單或總結項目無法點擊，或總結畫面未就緒時丟出測試錯誤
    func openAISummary(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> AISummaryScreen {
        try tapAISummaryMenuItem(file: file, line: line)
        let screen = AISummaryScreen(app: app)
        try screen.requireReady(file: file, line: line)
        return screen
    }

    /// 點 regular 版面的類別觸發鈕開啟類別選擇器
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的目的地 Page Object
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    @discardableResult
    func openCategoryPicker(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> OrderCategoryPickerScreen {
        let trigger = categoryTrigger
        try trigger.tapAfterWaiting(in: app, file: file, line: line)
        let screen = OrderCategoryPickerScreen(app: app)
        try screen.requireReady(file: file, line: line)
        return screen
    }

    /// 選取 regular 版面付款方式 Menu 的指定項目，identifier 缺失時以名稱比對標籤
    ///
    /// - Parameters:
    ///   - name: 付款方式名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func selectPaymentMethodInRegularLayout(
        _ name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try paymentMethodTrigger.tapAfterWaiting(in: app, file: file, line: line)
        let item = BLAccessibilityID.Orders.paymentMethodMenuOption(name)
        try app.tapMenuItem(
            item,
            label: name,
            file: file,
            line: line
        )
    }

    /// 點 regular 版面的日期膠囊選取指定期間
    ///
    /// - Parameters:
    ///   - periodID: 日期期間識別值 (`all`、`thisWeek`、`thisMonth`、`lastMonth`)
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func selectRegularDateChip(
        _ periodID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let identifier = BLAccessibilityID.Orders.dateChip(periodID)
        let chip = dateChip(periodID)
        if !chip.isHittableOnScreen {
            let scrollView = app.scrollViews.containing(.button, identifier: identifier).firstMatch
            try app.scrollToHittableHorizontally(
                chip,
                within: scrollView,
                file: file,
                line: line
            )
        }
        try chip.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 判斷 regular 版面的日期膠囊是否處於選中狀態
    ///
    /// - Parameter periodID: 日期期間識別值
    /// - Returns: 膠囊是否存在且選中
    func isRegularDateChipSelected(_ periodID: String) -> Bool {
        dateChip(periodID).isSelected
    }

    /// 判斷 regular 版面的狀態膠囊是否處於選中狀態
    ///
    /// - Parameter filterID: 狀態篩選識別值 (`all` 或狀態 `rawValue`)
    /// - Returns: 膠囊是否存在且選中
    func isRegularStatusChipSelected(_ filterID: String) -> Bool {
        statusChip(filterID).isSelected
    }

    /// 判斷 regular 版面的付款方式 Menu 是否處於選中狀態
    ///
    /// - Returns: 付款方式 Menu 是否存在且選中
    func isRegularPaymentMethodMenuSelected() -> Bool {
        paymentMethodTrigger.isSelected
    }

    /// 點 regular 版面的清除篩選按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapRegularClearFilters(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try regularClearFiltersButton.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 收集清單上列出的所有訂單編號
    ///
    /// - Parameter maxSwipes: 最多 `swipeUp` 次數
    /// - Returns: 清單列出的訂單編號集合
    /// - Note: 結果以清單實際列出的 identifier 為準，不以單一畫面可見數量代表全部結果
    func collectListedOrderIDs(maxSwipes: Int = 20) -> Set<String> {
        let prefix = BLAccessibilityID.Orders.row(orderID: "")
        var collected = Set<String>()
        var stableRounds = 0
        var swipes = 0
        // 惰性清單的下方列需上捲後才會進入可及性樹
        while swipes < maxSwipes, stableRounds < 2 {
            let before = collected.count
            let rows = orderRows
            for index in 0..<rows.count {
                let identifier = rows.element(boundBy: index).identifier
                collected.insert(String(identifier.dropFirst(prefix.count)))
            }
            stableRounds = collected.count == before ? stableRounds + 1 : 0
            listRootElements.firstMatch.swipeUp()
            swipes += 1
        }
        return collected
    }

    /// 查詢目前訂單篩選內容中的類別格
    ///
    /// - Parameter name: 類別名稱
    /// - Returns: 對應的類別格元素
    func filterCategoryCell(_ name: String) -> XCUIElement {
        categoryGrid.filterCategoryCell(name)
    }

    /// 透過共用類別格互動露出訂單篩選中的類別
    ///
    /// - Parameters:
    ///   - name: 類別名稱
    ///   - container: 類別格所在的 sheet；未指定時查詢整合篩選 sheet
    ///   - maxSwipes: 每個方向的捲動次數上限
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 目標類別格無法露出時丟出測試錯誤
    func revealFilterCategory(
        _ name: String,
        within container: XCUIElement? = nil,
        maxSwipes: Int = 60,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let sheet = container
            ?? app.descendants(matching: .any)[BLAccessibilityID.Orders.filterSheet]
        try categoryGrid.revealFilterCategory(
            name,
            within: sheet,
            maxSwipes: maxSwipes,
            file: file,
            line: line
        )
    }

    /// 點篩選 sheet 或類別選擇器捨棄確認的「繼續編輯」，sheet 保持開啟
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapDiscardKeepEditing(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try app.tapAlertButton(label: "繼續編輯", file: file, line: line)
    }
}

// MARK: - ScreenProtocol

extension OrdersScreen: ScreenProtocol {

    /// 判定訂單清單已就緒的根 identifier (清單捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.Orders.listRoot
    }
}

// MARK: - Private Method

@MainActor
private extension OrdersScreen {

    /// 訂單清單根元素的完整查詢，保留重複根的計數
    var listRootElements: XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: BLAccessibilityID.Orders.listRoot)
    }

    /// 訂單詳情根元素的完整查詢，保留重複根的計數
    var detailRootElements: XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: BLAccessibilityID.Orders.detailRoot)
    }

    /// 訂單清單空狀態的完整查詢，供存在與可互動性判斷共用
    var listEmptyStateElements: XCUIElementQuery {
        app.descendants(matching: .any)
            .matching(identifier: BLAccessibilityID.Orders.listEmptyState)
    }

    /// 詳情欄未選取提示的元素，存在與快照框線判斷共用此查詢
    var detailEmptyStateElement: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.detailEmptyState].firstMatch
    }

    /// compact 版面的整合篩選入口
    var filterTrigger: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.filterButton]
    }

    /// 以訂單列識別值前綴定位的完整查詢
    var orderRows: XCUIElementQuery {
        app.descendants(matching: .any).matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@",
                BLAccessibilityID.Orders.row(orderID: "")
            )
        )
    }

    /// 訂單篩選內容使用的類別格互動
    var categoryGrid: CategoryGridInteraction {
        CategoryGridInteraction(app: app)
    }

    /// 訂單目的地是否有可互動的清單、空狀態、失敗或已推入的詳情
    var isForegroundReady: Bool {
        let queries = [
            addButtonElements(),
            listEmptyStateElements,
            retryButtonElements(),
        ] + [
            BLAccessibilityID.Orders.detailMoreButton,
            BLAccessibilityID.Orders.detailSummaryTile(.revenue),
            BLAccessibilityID.Orders.detailSummaryTile(.cost),
            BLAccessibilityID.Orders.detailSummaryTile(.profit),
        ].map {
            app.descendants(matching: .any).matching(identifier: $0)
        }
        return hasHittableOrderRow(timeout: 0)
            || queries.contains {
                $0.allElementsBoundByIndex.contains { $0.isHittableOnScreen }
            }
    }

    /// 單次讀取路徑投影：詳情根的值、清單或空狀態可見時的空字串，或都不存在時的缺值
    var currentPathProjection: String? {
        let detailRoot = detailRootElements.firstMatch
        if detailRoot.exists {
            return detailRoot.value as? String
        }
        let listRoot = listRootElements.firstMatch
        return listRoot.exists || detailEmptyStateElement.exists ? "" : nil
    }

    /// 依元素類型取得新增訂單按鈕的完整查詢
    ///
    /// - Parameter type: 元素類型；前景就緒判斷使用任意類型，點擊使用按鈕
    /// - Returns: 符合識別值與元素類型的完整查詢
    func addButtonElements(matching type: XCUIElement.ElementType = .any) -> XCUIElementQuery {
        app.descendants(matching: type)
            .matching(identifier: BLAccessibilityID.Orders.addButton)
    }

    /// 依元素類型取得重試按鈕的完整查詢
    ///
    /// - Parameter type: 元素類型；前景就緒判斷使用任意類型，點擊使用按鈕
    /// - Returns: 符合識別值與元素類型的完整查詢
    func retryButtonElements(matching type: XCUIElement.ElementType = .any) -> XCUIElementQuery {
        app.descendants(matching: type)
            .matching(identifier: BLAccessibilityID.Orders.listLoadFailureRetryButton)
    }

    /// 開啟更多操作選單並點 AI 總結項目
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 選單或總結項目無法點擊時丟出測試錯誤
    func tapAISummaryMenuItem(file: StaticString, line: UInt) throws(UITestError) {
        let menu = batchMenuButton
        try menu.tapAfterWaiting(in: app, file: file, line: line)
        try app.tapMenuItem(BLAccessibilityID.Orders.aiSummaryButton, file: file, line: line)
    }
}
