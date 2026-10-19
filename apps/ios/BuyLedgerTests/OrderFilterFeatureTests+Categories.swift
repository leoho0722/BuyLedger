//
//  OrderFilterFeatureTests+Categories.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension OrderFilterFeatureTests {

    /// 開啟時依目前分組與已選類別計算展開，不替已移除的類別建立組
    ///
    /// - Parameters:
    ///   - selected: 已套用的類別集合
    ///   - expanded: 預期展開的組別集合
    @Test(arguments: Self.initialExpansionCases)
    func init_開啟篩選面板_依分組與已選類別展開(selected: Set<String>, expanded: Set<OrderCategoryGroups.Kind>) {
        // Given
        let selection = OrderFilterSelection(categories: selected)

        // When
        let state = Self.makeGroupedState(selection: selection)

        // Then
        #expect(state.categoryGroupExpansion.expandedKinds == expanded)
        #expect(state.pendingFilterSelection.categories == selected)
        #expect(state.filterSheetSearchText == "")
        #expect(state.isSearchFieldFocused == false)
    }

    /// 沒有進行中開團時自動展開唯一的已收單組
    @Test
    func init_只有已收單類別_展開已收單() {
        // Given
        let categories = ["beauty", "books"]

        // When
        let state = Self.makeState(categories: categories)

        // Then
        #expect(state.categoryGroupExpansion.expandedKinds == [.closed])
    }

    /// 合併主檔與訂單類別，暫存日期與付款方式不影響分組，已選數以暫存為準
    @Test
    func filterSheetCategoryGroups_未搜尋且兩組已選_合併來源並呈現完整分組() {
        // Given
        var state = Self.makeGroupedState()
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

    /// 逐步驗證美妝、書籍、美妝及英文規格序列，也涵蓋移除最後一個類別
    ///
    /// - Parameter testCase: 多選切換的測試案例
    @Test(arguments: Self.categoryToggleCases)
    func filterPendingCategoryToggled_多選序列各步驟_只更新暫存集合(testCase: CategoryToggleCase) async {
        // Given
        var state = Self.makeState(categories: ["美妝", "書籍", "beauty", "books"])
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
        #expect(store.state.hasUnappliedFilterChanges == !testCase.expected.isEmpty)
    }

    /// 全部只清空暫存類別，不改日期、付款方式與已套用值
    @Test
    func filterPendingCategoriesCleared_暫存多類別_清空類別並保留其他條件() async {
        // Given
        var state = Self.makeState(
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

    /// 逐步驗證標題收合與重新展開，只切換指定組且不改選取
    ///
    /// - Parameter testCase: 組別展開切換的測試案例
    @Test(arguments: Self.categoryGroupToggleCases)
    func filterCategoryGroupToggled_收合與展開各步驟_僅切換指定組(testCase: GroupToggleCase) async {
        // Given
        var state = Self.makeGroupedState(selection: OrderFilterSelection(categories: ["書籍"]))
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

    /// 重新建立面板時重算預設展開，不繼承前次操作的收合狀態
    @Test
    func init_前次面板已收合_再次開啟重算展開() {
        // Given
        var previous = Self.makeGroupedState()
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

    /// 兩項類別套用後，清單收到集合並產生本月與兩項類別摘要
    @Test
    func destination_本月與兩項類別_提交集合並更新觸發摘要() async {
        // Given
        var state = OrderListFeatureTests.makeState(orders: [
            OrdersFeatureTests.makeOrder(id: "outside", category: "books"),
            OrdersFeatureTests.makeOrder(id: "beauty", category: "beauty"),
            OrdersFeatureTests.makeOrder(id: "snacks", category: "snacks"),
        ])
        state.selectedDatePeriod = .thisMonth
        state.selectedOrderID = "snacks"
        state.destination = .filterSheet(Self.makeState(for: state))
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
            OrderFilterSelection(datePeriod: .thisMonth, categories: ["beauty", "snacks"])
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

extension OrderFilterFeatureTests {

    /// 多選切換的測試案例
    struct CategoryToggleCase: Sendable {

        /// 切換前的暫存集合
        let initial: Set<String>

        /// 本次切換的目標類別
        let target: String

        /// 切換後的字面值集合
        let expected: Set<String>
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

// MARK: - Internal Method

extension OrderFilterFeatureTests {

    /// 建立規格搜尋範例的兩組類別，包含訂單專用類別與未使用的主檔類別
    ///
    /// - Parameters:
    ///   - selection: 開啟面板時已套用的篩選
    ///   - campaigns: 可選的共用開團引用，省略時使用兩個固定開團
    /// - Returns: 開團中三類與已收單三類的面板狀態
    static func makeGroupedState(
        selection: OrderFilterSelection = OrderFilterSelection(),
        campaigns: SharedReader<[Campaign]>? = nil
    ) -> OrderFilterFeature.State {
        OrderFilterFeature.State(
            orders: SharedReader(value: [
                LedgerOrder.fixture(
                    id: "ongoing",
                    categories: ["美妝", "3C", "零食"],
                    campaignNames: ["春季團"]
                ),
                LedgerOrder.fixture(id: "closed", categories: ["精品", "食品"], campaignNames: ["冬季團"]),
            ]),
            campaigns: campaigns ?? SharedReader(value: [
                Campaign.fixture(id: "spring", name: "春季團", closeDate: TestDependencies.fixedNow),
                Campaign.fixture(id: "winter", name: "冬季團", status: .closed),
            ]),
            lookupCatalog: SharedReader(
                value: LookupCatalog(categories: ["美妝", "零食", "精品", "食品", "書籍"])
            ),
            committedFilterSelection: selection,
            dateContext: OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        )
    }
}

// MARK: - Private Method

private extension OrderFilterFeatureTests {

    /// 開啟面板的已選集合與預期展開
    ///
    /// - Note: 只建立值，不存取測試的主執行緒狀態
    nonisolated static var initialExpansionCases: [(Set<String>, Set<OrderCategoryGroups.Kind>)] {
        [
            ([], [.ongoing]),
            (["書籍"], [.ongoing, .closed]),
            (["已移除"], [.ongoing]),
        ]
    }

    /// 多選切換的前值、操作、後值與未套用變更
    ///
    /// - Note: 只建立值，不存取測試的主執行緒狀態
    nonisolated static var categoryToggleCases: [CategoryToggleCase] {
        [
            CategoryToggleCase(initial: [], target: "美妝", expected: ["美妝"]),
            CategoryToggleCase(initial: ["美妝"], target: "書籍", expected: ["美妝", "書籍"]),
            CategoryToggleCase(initial: ["美妝", "書籍"], target: "美妝", expected: ["書籍"]),
            CategoryToggleCase(initial: [], target: "beauty", expected: ["beauty"]),
            CategoryToggleCase(initial: ["beauty"], target: "books", expected: ["beauty", "books"]),
            CategoryToggleCase(initial: ["beauty", "books"], target: "beauty", expected: ["books"]),
            CategoryToggleCase(initial: ["美妝"], target: "美妝", expected: []),
            CategoryToggleCase(initial: ["beauty"], target: "beauty", expected: []),
        ]
    }

    /// 組別標題切換的原本展開、目標組別與預期展開
    ///
    /// - Note: 只建立值，不存取測試的主執行緒狀態
    nonisolated static var categoryGroupToggleCases: [GroupToggleCase] {
        [
            GroupToggleCase(initial: [.ongoing], kind: .ongoing, expected: []),
            GroupToggleCase(initial: [], kind: .ongoing, expected: [.ongoing]),
            GroupToggleCase(initial: [.ongoing, .closed], kind: .ongoing, expected: [.closed]),
            GroupToggleCase(initial: [.ongoing], kind: .closed, expected: [.ongoing, .closed]),
        ]
    }
}
