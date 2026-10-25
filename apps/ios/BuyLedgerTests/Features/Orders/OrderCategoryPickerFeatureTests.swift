//
//  OrderCategoryPickerFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrderCategoryPickerFeature` 的單元測試，涵蓋初始集合、分組與未套用變更的判定
struct OrderCategoryPickerFeatureTests {

    /// 驗證開啟選擇器時，已套用與暫存集合都複製傳入的已選類別，展開依已選類別計算，已移除的類別仍保留在暫存中
    ///
    /// - Parameter testCase: 已選類別與預期展開的組別
    @Test(arguments: Self.initialCases)
    func init_開啟類別選擇器_複製集合並計算展開(testCase: InitialCase) {
        // Given
        let selection = testCase.selected

        // When
        let state = OrderCategoryPickerFeatureTestSupport.makeGroupedState(committed: selection)

        // Then
        #expect(state.committedCategories == selection)
        #expect(state.pendingCategories == selection)
        #expect(state.groupExpansion.expandedKinds == testCase.expanded)
        #expect(state.searchText == "")
        #expect(state.isSearchFieldFocused == false)
        #expect(state.discardConfirmation == nil)
        #expect(state.hasUnappliedChanges == false)
    }

    /// 驗證已選 snacks 且沒有開團時，唯一的已收單組展開並標記 snacks 為已選，「全部」選項維持未選取
    @Test
    func init_已選零食且沒有開團_展開已收單並標記選取() {
        // Given
        let categories = ["beauty", "snacks", "books"]

        // When
        let state = OrderCategoryPickerFeatureTestSupport.makeState(
            categories: categories,
            committed: ["snacks"]
        )

        // Then
        #expect(state.pendingCategories == ["snacks"])
        #expect(state.pendingCategories.isEmpty == false)
        #expect(
            state.categoryGroups == [
                OrderCategoryGroups.Display(
                    kind: .closed,
                    visibleCategories: ["beauty", "books", "snacks"],
                    displayedCount: 3,
                    selectedCount: 1,
                    isExpanded: true
                ),
            ]
        )
    }

    /// 驗證未套用變更只依暫存與已套用的集合內容判定，順序不同不算變更，增加、替換或清空類別都算變更
    ///
    /// - Parameter dirtyCase: 集合差異測試案例
    @Test(arguments: Self.dirtyCases)
    func hasUnappliedChanges_比較暫存與已套用集合_依集合差異判斷(dirtyCase: DirtyCase) {
        // Given
        var state = OrderCategoryPickerFeatureTestSupport.makeState(committed: dirtyCase.committed)
        state.pendingCategories = dirtyCase.pending

        // When
        let hasUnappliedChanges = state.hasUnappliedChanges

        // Then
        #expect(hasUnappliedChanges == dirtyCase.hasChanges)
    }

    /// 驗證只變更搜尋文字、焦點與組別展開時，不算有未套用變更
    @Test
    func hasUnappliedChanges_只改搜尋焦點與展開_維持未變更() {
        // Given
        var state = OrderCategoryPickerFeatureTestSupport.makeGroupedState(committed: ["美妝"])
        state.searchText = "食"
        state.isSearchFieldFocused = true
        state.groupExpansion.expandedKinds = [.closed]

        // When
        let hasChanges = state.hasUnappliedChanges

        // Then
        #expect(hasChanges == false)
    }

    /// 驗證重新建立選擇器狀態時，不沿用前次收合的開團中組，展開狀態依初始規則重算為開團中展開
    @Test
    func init_前次已收合開團中_再次開啟重算展開() {
        // Given
        var previous = OrderCategoryPickerFeatureTestSupport.makeGroupedState()
        previous.groupExpansion.expandedKinds = []

        // When
        let state = OrderCategoryPickerFeature.State(
            orders: previous.$orders,
            campaigns: previous.$campaigns,
            lookupCatalog: previous.$lookupCatalog,
            committedCategories: previous.committedCategories,
            dateContext: previous.dateContext
        )

        // Then
        #expect(state.groupExpansion.expandedKinds == [.ongoing])
    }
}

// MARK: - Nested Types

extension OrderCategoryPickerFeatureTests {

    /// 初始化測試的單一案例，含已選集合與預期展開的組別
    struct InitialCase: Sendable {

        /// 已套用的集合
        let selected: Set<String>

        /// 預期展開的組別
        let expanded: Set<OrderCategoryGroups.Kind>
    }

    /// 集合差異比對的測試案例
    struct DirtyCase: Sendable {

        /// 已套用集合
        let committed: Set<String>

        /// 暫存集合
        let pending: Set<String>

        /// 是否有未套用變更的字面值預期
        let hasChanges: Bool
    }
}

// MARK: - Private Method

private extension OrderCategoryPickerFeatureTests {

    /// 預設、已選已收單與已移除類別的展開案例
    static var initialCases: [InitialCase] {
        [
            InitialCase(selected: [], expanded: [.ongoing]),
            InitialCase(selected: ["美妝", "書籍"], expanded: [.ongoing, .closed]),
            InitialCase(selected: ["已移除"], expanded: [.ongoing]),
        ]
    }

    /// 相等、增加、等量替換、清空與不同順序的集合比較案例
    static var dirtyCases: [DirtyCase] {
        [
            DirtyCase(committed: [], pending: [], hasChanges: false),
            DirtyCase(committed: ["beauty"], pending: ["beauty"], hasChanges: false),
            DirtyCase(committed: ["beauty"], pending: ["beauty", "books"], hasChanges: true),
            DirtyCase(committed: ["beauty"], pending: ["books"], hasChanges: true),
            DirtyCase(committed: ["beauty"], pending: [], hasChanges: true),
            DirtyCase(
                committed: ["beauty", "books"],
                pending: ["books", "beauty"],
                hasChanges: false
            ),
        ]
    }
}
