//
//  OrderListFeatureClearFilterPresentationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrderListFeature` 的單元測試，涵蓋清除篩選的呈現與篩選觸發鈕的文案
struct OrderListFeatureClearFilterPresentationTests {

    /// 驗證清除篩選時，篩選面板的已套用值同步為清除後的值，暫存選擇、搜尋文字、焦點與展開都保留，並通知清單選取改為 restored
    @Test
    @MainActor
    func clearFiltersTapped_整合篩選已開啟_同步基準並保留草稿() async {
        // Given
        var state = OrderListFeatureTestSupport.makeClearFiltersState()
        var sheet = OrderFilterFeatureTestSupport.makeState(for: state)
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

    /// 驗證清除篩選時，開啟中的類別選擇器只同步已套用的類別基準，暫存集合、搜尋文字、焦點與展開都保留
    @Test
    @MainActor
    func clearFiltersTapped_類別選擇器已開啟_同步基準並保留草稿() async {
        // Given
        var state = OrderListFeatureTestSupport.makeClearFiltersState()
        var picker = OrderCategoryPickerFeatureTestSupport.makeState(for: state)
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

    /// 驗證篩選觸發鈕文案依語言使用對應的冒號，摘要內容原樣保留
    ///
    /// - Parameter testCase: 顯示語言、已套用篩選摘要與預期的完整觸發鈕文案
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

extension OrderListFeatureClearFilterPresentationTests {

    /// 篩選觸發鈕文案的測試案例，含顯示語言、摘要與預期文案
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

private extension OrderListFeatureClearFilterPresentationTests {

    /// 篩選觸發鈕文案的語言案例，中文用全形冒號，英文用半形冒號加空格
    static var clearFilterTitleCases: [ClearFilterTitleCase] {
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
