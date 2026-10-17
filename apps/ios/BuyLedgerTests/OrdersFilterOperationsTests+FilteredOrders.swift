//
//  OrdersFilterOperationsTests+FilteredOrders.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import Testing

@testable import BuyLedger

extension OrdersFilterOperationsTests {

    /// 驗證狀態篩選只回傳相符狀態的訂單，並保留原本順序
    ///
    /// - Throws: 三月日期無法建立時拋出測試錯誤
    @Test
    func filteredOrders_狀態篩選_只回傳相符狀態的訂單() throws {
        // Given
        var state = try makeFilteredOrdersState()

        // When
        state.selectedStatus = .status(.quoting)

        // Then
        #expect(state.filteredOrders.map(\.id) == ["O1", "O3"])
    }

    /// 驗證日期篩選只回傳本月的訂單，並保留原本順序
    ///
    /// - Throws: 三月日期無法建立時拋出測試錯誤
    @Test
    func filteredOrders_日期篩選_只回傳本月的訂單() throws {
        // Given
        var state = try makeFilteredOrdersState()

        // When
        state.selectedDatePeriod = .thisMonth

        // Then
        #expect(state.filteredOrders.map(\.id) == ["O1", "O3", "O4"])
    }

    /// 驗證類別篩選只回傳相符類別的訂單，並保留原本順序
    ///
    /// - Throws: 三月日期無法建立時拋出測試錯誤
    @Test
    func filteredOrders_類別篩選_只回傳相符類別的訂單() throws {
        // Given
        var state = try makeFilteredOrdersState()

        // When
        state.selectedCategory = "美妝"

        // Then
        #expect(state.filteredOrders.map(\.id) == ["O1", "O3"])
    }

    /// 驗證付款方式篩選只回傳相符付款方式的訂單，並保留原本順序
    ///
    /// - Throws: 三月日期無法建立時拋出測試錯誤
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

private extension OrdersFilterOperationsTests {

    /// 建立四筆篩選測試訂單，O2 的日期落在三月，其餘訂單使用固定時間
    ///
    /// - Returns: 尚未套用任何篩選的清單狀態
    /// - Throws: 三月日期無法建立時拋出測試錯誤
    func makeFilteredOrdersState() throws -> OrderListFeature.State {
        let marchFirst = try Self.date(year: 2026, month: 3, day: 1)
        return OrderListFeatureTests.makeState(orders: [
            makeOrder(
                id: "O1",
                status: .quoting,
                date: TestDependencies.fixedNow,
                category: "美妝",
                paymentMethod: "信用卡"
            ),
            makeOrder(
                id: "O2",
                status: .confirmed,
                date: marchFirst,
                category: "服飾",
                paymentMethod: "現金"
            ),
            makeOrder(
                id: "O3",
                status: .quoting,
                date: TestDependencies.fixedNow,
                category: "美妝",
                paymentMethod: "現金"
            ),
            makeOrder(
                id: "O4",
                status: .delivered,
                date: TestDependencies.fixedNow,
                category: "服飾",
                paymentMethod: "信用卡"
            ),
        ])
    }
}
