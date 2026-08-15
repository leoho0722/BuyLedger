//
//  OrdersBatchOperations.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/2.
//

import Foundation

/// ``OrdersFeature`` 多選與批次改狀態子域的分支主體
enum OrdersBatchOperations {}

// MARK: - Internal Method

extension OrdersBatchOperations {
    
    /// 進入／退出多選模式；退出時清空已選集合
    /// - Parameter state: 要更新的訂單功能狀態
    static func selectionModeToggled(state: inout OrdersFeature.State) {
        state.isSelecting.toggle()
        if !state.isSelecting {
            state.selectedOrderIDs = []
        }
    }
    
    /// 多選模式下切換單筆訂單的勾選狀態
    /// - Parameters:
    ///   - id: 要切換勾選狀態的訂單編號
    ///   - state: 要更新的訂單功能狀態
    static func orderSelectionToggled(_ id: LedgerOrder.ID, state: inout OrdersFeature.State) {
        if state.selectedOrderIDs.contains(id) {
            state.selectedOrderIDs.remove(id)
        } else {
            state.selectedOrderIDs.insert(id)
        }
    }
    
    /// 全選目前篩選後清單
    /// - Parameters:
    ///   - state: 要更新的訂單功能狀態
    ///   - referenceDate: 用於計算日期篩選的基準時間
    ///   - calendar: 日期篩選使用的行事曆
    static func selectAllTapped(
        state: inout OrdersFeature.State,
        referenceDate: Date,
        calendar: Calendar
    ) {
        let filtered = state.filteredOrders(referenceDate: referenceDate, calendar: calendar)
        state.selectedOrderIDs = Set(filtered.map(\.id))
    }
    
    /// 清除目前已選集合
    /// - Parameter state: 要更新的訂單功能狀態
    static func clearSelectionTapped(state: inout OrdersFeature.State) {
        state.selectedOrderIDs = []
    }
    
    /// 對已選訂單批次套用同一目標狀態 (目標清單已排除 merged)
    /// - Parameters:
    ///   - newStatus: 批次套用的目標狀態
    ///   - state: 將被修改的 ``OrdersFeature/State``
    /// - Returns: 實際變更的訂單；沒有變更時回傳 `nil`
    static func batchStatusChanged(
        _ newStatus: OrderStatus,
        state: inout OrdersFeature.State
    ) -> [LedgerOrder]? {
        // merged 僅由合併流程寫入；批次目標清單已於 view 端排除，此處為防衛
        guard newStatus != .merged else {
            return nil
        }
        
        // 先計算完整結果，避免寫入失敗時只更新部分畫面。
        let selectedIDs = state.selectedOrderIDs
        let changed = state.orders
            .filter { selectedIDs.contains($0.id) && $0.status != newStatus }
            .map { $0.withStatus(newStatus) }
        
        // 完成批次操作後退出多選並清空選取
        state.isSelecting = false
        state.selectedOrderIDs = []
        
        guard !changed.isEmpty else {
            return nil
        }
        return changed
    }
    
    /// 批次狀態變更落盤成功，套用到畫面狀態
    /// - Parameters:
    ///   - changedOrders: 已成功寫入的訂單
    ///   - state: 要更新的訂單功能狀態
    static func batchStatusChangePersisted(
        _ changedOrders: [LedgerOrder],
        state: inout OrdersFeature.State
    ) {
        for updated in changedOrders {
            if let index = state.orders.firstIndex(where: { $0.id == updated.id }) {
                state.orders[index] = updated
            }
        }
    }
}
