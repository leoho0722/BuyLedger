//
//  CampaignListFeatureTests+DateContext.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignListFeatureTests {

    /// 已載入時再次執行外觀任務仍記錄新的日期與行事曆，且不重複載入
    @Test
    func task_已載入時再次執行外觀任務_更新日期脈絡而不重複載入() async {
        // Given
        var initial = Self.makeState()
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

    /// 列表停留期間跨午夜，標題仍依外觀任務記錄的日期，直到下一次任務才更新
    ///
    /// - Throws: 日期脈絡不存在時由 `try #require` 丟出
    @Test
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
        var initial = Self.makeState(campaigns: [today, yesterday, older])
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

    /// 下次執行外觀任務才把原本今天的區段改成昨天
    ///
    /// - Throws: 日期脈絡不存在時由 `try #require` 丟出
    @Test
    func task_跨午夜後重新執行外觀任務_今天區段改為昨天() async throws {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "五月團",
            openDate: Date(timeIntervalSince1970: 1_778_544_000),
            status: .ongoing,
            notes: ""
        )
        var initial = Self.makeState(campaigns: [campaign])
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

    /// 日期脈絡尚未建立時不產生日期區段與列彙總
    @Test
    func dateSections_日期脈絡尚未建立_回傳空區段與彙總() {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "團",
            closeDate: nil,
            status: .ongoing
        )
        let state = Self.makeState(campaigns: [campaign])

        // When
        let sections = state.dateSections
        let summaries = state.rowSummaries

        // Then
        #expect(sections == [])
        #expect(summaries.byName == [:])
    }

    /// 列彙總只包含篩選後可見的開團名稱，並採用唯讀訂單的金額
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
        var state = Self.makeState(campaigns: [ongoing, closed], orders: [orderA, orderB])
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
