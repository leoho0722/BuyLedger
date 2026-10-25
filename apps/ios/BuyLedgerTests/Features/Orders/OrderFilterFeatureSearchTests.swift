//
//  OrderFilterFeatureSearchTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderFilterFeature` 的單元測試，涵蓋類別搜尋、收合狀態與搜尋焦點管理
struct OrderFilterFeatureSearchTests {

    /// 驗證搜尋文字命中不同收單組時，命中的組都展開，已選數連同被搜尋隱藏的選取一併計入
    ///
    /// - Parameter testCase: 搜尋文字與預期的分組顯示資料
    @Test(arguments: Self.categorySearchCases)
    func filterSheetCategoryGroups_搜尋食或品_展開命中組並計入隱藏選取(testCase: CategorySearchCase) {
        // Given
        var state = OrderFilterFeatureTestSupport.makeGroupedState()
        state.pendingFilterSelection.categories = ["美妝", "食品", "書籍"]
        state.categoryGroupExpansion.expandedKinds = [.ongoing]
        state.filterSheetSearchText = testCase.query

        // When
        let groups = state.filterSheetCategoryGroups

        // Then
        #expect(groups == testCase.expected)
    }

    /// 驗證搜尋文字只有空白字元時視為沒有搜尋，開團中組展開並列出完整類別，已收單組依儲存的設定維持收合，不列類別但顯示數仍為 3
    ///
    /// - Parameter query: 只包含空白字元的搜尋文字
    @Test(arguments: Self.whitespaceSearchCases)
    func filterSheetCategoryGroups_搜尋只有空白_保留完整組與原本收合(query: String) {
        // Given
        var state = OrderFilterFeatureTestSupport.makeGroupedState()
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

    /// 驗證搜尋文字沒有命中任何類別時，分組結果為空，不列出任何組
    @Test
    func filterSheetCategoryGroups_搜尋沒有符合類別_隱藏所有組() {
        // Given
        var state = OrderFilterFeatureTestSupport.makeState(categories: ["beauty", "snacks"])
        state.filterSheetSearchText = "不存在"

        // When
        let groups = state.filterSheetCategoryGroups

        // Then
        #expect(groups == [])
    }

    /// 驗證搜尋中點擊已收單組的標題時，儲存的展開狀態不變，該組仍因搜尋而顯示展開，搜尋文字與暫存選取也都保留
    @Test
    @MainActor
    func filterCategoryGroupToggled_搜尋中點已收單標題_保留儲存展開與選取() async {
        // Given
        var state = OrderFilterFeatureTestSupport.makeGroupedState(
            selection: OrderFilterSelection(
                datePeriod: .all,
                categories: ["美妝", "書籍"],
                paymentMethod: nil
            )
        )
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

    /// 驗證搜尋欄有焦點時按下 return，只收起焦點，搜尋文字與暫存選取都保留
    @Test
    @MainActor
    func filterSearchSubmitted_搜尋欄有焦點_清除焦點並保留文字() async {
        // Given
        var state = OrderFilterFeatureTestSupport.makeState()
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

    /// 驗證清除搜尋文字後，原本因搜尋而展開的已收單組恢復為儲存的收合狀態，暫存選取與搜尋欄焦點都保留
    @Test
    @MainActor
    func filterSearchClearTapped_搜尋隱藏已選類別_恢復組並保留選取與焦點() async {
        // Given
        var state = OrderFilterFeatureTestSupport.makeGroupedState(
            selection: OrderFilterSelection(
                datePeriod: .all,
                categories: ["美妝", "書籍"],
                paymentMethod: nil
            )
        )
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

    /// 驗證只改搜尋文字、搜尋焦點與收合展開時，暫存篩選不算未套用變更，因為這些只影響呈現
    @Test
    func hasUnappliedFilterChanges_只改搜尋焦點與展開_維持未變更() {
        // Given
        var state = OrderFilterFeatureTestSupport.makeGroupedState()
        state.filterSheetSearchText = "食"
        state.isSearchFieldFocused = true
        state.categoryGroupExpansion.expandedKinds = [.closed]

        // When
        let hasChanges = state.hasUnappliedFilterChanges

        // Then
        #expect(hasChanges == false)
    }

    /// 驗證日期前進過春季團的結單時間後，只剩已收單組並顯示全部 6 個類別
    @Test
    func filterSheetCategoryGroups_日期跨過結單界線_已收單組顯示全部類別() {
        // Given
        var state = OrderFilterFeatureTestSupport.makeGroupedState()
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
    }

    /// 驗證共用開團清空後，面板改讀最新的分組，只剩已收單組且維持收合，顯示數為 6
    @Test
    func filterSheetCategoryGroups_共用開團更新_讀取最新分組並保留展開() {
        // Given
        let campaigns = Shared<[Campaign]>(value: [
            Campaign.fixture(id: "spring", name: "春季團", closeDate: TestDependencies.fixedNow),
            Campaign.fixture(id: "winter", name: "冬季團", status: .closed),
        ])
        var state = OrderFilterFeatureTestSupport.makeGroupedState(
            campaigns: SharedReader(campaigns)
        )
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
    }
}

// MARK: - Nested Types

extension OrderFilterFeatureSearchTests {

    /// 跨組類別搜尋案例，含搜尋文字與完整的分組顯示預期
    struct CategorySearchCase: Sendable {

        /// 搜尋文字
        let query: String

        /// 字面值的分組顯示資料
        let expected: [OrderCategoryGroups.Display]
    }
}

// MARK: - Private Method

private extension OrderFilterFeatureSearchTests {

    /// 搜尋文字與完整的字面值分組預期
    static var categorySearchCases: [CategorySearchCase] {
        [
            CategorySearchCase(
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
            CategorySearchCase(
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

    /// 只包含空白字元的搜尋案例
    static var whitespaceSearchCases: [String] {
        ["   ", " \n\t"]
    }
}
