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

    /// 篩選一次後產生清單與工具列共用的顯示資料
    ///
    /// - Parameter state: 清單的篩選值、唯讀訂單與勾選集合
    /// - Returns: 保留來源順序的訂單、識別值與全選狀態
    static func listSnapshot(state: OrderListFeature.State) -> OrderListSnapshot {
        let orders = filteredOrders(state: state)
        let ids = orders.map(\.id)
        return OrderListSnapshot(
            orders: orders,
            ids: ids,
            isAllSelected: isAllFilteredSelected(ids: ids, selectedOrderIDs: state.selectedOrderIDs)
        )
    }

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
            selectedCategories: state.selectedCategories,
            selectedPaymentMethod: state.selectedPaymentMethod,
            searchText: state.searchText,
            now: context.now,
            calendar: context.calendar
        )
    }

    /// 以清單記錄的日期產生分組標題與訂單區段
    ///
    /// - Parameters:
    ///   - orders: 已篩選的訂單
    ///   - context: 清單記錄的時間與行事曆；尚未記錄時為 `nil`
    ///   - locale: 日期標題使用的語系
    /// - Returns: 由新到舊排列的日期區段
    static func dateSections(
        orders: [LedgerOrder],
        context: OrderDateContext?,
        locale: Locale
    ) -> [OrderDateSection] {
        guard let context else {
            return []
        }
        return OrderDateSection.group(
            orders,
            referenceDate: context.now,
            calendar: context.calendar,
            locale: locale
        )
    }

    /// 取得主檔與訂單已使用的類別，去重後排序
    ///
    /// - Parameters:
    ///   - orders: 訂單快照
    ///   - catalog: 主檔目錄
    /// - Returns: 去重後依語言排序的類別
    static func availableCategories(orders: [LedgerOrder], catalog: LookupCatalog) -> [String] {
        mergedCategories(orders: orders, catalog: catalog).sorted { lhs, rhs in
            lhs.localizedStandardCompare(rhs) == .orderedAscending
        }
    }

    /// 合併主檔與訂單的商品類別，主檔類別原樣保留，訂單類別去除前後空白與換行並略過空字串
    ///
    /// - Parameters:
    ///   - orders: 訂單快照
    ///   - catalog: 主檔目錄
    /// - Returns: 去重後未排序的類別集合
    static func mergedCategories(orders: [LedgerOrder], catalog: LookupCatalog) -> Set<String> {
        let fromOrders = orders
            .flatMap(\.categories)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var merged = Set(catalog.categories)
        merged.formUnion(fromOrders)
        return merged
    }

    /// 檢查主檔或訂單中是否含有可用商品類別
    ///
    /// - Parameters:
    ///   - orders: 訂單快照
    ///   - catalog: 主檔目錄
    /// - Returns: 主檔類別非空或任一訂單含去空白後非空的類別時為 `true`，否則為 `false`
    static func hasAvailableCategories(orders: [LedgerOrder], catalog: LookupCatalog) -> Bool {
        if !catalog.categories.isEmpty {
            return true
        }
        return orders.contains {
            $0.categories.contains {
                !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
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
        let categories = selection.categories.sorted { lhs, rhs in
            lhs.localizedStandardCompare(rhs) == .orderedAscending
        }
        if categories.count >= 2 {
            parts.append(
                language.localizedString(
                    forKey: "orders.filter.label.categoryCount",
                    categories.count
                )
            )
        } else if let category = categories.first {
            parts.append(category)
        }
        if let paymentMethod = selection.paymentMethod {
            parts.append(paymentMethod)
        }
        return parts.isEmpty
            ? language.localized("common.action.label.all") : parts.joined(separator: " · ")
    }

    /// 依多選模式與選取筆數決定清單標題
    ///
    /// - Parameters:
    ///   - isSelecting: 是否處於多選模式
    ///   - count: 選取筆數
    /// - Returns: 導覽標題的本地化 key
    static func navigationTitle(isSelecting: Bool, count: Int) -> String.LocalizationValue {
        guard isSelecting else {
            return "orders.list.title"
        }
        guard count > 0 else {
            return "orders.edit.label.selectOrders"
        }
        var string = String.LocalizationValue.StringInterpolation(
            literalCapacity: 34,
            interpolationCount: 1
        )
        string.appendLiteral("orders.batch.message.selectedCount")
        string.appendLiteral(" ")
        string.appendInterpolation(count)
        return String.LocalizationValue(stringInterpolation: string)
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

// MARK: - Private Method

private extension OrdersListQuery {

    /// 判斷非空篩選結果是否全部已勾選，不排除篩選外的勾選
    ///
    /// - Parameters:
    ///   - ids: 已篩選的訂單識別值
    ///   - selectedOrderIDs: 已勾選的訂單識別值
    /// - Returns: 至少一筆篩選結果且每筆都已勾選時為真
    static func isAllFilteredSelected(
        ids: [LedgerOrder.ID],
        selectedOrderIDs: Set<LedgerOrder.ID>
    ) -> Bool {
        !ids.isEmpty && ids.allSatisfy { selectedOrderIDs.contains($0) }
    }
}
