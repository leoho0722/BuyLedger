//
//  RootNavigationCustomerOrdersUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/15.
//

import XCTest

/// 點客戶列後切到該客戶訂單清單的 UI 測試
@MainActor
final class RootNavigationCustomerOrdersUITests: BLUITestCase {

    // MARK: - Properties

    /// customerRanking 種子中累計消費最高的客戶名稱
    private static let topCustomerName = "林書宇"

    /// 驗證有客戶排行資料時點選最高消費客戶列，切到訂單頁且清單就緒
    ///
    /// - Throws: 客戶頁或訂單清單未就緒時丟出測試錯誤
    func testCustomerTapped_有客戶排行資料_切到訂單清單() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .customerRanking))
        let customers = try CustomersScreen.open(in: app)

        // When
        try customers.tapCustomer(customerName: Self.topCustomerName)

        // Then
        let orders = OrdersScreen(app: app)
        XCTAssertTrue(
            orders.waitUntilReady(),
            "點客戶「\(Self.topCustomerName)」後訂單清單未就緒"
        )
    }

    /// 驗證 AX5 最大字級下仍可捲動並點選客戶列，切到該客戶的訂單
    ///
    /// - Throws: 客戶頁或訂單清單未就緒時丟出測試錯誤
    func testCustomerTapped_AX5字級_列仍可點選切到訂單() throws {
        // Given
        let options = LaunchOptions(
            seed: .customerRanking,
            contentSizeCategory: .accessibilityExtraExtraExtraLarge
        )
        let app = try launch(options)
        let customers = try CustomersScreen.open(in: app)

        // When
        try customers.tapCustomer(customerName: Self.topCustomerName)

        // Then
        let orders = OrdersScreen(app: app)
        XCTAssertTrue(
            orders.waitUntilReady(),
            "AX5 字級下點客戶「\(Self.topCustomerName)」後訂單清單未就緒"
        )
    }
}

