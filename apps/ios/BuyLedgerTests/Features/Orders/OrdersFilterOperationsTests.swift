//
//  OrdersFilterOperationsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrdersFilterOperations` 的單元測試，直接呼叫各篩選方法並斷言狀態變化，另含 `OrderFilterSelection.isActive` 的真值表
struct OrdersFilterOperationsTests {

    /// 驗證切換為 `delivered` 狀態時，`selectedStatus` 更新，選取改為第一筆相符的 B
    @Test
    func statusFilterSelected_切換狀態_重選第一筆相符訂單() {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            OrdersFilterOperationsTestSupport.makeOrder(id: "A", status: .quoting),
            OrdersFilterOperationsTestSupport.makeOrder(id: "B", status: .delivered),
        ])

        // When
        OrdersFilterOperations.statusFilterSelected(.status(.delivered), state: &state)

        // Then
        #expect(state.selectedStatus == .status(.delivered))
        #expect(state.selectedOrderID == "B")
    }

    /// 驗證切換為 `thisMonth` 時，三月的 A 被排除，選取改為第一筆相符的 B
    ///
    /// - Throws: 日期無法建立時丟出測試錯誤
    @Test
    func datePeriodSelected_切換日期_重選第一筆相符訂單() throws {
        // Given
        let march = try OrdersFilterOperationsTestSupport.date(year: 2026, month: 3, day: 15)
        var state = OrderListFeatureTestSupport.makeState(orders: [
            OrdersFilterOperationsTestSupport.makeOrder(id: "A", date: march),
            OrdersFilterOperationsTestSupport.makeOrder(id: "B", date: TestDependencies.fixedNow),
        ])

        // When
        OrdersFilterOperations.datePeriodSelected(.thisMonth, state: &state)

        // Then
        #expect(state.selectedDatePeriod == .thisMonth)
        #expect(state.selectedOrderID == "B")
    }

    /// 驗證套用類別「服飾」時，已套用類別更新、選取改為第一筆相符的 B，並關閉類別選擇器
    @Test
    func categoryApplied_切換類別_重選第一筆相符訂單並關閉() {
        // Given
        let initialOrders = [
            OrdersFilterOperationsTestSupport.makeOrder(id: "A", category: "美妝"),
            OrdersFilterOperationsTestSupport.makeOrder(id: "B", category: "服飾"),
        ]
        var state = OrderListFeatureTestSupport.makeState(orders: initialOrders)
        state.selectedCategories = ["beauty", "books"]
        state.destination = .categoryPicker(
            OrderCategoryPickerFeatureTestSupport.makeState(for: state)
        )

        // When
        OrdersFilterOperations.categoryApplied(["服飾"], state: &state)

        // Then
        #expect(state.selectedCategories == ["服飾"])
        #expect(state.selectedOrderID == "B")
        #expect(state.destination == nil)
    }

    /// 驗證切換為付款方式「現金」時，已套用付款方式更新，選取改為第一筆相符的 B
    @Test
    func paymentMethodFilterSelected_切換付款方式_重選第一筆相符訂單() {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            OrdersFilterOperationsTestSupport.makeOrder(id: "A", paymentMethod: "信用卡"),
            OrdersFilterOperationsTestSupport.makeOrder(id: "B", paymentMethod: "現金"),
        ])

        // When
        OrdersFilterOperations.paymentMethodFilterSelected("現金", state: &state)

        // Then
        #expect(state.selectedPaymentMethod == "現金")
        #expect(state.selectedOrderID == "B")
    }

    /// 驗證日期、類別或付款方式任一偏離預設時篩選啟用，類別集合只要非空即算啟用 (連只含空字串也算)，三者皆為預設時停用
    ///
    /// - Parameter testCase: 已套用的日期、類別、付款方式與預期的啟用狀態
    @Test(arguments: [
        ActiveFilterCase(
            date: OrderDatePeriod.all,
            categories: Set<String>(),
            paymentMethod: nil,
            isActive: false
        ),
        ActiveFilterCase(
            date: .thisWeek,
            categories: Set<String>(),
            paymentMethod: nil,
            isActive: true
        ),
        ActiveFilterCase(
            date: .all,
            categories: Set<String>(["美妝"]),
            paymentMethod: nil,
            isActive: true
        ),
        ActiveFilterCase(
            date: .all,
            categories: Set<String>(),
            paymentMethod: "信用卡",
            isActive: true
        ),
        ActiveFilterCase(
            date: .thisWeek,
            categories: Set<String>(["美妝"]),
            paymentMethod: nil,
            isActive: true
        ),
        ActiveFilterCase(
            date: .thisWeek,
            categories: Set<String>(),
            paymentMethod: "信用卡",
            isActive: true
        ),
        ActiveFilterCase(
            date: .all,
            categories: Set<String>(["美妝"]),
            paymentMethod: "信用卡",
            isActive: true
        ),
        ActiveFilterCase(
            date: .thisWeek,
            categories: Set<String>(["美妝"]),
            paymentMethod: "信用卡",
            isActive: true
        ),
        ActiveFilterCase(
            date: .all,
            categories: Set<String>(["美妝", "書籍"]),
            paymentMethod: nil,
            isActive: true
        ),
        ActiveFilterCase(
            date: .all,
            categories: Set<String>([""]),
            paymentMethod: nil,
            isActive: true
        ),
    ])
    func isActive_各種篩選值_依非預設值判斷(testCase: ActiveFilterCase) {
        // Given
        let selection = OrderFilterSelection(
            datePeriod: testCase.date,
            categories: testCase.categories,
            paymentMethod: testCase.paymentMethod
        )

        // When
        let hasActiveFilter = selection.isActive

        // Then
        #expect(hasActiveFilter == testCase.isActive)
    }
}

// MARK: - Nested Types

extension OrdersFilterOperationsTests {

    /// 篩選條件與預期啟用狀態的案例
    struct ActiveFilterCase: Sendable {

        /// 日期區間
        let date: OrderDatePeriod

        /// 類別集合
        let categories: Set<String>

        /// 付款方式，`nil` 代表全部
        let paymentMethod: String?

        /// 是否預期有啟用篩選條件
        let isActive: Bool
    }
}
