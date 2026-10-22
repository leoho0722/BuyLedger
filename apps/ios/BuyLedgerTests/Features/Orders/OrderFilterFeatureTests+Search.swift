//
//  OrderFilterFeatureTests+Search.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrderFilterFeatureTests {

    /// 搜尋跨兩組與只命中已收單組時，顯示數與含隱藏選取的已選數符合規格
    ///
    /// - Parameters:
    ///   - query: 搜尋文字
    ///   - expected: 字面值的分組顯示資料
    @Test(arguments: Self.categorySearchCases)
    func filterSheetCategoryGroups_搜尋食或品_展開命中組並計入隱藏選取(
        query: String,
        expected: [OrderCategoryGroups.Display]
    ) {
        // Given
        var state = Self.makeGroupedState()
        state.pendingFilterSelection.categories = ["美妝", "食品", "書籍"]
        state.categoryGroupExpansion.expandedKinds = [.ongoing]
        state.filterSheetSearchText = query

        // When
        let groups = state.filterSheetCategoryGroups

        // Then
        #expect(groups == expected)
        #expect(state.pendingFilterSelection.categories == ["美妝", "食品", "書籍"])
        #expect(state.committedFilterSelection.categories == [])
        #expect(state.categoryGroupExpansion.expandedKinds == [.ongoing])
    }

    /// 空白與換行不算搜尋，已收單仍依使用者儲存的狀態收合
    ///
    /// - Parameter query: 只包含空白字元的搜尋文字
    @Test(arguments: Self.whitespaceSearchCases)
    func filterSheetCategoryGroups_搜尋只有空白_保留完整組與原本收合(query: String) {
        // Given
        var state = Self.makeGroupedState()
        state.categoryGroupExpansion.expandedKinds = [.ongoing]
        state.filterSheetSearchText = query

        // When
        let groups = state.filterSheetCategoryGroups

        // Then
        #expect(
            groups == [
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
                    displayedCount: 3,
                    selectedCount: 0,
                    isExpanded: false
                ),
            ]
        )
    }

    /// 無符合的類別時不提供分組資料，保留全部列所需的空集合選取
    @Test
    func filterSheetCategoryGroups_搜尋沒有符合類別_隱藏所有組且不改選取() {
        // Given
        var state = Self.makeState(categories: ["beauty", "snacks"])
        state.filterSheetSearchText = "不存在"

        // When
        let groups = state.filterSheetCategoryGroups

        // Then
        #expect(groups == [])
        #expect(state.pendingFilterSelection.categories == [])
    }

    /// 搜尋期間點標題不改儲存展開，顯示仍由搜尋強制展開
    @Test
    func filterCategoryGroupToggled_搜尋中點已收單標題_保留儲存展開與選取() async {
        // Given
        var state = Self.makeGroupedState(selection: OrderFilterSelection(categories: ["美妝", "書籍"]))
        state.categoryGroupExpansion.expandedKinds = [.ongoing]
        state.filterSheetSearchText = "食"
        let store = TestStore(initialState: state) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterCategoryGroupToggled(.closed)))

        // Then
        #expect(store.state.categoryGroupExpansion.expandedKinds == [.ongoing])
        #expect(
            store.state.filterSheetCategoryGroups.first { $0.kind == .closed }?.isExpanded == true
        )
        #expect(store.state.filterSheetSearchText == "食")
        #expect(store.state.pendingFilterSelection.categories == ["美妝", "書籍"])
    }

    /// return 清除焦點但保留搜尋文字與暫存選取
    @Test
    func filterSearchSubmitted_搜尋欄有焦點_清除焦點並保留文字() async {
        // Given
        var state = Self.makeState()
        state.isSearchFieldFocused = true
        state.filterSheetSearchText = "食"
        state.pendingFilterSelection.categories = ["美妝"]
        let store = TestStore(initialState: state) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterSearchSubmitted)) {
            $0.isSearchFieldFocused = false
        }

        // Then
        #expect(store.state.filterSheetSearchText == "食")
        #expect(store.state.pendingFilterSelection.categories == ["美妝"])
    }

    /// 清除搜尋恢復原本展開，保留搜尋隱藏的類別與輸入焦點
    @Test
    func filterSearchClearTapped_搜尋隱藏已選類別_恢復組並保留選取與焦點() async {
        // Given
        var state = Self.makeGroupedState(selection: OrderFilterSelection(categories: ["美妝", "書籍"]))
        state.categoryGroupExpansion.expandedKinds = [.ongoing]
        state.filterSheetSearchText = "食"
        state.isSearchFieldFocused = true
        let store = TestStore(initialState: state) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterSearchClearTapped)) {
            $0.filterSheetSearchText = ""
        }

        // Then
        #expect(store.state.pendingFilterSelection.categories == ["美妝", "書籍"])
        #expect(store.state.isSearchFieldFocused == true)
        #expect(store.state.categoryGroupExpansion.expandedKinds == [.ongoing])
        #expect(store.state.filterSheetCategoryGroups.map(\.kind) == [.ongoing, .closed])
        #expect(
            store.state.filterSheetCategoryGroups.first { $0.kind == .closed }?.isExpanded == false
        )
    }

    /// 搜尋、焦點與展開是呈現狀態，不參與暫存篩選的比較
    @Test
    func hasUnappliedFilterChanges_只改搜尋焦點與展開_維持未變更() {
        // Given
        var state = Self.makeGroupedState()
        state.filterSheetSearchText = "食"
        state.isSearchFieldFocused = true
        state.categoryGroupExpansion.expandedKinds = [.closed]

        // When
        let hasChanges = state.hasUnappliedFilterChanges

        // Then
        #expect(hasChanges == false)
    }

    /// 日期刷新影響開團是否自動收單，但不重設使用者的展開操作
    @Test
    func filterSheetCategoryGroups_日期跨過結單界線_更新分組並保留展開() {
        // Given
        var state = Self.makeGroupedState()
        state.categoryGroupExpansion.expandedKinds = [.closed]

        // When
        state.dateContext = OrderDateContext(
            now: TestDependencies.fixedNow.addingTimeInterval(86_400),
            calendar: TestDependencies.fixedCalendar
        )
        let groups = state.filterSheetCategoryGroups

        // Then
        #expect(groups.map(\.kind) == [.closed])
        #expect(groups.first?.displayedCount == 6)
        #expect(groups.first?.visibleCategories.count == 6)
        #expect(state.categoryGroupExpansion.expandedKinds == [.closed])
    }

    /// 根功能同步開團引用後，面板重新分組且不重算已儲存展開
    @Test
    func filterSheetCategoryGroups_共用開團更新_讀取最新分組並保留展開() {
        // Given
        let campaigns = Shared<[Campaign]>(value: [
            Campaign.fixture(id: "spring", name: "春季團", closeDate: TestDependencies.fixedNow),
            Campaign.fixture(id: "winter", name: "冬季團", status: .closed),
        ])
        var state = Self.makeGroupedState(campaigns: SharedReader(campaigns))
        state.categoryGroupExpansion.expandedKinds = [.ongoing]

        // When
        campaigns.withLock {
            $0 = []
        }
        let groups = state.filterSheetCategoryGroups

        // Then
        #expect(
            groups == [
                OrderCategoryGroups.Display(
                    kind: .closed,
                    visibleCategories: [],
                    displayedCount: 6,
                    selectedCount: 0,
                    isExpanded: false
                ),
            ]
        )
        #expect(state.categoryGroupExpansion.expandedKinds == [.ongoing])
    }
}

// MARK: - Private Method

private extension OrderFilterFeatureTests {

    /// 搜尋文字與完整的字面值分組預期
    ///
    /// - Note: 只建立值，不存取測試的主執行緒狀態
    nonisolated static var categorySearchCases: [(String, [OrderCategoryGroups.Display])] {
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

    /// 只包含空白字元的搜尋案例
    ///
    /// - Note: 只建立值，不存取測試的主執行緒狀態
    nonisolated static var whitespaceSearchCases: [String] {
        ["   ", " \n\t"]
    }
}
