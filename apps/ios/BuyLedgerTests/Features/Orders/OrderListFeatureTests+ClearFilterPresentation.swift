//
//  OrderListFeatureTests+ClearFilterPresentation.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension OrderListFeatureTests {

    /// 清除已套用值也同步整合篩選的比較基準，草稿與呈現欄位保留
    @Test
    func clearFiltersTapped_整合篩選已開啟_同步基準並保留草稿() async {
        // Given
        var state = Self.makeClearFiltersState()
        var sheet = OrderFilterFeatureTests.makeState(for: state)
        sheet.pendingFilterSelection = OrderFilterSelection(
            datePeriod: .lastMonth,
            categories: ["未套用"],
            paymentMethod: "轉帳"
        )
        sheet.filterSheetSearchText = "草稿"
        sheet.isSearchFieldFocused = true
        sheet.categoryGroupExpansion.expandedKinds = [.closed]
        state.destination = .filterSheet(sheet)
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.clearFiltersTapped)) {
            $0.selectedDatePeriod = .all
            $0.selectedCategories = []
            $0.selectedPaymentMethod = nil
            $0.selectedOrderID = "restored"
            $0.destination?.modify(\.filterSheet) {
                $0.committedFilterSelection = OrderFilterSelection(
                    datePeriod: .all,
                    categories: [],
                    paymentMethod: nil
                )
            }
        }

        // Then
        await store.receive(\.delegate.selectionChanged, "restored")
        let pending = store.state.destination?.filterSheet?.pendingFilterSelection
        #expect(
            pending == OrderFilterSelection(
                datePeriod: .lastMonth,
                categories: ["未套用"],
                paymentMethod: "轉帳"
            )
        )
        #expect(store.state.destination?.filterSheet?.filterSheetSearchText == "草稿")
        #expect(store.state.destination?.filterSheet?.isSearchFieldFocused == true)
        #expect(
            store.state.destination?.filterSheet?.categoryGroupExpansion.expandedKinds
                == [.closed]
        )
    }

    /// 清除已套用類別時同步選擇器基準，不覆寫尚未完成的暫存與搜尋
    @Test
    func clearFiltersTapped_類別選擇器已開啟_同步基準並保留草稿() async {
        // Given
        var state = Self.makeClearFiltersState()
        var picker = OrderCategoryPickerFeatureTests.makeState(for: state)
        picker.pendingCategories = ["未套用"]
        picker.searchText = "草稿"
        picker.isSearchFieldFocused = true
        picker.groupExpansion.expandedKinds = [.closed]
        state.destination = .categoryPicker(picker)
        let store = TestStore(initialState: state) {
            OrderListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.clearFiltersTapped)) {
            $0.selectedDatePeriod = .all
            $0.selectedCategories = []
            $0.selectedPaymentMethod = nil
            $0.selectedOrderID = "restored"
            $0.destination?.modify(\.categoryPicker) {
                $0.committedCategories = []
            }
        }

        // Then
        await store.receive(\.delegate.selectionChanged, "restored")
        #expect(store.state.destination?.categoryPicker?.pendingCategories == ["未套用"])
        #expect(store.state.destination?.categoryPicker?.searchText == "草稿")
        #expect(store.state.destination?.categoryPicker?.isSearchFieldFocused == true)
        #expect(store.state.destination?.categoryPicker?.groupExpansion.expandedKinds == [.closed])
    }

    /// 篩選摘要前綴依語言使用規格的冒號，不改主檔摘要
    ///
    /// - Parameter testCase: 篩選觸發鈕文案語言案例
    @Test(arguments: Self.clearFilterTitleCases)
    func localizedString_篩選觸發鈕摘要_使用各語言冒號(testCase: ClearFilterTitleCase) {
        // Given
        let key = "orders.filter.label.filterSummary"

        // When
        let title = testCase.language.localizedString(forKey: key, testCase.summary)

        // Then
        #expect(title == testCase.expectedTitle)
    }
}

// MARK: - Nested Types

extension OrderListFeatureTests {

    /// 篩選觸發鈕文案語言案例
    struct ClearFilterTitleCase: Sendable {

        /// 顯示語言
        let language: AppLanguage

        /// 全部或已套用篩選摘要
        let summary: String

        /// 完整觸發鈕文案
        let expectedTitle: String
    }
}

// MARK: - Private Method

private extension OrderListFeatureTests {

    /// 中文使用全形冒號，英文保留原有半形冒號與空格
    ///
    /// - Note: 只建立值，不存取測試的主執行緒狀態
    nonisolated static var clearFilterTitleCases: [ClearFilterTitleCase] {
        [
            ClearFilterTitleCase(
                language: .traditionalChinese,
                summary: "全部",
                expectedTitle: "篩選：全部"
            ),
            ClearFilterTitleCase(
                language: .traditionalChinese,
                summary: "本月 · 美妝 · 現金",
                expectedTitle: "篩選：本月 · 美妝 · 現金"
            ),
            ClearFilterTitleCase(language: .english, summary: "All", expectedTitle: "Filter: All"),
            ClearFilterTitleCase(
                language: .english,
                summary: "This Month · beauty · Cash",
                expectedTitle: "Filter: This Month · beauty · Cash"
            ),
        ]
    }
}
