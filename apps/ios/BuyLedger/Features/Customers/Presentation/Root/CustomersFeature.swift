//
//  CustomersFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/12.
//

import ComposableArchitecture
import Foundation

/// 客戶彙總功能，提供訂單投影與客戶消費摘要
@Reducer
struct CustomersFeature {

    // MARK: - Properties

    /// 強調區塊顯示的前幾名客戶數量
    static let topHighlightCount = 3

    // MARK: - State

    /// 客戶彙總功能狀態
    @ObservableState
    struct State: Equatable {

        /// 唯讀訂單投影；由根功能同步更多頁來源，推入後持續共享更新
        @SharedReader var orders: [LedgerOrder]

        /// 由根功能同步的訂單載入狀態
        @SharedReader var loadState: OrdersLoadState

        /// 依累計消費由高到低排序的客戶彙總列
        var customers: [CustomerRow] {
            CustomerRow.aggregate(orders: orders)
        }

        /// 強調區塊的前幾名客戶，依累計消費由高到低標示名次 (由 1 起算)
        var topCustomers: [CustomerRank] {
            customers
                .prefix(CustomersFeature.topHighlightCount)
                .enumerated()
                .map { CustomerRank(rank: $0.offset + 1, customer: $0.element) }
        }

        /// 依訂單載入結果決定顯示進度、失敗原因、空名單或客戶清單
        var screenState: ScreenState {
            switch loadState {
            case .loading:
                return .loading

            case .failed(let message):
                return .failed(message)

            case .loaded:
                if customers.isEmpty {
                    return .empty
                }
                return .customers
            }
        }

        /// 以宿主提供的唯讀來源建立客戶頁
        ///
        /// - Parameters:
        ///   - orders: 根功能同步的訂單投影
        ///   - loadState: 根功能同步的訂單載入狀態
        init(orders: SharedReader<[LedgerOrder]>, loadState: SharedReader<OrdersLoadState>) {
            _orders = orders
            _loadState = loadState
        }

        /// 客戶頁依訂單載入結果顯示的內容種類
        enum ScreenState: Equatable {

            /// 訂單尚在載入，顯示進度
            case loading

            /// 訂單載入失敗，顯示原因並提供重試
            ///
            /// - Parameter message: 訂單載入失敗的原因
            case failed(LocalizedStringResource)

            /// 訂單已載入，但沒有客戶資料
            case empty

            /// 訂單已載入，顯示客戶清單
            case customers
        }
    }

    // MARK: - Action

    /// 客戶彙總功能可處理的事件
    enum Action: Equatable {

        /// 使用者可直接操作的客戶名單事件
        ///
        /// - Parameter action: 使用者在客戶名單畫面執行的操作
        case view(View)

        /// 交給更多頁 (`MoreFeature`) 轉送的跨功能意圖
        ///
        /// - Parameter action: 要交給更多頁處理的結果
        case delegate(Delegate)

        /// 客戶名單畫面事件
        @CasePathable
        enum View: Equatable {

            /// 畫面出現時觸發訂單載入
            case task

            /// 使用者在失敗畫面要求重新載入訂單
            case retryTapped

            /// 使用者點擊客戶列或強調卡
            ///
            /// - Parameter name: 被點擊的客戶姓名
            case customerTapped(String)
        }

        /// 客戶名單可能發出的跨 feature 意圖
        @CasePathable
        enum Delegate: Equatable {

            /// 請根功能觸發訂單載入
            case ordersLoadRequested

            /// 使用者已選定客戶，交由根功能導覽至訂單頁
            ///
            /// - Parameter name: 被選定的客戶姓名
            case customerSelected(String)
        }
    }

    // MARK: - Body

    /// 只負責組合 reducer，客戶頁自己的邏輯在 `core(state:action:)`
    var body: some ReducerOf<Self> {
        Reduce(core)
    }
}

// MARK: - Private Method

private extension CustomersFeature {

    /// 依收到的事件更新客戶彙總狀態，並回傳要執行的 Effect
    ///
    /// - Parameters:
    ///   - state: 目前的客戶彙總狀態
    ///   - action: 這次收到的客戶彙總事件
    /// - Returns: 接下來要執行的 Effect，沒有就回 `.none`
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .view(.task), .view(.retryTapped):
            return .send(.delegate(.ordersLoadRequested))

        case .view(.customerTapped(let name)):
            return .send(.delegate(.customerSelected(name)))

        case .delegate:
            return .none
        }
    }
}
