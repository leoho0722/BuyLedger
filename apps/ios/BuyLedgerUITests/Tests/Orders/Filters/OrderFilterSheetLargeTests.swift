//
//  OrderFilterSheetLargeTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/18.
//

import XCTest

/// compact 版面整合篩選 sheet 在大量類別下的展開、捲動選取與套用流程 UI 測試
///
/// - Note: 種子為 `categoryFilterLarge`
/// - Note: 300 個類別，類別 001 至 類別 005 屬開團中，其餘屬已收單
@MainActor
final class OrderFilterSheetLargeTests: BLUITestCase {

    // MARK: - Properties

    /// 開團中的首個類別，對應訂單「UITEST-CFL-001」
    private static let ongoingCategory = "類別 001"

    /// 已收單的末個類別，對應訂單「UITEST-CFL-300」
    private static let lastClosedCategory = "類別 300"

    /// 兩個選取類別的篩選結果訂單編號
    private static let filteredOrderIDs: Set<String> = [
        "UITEST-CFL-001",
        "UITEST-CFL-300",
    ]

    /// 驗證 compact 版面的篩選 sheet 展開已收單、捲到末格並選取，再選一個開團中類別後套用，篩選入口顯示「2 項類別」且清單列出兩筆訂單
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面；開啟篩選 sheet 時已收單組不是已收合狀態時丟出測試錯誤
    func testFilterSheetLargeApply_展開已收單捲到末格_觸發鈕兩項且結果兩筆() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilterLarge))
        try XCTSkipUnless(isCompactLayout(app), "篩選 sheet 只存在於 compact 版面，regular 版面改由類別選擇器測試覆蓋")
        let orders = openOrders(app)
        let filterSheet = OrderFilterSheetScreen(app: app)
        orders.openFilterSheet()
        try requireCondition(
            filterSheet.filterGroupValue("closed") == "已收合",
            in: app,
            "前提不成立：已收單組開啟時應為已收合"
        )
        filterSheet.tapFilterGroupHeader("closed")
        filterSheet.tapFilterCategory(Self.lastClosedCategory)
        filterSheet.tapFilterCategory(Self.ongoingCategory)

        // When
        filterSheet.tapFilterApply()

        // Then
        if !orders.filterTriggerLabel.contains("2 項類別") {
            app.failWithDiagnostics("篩選入口標題應包含「2 項類別」，實際為「\(orders.filterTriggerLabel)」")
        }
        let listed = orders.collectListedOrderIDs()
        if listed != Self.filteredOrderIDs {
            app.failWithDiagnostics(
                "清單應列出 \(Self.filteredOrderIDs.sorted())，實際為 \(listed.sorted())"
            )
        }
    }
}

// MARK: - Private Method

private extension OrderFilterSheetLargeTests {

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
}
