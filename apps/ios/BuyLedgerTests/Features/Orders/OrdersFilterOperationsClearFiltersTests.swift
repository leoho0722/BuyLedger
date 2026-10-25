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

    /// 驗證任一或多項條件啟用時，清除日期、類別與付款方式三項並還原為預設、回報有變更，狀態與搜尋文字保留，並依清除後的結果重選訂單
    ///
    /// - Parameter filterCase: 已套用的日期、類別與付款方式
    @Test(arguments: Self.activeClearFilterCases)
    func clearFilters_單項或混合條件啟用_還原預設並回報變更(filterCase: ClearFilterCase) {
        // Given
        var state = OrderListFeatureTestSupport.makeClearFiltersState()
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

    /// 驗證三項條件已是預設、只剩狀態與搜尋文字時，清除回報未變更，整體狀態與原本選取的「selected」都保留
    @Test
    func clearFilters_三項已是預設且有狀態搜尋_回報未變更並保留整體狀態() {
        // Given
        var state = OrderListFeatureTestSupport.makeClearFiltersState()
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
