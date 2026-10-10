//
//  SnapshotTests+Campaigns.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import BuyLedger

extension SnapshotTests {

    /// 按日分組時依序顯示今天、昨天與同年較早一天的區段，各列帶訂單筆數、應收金額與進度
    @Test
    func campaignListView_依日分組含今天與昨天_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            var state = Self.makeRecentDaysListState()
            state.grouping = .day

            // When
            let view = Self.makeListView(state: state, language: .traditionalChinese)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 按月分組時同一個月的區段下，子標題依序顯示今天、昨天與較早一天的日期
    @Test
    func campaignListView_依月分組_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            var state = Self.makeRecentDaysListState()
            state.grouping = .month

            // When
            let view = Self.makeListView(state: state, language: .traditionalChinese)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 按年分組時同一年的區段下，子標題依序顯示四月、三月與一月，每列上方帶開團日期
    @Test
    func campaignListView_依年分組_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            var state = Self.makeAcrossMonthsListState()
            state.grouping = .year

            // When
            let view = Self.makeListView(state: state, language: .traditionalChinese)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 英文月分組的子標題依序顯示 Today 與 Yesterday，保留其餘日期與列表版面
    @Test
    func campaignListView_英文月分組_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            var state = Self.makeRecentDaysListState()
            state.grouping = .month

            // When
            let view = Self.makeListView(state: state, language: .english)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 尚未載入完成且有失敗訊息時，列表顯示載入失敗畫面與重試鍵
    @Test
    func campaignListView_載入失敗_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            let state = CampaignListFeature.State(
                campaigns: SharedReader(value: []),
                orders: SharedReader(value: []),
                errorMessage: SharedReader(value: "開團載入失敗，請稍後再試。")
            )

            // When
            let view = Self.makeListView(state: state, language: .traditionalChinese)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }
}

// MARK: - Private Method

private extension SnapshotTests {

    /// 建立今天、昨天與同月較早一天各有一個開團的已載入列表狀態
    ///
    /// - Returns: 附訂單的列表狀態，分組方式維持預設
    static func makeRecentDaysListState() -> CampaignListFeature.State {
        let today = Campaign.fixture(
            id: "campaign-today",
            name: "今日現貨團",
            openDate: campaignDate(daysAgo: 0)
        )
        let yesterday = Campaign.fixture(
            id: "campaign-yesterday",
            name: "昨日預購團",
            openDate: campaignDate(daysAgo: 1),
            status: .closed
        )
        let earlier = Campaign.fixture(
            id: "campaign-april-10",
            name: "四月韓國團",
            openDate: campaignDate(daysAgo: 20),
            status: .closed,
            settledDate: campaignDate(daysAgo: 15)
        )
        let todayOrders = makeOrders(
            for: today,
            rows: [
                CampaignOrderRow(
                    customer: "小美",
                    amount: 1_200,
                    status: .arrived,
                    isReceived: true
                ),
                CampaignOrderRow(
                    customer: "阿凱",
                    amount: 800,
                    status: .purchased,
                    isReceived: false
                ),
            ]
        )
        let yesterdayOrders = makeOrders(
            for: yesterday,
            rows: [
                CampaignOrderRow(
                    customer: "阿凱",
                    amount: 2_400,
                    status: .delivered,
                    isReceived: true
                ),
                CampaignOrderRow(
                    customer: "小安",
                    amount: 1_500,
                    status: .arrived,
                    isReceived: false
                ),
                CampaignOrderRow(
                    customer: "小美",
                    amount: 900,
                    status: .shipping,
                    isReceived: false
                ),
            ]
        )
        let earlierOrders = makeOrders(
            for: earlier,
            rows: [
                CampaignOrderRow(
                    customer: "小美",
                    amount: 3_600,
                    status: .delivered,
                    isReceived: true
                ),
                CampaignOrderRow(
                    customer: "小安",
                    amount: 2_800,
                    status: .pickedUp,
                    isReceived: true
                ),
            ]
        )

        var state = CampaignListFeature.State(
            campaigns: SharedReader(value: [today, yesterday, earlier]),
            orders: SharedReader(value: todayOrders + yesterdayOrders + earlierOrders),
            hasLoaded: SharedReader(value: true)
        )
        state.dateContext = CampaignDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        return state
    }

    /// 建立列表的固定尺寸宿主，讓各案例只指定狀態與語系
    ///
    /// - Parameters:
    ///   - state: 待渲染的列表狀態
    ///   - language: 根標題與環境使用的語系
    /// - Returns: 393 × 852 的列表導覽宿主
    static func makeListView(state: CampaignListFeature.State, language: AppLanguage) -> some View {
        NavigationStack {
            CampaignListView(
                store: Store(initialState: state) {
                    EmptyReducer()
                },
                language: language
            )
        }
        .environment(\.locale, language.locale)
        .frame(width: 393, height: 852)
    }

    /// 建立同一年四月、三月與一月各有一個開團的已載入列表狀態
    ///
    /// - Returns: 附訂單的列表狀態，分組方式維持預設
    static func makeAcrossMonthsListState() -> CampaignListFeature.State {
        let april = Campaign.fixture(
            id: "campaign-april-29",
            name: "四月預購團",
            openDate: campaignDate(daysAgo: 1)
        )
        let march = Campaign.fixture(
            id: "campaign-march-12",
            name: "三月日本團",
            openDate: campaignDate(daysAgo: 49),
            status: .closed,
            settledDate: campaignDate(daysAgo: 44)
        )
        let january = Campaign.fixture(
            id: "campaign-january-20",
            name: "一月年貨團",
            openDate: campaignDate(daysAgo: 100),
            status: .closed,
            settledDate: campaignDate(daysAgo: 95)
        )
        let aprilOrders = makeOrders(
            for: april,
            rows: [
                CampaignOrderRow(
                    customer: "小美",
                    amount: 2_400,
                    status: .arrived,
                    isReceived: true
                ),
                CampaignOrderRow(
                    customer: "阿凱",
                    amount: 1_200,
                    status: .shipping,
                    isReceived: false
                ),
            ]
        )
        let marchOrders = makeOrders(
            for: march,
            rows: [
                CampaignOrderRow(
                    customer: "小安",
                    amount: 4_200,
                    status: .delivered,
                    isReceived: true
                ),
            ]
        )
        let januaryOrders = makeOrders(
            for: january,
            rows: [
                CampaignOrderRow(
                    customer: "阿凱",
                    amount: 1_800,
                    status: .pickedUp,
                    isReceived: true
                ),
                CampaignOrderRow(
                    customer: "小美",
                    amount: 2_200,
                    status: .delivered,
                    isReceived: true
                ),
            ]
        )

        var state = CampaignListFeature.State(
            campaigns: SharedReader(value: [april, march, january]),
            orders: SharedReader(value: aprilOrders + marchOrders + januaryOrders),
            hasLoaded: SharedReader(value: true)
        )
        state.dateContext = CampaignDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        return state
    }
}
