//
//  OrderCategoryGroupsDisplayTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import Testing

@testable import BuyLedger

/// `OrderCategoryGroups.displayGroups` 的單元測試，涵蓋搜尋與展開狀態下的顯示結果
struct OrderCategoryGroupsDisplayTests {

    /// 驗證搜尋「食」時，兩組都展開，各組只顯示名稱含「食」的類別，即使儲存的展開狀態只展開一組
    @Test
    func displayGroups_搜尋包含食_兩組皆展開且僅顯示相符類別() {
        // Given
        let groups = [
            OrderCategoryGroups.Group(kind: .ongoing, categories: ["3C", "美妝", "零食"]),
            OrderCategoryGroups.Group(kind: .closed, categories: ["保健", "食品", "書籍", "精品"]),
        ]
        let expansion = OrderCategoryGroups.Expansion(expandedKinds: [.ongoing])

        // When
        let displays = OrderCategoryGroups.displayGroups(
            groups: groups,
            expansion: expansion,
            selected: [],
            searchText: "食"
        )

        // Then
        #expect(
            displays == [
                OrderCategoryGroups.Display(
                    kind: .ongoing,
                    visibleCategories: ["零食"],
                    displayedCount: 1,
                    selectedCount: 0,
                    isExpanded: true
                ),
                OrderCategoryGroups.Display(
                    kind: .closed,
                    visibleCategories: ["食品"],
                    displayedCount: 1,
                    selectedCount: 0,
                    isExpanded: true
                ),
            ]
        )
    }

    /// 驗證搜尋「品」時，開團中沒有相符類別的組別整組不回傳，只回傳已收單組中相符的類別
    @Test
    func displayGroups_搜尋關鍵字僅命中已收單_開團中隱藏且僅回傳已收單組() {
        // Given
        let groups = [
            OrderCategoryGroups.Group(kind: .ongoing, categories: ["3C", "美妝", "零食"]),
            OrderCategoryGroups.Group(kind: .closed, categories: ["保健", "食品", "書籍", "精品"]),
        ]
        let expansion = OrderCategoryGroups.Expansion(expandedKinds: [.ongoing])

        // When
        let displays = OrderCategoryGroups.displayGroups(
            groups: groups,
            expansion: expansion,
            selected: [],
            searchText: "品"
        )

        // Then
        #expect(
            displays == [
                OrderCategoryGroups.Display(
                    kind: .closed,
                    visibleCategories: ["食品", "精品"],
                    displayedCount: 2,
                    selectedCount: 0,
                    isExpanded: true
                ),
            ]
        )
    }

    /// 驗證搜尋文字只有空白時視為未搜尋，各組依既有的展開狀態顯示，收合的組別不列出類別
    @Test
    func displayGroups_搜尋純空白文字_視為未搜尋且保留既有展開狀態() {
        // Given
        let groups = [
            OrderCategoryGroups.Group(kind: .ongoing, categories: ["3C", "美妝", "零食"]),
            OrderCategoryGroups.Group(kind: .closed, categories: ["保健", "食品", "書籍", "精品"]),
        ]
        let expansion = OrderCategoryGroups.Expansion(expandedKinds: [.ongoing])

        // When
        let displays = OrderCategoryGroups.displayGroups(
            groups: groups,
            expansion: expansion,
            selected: [],
            searchText: "   "
        )

        // Then
        #expect(
            displays == [
                OrderCategoryGroups.Display(
                    kind: .ongoing,
                    visibleCategories: ["3C", "美妝", "零食"],
                    displayedCount: 3,
                    selectedCount: 0,
                    isExpanded: true
                ),
                OrderCategoryGroups.Display(
                    kind: .closed,
                    visibleCategories: [],
                    displayedCount: 4,
                    selectedCount: 0,
                    isExpanded: false
                ),
            ]
        )
    }

    /// 驗證搜尋時，已選數以整組計算，包含被搜尋隱藏的已選取類別，顯示數則只計相符的類別
    @Test
    func displayGroups_搜尋時已選數_包含搜尋隱藏之已選取類別() {
        // Given
        let groups = [
            OrderCategoryGroups.Group(kind: .closed, categories: ["保健", "食品", "書籍", "精品"]),
        ]
        let expansion = OrderCategoryGroups.Expansion(expandedKinds: [.closed])
        let selected: Set<String> = ["食品", "書籍"]

        // When
        let displays = OrderCategoryGroups.displayGroups(
            groups: groups,
            expansion: expansion,
            selected: selected,
            searchText: "食"
        )

        // Then
        #expect(
            displays == [
                OrderCategoryGroups.Display(
                    kind: .closed,
                    visibleCategories: ["食品"],
                    displayedCount: 1,
                    selectedCount: 2,
                    isExpanded: true
                ),
            ]
        )
    }

    /// 驗證組別收合時可見類別為空，顯示數仍為該組的類別總數，已選數照常計入
    @Test
    func displayGroups_組別收合_可見類別為空陣列且顯示數不變() {
        // Given
        let groups = [
            OrderCategoryGroups.Group(kind: .closed, categories: ["保健", "食品", "書籍", "精品"]),
        ]
        let expansion = OrderCategoryGroups.Expansion(expandedKinds: [])

        // When
        let displays = OrderCategoryGroups.displayGroups(
            groups: groups,
            expansion: expansion,
            selected: ["書籍"],
            searchText: ""
        )

        // Then
        #expect(
            displays == [
                OrderCategoryGroups.Display(
                    kind: .closed,
                    visibleCategories: [],
                    displayedCount: 4,
                    selectedCount: 1,
                    isExpanded: false
                ),
            ]
        )
    }

    /// 驗證搜尋中即使儲存的展開狀態為收合，組別仍呈現為展開
    @Test
    func displayGroups_搜尋中呈現一律展開_儲存為收合也展開() {
        // Given
        let groups = [
            OrderCategoryGroups.Group(kind: .closed, categories: ["保健", "食品", "書籍", "精品"]),
        ]
        let expansion = OrderCategoryGroups.Expansion(expandedKinds: [])

        // When
        let displays = OrderCategoryGroups.displayGroups(
            groups: groups,
            expansion: expansion,
            selected: [],
            searchText: "食品"
        )

        // Then
        #expect(displays.first?.isExpanded == true)
    }

    /// 驗證未搜尋時，展開與收合的組別，已選數都等於該組內已選的類別數
    @Test
    func displayGroups_非搜尋情境_已選數等於該組已選類別數() {
        // Given
        let groups = [
            OrderCategoryGroups.Group(kind: .ongoing, categories: ["3C", "美妝", "零食"]),
            OrderCategoryGroups.Group(kind: .closed, categories: ["保健", "食品", "書籍", "精品"]),
        ]
        let selected: Set<String> = ["美妝", "書籍"]
        let expansion = OrderCategoryGroups.Expansion(expandedKinds: [.ongoing])

        // When
        let displays = OrderCategoryGroups.displayGroups(
            groups: groups,
            expansion: expansion,
            selected: selected,
            searchText: ""
        )

        // Then
        #expect(
            displays == [
                OrderCategoryGroups.Display(
                    kind: .ongoing,
                    visibleCategories: ["3C", "美妝", "零食"],
                    displayedCount: 3,
                    selectedCount: 1,
                    isExpanded: true
                ),
                OrderCategoryGroups.Display(
                    kind: .closed,
                    visibleCategories: [],
                    displayedCount: 4,
                    selectedCount: 1,
                    isExpanded: false
                ),
            ]
        )
    }
}
