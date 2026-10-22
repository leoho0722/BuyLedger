//
//  OrderCategoryGroupsTests+Expansion.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import Testing

@testable import BuyLedger

extension OrderCategoryGroupsTests {

    /// 兩組皆有類別且未選取已收單類別時，預設僅展開開團中
    @Test
    func initialExpansion_兩組皆有類別且未選取已收單類別_僅展開開團中() {
        // Given
        let groups = [
            OrderCategoryGroups.Group(kind: .ongoing, categories: ["美妝"]),
            OrderCategoryGroups.Group(kind: .closed, categories: ["書籍"]),
        ]

        // When
        let expansion = OrderCategoryGroups.initialExpansion(groups: groups, selected: ["美妝"])

        // Then
        #expect(expansion.isExpanded(.ongoing) == true)
        #expect(expansion.isExpanded(.closed) == false)
    }

    /// 已選取之類別包含已收單類別時，開團中與已收單兩組皆展開
    @Test
    func initialExpansion_已選取已收單類別_兩組皆展開() {
        // Given
        let groups = [
            OrderCategoryGroups.Group(kind: .ongoing, categories: ["美妝"]),
            OrderCategoryGroups.Group(kind: .closed, categories: ["書籍"]),
        ]

        // When
        let expansion = OrderCategoryGroups.initialExpansion(groups: groups, selected: ["美妝", "書籍"])

        // Then
        #expect(expansion.isExpanded(.ongoing) == true)
        #expect(expansion.isExpanded(.closed) == true)
    }

    /// 開團中組沒有任何類別時，已收單組展開
    @Test
    func initialExpansion_開團中組為空_展開已收單組() {
        // Given
        let groups = [
            OrderCategoryGroups.Group(kind: .closed, categories: ["書籍"]),
        ]

        // When
        let expansion = OrderCategoryGroups.initialExpansion(groups: groups, selected: [])

        // Then
        #expect(expansion.isExpanded(.closed) == true)
    }

    /// 空字串或僅含空白與換行時判定為非搜尋
    ///
    /// - Parameter text: 測試輸入的字串
    @Test(arguments: ["", "   ", "\n\t  "])
    func isSearching_空白或換行文字_判定為非搜尋(text: String) {
        // Given
        let searchText = text

        // When
        let isSearching = OrderCategoryGroups.isSearching(searchText)

        // Then
        #expect(isSearching == false)
    }

    /// 包含非空白字元時判定為有效搜尋
    ///
    /// - Parameter text: 測試輸入的字串
    @Test(arguments: ["食", "  品  ", "3C\n"])
    func isSearching_包含有效文字_判定為有效搜尋(text: String) {
        // Given
        let searchText = text

        // When
        let isSearching = OrderCategoryGroups.isSearching(searchText)

        // Then
        #expect(isSearching == true)
    }

    /// 切換單一組別僅更動該組展開狀態且不影響其他組別
    @Test
    func toggle_切換單一組別_僅更動該組展開狀態() {
        // Given
        var expansion = OrderCategoryGroups.Expansion(expandedKinds: [.ongoing])

        // When
        expansion.toggle(.ongoing)

        // Then
        #expect(expansion.isExpanded(.ongoing) == false)
        #expect(expansion.isExpanded(.closed) == false)
    }

    /// 切換單一組別兩次回到原狀且未更動其他組別
    @Test
    func toggle_切換單一組別兩次_回到原本展開狀態() {
        // Given
        var expansion = OrderCategoryGroups.Expansion(expandedKinds: [.ongoing])

        // When
        expansion.toggle(.ongoing)
        expansion.toggle(.ongoing)

        // Then
        #expect(expansion.isExpanded(.ongoing) == true)
        #expect(expansion.isExpanded(.closed) == false)
    }

    /// 點選未選中的類別時將其加入選取集合
    @Test
    func toggled_未選中類別_加入選取集合() {
        // Given
        let selected: Set<String> = ["書籍"]

        // When
        let result = OrderCategoryGroups.toggled("美妝", in: selected)

        // Then
        #expect(result == ["書籍", "美妝"])
    }

    /// 點選已選中的類別時將其自選取集合移除
    @Test
    func toggled_已選中類別_自選取集合移除() {
        // Given
        let selected: Set<String> = ["書籍", "美妝"]

        // When
        let result = OrderCategoryGroups.toggled("美妝", in: selected)

        // Then
        #expect(result == ["書籍"])
    }
}
