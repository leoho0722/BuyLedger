//
//  OrderDetailPath.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/12.
//

import ComposableArchitecture
import Foundation

/// ``OrdersFeature/State/detailPath`` 的最小堆疊元素
///
/// iPhone (compact) 的訂單詳情頁 (``OrderDetailView``) 是純展示型 view，只需知道要顯示哪一筆訂單；本
/// reducer 不持有商業邏輯，僅承載訂單編號，讓堆疊由 ``OrdersFeature`` 的 `StackState` 擁有並可被 TestStore 斷言
@Reducer
struct OrderDetailPath {

    // MARK: - State

    /// 堆疊中單一詳情頁的狀態
    @ObservableState
    struct State: Equatable {

        /// 對應顯示的訂單編號；實際訂單資料由 ``OrdersFeature/State/orders`` 依此編號查得
        let orderID: LedgerOrder.ID
    }

    // MARK: - Action

    /// 本元素不處理任何事件；詳情頁的操作 (更新狀態／合併／編輯／刪除) 皆透過父層 ``OrdersFeature`` 既有 action 送出
    enum Action: Equatable {}

    // MARK: - Reducer Body

    /// 純展示元素，無自訂邏輯
    var body: some Reducer<State, Action> {
        EmptyReducer()
    }
}
