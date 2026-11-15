//
//  OrdersPaymentMethodMenuUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/18.
//

import XCTest

/// regular 版面付款方式 Menu 選取後的清單變化 UI 測試
///
/// - Note: 只在 regular 版面執行
/// - Note: 種子為 `categoryFilter`
@MainActor
final class OrdersPaymentMethodMenuUITests: BLUITestCase {

    // MARK: - Properties

    /// 信用卡的訂單編號，即種子中付款方式為信用卡的 8 筆
    private static let creditCardOrderIDs: Set<String> = [
        "UITEST-CF-001",
        "UITEST-CF-002",
        "UITEST-CF-004",
        "UITEST-CF-005",
        "UITEST-CF-006",
        "UITEST-CF-007",
        "UITEST-CF-008",
        "UITEST-CF-010",
    ]

    /// 驗證選信用卡後觸發鈕顯示信用卡，清單只列出信用卡的八筆訂單
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testPaymentMethodFilterSelected_選信用卡_清單只列信用卡八筆() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilter))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            "compact 版面由篩選 sheet 測試覆蓋"
        )

        // When
        try orders.selectPaymentMethodInRegularLayout("信用卡")

        // Then
        try OrdersUITestSupport.assertTrigger(
            label: orders.paymentMethodTriggerLabel(),
            contains: "信用卡",
            in: app
        )
        try assertListedOrderIDs(Self.creditCardOrderIDs, orders)
    }

    /// 驗證付款方式 Menu 未選擇時觸發鈕未選取，選信用卡後標記為已選取
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    func testPaymentMethodFilterSelected_選信用卡_觸發鈕標記已選取() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .categoryFilter))
        let orders = try OrdersScreen.open(in: app)
        try XCTSkipUnless(
            try ordersLayout(in: app) == .regular,
            "compact 版面由篩選 sheet 測試覆蓋"
        )
        try requireCondition(
            !orders.isRegularPaymentMethodMenuSelected(),
            in: app,
            "未選擇付款方式時，觸發鈕不應標記為已選取"
        )

        // When
        try orders.selectPaymentMethodInRegularLayout("信用卡")

        // Then
        XCTAssertTrue(
            orders.isRegularPaymentMethodMenuSelected(),
            "選擇信用卡後，付款方式觸發鈕應標記為已選取"
        )
    }
}
