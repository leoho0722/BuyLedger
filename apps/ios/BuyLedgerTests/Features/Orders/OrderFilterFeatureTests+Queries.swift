//
//  OrderFilterFeatureTests+Queries.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension OrderFilterFeatureTests {

    /// 任一暫存欄位不同時才視為未套用變更
    ///
    /// - Parameter testCase: 三欄暫存比較案例
    @Test(arguments: Self.dirtyCases)
    func hasUnappliedFilterChanges_比較三欄暫存_判斷是否有變更(testCase: DirtyCase) {
        // Given
        var state = Self.makeState()
        state.pendingFilterSelection = OrderFilterSelection(
            datePeriod: testCase.date,
            categories: testCase.category.map { [$0] } ?? [],
            paymentMethod: testCase.paymentMethod
        )

        // When
        let hasUnappliedFilterChanges = state.hasUnappliedFilterChanges

        // Then
        #expect(hasUnappliedFilterChanges == testCase.hasUnappliedChanges)
    }

    /// 分組沿用主檔與訂單類別合併、去空白及不分大小寫搜尋
    ///
    /// - Parameters:
    ///   - searchText: 面板搜尋文字
    ///   - expectedCategories: 獨立字面值的相符類別
    @Test(arguments: Self.categoryQueryCases)
    func filterSheetCategoryGroups_搜尋主檔與訂單類別_回傳相符名稱(
        searchText: String,
        expectedCategories: [String]
    ) {
        // Given
        var state = OrderFilterFeature.State(
            orders: SharedReader(value: [
                OrdersFeatureTests.makeOrder(id: "A", category: " books "),
            ]),
            campaigns: SharedReader(value: []),
            lookupCatalog: SharedReader(value: LookupCatalog(categories: ["beauty", "snacks"])),
            committedFilterSelection: OrderFilterSelection(),
            dateContext: OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        )
        state.filterSheetSearchText = searchText

        // When
        let categories = state.filterSheetCategoryGroups.flatMap(\.visibleCategories)

        // Then
        #expect(categories == expectedCategories)
    }

    /// 付款方式合併主檔與訂單值並去空白，類別搜尋不改選項
    ///
    /// - Parameter searchText: 面板搜尋文字
    @Test(arguments: Self.paymentQueryCases)
    func availablePaymentMethodNames_類別搜尋不同文字_完整保留主檔與訂單付款方式(searchText: String) {
        // Given
        var state = OrderFilterFeature.State(
            orders: SharedReader(value: [
                OrdersFeatureTests.makeOrder(id: "A", category: "美妝", paymentMethod: " Cash "),
            ]),
            campaigns: SharedReader(value: []),
            lookupCatalog: SharedReader(
                value: LookupCatalog(paymentMethods: [
                    PaymentMethodInfo(
                        name: "Card",
                        isCardless: false,
                        isBankTransfer: false,
                        isCashOnDelivery: false
                    ),
                ])
            ),
            committedFilterSelection: OrderFilterSelection(),
            dateContext: OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        )
        state.filterSheetSearchText = searchText

        // When
        let paymentMethods = state.availablePaymentMethodNames

        // Then
        #expect(paymentMethods == ["Card", "Cash"])
        #expect(
            state.pendingFilterSelection
                == OrderFilterSelection(datePeriod: .all, categories: [], paymentMethod: nil)
        )
    }

    /// 開啟後更新共用主檔時，子層讀到更新後的選項
    @Test
    func filterSheetCategoryGroups_共用主檔更新_讀取最新選項() {
        // Given
        let catalog = Shared<LookupCatalog>(value: LookupCatalog())
        catalog.withLock {
            $0.categories = ["beauty"]
        }
        let state = OrderFilterFeature.State(
            orders: SharedReader(value: []),
            campaigns: SharedReader(value: []),
            lookupCatalog: SharedReader(catalog),
            committedFilterSelection: OrderFilterSelection(),
            dateContext: OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        )

        // When
        catalog.withLock {
            $0.categories = ["books"]
        }

        // Then
        #expect(state.filterSheetCategoryGroups.flatMap(\.visibleCategories) == ["books"])
    }

    /// 以畫面實際使用的繫結更新搜尋文字，不改暫存條件或 dirty
    @Test
    func binding_輸入篩選搜尋文字_更新子層搜尋() {
        // Given
        let store = withDependencies {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        } operation: {
            Store(initialState: Self.makeState()) {
                OrderFilterFeature()
            }
        }
        @Bindable var bindable = store

        // When
        $bindable.filterSheetSearchText.wrappedValue = "boo"

        // Then
        #expect(store.state.filterSheetSearchText == "boo")
        #expect(
            store.state.pendingFilterSelection
                == OrderFilterSelection(datePeriod: .all, categories: [], paymentMethod: nil)
        )
        #expect(store.state.hasUnappliedFilterChanges == false)
    }

    /// 日期選單的實際繫結只更新暫存日期
    @Test
    func binding_日期選單選取本月_只改暫存日期() {
        // Given
        let store = withDependencies {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        } operation: {
            Store(initialState: Self.makeState()) {
                OrderFilterFeature()
            }
        }
        @Bindable var bindable = store

        // When
        $bindable.pendingFilterSelection.datePeriod
            .sending(\.view.filterPendingDatePeriodSelected).wrappedValue = .thisMonth

        // Then
        #expect(store.state.pendingFilterSelection.datePeriod == .thisMonth)
        #expect(store.state.pendingFilterSelection.categories == [])
        #expect(store.state.pendingFilterSelection.paymentMethod == nil)
        #expect(
            store.state.committedFilterSelection
                == OrderFilterSelection(datePeriod: .all, categories: [], paymentMethod: nil)
        )
    }

    /// 付款方式選單的實際繫結保留日期與類別，不提交清單條件
    @Test
    func binding_付款選單選取信用卡_只改暫存付款方式() {
        // Given
        let selection = OrderFilterSelection(datePeriod: .thisMonth, categories: ["美妝"])
        let store = withDependencies {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        } operation: {
            Store(initialState: Self.makeState(committedFilterSelection: selection)) {
                OrderFilterFeature()
            }
        }
        @Bindable var bindable = store

        // When
        $bindable.pendingFilterSelection.paymentMethod
            .sending(\.view.filterPendingPaymentMethodSelected).wrappedValue = "信用卡"

        // Then
        #expect(store.state.pendingFilterSelection.datePeriod == .thisMonth)
        #expect(store.state.pendingFilterSelection.categories == ["美妝"])
        #expect(store.state.pendingFilterSelection.paymentMethod == "信用卡")
        #expect(store.state.committedFilterSelection == selection)
    }

    /// 面板沿用共用訂單引用，載入或寫入後的類別立即反映
    @Test
    func filterSheetCategoryGroups_共用訂單更新_讀取最新選項() {
        // Given
        let orders = Shared<[LedgerOrder]>(value: [])
        orders.withLock {
            $0 = [OrdersFeatureTests.makeOrder(id: "A", category: "beauty")]
        }
        let state = OrderFilterFeature.State(
            orders: SharedReader(orders),
            campaigns: SharedReader(value: []),
            lookupCatalog: SharedReader(value: LookupCatalog()),
            committedFilterSelection: OrderFilterSelection(),
            dateContext: OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        )

        // When
        orders.withLock {
            $0 = [OrdersFeatureTests.makeOrder(id: "B", category: "books")]
        }

        // Then
        #expect(state.filterSheetCategoryGroups.flatMap(\.visibleCategories) == ["books"])
    }
}

// MARK: - Nested Types

extension OrderFilterFeatureTests {

    /// 三欄暫存比較案例
    struct DirtyCase: Sendable {

        /// 暫存日期
        let date: OrderDatePeriod

        /// 暫存類別
        let category: String?

        /// 暫存付款方式
        let paymentMethod: String?

        /// 是否應視為未套用變更
        let hasUnappliedChanges: Bool
    }
}

// MARK: - Private Method

private extension OrderFilterFeatureTests {

    /// 比較三欄暫存與未套用變更的測試案例
    ///
    /// - Note: 只建立值，不存取測試的主執行緒狀態
    nonisolated static var dirtyCases: [DirtyCase] {
        [
            DirtyCase(
                date: .all,
                category: nil,
                paymentMethod: nil,
                hasUnappliedChanges: false
            ),
            DirtyCase(
                date: .thisMonth,
                category: nil,
                paymentMethod: nil,
                hasUnappliedChanges: true
            ),
            DirtyCase(
                date: .all,
                category: "美妝",
                paymentMethod: nil,
                hasUnappliedChanges: true
            ),
            DirtyCase(
                date: .all,
                category: nil,
                paymentMethod: "信用卡",
                hasUnappliedChanges: true
            ),
            DirtyCase(
                date: .all,
                category: "",
                paymentMethod: nil,
                hasUnappliedChanges: true
            ),
        ]
    }

    /// 類別搜尋的大小寫、空白、空字串與無結果案例
    ///
    /// - Note: 只建立值，不存取測試的主執行緒狀態
    nonisolated static var categoryQueryCases: [(String, [String])] {
        [
            ("BOO", ["books"]),
            ("  boo \n", ["books"]),
            ("", ["beauty", "books", "snacks"]),
            ("不存在", []),
        ]
    }

    /// 付款方式不得受任何類別搜尋文字縮減
    ///
    /// - Note: 只建立值，不存取測試的主執行緒狀態
    nonisolated static var paymentQueryCases: [String] {
        ["CAR", "  car \n", "", "不存在"]
    }
}
