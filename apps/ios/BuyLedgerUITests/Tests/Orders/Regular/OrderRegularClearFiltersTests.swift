//
//  OrderRegularClearFiltersTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/18.
//

import XCTest

/// regular 版面清除篩選的 UI 流程測試，涵蓋清除後付款方式、類別與日期回到預設、狀態篩選維持，以及無條件時按鈕停用
///
/// - Note: 只在 regular 版面執行
/// - Note: 種子為 `categoryFilter`
@MainActor
final class OrderRegularClearFiltersTests: BLUITestCase {

    // MARK: - Properties

    /// 種子的全部 10 筆訂單編號，狀態皆為已確認
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

    /// 已確認狀態篩選的 `filterID`
    private static let confirmedFilterID = "confirmed"

    /// 驗證狀態選已確認、付款選信用卡、日期選本月、類別選兩項後清除，付款、類別與日期回到預設，狀態仍維持已確認
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testRegularClearFilters_有篩選條件_三項回到預設且狀態維持() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isRegularLayout(app), "清除篩選按鈕只存在於 regular 版面，compact 版面由篩選 sheet 測試覆蓋")
        let orders = openOrders(app)
        let picker = OrderCategoryPickerScreen(app: app)
        orders.selectStatusChip(filterID: Self.confirmedFilterID)
        orders.selectPaymentMethodInRegularLayout("信用卡")
        orders.selectRegularDateChip("thisMonth")
        orders.openCategoryPicker()
        picker.tapPickerCategory("3C")
        picker.tapPickerCategory("美妝")
        picker.tapPickerDone()
        if !orders.isRegularClearFiltersEnabled {
            app.failWithDiagnostics("前提不成立：有篩選條件時清除篩選應可點")
        }
        let isMonthSelected = orders.isRegularDateChipSelected("thisMonth")
        let isAllSelected = orders.isRegularDateChipSelected("all")
        if !isMonthSelected || isAllSelected {
            app.failWithDiagnostics("前提不成立：日期應已選本月")
        }
        if !orders.paymentMethodTriggerLabel.contains("付款方式：信用卡") {
            let actual = orders.paymentMethodTriggerLabel
            app.failWithDiagnostics("前提不成立：付款方式應為信用卡，實際為「\(actual)」")
        }
        if !orders.categoryTriggerLabel.contains("類別：2 項") {
            app.failWithDiagnostics("前提不成立：類別應為兩項，實際為「\(orders.categoryTriggerLabel)」")
        }
        if !orders.isRegularStatusChipSelected(Self.confirmedFilterID) {
            app.failWithDiagnostics("前提不成立：狀態篩選應為已確認")
        }

        // When
        orders.tapRegularClearFilters()

        // Then
        if !orders.paymentMethodTriggerLabel.contains("付款方式：全部") {
            app.failWithDiagnostics("清除後付款方式應為全部，實際為「\(orders.paymentMethodTriggerLabel)」")
        }
        if !orders.categoryTriggerLabel.contains("類別：全部") {
            app.failWithDiagnostics("清除後類別應為全部，實際為「\(orders.categoryTriggerLabel)」")
        }
        let isDefaultDateSelected = orders.isRegularDateChipSelected("all")
        let isMonthStillSelected = orders.isRegularDateChipSelected("thisMonth")
        if !isDefaultDateSelected || isMonthStillSelected {
            app.failWithDiagnostics("清除後日期應回到全部時間")
        }
        if !orders.isRegularStatusChipSelected(Self.confirmedFilterID) {
            app.failWithDiagnostics("清除後狀態篩選應維持已確認")
        }
        if orders.isRegularClearFiltersEnabled {
            app.failWithDiagnostics("清除後無篩選條件，清除篩選按鈕應停用")
        }
        let listed = orders.collectListedOrderIDs()
        if listed != Self.allOrderIDs {
            app.failWithDiagnostics("清除後應列出全部 10 筆，實際為 \(listed.sorted())")
        }
    }

    /// 驗證尚無任何篩選條件時，清除篩選按鈕停用，狀態篩選的「全部」預設選中
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testRegularClearFilters_無篩選條件_按鈕停用() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(isRegularLayout(app), "清除篩選按鈕只存在於 regular 版面，compact 版面由篩選 sheet 測試覆蓋")
        let orders = openOrders(app)

        // When
        let isClearButtonEnabled = orders.isRegularClearFiltersEnabled

        // Then
        if isClearButtonEnabled {
            app.failWithDiagnostics("無篩選條件時清除篩選按鈕應停用")
        }
        if !orders.isRegularStatusChipSelected("all") {
            app.failWithDiagnostics("預設狀態篩選應為全部並選中")
        }
    }
}

// MARK: - Private Method

private extension OrderRegularClearFiltersTests {

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
