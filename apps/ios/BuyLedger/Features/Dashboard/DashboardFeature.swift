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

        /// 總覽「進行中的開團」區段的一列：開團與它的訂單彙總
        struct OngoingCampaignRow {

            /// 進行中的開團
            let campaign: Campaign

            /// 該團的訂單彙總
            let summary: CampaignSummary
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

    // MARK: - Body

    /// 只負責組合 reducer，本畫面自己的邏輯在 `core(state:action:)`
    var body: some Reducer<State, Action> {
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
