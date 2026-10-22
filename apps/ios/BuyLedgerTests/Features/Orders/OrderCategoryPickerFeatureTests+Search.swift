//
//  OrderCategoryPickerFeatureTests+Search.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension OrderCategoryPickerFeatureTests {

    /// return 清除焦點，保留搜尋與暫存類別
    @Test
    func searchSubmitted_搜尋欄有焦點_清焦點並保留文字() async {
        // Given
        var state = Self.makeGroupedState(committed: ["美妝", "書籍"])
        state.searchText = "食"
        state.isSearchFieldFocused = true
        let store = TestStore(initialState: state) {
            OrderCategoryPickerFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.searchSubmitted)) {
            $0.isSearchFieldFocused = false
        }

        // Then
        #expect(store.state.searchText == "食")
        #expect(store.state.pendingCategories == ["美妝", "書籍"])
    }

    /// 清除搜尋顯示所有組，保留隱藏選取、輸入焦點與儲存展開
    @Test
    func searchClearTapped_搜尋隱藏已選類別_還原分組並保留選取() async {
        // Given
        var state = Self.makeGroupedState(committed: ["美妝", "書籍"])
        state.groupExpansion.expandedKinds = [.ongoing]
        state.searchText = "食"
        state.isSearchFieldFocused = true
        let store = TestStore(initialState: state) {
            OrderCategoryPickerFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.searchClearTapped)) {
            $0.searchText = ""
        }

        // Then
        #expect(store.state.pendingCategories == ["美妝", "書籍"])
        #expect(store.state.isSearchFieldFocused == true)
        #expect(store.state.groupExpansion.expandedKinds == [.ongoing])
        #expect(store.state.categoryGroups.map(\.kind) == [.ongoing, .closed])
        #expect(store.state.categoryGroups.first { $0.kind == .closed }?.isExpanded == false)
    }

    /// 搜尋實際繫結只寫入呈現欄位，不改選取或 dirty
    @Test
    func binding_輸入搜尋文字_保留暫存集合與未變更狀態() {
        // Given
        let store = withDependencies {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        } operation: {
            Store(initialState: Self.makeState(committed: ["snacks"])) {
                OrderCategoryPickerFeature()
            }
        }
        @Bindable var bindable = store

        // When
        $bindable.searchText.wrappedValue = "boo"

        // Then
        #expect(store.state.searchText == "boo")
        #expect(store.state.pendingCategories == ["snacks"])
        #expect(store.state.committedCategories == ["snacks"])
        #expect(store.state.hasUnappliedChanges == false)
    }

    /// 原生焦點鏡像使用的繫結只更新焦點，不構成 dirty
    @Test
    func binding_搜尋欄取得焦點_保留選取與未變更狀態() {
        // Given
        let store = withDependencies {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        } operation: {
            Store(initialState: Self.makeState(committed: ["snacks"])) {
                OrderCategoryPickerFeature()
            }
        }
        @Bindable var bindable = store

        // When
        $bindable.isSearchFieldFocused.wrappedValue = true

        // Then
        #expect(store.state.isSearchFieldFocused == true)
        #expect(store.state.pendingCategories == ["snacks"])
        #expect(store.state.hasUnappliedChanges == false)
    }
}
