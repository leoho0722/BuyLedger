//
//  OrderCategoryGroups.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/18.
//

import Foundation

/// 類別分組、展開狀態與顯示清單的純計算輔助型別
enum OrderCategoryGroups {

}

// MARK: - Nested Types

extension OrderCategoryGroups {

    /// 類別所屬的開團活動分組種類
    enum Kind: String, CaseIterable, Equatable, Hashable, Sendable, Identifiable {

        /// 開團進行中
        case ongoing

        /// 已收單
        case closed

        /// 唯一識別值
        var id: Self {
            self
        }
    }

    /// 依開團活動分組後的類別清單
    struct Group: Equatable, Hashable, Sendable {

        /// 分組種類
        let kind: Kind

        /// 該組包含已排序的類別名稱清單
        let categories: [String]
    }

    /// 各組別目前的展開狀態
    struct Expansion: Equatable, Hashable, Sendable {

        /// 展開中的組別種類集合
        var expandedKinds: Set<Kind>

        /// 查詢特定組別是否展開
        ///
        /// - Parameter kind: 要查詢的組別種類
        /// - Returns: 是否處於展開狀態
        func isExpanded(_ kind: Kind) -> Bool {
            expandedKinds.contains(kind)
        }

        /// 切換特定組別的展開狀態
        ///
        /// - Parameter kind: 要切換的組別種類
        mutating func toggle(_ kind: Kind) {
            if expandedKinds.contains(kind) {
                expandedKinds.remove(kind)
            } else {
                expandedKinds.insert(kind)
            }
        }
    }

    /// 供畫面呈現與無障礙讀取的分組顯示資料
    struct Display: Equatable, Hashable, Sendable, Identifiable {

        /// 組別種類
        let kind: Kind

        /// 目前可見的類別清單，收合時為空陣列
        let visibleCategories: [String]

        /// 該組符合條件的類別數量 (顯示數)
        let displayedCount: Int

        /// 該組已選取的類別數量，包含搜尋時隱藏的已選取類別
        let selectedCount: Int

        /// 該組在畫面上是否呈現為展開
        let isExpanded: Bool

        /// 唯一識別值
        var id: Kind {
            kind
        }
    }
}

// MARK: - Internal Method

extension OrderCategoryGroups {

    /// 合併主檔與訂單類別，再依開團活動狀態分組
    ///
    /// - Parameters:
    ///   - orders: 提供已使用類別與開團關聯的訂單
    ///   - campaigns: 判斷活動狀態的開團清單
    ///   - catalog: 提供可用類別的主檔目錄
    ///   - context: 記錄的日期與行事曆
    /// - Returns: 分組後的類別清單，不含沒有類別的空組
    static func groups(
        orders: [LedgerOrder],
        campaigns: [Campaign],
        catalog: LookupCatalog,
        context: OrderDateContext
    ) -> [Group] {
        groups(
            categories: OrdersListQuery.mergedCategories(orders: orders, catalog: catalog),
            orders: orders,
            campaigns: campaigns,
            context: context
        )
    }

    /// 依開團活動狀態將可用類別分為「開團中」與「已收單」兩組
    ///
    /// - Parameters:
    ///   - categories: 可用類別集合，未排序，由本方法依語言排序一次
    ///   - orders: 訂單清單
    ///   - campaigns: 開團清單
    ///   - context: 記錄的日期脈絡
    /// - Returns: 分組後的類別清單，不含沒有類別的空組
    /// - Note: 判斷開團中類別時，先移除訂單類別前後空白與換行，並略過空字串
    static func groups(
        categories: some Collection<String>,
        orders: [LedgerOrder],
        campaigns: [Campaign],
        context: OrderDateContext
    ) -> [Group] {
        guard !categories.isEmpty else {
            return []
        }
        let ongoingCampaignNames = Set(
            campaigns
                .map { $0.evaluatingAutoClose(asOf: context.now, calendar: context.calendar) }
                .filter { $0.status == .ongoing }
                .map(\.name)
        )
        var ongoingCategories: Set<String> = []
        for order in orders where !ongoingCampaignNames.isDisjoint(with: order.campaignNames) {
            ongoingCategories.formUnion(
                order.categories
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        }
        let sortedCategories = categories.sorted { lhs, rhs in
            lhs.localizedStandardCompare(rhs) == .orderedAscending
        }
        var ongoingList: [String] = []
        var closedList: [String] = []
        for category in sortedCategories {
            if ongoingCategories.contains(category) {
                ongoingList.append(category)
            } else {
                closedList.append(category)
            }
        }
        var result: [Group] = []
        if !ongoingList.isEmpty {
            result.append(Group(kind: .ongoing, categories: ongoingList))
        }
        if !closedList.isEmpty {
            result.append(Group(kind: .closed, categories: closedList))
        }
        return result
    }

    /// 計算選擇器開啟時各組別的預設展開狀態
    ///
    /// - Parameters:
    ///   - groups: 分組後的類別清單
    ///   - selected: 目前已選取的類別集合
    /// - Returns: 初始展開狀態
    static func initialExpansion(groups: [Group], selected: Set<String>) -> Expansion {
        let ongoingGroup = groups.first { $0.kind == .ongoing }
        let closedGroup = groups.first { $0.kind == .closed }
        var expanded: Set<Kind> = []
        if ongoingGroup != nil {
            expanded.insert(.ongoing)
        }
        if let closedGroup {
            let hasSelectedInClosed = closedGroup.categories.contains { selected.contains($0) }
            if hasSelectedInClosed || ongoingGroup == nil {
                expanded.insert(.closed)
            }
        }
        return Expansion(expandedKinds: expanded)
    }

    /// 依展開狀態、選取集合與搜尋文字產生畫面呈現所需的資料
    ///
    /// - Parameters:
    ///   - groups: 分組後的類別清單
    ///   - expansion: 目前各組別的展開狀態
    ///   - selected: 目前已選取的類別集合
    ///   - searchText: 搜尋文字
    /// - Returns: 供畫面顯示的分組資料，不含沒有結果的組
    static func displayGroups(
        groups: [Group],
        expansion: Expansion,
        selected: Set<String>,
        searchText: String
    ) -> [Display] {
        let isSearchActive = isSearching(searchText)
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        var displays: [Display] = []
        for group in groups {
            let matchingCategories: [String]
            if isSearchActive {
                matchingCategories = group.categories.filter {
                    $0.localizedStandardContains(trimmedSearch)
                }
            } else {
                matchingCategories = group.categories
            }
            guard !matchingCategories.isEmpty else {
                continue
            }
            let isExpanded = isSearchActive || expansion.isExpanded(group.kind)
            let visibleCategories: [String]
            if isExpanded {
                visibleCategories = matchingCategories
            } else {
                visibleCategories = []
            }
            let displayedCount = matchingCategories.count
            let selectedCount = group.categories.filter { selected.contains($0) }.count
            displays.append(
                Display(
                    kind: group.kind,
                    visibleCategories: visibleCategories,
                    displayedCount: displayedCount,
                    selectedCount: selectedCount,
                    isExpanded: isExpanded
                )
            )
        }
        return displays
    }

    /// 判斷搜尋文字是否為有效搜尋
    ///
    /// - Parameter searchText: 使用者輸入的搜尋文字
    /// - Returns: 去除空白與換行後是否非空
    static func isSearching(_ searchText: String) -> Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 切換單一類別在選取集合中的成員資格
    ///
    /// - Parameters:
    ///   - category: 要切換的類別名稱
    ///   - selected: 目前已選取的類別集合
    /// - Returns: 切換後的選取集合
    static func toggled(_ category: String, in selected: Set<String>) -> Set<String> {
        var updated = selected
        if updated.contains(category) {
            updated.remove(category)
        } else {
            updated.insert(category)
        }
        return updated
    }
}
