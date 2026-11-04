//
//  OrdersFilterOperationsClearFiltersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import Testing

@testable import BuyLedger

/// `OrdersFilterOperations.clearFilters` 的單元測試，直接以 `inout` 狀態呼叫並斷言結果
struct OrdersFilterOperationsClearFiltersTests {

    /// 驗證任一或多項條件啟用時，清除日期、類別與付款方式，並保留狀態與搜尋文字，結果仍列出符合條件的訂單
    ///
    /// - Parameter filterCase: 已套用的日期、類別與付款方式
    @Test(arguments: Self.activeClearFilterCases)
    func clearFilters_單項或混合條件啟用_還原預設並保留狀態與搜尋(filterCase: ClearFilterCase) {
        // Given
        var state = OrderListFeatureTestSupport.makeClearFiltersState()
        state.selectedDatePeriod = filterCase.datePeriod
        state.selectedCategories = filterCase.categories
        state.selectedPaymentMethod = filterCase.paymentMethod

        // When
        OrdersFilterOperations.clearFilters(state: &state)

        // Then
        #expect(state.selectedDatePeriod == .all)
        #expect(state.selectedCategories == [])
        #expect(state.selectedPaymentMethod == nil)
        #expect(state.selectedStatus == .status(.purchased))
        #expect(state.searchText == "Alice")
        #expect(
            state.filteredOrders.map(\.id) == [
                "restored",
                "dateOnly",
                "categoryOnly",
                "paymentOnly",
                "matched",
            ]
        )
        #expect(state.committedFilterSelection.isActive == false)
    }

    /// 驗證三項條件已是預設、只剩狀態與搜尋文字時，清除不改變任何狀態
    @Test
    func clearFilters_三項已是預設且有狀態搜尋_不改變整體狀態() {
        // Given
        var state = OrderListFeatureTestSupport.makeClearFiltersState()
        state.selectedDatePeriod = .all
        state.selectedCategories = []
        state.selectedPaymentMethod = nil
        let initial = state

        // When
        OrdersFilterOperations.clearFilters(state: &state)

        // Then
        #expect(state == initial)
    }
}

// MARK: - Nested Types

extension OrdersFilterOperationsClearFiltersTests {

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

private extension OrdersFilterOperationsClearFiltersTests {

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
