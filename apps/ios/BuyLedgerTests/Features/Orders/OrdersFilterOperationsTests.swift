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

/// 驗證 `OrdersFilterOperations` 的狀態變化
struct OrdersFilterOperationsTests {

    /// 驗證切換狀態時重選第一筆相符訂單
    @Test
    func statusFilterSelected_切換狀態_重選第一筆相符訂單() {
        // Given
        var state = OrderListFeatureTests.makeState(orders: [
            makeOrder(id: "A", status: .quoting),
            makeOrder(id: "B", status: .delivered),
        ])

        // When
        OrdersFilterOperations.statusFilterSelected(.status(.delivered), state: &state)

        // Then
        #expect(state.selectedStatus == .status(.delivered))
        #expect(state.selectedOrderID == "B")
    }

    /// 驗證切換日期時重選第一筆相符訂單
    ///
    /// - Throws: 日期無法建立時拋出測試錯誤
    @Test
    func datePeriodSelected_切換日期_重選第一筆相符訂單() throws {
        // Given
        let march = try Self.date(year: 2026, month: 3, day: 15)
        var state = OrderListFeatureTests.makeState(orders: [
            makeOrder(id: "A", date: march),
            makeOrder(id: "B", date: TestDependencies.fixedNow),
        ])

        // When
        OrdersFilterOperations.datePeriodSelected(.thisMonth, state: &state)

        // Then
        #expect(state.selectedDatePeriod == .thisMonth)
        #expect(state.selectedOrderID == "B")
    }

    /// 驗證切換類別時重選第一筆相符訂單
    @Test
    func categoryApplied_切換類別_重選第一筆相符訂單並關閉() {
        // Given
        let initialOrders = [makeOrder(id: "A", category: "美妝"), makeOrder(id: "B", category: "服飾")]
        var state = OrderListFeatureTests.makeState(orders: initialOrders)
        state.selectedCategories = ["beauty", "books"]
        state.destination = .categoryPicker(OrderCategoryPickerFeatureTests.makeState(for: state))

        // When
        OrdersFilterOperations.categoryApplied(["服飾"], state: &state)

        // Then
        #expect(state.selectedCategories == ["服飾"])
        #expect(state.selectedOrderID == "B")
        #expect(state.destination == nil)
    }

    /// 驗證切換付款方式時重選第一筆相符訂單
    @Test
    func paymentMethodFilterSelected_切換付款方式_重選第一筆相符訂單() {
        // Given
        var state = OrderListFeatureTests.makeState(orders: [
            makeOrder(id: "A", paymentMethod: "信用卡"),
            makeOrder(id: "B", paymentMethod: "現金"),
        ])

        // When
        OrdersFilterOperations.paymentMethodFilterSelected("現金", state: &state)

        // Then
        #expect(state.selectedPaymentMethod == "現金")
        #expect(state.selectedOrderID == "B")
    }

    /// 任一非預設欄位啟用篩選，全部預設時停用
    ///
    /// - Parameter testCase: 已套用的日期、類別、付款方式與預期的啟用狀態
    @Test(arguments: [
        ActiveFilterCase(
            date: OrderDatePeriod.all,
            categories: Set<String>(),
            paymentMethod: nil,
            isActive: false,
        ),
        ActiveFilterCase(
            date: .thisWeek,
            categories: Set<String>(),
            paymentMethod: nil,
            isActive: true,
        ),
        ActiveFilterCase(
            date: .all,
            categories: Set<String>(["美妝"]),
            paymentMethod: nil,
            isActive: true,
        ),
        ActiveFilterCase(
            date: .all,
            categories: Set<String>(),
            paymentMethod: "信用卡",
            isActive: true,
        ),
        ActiveFilterCase(
            date: .thisWeek,
            categories: Set<String>(["美妝"]),
            paymentMethod: nil,
            isActive: true,
        ),
        ActiveFilterCase(
            date: .thisWeek,
            categories: Set<String>(),
            paymentMethod: "信用卡",
            isActive: true,
        ),
        ActiveFilterCase(
            date: .all,
            categories: Set<String>(["美妝"]),
            paymentMethod: "信用卡",
            isActive: true,
        ),
        ActiveFilterCase(
            date: .thisWeek,
            categories: Set<String>(["美妝"]),
            paymentMethod: "信用卡",
            isActive: true,
        ),
        ActiveFilterCase(
            date: .all,
            categories: Set<String>(["美妝", "書籍"]),
            paymentMethod: nil,
            isActive: true,
        ),
        ActiveFilterCase(
            date: .all,
            categories: Set<String>([""]),
            paymentMethod: nil,
            isActive: true,
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

        /// 真值表的預期結果
        let isActive: Bool
    }
}

// MARK: - Internal Method

extension OrdersFilterOperationsTests {

    /// 建立固定行事曆與 UTC 時區的指定年月日日期
    ///
    /// - Parameters:
    ///   - year: 西元年
    ///   - month: 月份
    ///   - day: 日期
    /// - Returns: 指定日期 UTC 零時的時間值
    /// - Throws: 年月日無法組成日期時拋出測試錯誤
    static func date(year: Int, month: Int, day: Int) throws -> Date {
        var components = DateComponents()
        components.calendar = TestDependencies.fixedCalendar
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        return try #require(components.date)
    }

    /// 建立僅供篩選測試使用的最小訂單；非相關欄位以零值或佔位填入
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - status: 訂單狀態
    ///   - date: 訂單日期
    ///   - category: 商品類別
    ///   - paymentMethod: 付款方式
    /// - Returns: 建立的測試訂單
    func makeOrder(
        id: String,
        status: OrderStatus = .quoting,
        date: Date = TestDependencies.fixedNow,
        category: String = "類別",
        paymentMethod: String = "付款"
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "客戶\(id)", initials: "XX", tier: .new),
            status: status,
            currency: .twd,
            date: date,
            items: [
                LedgerOrderItem(
                    id: UUID(0),
                    name: "商品",
                    quantity: 1,
                    unitPrice: 100
                ),
            ],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "來源",
            categories: [category],
            paymentMethod: paymentMethod,
            notes: "",
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
}
