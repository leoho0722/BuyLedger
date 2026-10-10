//
//  InsightsFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/2.
//

import ComposableArchitecture

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
    }

    // MARK: - Action

    /// 分析功能可處理的事件，依來源分為雙向繫結、畫面操作與交給根功能的意圖
    @CasePathable
    enum Action: BindableAction, Equatable {

        /// SwiftUI 雙向繫結事件 (分析區間 segmented picker)
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

    // MARK: - Body

    /// 只負責組合 reducer，本畫面自己的邏輯在 `core(state:action:)`
    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce(core)
    }
}

// MARK: - Private Method

private extension InsightsFeature {

    /// 依收到的 Action 更新 State，畫面操作轉成交給根功能的意圖
    ///
    /// - Parameters:
    ///   - state: 目前的分析狀態，直接就地修改
    ///   - action: 這次收到的事件
    /// - Returns: 接下來要執行的 Effect，沒有就回 `.none`
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .binding:
            return .none

        case .view(.task), .view(.retryTapped):
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
