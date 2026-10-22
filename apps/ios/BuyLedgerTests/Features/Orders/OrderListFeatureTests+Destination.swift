//
//  OrderListFeatureTests+Destination.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension OrderListFeatureTests {

    /// 尚未記錄日期時開啟面板，清單與子層都使用注入的日期脈絡
    @Test
    func filterSheetTapped_日期脈絡為空_補上注入時間並傳給面板() async {
        // Given
        let initial = OrderListFeature.State(orders: SharedReader(value: []))
        let context = OrderDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: initial) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        var filter = OrderFilterFeatureTests.makeState(for: initial)
        filter.dateContext = context
        filter.pendingFilterSelection = OrderFilterSelection(
            datePeriod: .all,
            categories: [],
            paymentMethod: nil
        )
        filter.categoryGroupExpansion = OrderCategoryGroups.Expansion(expandedKinds: [])

        // When
        await store.send(.view(.filterSheetTapped)) {
            $0.dateContext = context
            $0.destination = .filterSheet(filter)
        }

        // Then
        #expect(store.state.dateContext == context)
        #expect(store.state.destination?.filterSheet?.dateContext == context)
    }

    /// 根功能刷新日期時同步已開啟的面板，保留尚未套用的選擇與搜尋
    ///
    /// - Throws: 舊日期脈絡的固定時區無法建立時由 `#require` 丟出
    @Test
    func launch_根功能刷新日期_同步面板且保留暫存() async throws {
        // Given
        var initial = RootFeatureTests.makeIsolatedRootState()
        var previousCalendar = TestDependencies.fixedCalendar
        previousCalendar.timeZone = try #require(TimeZone(secondsFromGMT: 32_400))
        initial.orders.refreshDateContext(
            now: Date(timeIntervalSince1970: 0),
            calendar: previousCalendar
        )
        initial.orders.list.destination = .filterSheet(
            OrderFilterFeatureTests.makeState(for: initial.orders.list)
        )
        initial.orders.list.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection.categories = ["未套用"]
            $0.filterSheetSearchText = "草稿"
        }
        let context = OrderDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.launch(.delegate(.significantTimeChanged))) {
            $0.campaigns.list.dateContext = CampaignDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.orders.list.dateContext = context
            $0.orders.list.destination?.modify(\.filterSheet) {
                $0.dateContext = context
            }
            $0.dashboard.dateContext = DashboardDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.insights.dateContext = InsightsDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        #expect(store.state.orders.list.destination?.filterSheet?.dateContext == context)
        #expect(
            store.state.orders.list.destination?.filterSheet?.pendingFilterSelection.categories
                == ["未套用"]
        )
        #expect(store.state.orders.list.destination?.filterSheet?.filterSheetSearchText == "草稿")
    }

    /// 經實際 binding 改變已套用類別時，面板同步完整比較基準並保留草稿
    @Test
    func binding_面板已開啟_同步類別比較基準並保留草稿() {
        // Given
        var initial = Self.makeState()
        initial.selectedDatePeriod = .thisMonth
        initial.selectedCategories = ["beauty"]
        initial.selectedPaymentMethod = "信用卡"
        initial.destination = .filterSheet(OrderFilterFeatureTests.makeState(for: initial))
        let store = Store(initialState: initial) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        @Bindable var bindable = store

        // When
        $bindable.selectedCategories.wrappedValue = ["books"]

        // Then
        #expect(store.selectedCategories == ["books"])
        #expect(
            store.destination?.filterSheet?.committedFilterSelection
                == OrderFilterSelection(
                    datePeriod: .thisMonth,
                    categories: ["books"],
                    paymentMethod: "信用卡"
                )
        )
        #expect(store.destination?.filterSheet?.pendingFilterSelection.categories == ["beauty"])
        #expect(store.destination?.filterSheet?.hasUnappliedFilterChanges == true)
    }

    /// 深連結直接套用篩選時，同步面板比較基準並保留付款方式與草稿
    @Test
    func applyFilterNavigation_面板已開啟_同步比較基準並保留草稿() {
        // Given
        var state = Self.makeState()
        state.selectedDatePeriod = .thisMonth
        state.selectedCategories = ["beauty"]
        state.selectedPaymentMethod = "信用卡"
        state.destination = .filterSheet(OrderFilterFeatureTests.makeState(for: state))

        // When
        state.applyFilterNavigation(searchText: "林", category: "books")

        // Then
        #expect(state.searchText == "林")
        #expect(
            state.destination?.filterSheet?.committedFilterSelection
                == OrderFilterSelection(categories: ["books"], paymentMethod: "信用卡")
        )
        #expect(state.destination?.filterSheet?.pendingFilterSelection.datePeriod == .thisMonth)
        #expect(state.destination?.filterSheet?.pendingFilterSelection.categories == ["beauty"])
        #expect(state.destination?.filterSheet?.hasUnappliedFilterChanges == true)
    }

    /// 根功能更新開團後，已開啟面板保留的唯讀引用讀到最新投影
    ///
    /// - Throws: 面板沒有提供開團引用時由 `#require` 丟出
    @Test
    func campaigns_根功能更新開團_已開啟面板引用讀到新值() async throws {
        // Given
        let previous = Campaign.fixture(id: "C1", name: "舊團")
        let updated = Campaign.fixture(id: "C1", name: "新團")
        var initial = RootFeatureTests.makeIsolatedRootState()
        initial.campaigns.$campaigns.withLock {
            $0 = [previous]
        }
        initial.orders.$campaigns.withLock {
            $0 = [previous]
        }
        initial.orders.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        var filter = OrderFilterFeatureTests.makeState(for: initial.orders.list)
        filter.categoryGroupExpansion = OrderCategoryGroups.Expansion(expandedKinds: [.ongoing])
        initial.orders.list.destination = .filterSheet(filter)
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        let sheetCampaigns = try #require(
            store.state.orders.list.destination?.filterSheet?.$campaigns
        )

        // When
        await store.send(.campaigns(.load(.campaignsResponse(.success([updated]))))) {
            $0.campaigns.$campaigns.withLock {
                $0 = [updated]
            }
            $0.campaigns.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.orders.$campaigns.withLock {
                $0 = [updated]
            }
            $0.dashboard.campaigns = [updated]
            $0.insights.campaigns = [updated]
        }

        // Then
        await store.finish()
        #expect(store.state.orders.list.campaigns == [updated])
        #expect(store.state.orders.list.destination?.filterSheet?.campaigns == [updated])
        #expect(sheetCampaigns.wrappedValue == [updated])
    }
}
