//
//  OrderCategoryPickerTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/18.
//

import XCTest

/// regular 版面類別選擇器的多選、完成、下滑與捨棄確認、搜尋流程 UI 測試
///
/// - Note: 只在 regular 版面執行
/// - Note: 種子為 `categoryFilter`
@MainActor
final class OrderCategoryPickerTests: BLUITestCase {

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

    /// 驗證 regular 版面類別選擇器同一列點 3C 與美妝後完成，類別觸發鈕顯示「類別：2 項」，清單列出六筆訂單
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testCategoryPickerMultiSelect_同列點兩格並完成_觸發鈕顯示兩項() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isRegularLayout(app), "類別選擇器只存在於 regular 版面，compact 版面由篩選 sheet 測試覆蓋")
        let orders = openOrders(app)
        let picker = OrderCategoryPickerScreen(app: app)
        orders.openCategoryPicker()
        picker.tapPickerCategory("3C")
        picker.tapPickerCategory("美妝")

        // When
        picker.tapPickerDone()

        // Then
        assertTrigger(orders, contains: "類別：2 項")
        assertListedOrderIDs(Self.threeCAndBeautyOrderIDs, orders)
    }

    /// 驗證類別選擇器有未套用的變更時，下滑不會關閉選擇器
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testCategoryPickerSwipeDown_有未套用變更_不關閉() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isRegularLayout(app), "類別選擇器只存在於 regular 版面，compact 版面由篩選 sheet 測試覆蓋")
        let orders = openOrders(app)
        let picker = OrderCategoryPickerScreen(app: app)
        orders.openCategoryPicker()
        picker.tapPickerCategory("美妝")

        // When
        let isBlocked = picker.categoryPickerBlocksSwipeDismiss()

        // Then
        if !isBlocked {
            app.failWithDiagnostics("有未套用變更時下滑類別選擇器不應關閉")
        }
    }

    /// 驗證類別選擇器有變更時按取消，捨棄確認選「繼續編輯」後，選擇器保持開啟且「美妝」仍為選中
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面；捨棄確認未呈現時丟出測試錯誤
    func testCategoryPickerCancel_捨棄確認選繼續編輯_留在選擇器() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isRegularLayout(app), "類別選擇器只存在於 regular 版面，compact 版面由篩選 sheet 測試覆蓋")
        let orders = openOrders(app)
        let picker = OrderCategoryPickerScreen(app: app)
        orders.openCategoryPicker()
        picker.tapPickerCategory("美妝")
        picker.tapPickerCancel()
        try requireCondition(app.alertPresented(), in: app, "取消有變更的選擇器後捨棄確認未呈現")

        // When
        orders.tapDiscardKeepEditing()

        // Then
        if !picker.categoryPickerSheet.exists {
            app.failWithDiagnostics("選繼續編輯後類別選擇器應保持開啟")
        }
        if !picker.isPickerCategorySelected("美妝") {
            app.failWithDiagnostics("選繼續編輯後美妝應仍為選中")
        }
    }

    /// 驗證類別選擇器搜尋欄輸入「食」後收到該文字，相符的零食列顯示，不符的美妝列隱藏
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testCategoryPickerSearch_輸入文字_顯示相符並隱藏不符類別() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isRegularLayout(app), "類別選擇器只存在於 regular 版面，compact 版面由篩選 sheet 測試覆蓋")
        let orders = openOrders(app)
        let picker = OrderCategoryPickerScreen(app: app)
        orders.openCategoryPicker()

        // When
        picker.typePickerSearch("食")

        // Then
        let isTyped = picker.categoryPickerSearchValue == "食"
        let isMatchShown = orders.filterCategoryCell("零食").waitForExistence(timeout: 5)
        let isOtherHidden = !orders.filterCategoryCell("美妝").exists
        if !isTyped {
            app.failWithDiagnostics("選擇器搜尋欄未收到輸入「食」")
        }
        if !isMatchShown {
            app.failWithDiagnostics("搜尋「食」後應顯示零食")
        }
        if !isOtherHidden {
            app.failWithDiagnostics("搜尋「食」後不應顯示美妝")
        }
    }

    /// 驗證輸入「食」後清除搜尋，被篩掉的「美妝」恢復顯示，且搜尋欄為空
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testCategoryPickerSearch_清除搜尋_恢復被篩掉的類別並清空搜尋欄() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isRegularLayout(app), "類別選擇器只存在於 regular 版面，compact 版面由篩選 sheet 測試覆蓋")
        let orders = openOrders(app)
        let picker = OrderCategoryPickerScreen(app: app)
        orders.openCategoryPicker()
        picker.typePickerSearch("食")

        // When
        picker.tapPickerClearSearch()

        // Then
        let isRestored = orders.revealFilterCategory("美妝", within: picker.categoryPickerSheet)
        if !isRestored || picker.hasCategoryPickerSearchText {
            app.failWithDiagnostics("清除搜尋後應恢復美妝且搜尋欄為空")
        }
    }
}

// MARK: - Private Method

private extension OrderCategoryPickerTests {

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

    /// 斷言類別觸發鈕的標題包含指定片段
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
        if !orders.categoryTriggerLabel.contains(fragment) {
            orders.app.failWithDiagnostics(
                "類別觸發鈕標題應包含「\(fragment)」，實際為「\(orders.categoryTriggerLabel)」",
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
