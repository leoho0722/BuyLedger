//
//  OrderFilterSheetTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/18.
//

import XCTest

/// compact 版面整合篩選 sheet 的分類多選、套用、下滑、捨棄確認與搜尋流程 UI 測試
///
/// - Note: 種子為 `categoryFilter`
/// - Note: 本月、信用卡、類別美妝與書籍的結果為 4 筆，不限條件為 10 筆
@MainActor
final class OrderFilterSheetTests: BLUITestCase {

    // MARK: - Properties

    /// 本月、信用卡、類別美妝與書籍的篩選結果訂單編號
    private static let filteredOrderIDs: Set<String> = [
        "UITEST-CF-001",
        "UITEST-CF-004",
        "UITEST-CF-007",
        "UITEST-CF-010",
    ]

    /// 種子的全部 10 筆訂單編號
    private static let allOrderIDs: Set<String> = [
        "UITEST-CF-001",
        "UITEST-CF-002",
        "UITEST-CF-003",
        "UITEST-CF-004",
        "UITEST-CF-005",
        "UITEST-CF-006",
        "UITEST-CF-007",
        "UITEST-CF-008",
        "UITEST-CF-009",
        "UITEST-CF-010",
    ]

    /// 驗證篩選 sheet 同一列點 3C 與美妝後，兩格都被選取，零食維持未選
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testFilterSheetCategoryCells_同列點兩格_兩格都被選取且其他格不變() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isCompactLayout(app), "篩選 sheet 只存在於 compact 版面，regular 版面改由類別選擇器測試覆蓋")
        let orders = openOrders(app)
        let filterSheet = OrderFilterSheetScreen(app: app)
        orders.openFilterSheet()
        filterSheet.tapFilterCategory("3C")

        // When
        filterSheet.tapFilterCategory("美妝")

        // Then
        assertCategorySelected("3C", isSelected: true, filterSheet)
        assertCategorySelected("美妝", isSelected: true, filterSheet)
        assertCategorySelected("零食", isSelected: false, filterSheet)
    }

    /// 驗證同一列的 3C 與美妝都選取後，再點 3C 取消，只保留美妝
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testFilterSheetCategoryCells_再點其中一格取消_只保留另一格() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isCompactLayout(app), "篩選 sheet 只存在於 compact 版面，regular 版面改由類別選擇器測試覆蓋")
        let orders = openOrders(app)
        let filterSheet = OrderFilterSheetScreen(app: app)
        orders.openFilterSheet()
        filterSheet.tapFilterCategory("3C")
        filterSheet.tapFilterCategory("美妝")

        // When
        filterSheet.tapFilterCategory("3C")

        // Then
        assertCategorySelected("3C", isSelected: false, filterSheet)
        assertCategorySelected("美妝", isSelected: true, filterSheet)
    }

    /// 驗證選本月、信用卡與美妝，展開已收單再選書籍後套用，篩選入口顯示「2 項類別」且清單列出四筆訂單
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面；開啟篩選 sheet 時已收單組不是已收合狀態時丟出測試錯誤
    func testFilterSheetApply_本月信用卡與兩類別_觸發鈕顯示兩項且結果為四筆() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isCompactLayout(app), "篩選 sheet 只存在於 compact 版面，regular 版面改由類別選擇器測試覆蓋")
        let orders = openOrders(app)
        let filterSheet = OrderFilterSheetScreen(app: app)
        orders.openFilterSheet()
        filterSheet.selectFilterDatePeriod("thisMonth")
        filterSheet.selectFilterPaymentMethod("信用卡")
        filterSheet.tapFilterCategory("美妝")
        try requireCondition(
            filterSheet.filterGroupValue("closed") == "已收合",
            in: app,
            "前提不成立：已收單組開啟時應為已收合"
        )
        filterSheet.tapFilterGroupHeader("closed")
        filterSheet.tapFilterCategory("書籍")

        // When
        filterSheet.tapFilterApply()

        // Then
        assertTrigger(orders, contains: "2 項類別")
        assertListedOrderIDs(Self.filteredOrderIDs, orders)
    }

    /// 驗證選了本月日期後點清除篩選再套用，篩選入口回到「全部」且清單列出全部 10 筆
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    /// - Note: 清除只改同次編輯的暫存條件，須接著套用才能從清單結果確認清除已生效
    func testFilterSheetClearThenApply_清除後套用_回到全部() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isCompactLayout(app), "篩選 sheet 只存在於 compact 版面，regular 版面改由類別選擇器測試覆蓋")
        let orders = openOrders(app)
        let filterSheet = OrderFilterSheetScreen(app: app)
        orders.openFilterSheet()
        filterSheet.selectFilterDatePeriod("thisMonth")

        // When
        filterSheet.tapFilterClear()
        filterSheet.tapFilterApply()

        // Then
        assertTrigger(orders, contains: "全部")
        assertListedOrderIDs(Self.allOrderIDs, orders)
    }

    /// 驗證篩選 sheet 有未套用的變更時下滑不會關閉，之後套用時暫存的「本月」日期選擇仍保留
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    /// - Note: 下滑後套用同次暫存條件，後續清單結果用來確認阻擋關閉時未遺失原選擇
    func testFilterSheetSwipeDown_有未套用變更_不關閉且保留選取() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isCompactLayout(app), "篩選 sheet 只存在於 compact 版面，regular 版面改由類別選擇器測試覆蓋")
        let orders = openOrders(app)
        let filterSheet = OrderFilterSheetScreen(app: app)
        orders.openFilterSheet()
        filterSheet.selectFilterDatePeriod("thisMonth")

        // When
        let isBlocked = filterSheet.filterSheetBlocksSwipeDismiss()
        filterSheet.tapFilterApply()

        // Then
        if !isBlocked {
            app.failWithDiagnostics("有未套用變更時下滑不應關閉 sheet")
        }
        assertTrigger(orders, contains: "本月")
    }

    /// 驗證篩選 sheet 沒有變更時，下滑可以關閉
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testFilterSheetSwipeDown_無變更_可關閉() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isCompactLayout(app), "篩選 sheet 只存在於 compact 版面，regular 版面改由類別選擇器測試覆蓋")
        let orders = openOrders(app)
        let filterSheet = OrderFilterSheetScreen(app: app)
        orders.openFilterSheet()

        // When
        let isDismissed = filterSheet.dismissFilterSheetBySwipe()

        // Then
        if !isDismissed {
            app.failWithDiagnostics("沒有變更時下滑應關閉 sheet")
        }
    }

    /// 驗證選了「美妝」後再點一次切回未選中，視為沒有變更，下滑可關閉篩選 sheet
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面；切回原狀後美妝仍為選中時丟出測試錯誤
    func testFilterSheetSwipeDown_選後再切回原狀_可關閉() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isCompactLayout(app), "篩選 sheet 只存在於 compact 版面，regular 版面改由類別選擇器測試覆蓋")
        let orders = openOrders(app)
        let filterSheet = OrderFilterSheetScreen(app: app)
        orders.openFilterSheet()
        filterSheet.tapFilterCategory("美妝")
        filterSheet.tapFilterCategory("美妝")
        try requireCondition(!filterSheet.isFilterCategorySelected("美妝"), in: app, "再點一次後美妝應回到未選中")

        // When
        let isDismissed = filterSheet.dismissFilterSheetBySwipe()

        // Then
        if !isDismissed {
            app.failWithDiagnostics("選後再切回原狀，下滑應關閉 sheet")
        }
    }

    /// 驗證篩選 sheet 有變更時按取消，捨棄確認選「繼續編輯」後，sheet 保持開啟，暫存的「本月」仍可套用
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面；捨棄確認未呈現時丟出測試錯誤
    /// - Note: 選繼續編輯後套用同次暫存條件，後續清單結果用來確認暫存日期未被捨棄
    func testFilterSheetDiscard_繼續編輯_留在篩選畫面() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isCompactLayout(app), "篩選 sheet 只存在於 compact 版面，regular 版面改由類別選擇器測試覆蓋")
        let orders = openOrders(app)
        let filterSheet = OrderFilterSheetScreen(app: app)
        orders.openFilterSheet()
        filterSheet.selectFilterDatePeriod("thisMonth")
        filterSheet.tapFilterCancel()
        try requireCondition(app.alertPresented(), in: app, "取消有變更的 sheet 後捨棄確認未呈現")

        // When
        orders.tapDiscardKeepEditing()

        // Then
        if !filterSheet.filterSheet.exists {
            app.failWithDiagnostics("選繼續編輯後 sheet 應保持開啟")
        }
        filterSheet.tapFilterApply()
        assertTrigger(orders, contains: "本月")
    }

    /// 驗證篩選 sheet 搜尋欄輸入「食」後收到該文字，相符的零食列顯示，不符的美妝列隱藏
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testFilterSheetSearch_輸入文字_顯示相符並隱藏不符類別() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isCompactLayout(app), "篩選 sheet 只存在於 compact 版面，regular 版面改由類別選擇器測試覆蓋")
        let orders = openOrders(app)
        let filterSheet = OrderFilterSheetScreen(app: app)
        orders.openFilterSheet()

        // When
        filterSheet.typeFilterSearch("食")

        // Then
        let isTyped = filterSheet.filterSearchFieldValue == "食"
        let isMatchShown = orders.filterCategoryCell("零食").waitForExistence(timeout: 5)
        let isOtherHidden = !orders.filterCategoryCell("美妝").exists
        if !isTyped {
            app.failWithDiagnostics("搜尋欄未收到輸入「食」")
        }
        if !isMatchShown {
            app.failWithDiagnostics("搜尋「食」後應顯示零食")
        }
        if !isOtherHidden {
            app.failWithDiagnostics("搜尋「食」後不應顯示美妝")
        }
    }

    /// 驗證篩選 sheet 輸入「食」後清除搜尋，被篩掉的「美妝」恢復顯示，且搜尋欄為空
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testFilterSheetSearch_清除搜尋_恢復被篩掉的類別並清空搜尋欄() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isCompactLayout(app), "篩選 sheet 只存在於 compact 版面，regular 版面改由類別選擇器測試覆蓋")
        let orders = openOrders(app)
        let filterSheet = OrderFilterSheetScreen(app: app)
        orders.openFilterSheet()
        filterSheet.typeFilterSearch("食")

        // When
        filterSheet.tapFilterClearSearch()

        // Then
        let isRestored = orders.revealFilterCategory("美妝")
        if !isRestored || filterSheet.hasFilterSearchText {
            app.failWithDiagnostics("清除搜尋後應恢復美妝且搜尋欄為空")
        }
    }
}

// MARK: - Private Method

private extension OrderFilterSheetTests {

    /// 切到訂單分頁並等待清單就緒
    ///
    /// - Parameters:
    ///   - app: 已啟動的 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 訂單清單的 Page Object
    func openOrders(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OrdersScreen {
        let root = RootNavigationScreen(app: app)
        if !root.goToOrders(file: file, line: line) {
            app.failWithDiagnostics("切到訂單分頁後畫面未就緒", file: file, line: line)
        }
        let orders = OrdersScreen(app: app)
        if !orders.waitUntilReady() {
            app.failWithDiagnostics("訂單清單根 identifier 逾時仍未出現", file: file, line: line)
        }
        return orders
    }

    /// 斷言篩選 sheet 內指定類別的選中狀態
    ///
    /// - Parameters:
    ///   - name: 類別名稱
    ///   - isSelected: 預期是否選中
    ///   - filterSheet: 篩選 sheet 的 Page Object
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func assertCategorySelected(
        _ name: String,
        isSelected: Bool,
        _ filterSheet: OrderFilterSheetScreen,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if filterSheet.isFilterCategorySelected(name) != isSelected {
            filterSheet.app.failWithDiagnostics(
                "類別「\(name)」選中狀態應為 \(isSelected)",
                file: file,
                line: line
            )
        }
    }

    /// 斷言篩選入口的標題包含指定片段
    ///
    /// - Parameters:
    ///   - orders: 訂單清單的 Page Object
    ///   - fragment: 預期包含的文字
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func assertTrigger(
        _ orders: OrdersScreen,
        contains fragment: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if !orders.filterTriggerLabel.contains(fragment) {
            orders.app.failWithDiagnostics(
                "篩選入口標題應包含「\(fragment)」，實際為「\(orders.filterTriggerLabel)」",
                file: file,
                line: line
            )
        }
    }

    /// 斷言清單實際列出的訂單編號與預期集合相同
    ///
    /// - Parameters:
    ///   - expected: 預期列出的訂單編號
    ///   - orders: 訂單清單的 Page Object
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    func assertListedOrderIDs(
        _ expected: Set<String>,
        _ orders: OrdersScreen,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let listed = orders.collectListedOrderIDs()
        if listed != expected {
            orders.app.failWithDiagnostics(
                "清單應列出 \(expected.sorted())，實際為 \(listed.sorted())",
                file: file,
                line: line
            )
        }
    }
}
