//
//  OrdersFilterOperations.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/2.
//

import ComposableArchitecture
import Foundation

/// ``OrdersFeature`` 篩選與選取子域的分支主體
enum OrdersFilterOperations {}

// MARK: - Internal Method

extension OrdersFilterOperations {
    
    /// 使用者切換狀態篩選
    /// - Parameters:
    ///   - filter: 要套用的狀態篩選
    ///   - state: 要更新的訂單功能狀態
    ///   - referenceDate: 用於計算日期篩選的基準時間
    ///   - calendar: 日期篩選使用的行事曆
    static func statusFilterSelected(
        _ filter: OrderStatusFilter,
        state: inout OrdersFeature.State,
        referenceDate: Date,
        calendar: Calendar
    ) {
        state.selectedStatus = filter
        state.selectFirstFilteredOrder(referenceDate: referenceDate, calendar: calendar)
    }
    
    /// 使用者切換日期區間篩選
    /// - Parameters:
    ///   - period: 要套用的日期區間
    ///   - state: 要更新的訂單功能狀態
    ///   - referenceDate: 用於計算日期篩選的基準時間
    ///   - calendar: 日期篩選使用的行事曆
    static func datePeriodSelected(
        _ period: OrderDatePeriod,
        state: inout OrdersFeature.State,
        referenceDate: Date,
        calendar: Calendar
    ) {
        state.selectedDatePeriod = period
        state.selectFirstFilteredOrder(referenceDate: referenceDate, calendar: calendar)
    }
    
    /// 使用者切換商品類別篩選 (`nil` = 全部類別)
    /// - Parameters:
    ///   - category: 要套用的商品類別；`nil` 代表全部類別
    ///   - state: 要更新的訂單功能狀態
    ///   - referenceDate: 用於計算日期篩選的基準時間
    ///   - calendar: 日期篩選使用的行事曆
    static func categoryFilterSelected(
        _ category: String?,
        state: inout OrdersFeature.State,
        referenceDate: Date,
        calendar: Calendar
    ) {
        state.selectedCategory = category
        state.selectFirstFilteredOrder(referenceDate: referenceDate, calendar: calendar)
    }
    
    /// 使用者切換付款方式篩選 (`nil` = 全部付款方式)
    /// - Parameters:
    ///   - paymentMethod: 要套用的付款方式；`nil` 代表全部付款方式
    ///   - state: 要更新的訂單功能狀態
    ///   - referenceDate: 用於計算日期篩選的基準時間
    ///   - calendar: 日期篩選使用的行事曆
    static func paymentMethodFilterSelected(
        _ paymentMethod: String?,
        state: inout OrdersFeature.State,
        referenceDate: Date,
        calendar: Calendar
    ) {
        state.selectedPaymentMethod = paymentMethod
        state.selectFirstFilteredOrder(referenceDate: referenceDate, calendar: calendar)
    }
    
    /// 使用者切換指定開團篩選 (`nil` = 全部開團)
    /// - Parameters:
    ///   - campaign: 要套用的開團；`nil` 代表全部開團
    ///   - state: 要更新的訂單功能狀態
    ///   - referenceDate: 用於計算日期篩選的基準時間
    ///   - calendar: 日期篩選使用的行事曆
    static func campaignFilterSelected(
        _ campaign: String?,
        state: inout OrdersFeature.State,
        referenceDate: Date,
        calendar: Calendar
    ) {
        state.selectedCampaign = campaign
        state.selectFirstFilteredOrder(referenceDate: referenceDate, calendar: calendar)
    }
    
    /// 使用者切換開團狀態篩選 (`nil` = 全部狀態)
    /// - Parameters:
    ///   - campaignStatus: 要套用的開團狀態；`nil` 代表全部狀態
    ///   - state: 要更新的訂單功能狀態
    ///   - referenceDate: 用於計算日期篩選的基準時間
    ///   - calendar: 日期篩選使用的行事曆
    static func campaignStatusFilterSelected(
        _ campaignStatus: CampaignStatus?,
        state: inout OrdersFeature.State,
        referenceDate: Date,
        calendar: Calendar
    ) {
        state.selectedCampaignStatus = campaignStatus
        state.selectFirstFilteredOrder(referenceDate: referenceDate, calendar: calendar)
    }
    
    /// 使用者點擊 iPad (regular) 商品類別篩選 trigger，開啟類別 picker sheet
    /// - Parameter state: 要更新的訂單功能狀態
    static func categoryPickerTapped(state: inout OrdersFeature.State) {
        state.showsCategoryPicker = true
    }
    
    /// 使用者點擊 iPad (regular) 付款方式篩選 trigger，開啟付款方式 picker sheet
    /// - Parameter state: 要更新的訂單功能狀態
    static func paymentMethodPickerTapped(state: inout OrdersFeature.State) {
        state.showsPaymentMethodPicker = true
    }
    
    /// 開啟篩選 sheet，並以已套用值重設暫存選擇
    /// - Parameter state: 要更新的訂單功能狀態
    static func filterSheetTapped(state: inout OrdersFeature.State) {
        state.pendingFilterSelection = state.committedFilterSelection
        state.filterSheetSearchText = ""
        state.showsFilterSheet = true
    }
    
    /// 使用者在整合篩選 sheet 選擇日期區間；僅更新未套用選擇，不 commit
    /// - Parameters:
    ///   - period: 暫存的日期區間
    ///   - state: 要更新的訂單功能狀態
    static func filterPendingDatePeriodSelected(
        _ period: OrderDatePeriod,
        state: inout OrdersFeature.State
    ) {
        state.pendingFilterSelection.datePeriod = period
    }
    
    /// 選擇商品類別；只更新暫存選擇
    /// - Parameters:
    ///   - category: 暫存的商品類別；`nil` 代表全部類別
    ///   - state: 要更新的訂單功能狀態
    static func filterPendingCategorySelected(
        _ category: String?,
        state: inout OrdersFeature.State
    ) {
        state.pendingFilterSelection.category = category
    }
    
    /// 選擇付款方式；只更新暫存選擇
    /// - Parameters:
    ///   - paymentMethod: 暫存的付款方式；`nil` 代表全部付款方式
    ///   - state: 要更新的訂單功能狀態
    static func filterPendingPaymentMethodSelected(
        _ paymentMethod: String?,
        state: inout OrdersFeature.State
    ) {
        state.pendingFilterSelection.paymentMethod = paymentMethod
    }
    
    /// 套用暫存篩選並關閉 sheet
    /// - Parameters:
    ///   - state: 要更新的訂單功能狀態
    ///   - referenceDate: 用於計算日期篩選的基準時間
    ///   - calendar: 日期篩選使用的行事曆
    static func filterApplyTapped(
        state: inout OrdersFeature.State,
        referenceDate: Date,
        calendar: Calendar
    ) {
        var didChangeFilter = false
        if state.pendingFilterSelection.datePeriod != state.selectedDatePeriod {
            state.selectedDatePeriod = state.pendingFilterSelection.datePeriod
            didChangeFilter = true
        }
        if state.pendingFilterSelection.category != state.selectedCategory {
            state.selectedCategory = state.pendingFilterSelection.category
            didChangeFilter = true
        }
        if state.pendingFilterSelection.paymentMethod != state.selectedPaymentMethod {
            state.selectedPaymentMethod = state.pendingFilterSelection.paymentMethod
            didChangeFilter = true
        }
        if didChangeFilter {
            state.selectFirstFilteredOrder(referenceDate: referenceDate, calendar: calendar)
        }
        state.showsFilterSheet = false
    }
    
    /// 取消篩選；有變更時先確認捨棄
    /// - Parameter state: 要更新的訂單功能狀態
    static func filterCancelTapped(state: inout OrdersFeature.State) {
        guard state.hasUnappliedFilterChanges else {
            state.showsFilterSheet = false
            return
        }
        
        state.filterDiscardConfirmation = AlertState {
            TextState("捨棄變更")
        } actions: {
            ButtonState(role: .destructive, action: .discard) {
                TextState("捨棄變更")
            }
            ButtonState(role: .cancel) {
                TextState("繼續編輯")
            }
        } message: {
            TextState("這些篩選條件尚未套用，離開後將不會保留。")
        }
    }
    
    /// 使用者確認捨棄整合篩選 sheet 尚未套用的變更
    /// - Parameter state: 要更新的訂單功能狀態
    static func filterDiscardConfirmed(state: inout OrdersFeature.State) {
        state.pendingFilterSelection = state.committedFilterSelection
        state.showsFilterSheet = false
    }
    
    /// 使用者輸入搜尋文字
    /// - Parameters:
    ///   - text: 使用者輸入的搜尋文字
    ///   - state: 要更新的訂單功能狀態
    ///   - referenceDate: 用於計算日期篩選的基準時間
    ///   - calendar: 日期篩選使用的行事曆
    static func searchTextChanged(
        _ text: String,
        state: inout OrdersFeature.State,
        referenceDate: Date,
        calendar: Calendar
    ) {
        state.searchText = text
        state.selectFirstFilteredOrder(referenceDate: referenceDate, calendar: calendar)
    }
    
    /// 使用者選取訂單
    /// - Parameters:
    ///   - id: 被選取的訂單編號；`nil` 代表清除選取
    ///   - state: 要更新的訂單功能狀態
    static func orderSelected(_ id: LedgerOrder.ID?, state: inout OrdersFeature.State) {
        state.selectedOrderID = id
    }
}
