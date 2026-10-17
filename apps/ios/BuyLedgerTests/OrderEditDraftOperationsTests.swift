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

/// 驗證訂單編輯草稿的顯示文字，取代基本資料區段的像素比對
struct OrderEditDraftOperationsTests {

    /// 類別依儲存順序以頓號串接，單一類別原樣顯示，沒有類別時為空字串
    ///
    /// - Parameters:
    ///   - categories: 草稿已選的類別
    ///   - expected: 預期顯示的類別文字
    @Test(arguments: [
        (categories: ["美妝", "服飾"], expected: "美妝、服飾"),
        (categories: ["美妝"], expected: "美妝"),
        (categories: [String](), expected: ""),
    ])
    func categoriesDisplayText_類別數量不同_依序以頓號串接或為空(categories: [String], expected: String) {
        // Given
        var state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        state.draft.categories = categories

        // When
        let text = OrderEditDraftOperations.categoriesDisplayText(draft: state.draft)

        // Then
        #expect(text == expected)
    }
}
