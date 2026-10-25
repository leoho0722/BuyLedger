//
//  CampaignListFeatureDateContextTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `CampaignListFeature` 的單元測試，涵蓋日期脈絡的建立、跨日更新與區段投影
struct CampaignListFeatureDateContextTests {

    /// 驗證列表已載入時再次執行 `task`，日期脈絡更新為注入的現在與行事曆，載入請求仍照常送出
    @Test
    @MainActor
    func task_已載入時再次執行外觀任務_更新日期脈絡並送出載入請求() async {
        // Given
        var initial = CampaignListFeatureTestSupport.makeState()
        initial.$hasLoaded = SharedReader(value: true)
        initial.dateContext = CampaignDateContext(
            now: .distantPast,
            calendar: TestDependencies.fixedCalendar
        )
        var calendar = TestDependencies.fixedCalendar
        calendar.firstWeekday = 2
        let store = TestStore(initialState: initial) {
            CampaignListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = calendar
        }

        // When
        await store.send(.view(.task)) {
            $0.dateContext = CampaignDateContext(
                now: Date(timeIntervalSince1970: 1_777_507_200),
                calendar: calendar
            )
        }

        // Then
        await store.receive(\.delegate.loadRequested)
        await store.finish()
        #expect(store.state.dateContext?.now == Date(timeIntervalSince1970: 1_777_507_200))
        #expect(store.state.dateContext?.calendar.firstWeekday == 2)
    }

    /// 驗證注入的時間已跨午夜但列表未重新執行 `task` 時，切換分組後的區段標題仍依上次記錄的日期計算，日期脈絡不變
    ///
    /// - Throws: 日期脈絡不存在時由 `try #require` 丟出
    @Test
    @MainActor
    func groupingSelected_列表停留期間注入時間跨午夜_標題維持原日期() async throws {
        // Given
        let today = Campaign.fixture(
            id: "T",
            name: "今日團",
            openDate: Date(timeIntervalSince1970: 1_778_544_000),
            status: .ongoing,
            notes: ""
        )
        let yesterday = Campaign.fixture(
            id: "Y",
            name: "昨日團",
            openDate: Date(timeIntervalSince1970: 1_778_457_600),
            status: .ongoing,
            notes: ""
        )
        let older = Campaign.fixture(
            id: "O",
            name: "早期團",
            openDate: Date(timeIntervalSince1970: 1_778_198_400),
            status: .ongoing,
            notes: ""
        )
        var initial = CampaignListFeatureTestSupport.makeState(campaigns: [today, yesterday, older])
        initial.$hasLoaded = SharedReader(value: true)
        initial.dateContext = CampaignDateContext(
            now: Date(timeIntervalSince1970: 1_778_580_000),
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: initial) {
            CampaignListFeature()
        } withDependencies: {
            $0.date = .constant(Date(timeIntervalSince1970: 1_778_666_400))
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.groupingSelected(.day)))

        // Then
        let context = try #require(store.state.dateContext)
        let titles = store.state.dateSections.map {
            CampaignFormatters.sectionTitle(
                $0.title,
                context: context,
                locale: Locale(identifier: "zh-Hant_TW")
            )
        }
        #expect(titles == ["今天", "昨天", "5月8日週五"])
        #expect(store.state.dateContext?.now == Date(timeIntervalSince1970: 1_778_580_000))
    }

    /// 驗證跨午夜後再次執行 `task`，日期脈絡更新為注入的現在，原本今天的區段改顯示為昨天
    ///
    /// - Throws: 日期脈絡不存在時由 `try #require` 丟出
    @Test
    @MainActor
    func task_跨午夜後重新執行外觀任務_今天區段改為昨天() async throws {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "五月團",
            openDate: Date(timeIntervalSince1970: 1_778_544_000),
            status: .ongoing,
            notes: ""
        )
        var initial = CampaignListFeatureTestSupport.makeState(campaigns: [campaign])
        initial.$hasLoaded = SharedReader(value: true)
        initial.dateContext = CampaignDateContext(
            now: Date(timeIntervalSince1970: 1_778_580_000),
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: initial) {
            CampaignListFeature()
        } withDependencies: {
            $0.date = .constant(Date(timeIntervalSince1970: 1_778_666_400))
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.task)) {
            $0.dateContext = CampaignDateContext(
                now: Date(timeIntervalSince1970: 1_778_666_400),
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        await store.receive(\.delegate.loadRequested)
        let context = try #require(store.state.dateContext)
        let titles = store.state.dateSections.map {
            CampaignFormatters.sectionTitle(
                $0.title,
                context: context,
                locale: Locale(identifier: "zh-Hant_TW")
            )
        }
        #expect(titles == ["昨天"])
    }

    /// 驗證清單已有開團但日期脈絡尚未建立時，日期區段為空
    @Test
    func dateSections_日期脈絡尚未建立_回傳空區段() {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "團",
            closeDate: nil,
            status: .ongoing
        )
        let state = CampaignListFeatureTestSupport.makeState(campaigns: [campaign])

        // When
        let sections = state.dateSections

        // Then
        #expect(sections == [])
    }

    /// 驗證清單已有開團但日期脈絡尚未建立時，列彙總為空
    @Test
    func rowSummaries_日期脈絡尚未建立_回傳空彙總() {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "團",
            closeDate: nil,
            status: .ongoing
        )
        let state = CampaignListFeatureTestSupport.makeState(campaigns: [campaign])

        // When
        let summaries = state.rowSummaries

        // Then
        #expect(summaries.byName == [:])
    }

    /// 驗證狀態篩選為進行中時，列彙總只含進行中的開團，應收金額取自唯讀訂單投影，已結束開團的訂單不計入
    @Test
    func rowSummaries_只顯示進行中開團_只投影可見開團的訂單() {
        // Given
        let ongoing = Campaign.fixture(
            id: "A",
            name: "進行團",
            closeDate: nil,
            status: .ongoing
        )
        let closed = Campaign.fixture(
            id: "B",
            name: "結束團",
            closeDate: nil,
            status: .closed
        )
        let orderA = LedgerOrder.fixture(id: "OA", chargedAmount: 1_200, campaignNames: ["進行團"])
        let orderB = LedgerOrder.fixture(id: "OB", chargedAmount: 2_400, campaignNames: ["結束團"])
        var state = CampaignListFeatureTestSupport.makeState(
            campaigns: [ongoing, closed],
            orders: [orderA, orderB]
        )
        state.statusFilter = .ongoing
        state.dateContext = CampaignDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        // When
        let summaries = state.rowSummaries

        // Then
        #expect(Set(summaries.byName.keys) == ["進行團"])
        #expect(summaries.byName["進行團"]?.orderCount == 1)
        #expect(summaries.byName["進行團"]?.receivables == 1_200)
    }
}
