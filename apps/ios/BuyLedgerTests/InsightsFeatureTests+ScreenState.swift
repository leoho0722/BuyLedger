//
//  InsightsFeatureTests+ScreenState.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

extension InsightsFeatureTests {

    /// 載入失敗且尚未記錄日期時顯示失敗畫面，附帶失敗訊息
    @Test
    func screenState_載入失敗且未記錄日期_顯示失敗畫面() {
        // Given
        var state = InsightsFeature.State()
        state.loadState = .failed("網路連線失敗")

        // When
        let screenState = state.screenState

        // Then
        #expect(screenState == .failed("網路連線失敗"))
    }

    /// 訂單仍在載入中時顯示載入骨架，即使已記錄日期
    ///
    /// - Throws: 測試用日期無法組成時丟出
    @Test
    func screenState_載入中且已記錄日期_顯示骨架() throws {
        // Given
        var state = InsightsFeature.State()
        state.loadState = .loading
        state.dateContext = InsightsDateContext(
            now: try Self.utcDate("2026-05-12 10:00"),
            calendar: TestDependencies.fixedCalendar
        )

        // When
        let screenState = state.screenState

        // Then
        #expect(screenState == .loading)
    }

    /// 已載入但尚未記錄日期時顯示載入骨架，不顯示任何統計
    ///
    /// - Throws: 測試用日期無法組成時丟出
    @Test
    func screenState_已載入有訂單但未記錄日期_顯示骨架() throws {
        // Given
        var state = InsightsFeature.State()
        state.loadState = .loaded
        state.orders = try Self.sampleOrders()

        // When
        let screenState = state.screenState

        // Then
        #expect(screenState == .loading)
    }

    /// 已載入且沒有訂單、尚未記錄日期時仍顯示載入骨架，不顯示空狀態
    @Test
    func screenState_已載入無訂單且未記錄日期_顯示骨架() {
        // Given
        var state = InsightsFeature.State()
        state.loadState = .loaded

        // When
        let screenState = state.screenState

        // Then
        #expect(screenState == .loading)
    }

    /// 已載入且沒有訂單、已記錄日期時顯示空狀態
    ///
    /// - Throws: 測試用日期無法組成時丟出
    @Test
    func screenState_已載入無訂單且已記錄日期_顯示空狀態() throws {
        // Given
        var state = InsightsFeature.State()
        state.loadState = .loaded
        state.dateContext = InsightsDateContext(
            now: try Self.utcDate("2026-05-12 10:00"),
            calendar: TestDependencies.fixedCalendar
        )

        // When
        let screenState = state.screenState

        // Then
        #expect(screenState == .empty)
    }

    /// 已載入、有訂單且已記錄日期時顯示分析內容，統計依記錄的日期與期間計算
    ///
    /// - Throws: 測試用日期無法組成時丟出
    @Test
    func screenState_已載入有訂單且已記錄日期_顯示分析內容() throws {
        // Given
        var state = InsightsFeature.State()
        state.loadState = .loaded
        state.orders = try Self.sampleOrders()
        state.dateContext = InsightsDateContext(
            now: try Self.utcDate("2026-05-12 10:00"),
            calendar: TestDependencies.fixedCalendar
        )

        // When
        let screenState = state.screenState

        // Then
        if case .analytics(let insightsStats, let insightsHeatmap) = screenState {
            #expect(insightsStats.totalProfit == 2_300)
            #expect(insightsStats.trendBuckets.count == 12)
            #expect(insightsHeatmap.maxCount == 1)
        } else {
            Issue.record("已載入有訂單且已記錄日期時應顯示分析內容")
        }
    }

    /// 系統回報跨過午夜的重大時間變更後，三十天走勢的最後一段由前一日改為隔日標籤
    ///
    /// - Throws: 測試用日期無法組成時丟出
    @Test
    func refreshDateContext_跨過午夜_三十天走勢最後一段改為隔日() throws {
        // Given
        var state = InsightsFeature.State()
        state.loadState = .loaded
        state.insightsDateRange = .thirtyDays
        state.refreshDateContext(
            now: try Self.utcDate("2026-05-12 23:50"),
            calendar: TestDependencies.fixedCalendar
        )
        let labelBeforeMidnight = state.stats?.trendBuckets.last?.label

        // When
        state.refreshDateContext(
            now: try Self.utcDate("2026-05-13 00:00"),
            calendar: TestDependencies.fixedCalendar
        )

        // Then
        #expect(labelBeforeMidnight == "05/12")
        #expect(state.stats?.trendBuckets.last?.label == "05/13")
    }

    /// 切換分析期間後，走勢區間與期間總獲利依新期間重算，記錄的日期不變
    ///
    /// - Throws: 測試用日期無法組成時丟出
    @Test
    func stats_切換分析期間_走勢與期間總獲利依新期間重算且記錄日期不變() throws {
        // Given
        let recordedContext = InsightsDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let fortyDaysAgo = try #require(
            TestDependencies.fixedCalendar.date(
                byAdding: .day,
                value: -40,
                to: TestDependencies.fixedNow
            )
        )
        var state = InsightsFeature.State()
        state.loadState = .loaded
        state.dateContext = recordedContext
        state.orders = [
            InsightsStatsTests.makeOrder(
                id: "today",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 1_000
            ),
            InsightsStatsTests.makeOrder(
                id: "fortyDaysAgo",
                status: .delivered,
                date: fortyDaysAgo,
                charged: 300
            ),
        ]
        let totalInTwelveMonths = state.stats?.totalProfit

        // When
        state.insightsDateRange = .thirtyDays

        // Then
        #expect(totalInTwelveMonths == 1_300)
        #expect(state.stats?.trendBuckets.count == 30)
        #expect(state.stats?.totalProfit == 1_000)
        #expect(state.dateContext == recordedContext)
    }

    /// 訂單改變後，統計依既有的記錄日期立即重算，記錄的日期不變
    @Test
    func stats_訂單改變_依既有記錄日期立即重算() {
        // Given
        let recordedContext = InsightsDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        var state = InsightsFeature.State()
        state.loadState = .loaded
        state.dateContext = recordedContext
        state.orders = [
            InsightsStatsTests.makeOrder(
                id: "A",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 1_000
            ),
        ]
        let totalBeforeChange = state.stats?.totalProfit

        // When
        state.orders.append(
            InsightsStatsTests.makeOrder(
                id: "B",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 500
            )
        )

        // Then
        #expect(totalBeforeChange == 1_000)
        #expect(state.stats?.totalProfit == 1_500)
        #expect(state.dateContext == recordedContext)
    }

    /// 開團改變後，每團毛利排行依新的開團與訂單重算，記錄的日期不變
    @Test
    func campaignRanks_開團改變_每團毛利排行依最新開團重算且記錄日期不變() {
        // Given
        let recordedContext = InsightsDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        var state = InsightsFeature.State()
        state.loadState = .loaded
        state.dateContext = recordedContext
        state.campaigns = [
            Campaign(
                id: "1",
                name: "A團",
                openDate: Date(timeIntervalSince1970: 0),
                status: .ongoing,
                notes: ""
            ),
        ]
        state.orders = [
            InsightsStatsTests.makeOrder(
                id: "O1",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 500,
                campaignNames: ["A團"]
            ),
        ]
        let namesBeforeChange = state.campaignRanks.map(\.campaignName)

        // When
        state.campaigns.append(
            Campaign(
                id: "2",
                name: "B團",
                openDate: Date(timeIntervalSince1970: 0),
                status: .ongoing,
                notes: ""
            )
        )
        state.orders.append(
            InsightsStatsTests.makeOrder(
                id: "O2",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 2_000,
                campaignNames: ["B團"]
            )
        )

        // Then
        #expect(namesBeforeChange == ["A團"])
        #expect(state.campaignRanks.map(\.campaignName) == ["B團", "A團"])
        #expect(state.campaignRanks.map(\.rank) == [1, 2])
        #expect(state.dateContext == recordedContext)
    }
}

// MARK: - Private Method

private extension InsightsFeatureTests {

    /// 把 UTC 時區的「年-月-日 時:分」字串解析為日期，對應 spec 範例中的記錄日期
    ///
    /// - Parameter text: 格式為 `yyyy-MM-dd HH:mm` 的字串
    /// - Returns: UTC 時區的日期時間
    /// - Throws: 字串無法解析時丟出
    static func utcDate(_ text: String) throws -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return try #require(formatter.date(from: text))
    }

    /// 三筆已實現訂單：2026/05/03 為 1000 元、2026/05/10 為 500 元、2026/04/20 為 800 元，合計 2300 元
    ///
    /// - Returns: 三筆測試訂單
    /// - Throws: 日期無法解析時丟出
    static func sampleOrders() throws -> [LedgerOrder] {
        [
            InsightsStatsTests.makeOrder(
                id: "may03",
                status: .delivered,
                date: try utcDate("2026-05-03 10:00"),
                charged: 1_000
            ),
            InsightsStatsTests.makeOrder(
                id: "may10",
                status: .delivered,
                date: try utcDate("2026-05-10 10:00"),
                charged: 500
            ),
            InsightsStatsTests.makeOrder(
                id: "apr20",
                status: .delivered,
                date: try utcDate("2026-04-20 10:00"),
                charged: 800
            ),
        ]
    }
}
