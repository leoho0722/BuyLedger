//
//  OrderCategoryGroupsTests+Display.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import Testing

@testable import BuyLedger

extension OrderCategoryGroupsTests {

    /// 搜尋關鍵字「食」時，兩組皆展開且僅顯示包含「食」的類別
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

    /// 搜尋關鍵字「品」時開團中無相符類別因而隱藏，僅回傳已收單組
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

    /// 搜尋文字僅為純空白時視為未搜尋並保留既有展開與收合狀態
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

    /// 搜尋時已選數計算整組數量，包含因搜尋而隱藏的已選取類別
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

    /// 組別收合時可見類別為空陣列且顯示數維持該組總數不變
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

    /// 搜尋中即使儲存之展開狀態為收合，呈現時仍一律展開
    @Test
    func displayGroups_搜尋中呈現一律展開_不影響傳入之展開狀態() {
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
        #expect(expansion.isExpanded(.closed) == false)
    }

    /// 非搜尋情境下無論收合或展開已選數皆等於該組已選類別數
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
