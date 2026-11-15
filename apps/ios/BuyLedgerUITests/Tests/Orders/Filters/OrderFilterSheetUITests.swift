//
//  OrderFilterSheetUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/18.
//

import XCTest

/// compact 版面整合篩選 sheet 流程 UI 測試
/// 涵蓋分類多選、套用、下滑、捨棄確認與搜尋
///
/// - Note: 種子為 `categoryFilter`
/// - Note: 本月、信用卡、類別美妝與書籍的結果為 4 筆，不限條件為 10 筆
@MainActor
final class OrderFilterSheetUITests: BLUITestCase {

    /// 驗證篩選 sheet 同一列點 3C 與美妝後，兩格都被選取，零食維持未選
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testFilterPendingCategoryToggled_同列點兩格_兩格都被選取且其他格不變() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilter))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(in: app) == .compact, "regular 版面由類別選擇器測試覆蓋")
        let filterSheet = try orders.openFilterSheet()
        try filterSheet.tapFilterCategory("3C")

        // When
        try filterSheet.tapFilterCategory("美妝")

        // Then
        assertCategorySelected("3C", isSelected: true, filterSheet)
        assertCategorySelected("美妝", isSelected: true, filterSheet)
        assertCategorySelected("零食", isSelected: false, filterSheet)
    }

    /// 驗證同一列的 3C 與美妝都選取後，再點 3C 取消，只保留美妝
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testFilterPendingCategoryToggled_再點其中一格取消_只保留另一格() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilter))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(in: app) == .compact, "regular 版面由類別選擇器測試覆蓋")
        let filterSheet = try orders.openFilterSheet()
        try filterSheet.tapFilterCategory("3C")
        try filterSheet.tapFilterCategory("美妝")

        // When
        try filterSheet.tapFilterCategory("3C")

        // Then
        assertCategorySelected("3C", isSelected: false, filterSheet)
        assertCategorySelected("美妝", isSelected: true, filterSheet)
    }

    /// 驗證選本月、信用卡與兩類別後套用
    /// 篩選入口顯示兩項且清單列出四筆
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    ///   開啟篩選 sheet 時已收單組不是已收合狀態時丟出測試錯誤
    func testFilterApplyTapped_本月信用卡與兩類別_觸發鈕顯示兩項且結果為四筆() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilter))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(in: app) == .compact, "regular 版面由類別選擇器測試覆蓋")
        let filterSheet = try orders.openFilterSheet()
        try filterSheet.selectFilterDatePeriod("thisMonth")
        try filterSheet.selectFilterPaymentMethod("信用卡")
        try filterSheet.tapFilterCategory("美妝")
        try requireCondition(
            try filterSheet.filterGroupValue("closed") == "已收合",
            in: app,
            "前提不成立：已收單組開啟時應為已收合"
        )
        try filterSheet.tapFilterGroupHeader("closed")
        try filterSheet.tapFilterCategory("書籍")

        // When
        try filterSheet.tapFilterApply()

        // Then
        try OrdersUITestSupport.assertTrigger(
            label: orders.filterTriggerLabel(),
            contains: "2 項類別",
            in: app
        )
        try assertListedOrderIDs(OrdersSeedFixture.filteredOrderIDs, orders)
    }

    /// 驗證選了本月日期後點清除篩選再套用
    /// 篩選入口回到「全部」且清單列出全部 10 筆
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    /// - Note: 清除只改同次編輯的暫存條件
    ///   須接著套用才能從清單結果確認清除已生效
    func testFilterClearTapped_清除後套用_回到全部() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilter))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(in: app) == .compact, "regular 版面由類別選擇器測試覆蓋")
        let filterSheet = try orders.openFilterSheet()
        try filterSheet.selectFilterDatePeriod("thisMonth")

        // When
        try filterSheet.tapFilterClear()
        try filterSheet.tapFilterApply()

        // Then
        try OrdersUITestSupport.assertTrigger(
            label: orders.filterTriggerLabel(),
            contains: "全部",
            in: app
        )
        try assertListedOrderIDs(OrdersSeedFixture.allOrderIDs, orders)
    }

    /// 驗證篩選 sheet 的值都是預設時，清除鈕為停用
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testFilterSheetTapped_值皆為預設_清除鈕停用() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilter))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(in: app) == .compact, "regular 版面由類別選擇器測試覆蓋")

        // When
        let filterSheet = try orders.openFilterSheet()

        // Then
        let isEnabled = try filterSheet.isFilterClearEnabled(file: #filePath, line: #line)
        try requireCondition(!isEnabled, in: app, "值皆為預設時清除鈕應停用")
    }

    /// 驗證篩選 sheet 有未套用變更時下滑不會關閉
    /// 之後套用時暫存的「本月」日期選擇仍保留
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    /// - Note: 下滑後套用同次暫存條件
    ///   後續清單結果用來確認原選擇未遺失
    func testFilterSheetBlocksSwipeDismiss_有未套用變更_不關閉且保留選取() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilter))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(in: app) == .compact, "regular 版面由類別選擇器測試覆蓋")
        let filterSheet = try orders.openFilterSheet()
        try filterSheet.selectFilterDatePeriod("thisMonth")

        // When
        try filterSheet.filterSheetBlocksSwipeDismiss()
        let isBlocked = filterSheet.filterSheet.exists
        try requireCondition(isBlocked, in: app, "有未套用變更時下滑不應關閉 sheet")
        try filterSheet.tapFilterApply()

        // Then
        try OrdersUITestSupport.assertTrigger(
            label: orders.filterTriggerLabel(),
            contains: "本月",
            in: app
        )
    }

    /// 驗證篩選 sheet 沒有變更時，下滑後 sheet 已關閉
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testDismissFilterSheetBySwipe_無變更_可關閉() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilter))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(in: app) == .compact, "regular 版面由類別選擇器測試覆蓋")
        let filterSheet = try orders.openFilterSheet()

        // When
        try filterSheet.dismissFilterSheetBySwipe()
        let isDismissed = !filterSheet.filterSheet.exists

        // Then
        XCTAssertTrue(isDismissed, "沒有變更時下滑應關閉 sheet")
    }

    /// 驗證選了「美妝」後再點一次切回未選中
    /// 視為沒有變更，下滑可關閉篩選 sheet
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    ///   切回原狀後美妝仍為選中時丟出測試錯誤
    func testDismissFilterSheetBySwipe_選後再切回原狀_可關閉() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilter))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(in: app) == .compact, "regular 版面由類別選擇器測試覆蓋")
        let filterSheet = try orders.openFilterSheet()
        try filterSheet.tapFilterCategory("美妝")
        try filterSheet.tapFilterCategory("美妝")
        try requireCondition(!filterSheet.isFilterCategorySelected("美妝"), in: app, "再點一次後美妝應回到未選中")

        // When
        try filterSheet.dismissFilterSheetBySwipe()
        let isDismissed = !filterSheet.filterSheet.exists

        // Then
        XCTAssertTrue(isDismissed, "選後再切回原狀，下滑應關閉 sheet")
    }

    /// 驗證篩選 sheet 有變更時按取消，再選「繼續編輯」
    /// sheet 保持開啟，暫存的「本月」仍可套用
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    ///   捨棄確認未呈現時丟出測試錯誤
    /// - Note: 選繼續編輯後套用同次暫存條件
    ///   後續清單結果用來確認暫存日期未被捨棄
    func testTapDiscardKeepEditing_篩選捨棄確認選繼續編輯_留在篩選畫面() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilter))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(in: app) == .compact, "regular 版面由類別選擇器測試覆蓋")
        let filterSheet = try orders.openFilterSheet()
        try filterSheet.selectFilterDatePeriod("thisMonth")
        try filterSheet.tapFilterCancel()
        try requireCondition(app.alertPresented(), in: app, "取消後捨棄確認未呈現")

        // When
        try orders.tapDiscardKeepEditing()
        try requireCondition(filterSheet.filterSheet.exists, in: app, "選繼續編輯後 sheet 應保持開啟")
        try filterSheet.tapFilterApply()

        // Then
        try OrdersUITestSupport.assertTrigger(
            label: orders.filterTriggerLabel(),
            contains: "本月",
            in: app
        )
    }

    /// 驗證篩選 sheet 搜尋欄輸入「食」後收到該文字
    /// 相符的零食列顯示，不符的美妝列隱藏
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testTypeFilterSearch_輸入文字_顯示相符並隱藏不符類別() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilter))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(in: app) == .compact, "regular 版面由類別選擇器測試覆蓋")
        let filterSheet = try orders.openFilterSheet()

        // When
        try filterSheet.typeFilterSearch("食")

        // Then
        XCTAssertEqual(filterSheet.filterSearchFieldValue, "食", "搜尋欄應收到輸入「食」")
        XCTAssertTrue(orders.filterCategoryCell("零食").waitForExistence(timeout: 5), "搜尋後應顯示零食")
        XCTAssertFalse(orders.filterCategoryCell("美妝").exists, "搜尋後不應顯示美妝")
    }

    /// 驗證篩選 sheet 輸入「食」後清除搜尋
    /// 被篩掉的「美妝」恢復顯示，且搜尋欄為空
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testFilterSearchClearTapped_清除搜尋_恢復被篩掉的類別並清空搜尋欄() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilter))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(in: app) == .compact, "regular 版面由類別選擇器測試覆蓋")
        let filterSheet = try orders.openFilterSheet()
        try filterSheet.typeFilterSearch("食")

        // When
        try filterSheet.tapFilterClearSearch()
        try orders.revealFilterCategory("美妝")

        // Then
        XCTAssertTrue(orders.filterCategoryCell("美妝").exists, "清除搜尋後應恢復美妝")
        XCTAssertFalse(filterSheet.hasFilterSearchText, "清除搜尋後搜尋欄應為空")
    }
}

// MARK: - Private Method

private extension OrderFilterSheetUITests {

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
}
