//
//  InsightsFeatureScreenStateTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation
import Testing

@testable import BuyLedger

/// `InsightsFeature.State` 的單元測試，直接以 State 計算 `screenState` 與統計，不經 TestStore
struct InsightsFeatureScreenStateTests {

    /// 驗證載入失敗且尚未記錄日期時，`screenState` 為失敗畫面，並帶著失敗訊息
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

    /// 驗證訂單仍在載入中時，即使已記錄日期，`screenState` 仍為載入骨架
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

    /// 驗證已載入訂單但尚未記錄日期時，`screenState` 為載入骨架，不顯示任何統計
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

    /// 驗證已載入且沒有訂單、尚未記錄日期脈絡時，`screenState` 為 `.loading`，不顯示空狀態
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

    /// 驗證已載入且日期脈絡記錄為 2026/05/12 時，沒有訂單的分析畫面回傳 `.empty`
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

    /// 驗證已載入、有訂單且已記錄日期時，`screenState` 為分析內容，統計依記錄的日期與期間計算
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
        let content = try #require(Self.analyticsContent(of: screenState))
        #expect(content.stats.totalProfit == 2_300)
        #expect(content.stats.trendBuckets.count == 12)
        #expect(content.heatmap.maxCount == 1)
    }

    /// 驗證跨過午夜的重大時間變更後，`refreshDateContext` 把三十天走勢的最後一段標籤由 05/12 改為 05/13
    ///
    /// - Throws: 測試用日期無法組成時丟出
    @Test
    func refreshDateContext_跨過午夜_三十天走勢最後一段改為隔日() throws {
        // Given
        var state = InsightsFeature.State()
        state.loadState = .loaded
        state.insightsDateRange = .thirtyDays
        state.dateContext = InsightsDateContext(
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

    /// 驗證切換為三十天期間後，走勢區間改為三十段，總獲利由 1,300 重算為 1,000
    ///
    /// - Throws: 測試用日期無法組成時丟出
    @Test
    func stats_切換分析期間_走勢與期間總獲利依新期間重算() throws {
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
            InsightsStatsTestSupport.makeOrder(
                id: "today",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 1_000
            ),
            InsightsStatsTestSupport.makeOrder(
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
    }

    /// 驗證追加訂單後，`stats` 立即把新增的獲利計入總獲利
    @Test
    func stats_訂單改變_總獲利立即重算() {
        // Given
        let recordedContext = InsightsDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        var state = InsightsFeature.State()
        state.loadState = .loaded
        state.dateContext = recordedContext
        state.orders = [
            InsightsStatsTestSupport.makeOrder(
                id: "A",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 1_000
            ),
        ]
        let totalBeforeChange = state.stats?.totalProfit

        // When
        state.orders.append(
            InsightsStatsTestSupport.makeOrder(
                id: "B",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 500
            )
        )

        // Then
        #expect(totalBeforeChange == 1_000)
        #expect(state.stats?.totalProfit == 1_500)
    }

    /// 驗證新增開團後，`campaignRanks` 依最新開團重算，毛利較高的新開團排第一
    @Test
    func campaignRanks_開團改變_每團毛利排行依最新開團重算() {
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
            InsightsStatsTestSupport.makeOrder(
                id: "O1",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 500,
                campaignNames: ["A團"]
            ),
            InsightsStatsTestSupport.makeOrder(
                id: "O2",
                status: .delivered,
                date: TestDependencies.fixedNow,
                charged: 2_000,
                campaignNames: ["B團"]
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

        // Then
        #expect(namesBeforeChange == ["A團"])
        #expect(state.campaignRanks.map(\.campaignName) == ["B團", "A團"])
        #expect(state.campaignRanks.map(\.rank) == [1, 2])
    }
}

// MARK: - Private Method

private extension InsightsFeatureScreenStateTests {

    /// 解析 UTC 時區的日期時間字串，對應規格範例中的記錄日期
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

    /// 建立三筆已實現訂單：2026/05/03 為 1000 元、2026/05/10 為 500 元、2026/04/20 為 800 元，合計 2300 元
    ///
    /// - Returns: 三筆測試訂單
    /// - Throws: 日期無法解析時丟出
    static func sampleOrders() throws -> [LedgerOrder] {
        [
            InsightsStatsTestSupport.makeOrder(
                id: "may03",
                status: .delivered,
                date: try utcDate("2026-05-03 10:00"),
                charged: 1_000
            ),
            InsightsStatsTestSupport.makeOrder(
                id: "may10",
                status: .delivered,
                date: try utcDate("2026-05-10 10:00"),
                charged: 500
            ),
            InsightsStatsTestSupport.makeOrder(
                id: "apr20",
                status: .delivered,
                date: try utcDate("2026-04-20 10:00"),
                charged: 800
            ),
        ]
    }

    /// 取出分析畫面的統計與熱度圖，其他畫面狀態回傳 `nil`
    ///
    /// - Parameter screenState: 分析頁目前的畫面狀態
    /// - Returns: 分析內容的統計與熱度圖，不是分析內容時為 `nil`
    static func analyticsContent(
        of screenState: InsightsFeature.State.ScreenState
    ) -> (stats: InsightsStats, heatmap: InsightsHeatmap)? {
        guard case .analytics(let stats, let heatmap) = screenState else {
            return nil
        }
        return (stats, heatmap)
    }
}
