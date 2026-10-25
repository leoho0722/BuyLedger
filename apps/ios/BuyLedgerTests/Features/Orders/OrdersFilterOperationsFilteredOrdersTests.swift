//
//  OrdersFilterOperationsFilteredOrdersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import Testing

@testable import BuyLedger

/// `OrderListFeature.State` 的單元測試，涵蓋 `filteredOrders` 依各種篩選條件回傳的訂單與順序
struct OrdersFilterOperationsFilteredOrdersTests {

    /// 驗證狀態篩選選為 `quoting` 時，清單只剩狀態相符的 O1 與 O3，並保留原本順序
    ///
    /// - Throws: 三月日期無法建立時丟出測試錯誤
    @Test
    func filteredOrders_狀態篩選_只回傳相符狀態的訂單() throws {
        // Given
        var state = try makeFilteredOrdersState()

        // When
        state.selectedStatus = .status(.quoting)

        // Then
        #expect(state.filteredOrders.map(\.id) == ["O1", "O3"])
    }

    /// 驗證日期篩選選為 `thisMonth` 時，日期不在本月的 O2 (三月) 被排除，其餘訂單保留原本順序
    ///
    /// - Throws: 三月日期無法建立時丟出測試錯誤
    @Test
    func filteredOrders_日期篩選_只回傳本月的訂單() throws {
        // Given
        var state = try makeFilteredOrdersState()

        // When
        state.selectedDatePeriod = .thisMonth

        // Then
        #expect(state.filteredOrders.map(\.id) == ["O1", "O3", "O4"])
    }

    /// 驗證類別篩選選為「美妝」時，只回傳類別含美妝的 O1 與 O3，並保留原本順序
    ///
    /// - Throws: 三月日期無法建立時丟出測試錯誤
    @Test
    func filteredOrders_類別篩選_只回傳相符類別的訂單() throws {
        // Given
        var state = try makeFilteredOrdersState()

        // When
        state.selectedCategories = ["美妝"]

        // Then
        #expect(state.filteredOrders.map(\.id) == ["O1", "O3"])
    }

    /// 驗證付款方式篩選選為「信用卡」時，只回傳 O1 與 O4，並保留原本順序
    ///
    /// - Throws: 三月日期無法建立時丟出測試錯誤
    @Test
    func filteredOrders_付款方式篩選_只回傳相符付款方式的訂單() throws {
        // Given
        var state = try makeFilteredOrdersState()

        // When
        state.selectedPaymentMethod = "信用卡"

        // Then
        #expect(state.filteredOrders.map(\.id) == ["O1", "O4"])
    }
}

// MARK: - Private Method

private extension OrdersFilterOperationsFilteredOrdersTests {

    /// 建立四筆篩選測試訂單，O2 的日期落在三月，其餘訂單使用固定時間
    ///
    /// - Returns: 尚未套用任何篩選的清單狀態
    /// - Throws: 三月日期無法建立時丟出測試錯誤
    func makeFilteredOrdersState() throws -> OrderListFeature.State {
        let marchFirst = try OrdersFilterOperationsTestSupport.date(year: 2026, month: 3, day: 1)
        return OrderListFeatureTestSupport.makeState(orders: [
            OrdersFilterOperationsTestSupport.makeOrder(
                id: "O1",
                status: .quoting,
                date: TestDependencies.fixedNow,
                category: "美妝",
                paymentMethod: "信用卡"
            ),
            OrdersFilterOperationsTestSupport.makeOrder(
                id: "O2",
                status: .confirmed,
                date: marchFirst,
                category: "服飾",
                paymentMethod: "現金"
            ),
            OrdersFilterOperationsTestSupport.makeOrder(
                id: "O3",
                status: .quoting,
                date: TestDependencies.fixedNow,
                category: "美妝",
                paymentMethod: "現金"
            ),
            OrdersFilterOperationsTestSupport.makeOrder(
                id: "O4",
                status: .delivered,
                date: TestDependencies.fixedNow,
                category: "服飾",
                paymentMethod: "信用卡"
            ),
        ])
    }
}
