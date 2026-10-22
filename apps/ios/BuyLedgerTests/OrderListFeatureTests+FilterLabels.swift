//
//  OrderListFeatureTests+FilterLabels.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import SwiftUI
import Testing

@testable import BuyLedger

extension OrderListFeatureTests {

    /// 寬版類別觸發鈕依選取數量顯示全部、名稱或項數
    ///
    /// - Parameter testCase: 類別觸發鈕標題測試案例
    @Test(arguments: Self.categoryFilterTitleCases)
    func categoryFilterTitle_各種選取集合_顯示對應標題與啟用狀態(testCase: CategoryFilterTitleCase) {
        // Given
        var state = Self.makeState()
        state.selectedCategories = testCase.categories

        // When
        let title = OrderFormatters.categoryFilterTitle(
            testCase.categories,
            locale: testCase.language.locale
        )

        // Then
        #expect(title == LocalizedStringKey(testCase.expectedTitle))
        #expect(state.hasCategoryFilter == testCase.hasCategoryFilter)
    }

    /// 未套用商品類別篩選時，回報沒有類別篩選
    @Test
    func hasCategoryFilter_未選類別_回傳否() {
        // Given
        let state = Self.makeState()

        // When
        let hasCategoryFilter = state.hasCategoryFilter

        // Then
        #expect(hasCategoryFilter == false)
    }

    /// 套用商品類別篩選後，回報有類別篩選
    @Test
    func hasCategoryFilter_已選類別_回傳是() {
        // Given
        var state = Self.makeState()
        state.selectedCategories = ["美妝"]

        // When
        let hasCategoryFilter = state.hasCategoryFilter

        // Then
        #expect(hasCategoryFilter == true)
    }

    /// 未套用付款方式篩選時，回報沒有付款方式篩選
    @Test
    func hasPaymentMethodFilter_未選付款方式_回傳否() {
        // Given
        let state = Self.makeState()

        // When
        let hasPaymentMethodFilter = state.hasPaymentMethodFilter

        // Then
        #expect(hasPaymentMethodFilter == false)
    }

    /// 套用付款方式篩選後，回報有付款方式篩選
    @Test
    func hasPaymentMethodFilter_已選付款方式_回傳是() {
        // Given
        var state = Self.makeState()
        state.selectedPaymentMethod = "信用卡"

        // When
        let hasPaymentMethodFilter = state.hasPaymentMethodFilter

        // Then
        #expect(hasPaymentMethodFilter == true)
    }
}

// MARK: - Nested Types

extension OrderListFeatureTests {

    /// 類別觸發鈕標題測試案例
    struct CategoryFilterTitleCase: Sendable {

        /// 已套用類別
        let categories: Set<String>

        /// 顯示語言
        let language: AppLanguage

        /// 觸發鈕標題
        let expectedTitle: String

        /// 是否採用啟用外觀
        let hasCategoryFilter: Bool
    }
}

// MARK: - Private Method

private extension OrderListFeatureTests {

    /// 各種選取集合與語言的標題預期
    ///
    /// - Note: 只建立值，不存取測試的主執行緒狀態
    nonisolated static var categoryFilterTitleCases: [CategoryFilterTitleCase] {
        [
            CategoryFilterTitleCase(
                categories: [],
                language: .traditionalChinese,
                expectedTitle: "類別：全部",
                hasCategoryFilter: false
            ),
            CategoryFilterTitleCase(
                categories: ["beauty"],
                language: .traditionalChinese,
                expectedTitle: "類別：beauty",
                hasCategoryFilter: true
            ),
            CategoryFilterTitleCase(
                categories: ["beauty", "snacks"],
                language: .traditionalChinese,
                expectedTitle: "類別：2 項",
                hasCategoryFilter: true
            ),
            CategoryFilterTitleCase(
                categories: ["beauty", "snacks", "books"],
                language: .traditionalChinese,
                expectedTitle: "類別：3 項",
                hasCategoryFilter: true
            ),
            CategoryFilterTitleCase(
                categories: [],
                language: .english,
                expectedTitle: "Category: All",
                hasCategoryFilter: false
            ),
            CategoryFilterTitleCase(
                categories: ["beauty"],
                language: .english,
                expectedTitle: "Category: beauty",
                hasCategoryFilter: true
            ),
            CategoryFilterTitleCase(
                categories: ["beauty", "snacks"],
                language: .english,
                expectedTitle: "Categories: 2",
                hasCategoryFilter: true
            ),
            CategoryFilterTitleCase(
                categories: ["beauty", "snacks", "books"],
                language: .english,
                expectedTitle: "Categories: 3",
                hasCategoryFilter: true
            ),
        ]
    }
}
