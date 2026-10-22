//
//  OrdersFilterOperations.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/2.
//

import ComposableArchitecture

/// 清單已套用篩選與篩選子層暫存選擇的狀態更新
enum OrdersFilterOperations {

}

// MARK: - Internal Method

extension OrdersFilterOperations {

    /// 套用跨功能篩選並重選第一筆，保留付款方式條件
    ///
    /// - Parameters:
    ///   - searchText: 客戶名稱搜尋
    ///   - category: 精準類別篩選
    ///   - state: 清單狀態
    static func applyNavigation(
        _ searchText: String,
        category: String?,
        state: inout OrderListFeature.State
    ) {
        state.searchText = searchText
        state.selectedStatus = .all
        state.selectedDatePeriod = .all
        state.selectedCategories = category.map { [$0] } ?? []
        state.selectFirstFilteredOrder()
        OrderListDestinationOperations.syncCommittedSelection(state: &state)
    }

    /// 切換狀態篩選並重選第一筆
    ///
    /// - Parameters:
    ///   - filter: 要套用的狀態篩選
    ///   - state: 要更新的訂單功能狀態
    static func statusFilterSelected(
        _ filter: OrderStatusFilter,
        state: inout OrderListFeature.State
    ) {
        state.selectedStatus = filter
        state.selectFirstFilteredOrder()
    }

    /// 切換日期區間篩選並重選第一筆
    ///
    /// - Parameters:
    ///   - period: 要套用的日期區間
    ///   - state: 要更新的訂單功能狀態
    static func datePeriodSelected(_ period: OrderDatePeriod, state: inout OrderListFeature.State) {
        state.selectedDatePeriod = period
        state.selectFirstFilteredOrder()
    }

    /// 提交完整類別集合，有變更時重選第一筆並關閉選擇器
    ///
    /// - Parameters:
    ///   - categories: 選擇器提交的類別集合
    ///   - state: 清單目前的狀態
    static func categoryApplied(_ categories: Set<String>, state: inout OrderListFeature.State) {
        if categories != state.selectedCategories {
            state.selectedCategories = categories
            state.selectFirstFilteredOrder()
        }
        state.destination = nil
    }

    /// 切換付款方式篩選並重選第一筆 (`nil` = 全部付款方式)
    ///
    /// - Parameters:
    ///   - paymentMethod: 要套用的付款方式；`nil` 代表全部付款方式
    ///   - state: 要更新的訂單功能狀態
    static func paymentMethodFilterSelected(
        _ paymentMethod: String?,
        state: inout OrderListFeature.State
    ) {
        state.selectedPaymentMethod = paymentMethod
        state.selectFirstFilteredOrder()
    }

    /// 開啟類別選擇器，以已套用集合重設草稿、搜尋與展開
    ///
    /// - Parameters:
    ///   - campaigns: 清單傳入的開團唯讀引用
    ///   - context: 清單 reducer 已解析的日期脈絡
    ///   - state: 要更新的清單狀態
    static func categoryPickerTapped(
        campaigns: SharedReader<[Campaign]>,
        context: OrderDateContext,
        state: inout OrderListFeature.State
    ) {
        state.destination = .categoryPicker(
            OrderCategoryPickerFeature.State(
                orders: state.$orders,
                campaigns: campaigns,
                lookupCatalog: state.$lookupCatalog,
                committedCategories: state.selectedCategories,
                dateContext: context
            )
        )
    }

    /// 開啟篩選 sheet，並以已套用值重設暫存選擇
    ///
    /// - Parameters:
    ///   - campaigns: 清單傳入的開團唯讀引用
    ///   - context: 清單 reducer 已解析的日期脈絡
    ///   - state: 要更新的訂單功能狀態
    static func filterSheetTapped(
        campaigns: SharedReader<[Campaign]>,
        context: OrderDateContext,
        state: inout OrderListFeature.State
    ) {
        state.destination = .filterSheet(
            OrderFilterFeature.State(
                orders: state.$orders,
                campaigns: campaigns,
                lookupCatalog: state.$lookupCatalog,
                committedFilterSelection: state.committedFilterSelection,
                dateContext: context
            )
        )
    }

    /// 清除已套用的三項篩選後重選一次，保留狀態、搜尋與目的地
    ///
    /// - Parameter state: 要更新的清單狀態
    /// - Returns: 至少一項條件變更時為 `true`，原本皆為預設時為 `false`
    static func clearFilters(state: inout OrderListFeature.State) -> Bool {
        guard state.committedFilterSelection.isActive else {
            return false
        }
        state.selectedDatePeriod = .all
        state.selectedCategories = []
        state.selectedPaymentMethod = nil
        state.selectFirstFilteredOrder()
        return true
    }

    /// 選擇整合篩選 sheet 的日期區間；僅更新暫存選擇，不改已套用的篩選
    ///
    /// - Parameters:
    ///   - period: 暫存的日期區間
    ///   - state: 要更新的訂單功能狀態
    static func filterPendingDatePeriodSelected(
        _ period: OrderDatePeriod,
        state: inout OrderFilterFeature.State
    ) {
        state.pendingFilterSelection.datePeriod = period
    }

    /// 選擇付款方式；只更新暫存選擇
    ///
    /// - Parameters:
    ///   - paymentMethod: 暫存的付款方式；`nil` 代表全部付款方式
    ///   - state: 要更新的訂單功能狀態
    static func filterPendingPaymentMethodSelected(
        _ paymentMethod: String?,
        state: inout OrderFilterFeature.State
    ) {
        state.pendingFilterSelection.paymentMethod = paymentMethod
    }

    /// 套用暫存篩選並關閉 sheet
    ///
    /// - Parameters:
    ///   - selection: 子層委派的日期、類別與付款方式
    ///   - state: 要更新的清單狀態
    static func filterApplied(
        _ selection: OrderFilterSelection,
        state: inout OrderListFeature.State
    ) {
        var hasFilterChanged = false
        if selection.datePeriod != state.selectedDatePeriod {
            state.selectedDatePeriod = selection.datePeriod
            hasFilterChanged = true
        }
        if selection.categories != state.selectedCategories {
            state.selectedCategories = selection.categories
            hasFilterChanged = true
        }
        if selection.paymentMethod != state.selectedPaymentMethod {
            state.selectedPaymentMethod = selection.paymentMethod
            hasFilterChanged = true
        }
        if hasFilterChanged {
            state.selectFirstFilteredOrder()
        }
        state.destination = nil
    }

    /// 取消篩選；有變更時先確認捨棄
    ///
    /// - Parameter state: 要更新的訂單功能狀態
    /// - Returns: 無變更時委派取消；有變更時呈現確認並回傳 `nil`
    static func filterCancelTapped(
        state: inout OrderFilterFeature.State
    ) -> OrderFilterFeature.Action.Delegate? {
        if !state.hasUnappliedFilterChanges {
            return .cancelled
        }

        state.filterDiscardConfirmation = OrderFilterConfirmations.discardChanges(discard: .discard)
        return nil
    }

    /// 確認捨棄整合篩選 sheet 尚未套用的變更
    ///
    /// - Parameter state: 要更新的訂單功能狀態
    static func filterDiscardConfirmed(state: inout OrderFilterFeature.State) {
        state.pendingFilterSelection = state.committedFilterSelection
    }

    /// 更新搜尋文字並重選第一筆
    ///
    /// - Parameters:
    ///   - text: 使用者輸入的搜尋文字
    ///   - state: 要更新的訂單功能狀態
    static func searchTextChanged(_ text: String, state: inout OrderListFeature.State) {
        state.searchText = text
        state.selectFirstFilteredOrder()
    }

    /// 選取訂單
    ///
    /// - Parameters:
    ///   - id: 被選取的訂單編號；`nil` 代表清除選取
    ///   - state: 要更新的訂單功能狀態
    static func orderSelected(_ id: LedgerOrder.ID?, state: inout OrderListFeature.State) {
        state.selectedOrderID = id
    }
}
