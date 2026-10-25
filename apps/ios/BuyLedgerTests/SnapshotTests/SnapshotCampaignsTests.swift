//
//  SnapshotCampaignsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import BuyLedger

/// `CampaignListView` 的快照測試，涵蓋各語系與分組方式
@MainActor
struct SnapshotCampaignsTests {

    /// 驗證按日分組時依序顯示今天、昨天與同年較早一天的區段，各列帶訂單筆數、應收金額與進度，畫面符合基準圖
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

    /// 驗證按月分組時，同一個月的區段下，子標題依序顯示今天、昨天與較早一天的日期，畫面符合基準圖
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

    /// 驗證按年分組時，同一年的區段下，子標題依序顯示四月、三月與一月，每列上方帶開團日期，畫面符合基準圖
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

    /// 驗證英文語系按月分組時，子標題顯示 Today 與 Yesterday，畫面符合基準圖
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

    /// 驗證尚未載入完成且有失敗訊息時，列表顯示載入失敗畫面與重試鍵，畫面符合基準圖
    @Test
    func campaignListView_載入失敗_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            let state = CampaignListFeature.State(
                campaigns: SharedReader(value: []),
                orders: SharedReader(value: []),
                errorMessage: SharedReader(value: "campaigns.list.message.campaignsLoadedTry")
            )

            // When
            let view = Self.makeListView(state: state, language: .traditionalChinese)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }
}

// MARK: - Private Method

private extension SnapshotCampaignsTests {

    /// 建立今天、昨天與同月較早一天各有一個開團的已載入列表狀態
    ///
    /// - Returns: 附訂單的列表狀態，分組方式維持預設
    static func makeRecentDaysListState() -> CampaignListFeature.State {
        let today = Campaign.fixture(
            id: "campaign-today",
            name: "今日現貨團",
            openDate: SnapshotTestSupport.campaignDate(daysAgo: 0)
        )
        let yesterday = Campaign.fixture(
            id: "campaign-yesterday",
            name: "昨日預購團",
            openDate: SnapshotTestSupport.campaignDate(daysAgo: 1),
            status: .closed
        )
        let earlier = Campaign.fixture(
            id: "campaign-april-10",
            name: "四月韓國團",
            openDate: SnapshotTestSupport.campaignDate(daysAgo: 20),
            status: .closed,
            settledDate: SnapshotTestSupport.campaignDate(daysAgo: 15)
        )
        let todayOrders = SnapshotTestSupport.makeOrders(
            for: today,
            rows: [
                SnapshotTestSupport.CampaignOrderRow(
                    customer: "小美",
                    amount: 1_200,
                    status: .arrived,
                    isReceived: true
                ),
                SnapshotTestSupport.CampaignOrderRow(
                    customer: "阿凱",
                    amount: 800,
                    status: .purchased,
                    isReceived: false
                ),
            ]
        )
        let yesterdayOrders = SnapshotTestSupport.makeOrders(
            for: yesterday,
            rows: [
                SnapshotTestSupport.CampaignOrderRow(
                    customer: "阿凱",
                    amount: 2_400,
                    status: .delivered,
                    isReceived: true
                ),
                SnapshotTestSupport.CampaignOrderRow(
                    customer: "小安",
                    amount: 1_500,
                    status: .arrived,
                    isReceived: false
                ),
                SnapshotTestSupport.CampaignOrderRow(
                    customer: "小美",
                    amount: 900,
                    status: .shipping,
                    isReceived: false
                ),
            ]
        )
        let earlierOrders = SnapshotTestSupport.makeOrders(
            for: earlier,
            rows: [
                SnapshotTestSupport.CampaignOrderRow(
                    customer: "小美",
                    amount: 3_600,
                    status: .delivered,
                    isReceived: true
                ),
                SnapshotTestSupport.CampaignOrderRow(
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
            openDate: SnapshotTestSupport.campaignDate(daysAgo: 1)
        )
        let march = Campaign.fixture(
            id: "campaign-march-12",
            name: "三月日本團",
            openDate: SnapshotTestSupport.campaignDate(daysAgo: 49),
            status: .closed,
            settledDate: SnapshotTestSupport.campaignDate(daysAgo: 44)
        )
        let january = Campaign.fixture(
            id: "campaign-january-20",
            name: "一月年貨團",
            openDate: SnapshotTestSupport.campaignDate(daysAgo: 100),
            status: .closed,
            settledDate: SnapshotTestSupport.campaignDate(daysAgo: 95)
        )
        let aprilOrders = SnapshotTestSupport.makeOrders(
            for: april,
            rows: [
                SnapshotTestSupport.CampaignOrderRow(
                    customer: "小美",
                    amount: 2_400,
                    status: .arrived,
                    isReceived: true
                ),
                SnapshotTestSupport.CampaignOrderRow(
                    customer: "阿凱",
                    amount: 1_200,
                    status: .shipping,
                    isReceived: false
                ),
            ]
        )
        let marchOrders = SnapshotTestSupport.makeOrders(
            for: march,
            rows: [
                SnapshotTestSupport.CampaignOrderRow(
                    customer: "小安",
                    amount: 4_200,
                    status: .delivered,
                    isReceived: true
                ),
            ]
        )
        let januaryOrders = SnapshotTestSupport.makeOrders(
            for: january,
            rows: [
                SnapshotTestSupport.CampaignOrderRow(
                    customer: "阿凱",
                    amount: 1_800,
                    status: .pickedUp,
                    isReceived: true
                ),
                SnapshotTestSupport.CampaignOrderRow(
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
