//
//  OrderCategoryPickerFeatureTests+Groups.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrderCategoryPickerFeatureTests {

    /// 搜尋兩組或只命中已收單時，已選數仍包含隱藏的選取
    ///
    /// - Parameters:
    ///   - query: 搜尋文字
    ///   - expected: 完整顯示分組的字面值預期
    @Test(arguments: Self.searchGroupCases)
    func categoryGroups_搜尋食或品_縮小格子並保留隱藏選取(query: String, expected: [OrderCategoryGroups.Display]) {
        // Given
        var state = Self.makeGroupedState(committed: ["美妝", "食品", "書籍"])
        state.groupExpansion.expandedKinds = [.ongoing]
        state.searchText = query

        // When
        let groups = state.categoryGroups

        // Then
        #expect(groups == expected)
        #expect(state.pendingCategories == ["美妝", "食品", "書籍"])
        #expect(state.committedCategories == ["美妝", "食品", "書籍"])
        #expect(state.groupExpansion.expandedKinds == [.ongoing])
    }

    /// 三個空白不算搜尋，已收單保持使用者儲存的收合
    @Test
    func categoryGroups_搜尋只有空白_保留完整組與收合狀態() {
        // Given
        var state = Self.makeGroupedState(committed: ["美妝", "書籍"])
        state.groupExpansion.expandedKinds = [.ongoing]
        state.searchText = "   "

        // When
        let groups = state.categoryGroups

        // Then
        #expect(
            groups == [
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
                    displayedCount: 3,
                    selectedCount: 1,
                    isExpanded: false
                ),
            ]
        )
    }

    /// 無結果時不回傳組，暫存集合仍供全部列與後續完成使用
    @Test
    func categoryGroups_搜尋沒有結果_隱藏組且保留暫存() {
        // Given
        var state = Self.makeGroupedState(committed: ["美妝", "書籍"])
        state.searchText = "不存在"

        // When
        let groups = state.categoryGroups

        // Then
        #expect(groups == [])
        #expect(state.pendingCategories == ["美妝", "書籍"])
    }

    /// 標題收合與展開的各步驟只更新指定組
    ///
    /// - Parameter testCase: 切換前後與組別的測試案例
    @Test(arguments: Self.groupToggleCases)
    func groupToggled_收合與展開各步驟_只更新指定組(testCase: GroupToggleCase) async {
        // Given
        var state = Self.makeGroupedState(committed: ["美妝", "書籍"])
        state.groupExpansion.expandedKinds = testCase.initial
        let store = TestStore(initialState: state) {
            OrderCategoryPickerFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.groupToggled(testCase.kind))) {
            $0.groupExpansion.expandedKinds = testCase.expected
        }

        // Then
        #expect(store.state.pendingCategories == ["美妝", "書籍"])
        #expect(store.state.hasUnappliedChanges == false)
    }

    /// 搜尋期間點已收單標題不改儲存展開，顯示仍強制展開
    @Test
    func groupToggled_搜尋中點標題_保留儲存展開與選取() async {
        // Given
        var state = Self.makeGroupedState(committed: ["美妝", "書籍"])
        state.groupExpansion.expandedKinds = [.ongoing]
        state.searchText = "食"
        let store = TestStore(initialState: state) {
            OrderCategoryPickerFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.groupToggled(.closed)))

        // Then
        #expect(store.state.groupExpansion.expandedKinds == [.ongoing])
        #expect(store.state.categoryGroups.first { $0.kind == .closed }?.isExpanded == true)
        #expect(store.state.pendingCategories == ["美妝", "書籍"])
        #expect(store.state.searchText == "食")
    }

    /// 日期越過結單界線時重算歸屬，但不重設使用者展開
    @Test
    func categoryGroups_日期跨過結單界線_更新分組並保留展開() {
        // Given
        var state = Self.makeGroupedState()
        state.groupExpansion.expandedKinds = [.closed]

        // When
        state.dateContext = OrderDateContext(
            now: TestDependencies.fixedNow.addingTimeInterval(86_400),
            calendar: TestDependencies.fixedCalendar
        )
        let groups = state.categoryGroups

        // Then
        #expect(groups.map(\.kind) == [.closed])
        #expect(groups.first?.displayedCount == 6)
        #expect(groups.first?.visibleCategories.count == 6)
        #expect(state.groupExpansion.expandedKinds == [.closed])
    }
}

// MARK: - Nested Types

extension OrderCategoryPickerFeatureTests {

    /// 組別展開切換的測試案例
    struct GroupToggleCase: Sendable {

        /// 切換前的展開集合
        let initial: Set<OrderCategoryGroups.Kind>

        /// 本次切換的組別
        let kind: OrderCategoryGroups.Kind

        /// 切換後的字面值集合
        let expected: Set<OrderCategoryGroups.Kind>
    }
}

// MARK: - Private Method

private extension OrderCategoryPickerFeatureTests {

    /// 搜尋命中與整組已選數的規格案例
    ///
    /// - Note: 只建立值，不存取測試的主執行緒狀態
    nonisolated static var searchGroupCases: [(String, [OrderCategoryGroups.Display])] {
        [
            (
                "食",
                [
                    OrderCategoryGroups.Display(
                        kind: .ongoing,
                        visibleCategories: ["零食"],
                        displayedCount: 1,
                        selectedCount: 1,
                        isExpanded: true
                    ),
                    OrderCategoryGroups.Display(
                        kind: .closed,
                        visibleCategories: ["食品"],
                        displayedCount: 1,
                        selectedCount: 2,
                        isExpanded: true
                    ),
                ]
            ),
            (
                "品",
                [
                    OrderCategoryGroups.Display(
                        kind: .closed,
                        visibleCategories: ["食品", "精品"],
                        displayedCount: 2,
                        selectedCount: 2,
                        isExpanded: true
                    ),
                ]
            ),
        ]
    }

    /// 收合、再展開與切換另一組的字面值案例
    ///
    /// - Note: 只建立值，不存取測試的主執行緒狀態
    nonisolated static var groupToggleCases: [GroupToggleCase] {
        [
            GroupToggleCase(initial: [.ongoing], kind: .ongoing, expected: []),
            GroupToggleCase(initial: [], kind: .ongoing, expected: [.ongoing]),
            GroupToggleCase(initial: [.ongoing, .closed], kind: .ongoing, expected: [.closed]),
            GroupToggleCase(initial: [.ongoing], kind: .closed, expected: [.ongoing, .closed]),
        ]
    }
}
