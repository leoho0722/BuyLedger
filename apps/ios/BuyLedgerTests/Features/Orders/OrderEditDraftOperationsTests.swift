//
//  OrderEditDraftOperationsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/17.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderEditDraftOperations` 的單元測試，守住基本資料區段的顯示文字，取代該區段的像素比對
struct OrderEditDraftOperationsTests {

    /// 驗證草稿有多個類別時，顯示文字依儲存順序以頓號串接，只有一個時原樣顯示，沒有類別時為空字串
    ///
    /// - Parameter testCase: 測試輸入與字面值預期結果
    @Test(arguments: [
        CategoriesDisplayCase(categories: ["美妝", "服飾"], expected: "美妝、服飾"),
        CategoriesDisplayCase(categories: ["美妝"], expected: "美妝"),
        CategoriesDisplayCase(categories: [], expected: ""),
    ])
    func categoriesDisplayText_類別數量不同_依序以頓號串接或為空(testCase: CategoriesDisplayCase) {
        // Given
        var state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        state.draft.categories = testCase.categories

        // When
        let text = OrderEditDraftOperations.categoriesDisplayText(draft: state.draft)

        // Then
        #expect(text == testCase.expected)
    }
}

// MARK: - Nested Types

extension OrderEditDraftOperationsTests {

    /// 類別顯示文字的輸入與預期結果
    struct CategoriesDisplayCase: Sendable {

        /// 草稿已選的類別
        let categories: [String]

        /// 預期顯示的類別文字
        let expected: String
    }
}
