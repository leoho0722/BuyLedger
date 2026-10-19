//
//  OrderFilterSheetTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/18.
//

import XCTest

/// compact 版面整合篩選 sheet 的分類多選、套用、下滑、捨棄確認與搜尋流程測試
///
/// - Note: 種子為 `categoryFilter`
/// - Note: 本月、信用卡、類別美妝與書籍的結果為 4 筆，不限條件為 10 筆
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

    /// 同一列點兩格後兩格都被選取，同列的其他格與其他組不受影響
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    @MainActor
    func testFilterSheetCategoryCells_同列點兩格_兩格都被選取且其他格不變() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isCompactLayout(app), "篩選 sheet 只存在於 compact 版面，regular 版面改由類別選擇器測試覆蓋")
        let orders = openOrders(app)
        orders.openFilterSheet()

        // When
        orders.tapFilterCategory("3C")
        orders.tapFilterCategory("美妝")

        // Then
        assertCategorySelected("3C", isSelected: true, orders)
        assertCategorySelected("美妝", isSelected: true, orders)
        assertCategorySelected("零食", isSelected: false, orders)
    }

    /// 同一列的兩格都選取後，再點其中一格取消，只保留另一格
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    @MainActor
    func testFilterSheetCategoryCells_再點其中一格取消_只保留另一格() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isCompactLayout(app), "篩選 sheet 只存在於 compact 版面，regular 版面改由類別選擇器測試覆蓋")
        let orders = openOrders(app)
        orders.openFilterSheet()
        orders.tapFilterCategory("3C")
        orders.tapFilterCategory("美妝")

        // When
        orders.tapFilterCategory("3C")

        // Then
        assertCategorySelected("3C", isSelected: false, orders)
        assertCategorySelected("美妝", isSelected: true, orders)
    }

    /// 本月、信用卡、類別美妝與書籍，展開已收單後套用，觸發鈕為兩項且清單列出四筆
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    @MainActor
    func testFilterSheetApply_本月信用卡與兩類別_觸發鈕顯示兩項且結果為四筆() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isCompactLayout(app), "篩選 sheet 只存在於 compact 版面，regular 版面改由類別選擇器測試覆蓋")
        let orders = openOrders(app)
        orders.openFilterSheet()
        orders.selectFilterDatePeriod("thisMonth")
        orders.selectFilterPaymentMethod("信用卡")
        orders.tapFilterCategory("美妝")
        if orders.filterGroupValue("closed") != "已收合" {
            app.failWithDiagnostics("前提不成立：已收單組開啟時應為已收合")
        }

        // When
        orders.tapFilterGroupHeader("closed")
        orders.tapFilterCategory("書籍")
        orders.tapFilterApply()

        // Then
        assertTrigger(orders, contains: "2 項類別")
        assertListedOrderIDs(Self.filteredOrderIDs, orders)
    }

    /// 選日期後點清除篩選再套用，觸發鈕回到全部且清單列出全部 10 筆
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    @MainActor
    func testFilterSheetClearThenApply_清除後套用_回到全部() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isCompactLayout(app), "篩選 sheet 只存在於 compact 版面，regular 版面改由類別選擇器測試覆蓋")
        let orders = openOrders(app)
        orders.openFilterSheet()
        orders.selectFilterDatePeriod("thisMonth")

        // When
        orders.tapFilterClear()
        orders.tapFilterApply()

        // Then
        assertTrigger(orders, contains: "全部")
        assertListedOrderIDs(Self.allOrderIDs, orders)
    }

    /// 有未套用變更時下滑不關閉，且暫存的日期選擇保留到套用
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    @MainActor
    func testFilterSheetSwipeDown_有未套用變更_不關閉且保留選取() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isCompactLayout(app), "篩選 sheet 只存在於 compact 版面，regular 版面改由類別選擇器測試覆蓋")
        let orders = openOrders(app)
        orders.openFilterSheet()
        orders.selectFilterDatePeriod("thisMonth")

        // When
        let isBlocked = orders.filterSheetBlocksSwipeDismiss()
        orders.tapFilterApply()

        // Then
        if !isBlocked {
            app.failWithDiagnostics("有未套用變更時下滑不應關閉 sheet")
        }
        assertTrigger(orders, contains: "本月")
    }

    /// 沒有變更時下滑可關閉；選後再切回原狀，也視為沒有變更
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    @MainActor
    func testFilterSheetSwipeDown_無變更或切回原狀_可關閉() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isCompactLayout(app), "篩選 sheet 只存在於 compact 版面，regular 版面改由類別選擇器測試覆蓋")
        let orders = openOrders(app)
        orders.openFilterSheet()

        // When
        let isDismissedWithoutChange = orders.dismissFilterSheetBySwipe()
        orders.openFilterSheet()
        orders.tapFilterCategory("美妝")
        orders.tapFilterCategory("美妝")
        let isDismissedAfterToggleBack = orders.dismissFilterSheetBySwipe()

        // Then
        if !isDismissedWithoutChange {
            app.failWithDiagnostics("沒有變更時下滑應關閉 sheet")
        }
        if !isDismissedAfterToggleBack {
            app.failWithDiagnostics("選後再切回原狀，下滑應關閉 sheet")
        }
    }

    /// 取消有變更的 sheet，捨棄確認選繼續編輯後 sheet 保持開啟
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    @MainActor
    func testFilterSheetDiscard_繼續編輯_留在篩選畫面() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isCompactLayout(app), "篩選 sheet 只存在於 compact 版面，regular 版面改由類別選擇器測試覆蓋")
        let orders = openOrders(app)
        orders.openFilterSheet()
        orders.selectFilterDatePeriod("thisMonth")

        // When
        orders.tapFilterCancel()
        orders.tapDiscardKeepEditing()
        let isSheetKept = orders.filterSheet.exists
        orders.tapFilterApply()

        // Then
        if !isSheetKept {
            app.failWithDiagnostics("選繼續編輯後 sheet 應保持開啟")
        }
        assertTrigger(orders, contains: "本月")
    }

    /// 輸入搜尋文字後只留相符類別
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    @MainActor
    func testFilterSheetSearch_輸入文字_只留相符類別() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isCompactLayout(app), "篩選 sheet 只存在於 compact 版面，regular 版面改由類別選擇器測試覆蓋")
        let orders = openOrders(app)
        orders.openFilterSheet()

        // When
        orders.typeFilterSearch("食")

        // Then
        let isTyped = orders.filterSearchFieldValue == "食"
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

    /// 清除搜尋後恢復全部類別
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    @MainActor
    func testFilterSheetSearch_清除搜尋_恢復全部類別() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isCompactLayout(app), "篩選 sheet 只存在於 compact 版面，regular 版面改由類別選擇器測試覆蓋")
        let orders = openOrders(app)
        orders.openFilterSheet()
        orders.typeFilterSearch("食")

        // When
        orders.tapFilterClearSearch()

        // Then
        let isRestored = orders.revealFilterCategory("美妝")
        if !isRestored || orders.hasFilterSearchText {
            app.failWithDiagnostics("清除搜尋後應恢復美妝且搜尋欄為空")
        }
    }
}
