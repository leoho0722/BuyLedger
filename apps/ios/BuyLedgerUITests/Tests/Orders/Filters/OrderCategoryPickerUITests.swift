//
//  OrderCategoryPickerUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/18.
//

import XCTest

/// regular 版面類別選擇器流程 UI 測試
/// 涵蓋多選、下滑、捨棄確認與搜尋
///
/// - Note: 只在 regular 版面執行
/// - Note: 種子為 `categoryFilter`
@MainActor
final class OrderCategoryPickerUITests: BLUITestCase {

    // MARK: - Properties

    /// 3C 與美妝的篩選結果訂單編號 (3C 一筆、美妝五筆)
    private static let threeCAndBeautyOrderIDs: Set<String> = [
        "UITEST-CF-001",
        "UITEST-CF-002",
        "UITEST-CF-003",
        "UITEST-CF-006",
        "UITEST-CF-007",
        "UITEST-CF-010",
    ]

    /// 驗證 regular 版面類別選擇器同一列點 3C 與美妝後完成
    /// 類別觸發鈕顯示「類別：2 項」，清單列出六筆訂單
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testDoneTapped_同列點兩格並完成_觸發鈕顯示兩項() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilter))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(
            in: app
        ) == .regular, "compact 版面由篩選 sheet 測試覆蓋")
        let picker = OrderCategoryPickerScreen(app: app)
        try orders.openCategoryPicker()
        try picker.tapPickerCategory("3C")
        try picker.tapPickerCategory("美妝")

        // When
        try picker.tapPickerDone()

        // Then
        try OrdersUITestSupport.assertTrigger(
            label: orders.categoryTriggerLabel(),
            contains: "類別：2 項",
            in: app
        )
        try assertListedOrderIDs(Self.threeCAndBeautyOrderIDs, orders)
    }

    /// 驗證選取美妝後下滑，類別選擇器仍開啟且美妝仍為選中
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testCategoryPickerBlocksSwipeDismiss_有未套用變更_不關閉() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilter))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(
            in: app
        ) == .regular, "compact 版面由篩選 sheet 測試覆蓋")
        let picker = OrderCategoryPickerScreen(app: app)
        try orders.openCategoryPicker()
        try picker.tapPickerCategory("美妝")

        // When
        try picker.categoryPickerBlocksSwipeDismiss()

        // Then
        XCTAssertTrue(
            picker.categoryPickerSheet.exists,
            "有未套用變更時下滑不應關閉類別選擇器"
        )
        XCTAssertTrue(
            picker.isPickerCategorySelected("美妝"),
            "下滑後美妝選取狀態應保留"
        )
    }

    /// 驗證類別選擇器有變更時選繼續編輯
    /// 選擇器保持開啟且美妝仍為選中
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    ///   捨棄確認未呈現時丟出測試錯誤
    func testTapDiscardKeepEditing_類別選擇器捨棄確認選繼續編輯_留在選擇器()
        throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilter))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(
            in: app
        ) == .regular, "compact 版面由篩選 sheet 測試覆蓋")
        let picker = OrderCategoryPickerScreen(app: app)
        try orders.openCategoryPicker()
        try picker.tapPickerCategory("美妝")
        try picker.tapPickerCancel()
        try requireCondition(
            app.alertPresented(),
            in: app,
            "取消後捨棄確認未呈現"
        )

        // When
        try orders.tapDiscardKeepEditing()

        // Then
        XCTAssertTrue(
            picker.categoryPickerSheet.exists,
            "選繼續編輯後類別選擇器應保持開啟"
        )
        XCTAssertTrue(
            picker.isPickerCategorySelected("美妝"),
            "選繼續編輯後美妝應仍為選中"
        )
    }

    /// 驗證類別選擇器搜尋欄輸入「食」後收到該文字
    /// 相符的零食列顯示，不符的美妝列隱藏
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testTypePickerSearch_輸入文字_顯示相符並隱藏不符類別() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilter))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(
            in: app
        ) == .regular, "compact 版面由篩選 sheet 測試覆蓋")
        let picker = OrderCategoryPickerScreen(app: app)
        try orders.openCategoryPicker()

        // When
        try picker.typePickerSearch("食")

        // Then
        XCTAssertEqual(
            picker.categoryPickerSearchValue,
            "食",
            "選擇器搜尋欄應收到輸入「食」"
        )
        XCTAssertTrue(
            orders.filterCategoryCell("零食").waitForExistence(timeout: 5),
            "搜尋後應顯示零食"
        )
        XCTAssertFalse(orders.filterCategoryCell("美妝").exists, "搜尋後不應顯示美妝")
    }

    /// 驗證輸入「食」後清除搜尋
    /// 被篩掉的「美妝」恢復顯示，且搜尋欄為空
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testSearchClearTapped_清除搜尋_恢復被篩掉的類別並清空搜尋欄() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilter))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(
            in: app
        ) == .regular, "compact 版面由篩選 sheet 測試覆蓋")
        let picker = OrderCategoryPickerScreen(app: app)
        try orders.openCategoryPicker()
        try picker.typePickerSearch("食")

        // When
        try picker.tapPickerClearSearch()
        try orders.revealFilterCategory("美妝", within: picker.categoryPickerSheet)

        // Then
        XCTAssertTrue(orders.filterCategoryCell("美妝").exists, "清除搜尋後應恢復美妝")
        XCTAssertFalse(picker.hasCategoryPickerSearchText, "清除搜尋後搜尋欄應為空")
    }
}

