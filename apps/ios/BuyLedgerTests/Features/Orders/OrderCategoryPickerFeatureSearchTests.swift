//
//  OrderCategoryPickerFeatureSearchTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrderCategoryPickerFeature` 的單元測試，涵蓋搜尋送出、搜尋清除與輸入綁定
@MainActor
struct OrderCategoryPickerFeatureSearchTests {

    /// 驗證搜尋欄有焦點時送出搜尋，焦點收起，搜尋文字與暫存類別都保留不變
    @Test
    func searchSubmitted_搜尋欄有焦點_清焦點並保留文字() async {
        // Given
        var state = OrderCategoryPickerFeatureTestSupport.makeGroupedState(committed: ["美妝", "書籍"])
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

    /// 驗證清除搜尋後兩組都重新顯示，暫存選取、焦點與儲存的展開狀態保留不變，已收單組仍為收合
    @Test
    func searchClearTapped_搜尋隱藏已選類別_還原分組並保留選取() async {
        // Given
        var state = OrderCategoryPickerFeatureTestSupport.makeGroupedState(committed: ["美妝", "書籍"])
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

    /// 驗證輸入搜尋文字的綁定只寫入搜尋欄位，暫存集合與是否有未套用變更都不變
    @Test
    func binding_輸入搜尋文字_保留暫存集合與未變更狀態() {
        // Given
        let store = withDependencies {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        } operation: {
            Store(
                initialState: OrderCategoryPickerFeatureTestSupport.makeState(committed: ["snacks"])
            ) {
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

    /// 驗證同步原生焦點狀態的綁定只更新搜尋欄焦點，暫存集合與是否有未套用變更都不變
    @Test
    func binding_搜尋欄取得焦點_保留選取與未變更狀態() {
        // Given
        let store = withDependencies {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        } operation: {
            Store(
                initialState: OrderCategoryPickerFeatureTestSupport.makeState(committed: ["snacks"])
            ) {
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
