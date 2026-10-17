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

/// 訂單篩選各條件、交集與日期邊界的行為測試
struct OrdersQueryTests {

    /// 空清單不產生任何篩選結果
    @Test
    func filteredOrders_空清單_回傳空清單() {
        // Given
        let orders: [LedgerOrder] = []

        // When
        let result = filtered(orders: orders)

        // Then
        #expect(result.isEmpty)
    }

    /// 沒有篩選條件時保留輸入順序，空白搜尋不篩除資料
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

    /// 各狀態篩選只保留該狀態的訂單，全部狀態篩選則保留所有訂單
    ///
    /// - Parameters:
    ///   - status: 要套用的狀態篩選
    ///   - expected: 字面值定義的訂單識別值
    @Test(arguments: [
        (
            OrderStatusFilter.all,
            [
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
            ],
        ),
        (.status(.quoting), ["quoting"]),
        (.status(.confirmed), ["confirmed"]),
        (.status(.purchased), ["purchased"]),
        (.status(.shipping), ["shipping"]),
        (.status(.partiallyArrived), ["partiallyArrived"]),
        (.status(.arrived), ["arrived"]),
        (.status(.delivered), ["delivered"]),
        (.status(.pickedUp), ["pickedUp"]),
        (.status(.cancelled), ["cancelled"]),
        (.status(.merged), ["merged"]),
    ])
    func filteredOrders_所有狀態篩選_僅保留指定狀態(status: OrderStatusFilter, expected: [String]) {
        // Given
        let orders = OrderStatus.allCases.map {
            LedgerOrder.fixture(id: $0.rawValue, status: $0, date: TestDependencies.fixedNow)
        }

        // When
        let result = filtered(orders: orders, status: status)

        // Then
        #expect(result.map(\.id) == expected)
    }

    /// 類別與付款方式各自以精確值篩選，未選取時不排除
    ///
    /// - Parameters:
    ///   - selection: 篩選值，包含未選取、符合與不符合
    ///   - expected: 字面值定義的訂單識別值
    @Test(arguments: [
        (nil as String?, ["match", "other"]),
        ("Selected", ["match"]),
        ("selected", []),
        ("missing", []),
    ])
    func filteredOrders_類別與付款方式篩選_各自保留精確符合者(selection: String?, expected: [String]) {
        // Given
        let orders = [
            LedgerOrder.fixture(
                id: "match",
                date: TestDependencies.fixedNow,
                categories: ["other", "Selected"],
                paymentMethod: "Selected"
            ),
            LedgerOrder.fixture(id: "other", date: TestDependencies.fixedNow),
        ]

        // When
        let categories = filtered(orders: orders, category: selection)
        let payments = filtered(orders: orders, paymentMethod: selection)
        let combined = filtered(
            orders: orders,
            status: .status(.confirmed),
            period: .thisMonth,
            category: selection,
            paymentMethod: selection
        )

        // Then
        #expect(categories.map(\.id) == expected)
        #expect(payments.map(\.id) == expected)
        #expect(combined.map(\.id) == expected)
    }

    /// 搜尋比對訂單編號、客戶名稱與縮寫、來源、幣別、類別與商品名稱，不分大小寫，首尾空白不影響結果
    ///
    /// - Parameters:
    ///   - query: 要搜尋的欄位內容
    ///   - expected: 字面值定義的訂單識別值
    @Test(arguments: [
        ("  ALPHA-ID\n", ["Alpha-ID"]),
        ("小明", ["Alpha-ID"]),
        ("xm", ["Alpha-ID"]),
        ("sourceabc", ["Alpha-ID"]),
        ("jpy", ["Alpha-ID"]),
        ("分類甲", ["Alpha-ID"]),
        ("widget", ["Alpha-ID"]),
        ("只在備註", []),
        ("只在付款", []),
        ("只在開團", []),
        ("missing", []),
    ])
    func filteredOrders_搜尋既有欄位與非搜尋欄位_只回傳符合者(query: String, expected: [String]) {
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
        let result = filtered(orders: orders, searchText: query)

        // Then
        #expect(result.map(\.id) == expected)
    }

    /// 日期區間包含起點並排除終點，週與月的邊界使用固定 UTC 行事曆
    ///
    /// - Parameters:
    ///   - period: 要套用的日期區間
    ///   - expected: 字面值定義的訂單識別值
    @Test(arguments: [
        (
            OrderDatePeriod.all,
            [
                "feb-end",
                "mar-start",
                "mar-end",
                "apr-start",
                "week-before",
                "week-start",
                "apr-end",
                "may-start",
                "week-end",
            ],
        ),
        (.thisWeek, ["week-start", "apr-end", "may-start"]),
        (.thisMonth, ["apr-start", "week-before", "week-start", "apr-end"]),
        (.lastMonth, ["mar-start", "mar-end"]),
    ])
    func filteredOrders_日期區間端點_包含起點排除終點(period: OrderDatePeriod, expected: [String]) {
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
        let result = filtered(orders: orders, period: period)

        // Then
        #expect(result.map(\.id) == expected)
    }
}

// MARK: - Private Method

private extension OrdersQueryTests {

    /// 以固定時間與 UTC 行事曆執行篩選，省略的條件代表未選取
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
            selectedCategory: category,
            selectedPaymentMethod: paymentMethod,
            searchText: searchText,
            now: TestDependencies.fixedNow,
            calendar: calendar
        )
    }
}
