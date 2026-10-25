//
//  OrderListFeatureFilterLabelsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import SwiftUI
import Testing

@testable import BuyLedger

/// `OrderListFeature` 的單元測試，涵蓋篩選觸發鈕的標題與啟用狀態
struct OrderListFeatureFilterLabelsTests {

    /// 驗證類別標題依語言及已選數量顯示全部、單一名稱或項數
    ///
    /// - Parameter testCase: 已選類別、顯示語言與預期標題
    @Test(arguments: Self.categoryFilterTitleCases)
    func categoryFilterTitle_各種選取集合_顯示對應標題(testCase: CategoryFilterTitleCase) {
        // Given
        let categories = testCase.categories

        // When
        let title = OrderFormatters.categoryFilterTitle(
            categories,
            locale: testCase.language.locale
        )

        // Then
        #expect(title == LocalizedStringKey(testCase.expectedTitle))
    }

    /// 驗證未選任何類別時，`hasCategoryFilter` 為 `false`
    @Test
    func hasCategoryFilter_未選類別_回傳否() {
        // Given
        let state = OrderListFeatureTestSupport.makeState()

        // When
        let hasCategoryFilter = state.hasCategoryFilter

        // Then
        #expect(hasCategoryFilter == false)
    }

    /// 驗證已選取美妝類別時，`hasCategoryFilter` 為 `true`
    @Test
    func hasCategoryFilter_已選類別_回傳是() {
        // Given
        var state = OrderListFeatureTestSupport.makeState()
        state.selectedCategories = ["美妝"]

        // When
        let hasCategoryFilter = state.hasCategoryFilter

        // Then
        #expect(hasCategoryFilter == true)
    }

    /// 驗證未選任何付款方式時，`hasPaymentMethodFilter` 為 `false`
    @Test
    func hasPaymentMethodFilter_未選付款方式_回傳否() {
        // Given
        let state = OrderListFeatureTestSupport.makeState()

        // When
        let hasPaymentMethodFilter = state.hasPaymentMethodFilter

        // Then
        #expect(hasPaymentMethodFilter == false)
    }

    /// 驗證已選取信用卡付款方式時，`hasPaymentMethodFilter` 為 `true`
    @Test
    func hasPaymentMethodFilter_已選付款方式_回傳是() {
        // Given
        var state = OrderListFeatureTestSupport.makeState()
        state.selectedPaymentMethod = "信用卡"

        // When
        let hasPaymentMethodFilter = state.hasPaymentMethodFilter

        // Then
        #expect(hasPaymentMethodFilter == true)
    }
}

// MARK: - Nested Types

extension OrderListFeatureFilterLabelsTests {

    /// 類別觸發鈕標題的測試案例，含已選類別、顯示語言與預期結果
    struct CategoryFilterTitleCase: Sendable {

        /// 已套用類別
        let categories: Set<String>

        /// 顯示語言
        let language: AppLanguage

        /// 預期的觸發鈕標題
        let expectedTitle: String
    }
}

// MARK: - Private Method

private extension OrderListFeatureFilterLabelsTests {

    /// 各種選取集合與語言的標題預期
    static var categoryFilterTitleCases: [CategoryFilterTitleCase] {
        [
            CategoryFilterTitleCase(
                categories: [],
                language: .traditionalChinese,
                expectedTitle: "類別：全部"
            ),
            CategoryFilterTitleCase(
                categories: ["beauty"],
                language: .traditionalChinese,
                expectedTitle: "類別：beauty"
            ),
            CategoryFilterTitleCase(
                categories: ["beauty", "snacks"],
                language: .traditionalChinese,
                expectedTitle: "類別：2 項"
            ),
            CategoryFilterTitleCase(
                categories: ["beauty", "snacks", "books"],
                language: .traditionalChinese,
                expectedTitle: "類別：3 項"
            ),
            CategoryFilterTitleCase(
                categories: [],
                language: .english,
                expectedTitle: "Category: All"
            ),
            CategoryFilterTitleCase(
                categories: ["beauty"],
                language: .english,
                expectedTitle: "Category: beauty"
            ),
            CategoryFilterTitleCase(
                categories: ["beauty", "snacks"],
                language: .english,
                expectedTitle: "Categories: 2"
            ),
            CategoryFilterTitleCase(
                categories: ["beauty", "snacks", "books"],
                language: .english,
                expectedTitle: "Categories: 3"
            ),
        ]
    }
}
