//
//  OrderListFeatureFilterPendingTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrderListFeature` 的單元測試，以 TestStore 逐步驗證篩選面板內的暫存操作
@MainActor
struct OrderListFeatureFilterPendingTests {

    /// 驗證篩選面板內選擇本月日期時只改暫存的日期，清單已套用的日期、類別與付款方式都不變，並視為有未套用變更
    @Test
    func destination_調整待確認日期_不改已提交值() async {
        // Given
        var state = OrdersFeature.State()
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.list.selectedDatePeriod = .all
        state.list.selectedCategories = []
        state.list.selectedPaymentMethod = nil
        state.list.destination = .filterSheet(
            OrderFilterFeatureTestSupport.makeState(for: state.list)
        )
        state.list.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection = OrderFilterSelection(
                datePeriod: .all,
                categories: [],
                paymentMethod: nil
            )
        }

        let store = TestStore(initialState: state.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .destination(
                .presented(.filterSheet(.view(.filterPendingDatePeriodSelected(.thisMonth))))
            )
        ) {
            $0.destination?.modify(\.filterSheet) {
                $0.pendingFilterSelection.datePeriod = .thisMonth
            }
        }

        // Then
        #expect(store.state.destination?.filterSheet?.hasUnappliedFilterChanges == true)
        #expect(store.state.selectedDatePeriod == .all)
        #expect(store.state.selectedCategories == [])
        #expect(store.state.selectedPaymentMethod == nil)
        #expect(
            store.state.destination?.filterSheet?.pendingFilterSelection.datePeriod == .thisMonth
        )
    }

    /// 驗證篩選面板內勾選 beauty 類別時只改暫存類別，清單已套用的篩選都不變，並視為有未套用變更
    @Test
    func destination_調整待確認類別_不改已提交值() async {
        // Given
        var state = OrdersFeature.State()
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.list.selectedDatePeriod = .all
        state.list.selectedCategories = []
        state.list.selectedPaymentMethod = nil
        state.list.destination = .filterSheet(
            OrderFilterFeatureTestSupport.makeState(for: state.list)
        )
        state.list.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection = OrderFilterSelection(
                datePeriod: .all,
                categories: [],
                paymentMethod: nil
            )
        }

        let store = TestStore(initialState: state.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .destination(.presented(.filterSheet(.view(.filterPendingCategoryToggled("beauty")))))
        ) {
            $0.destination?.modify(\.filterSheet) {
                $0.pendingFilterSelection.categories = ["beauty"]
            }
        }

        // Then
        #expect(store.state.destination?.filterSheet?.hasUnappliedFilterChanges == true)
        #expect(store.state.selectedDatePeriod == .all)
        #expect(store.state.selectedCategories == [])
        #expect(store.state.selectedPaymentMethod == nil)
        #expect(
            store.state.destination?.filterSheet?.pendingFilterSelection.categories == ["beauty"]
        )
    }

    /// 驗證篩選面板內選擇信用卡付款方式時只改暫存的付款方式，清單已套用的篩選都不變，並視為有未套用變更
    @Test
    func destination_調整待確認付款方式_不改已提交值() async {
        // Given
        var state = OrdersFeature.State()
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.list.selectedDatePeriod = .all
        state.list.selectedCategories = []
        state.list.selectedPaymentMethod = nil
        state.list.destination = .filterSheet(
            OrderFilterFeatureTestSupport.makeState(for: state.list)
        )
        state.list.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection = OrderFilterSelection(
                datePeriod: .all,
                categories: [],
                paymentMethod: nil
            )
        }

        let store = TestStore(initialState: state.list) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(
            .destination(
                .presented(.filterSheet(.view(.filterPendingPaymentMethodSelected("信用卡"))))
            )
        ) {
            $0.destination?.modify(\.filterSheet) {
                $0.pendingFilterSelection.paymentMethod = "信用卡"
            }
        }

        // Then
        #expect(store.state.destination?.filterSheet?.hasUnappliedFilterChanges == true)
        #expect(store.state.selectedDatePeriod == .all)
        #expect(store.state.selectedCategories == [])
        #expect(store.state.selectedPaymentMethod == nil)
        #expect(store.state.destination?.filterSheet?.pendingFilterSelection.paymentMethod == "信用卡")
    }

    /// 驗證篩選面板搜尋類別時，只過濾類別清單，付款方式選項保持完整，暫存的選擇不變
    ///
    /// - Parameter testCase: 搜尋文字與預期留下的類別
    /// - Note: 清單與篩選共用同一份唯讀主檔引用
    @Test(arguments: Self.filterCategorySearchCases)
    func destination_輸入篩選搜尋文字_只過濾分類且保留完整付款方式(testCase: FilterCategorySearchCase) async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var state = OrdersFeature.State()
            state.refreshDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            state.$lookupCatalog = SharedReader(
                value: LookupCatalog(
                    categories: ["beauty", "snacks", "books"],
                    paymentMethods: [
                        PaymentMethodInfo(
                            name: "轉帳",
                            isCardless: false,
                            isBankTransfer: true,
                            isCashOnDelivery: false
                        ),
                        PaymentMethodInfo(
                            name: "orders.list.label.cashDelivery",
                            isCardless: false,
                            isBankTransfer: false,
                            isCashOnDelivery: true
                        ),
                    ]
                )
            )
            state.list.$lookupCatalog = state.$lookupCatalog

            state.list.destination = .filterSheet(
                OrderFilterFeatureTestSupport.makeState(for: state.list)
            )
            let store = TestStore(initialState: state.list) {
                OrderListFeature()
            } withDependencies: {
                $0.date = .constant(TestDependencies.fixedNow)
                $0.calendar = TestDependencies.fixedCalendar
            }

            // When
            await store.send(
                .destination(
                    .presented(
                        .filterSheet(.binding(.set(\.filterSheetSearchText, testCase.searchText)))
                    )
                )
            ) {
                $0.destination?.modify(\.filterSheet) {
                    $0.filterSheetSearchText = testCase.searchText
                }
            }

            // Then
            let sheet = store.state.destination?.filterSheet
            let categories = sheet?.filterSheetCategoryGroups.flatMap(\.visibleCategories)
            #expect(categories == testCase.expectedCategories)
            #expect(
                sheet?.pendingFilterSelection
                    == OrderFilterSelection(datePeriod: .all, categories: [], paymentMethod: nil)
            )
            #expect(
                Set(sheet?.availablePaymentMethodNames ?? [])
                    == Set<String>(["轉帳", "orders.list.label.cashDelivery"])
            )
        }
    }
}

// MARK: - Nested Types

extension OrderListFeatureFilterPendingTests {

    /// 篩選面板類別搜尋的測試案例，含搜尋文字與預期留下的類別
    struct FilterCategorySearchCase: Sendable {

        /// 要比對的搜尋文字
        let searchText: String

        /// 預期留下的類別
        let expectedCategories: [String]
    }
}

// MARK: - Private Method

private extension OrderListFeatureFilterPendingTests {

    /// 類別搜尋的字面值案例
    ///
    /// - Note: 只建立字面值，不存取 `@MainActor` 狀態
    nonisolated static var filterCategorySearchCases: [FilterCategorySearchCase] {
        [
            FilterCategorySearchCase(searchText: "boo", expectedCategories: ["books"]),
            FilterCategorySearchCase(searchText: "ook", expectedCategories: ["books"]),
            FilterCategorySearchCase(searchText: "BOO", expectedCategories: ["books"]),
            FilterCategorySearchCase(searchText: "轉帳", expectedCategories: []),
        ]
    }
}
