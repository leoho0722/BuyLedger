//
//  OrdersListQuery.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import Foundation

/// 訂單清單的純篩選、日期分組與顯示資料計算
enum OrdersListQuery {

}

// MARK: - Internal Method

extension OrdersListQuery {

    /// 依清單記錄的時間套用全部篩選，尚未記錄日期時為空
    ///
    /// - Parameter state: 清單的篩選值與唯讀資料
    /// - Returns: 保留原始順序的篩選結果
    static func filteredOrders(state: OrderListFeature.State) -> [LedgerOrder] {
        guard let context = state.dateContext else {
            return []
        }
        return OrdersQuery.filteredOrders(
            orders: state.orders,
            selectedStatus: state.selectedStatus,
            selectedDatePeriod: state.selectedDatePeriod,
            selectedCategory: state.selectedCategory,
            selectedPaymentMethod: state.selectedPaymentMethod,
            searchText: state.searchText,
            now: context.now,
            calendar: context.calendar
        )
    }

    /// 判斷非空篩選結果是否全部已勾選，不排除篩選外的勾選
    ///
    /// - Parameter state: 篩選結果與已勾選識別值
    /// - Returns: 至少一筆篩選結果且每筆都已勾選時為真
    static func isAllFilteredSelected(state: OrderListFeature.State) -> Bool {
        let ids = state.filteredIDs
        return !ids.isEmpty && ids.allSatisfy { state.selectedOrderIDs.contains($0) }
    }

    /// 以清單記錄的日期產生分組標題與訂單區段
    ///
    /// - Parameters:
    ///   - state: 清單狀態
    ///   - locale: 日期標題使用的語系
    /// - Returns: 由新到舊排列的日期區段
    static func dateSections(state: OrderListFeature.State, locale: Locale) -> [OrderDateSection] {
        guard let context = state.dateContext else {
            return []
        }
        return OrderDateSection.group(
            filteredOrders(state: state),
            referenceDate: context.now,
            calendar: context.calendar,
            locale: locale
        )
    }

    /// 主檔與訂單已使用的類別，去重後排序
    ///
    /// - Parameters:
    ///   - orders: 訂單快照
    ///   - catalog: 主檔目錄
    /// - Returns: 去重後依語言排序的類別
    static func availableCategories(orders: [LedgerOrder], catalog: LookupCatalog) -> [String] {
        let fromOrders = orders
            .flatMap(\.categories)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var merged = Set(catalog.categories)
        merged.formUnion(fromOrders)
        return merged.sorted { lhs, rhs in
            lhs.localizedStandardCompare(rhs) == .orderedAscending
        }
    }

    /// 合併主檔與訂單的付款方式，保留主檔旗標
    ///
    /// - Parameters:
    ///   - orders: 訂單快照
    ///   - catalog: 主檔目錄
    /// - Returns: 依名稱排序的付款方式
    static func availablePaymentMethods(
        orders: [LedgerOrder],
        catalog: LookupCatalog
    ) -> [PaymentMethodInfo] {
        var byName: [String: PaymentMethodInfo] = [:]
        for info in catalog.paymentMethods {
            byName[info.name] = info
        }
        for order in orders {
            let trimmed = order.paymentMethod.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, byName[trimmed] == nil else {
                continue
            }
            byName[trimmed] = PaymentMethodInfo(
                name: trimmed,
                isCardless: false,
                isBankTransfer: false,
                isCashOnDelivery: false
            )
        }
        return byName.values
            .sorted { lhs, rhs in
                lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
    }

    /// 以篩選 sheet 的搜尋文字比對付款方式名稱
    ///
    /// - Parameter state: 篩選子層的唯讀資料與搜尋文字
    /// - Returns: 符合搜尋條件的名稱
    static func filteredPaymentMethods(state: OrderFilterFeature.State) -> [String] {
        let names = availablePaymentMethods(orders: state.orders, catalog: state.lookupCatalog)
            .map(\.name)
        return matching(names, searchText: state.filterSheetSearchText)
    }

    /// 以去除前後空白的搜尋文字比對主檔名稱
    ///
    /// - Parameters:
    ///   - names: 可用名稱
    ///   - searchText: 篩選 sheet 的搜尋文字
    /// - Returns: 相符名稱；空查詢回傳全部
    static func matching(_ names: [String], searchText: String) -> [String] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? names : names.filter { $0.localizedStandardContains(trimmed) }
    }

    /// 本地化已套用篩選的固定詞，主檔名稱與分隔符保留原文
    ///
    /// - Parameters:
    ///   - selection: 已套用的日期、類別與付款方式
    ///   - language: 畫面使用的語言
    /// - Returns: 依日期、類別、付款方式順序排列的摘要，無條件時顯示全部
    static func filterSummary(selection: OrderFilterSelection, language: AppLanguage) -> String {
        var parts: [String] = []
        if selection.datePeriod != .all {
            parts.append(language.localized(String.LocalizationValue(selection.datePeriod.title)))
        }
        if let category = selection.category {
            parts.append(category)
        }
        if let paymentMethod = selection.paymentMethod {
            parts.append(paymentMethod)
        }
        return parts.isEmpty ? language.localized("全部") : parts.joined(separator: " · ")
    }

    /// 依多選模式與選取筆數決定清單標題
    ///
    /// - Parameters:
    ///   - isSelecting: 是否處於多選模式
    ///   - count: 選取筆數
    /// - Returns: 導覽標題的本地化 key
    static func navigationTitle(isSelecting: Bool, count: Int) -> String.LocalizationValue {
        guard isSelecting else {
            return "訂單"
        }
        return count == 0 ? "選擇訂單" : "已選 \(count) 筆"
    }

    /// 依已載入、錯誤、載入中順序決定呈現狀態
    ///
    /// - Parameters:
    ///   - hasLoaded: 是否已完成載入
    ///   - errorMessage: 載入失敗訊息
    /// - Returns: 清單要呈現的載入狀態
    static func loadState(hasLoaded: Bool, errorMessage: String?) -> OrdersLoadState {
        if hasLoaded {
            return .loaded
        }
        if let errorMessage {
            return .failed(errorMessage)
        }
        return .loading
    }
}
