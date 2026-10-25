//
//  OrderCategoryPickerFeatureGroupsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderCategoryPickerFeature` 的單元測試，涵蓋類別分組計算、搜尋縮小與展開收合切換
struct OrderCategoryPickerFeatureGroupsTests {

    /// 驗證搜尋同時命中兩組或只命中已收單組時，只顯示相符的類別，已選數仍計入被搜尋隱藏的已選類別
    ///
    /// - Parameter testCase: 搜尋文字與完整顯示分組的預期
    @Test(arguments: Self.searchGroupCases)
    func categoryGroups_搜尋食或品_縮小格子並保留隱藏選取(testCase: SearchGroupCase) {
        // Given
        var state = OrderCategoryPickerFeatureTestSupport.makeGroupedState(
            committed: ["美妝", "食品", "書籍"]
        )
        state.groupExpansion.expandedKinds = [.ongoing]
        state.searchText = testCase.query

        // When
        let groups = state.categoryGroups

        // Then
        #expect(groups == testCase.expected)
    }

    /// 驗證三個空白的搜尋文字不算搜尋，開團中組完整顯示，已收單組保持使用者儲存的收合狀態
    @Test
    func categoryGroups_搜尋只有空白_保留完整組與收合狀態() {
        // Given
        var state = OrderCategoryPickerFeatureTestSupport.makeGroupedState(committed: ["美妝", "書籍"])
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

    /// 驗證搜尋沒有相符類別時，兩組都不回傳
    @Test
    func categoryGroups_搜尋沒有結果_隱藏所有分組() {
        // Given
        var state = OrderCategoryPickerFeatureTestSupport.makeGroupedState(committed: ["美妝", "書籍"])
        state.searchText = "不存在"

        // When
        let groups = state.categoryGroups

        // Then
        #expect(groups == [])
    }

    /// 驗證點選組別標題時，只切換該組的展開狀態，待套用的類別與未變更狀態都不受影響
    ///
    /// - Parameter testCase: 切換前後與組別的測試案例
    @Test(arguments: Self.groupToggleCases)
    @MainActor
    func groupToggled_收合與展開各步驟_只更新指定組(testCase: GroupToggleCase) async {
        // Given
        var state = OrderCategoryPickerFeatureTestSupport.makeGroupedState(committed: ["美妝", "書籍"])
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

    /// 驗證搜尋中點擊已收單標題時，儲存的展開狀態與暫存選取都不變，該組仍因搜尋而呈現為展開
    @Test
    @MainActor
    func groupToggled_搜尋中點標題_保留儲存展開與選取() async {
        // Given
        var state = OrderCategoryPickerFeatureTestSupport.makeGroupedState(committed: ["美妝", "書籍"])
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

    /// 驗證日期跨過結單界線後，所有類別都歸入已收單組，並依儲存的展開設定顯示全部六個類別
    @Test
    func categoryGroups_日期跨過結單界線_全部歸入已收單並展開() {
        // Given
        var state = OrderCategoryPickerFeatureTestSupport.makeGroupedState()
        state.groupExpansion.expandedKinds = [.closed]
        state.dateContext = OrderDateContext(
            now: TestDependencies.fixedNow.addingTimeInterval(86_400),
            calendar: TestDependencies.fixedCalendar
        )

        // When
        let groups = state.categoryGroups

        // Then
        #expect(groups.map(\.kind) == [.closed])
        #expect(groups.first?.displayedCount == 6)
        #expect(groups.first?.visibleCategories.count == 6)
    }
}

// MARK: - Nested Types

extension OrderCategoryPickerFeatureGroupsTests {

    /// 分組搜尋測試的單一案例，含搜尋文字與完整的預期分組
    struct SearchGroupCase: Sendable {

        /// 搜尋文字
        let query: String

        /// 完整顯示分組的字面值預期
        let expected: [OrderCategoryGroups.Display]
    }

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

private extension OrderCategoryPickerFeatureGroupsTests {

    /// 搜尋命中與整組已選數的規格案例
    static var searchGroupCases: [SearchGroupCase] {
        [
            SearchGroupCase(
                query: "食",
                expected: [
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
            SearchGroupCase(
                query: "品",
                expected: [
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
    static var groupToggleCases: [GroupToggleCase] {
        [
            GroupToggleCase(initial: [.ongoing], kind: .ongoing, expected: []),
            GroupToggleCase(initial: [], kind: .ongoing, expected: [.ongoing]),
            GroupToggleCase(initial: [.ongoing, .closed], kind: .ongoing, expected: [.closed]),
            GroupToggleCase(initial: [.ongoing], kind: .closed, expected: [.ongoing, .closed]),
        ]
    }
}
