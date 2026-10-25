//
//  OrdersSearchCancellationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/20.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderListFeature` 的單元測試，以 TestStore 逐步驗證系統搜尋列取消後的篩選狀態
@MainActor
struct OrdersSearchCancellationTests {

    // MARK: - Properties

    /// 測試用訂單：兩筆美妝、一筆零食，客戶名稱各異
    private static let orders: [LedgerOrder] = [
        makeOrder(id: "A", customer: "小美", category: "美妝"),
        makeOrder(id: "B", customer: "阿明", category: "美妝"),
        makeOrder(id: "C", customer: "阿華", category: "零食"),
    ]

    /// 驗證搜尋列取消、查詢改為空字串時，查詢清空，選取的 A 維持不變，清單恢復為 A、B、C 三筆，並送出 `delegate.selectionChanged`
    ///
    /// - Throws: 搜尋前置條件不成立時丟出測試錯誤
    @Test
    func searchTextChanged_取消搜尋_清空查詢並恢復完整清單() async throws {
        // Given
        var initial = OrderListFeatureTestSupport.makeState(orders: Self.orders)
        initial.searchText = "小美"
        initial.selectedOrderID = "A"
        try #require(initial.filteredOrders.map(\.id) == ["A"])
        let store = TestStore(initialState: initial) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.searchTextChanged(""))) {
            $0.searchText = ""
            $0.selectedOrderID = "A"
        }

        // Then
        await store.receive(\.delegate.selectionChanged)
        #expect(store.state.searchText.isEmpty)
        let restored = store.state.filteredOrders
        #expect(restored.map(\.id) == ["A", "B", "C"])
    }

    /// 驗證搜尋列取消時只解除查詢，已套用的類別篩選維持「美妝」，清單剩 A、B 兩筆，並送出 `delegate.selectionChanged`
    @Test
    func searchTextChanged_取消搜尋且有類別篩選_保留其他篩選() async {
        // Given
        var initial = OrderListFeatureTestSupport.makeState(orders: Self.orders)
        initial.selectedCategories = ["美妝"]
        initial.searchText = "小美"
        initial.selectedOrderID = "A"
        let store = TestStore(initialState: initial) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.searchTextChanged(""))) {
            $0.searchText = ""
            $0.selectedOrderID = "A"
        }

        // Then
        await store.receive(\.delegate.selectionChanged)
        #expect(store.state.selectedCategories == ["美妝"])
        let restored = store.state.filteredOrders
        #expect(restored.map(\.id) == ["A", "B"])
    }
}

// MARK: - Private Method

private extension OrdersSearchCancellationTests {

    /// 建立搜尋取消測試用的最小訂單
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - customer: 客戶名稱
    ///   - category: 商品類別
    /// - Returns: 建立的測試訂單
    static func makeOrder(id: String, customer: String, category: String) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: customer, initials: "XX", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [
                LedgerOrderItem(
                    id: UUID(0),
                    name: "示範商品",
                    quantity: 1,
                    unitPrice: 100
                ),
            ],
            itemCost: 100,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 1_000,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "蝦皮",
            categories: [category],
            paymentMethod: "信用卡",
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
