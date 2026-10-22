//
//  OrderCategoryPickerFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 類別選擇器的初始集合、分組與 dirty 規則
@MainActor
struct OrderCategoryPickerFeatureTests {

    /// 依已選類別計算展開，已移除的類別仍保留於暫存
    ///
    /// - Parameters:
    ///   - selected: 已套用的集合
    ///   - expanded: 預期展開的組別
    @Test(arguments: Self.initialCases)
    func init_開啟類別選擇器_複製集合並計算展開(selected: Set<String>, expanded: Set<OrderCategoryGroups.Kind>) {
        // Given
        let selection = selected

        // When
        let state = Self.makeGroupedState(committed: selection)

        // Then
        #expect(state.committedCategories == selection)
        #expect(state.pendingCategories == selection)
        #expect(state.groupExpansion.expandedKinds == expanded)
        #expect(state.searchText == "")
        #expect(state.isSearchFieldFocused == false)
        #expect(state.discardConfirmation == nil)
        #expect(state.hasUnappliedChanges == false)
    }

    /// 規格的 snacks 選取在唯一已收單組內標記，「全部」選項維持未選取
    @Test
    func init_已選零食且沒有開團_展開已收單並標記選取() {
        // Given
        let categories = ["beauty", "snacks", "books"]

        // When
        let state = Self.makeState(categories: categories, committed: ["snacks"])

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

    /// dirty 只比較完整集合，不把呈現欄位加入比較
    ///
    /// - Parameter dirtyCase: 集合差異測試案例
    @Test(arguments: Self.dirtyCases)
    func hasUnappliedChanges_比較暫存與已套用集合_依集合差異判斷(dirtyCase: DirtyCase) {
        // Given
        var state = Self.makeState(committed: dirtyCase.committed)
        state.pendingCategories = dirtyCase.pending

        // When
        let hasUnappliedChanges = state.hasUnappliedChanges

        // Then
        #expect(hasUnappliedChanges == dirtyCase.hasChanges)
    }

    /// 搜尋、焦點與組別展開不構成未套用的使用者資料
    @Test
    func hasUnappliedChanges_只改搜尋焦點與展開_維持未變更() {
        // Given
        var state = Self.makeGroupedState(committed: ["美妝"])
        state.searchText = "食"
        state.isSearchFieldFocused = true
        state.groupExpansion.expandedKinds = [.closed]

        // When
        let hasChanges = state.hasUnappliedChanges

        // Then
        #expect(hasChanges == false)
    }

    /// 重新建立面板時不繼承前次操作留下的收合
    @Test
    func init_前次已收合開團中_再次開啟重算展開() {
        // Given
        var previous = Self.makeGroupedState()
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

    /// 集合差異比對的測試案例
    struct DirtyCase: Sendable {

        /// 已套用集合
        let committed: Set<String>

        /// 暫存集合
        let pending: Set<String>

        /// 字面值的 dirty 預期
        let hasChanges: Bool
    }
}

// MARK: - Internal Method

extension OrderCategoryPickerFeatureTests {

    /// 建立隔離的類別主檔與固定日期，不讀持久化目錄
    ///
    /// - Parameters:
    ///   - categories: 可用類別名稱
    ///   - committed: 已套用類別集合
    /// - Returns: 已建立暫存集合的選擇器
    static func makeState(
        categories: [String] = [],
        committed: Set<String> = []
    ) -> OrderCategoryPickerFeature.State {
        OrderCategoryPickerFeature.State(
            orders: SharedReader(value: []),
            campaigns: SharedReader(value: []),
            lookupCatalog: SharedReader(value: LookupCatalog(categories: categories)),
            committedCategories: committed,
            dateContext: OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        )
    }

    /// 沿用 iPhone 規格的兩組資料，但不使用其結果作為預期
    ///
    /// - Parameter committed: 已套用類別集合
    /// - Returns: 開團中三類、已收單三類的選擇器
    static func makeGroupedState(committed: Set<String> = []) -> OrderCategoryPickerFeature.State {
        let source = OrderFilterFeatureTests.makeGroupedState(
            selection: OrderFilterSelection(categories: committed)
        )
        return OrderCategoryPickerFeature.State(
            orders: source.$orders,
            campaigns: source.$campaigns,
            lookupCatalog: source.$lookupCatalog,
            committedCategories: committed,
            dateContext: source.dateContext
        )
    }

    /// 建立承接清單共用引用與比較基準之選擇器狀態
    ///
    /// - Parameter state: 清單狀態
    /// - Returns: 保留同一份資料引用的選擇器
    /// - Note: 只建立值，不存取測試的主執行緒狀態
    nonisolated static func makeState(
        for state: OrderListFeature.State
    ) -> OrderCategoryPickerFeature.State {
        OrderCategoryPickerFeature.State(
            orders: state.$orders,
            campaigns: state.$campaigns,
            lookupCatalog: state.$lookupCatalog,
            committedCategories: state.selectedCategories,
            dateContext: state.dateContext ?? OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        )
    }

    /// 建立捨棄確認對話方塊之字面值預期
    ///
    /// - Returns: 字面值的確認資料
    static func expectedDiscardAlert() -> AlertState<OrderCategoryPickerFeature.Action.DiscardAlert> {
        AlertState {
            TextState("orders.list.label.discardChanges")
        } actions: {
            ButtonState(role: .destructive, action: .discard) {
                TextState("orders.list.label.discardChanges")
            }
            ButtonState(role: .cancel) {
                TextState("orders.list.label.keepEditing")
            }
        } message: {
            TextState("orders.list.message.filtersHaveApplied")
        }
    }
}

// MARK: - Private Method

private extension OrderCategoryPickerFeatureTests {

    /// 預設、已選已收單與已移除類別的展開案例
    ///
    /// - Note: 只建立值，不存取測試的主執行緒狀態
    nonisolated static var initialCases: [(Set<String>, Set<OrderCategoryGroups.Kind>)] {
        [
            (Set<String>(), [.ongoing]),
            (Set<String>(["美妝", "書籍"]), [.ongoing, .closed]),
            (Set<String>(["已移除"]), [.ongoing]),
        ]
    }

    /// 相等、增加、等量替換、清空與不同順序的集合比較案例
    ///
    /// - Note: 只建立值，不存取測試的主執行緒狀態
    nonisolated static var dirtyCases: [DirtyCase] {
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
