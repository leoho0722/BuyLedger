//
//  OrderListFeatureTests+CategoryPicker.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension OrderListFeatureTests {

    /// 日期脈絡未建立時，開啟前補上注入值並複製已套用類別
    @Test
    func categoryPickerTapped_日期脈絡為空_補注入時間並建立目的地() async {
        // Given
        var state = OrderListFeature.State(orders: SharedReader(value: []))
        state.$lookupCatalog = SharedReader(
            value: LookupCatalog(categories: ["beauty", "snacks", "books"])
        )
        state.selectedCategories = ["snacks"]
        let context = OrderDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        var picker = OrderCategoryPickerFeatureTests.makeState(for: state)
        picker.dateContext = context
        picker.pendingCategories = ["snacks"]
        picker.groupExpansion = OrderCategoryGroups.Expansion(expandedKinds: [.closed])

        // When
        await store.send(.view(.categoryPickerTapped)) {
            $0.dateContext = context
            $0.destination = .categoryPicker(picker)
        }

        // Then
        #expect(store.state.dateContext == context)
        #expect(store.state.destination?.categoryPicker?.dateContext == context)
        #expect(store.state.destination?.categoryPicker?.pendingCategories == ["snacks"])
        #expect(store.state.destination?.categoryPicker?.groupExpansion.expandedKinds == [.closed])
        #expect(store.state.destination?.filterSheet == nil)
    }

    /// 類別選擇器與整合篩選共用唯一目的地，開啟前者取代後者
    @Test
    func categoryPickerTapped_篩選面板已開啟_切換為互斥類別目的地() async {
        // Given
        var state = Self.makeState()
        state.selectedCategories = ["beauty"]
        state.destination = .filterSheet(OrderFilterFeatureTests.makeState(for: state))
        var picker = OrderCategoryPickerFeatureTests.makeState(for: state)
        picker.pendingCategories = ["beauty"]
        picker.groupExpansion = OrderCategoryGroups.Expansion(expandedKinds: [])
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.categoryPickerTapped)) {
            $0.destination = .categoryPicker(picker)
        }

        // Then
        #expect(store.state.destination?.filterSheet == nil)
        #expect(store.state.destination?.categoryPicker?.pendingCategories == ["beauty"])
    }

    /// 開啟整合篩選取代類別目的地，不保留兩份呈現狀態
    @Test
    func filterSheetTapped_類別選擇器已開啟_切換為互斥篩選目的地() async {
        // Given
        var state = Self.makeState()
        state.selectedCategories = ["beauty"]
        state.destination = .categoryPicker(OrderCategoryPickerFeatureTests.makeState(for: state))
        var filter = OrderFilterFeatureTests.makeState(for: state)
        filter.pendingFilterSelection = OrderFilterSelection(categories: ["beauty"])
        filter.categoryGroupExpansion = OrderCategoryGroups.Expansion(expandedKinds: [])
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.filterSheetTapped)) {
            $0.destination = .filterSheet(filter)
        }

        // Then
        #expect(store.state.destination?.categoryPicker == nil)
        let categories = store.state.destination?.filterSheet?.pendingFilterSelection.categories
        #expect(categories == ["beauty"])
    }

    /// 再次開啟以目前已套用集合建新草稿，不留下搜尋、焦點或展開操作
    @Test
    func categoryPickerTapped_前次草稿仍在_重建集合搜尋與展開() async {
        // Given
        var state = Self.makeState()
        state.selectedCategories = ["snacks"]
        state.$lookupCatalog = SharedReader(value: LookupCatalog(categories: ["snacks", "books"]))
        var previous = OrderCategoryPickerFeatureTests.makeState(for: state)
        previous.pendingCategories = ["books"]
        previous.searchText = "boo"
        previous.isSearchFieldFocused = true
        previous.groupExpansion.expandedKinds = []
        state.destination = .categoryPicker(previous)
        var picker = OrderCategoryPickerFeatureTests.makeState(for: state)
        picker.pendingCategories = ["snacks"]
        picker.searchText = ""
        picker.isSearchFieldFocused = false
        picker.groupExpansion = OrderCategoryGroups.Expansion(expandedKinds: [.closed])
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.categoryPickerTapped)) {
            $0.destination = .categoryPicker(picker)
        }

        // Then
        #expect(store.state.destination?.categoryPicker?.pendingCategories == ["snacks"])
        #expect(store.state.destination?.categoryPicker?.searchText == "")
        #expect(store.state.destination?.categoryPicker?.isSearchFieldFocused == false)
        #expect(store.state.destination?.categoryPicker?.groupExpansion.expandedKinds == [.closed])
    }
}
