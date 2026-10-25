//
//  OrderCategoryGroupsExpansionTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import Testing

@testable import BuyLedger

/// `OrderCategoryGroups` 的單元測試，涵蓋預設展開、搜尋判斷與選取切換
struct OrderCategoryGroupsExpansionTests {

    /// 驗證兩組都有類別，且已選取的類別都在開團中時，預設只展開開團中組
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

    /// 驗證已選取的類別包含已收單組的類別時，開團中與已收單兩組都展開
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

    /// 驗證清單中沒有開團中組時，預設展開已收單組
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

    /// 驗證空字串或只含空白與換行的文字，判定為非搜尋
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

    /// 驗證含有非空白字元的文字判定為有效搜尋，前後的空白與換行不影響判定
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

    /// 驗證切換已展開的組別後該組收合，其他組別維持收合
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

    /// 驗證切換已收合的組別後該組展開，其他組別維持收合
    @Test
    func toggle_已收合組別_展開該組且不影響其他組別() {
        // Given
        var expansion = OrderCategoryGroups.Expansion(expandedKinds: [])

        // When
        expansion.toggle(.ongoing)

        // Then
        #expect(expansion.isExpanded(.ongoing) == true)
        #expect(expansion.isExpanded(.closed) == false)
    }

    /// 驗證點選未選中的類別後，該類別加入選取集合，既有的選取保留
    @Test
    func toggled_未選中類別_加入選取集合() {
        // Given
        let selected: Set<String> = ["書籍"]

        // When
        let result = OrderCategoryGroups.toggled("美妝", in: selected)

        // Then
        #expect(result == ["書籍", "美妝"])
    }

    /// 驗證點選已選中的類別後，該類別自選取集合移除，其他已選類別保留
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
