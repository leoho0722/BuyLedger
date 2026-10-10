//
//  OrdersBatchOperations.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/2.
//

import Foundation

/// ``OrderListFeature`` 的多選與批次改狀態操作，直接改寫清單狀態
enum OrdersBatchOperations {

}

// MARK: - Internal Method

extension OrdersBatchOperations {

    /// 批次更新可選的狀態，已合併僅由合併流程寫入
    ///
    /// - Returns: 依既有順序排列、排除已合併的狀態
    static func targetStatuses() -> [OrderStatus] {
        OrderStatus.allCases.filter { $0 != .merged }
    }

    /// 進入／退出多選模式；退出時清空已選集合
    ///
    /// - Parameter state: 要更新的訂單功能狀態
    static func selectionModeToggled(state: inout OrderListFeature.State) {
        state.isSelecting.toggle()
        if !state.isSelecting {
            state.selectedOrderIDs = []
        }
    }

    /// 多選模式下切換單筆訂單的勾選狀態
    ///
    /// - Parameters:
    ///   - id: 要切換勾選狀態的訂單編號
    ///   - state: 要更新的訂單功能狀態
    static func orderSelectionToggled(_ id: LedgerOrder.ID, state: inout OrderListFeature.State) {
        if state.selectedOrderIDs.contains(id) {
            state.selectedOrderIDs.remove(id)
        } else {
            state.selectedOrderIDs.insert(id)
        }
    }

    /// 全選目前篩選後清單
    ///
    /// - Parameter state: 要更新的訂單功能狀態
    static func selectAllTapped(state: inout OrderListFeature.State) {
        let filtered = state.filteredOrders
        state.selectedOrderIDs = Set(filtered.map(\.id))
    }

    /// 清除目前已選集合
    ///
    /// - Parameter state: 要更新的訂單功能狀態
    static func clearSelectionTapped(state: inout OrderListFeature.State) {
        state.selectedOrderIDs = []
    }

    /// 對已選訂單批次套用同一目標狀態 (目標清單已排除 `merged`)
    ///
    /// - Parameters:
    ///   - newStatus: 批次套用的目標狀態
    ///   - state: 將被修改的 ``OrderListFeature/State``
    /// - Returns: 實際變更的訂單；沒有變更時回傳 `nil`
    static func batchStatusChanged(
        _ newStatus: OrderStatus,
        state: inout OrderListFeature.State
    ) -> [LedgerOrder]? {
        // `merged` 僅由合併流程寫入；批次目標清單已由 `targetStatuses()` 排除，此處為防衛
        guard newStatus != .merged else {
            return nil
        }

        // 先計算完整結果，避免寫入失敗時只更新部分畫面
        let selectedIDs = state.selectedOrderIDs
        let changed = state.orders
            .filter { selectedIDs.contains($0.id) && $0.status != newStatus }
            .map { $0.withStatus(newStatus) }

        // 批次送出後結束多選，讓下一次多選從空白開始
        state.isSelecting = false
        state.selectedOrderIDs = []

        guard !changed.isEmpty else {
            return nil
        }
        return changed
    }
}
