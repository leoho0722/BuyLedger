//
//  OrderListFeatureCategoryPickerSyncTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrderListFeature` 的單元測試，涵蓋類別選擇器與清單之間的狀態同步
struct OrderListFeatureCategoryPickerSyncTests {

    /// 驗證根功能深連結呼叫 `applyFilterNavigation` 時，清單的搜尋文字與類別改為深連結的值，日期重設為全部，付款方式保留，選擇器的比較基準同步更新且草稿保留
    @Test
    func applyFilterNavigation_類別選擇器已開啟_同步基準並保留草稿() {
        // Given
        var state = OrderListFeatureTestSupport.makeState()
        state.selectedDatePeriod = .thisMonth
        state.selectedCategories = ["beauty"]
        state.selectedPaymentMethod = "信用卡"
        var picker = OrderCategoryPickerFeatureTestSupport.makeState(for: state)
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

    /// 驗證已選類別從訂單與主檔都消失時，清單與選擇器都沒有可選類別
    @Test
    func availableCategories_已選類別從資料消失_清單與選擇器均無可選類別() {
        // Given
        let orders = Shared<[LedgerOrder]>(value: [
            OrdersFeatureTestSupport.makeOrder(id: "A", category: "beauty"),
        ])
        var state = OrderListFeature.State(orders: SharedReader(orders))
        state.$lookupCatalog = SharedReader(value: LookupCatalog())
        state.dateContext = OrderDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.selectedCategories = ["beauty"]
        state.destination = .categoryPicker(
            OrderCategoryPickerFeatureTestSupport.makeState(for: state)
        )

        // When
        orders.withLock {
            $0 = []
        }

        // Then
        #expect(state.availableCategories == [])
        #expect(state.destination?.categoryPicker?.categoryGroups == [])
    }

    /// 驗證選擇器共用的主檔改為只有 books 時，分組立即改列 books
    @Test
    func categoryGroups_共用主檔更新_讀到新類別() {
        // Given
        let catalog = Shared<LookupCatalog>(value: LookupCatalog(categories: ["beauty"]))
        var state = OrderListFeatureTestSupport.makeState()
        state.$lookupCatalog = SharedReader(catalog)
        state.selectedCategories = ["beauty"]
        var picker = OrderCategoryPickerFeatureTestSupport.makeState(for: state)
        picker.groupExpansion.expandedKinds = [.closed]
        state.destination = .categoryPicker(picker)

        // When
        catalog.withLock {
            $0.categories = ["books"]
        }
        let groups = state.destination?.categoryPicker?.categoryGroups

        // Then
        #expect(groups?.flatMap(\.visibleCategories) == ["books"])
    }
}
