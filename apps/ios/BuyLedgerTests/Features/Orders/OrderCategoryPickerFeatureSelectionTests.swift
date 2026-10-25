//
//  OrderCategoryPickerFeatureSelectionTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrderCategoryPickerFeature` 的單元測試，涵蓋類別切換、「全部」清空與完成
@MainActor
struct OrderCategoryPickerFeatureSelectionTests {

    /// 驗證依序切換多個類別時，每一步只更新暫存集合，移除到與已套用相同時不再有未套用變更
    ///
    /// - Parameter testCase: 類別切換步驟的測試案例
    @Test(arguments: Self.toggleCases)
    func categoryToggled_多選序列各步驟_只更新暫存集合(testCase: ToggleCase) async {
        // Given
        var state = OrderCategoryPickerFeatureTestSupport.makeState(
            categories: ["beauty", "books", "snacks"]
        )
        state.pendingCategories = testCase.initial
        let store = TestStore(initialState: state) {
            OrderCategoryPickerFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.categoryToggled(testCase.category))) {
            $0.pendingCategories = testCase.expected
        }

        // Then
        #expect(store.state.pendingCategories == testCase.expected)
        #expect(store.state.committedCategories == [])
        #expect(store.state.hasUnappliedChanges == testCase.hasChanges)
    }

    /// 驗證已套用 snacks 時加選 beauty，暫存集合加入 beauty，已套用集合仍只有 snacks，並標記有未套用變更
    @Test
    func categoryToggled_已套用零食再選美妝_保留已套用集合() async {
        // Given
        let state = OrderCategoryPickerFeatureTestSupport.makeState(
            categories: ["beauty", "snacks", "books"],
            committed: ["snacks"]
        )
        let store = TestStore(initialState: state) {
            OrderCategoryPickerFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.categoryToggled("beauty"))) {
            $0.pendingCategories = ["snacks", "beauty"]
        }

        // Then
        #expect(store.state.committedCategories == ["snacks"])
        #expect(store.state.hasUnappliedChanges == true)
    }

    /// 驗證按下「全部」只清空暫存集合，已套用類別、搜尋、焦點與展開狀態都保留，不提交，待完成或捨棄
    @Test
    func allTapped_暫存已選兩項_清空暫存且不提交() async {
        // Given
        var state = OrderCategoryPickerFeatureTestSupport.makeState(committed: ["beauty"])
        state.pendingCategories = ["beauty", "books"]
        state.searchText = "boo"
        state.isSearchFieldFocused = true
        state.groupExpansion.expandedKinds = [.closed]
        let store = TestStore(initialState: state) {
            OrderCategoryPickerFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.allTapped)) {
            $0.pendingCategories = []
        }

        // Then
        #expect(store.state.pendingCategories == [])
        #expect(store.state.committedCategories == ["beauty"])
        #expect(store.state.hasUnappliedChanges == true)
        #expect(store.state.searchText == "boo")
        #expect(store.state.isSearchFieldFocused == true)
        #expect(store.state.groupExpansion.expandedKinds == [.closed])
    }

    /// 驗證暫存已取消 snacks 後再選回，暫存與已套用集合相同，不再有未套用變更，也不跳出捨棄確認
    @Test
    func categoryToggled_暫存已取消零食_選回後不再有變更() async {
        // Given
        var state = OrderCategoryPickerFeatureTestSupport.makeState(committed: ["snacks"])
        state.pendingCategories = []
        let store = TestStore(initialState: state) {
            OrderCategoryPickerFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.categoryToggled("snacks"))) {
            $0.pendingCategories = ["snacks"]
        }

        // Then
        #expect(store.state.committedCategories == ["snacks"])
        #expect(store.state.hasUnappliedChanges == false)
        #expect(store.state.discardConfirmation == nil)
    }

    /// 驗證按下完成時，送出套用通知並帶上完整的暫存集合，已套用集合與暫存都不改
    @Test
    func doneTapped_暫存美妝與書籍_委派完整集合() async {
        // Given
        var state = OrderCategoryPickerFeatureTestSupport.makeState()
        state.pendingCategories = ["beauty", "books"]
        let store = TestStore(initialState: state) {
            OrderCategoryPickerFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.doneTapped))

        // Then
        await store.receive(\.delegate.applied, Set<String>(["beauty", "books"]))
        #expect(store.state.committedCategories == [])
        #expect(store.state.pendingCategories == ["beauty", "books"])
    }

    /// 驗證沒有暫存變更時按下完成，仍送出帶相同集合的套用通知，已套用與暫存都不變
    @Test
    func doneTapped_集合沒有變更_仍委派相同集合() async {
        // Given
        let store = TestStore(
            initialState: OrderCategoryPickerFeatureTestSupport.makeState(committed: ["snacks"])
        ) {
            OrderCategoryPickerFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.doneTapped))

        // Then
        await store.receive(\.delegate.applied, Set<String>(["snacks"]))
        #expect(store.state.pendingCategories == ["snacks"])
        #expect(store.state.committedCategories == ["snacks"])
    }
}

// MARK: - Nested Types

extension OrderCategoryPickerFeatureSelectionTests {

    /// 類別切換步驟的測試案例
    struct ToggleCase: Sendable {

        /// 切換前的集合
        let initial: Set<String>

        /// 要切換的類別
        let category: String

        /// 切換後的字面值集合
        let expected: Set<String>

        /// 是否仍有未套用變更
        let hasChanges: Bool
    }
}

// MARK: - Private Method

private extension OrderCategoryPickerFeatureSelectionTests {

    /// beauty、books、beauty 序列與最後一項移除的字面值案例
    ///
    /// - Note: 只建立值，不存取測試的主執行緒狀態
    nonisolated static var toggleCases: [ToggleCase] {
        [
            ToggleCase(
                initial: [],
                category: "beauty",
                expected: ["beauty"],
                hasChanges: true
            ),
            ToggleCase(
                initial: ["beauty"],
                category: "books",
                expected: ["beauty", "books"],
                hasChanges: true
            ),
            ToggleCase(
                initial: ["beauty", "books"],
                category: "beauty",
                expected: ["books"],
                hasChanges: true
            ),
            ToggleCase(
                initial: ["beauty"],
                category: "beauty",
                expected: [],
                hasChanges: false
            ),
        ]
    }
}
