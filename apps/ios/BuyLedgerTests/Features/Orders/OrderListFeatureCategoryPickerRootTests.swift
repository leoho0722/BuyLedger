//
//  OrderListFeatureCategoryPickerRootTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderListFeature` 的單元測試，以 TestStore 逐步驗證類別選擇器與根功能的同步行為
@MainActor
struct OrderListFeatureCategoryPickerRootTests {

    /// 驗證根功能收到重大時間變更時，已開啟的類別選擇器改用新的日期脈絡，草稿、搜尋文字、搜尋焦點與展開狀態都保留
    ///
    /// - Throws: 固定時區無法建立時由 `#require` 丟出
    @Test
    func launch_根功能刷新日期_同步類別選擇器並保留草稿() async throws {
        // Given
        var initial = RootFeatureTestSupport.makeIsolatedRootState()
        var previousCalendar = TestDependencies.fixedCalendar
        previousCalendar.timeZone = try #require(TimeZone(secondsFromGMT: 32_400))
        initial.orders.refreshDateContext(
            now: Date(timeIntervalSince1970: 0),
            calendar: previousCalendar
        )
        var picker = OrderCategoryPickerFeatureTestSupport.makeState(for: initial.orders.list)
        picker.pendingCategories = ["未套用"]
        picker.searchText = "草稿"
        picker.isSearchFieldFocused = true
        picker.groupExpansion.expandedKinds = [.closed]
        initial.orders.list.destination = .categoryPicker(picker)
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
            $0.orders.list.destination?.modify(\.categoryPicker) {
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
        #expect(store.state.orders.list.destination?.categoryPicker?.dateContext == context)
        #expect(store.state.orders.list.destination?.categoryPicker?.pendingCategories == ["未套用"])
        #expect(store.state.orders.list.destination?.categoryPicker?.searchText == "草稿")
        #expect(store.state.orders.list.destination?.categoryPicker?.isSearchFieldFocused == true)
        #expect(
            store.state.orders.list.destination?.categoryPicker?.groupExpansion.expandedKinds
                == [.closed]
        )
    }

    /// 驗證根功能更新開團後，開啟時取得的選擇器開團引用讀到新值，分組依新開團重算，展開狀態不變
    ///
    /// - Throws: 選擇器的開團引用不存在時由 `#require` 丟出
    @Test
    func campaigns_根功能更新開團_類別選擇器引用讀到新值() async throws {
        // Given
        let previous = Campaign.fixture(id: "C1", name: "春季團", status: .ongoing)
        let updated = Campaign.fixture(id: "C1", name: "春季團", status: .closed)
        var initial = RootFeatureTestSupport.makeIsolatedRootState()
        initial.campaigns.$campaigns.withLock {
            $0 = [previous]
        }
        initial.orders.$campaigns.withLock {
            $0 = [previous]
        }
        initial.orders.$orders.withLock {
            $0 = [
                LedgerOrder.fixture(id: "A", categories: ["美妝"], campaignNames: ["春季團"]),
            ]
        }
        initial.orders.list.$lookupCatalog = SharedReader(value: LookupCatalog())
        initial.orders.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        // 經實際的開啟路徑建立選擇器，避免自行接線漏掉建構時取得的快照
        var expectedPicker = OrderCategoryPickerFeatureTestSupport.makeState(
            for: initial.orders.list
        )
        expectedPicker.pendingCategories = []
        expectedPicker.groupExpansion = OrderCategoryGroups.Expansion(expandedKinds: [.ongoing])
        await store.send(.orders(.list(.view(.categoryPickerTapped)))) {
            $0.orders.list.destination = .categoryPicker(expectedPicker)
        }
        let pickerCampaigns = try #require(
            store.state.orders.list.destination?.categoryPicker?.$campaigns
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
        #expect(pickerCampaigns.wrappedValue == [updated])
        #expect(store.state.orders.list.destination?.categoryPicker?.campaigns == [updated])
        let groups = store.state.orders.list.destination?.categoryPicker?.categoryGroups
        #expect(groups?.map(\.kind) == [.closed])
        #expect(groups?.first?.displayedCount == 1)
        #expect(groups?.flatMap(\.visibleCategories) == [])
        #expect(
            store.state.orders.list.destination?.categoryPicker?.groupExpansion.expandedKinds
                == [.ongoing]
        )
    }
}
