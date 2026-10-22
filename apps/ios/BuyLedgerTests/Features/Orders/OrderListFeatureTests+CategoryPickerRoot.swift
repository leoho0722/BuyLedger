//
//  OrderListFeatureTests+CategoryPickerRoot.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrderListFeatureTests {

    /// Root 刷新日期與時區時同步選擇器，保留使用者草稿、搜尋、焦點與展開
    ///
    /// - Throws: 固定時區無法建立時由驗證前置條件丟出
    @Test
    func launch_根功能刷新日期_同步類別選擇器並保留草稿() async throws {
        // Given
        var initial = RootFeatureTests.makeIsolatedRootState()
        var previousCalendar = TestDependencies.fixedCalendar
        previousCalendar.timeZone = try #require(TimeZone(secondsFromGMT: 32_400))
        initial.orders.refreshDateContext(
            now: Date(timeIntervalSince1970: 0),
            calendar: previousCalendar
        )
        var picker = OrderCategoryPickerFeatureTests.makeState(for: initial.orders.list)
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

    /// Root 更新開團後，開啟時取得的唯讀引用仍讀到最新投影
    ///
    /// - Throws: 選擇器的開團引用不存在時由驗證前置條件丟出
    @Test
    func campaigns_根功能更新開團_類別選擇器引用讀到新值() async throws {
        // Given
        let previous = Campaign.fixture(id: "C1", name: "春季團", status: .ongoing)
        let updated = Campaign.fixture(id: "C1", name: "春季團", status: .closed)
        var initial = RootFeatureTests.makeIsolatedRootState()
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
        // 經實際開啟路徑取得引用，避免測試自行接線而漏掉建構時產生快照的錯誤
        var expectedPicker = OrderCategoryPickerFeatureTests.makeState(for: initial.orders.list)
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
