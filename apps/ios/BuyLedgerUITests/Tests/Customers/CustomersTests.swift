//
//  CustomersTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 客戶名單點選客戶切到訂單與空狀態測試
final class CustomersTests: BLUITestCase {

    // MARK: - Properties

    /// `customerRanking` 中累計消費最高的客戶名，用來點選客戶列
    private static let topCustomerName = "林書宇"

    /// 點客戶列後直接切到該客戶的訂單，訂單清單畫面出現
    @MainActor
    func testTapCustomer_有客戶排行資料_切到訂單清單() {
        // Given
        let app = launch(LaunchOptions(seed: .customerRanking))
        let customers = openCustomers(app)

        // When
        customers.tapCustomer(customerName: Self.topCustomerName)

        // Then
        let orders = OrdersScreen(app: app)
        if !orders.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "點客戶「\(Self.topCustomerName)」後訂單清單根 identifier「\(orders.rootIdentifier)」逾時仍未出現"
            )
        }
    }

    /// 空資料庫時，客戶名單顯示尚無客戶的空狀態
    @MainActor
    func testOpenCustomers_空資料_顯示空狀態() {
        // Given
        let app = launch(LaunchOptions(seed: .empty))

        // When
        _ = openCustomers(app)

        // Then
        assertEmptyState(BLAccessibilityID.Customers.listEmptyState, in: app)
    }
}

// MARK: - Private Method

private extension CustomersTests {

    /// 進入客戶頁 (從更多分頁點入) 並等名單就緒，回傳客戶頁 Page Object
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的來源檔案
    ///   - line: 失敗時回報的來源行號
    /// - Returns: 已就緒的客戶頁 Page Object
    @MainActor
    func openCustomers(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CustomersScreen {
        let customers = CustomersScreen.open(from: app, file: file, line: line)
        if !customers.waitUntilReady() {
            failWithDiagnostics(
                in: app,
                "客戶名單根 identifier「\(customers.rootIdentifier)」逾時仍未出現",
                file: file,
                line: line
            )
        }
        return customers
    }
}
