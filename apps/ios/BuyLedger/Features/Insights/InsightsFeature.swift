//
//  InsightsFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/2.
//

import ComposableArchitecture
import Foundation

/// 分析分頁功能，提供唯讀資料與區間選擇
@Reducer
struct InsightsFeature {

    // MARK: - State

    /// 分析功能狀態
    @ObservableState
    struct State: Equatable {

        /// 訂單投影；由 ``RootFeature`` 與 ``OrdersFeature/State/orders`` 保持同步
        var orders: [LedgerOrder] = []

        /// 開團投影；由 ``RootFeature`` 與 ``CampaignFeature/State/campaigns`` 保持同步
        var campaigns: [Campaign] = []

        /// 訂單載入狀態
        var loadState: OrdersLoadState = .loading

        /// 目前選取的趨勢期間
        var insightsDateRange: InsightsDateRange = .twelveMonths

        /// 最近一次出現、重試或 Root 刷新時記錄的時間與行事曆，尚未記錄時為 `nil`
        var dateContext: InsightsDateContext?

        /// 依訂單、趨勢期間與記錄的日期脈絡計算的統計，尚未記錄日期時為 `nil`
        var stats: InsightsStats? {
            guard let dateContext else {
                return nil
            }
            return InsightsStats(
                orders: orders,
                range: insightsDateRange,
                referenceDate: dateContext.now,
                calendar: dateContext.calendar
            )
        }

        /// 依開團與訂單計算的每團毛利排行，與記錄的日期無關
        var campaignRanks: [CampaignProfitRank] {
            InsightsStats.campaignProfitRanking(campaigns: campaigns, orders: orders)
        }

        /// 依訂單與記錄的日期脈絡計算的下單熱力圖，尚未記錄日期時為 `nil`
        var heatmap: InsightsHeatmap? {
            guard let dateContext else {
                return nil
            }
            return InsightsHeatmap.make(
                orders: orders,
                referenceDate: dateContext.now,
                calendar: dateContext.calendar
            )
        }

        /// 分析畫面目前應顯示的內容，依載入狀態、日期脈絡與訂單決定
        var screenState: ScreenState {
            switch loadState {
            case .failed(let message):
                return .failed(message)

            case .loading:
                return .loading

            case .loaded:
                guard let stats, let heatmap else {
                    return .loading
                }
                guard !orders.isEmpty else {
                    return .empty
                }
                return .analytics(stats, heatmap)
            }
        }

        /// 分析畫面的內容狀態，`content` 只依此切換分支
        enum ScreenState: Equatable {

            /// 正在載入或尚未記錄日期，顯示載入骨架
            case loading

            /// 載入失敗，顯示失敗畫面與重試鈕
            ///
            /// - Parameter message: 失敗畫面顯示的訊息
            case failed(String)

            /// 已載入但沒有訂單，顯示空狀態
            case empty

            /// 已載入且有訂單，顯示分析內容
            ///
            /// - Parameters:
            ///   - insightsStats: 依記錄日期計算的統計
            ///   - insightsHeatmap: 依記錄日期計算的熱力圖
            case analytics(InsightsStats, InsightsHeatmap)
        }

        /// 以 Root 注入的現在時間與行事曆覆寫分析的日期脈絡，不論原本是否已記錄
        ///
        /// - Parameters:
        ///   - now: 注入的現在時間
        ///   - calendar: 注入的行事曆
        mutating func refreshDateContext(now: Date, calendar: Calendar) {
            dateContext = InsightsDateContext(now: now, calendar: calendar)
        }
    }

    // MARK: - Action

    /// 分析功能可處理的事件，依來源分為雙向繫結、畫面操作與交給根功能的意圖
    @CasePathable
    enum Action: BindableAction, Equatable {

        /// `SwiftUI` 雙向繫結事件 (分析區間 segmented picker)
        ///
        /// - Parameter action: 繫結的欄位與新值
        case binding(BindingAction<State>)

        /// 分析畫面送出的使用者操作
        ///
        /// - Parameter action: 實際的操作
        case view(View)

        /// 交給根功能處理的跨功能意圖
        ///
        /// - Parameter delegate: 要交給根功能的意圖
        case delegate(Delegate)

        /// 分析畫面送出的使用者操作
        @CasePathable
        enum View: Equatable {

            /// 畫面出現時觸發載入
            case task

            /// 使用者點擊載入失敗畫面的重試鈕
            case retryTapped

            /// 使用者點擊每團毛利排行的某一團，帶開團名稱
            ///
            /// - Parameter name: 開團名稱
            case campaignTapped(String)

            /// 使用者點擊類別排行的某個類別，帶類別名稱
            ///
            /// - Parameter name: 類別名稱
            case categoryTapped(String)
        }

        /// 分析頁可能發出的跨 feature 意圖
        @CasePathable
        enum Delegate: Equatable {

            /// 要求重新載入
            case refresh

            /// 使用者點擊每團毛利排行的某一團，帶開團名稱
            ///
            /// - Parameter name: 開團名稱
            case campaignTapped(String)

            /// 使用者點擊類別排行的某個類別，帶類別名稱
            ///
            /// - Parameter name: 類別名稱
            case categoryTapped(String)
        }
    }

    // MARK: - Dependencies

    /// 分析出現與重試時記錄的現在時間
    @Dependency(\.date) private var date

    /// 記錄日期脈絡所用的行事曆
    @Dependency(\.calendar) private var calendar

    // MARK: - Body

    /// 只負責組合 reducer，本畫面自己的邏輯在 `core(state:action:)`
    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce(core)
    }
}

// MARK: - Private Method

private extension InsightsFeature {

    /// 依收到的 `Action` 更新 `State`，畫面操作轉成交給根功能的意圖
    ///
    /// - Parameters:
    ///   - state: 目前的分析狀態，直接就地修改
    ///   - action: 這次收到的事件
    /// - Returns: 接下來要執行的 `Effect`，沒有就回 `.none`
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .binding:
            return .none

        case .view(.task), .view(.retryTapped):
            state.refreshDateContext(now: date.now, calendar: calendar)
            return .send(.delegate(.refresh))

        case .view(.campaignTapped(let name)):
            return .send(.delegate(.campaignTapped(name)))

        case .view(.categoryTapped(let name)):
            return .send(.delegate(.categoryTapped(name)))

        case .delegate:
            return .none
        }
    }
}
