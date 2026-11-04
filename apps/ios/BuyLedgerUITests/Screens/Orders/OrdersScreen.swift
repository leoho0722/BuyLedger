//
//  OrdersScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單清單頁的 Page Object
///
/// - Note: 篩選 sheet 與類別選擇器共用的類別格查詢、捲動與搜尋輸入 helper 也放在這裡，
///   兩個 sheet 的 Page Object 透過它呼叫
struct OrdersScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Nested Types

private extension OrdersScreen {

    /// 必要互動元素無法取得時的測試錯誤
    enum InteractionError: Error {

        /// 畫面缺少必要元素或元素尚未能互動
        case elementUnavailable
    }

    /// 單一方向的滑動設定
    struct ScrollSweep {

        /// 是否以 `swipeUp` 露出下方內容 (`true`)；`false` 時以 `swipeDown` 露出上方內容
        let isRevealingContentBelow: Bool

        /// 最多滑動次數
        let maxSwipes: Int
    }
}

// MARK: - Computed Properties

@MainActor
extension OrdersScreen {

    /// 是否正顯示沒有符合條件訂單的空狀態
    var isEmptyStateShown: Bool {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.listEmptyState].exists
    }

    /// 目前路徑投影到畫面的訂單識別碼，連續三次取樣相同才回傳
    ///
    /// - Note: 詳情根的值是顯示中的訂單識別碼；只見清單或詳情空狀態時為空字串；三者都不存在時為 `nil`
    /// - Note: 根分頁徽章會覆寫訂單分頁內容最外層節點的 value，路徑因此改由詳情根的值投影
    /// - Note: 連續取樣避開推入與返回動畫期間詳情根短暫殘留的值
    /// - Note: 5 秒內未穩定時回傳最後一次取樣，由呼叫端的預期值斷言判定
    var pathProjectedOrderID: String? {
        let deadline = Date.now.addingTimeInterval(5)
        var previous: String??
        var stableSamples = 0
        while true {
            let current = currentPathProjection
            if let previous, previous == current {
                stableSamples += 1
            } else {
                stableSamples = 1
            }
            if stableSamples >= 3, current != nil {
                return current
            }
            previous = current
            guard Date.now < deadline else {
                return current
            }
            _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: 0.25)
        }
    }

    /// 篩選入口目前的標題，例如「篩選：本月 · 2 項類別」
    var filterTriggerLabel: String {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.filterButton].label
    }

    /// regular 版面類別觸發鈕目前的標題，例如「類別：2 項」
    var categoryTriggerLabel: String {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.categoryFilterButton].label
    }

    /// regular 版面付款方式 Menu 目前的標題，例如「付款方式：信用卡」
    var paymentMethodTriggerLabel: String {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.paymentMethodMenuButton].label
    }

    /// regular 版面的清除篩選按鈕是否可互動；無篩選條件時停用
    var isRegularClearFiltersEnabled: Bool {
        let identifier = BLAccessibilityID.Orders.clearFiltersButton
        return app.buttons[identifier].firstMatch.isEnabled
    }
}

// MARK: - Internal Method

@MainActor
extension OrdersScreen {

    /// 從清單更多選單進入多選並等到完成鈕可互動
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 必要選單或完成鈕無法互動時丟出測試錯誤
    func enterSelectionMode(file: StaticString = #filePath, line: UInt = #line) throws {
        let menu = app.buttons[BLAccessibilityID.Orders.batchMenuButton].firstMatch
        guard menu.waitUntilHittableOrFail(
            in: app,
            timeout: 10,
            elementName: "訂單清單更多選單",
            file: file,
            line: line
        ) else {
            throw InteractionError.elementUnavailable
        }
        menu.tap()
        guard app.tapMenuItem(
            BLAccessibilityID.Orders.selectionModeButton,
            file: file,
            line: line
        ) else {
            throw InteractionError.elementUnavailable
        }
        let done = app.buttons[BLAccessibilityID.Orders.selectionDoneButton].firstMatch
        guard done.waitUntilHittableOrFail(
            in: app,
            timeout: 10,
            elementName: "訂單多選完成鈕",
            file: file,
            line: line
        ) else {
            throw InteractionError.elementUnavailable
        }
    }

    /// 點工具列的新增訂單
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapAddOrder(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.Orders.addButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 選取指定狀態瀏覽膠囊
    ///
    /// - Parameters:
    ///   - filterID: 狀態篩選的 identifier
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func selectStatusChip(filterID: String, file: StaticString = #filePath, line: UInt = #line) {
        let chip = app.buttons[BLAccessibilityID.Orders.statusChip(filterID)]
        chip.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 把指定狀態膠囊完整捲入視窗可視範圍，對包含該膠囊的水平捲動容器做小幅拖曳
    ///
    /// - Parameters:
    ///   - filterID: 狀態篩選的 identifier
    ///   - window: 判定可視範圍的視窗元素
    ///   - maxDrags: 拖曳次數上限，超過仍未完整露出即回傳 `false`
    /// - Returns: 膠囊框線完整落在視窗內時為 `true`
    func revealStatusChipFully(
        filterID: String,
        in window: XCUIElement,
        maxDrags: Int = 6
    ) -> Bool {
        let chipID = BLAccessibilityID.Orders.statusChip(filterID)
        let chip = app.descendants(matching: .any)[chipID].firstMatch
        let scrollView = app.scrollViews.containing(.button, identifier: chipID).firstMatch
        for attempt in 0...maxDrags {
            guard let windowFrame = window.snapshotFrame, let chipFrame = chip.snapshotFrame else {
                return false
            }
            if windowFrame.contains(chipFrame) {
                return true
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
        return false
    }

    /// 在系統搜尋欄輸入關鍵字
    ///
    /// - Parameters:
    ///   - text: 要輸入的搜尋文字
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 找不到可互動的搜尋欄時丟出測試錯誤
    func search(_ text: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let field = try hittableSearchField(file: file, line: line)
        field.clearAndType(
            text,
            in: app,
            file: file,
            line: line
        )
    }

    /// 取得目前畫面上可互動的訂單搜尋欄
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 目前可互動的系統搜尋欄
    /// - Throws: 找不到可互動搜尋欄時丟出測試錯誤
    func hittableSearchField(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> XCUIElement {
        let deadline = Date.now.addingTimeInterval(10)
        repeat {
            if let field = app.searchFields.allElementsBoundByIndex.first(
                where: \.isHittableOnScreen
            ) {
                return field
            }
            _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: 0.2)
        } while Date.now < deadline
        app.failWithDiagnostics("找不到元素：可互動的訂單搜尋欄", file: file, line: line)
        throw InteractionError.elementUnavailable
    }

    /// 點指定訂單編號的清單列進入詳情
    ///
    /// - Parameters:
    ///   - orderID: 訂單編號
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapOrder(orderID: String, file: StaticString = #filePath, line: UInt = #line) {
        let row = orderRow(orderID: orderID)
        // 列在可視區上方時往回輕拖，位於下方或尚未建立時以滑動載入；列已可點時不捲動
        if !row.isHittableOnScreen, app.stableVisibleFrame(of: row, within: rootElement) == nil {
            app.failWithDiagnostics("捲動後訂單列 \(orderID) 仍不可點", file: file, line: line)
            return
        }
        row.tapAfterWaiting(in: app, file: file, line: line)
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
    func openFilterSheet(file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[BLAccessibilityID.Orders.filterButton]
        button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 點工具列的 AI 商品明細總結入口
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 是否在逾時前點到 AI 商品明細總結項目
    @discardableResult
    func tapAISummary(file: StaticString = #filePath, line: UInt = #line) -> Bool {
        // AI 總結是「更多操作」選單內的項目，先開選單再點該項
        let menu = app.buttons[BLAccessibilityID.Orders.batchMenuButton]
        menu.tapAfterWaiting(in: app, file: file, line: line)
        return app.tapMenuItem(BLAccessibilityID.Orders.aiSummaryButton, file: file, line: line)
    }

    /// 點 regular 版面的類別觸發鈕開啟類別選擇器
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func openCategoryPicker(file: StaticString = #filePath, line: UInt = #line) {
        let trigger = app.descendants(matching: .any)[BLAccessibilityID.Orders.categoryFilterButton]
        trigger.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 選取 regular 版面付款方式 Menu 的指定項目，identifier 缺失時以名稱比對標籤
    ///
    /// - Parameters:
    ///   - name: 付款方式名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func selectPaymentMethodInRegularLayout(
        _ name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let menuID = BLAccessibilityID.Orders.paymentMethodMenuButton
        app.descendants(matching: .any)[menuID].tapAfterWaiting(in: app, file: file, line: line)
        let item = BLAccessibilityID.Orders.paymentMethodMenuOption(name)
        _ = app.tapMenuItem(
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
    func selectRegularDateChip(
        _ periodID: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let identifier = BLAccessibilityID.Orders.dateChip(periodID)
        app.descendants(matching: .any)[identifier].tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 判斷 regular 版面的日期膠囊是否處於選中狀態
    ///
    /// - Parameter periodID: 日期期間識別值
    /// - Returns: 膠囊是否存在且選中
    func isRegularDateChipSelected(_ periodID: String) -> Bool {
        let identifier = BLAccessibilityID.Orders.dateChip(periodID)
        return app.descendants(matching: .any)[identifier].isSelected
    }

    /// 判斷 regular 版面的狀態膠囊是否處於選中狀態
    ///
    /// - Parameter filterID: 狀態篩選識別值 (`all` 或狀態 `rawValue`)
    /// - Returns: 膠囊是否存在且選中
    func isRegularStatusChipSelected(_ filterID: String) -> Bool {
        let identifier = BLAccessibilityID.Orders.statusChip(filterID)
        return app.descendants(matching: .any)[identifier].isSelected
    }

    /// 判斷 regular 版面的付款方式 Menu 是否處於選中狀態
    ///
    /// - Returns: 付款方式 Menu 是否存在且選中
    func isRegularPaymentMethodMenuSelected() -> Bool {
        let identifier = BLAccessibilityID.Orders.paymentMethodMenuButton
        return app.descendants(matching: .any)[identifier].isSelected
    }

    /// 點 regular 版面的清除篩選按鈕
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapRegularClearFilters(file: StaticString = #filePath, line: UInt = #line) {
        let identifier = BLAccessibilityID.Orders.clearFiltersButton
        app.buttons[identifier].firstMatch.tapAfterWaiting(in: app, file: file, line: line)
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
            let rows = app.descendants(matching: .any).matching(
                NSPredicate(format: "identifier BEGINSWITH %@", prefix)
            )
            for index in 0..<rows.count {
                let identifier = rows.element(boundBy: index).identifier
                collected.insert(String(identifier.dropFirst(prefix.count)))
            }
            stableRounds = collected.count == before ? stableRounds + 1 : 0
            app.descendants(matching: .any)[BLAccessibilityID.Orders.listRoot].swipeUp()
            swipes += 1
        }
        return collected
    }

    /// 點篩選 sheet 或類別選擇器捨棄確認的「繼續編輯」，sheet 保持開啟
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func tapDiscardKeepEditing(file: StaticString = #filePath, line: UInt = #line) {
        app.tapAlertButton(label: "繼續編輯", file: file, line: line)
    }

    /// 取得篩選 sheet 或類別選擇器內組標題的元素
    ///
    /// - Parameter kindID: 組別種類的識別值 (`ongoing` 或 `closed`)
    /// - Returns: 對應組標題的元素
    func filterGroupHeader(_ kindID: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.categoryGroupHeader(kindID)]
    }

    /// 露出指定類別的格子，預設在篩選 sheet 內尋找
    ///
    /// - Parameters:
    ///   - name: 類別名稱
    ///   - container: 格子所在的 sheet，`nil` 代表篩選 sheet
    ///   - maxSwipes: 單一方向最多滑動次數
    /// - Returns: 格子是否在捲動後存在
    func revealFilterCategory(
        _ name: String,
        within container: XCUIElement? = nil,
        maxSwipes: Int = 60
    ) -> Bool {
        revealElement(
            filterCategoryCell(name),
            within: container ?? OrderFilterSheetScreen(app: app).filterSheet,
            maxSwipes: maxSwipes
        )
    }

    /// 取篩選 sheet 或類別選擇器內指定類別的格子
    ///
    /// - Parameter name: 類別名稱
    /// - Returns: 對應格子的元素
    func filterCategoryCell(_ name: String) -> XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.Orders.categoryCell(name)]
    }

    /// 依序找下方與上方內容，捲動後等待相對位置穩定再判斷目標與清單盡頭
    ///
    /// - Parameters:
    ///   - element: 要露出的元素 (類別格或組標題)
    ///   - container: 元素所在的可捲動 sheet
    ///   - maxSwipes: 單一方向最多滑動次數，作為安全上限
    /// - Returns: 元素是否在捲動後存在
    /// - Note: 首尾格的位置以容器為基準，避免 sheet 位移被當成清單捲動
    /// - Note: 位置簽章連續兩次相同後才檢查目標是否出現或清單是否到底
    func revealElement(
        _ element: XCUIElement,
        within container: XCUIElement,
        maxSwipes: Int = 60
    ) -> Bool {
        if element.exists {
            return true
        }
        let belowFirst = ScrollSweep(isRevealingContentBelow: true, maxSwipes: maxSwipes)
        if scrollToEndOfCategories(in: container, sweep: belowFirst, until: element) {
            return true
        }
        let aboveSecond = ScrollSweep(isRevealingContentBelow: false, maxSwipes: maxSwipes)
        return scrollToEndOfCategories(in: container, sweep: aboveSecond, until: element)
    }

    /// 捲動容器把元素露到導覽列下方的可點範圍內，輕拖結束後等位置穩定才回傳
    ///
    /// - Parameters:
    ///   - element: 要捲到可點位置的元素
    ///   - container: 元素所在的 sheet
    ///   - maxDrags: 輕拖次數上限
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Note: 導覽列遮住的部分不算可點，因此判斷範圍由導覽列下緣起算
    /// - Note: 慣性未停止前點擊只會停住捲動，因此輕拖後先等位置穩定再點擊
    func scrollToTappable(
        _ element: XCUIElement,
        within container: XCUIElement,
        maxDrags: Int = 12,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var drags = 0
        while true {
            if !waitUntilFrameStable(element) {
                app.failWithDiagnostics("元素位置未穩定，無法安全點擊", file: file, line: line)
                return
            }
            if isInVisibleBand(element, within: container) {
                return
            }
            if drags >= maxDrags {
                app.failWithDiagnostics("輕拖上限內仍無法露出可點範圍，目標可能被導覽列遮住", file: file, line: line)
                return
            }
            dragToward(element, within: container)
            drags += 1
        }
    }

    /// 在搜尋欄逐字輸入文字，先清除既有內容
    ///
    /// - Parameters:
    ///   - text: 要輸入的搜尋文字
    ///   - field: 搜尋欄
    ///   - clearButton: 搜尋欄的清除鈕，存在時代表欄位有文字
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Note: 注音鍵盤在輸入一個數字後會切回注音面板，整段 `typeText` 只會輸入到第一個數字，
    ///   因此逐字呼叫 `typeText`
    func typeSearchText(
        _ text: String,
        into field: XCUIElement,
        clearButton: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        field.tapAfterWaiting(in: app, file: file, line: line)
        // 點擊後等鍵盤出現才開始輸入，最多重新點擊三次
        var isKeyboardVisible = app.keyboards.firstMatch.waitForExistence(timeout: 2)
        var focusAttempts = 0
        while !isKeyboardVisible && focusAttempts < 3 {
            field.tap()
            focusAttempts += 1
            isKeyboardVisible = app.keyboards.firstMatch.waitForExistence(timeout: 2)
        }
        if !isKeyboardVisible {
            app.failWithDiagnostics("點擊搜尋欄後鍵盤未出現", file: file, line: line)
            return
        }
        if clearButton.exists, let existing = field.value as? String, !existing.isEmpty {
            let deletes = String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count)
            field.typeText(deletes)
        }
        for character in text {
            field.typeText(String(character))
        }
    }
}

// MARK: - Screen

extension OrdersScreen: Screen {

    /// 判定訂單清單已就緒的根 identifier (清單捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.Orders.listRoot
    }
}

// MARK: - Private Method

@MainActor
private extension OrdersScreen {

    /// 單次讀取路徑投影：詳情根的值、清單或空狀態可見時的空字串，或都不存在時的 `nil`
    var currentPathProjection: String? {
        let detailRoot = app.descendants(matching: .any)[BLAccessibilityID.Orders.detailRoot]
            .firstMatch
        if detailRoot.exists {
            return detailRoot.value as? String
        }
        let listRoot = app.descendants(matching: .any)[BLAccessibilityID.Orders.listRoot].firstMatch
        let emptyStateID = BLAccessibilityID.Orders.detailEmptyState
        let emptyState = app.descendants(matching: .any)[emptyStateID].firstMatch
        return listRoot.exists || emptyState.exists ? "" : nil
    }

    /// 依 `sweep` 的手勢滑動，直到目標出現或穩定位置簽章確認清單已到底
    ///
    /// - Parameters:
    ///   - container: 可捲動的容器
    ///   - sweep: 滑動方向與次數上限
    ///   - element: 要等待出現的目標元素
    /// - Returns: 目標元素是否在清單盡頭前出現
    /// - Note: 手勢前確認 sheet 存在，手勢後等相對位置簽章穩定再判斷
    func scrollToEndOfCategories(
        in container: XCUIElement,
        sweep: ScrollSweep,
        until element: XCUIElement
    ) -> Bool {
        let direction = sweep.isRevealingContentBelow ? "往下找" : "往上找"
        for _ in 0..<sweep.maxSwipes {
            guard container.exists else {
                app.failWithDiagnostics("類別清單的 sheet 已關閉，無法繼續\(direction)")
                return false
            }
            if element.exists {
                return true
            }
            let previous = categoryListSignature(in: container)
            if sweep.isRevealingContentBelow {
                container.swipeUp()
            } else {
                // 清單到頂端時快速下滑會把 sheet 拉掉，改用無慣性的輕拖
                let start = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
                let end = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65))
                start.press(
                    forDuration: 0.1,
                    thenDragTo: end,
                    withVelocity: .slow,
                    thenHoldForDuration: 0.1
                )
            }
            // 逾時仍未穩定代表還在捲動，不視為到底，下一輪開頭會再確認 sheet 是否存在
            guard let current = waitForStableCategorySignature(in: container) else {
                continue
            }
            guard container.exists else {
                app.failWithDiagnostics("類別清單的 sheet 已關閉，無法繼續\(direction)")
                return false
            }
            let hasReachedEnd = current == previous
            if element.exists {
                return true
            }
            if hasReachedEnd {
                return false
            }
        }
        return element.exists
    }

    /// 取得類別格相對於容器的縱向位置簽章
    ///
    /// - Parameter container: 可捲動的容器
    /// - Returns: 格子數量與首尾格相對位置；框線無效時回傳無效簽章
    /// - Note: 只查首尾格並扣除容器上緣，避免對所有格子取框線或受 sheet 位移影響
    func categoryListSignature(in container: XCUIElement) -> String {
        let prefix = BLAccessibilityID.Orders.categoryCell("")
        let cells = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", prefix)
        )
        let count = cells.count
        guard let containerFrame = currentFrame(of: container) else {
            return "\(count)|invalid"
        }
        guard count > 0 else {
            return "0"
        }
        guard let first = currentFrame(of: cells.element(boundBy: 0)) else {
            return "\(count)|invalid"
        }
        guard let last = currentFrame(of: cells.element(boundBy: count - 1)) else {
            return "\(count)|invalid"
        }
        let firstOffset = first.minY - containerFrame.minY
        let lastOffset = last.minY - containerFrame.minY
        return "\(count)|\(firstOffset)|\(lastOffset)"
    }

    /// 取得元素的有效框線，元素不存在、讀取失敗或框線無效時回傳 `nil`
    ///
    /// - Parameter element: 要讀取的元素
    /// - Returns: 有效的框線；取不到時為 `nil`
    /// - Note: 不先以 `exists` 判斷再讀 `frame`，兩次查詢之間元素可能被回收，會讓 `XCTest` 記錄失敗
    func currentFrame(of element: XCUIElement) -> CGRect? {
        let snapshot = try? element.snapshot() // 失敗可忽略，因為元素不存在時取不到框線
        guard let snapshot else {
            return nil
        }
        return isValidFrame(snapshot.frame) ? snapshot.frame : nil
    }

    /// 判斷框線是否可用於比較，排除空、無限大與非有限座標的框線
    ///
    /// - Parameter frame: 要檢查的框線
    /// - Returns: 框線是否有效
    func isValidFrame(_ frame: CGRect) -> Bool {
        !frame.isNull && !frame.isInfinite && !frame.isEmpty
            && frame.minX.isFinite && frame.minY.isFinite
    }

    /// 等待類別清單的相對位置簽章連續兩次相同
    ///
    /// - Parameter container: 可捲動的容器
    /// - Returns: 十次取樣內的穩定簽章，逾時未穩定時為 `nil`
    /// - Note: 取樣間隔 0.15 秒，等待手勢造成的減速結束
    func waitForStableCategorySignature(in container: XCUIElement) -> String? {
        var previous = categoryListSignature(in: container)
        for _ in 1..<10 {
            RunLoop.current.run(until: Date.now.addingTimeInterval(0.15))
            let current = categoryListSignature(in: container)
            if current.hasSuffix("|invalid") {
                previous = current
                continue
            }
            if current == previous {
                return current
            }
            previous = current
        }
        return nil
    }

    /// 輪詢元素的框線，連續兩次讀到相同且有效的框線即視為慣性已停止
    ///
    /// - Parameters:
    ///   - element: 要觀察的元素
    ///   - maxReads: 最多讀取框線的次數
    /// - Returns: 框線是否在上限內穩定
    /// - Note: 每次讀取框線都要查詢可及性樹，大清單下單次約數秒，因此以讀取次數而非牆鐘時間為上限
    func waitUntilFrameStable(_ element: XCUIElement, maxReads: Int = 10) -> Bool {
        var previous: CGRect?
        var stableReads = 0
        for _ in 0..<maxReads {
            if let current = currentFrame(of: element) {
                if current == previous {
                    stableReads += 1
                    if stableReads >= 2 {
                        return true
                    }
                } else {
                    stableReads = 0
                }
                previous = current
            }
            _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: 0.1)
        }
        return false
    }

    /// 判斷元素是否完整落在導覽列下緣與容器下緣之間
    ///
    /// - Parameters:
    ///   - element: 要判斷的元素
    ///   - container: 元素所在的 sheet
    /// - Returns: 元素是否在可點範圍內
    func isInVisibleBand(_ element: XCUIElement, within container: XCUIElement) -> Bool {
        guard let frame = currentFrame(of: element) else {
            return false
        }
        guard let containerFrame = currentFrame(of: container) else {
            return false
        }
        let top = visibleTopEdge(in: containerFrame)
        return frame.minY >= top && frame.maxY <= containerFrame.maxY
    }

    /// 取得容器內可點範圍的上緣，有位於容器上半部的導覽列時為其下緣，否則為容器上緣
    ///
    /// - Parameter containerFrame: 已通過 `isValidFrame` 的容器框線
    /// - Returns: 可點範圍的上緣座標
    /// - Note: 導覽列不是容器的子孫，因此從 App 的導覽列中以位置挑選
    func visibleTopEdge(in containerFrame: CGRect) -> CGFloat {
        var top = containerFrame.minY
        for bar in app.navigationBars.allElementsBoundByIndex {
            guard let frame = currentFrame(of: bar) else {
                continue
            }
            let isOverlapping = frame.minX < containerFrame.maxX && frame.maxX > containerFrame.minX
            let isInUpperHalf = frame.midY >= containerFrame.minY
                && frame.midY < containerFrame.midY
            if isOverlapping && isInUpperHalf {
                top = max(top, frame.maxY)
            }
        }
        return top
    }

    /// 輕拖容器一次，元素在可點範圍上方時向下拖，否則向上拖
    ///
    /// - Parameters:
    ///   - element: 要露出的元素
    ///   - container: 元素所在的 sheet
    func dragToward(_ element: XCUIElement, within container: XCUIElement) {
        guard let frame = currentFrame(of: element) else {
            return
        }
        guard let containerFrame = currentFrame(of: container) else {
            return
        }
        let isAboveBand = frame.minY < visibleTopEdge(in: containerFrame)
        let startY: CGFloat = isAboveBand ? 0.3 : 0.7
        let start = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: startY))
        let end = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)
    }
}
