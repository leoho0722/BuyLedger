//
//  OrderListFeatureTests+CategoryPickerSync.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

extension OrderListFeatureTests {

    /// 經清單繫結變更已套用類別後，同步比較基準但保留草稿與呈現欄位
    @Test
    func binding_選擇器開啟時變更已套用類別_同步基準並保留草稿() {
        // Given
        var state = Self.makeState()
        state.selectedCategories = ["beauty"]
        var picker = OrderCategoryPickerFeatureTests.makeState(for: state)
        picker.pendingCategories = ["beauty", "books"]
        picker.searchText = "草稿"
        picker.groupExpansion.expandedKinds = [.closed]
        state.destination = .categoryPicker(picker)
        let store = withDependencies {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        } operation: {
            Store(initialState: state) {
                OrderListFeature()
            }
        }
        @Bindable var bindable = store

        // When
        $bindable.selectedCategories.wrappedValue = ["books"]

        // Then
        #expect(store.state.destination?.categoryPicker?.committedCategories == ["books"])
        #expect(store.state.destination?.categoryPicker?.pendingCategories == ["beauty", "books"])
        #expect(store.state.destination?.categoryPicker?.searchText == "草稿")
        #expect(store.state.destination?.categoryPicker?.groupExpansion.expandedKinds == [.closed])
        #expect(store.state.destination?.categoryPicker?.hasUnappliedChanges == true)
    }

    /// Root 深連結所用的 State 方法也同步比較基準，保留草稿與付款方式
    @Test
    func applyFilterNavigation_類別選擇器已開啟_同步基準並保留草稿() {
        // Given
        var state = Self.makeState()
        state.selectedDatePeriod = .thisMonth
        state.selectedCategories = ["beauty"]
        state.selectedPaymentMethod = "信用卡"
        var picker = OrderCategoryPickerFeatureTests.makeState(for: state)
        picker.pendingCategories = ["beauty", "books"]
        picker.searchText = "草稿"
        state.destination = .categoryPicker(picker)

        // When
        state.applyFilterNavigation(searchText: "林", category: "books")

        // Then
        #expect(state.searchText == "林")
        #expect(state.selectedDatePeriod == .all)
        #expect(state.selectedPaymentMethod == "信用卡")
        #expect(state.destination?.categoryPicker?.committedCategories == ["books"])
        #expect(state.destination?.categoryPicker?.pendingCategories == ["beauty", "books"])
        #expect(state.destination?.categoryPicker?.searchText == "草稿")
        #expect(state.destination?.categoryPicker?.hasUnappliedChanges == true)
    }

    /// 可用類別全部消失也不暗中清空已套用與暫存集合
    @Test
    func availableCategories_已選類別從資料消失_保留篩選與選擇器集合() {
        // Given
        let orders = Shared<[LedgerOrder]>(value: [
            OrdersFeatureTests.makeOrder(id: "A", category: "beauty"),
        ])
        var state = OrderListFeature.State(orders: SharedReader(orders))
        state.$lookupCatalog = SharedReader(value: LookupCatalog())
        state.dateContext = OrderDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.selectedCategories = ["beauty"]
        state.destination = .categoryPicker(OrderCategoryPickerFeatureTests.makeState(for: state))

        // When
        orders.withLock {
            $0 = []
        }

        // Then
        #expect(state.availableCategories == [])
        #expect(state.selectedCategories == ["beauty"])
        #expect(state.hasCategoryFilter == true)
        #expect(state.filteredOrders == [])
        #expect(state.committedFilterSelection.isActive == true)
        #expect(state.destination?.categoryPicker?.committedCategories == ["beauty"])
        #expect(state.destination?.categoryPicker?.pendingCategories == ["beauty"])
        #expect(state.destination?.categoryPicker?.categoryGroups == [])
    }

    /// 開啟的選擇器沿用主檔引用，後續更新即時反映選項而不改選取
    @Test
    func categoryGroups_共用主檔更新_讀到新類別並保留選取() {
        // Given
        let catalog = Shared<LookupCatalog>(value: LookupCatalog(categories: ["beauty"]))
        var state = Self.makeState()
        state.$lookupCatalog = SharedReader(catalog)
        state.selectedCategories = ["beauty"]
        var picker = OrderCategoryPickerFeatureTests.makeState(for: state)
        picker.groupExpansion.expandedKinds = [.closed]
        state.destination = .categoryPicker(picker)

        // When
        catalog.withLock {
            $0.categories = ["books"]
        }
        let groups = state.destination?.categoryPicker?.categoryGroups

        // Then
        #expect(groups?.flatMap(\.visibleCategories) == ["books"])
        #expect(state.destination?.categoryPicker?.pendingCategories == ["beauty"])
        #expect(state.destination?.categoryPicker?.committedCategories == ["beauty"])
        #expect(state.destination?.categoryPicker?.hasUnappliedChanges == false)
    }
}
