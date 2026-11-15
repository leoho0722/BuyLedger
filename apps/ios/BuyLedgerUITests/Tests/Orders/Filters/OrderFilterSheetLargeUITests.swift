//
//  OrderFilterSheetLargeUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/18.
//

import XCTest

/// compact 版面整合篩選 sheet 的大量類別流程 UI 測試
/// 涵蓋展開、捲動選取與套用
///
/// - Note: 種子為 `categoryFilterLarge`
/// - Note: 300 個類別，類別 001 至 類別 005 屬開團中，其餘屬已收單
@MainActor
final class OrderFilterSheetLargeUITests: BLUITestCase {

    /// 驗證 compact 版面選取末格與開團中類別後套用
    /// 入口顯示兩項且清單列出兩筆
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    ///   開啟篩選 sheet 時已收單組不是已收合狀態時丟出測試錯誤
    func testFilterApplyTapped_展開已收單捲到末格_觸發鈕兩項且結果兩筆() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilterLarge))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(try ordersLayout(in: app) == .compact, "regular 版面由類別選擇器測試覆蓋")
        let filterSheet = try orders.openFilterSheet()
        try requireCondition(
            try filterSheet.filterGroupValue("closed") == "已收合",
            in: app,
            "前提不成立：已收單組開啟時應為已收合"
        )
        try filterSheet.tapFilterGroupHeader("closed")
        try filterSheet.tapFilterCategory(OrdersSeedFixture.lastClosedCategory)
        try filterSheet.tapFilterCategory(OrdersSeedFixture.ongoingCategory)

        // When
        try filterSheet.tapFilterApply()

        // Then
        try OrdersUITestSupport.assertTrigger(
            label: orders.filterTriggerLabel(),
            contains: "2 項類別",
            in: app
        )
        try assertListedOrderIDs(OrdersSeedFixture.largeFilteredOrderIDs, orders)
    }
}
