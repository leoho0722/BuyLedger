//
//  OrderPaymentMethodMenuTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/18.
//

import XCTest

/// regular 版面付款方式 Menu 選取後的清單變化測試
///
/// - Note: 只在 regular 版面執行
/// - Note: 種子為 `categoryFilter`
final class OrderPaymentMethodMenuTests: BLUITestCase {

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

    /// 付款方式 Menu 選信用卡後，觸發鈕顯示該付款方式且清單只列信用卡的 8 筆
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    @MainActor
    func testPaymentMethodMenu_選信用卡_清單只列信用卡八筆() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(
            isRegularLayout(app),
            "付款方式 Menu 只存在於 regular 版面，compact 版面由篩選 sheet 測試覆蓋"
        )
        let root = RootNavigationScreen(app: app)
        if !root.goToOrders() {
            app.failWithDiagnostics("切到訂單分頁後畫面未就緒")
        }
        let orders = OrdersScreen(app: app)
        if !orders.waitUntilReady() {
            app.failWithDiagnostics("訂單清單根 identifier 逾時仍未出現")
        }

        // When
        orders.selectPaymentMethodInRegularLayout("信用卡")

        // Then
        if !orders.paymentMethodTriggerLabel.contains("信用卡") {
            app.failWithDiagnostics("付款方式觸發鈕應包含「信用卡」，實際為「\(orders.paymentMethodTriggerLabel)」")
        }
        let listed = orders.collectListedOrderIDs()
        if listed != Self.creditCardOrderIDs {
            app.failWithDiagnostics(
                "清單應列出 \(Self.creditCardOrderIDs.sorted())，實際為 \(listed.sorted())"
            )
        }
    }

    /// 付款方式 Menu 選信用卡後，觸發鈕標記為已選取
    ///
    /// - Throws: 版面不符時由 `XCTSkip` 宣告適用版面
    @MainActor
    func testPaymentMethodMenu_選信用卡_觸發鈕標記已選取() throws {
        // Given
        let app = launch(LaunchOptions(seed: .categoryFilter))
        try XCTSkipUnless(
            isRegularLayout(app),
            "付款方式 Menu 只存在於 regular 版面，compact 版面由篩選 sheet 測試覆蓋"
        )
        let root = RootNavigationScreen(app: app)
        if !root.goToOrders() {
            app.failWithDiagnostics("切到訂單分頁後畫面未就緒")
        }
        let orders = OrdersScreen(app: app)
        if !orders.waitUntilReady() {
            app.failWithDiagnostics("訂單清單根 identifier 逾時仍未出現")
        }
        if orders.isRegularPaymentMethodMenuSelected() {
            app.failWithDiagnostics("未選擇付款方式時，觸發鈕不應標記為已選取")
        }

        // When
        orders.selectPaymentMethodInRegularLayout("信用卡")

        // Then
        if !orders.isRegularPaymentMethodMenuSelected() {
            app.failWithDiagnostics("選擇信用卡後，付款方式觸發鈕應標記為已選取")
        }
    }
}
