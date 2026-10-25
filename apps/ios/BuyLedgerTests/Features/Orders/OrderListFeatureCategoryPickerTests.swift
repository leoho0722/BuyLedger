//
//  OrderListFeatureCategoryPickerTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrderListFeature` 的單元測試，以 TestStore 逐步驗證類別選擇器目的地的開啟與互斥行為
@MainActor
struct OrderListFeatureCategoryPickerTests {

    /// 驗證日期脈絡尚未記錄時按下類別，先以注入的時間補上日期脈絡再建立選擇器，選擇器的暫存集合複製已套用的 snacks
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
        var picker = OrderCategoryPickerFeatureTestSupport.makeState(for: state)
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
    }

    /// 驗證篩選面板已開啟時按下類別，選擇器取代篩選面板成為唯一的目的地，暫存集合沿用已套用的 beauty
    @Test
    func categoryPickerTapped_篩選面板已開啟_切換為互斥類別目的地() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState()
        state.selectedCategories = ["beauty"]
        state.destination = .filterSheet(OrderFilterFeatureTestSupport.makeState(for: state))
        var picker = OrderCategoryPickerFeatureTestSupport.makeState(for: state)
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
        #expect(store.state.destination?.categoryPicker?.pendingCategories == ["beauty"])
    }

    /// 驗證類別選擇器已開啟時按下篩選，篩選面板取代選擇器成為唯一的目的地，暫存類別沿用 beauty
    @Test
    func filterSheetTapped_類別選擇器已開啟_切換為互斥篩選目的地() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState()
        state.selectedCategories = ["beauty"]
        state.destination = .categoryPicker(
            OrderCategoryPickerFeatureTestSupport.makeState(for: state)
        )
        var filter = OrderFilterFeatureTestSupport.makeState(for: state)
        filter.pendingFilterSelection = OrderFilterSelection(
            datePeriod: .all,
            categories: ["beauty"],
            paymentMethod: nil
        )
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
        let categories = store.state.destination?.filterSheet?.pendingFilterSelection.categories
        #expect(categories == ["beauty"])
    }

    /// 驗證前次草稿仍存在時再按一次類別，選擇器以目前已套用的 snacks 重建暫存集合，搜尋文字與焦點清空，展開狀態重設
    @Test
    func categoryPickerTapped_前次草稿仍在_重建集合搜尋與展開() async {
        // Given
        var state = OrderListFeatureTestSupport.makeState()
        state.selectedCategories = ["snacks"]
        state.$lookupCatalog = SharedReader(value: LookupCatalog(categories: ["snacks", "books"]))
        var previous = OrderCategoryPickerFeatureTestSupport.makeState(for: state)
        previous.pendingCategories = ["books"]
        previous.searchText = "boo"
        previous.isSearchFieldFocused = true
        previous.groupExpansion.expandedKinds = []
        state.destination = .categoryPicker(previous)
        var picker = OrderCategoryPickerFeatureTestSupport.makeState(for: state)
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
