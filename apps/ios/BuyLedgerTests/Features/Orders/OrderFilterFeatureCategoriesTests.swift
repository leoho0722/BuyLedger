//
//  OrderFilterFeatureCategoriesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrderFilterFeature` 的單元測試，涵蓋訂單分頁篩選面板的類別分組展開、多選切換與清空
struct OrderFilterFeatureCategoriesTests {

    /// 驗證開啟篩選面板時，依已選類別展開對應的組別，已被移除的類別不會讓已收單組展開
    ///
    /// - Parameter testCase: 測試輸入與字面值預期結果
    @Test(arguments: Self.initialExpansionCases)
    func init_開啟篩選面板_依分組與已選類別展開(testCase: InitialExpansionCase) {
        // Given
        let selection = OrderFilterSelection(categories: testCase.selected)

        // When
        let state = OrderFilterFeatureTestSupport.makeGroupedState(selection: selection)

        // Then
        #expect(state.categoryGroupExpansion.expandedKinds == testCase.expanded)
        #expect(state.pendingFilterSelection.categories == testCase.selected)
        #expect(state.filterSheetSearchText == "")
        #expect(state.isSearchFieldFocused == false)
    }

    /// 驗證類別只屬已收單組時，篩選面板開啟後自動展開該組
    @Test
    func init_只有已收單類別_展開已收單() {
        // Given
        let categories = ["beauty", "books"]

        // When
        let state = OrderFilterFeatureTestSupport.makeState(categories: categories)

        // Then
        #expect(state.categoryGroupExpansion.expandedKinds == [.closed])
    }

    /// 驗證未搜尋且兩組都有已選類別時，分組合併主檔與訂單類別，暫存的日期與付款方式不影響分組，已選數以暫存為準
    @Test
    func filterSheetCategoryGroups_未搜尋且兩組已選_合併來源並呈現完整分組() {
        // Given
        var state = OrderFilterFeatureTestSupport.makeGroupedState()
        state.pendingFilterSelection = OrderFilterSelection(
            datePeriod: .thisMonth,
            categories: ["美妝", "書籍"],
            paymentMethod: "不存在"
        )
        state.categoryGroupExpansion.expandedKinds = [.ongoing, .closed]

        // When
        let groups = state.filterSheetCategoryGroups

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
                    visibleCategories: ["食品", "書籍", "精品"],
                    displayedCount: 3,
                    selectedCount: 1,
                    isExpanded: true
                ),
            ]
        )
    }

    /// 驗證多選切換的每一步只更新暫存集合，已套用的類別不動，移除最後一個類別後不算有未套用的變更
    ///
    /// - Parameter testCase: 多選切換的測試案例
    @Test(arguments: Self.categoryToggleCases)
    @MainActor
    func filterPendingCategoryToggled_多選序列各步驟_只更新暫存集合(testCase: CategoryToggleCase) async {
        // Given
        var state = OrderFilterFeatureTestSupport.makeState(
            categories: ["美妝", "書籍", "beauty", "books"]
        )
        state.pendingFilterSelection.categories = testCase.initial
        state.categoryGroupExpansion.expandedKinds = []
        let store = TestStore(initialState: state) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterPendingCategoryToggled(testCase.target))) {
            $0.pendingFilterSelection.categories = testCase.expected
        }

        // Then
        #expect(store.state.pendingFilterSelection.categories == testCase.expected)
        #expect(store.state.committedFilterSelection.categories == [])
        #expect(store.state.pendingFilterSelection.datePeriod == .all)
        #expect(store.state.pendingFilterSelection.paymentMethod == nil)
        #expect(store.state.hasUnappliedFilterChanges == testCase.hasUnappliedChanges)
    }

    /// 驗證清空類別時只清除暫存的全部類別，暫存的日期與付款方式、已套用的類別都保留
    @Test
    @MainActor
    func filterPendingCategoriesCleared_暫存多類別_清空類別並保留其他條件() async {
        // Given
        var state = OrderFilterFeatureTestSupport.makeState(
            categories: ["beauty", "books"],
            committedFilterSelection: OrderFilterSelection(categories: ["beauty"])
        )
        state.pendingFilterSelection = OrderFilterSelection(
            datePeriod: .thisMonth,
            categories: ["beauty", "books"],
            paymentMethod: "轉帳"
        )
        state.categoryGroupExpansion.expandedKinds = []
        let store = TestStore(initialState: state) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterPendingCategoriesCleared)) {
            $0.pendingFilterSelection.categories = []
        }

        // Then
        #expect(store.state.pendingFilterSelection.categories == [])
        #expect(store.state.pendingFilterSelection.datePeriod == .thisMonth)
        #expect(store.state.pendingFilterSelection.paymentMethod == "轉帳")
        #expect(store.state.committedFilterSelection.categories == ["beauty"])
    }

    /// 驗證點選組別標題時，只切換該組的收合與展開，類別選取與未套用狀態都不變
    ///
    /// - Parameter testCase: 組別展開切換的測試案例
    @Test(arguments: Self.categoryGroupToggleCases)
    @MainActor
    func filterCategoryGroupToggled_收合與展開各步驟_僅切換指定組(testCase: GroupToggleCase) async {
        // Given
        var state = OrderFilterFeatureTestSupport.makeGroupedState(
            selection: OrderFilterSelection(categories: ["書籍"])
        )
        state.categoryGroupExpansion.expandedKinds = testCase.initial
        let store = TestStore(initialState: state) {
            OrderFilterFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterCategoryGroupToggled(testCase.kind))) {
            $0.categoryGroupExpansion.expandedKinds = testCase.expected
        }

        // Then
        #expect(store.state.categoryGroupExpansion.expandedKinds == testCase.expected)
        #expect(store.state.pendingFilterSelection.categories == ["書籍"])
        #expect(store.state.hasUnappliedFilterChanges == false)
    }

    /// 驗證重新開啟面板時重算預設展開，不沿用前次收合的組別
    @Test
    func init_前次面板已收合_再次開啟重算展開() {
        // Given
        var previous = OrderFilterFeatureTestSupport.makeGroupedState()
        previous.categoryGroupExpansion.expandedKinds = []

        // When
        let reopened = OrderFilterFeature.State(
            orders: previous.$orders,
            campaigns: previous.$campaigns,
            lookupCatalog: previous.$lookupCatalog,
            committedFilterSelection: previous.committedFilterSelection,
            dateContext: previous.dateContext
        )

        // Then
        #expect(reopened.categoryGroupExpansion.expandedKinds == [.ongoing])
    }

    /// 驗證套用本月與兩項類別後，清單收到該篩選集合、選取改為 beauty 訂單、篩選摘要顯示「本月 · 2 項類別」，且面板關閉
    @Test
    @MainActor
    func destination_本月與兩項類別_提交集合並更新觸發摘要() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState(orders: [
            OrdersFeatureTestSupport.makeOrder(id: "outside", category: "books"),
            OrdersFeatureTestSupport.makeOrder(id: "beauty", category: "beauty"),
            OrdersFeatureTestSupport.makeOrder(id: "snacks", category: "snacks"),
        ])
        state.selectedDatePeriod = .thisMonth
        state.selectedOrderID = "snacks"
        state.destination = .filterSheet(OrderFilterFeatureTestSupport.makeState(for: state))
        state.destination?.modify(\.filterSheet) {
            $0.pendingFilterSelection = OrderFilterSelection(
                datePeriod: .thisMonth,
                categories: ["beauty", "snacks"],
                paymentMethod: nil
            )
        }
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.destination(.presented(.filterSheet(.view(.filterApplyTapped)))))

        // Then
        await store.receive(
            \.destination.presented.filterSheet.delegate.applied,
            OrderFilterSelection(
                datePeriod: .thisMonth,
                categories: ["beauty", "snacks"],
                paymentMethod: nil
            )
        ) {
            $0.selectedDatePeriod = .thisMonth
            $0.selectedCategories = ["beauty", "snacks"]
            $0.selectedOrderID = "beauty"
            $0.destination = nil
        }
        await store.receive(\.delegate.selectionChanged, "beauty")
        #expect(store.state.filterSummary(language: .traditionalChinese) == "本月 · 2 項類別")
        #expect(store.state.destination == nil)
    }
}

// MARK: - Nested Types

extension OrderFilterFeatureCategoriesTests {

    /// 開啟篩選面板的已選類別與預期展開
    struct InitialExpansionCase: Sendable {

        /// 已套用的類別集合
        let selected: Set<String>

        /// 預期展開的組別集合
        let expanded: Set<OrderCategoryGroups.Kind>
    }

    /// 多選切換的測試案例
    struct CategoryToggleCase: Sendable {

        /// 切換前的暫存集合
        let initial: Set<String>

        /// 本次切換的目標類別
        let target: String

        /// 切換後的字面值集合
        let expected: Set<String>

        /// 切換後是否有尚未套用的類別變更
        let hasUnappliedChanges: Bool
    }

    /// 組別展開切換的測試案例
    struct GroupToggleCase: Sendable {

        /// 原本展開的組別
        let initial: Set<OrderCategoryGroups.Kind>

        /// 本次切換的組別
        let kind: OrderCategoryGroups.Kind

        /// 切換後應展開的組別
        let expected: Set<OrderCategoryGroups.Kind>
    }
}

// MARK: - Private Method

private extension OrderFilterFeatureCategoriesTests {

    /// 開啟面板的已選集合與預期展開
    static var initialExpansionCases: [InitialExpansionCase] {
        [
            InitialExpansionCase(selected: [], expanded: [.ongoing]),
            InitialExpansionCase(selected: ["書籍"], expanded: [.ongoing, .closed]),
            InitialExpansionCase(selected: ["已移除"], expanded: [.ongoing]),
        ]
    }

    /// 多選切換的前值、操作、後值與未套用變更
    static var categoryToggleCases: [CategoryToggleCase] {
        [
            CategoryToggleCase(
                initial: [],
                target: "美妝",
                expected: ["美妝"],
                hasUnappliedChanges: true
            ),
            CategoryToggleCase(
                initial: ["美妝"],
                target: "書籍",
                expected: ["美妝", "書籍"],
                hasUnappliedChanges: true
            ),
            CategoryToggleCase(
                initial: ["美妝", "書籍"],
                target: "美妝",
                expected: ["書籍"],
                hasUnappliedChanges: true
            ),
            CategoryToggleCase(
                initial: [],
                target: "beauty",
                expected: ["beauty"],
                hasUnappliedChanges: true
            ),
            CategoryToggleCase(
                initial: ["beauty"],
                target: "books",
                expected: ["beauty", "books"],
                hasUnappliedChanges: true
            ),
            CategoryToggleCase(
                initial: ["beauty", "books"],
                target: "beauty",
                expected: ["books"],
                hasUnappliedChanges: true
            ),
            CategoryToggleCase(
                initial: ["美妝"],
                target: "美妝",
                expected: [],
                hasUnappliedChanges: false
            ),
            CategoryToggleCase(
                initial: ["beauty"],
                target: "beauty",
                expected: [],
                hasUnappliedChanges: false
            ),
        ]
    }

    /// 組別標題切換的原本展開、目標組別與預期展開
    static var categoryGroupToggleCases: [GroupToggleCase] {
        [
            GroupToggleCase(initial: [.ongoing], kind: .ongoing, expected: []),
            GroupToggleCase(initial: [], kind: .ongoing, expected: [.ongoing]),
            GroupToggleCase(initial: [.ongoing, .closed], kind: .ongoing, expected: [.closed]),
            GroupToggleCase(initial: [.ongoing], kind: .closed, expected: [.ongoing, .closed]),
        ]
    }
}
