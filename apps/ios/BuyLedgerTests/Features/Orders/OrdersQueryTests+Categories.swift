//
//  OrdersQueryTests+Categories.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import Foundation
import Testing

@testable import BuyLedger

extension OrdersQueryTests {

    /// 多類別條件與狀態取交集，空集合保留未分類訂單
    ///
    /// - Parameter testCase: 規格表的狀態篩選、類別集合與訂單識別值
    @Test(arguments: [
        StatusCategoryCase(
            status: OrderStatusFilter.status(.purchased),
            categories: Set<String>(["beauty"]),
            expectedIDs: ["O1"],
        ),
        StatusCategoryCase(
            status: .status(.purchased),
            categories: Set<String>(["beauty", "snacks"]),
            expectedIDs: ["O1", "O3"],
        ),
        StatusCategoryCase(
            status: .status(.purchased),
            categories: Set<String>(["books"]),
            expectedIDs: ["O4"],
        ),
        StatusCategoryCase(
            status: .status(.purchased),
            categories: Set<String>(),
            expectedIDs: ["O1", "O3", "O4", "O5"],
        ),
        StatusCategoryCase(
            status: .all,
            categories: Set<String>(["snacks"]),
            expectedIDs: ["O2", "O3"],
        ),
    ])
    func filteredOrders_多類別與狀態範例_回傳所有條件相符訂單(testCase: StatusCategoryCase) {
        // Given
        let orders = [
            LedgerOrder.fixture(id: "O1", status: .purchased, categories: ["beauty"]),
            LedgerOrder.fixture(id: "O2", status: .quoting, categories: ["beauty", "snacks"]),
            LedgerOrder.fixture(id: "O3", status: .purchased, categories: ["snacks"]),
            LedgerOrder.fixture(id: "O4", status: .purchased, categories: ["books"]),
            LedgerOrder.fixture(id: "O5", status: .purchased, categories: []),
        ]

        // When
        let result = OrdersQuery.filteredOrders(
            orders: orders,
            selectedStatus: testCase.status,
            selectedDatePeriod: .all,
            selectedCategories: testCase.categories,
            selectedPaymentMethod: nil,
            searchText: "",
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(result.map(\.id) == testCase.expectedIDs)
    }

    /// 多選類別與狀態、日期、付款方式及搜尋同時生效
    @Test
    func filteredOrders_多類別結合全部篩選_只保留完整相符訂單() {
        // Given
        let orders = [
            LedgerOrder.fixture(
                id: "match-beauty",
                date: TestDependencies.fixedNow,
                categories: ["beauty"],
                paymentMethod: "Card"
            ),
            LedgerOrder.fixture(
                id: "match-books",
                date: TestDependencies.fixedNow,
                categories: ["books"],
                paymentMethod: "Card"
            ),
            LedgerOrder.fixture(
                id: "match-other",
                date: TestDependencies.fixedNow,
                categories: ["snacks"],
                paymentMethod: "Card"
            ),
            LedgerOrder.fixture(
                id: "match-status",
                status: .purchased,
                date: TestDependencies.fixedNow,
                categories: ["beauty"],
                paymentMethod: "Card"
            ),
            LedgerOrder.fixture(
                id: "match-date",
                date: Date(timeIntervalSince1970: 0),
                categories: ["beauty"],
                paymentMethod: "Card"
            ),
            LedgerOrder.fixture(
                id: "match-payment",
                date: TestDependencies.fixedNow,
                categories: ["beauty"],
                paymentMethod: "Cash"
            ),
            LedgerOrder.fixture(
                id: "outside-search",
                date: TestDependencies.fixedNow,
                categories: ["beauty"],
                paymentMethod: "Card"
            ),
        ]

        // When
        let result = OrdersQuery.filteredOrders(
            orders: orders,
            selectedStatus: .status(.confirmed),
            selectedDatePeriod: .thisMonth,
            selectedCategories: ["beauty", "books"],
            selectedPaymentMethod: "Card",
            searchText: "match",
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(result.map(\.id) == ["match-beauty", "match-books"])
    }

    /// 驗證主檔與訂單類別組合是否依非空白類別回傳可用狀態
    ///
    /// - Parameter testCase: 主檔類別、訂單類別與預期可用狀態的案例
    @Test(arguments: [
        AvailableCategoriesCase(catalogCategories: [], orderCategories: [], isAvailable: false),
        AvailableCategoriesCase(
            catalogCategories: ["beauty"],
            orderCategories: [],
            isAvailable: true,
        ),
        AvailableCategoriesCase(
            catalogCategories: [],
            orderCategories: ["  ", "\n\t"],
            isAvailable: false,
        ),
        AvailableCategoriesCase(
            catalogCategories: [],
            orderCategories: ["snacks"],
            isAvailable: true,
        ),
    ])
    func hasAvailableCategories_主檔與訂單類別組合_依是否有非空白類別回傳(testCase: AvailableCategoriesCase) {
        // Given
        let orders = [
            LedgerOrder.fixture(id: "O1", categories: testCase.orderCategories),
        ]
        let catalog = LookupCatalog(categories: testCase.catalogCategories)

        // When
        let result = OrdersListQuery.hasAvailableCategories(orders: orders, catalog: catalog)

        // Then
        #expect(result == testCase.isAvailable)
    }

    /// 合併主檔與訂單類別時，主檔類別原樣保留，訂單類別去除空白後略過空字串，重複類別只留一筆
    ///
    /// - Parameter testCase: 主檔類別、訂單類別與預期合併結果
    @Test(arguments: [
        MergedCategoriesCase(catalogCategories: [], orderCategories: [], expected: Set<String>([])),
        MergedCategoriesCase(
            catalogCategories: ["beauty"],
            orderCategories: ["beauty"],
            expected: Set<String>(["beauty"])
        ),
        MergedCategoriesCase(
            catalogCategories: [],
            orderCategories: [" beauty ", "\n snacks\t"],
            expected: Set<String>(["beauty", "snacks"])
        ),
        MergedCategoriesCase(
            catalogCategories: [],
            orderCategories: ["", "  "],
            expected: Set<String>([])
        ),
        MergedCategoriesCase(
            catalogCategories: ["3C"],
            orderCategories: ["books"],
            expected: Set<String>(["3C", "books"])
        ),
        MergedCategoriesCase(
            catalogCategories: [" spaced "],
            orderCategories: [],
            expected: Set<String>([" spaced "])
        ),
    ])
    func mergedCategories_主檔與訂單類別組合_依規則合併去重(testCase: MergedCategoriesCase) {
        // Given
        let orders = [
            LedgerOrder.fixture(id: "O1", categories: testCase.orderCategories),
        ]
        let catalog = LookupCatalog(categories: testCase.catalogCategories)

        // When
        let result = OrdersListQuery.mergedCategories(orders: orders, catalog: catalog)

        // Then
        #expect(result == testCase.expected)
    }
}

// MARK: - Nested Types

extension OrdersQueryTests {

    /// 合併類別的主檔與訂單類別組合與預期結果的案例
    struct MergedCategoriesCase: Sendable {

        /// 主檔類別清單
        let catalogCategories: [String]

        /// 訂單商品類別清單
        let orderCategories: [String]

        /// 預期的合併類別集合
        let expected: Set<String>
    }

    /// 主檔與訂單類別組合及是否有可用類別的案例
    struct AvailableCategoriesCase: Sendable {

        /// 主檔類別清單
        let catalogCategories: [String]

        /// 訂單商品類別清單
        let orderCategories: [String]

        /// 是否存在可用商品類別
        let isAvailable: Bool
    }

    /// 狀態與類別條件及預期訂單識別值的案例
    struct StatusCategoryCase: Sendable {

        /// 狀態篩選
        let status: OrderStatusFilter

        /// 選取的商品類別
        let categories: Set<String>

        /// 規格表列出的訂單識別值
        let expectedIDs: [String]
    }
}
