//
//  OrderListFeatureDestinationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrderListFeature` 的單元測試，涵蓋篩選面板的開啟與狀態同步
struct OrderListFeatureDestinationTests {

    /// 驗證清單尚未記錄日期脈絡時按下篩選，以注入的時間補上日期脈絡，並把同一份脈絡交給篩選面板
    @Test
    @MainActor
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
        var filter = OrderFilterFeatureTestSupport.makeState(for: initial)
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

    /// 驗證根功能因重大時間變更刷新日期時，已開啟的篩選面板改用新的日期脈絡，暫存的類別與搜尋文字保留
    ///
    /// - Throws: 舊日期脈絡的固定時區無法建立時由 `#require` 丟出
    @Test
    @MainActor
    func launch_根功能刷新日期_同步面板且保留暫存() async throws {
        // Given
        var initial = RootFeatureTestSupport.makeIsolatedRootState()
        var previousCalendar = TestDependencies.fixedCalendar
        previousCalendar.timeZone = try #require(TimeZone(secondsFromGMT: 32_400))
        initial.orders.refreshDateContext(
            now: Date(timeIntervalSince1970: 0),
            calendar: previousCalendar
        )
        initial.orders.list.destination = .filterSheet(
            OrderFilterFeatureTestSupport.makeState(for: initial.orders.list)
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

    /// 驗證透過清單的繫結改變已套用類別時，篩選面板的已套用值同步為新類別加上原有的日期與付款方式，暫存的類別 beauty 保留，並仍視為有未套用變更
    @Test
    @MainActor
    func binding_面板已開啟_同步類別比較基準並保留草稿() {
        // Given
        var initial = OrderListFeatureTestSupport.makeState()
        initial.selectedDatePeriod = .thisMonth
        initial.selectedCategories = ["beauty"]
        initial.selectedPaymentMethod = "信用卡"
        initial.destination = .filterSheet(OrderFilterFeatureTestSupport.makeState(for: initial))
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

    /// 驗證深連結直接套用篩選時，篩選面板的已套用值改為 books 與原付款方式、日期回到全部，暫存的日期與類別都保留
    @Test
    func applyFilterNavigation_面板已開啟_同步比較基準並保留草稿() {
        // Given
        var state = OrderListFeatureTestSupport.makeState()
        state.selectedDatePeriod = .thisMonth
        state.selectedCategories = ["beauty"]
        state.selectedPaymentMethod = "信用卡"
        state.destination = .filterSheet(OrderFilterFeatureTestSupport.makeState(for: state))

        // When
        state.applyFilterNavigation(searchText: "林", category: "books")

        // Then
        #expect(state.searchText == "林")
        #expect(
            state.destination?.filterSheet?.committedFilterSelection
                == OrderFilterSelection(
                    datePeriod: .all,
                    categories: ["books"],
                    paymentMethod: "信用卡"
                )
        )
        #expect(state.destination?.filterSheet?.pendingFilterSelection.datePeriod == .thisMonth)
        #expect(state.destination?.filterSheet?.pendingFilterSelection.categories == ["beauty"])
        #expect(state.destination?.filterSheet?.hasUnappliedFilterChanges == true)
    }

    /// 驗證根功能更新開團後，已開啟的篩選面板沿用的開團引用讀到新值，清單與面板的開團都是更新後的內容
    ///
    /// - Throws: 面板沒有提供開團引用時由 `#require` 丟出
    @Test
    @MainActor
    func campaigns_根功能更新開團_已開啟面板引用讀到新值() async throws {
        // Given
        let previous = Campaign.fixture(id: "C1", name: "舊團")
        let updated = Campaign.fixture(id: "C1", name: "新團")
        var initial = RootFeatureTestSupport.makeIsolatedRootState()
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
        var filter = OrderFilterFeatureTestSupport.makeState(for: initial.orders.list)
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
