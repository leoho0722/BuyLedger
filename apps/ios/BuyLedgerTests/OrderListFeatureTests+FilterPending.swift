//
//  OrderListFeatureTests+FilterPending.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension OrderListFeatureTests {

    /// 調整待確認日期篩選只改暫存值，已套用的篩選不變
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
        state.list.destination = .filterSheet(OrderFilterFeatureTests.makeState(for: state.list))
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
            store.state.destination?.filterSheet?.pendingFilterSelection.datePeriod
                == .thisMonth
        )
    }

    /// 調整待確認類別只改暫存值，已套用的篩選不變
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
        state.list.destination = .filterSheet(OrderFilterFeatureTests.makeState(for: state.list))
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
            store.state.destination?.filterSheet?.pendingFilterSelection.categories
                == ["beauty"]
        )
    }

    /// 調整待確認付款方式只改暫存值，已套用的篩選不變
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
        state.list.destination = .filterSheet(OrderFilterFeatureTests.makeState(for: state.list))
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

    /// 篩選面板只搜尋類別，付款方式選項始終完整且不改暫存選擇
    ///
    /// - Parameters:
    ///   - searchText: 要比對的搜尋文字
    ///   - expectedCategories: 預期留下的類別
    /// - Note: 以唯讀常數目錄準備分類與付款方式，清單與篩選共用同一份引用
    @Test(arguments: Self.filterCategorySearchCases)
    func destination_輸入篩選搜尋文字_只過濾分類且保留完整付款方式(
        searchText: String,
        expectedCategories: [String]
    ) async {
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
                OrderFilterFeatureTests.makeState(for: state.list)
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
                    .presented(.filterSheet(.binding(.set(\.filterSheetSearchText, searchText))))
                )
            ) {
                $0.destination?.modify(\.filterSheet) {
                    $0.filterSheetSearchText = searchText
                }
            }

            // Then
            let sheet = store.state.destination?.filterSheet
            let categories = sheet?.filterSheetCategoryGroups.flatMap(\.visibleCategories)
            #expect(categories == expectedCategories)
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

// MARK: - Private Method

private extension OrderListFeatureTests {

    /// 類別專用搜尋的字面值案例
    ///
    /// - Note: 只建立值，不存取測試的主執行緒狀態
    nonisolated static var filterCategorySearchCases: [(String, [String])] {
        [
            ("boo", ["books"]),
            ("ook", ["books"]),
            ("BOO", ["books"]),
            ("轉帳", []),
        ]
    }
}
