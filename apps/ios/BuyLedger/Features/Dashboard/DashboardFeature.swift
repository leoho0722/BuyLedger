//
//  DashboardFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/2.
//

import ComposableArchitecture
import Foundation

/// 總覽分頁功能，提供訂單、開團與月獲利目標的唯讀投影
@Reducer
struct DashboardFeature {

    // MARK: - State

    /// 總覽功能狀態
    @ObservableState
    struct State: Equatable {

        /// 訂單投影；由 ``RootFeature`` 與 ``OrdersFeature/State/orders`` 保持同步
        var orders: [LedgerOrder] = []

        /// 開團投影；由 ``RootFeature`` 與 ``CampaignFeature/State/campaigns`` 保持同步
        var campaigns: [Campaign] = []

        /// 每月獲利目標，單位為新台幣
        var monthlyProfitGoalTWD: Decimal = 80_000

        /// 訂單載入狀態
        var loadState: OrdersLoadState = .loading

        /// 最近一次出現、重試或 Root 刷新時記錄的時間與行事曆，尚未記錄時為 `nil`
        var dateContext: DashboardDateContext?

        /// 進行中的開團與各自的訂單彙總，依開團清單的順序排列
        var ongoingCampaignRows: [OngoingCampaignRow] {
            // 單次掃描訂單，批次建立各團的彙總
            let ongoingCampaigns = campaigns.filter { $0.status == .ongoing }
            let summaries = CampaignSummary.batch(
                campaignNames: ongoingCampaigns.map(\.name),
                orders: orders
            )

            return ongoingCampaigns.map {
                OngoingCampaignRow(
                    campaign: $0,
                    summary: summaries[$0.name]
                        ?? CampaignSummary(campaignName: $0.name, orders: [])
                )
            }
        }

        /// 依記錄的日期與訂單推導的總覽統計，尚未記錄日期時為 `nil`
        var stats: DashboardStats? {
            guard let dateContext else {
                return nil
            }
            return DashboardStats(
                orders: orders,
                monthlyGoal: monthlyProfitGoalTWD,
                referenceDate: dateContext.now,
                calendar: dateContext.calendar
            )
        }

        /// 畫面狀態，判斷順序為失敗優先，其次是載入中或尚未記錄日期的骨架，再來是首次使用與總覽
        var screenState: ScreenState {
            if case .failed(let message) = loadState {
                return .failed(message)
            }
            guard loadState == .loaded, let stats else {
                return .loading
            }
            if orders.isEmpty {
                return .onboarding
            }
            return .overview(stats)
        }

        /// 總覽「進行中的開團」區段的一列：開團與它的訂單彙總
        struct OngoingCampaignRow {

            /// 進行中的開團
            let campaign: Campaign

            /// 該團的訂單彙總
            let summary: CampaignSummary
        }

        /// 總覽畫面應呈現的狀態
        enum ScreenState: Equatable {

            /// 載入失敗，附帶失敗原因
            ///
            /// - Parameter message: 畫面持續顯示的失敗訊息
            case failed(String)

            /// 尚未載入完成或尚未記錄日期，顯示載入骨架
            case loading

            /// 已載入但沒有任何訂單，顯示首次使用畫面
            case onboarding

            /// 已載入且有訂單，顯示總覽數字
            ///
            /// - Parameter stats: 依記錄的日期計算的統計
            case overview(DashboardStats)
        }

        /// 以 Root 注入的現在時間與行事曆覆寫總覽的日期脈絡，不論原本是否已記錄
        ///
        /// - Parameters:
        ///   - now: 注入的現在時間
        ///   - calendar: 注入的行事曆
        mutating func refreshDateContext(now: Date, calendar: Calendar) {
            dateContext = DashboardDateContext(now: now, calendar: calendar)
        }
    }

    // MARK: - Action

    /// 總覽功能可處理的事件，依來源分為畫面操作與交給根功能的意圖
    @CasePathable
    enum Action: Equatable {

        /// 畫面送出的使用者操作
        ///
        /// - Parameter action: 實際的操作
        case view(View)

        /// 交給根功能處理的跨功能意圖
        ///
        /// - Parameter delegate: 要交給根功能的意圖
        case delegate(Delegate)

        /// 總覽畫面送出的使用者操作
        @CasePathable
        enum View: Equatable {

            /// 畫面出現時觸發載入
            case task

            /// 使用者點擊載入失敗畫面的重試鈕
            case retryTapped

            /// 使用者點擊進行中開團卡，帶開團名稱
            ///
            /// - Parameter name: 開團名稱
            case campaignTapped(String)

            /// 使用者點擊「建立第一筆訂單」
            case newOrderTapped

            /// 使用者點擊「查看全部」訂單
            case viewAllOrdersTapped
        }

        /// 總覽可能發出的跨 feature 意圖
        @CasePathable
        enum Delegate: Equatable {

            /// 重新載入訂單與設定
            case refresh

            /// 使用者點擊進行中開團卡，帶開團名稱
            ///
            /// - Parameter name: 開團名稱
            case campaignTapped(String)

            /// 使用者點擊「建立第一筆訂單」
            case newOrderTapped

            /// 使用者點擊「查看全部」訂單
            case viewAllOrdersTapped
        }
    }

    // MARK: - Dependencies

    /// 總覽出現與重試時記錄的現在時間
    @Dependency(\.date) private var date

    /// 記錄日期脈絡所用的行事曆
    @Dependency(\.calendar) private var calendar

    // MARK: - Body

    /// 只負責組合 reducer，本畫面自己的邏輯在 `core(state:action:)`
    var body: some ReducerOf<Self> {
        Reduce(core)
    }
}

// MARK: - Private Method

private extension DashboardFeature {

    /// 依收到的 Action 更新 State，畫面操作轉成交給根功能的意圖
    ///
    /// - Parameters:
    ///   - state: 目前的總覽狀態，直接就地修改
    ///   - action: 這次收到的事件
    /// - Returns: 接下來要執行的 Effect，沒有就回 `.none`
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .view(.task), .view(.retryTapped):
            state.refreshDateContext(now: date.now, calendar: calendar)
            return .send(.delegate(.refresh))

        case .view(.campaignTapped(let name)):
            return .send(.delegate(.campaignTapped(name)))

        case .view(.newOrderTapped):
            return .send(.delegate(.newOrderTapped))

        case .view(.viewAllOrdersTapped):
            return .send(.delegate(.viewAllOrdersTapped))

        case .delegate:
            return .none
        }
    }
}
