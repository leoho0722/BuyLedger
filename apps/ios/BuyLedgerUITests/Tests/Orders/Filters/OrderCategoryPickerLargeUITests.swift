//
//  OrderCategoryPickerLargeUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/18.
//

import XCTest

/// regular 版面大型類別選擇器的捲動選取與完成流程 UI 測試
///
/// - Note: 只在 regular 版面執行
/// - Note: 種子為 `categoryFilterLarge`
@MainActor
final class OrderCategoryPickerLargeUITests: BLUITestCase {

    /// 驗證 regular 版面選取末格與開團中類別後完成
    /// 觸發鈕顯示兩項且清單列出兩筆
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    ///   開啟選擇器時已收單組不是已收合狀態時丟出測試錯誤
    func testDoneTapped_捲到末格並選開團中類別_觸發鈕顯示兩項() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilterLarge))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(
            in: app
        ) == .regular, "compact 版面由篩選 sheet 測試覆蓋")
        let picker = OrderCategoryPickerScreen(app: app)
        try orders.openCategoryPicker()
        try requireCondition(
            try picker.pickerGroupValue("closed") == "已收合",
            in: app,
            "前提不成立：已收單組開啟時應為已收合"
        )
        try picker.tapPickerGroupHeader("closed")
        try picker.tapPickerCategory(OrdersSeedFixture.lastClosedCategory)
        try picker.tapPickerCategory(OrdersSeedFixture.ongoingCategory)

        // When
        try picker.tapPickerDone()

        // Then
        try OrdersUITestSupport.assertTrigger(
            label: orders.categoryTriggerLabel(),
            contains: "類別：2 項",
            in: app
        )
        try assertListedOrderIDs(OrdersSeedFixture.largeFilteredOrderIDs, orders)
    }
}
