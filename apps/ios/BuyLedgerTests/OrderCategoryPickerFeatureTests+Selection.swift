//
//  OrderCategoryPickerFeatureTests+Selection.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension OrderCategoryPickerFeatureTests {

    /// 多選序列各步驟只改暫存，也涵蓋移除最後一項後恢復乾淨
    ///
    /// - Parameter testCase: 類別切換步驟的測試案例
    @Test(arguments: Self.toggleCases)
    func categoryToggled_多選序列各步驟_只更新暫存集合(testCase: ToggleCase) async {
        // Given
        var state = Self.makeState(categories: ["beauty", "books", "snacks"])
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

    /// 規格的 snacks 已套用時，加選 beauty 不改背後清單的比較基準
    @Test
    func categoryToggled_已套用零食再選美妝_保留已套用集合() async {
        // Given
        let state = Self.makeState(categories: ["beauty", "snacks", "books"], committed: ["snacks"])
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

    /// 全部清空暫存並保留已套用值，等待完成或捨棄
    @Test
    func allTapped_暫存已選兩項_清空暫存且不提交() async {
        // Given
        var state = Self.makeState(committed: ["beauty"])
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

    /// 選回已取消的原類別時，與非空的已套用集合相等而恢復乾淨
    @Test
    func categoryToggled_暫存已取消零食_選回後不再有變更() async {
        // Given
        var state = Self.makeState(committed: ["snacks"])
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

    /// 完成只委派完整集合，提交與關閉由父層處理
    @Test
    func doneTapped_暫存美妝與書籍_委派完整集合() async {
        // Given
        var state = Self.makeState()
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

    /// 沒有暫存變更時完成仍通知父層關閉，集合保持原值
    @Test
    func doneTapped_集合沒有變更_仍委派相同集合() async {
        // Given
        let store = TestStore(initialState: Self.makeState(committed: ["snacks"])) {
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

extension OrderCategoryPickerFeatureTests {

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

private extension OrderCategoryPickerFeatureTests {

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
