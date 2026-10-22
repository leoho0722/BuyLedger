//
//  OrderCategoryPickerLargeTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/18.
//

import XCTest

/// regular 版面類別選擇器在大量類別下的捲動選取與完成流程測試
///
/// - Note: 只在 regular 版面執行
/// - Note: 種子為 `categoryFilterLarge`
final class OrderCategoryPickerLargeTests: BLUITestCase {

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

    /// 展開已收單、捲到末格並選取，再選一個開團中類別後完成，觸發鈕為兩項且清單列出兩筆
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    @MainActor
    func testCategoryPickerLargeApply_捲到末格並選開團中類別_觸發鈕顯示兩項() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilterLarge))
        try XCTSkipUnless(isRegularLayout(app), "類別選擇器只存在於 regular 版面，compact 版面由篩選 sheet 測試覆蓋")
        let orders = openOrders(app)
        orders.openCategoryPicker()
        if orders.pickerGroupValue("closed") != "已收合" {
            app.failWithDiagnostics("前提不成立：已收單組開啟時應為已收合")
        }

        // When
        orders.tapPickerGroupHeader("closed")
        orders.tapPickerCategory(Self.lastClosedCategory)
        orders.tapPickerCategory(Self.ongoingCategory)
        orders.tapPickerDone()

        // Then
        if !orders.categoryTriggerLabel.contains("類別：2 項") {
            app.failWithDiagnostics("類別觸發鈕應包含「類別：2 項」，實際為「\(orders.categoryTriggerLabel)」")
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

private extension OrderCategoryPickerLargeTests {

    /// 切到訂單分頁並等待清單就緒
    ///
    /// - Parameters:
    ///   - app: 已啟動的 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 訂單清單的 Page Object
    @MainActor
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
