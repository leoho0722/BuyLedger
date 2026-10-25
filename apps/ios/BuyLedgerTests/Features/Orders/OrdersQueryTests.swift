//
//  OrdersQueryTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/7.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrdersQuery` 的單元測試，逐項斷言各篩選條件、條件交集與日期邊界的行為
struct OrdersQueryTests {

    /// 驗證沒有篩選條件且搜尋文字只有空白與換行時，訂單保留輸入順序，不被篩除
    @Test
    func filteredOrders_沒有篩選與空白搜尋_保留輸入順序() {
        // Given
        let orders = [
            LedgerOrder.fixture(id: "z", status: .merged, date: TestDependencies.fixedNow),
            LedgerOrder.fixture(id: "a", status: .cancelled, date: TestDependencies.fixedNow),
        ]

        // When
        let result = filtered(orders: orders, searchText: " \n\t")

        // Then
        #expect(result.map(\.id) == ["z", "a"])
    }

    /// 驗證各狀態篩選只保留同狀態的訂單，全部狀態時保留所有狀態的訂單
    ///
    /// - Parameter scenario: 要套用的狀態篩選與字面值定義的訂單識別值
    @Test(arguments: StatusFilterCase.allCases)
    func filteredOrders_所有狀態篩選_僅保留指定狀態(scenario: StatusFilterCase) {
        // Given
        let orders = OrderStatus.allCases.map {
            LedgerOrder.fixture(id: $0.rawValue, status: $0, date: TestDependencies.fixedNow)
        }

        // When
        let result = filtered(orders: orders, status: scenario.status)

        // Then
        #expect(result.map(\.id) == scenario.expectedIDs)
    }

    /// 驗證類別篩選以精確值比對，未選取時不排除，大小寫不同或不存在的類別都不符合
    ///
    /// - Parameter scenario: 篩選值 (未選取、符合與不符合) 與字面值定義的訂單識別值
    @Test(arguments: SelectionCase.allCases)
    func filteredOrders_類別篩選_只保留精確符合者(scenario: SelectionCase) {
        // Given
        let orders = Self.makeSelectionOrders()

        // When
        let result = filtered(orders: orders, category: scenario.selection)

        // Then
        #expect(result.map(\.id) == scenario.expectedIDs)
    }

    /// 驗證付款方式篩選以精確值比對，未選取時不排除，大小寫不同或不存在的付款方式都不符合
    ///
    /// - Parameter scenario: 篩選值 (未選取、符合與不符合) 與字面值定義的訂單識別值
    @Test(arguments: SelectionCase.allCases)
    func filteredOrders_付款方式篩選_只保留精確符合者(scenario: SelectionCase) {
        // Given
        let orders = Self.makeSelectionOrders()

        // When
        let result = filtered(orders: orders, paymentMethod: scenario.selection)

        // Then
        #expect(result.map(\.id) == scenario.expectedIDs)
    }

    /// 驗證類別與付款方式同時套用，並與狀態、本月日期條件組合時，仍以精確值比對，未選取時不排除
    ///
    /// - Parameter scenario: 篩選值 (未選取、符合與不符合) 與字面值定義的訂單識別值
    @Test(arguments: SelectionCase.allCases)
    func filteredOrders_類別與付款方式組合_只保留精確符合者(scenario: SelectionCase) {
        // Given
        let orders = Self.makeSelectionOrders()

        // When
        let result = filtered(
            orders: orders,
            status: .status(.confirmed),
            period: .thisMonth,
            category: scenario.selection,
            paymentMethod: scenario.selection
        )

        // Then
        #expect(result.map(\.id) == scenario.expectedIDs)
    }

    /// 驗證搜尋比對訂單編號、客戶名稱與縮寫、來源、幣別、類別與商品名稱，不分大小寫且忽略首尾空白，備註、付款方式與開團名稱不在搜尋範圍內
    ///
    /// - Parameter scenario: 要搜尋的欄位內容與字面值定義的訂單識別值
    @Test(arguments: SearchCase.allCases)
    func filteredOrders_搜尋既有欄位與非搜尋欄位_只回傳符合者(scenario: SearchCase) {
        // Given
        let orders = [
            LedgerOrder.fixture(
                id: "Alpha-ID",
                customer: LedgerCustomer(name: "小明", initials: "XM", tier: .regular),
                currency: .jpy,
                date: TestDependencies.fixedNow,
                items: [
                    LedgerOrderItem(
                        id: UUID(0),
                        name: "Widget",
                        quantity: 1,
                        unitPrice: 10
                    ),
                ],
                orderSource: "SourceABC",
                categories: ["分類甲"],
                paymentMethod: "只在付款",
                notes: "只在備註",
                campaignNames: ["只在開團"]
            ),
        ]

        // When
        let result = filtered(orders: orders, searchText: scenario.query)

        // Then
        #expect(result.map(\.id) == scenario.expectedIDs)
    }

    /// 驗證日期區間包含起點、排除終點，週與月的邊界以固定 UTC 行事曆計算，九個邊界訂單依各區間判定去留
    ///
    /// - Parameter scenario: 要套用的日期區間與字面值定義的訂單識別值
    @Test(arguments: DatePeriodCase.allCases)
    func filteredOrders_日期區間端點_包含起點排除終點(scenario: DatePeriodCase) {
        // Given
        let now = TestDependencies.fixedNow
        let boundaries: [(String, TimeInterval)] = [
            ("feb-end", -5_184_001),
            ("mar-start", -5_184_000),
            ("mar-end", -2_505_601),
            ("apr-start", -2_505_600),
            ("week-before", -345_601),
            ("week-start", -345_600),
            ("apr-end", 86_399),
            ("may-start", 86_400),
            ("week-end", 259_200),
        ]
        let orders = boundaries.map { id, offset in
            LedgerOrder.fixture(id: id, date: now.addingTimeInterval(offset))
        }

        // When
        let result = filtered(orders: orders, period: scenario.period)

        // Then
        #expect(result.map(\.id) == scenario.expectedIDs)
    }
}

// MARK: - Nested Types

extension OrdersQueryTests {

    /// 狀態篩選與預期保留的訂單識別值
    struct StatusFilterCase: Sendable {

        /// 全部狀態與各單一狀態的篩選案例，逐一列出預期保留的訂單識別值
        static let allCases = [
            Self(
                status: .all,
                expectedIDs: [
                    "quoting",
                    "confirmed",
                    "purchased",
                    "shipping",
                    "partiallyArrived",
                    "arrived",
                    "delivered",
                    "pickedUp",
                    "cancelled",
                    "merged",
                ]
            ),
            Self(status: .status(.quoting), expectedIDs: ["quoting"]),
            Self(status: .status(.confirmed), expectedIDs: ["confirmed"]),
            Self(status: .status(.purchased), expectedIDs: ["purchased"]),
            Self(status: .status(.shipping), expectedIDs: ["shipping"]),
            Self(status: .status(.partiallyArrived), expectedIDs: ["partiallyArrived"]),
            Self(status: .status(.arrived), expectedIDs: ["arrived"]),
            Self(status: .status(.delivered), expectedIDs: ["delivered"]),
            Self(status: .status(.pickedUp), expectedIDs: ["pickedUp"]),
            Self(status: .status(.cancelled), expectedIDs: ["cancelled"]),
            Self(status: .status(.merged), expectedIDs: ["merged"]),
        ]

        /// 要套用的狀態篩選
        let status: OrderStatusFilter

        /// 字面值定義的訂單識別值
        let expectedIDs: [String]
    }

    /// 類別或付款方式的篩選值與預期保留的訂單識別值
    struct SelectionCase: Sendable {

        /// 未選取、大小寫相符、大小寫不符與不存在四種篩選值
        static let allCases = [
            Self(selection: nil, expectedIDs: ["match", "other"]),
            Self(selection: "Selected", expectedIDs: ["match"]),
            Self(selection: "selected", expectedIDs: []),
            Self(selection: "missing", expectedIDs: []),
        ]

        /// 篩選值，`nil` 代表未選取
        let selection: String?

        /// 字面值定義的訂單識別值
        let expectedIDs: [String]
    }

    /// 搜尋文字與預期保留的訂單識別值
    struct SearchCase: Sendable {

        /// 可搜尋欄位命中，以及只出現在備註、付款方式、開團或不存在時不命中的案例
        static let allCases = [
            Self(query: "  ALPHA-ID\n", expectedIDs: ["Alpha-ID"]),
            Self(query: "小明", expectedIDs: ["Alpha-ID"]),
            Self(query: "xm", expectedIDs: ["Alpha-ID"]),
            Self(query: "sourceabc", expectedIDs: ["Alpha-ID"]),
            Self(query: "jpy", expectedIDs: ["Alpha-ID"]),
            Self(query: "分類甲", expectedIDs: ["Alpha-ID"]),
            Self(query: "widget", expectedIDs: ["Alpha-ID"]),
            Self(query: "只在備註", expectedIDs: []),
            Self(query: "只在付款", expectedIDs: []),
            Self(query: "只在開團", expectedIDs: []),
            Self(query: "missing", expectedIDs: []),
        ]

        /// 要搜尋的欄位內容
        let query: String

        /// 字面值定義的訂單識別值
        let expectedIDs: [String]
    }

    /// 日期區間與預期保留的訂單識別值
    struct DatePeriodCase: Sendable {

        /// 全部、本週、本月與上個月四種區間
        static let allCases = [
            Self(
                period: .all,
                expectedIDs: [
                    "feb-end",
                    "mar-start",
                    "mar-end",
                    "apr-start",
                    "week-before",
                    "week-start",
                    "apr-end",
                    "may-start",
                    "week-end",
                ]
            ),
            Self(period: .thisWeek, expectedIDs: ["week-start", "apr-end", "may-start"]),
            Self(
                period: .thisMonth,
                expectedIDs: ["apr-start", "week-before", "week-start", "apr-end"]
            ),
            Self(period: .lastMonth, expectedIDs: ["mar-start", "mar-end"]),
        ]

        /// 要套用的日期區間
        let period: OrderDatePeriod

        /// 字面值定義的訂單識別值
        let expectedIDs: [String]
    }
}

// MARK: - Private Method

private extension OrdersQueryTests {

    /// 建立類別與付款方式篩選共用的兩筆訂單，只有識別值 match 的訂單含「Selected」類別與付款方式
    ///
    /// - Returns: 符合與不符合篩選值的兩筆訂單
    static func makeSelectionOrders() -> [LedgerOrder] {
        [
            LedgerOrder.fixture(
                id: "match",
                date: TestDependencies.fixedNow,
                categories: ["other", "Selected"],
                paymentMethod: "Selected"
            ),
            LedgerOrder.fixture(id: "other", date: TestDependencies.fixedNow),
        ]
    }

    /// 執行固定時間與 UTC 行事曆的訂單篩選，省略的條件代表未選取
    ///
    /// - Parameters:
    ///   - orders: 要篩選的訂單
    ///   - status: 訂單狀態條件
    ///   - period: 日期區間條件
    ///   - category: 商品類別條件
    ///   - paymentMethod: 付款方式條件
    ///   - searchText: 商品與訂單搜尋文字
    /// - Returns: 符合所有條件的訂單
    func filtered(
        orders: [LedgerOrder],
        status: OrderStatusFilter = .all,
        period: OrderDatePeriod = .all,
        category: String? = nil,
        paymentMethod: String? = nil,
        searchText: String = ""
    ) -> [LedgerOrder] {
        var calendar = TestDependencies.fixedCalendar
        calendar.firstWeekday = 1
        calendar.minimumDaysInFirstWeek = 1
        return OrdersQuery.filteredOrders(
            orders: orders,
            selectedStatus: status,
            selectedDatePeriod: period,
            selectedCategories: category.map { [$0] } ?? [],
            selectedPaymentMethod: paymentMethod,
            searchText: searchText,
            now: TestDependencies.fixedNow,
            calendar: calendar
        )
    }
}
