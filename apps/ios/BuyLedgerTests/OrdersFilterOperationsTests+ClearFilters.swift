//
//  OrdersFilterOperationsTests+ClearFilters.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import Testing

@testable import BuyLedger

extension OrdersFilterOperationsTests {

    /// 任一或多項條件啟用時清除全部三項，再依最終結果重選
    ///
    /// - Parameter filterCase: 已套用的日期、類別與付款方式
    @Test(arguments: Self.activeClearFilterCases)
    func clearFilters_單項或混合條件啟用_還原預設並回報變更(filterCase: ClearFilterCase) {
        // Given
        var state = OrderListFeatureTests.makeClearFiltersState()
        state.selectedDatePeriod = filterCase.datePeriod
        state.selectedCategories = filterCase.categories
        state.selectedPaymentMethod = filterCase.paymentMethod

        // When
        let hasChanged = OrdersFilterOperations.clearFilters(state: &state)

        // Then
        #expect(hasChanged == true)
        #expect(state.selectedDatePeriod == .all)
        #expect(state.selectedCategories == [])
        #expect(state.selectedPaymentMethod == nil)
        #expect(state.selectedStatus == .status(.purchased))
        #expect(state.searchText == "Alice")
        #expect(state.selectedOrderID == "restored")
        #expect(
            state.filteredOrders.map(\.id) == [
                "restored",
                "dateOnly",
                "categoryOnly",
                "paymentOnly",
                "selected",
            ]
        )
        #expect(state.committedFilterSelection.isActive == false)
    }

    /// 只有狀態與搜尋不構成清除三項的變更，保留非首筆選取
    @Test
    func clearFilters_三項已是預設且有狀態搜尋_回報未變更並保留整體狀態() {
        // Given
        var state = OrderListFeatureTests.makeClearFiltersState()
        state.selectedDatePeriod = .all
        state.selectedCategories = []
        state.selectedPaymentMethod = nil
        let initial = state

        // When
        let hasChanged = OrdersFilterOperations.clearFilters(state: &state)

        // Then
        #expect(hasChanged == false)
        #expect(state == initial)
        #expect(state.selectedOrderID == "selected")
    }
}

// MARK: - Nested Types

extension OrdersFilterOperationsTests {

    /// 清除篩選的一組已套用條件
    struct ClearFilterCase: Sendable {

        /// 已套用日期
        let datePeriod: OrderDatePeriod

        /// 已套用類別集合
        let categories: Set<String>

        /// 已套用付款方式
        let paymentMethod: String?
    }
}

// MARK: - Private Method

private extension OrdersFilterOperationsTests {

    /// 三項條件的七種啟用組合，另含多個類別的清空案例
    static var activeClearFilterCases: [ClearFilterCase] {
        [
            ClearFilterCase(datePeriod: .thisMonth, categories: [], paymentMethod: nil),
            ClearFilterCase(datePeriod: .all, categories: ["beauty"], paymentMethod: nil),
            ClearFilterCase(datePeriod: .all, categories: [], paymentMethod: "現金"),
            ClearFilterCase(datePeriod: .thisMonth, categories: ["beauty"], paymentMethod: nil),
            ClearFilterCase(datePeriod: .thisMonth, categories: [], paymentMethod: "現金"),
            ClearFilterCase(datePeriod: .all, categories: ["beauty"], paymentMethod: "現金"),
            ClearFilterCase(datePeriod: .thisMonth, categories: ["beauty"], paymentMethod: "現金"),
            ClearFilterCase(datePeriod: .all, categories: ["beauty", "books"], paymentMethod: nil),
        ]
    }
}
