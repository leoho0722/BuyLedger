//
//  OrderFilterFeatureQueriesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrderFilterFeature` 的單元測試，涵蓋未套用變更判定、類別與付款方式查詢，以及畫面綁定
struct OrderFilterFeatureQueriesTests {

    /// 驗證暫存三欄任一與已套用值不同時才有未套用變更，類別為空字串也算不同
    ///
    /// - Parameter testCase: 三欄暫存比較案例
    @Test(arguments: Self.dirtyCases)
    func hasUnappliedFilterChanges_比較三欄暫存_判斷是否有變更(testCase: DirtyCase) {
        // Given
        var state = OrderFilterFeatureTestSupport.makeState()
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

    /// 驗證搜尋類別時，分組合併主檔與訂單類別，搜尋文字去除空白並不分大小寫比對，空字串列出全部，無相符時為空
    ///
    /// - Parameter testCase: 測試輸入與字面值預期結果
    @Test(arguments: Self.categoryQueryCases)
    func filterSheetCategoryGroups_搜尋主檔與訂單類別_回傳相符名稱(testCase: CategoryQueryCase) {
        // Given
        var state = OrderFilterFeature.State(
            orders: SharedReader(value: [
                OrdersFeatureTestSupport.makeOrder(id: "A", category: " books "),
            ]),
            campaigns: SharedReader(value: []),
            lookupCatalog: SharedReader(value: LookupCatalog(categories: ["beauty", "snacks"])),
            committedFilterSelection: OrderFilterSelection(),
            dateContext: OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        )
        state.filterSheetSearchText = testCase.searchText

        // When
        let categories = state.filterSheetCategoryGroups.flatMap(\.visibleCategories)

        // Then
        #expect(categories == testCase.expectedCategories)
    }

    /// 驗證無論類別搜尋文字為何，付款方式選項都完整保留主檔與訂單的付款方式，並去除空白
    ///
    /// - Parameter searchText: 面板搜尋文字
    @Test(arguments: Self.paymentQueryCases)
    func availablePaymentMethodNames_類別搜尋不同文字_完整保留主檔與訂單付款方式(searchText: String) {
        // Given
        var state = OrderFilterFeature.State(
            orders: SharedReader(value: [
                OrdersFeatureTestSupport.makeOrder(
                    id: "A",
                    category: "美妝",
                    paymentMethod: " Cash "
                ),
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
    }

    /// 驗證面板建立後共用主檔的類別被更新時，分組讀到的是更新後的類別
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

    /// 驗證搜尋框經繫結輸入文字時，只更新搜尋文字，暫存條件與未套用變更都不變
    @Test
    @MainActor
    func binding_輸入篩選搜尋文字_更新子層搜尋() {
        // Given
        let store = withDependencies {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        } operation: {
            Store(initialState: OrderFilterFeatureTestSupport.makeState()) {
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

    /// 驗證日期選單經繫結選取本月時，只更新暫存日期，類別、付款方式與已套用條件都不變
    @Test
    @MainActor
    func binding_日期選單選取本月_只改暫存日期() {
        // Given
        let store = withDependencies {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        } operation: {
            Store(initialState: OrderFilterFeatureTestSupport.makeState()) {
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

    /// 驗證付款方式選單經繫結選取信用卡時，只更新暫存付款方式，日期與類別保留，已套用的條件不變
    @Test
    @MainActor
    func binding_付款選單選取信用卡_只改暫存付款方式() {
        // Given
        let selection = OrderFilterSelection(datePeriod: .thisMonth, categories: ["美妝"])
        let store = withDependencies {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        } operation: {
            Store(
                initialState: OrderFilterFeatureTestSupport.makeState(
                    committedFilterSelection: selection
                )
            ) {
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

    /// 驗證面板持有共用的訂單引用，共用訂單更新後分組立即讀到新的類別
    @Test
    func filterSheetCategoryGroups_共用訂單更新_讀取最新選項() {
        // Given
        let orders = Shared<[LedgerOrder]>(value: [])
        orders.withLock {
            $0 = [OrdersFeatureTestSupport.makeOrder(id: "A", category: "beauty")]
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
            $0 = [OrdersFeatureTestSupport.makeOrder(id: "B", category: "books")]
        }

        // Then
        #expect(state.filterSheetCategoryGroups.flatMap(\.visibleCategories) == ["books"])
    }
}

// MARK: - Nested Types

extension OrderFilterFeatureQueriesTests {

    /// 類別查詢的搜尋文字與預期結果
    struct CategoryQueryCase: Sendable {

        /// 面板搜尋文字
        let searchText: String

        /// 預期相符的類別字面值
        let expectedCategories: [String]
    }

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

private extension OrderFilterFeatureQueriesTests {

    /// 比較三欄暫存與未套用變更的測試案例
    static var dirtyCases: [DirtyCase] {
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
    static var categoryQueryCases: [CategoryQueryCase] {
        [
            CategoryQueryCase(searchText: "BOO", expectedCategories: ["books"]),
            CategoryQueryCase(searchText: "  boo \n", expectedCategories: ["books"]),
            CategoryQueryCase(searchText: "", expectedCategories: ["beauty", "books", "snacks"]),
            CategoryQueryCase(searchText: "不存在", expectedCategories: []),
        ]
    }

    /// 付款方式選項測試使用的類別搜尋文字，涵蓋大小寫、空白、空字串與無結果
    static var paymentQueryCases: [String] {
        ["CAR", "  car \n", "", "不存在"]
    }
}
