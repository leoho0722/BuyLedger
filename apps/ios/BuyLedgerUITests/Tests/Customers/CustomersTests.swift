//
//  CustomersTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 客戶名單的進入、排行與深連結流程測試
///
/// 一律以 accessibility identifier 定位、以客戶名這個業務鍵做結構性斷言，不硬編金額或名次；找不到 App 元素即附診斷失敗、不 skip。
/// 客戶名是 ``CustomerRow`` 的 id (業務鍵)，不隨語言變動，故中英兩語言皆有效
final class CustomersTests: BLUITestCase {

    // MARK: - Static Properties

    /// customerRanking 的四位既知客戶名 (依累計消費由高到低)
    private static let knownCustomerNames = ["林書宇", "Mika 周", "Ariel 陳", "Iris 楊"]

    /// customerRanking 中累計消費最高、必落在 Top 3 卡的客戶名
    private static let topCustomerName = "林書宇"

    // MARK: - Tests

    /// 從更多分頁進客戶頁後名單就緒，且四位既知客戶列都在
    @MainActor
    func testCustomerListReadyWithSeed() {
        let app = launch(LaunchOptions(seed: .customerRanking))
        let customers = openCustomers(app)

        for name in Self.knownCustomerNames where !customers.hasCustomer(customerName: name) {
            failWithDiagnostics(in: app, "customerRanking 名單未見既知客戶「\(name)」")
        }
    }

    /// 累計消費最高的客戶出現在 Top 3 強調卡
    @MainActor
    func testTopCustomerAppearsInTopCards() {
        let app = launch(LaunchOptions(seed: .customerRanking))
        let customers = openCustomers(app)

        let topCard = customers.topCard(customerName: Self.topCustomerName)
        if !topCard.waitForExistence(timeout: 5) {
            failWithDiagnostics(
                in: app,
                "最高消費客戶「\(Self.topCustomerName)」未出現在 Top 3 卡"
            )
        }
    }

    /// 點客戶列深連結到訂單頁，訂單清單根就緒
    @MainActor
    func testTapCustomerDeepLinksToOrders() {
        let app = launch(LaunchOptions(seed: .customerRanking))
        let customers = openCustomers(app)

        customers.tapCustomer(customerName: Self.topCustomerName)

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
    func testEmptySeedShowsEmptyState() {
        let app = launch(LaunchOptions(seed: .empty))
        _ = openCustomers(app)

        assertEmptyState(BLAccessibilityID.Customers.listEmptyState, in: app)
    }
}

// MARK: - Private Method

private extension CustomersTests {

    /// 從更多分頁導到客戶頁並等名單就緒，回傳客戶頁 Page Object
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 呼叫端檔案，交由 XCTest 定位
    ///   - line: 呼叫端行號，交由 XCTest 定位
    /// - Returns: 已就緒的客戶頁 Page Object
    @MainActor
    func openCustomers(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> CustomersScreen {
        let customers = CustomersScreen.open(from: app)
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
