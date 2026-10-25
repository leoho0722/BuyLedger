//
//  OrderSummaryPromptTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/7.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderSummaryPrompt` 的單元測試，鎖定既有的提示文字格式，包含類別範圍、空明細、名稱整理與二百筆上限
struct OrderSummaryPromptTests {

    /// 驗證提示範圍在已選類別為空時寫為涵蓋所有類別，有選取時列出排序後的類別名稱並以頓號串接
    ///
    /// - Parameter testCase: 已選類別與範圍文字的預期
    @Test(arguments: [
        CategoryScopeCase(categories: [], expectedScope: "(涵蓋目前列表所有類別)"),
        CategoryScopeCase(categories: ["美妝"], expectedScope: "(已篩選類別：美妝)"),
        CategoryScopeCase(categories: ["書籍", "美妝"], expectedScope: "(已篩選類別：美妝、書籍)"),
    ])
    func summaryPrompt_類別範圍範例_列出排序後的選取名稱(testCase: CategoryScopeCase) {
        // Given
        let orders: [LedgerOrder] = []

        // When
        let prompt = OrderSummaryPrompt.summaryPrompt(
            orders: orders,
            selectedCategories: testCase.categories
        )

        // Then
        #expect(prompt.contains(testCase.expectedScope))
    }

    /// 驗證列表沒有任何商品明細 (無訂單或訂單沒有品項) 時，提示在明細處保留「目前列表沒有任何商品明細」並前後空一行
    ///
    /// - Parameter hasOrder: 是否提供沒有品項的訂單
    @Test(arguments: [false, true])
    func summaryPrompt_沒有商品明細_提示保留空明細文字(hasOrder: Bool) {
        // Given
        let orders = hasOrder ? [LedgerOrder.fixture(date: TestDependencies.fixedNow)] : []

        // When
        let prompt = OrderSummaryPrompt.summaryPrompt(orders: orders, selectedCategories: [])

        // Then
        #expect(prompt.contains("\n\n(目前列表沒有任何商品明細)\n\n"))
    }

    /// 驗證類別與品名去除首尾空白後呈現，空白類別略過、無類別時顯示「未分類」，空白品名顯示「未命名商品」，順序、數量、單價與幣別原樣保留
    @Test
    func summaryPrompt_空白類別品名與多幣別_保留原有格式() {
        // Given
        let orders = [
            LedgerOrder.fixture(
                id: "first",
                currency: .jpy,
                date: TestDependencies.fixedNow,
                items: [
                    LedgerOrderItem(
                        id: UUID(0),
                        name: "  A2\n",
                        quantity: 2,
                        unitPrice: 125
                    ),
                    LedgerOrderItem(
                        id: UUID(1),
                        name: " \n",
                        quantity: 0,
                        unitPrice: 0
                    ),
                ],
                categories: [" 書籍 ", " \n", "文具"]
            ),
            LedgerOrder.fixture(
                id: "second",
                date: TestDependencies.fixedNow,
                items: [
                    LedgerOrderItem(
                        id: UUID(2),
                        name: " B1 ",
                        quantity: 3,
                        unitPrice: -5
                    ),
                ],
                categories: [" "]
            ),
        ]

        // When
        let prompt = OrderSummaryPrompt.summaryPrompt(orders: orders, selectedCategories: [])

        // Then
        let expected = """
            - [書籍、文具] A2 x2 @ 125 JPY
            - [書籍、文具] 未命名商品 x0 @ 0 JPY
            - [未分類] B1 x3 @ -5 TWD
            """
        #expect(prompt.contains("\n\n\(expected)\n\n"))
    }

    /// 驗證品項數在二百筆上下時，提示最多列出二百筆明細，只有超過時才在結尾顯示省略的筆數
    ///
    /// - Parameter testCase: 品項數與截取後的明細預期
    @Test(arguments: [
        ItemLimitCase(
            count: 199,
            expected: String(repeating: "- [未分類] A x1 @ 10 TWD\n", count: 198)
                + "- [未分類] A x1 @ 10 TWD"
        ),
        ItemLimitCase(
            count: 200,
            expected: String(repeating: "- [未分類] A x1 @ 10 TWD\n", count: 199)
                + "- [未分類] A x1 @ 10 TWD"
        ),
        ItemLimitCase(
            count: 201,
            expected: String(repeating: "- [未分類] A x1 @ 10 TWD\n", count: 199)
                + "- [未分類] A x1 @ 10 TWD\n…(其餘 1 個品項未列出)"
        ),
    ])
    func summaryPrompt_品項數在上限前後_只截取二百筆(testCase: ItemLimitCase) {
        // Given
        let item = LedgerOrderItem(
            id: UUID(0),
            name: "A",
            quantity: 1,
            unitPrice: 10
        )
        let orders = [
            LedgerOrder.fixture(
                date: TestDependencies.fixedNow,
                items: Array(repeating: item, count: testCase.count)
            ),
        ]

        // When
        let prompt = OrderSummaryPrompt.summaryPrompt(orders: orders, selectedCategories: [])

        // Then
        #expect(prompt.contains("\n\n" + testCase.expected + "\n\n"))
    }

    /// 驗證明細上限跨訂單累計，超過二百筆後略過所有後續訂單的品項，省略數也一併計入
    @Test
    func summaryPrompt_跨訂單超過上限_略過所有後續品項() {
        // Given
        let first = LedgerOrderItem(
            id: UUID(0),
            name: "A",
            quantity: 1,
            unitPrice: 10
        )
        let second = LedgerOrderItem(
            id: UUID(1),
            name: "B",
            quantity: 2,
            unitPrice: 20
        )
        let orders = [
            LedgerOrder.fixture(
                id: "first",
                date: TestDependencies.fixedNow,
                items: Array(repeating: first, count: 199)
            ),
            LedgerOrder.fixture(
                id: "second",
                date: TestDependencies.fixedNow,
                items: [second, second]
            ),
            LedgerOrder.fixture(id: "third", date: TestDependencies.fixedNow, items: [first]),
        ]
        let expected = String(repeating: "- [未分類] A x1 @ 10 TWD\n", count: 199)
            + "- [未分類] B x2 @ 20 TWD\n…(其餘 2 個品項未列出)"

        // When
        let prompt = OrderSummaryPrompt.summaryPrompt(orders: orders, selectedCategories: [])

        // Then
        #expect(prompt.contains("\n\n" + expected + "\n\n"))
    }

    /// 驗證沒有訂單且未篩選類別時，提示的完整原文 (含範圍文字與空明細) 與空行格式不變
    @Test
    func summaryPrompt_沒有類別篩選_顯示所有類別範圍() {
        // Given
        let orders: [LedgerOrder] = []

        // When
        let prompt = OrderSummaryPrompt.summaryPrompt(orders: orders, selectedCategories: [])

        // Then
        #expect(prompt == """
            你是個人代購 App 的分析助理。以下是目前訂單列表的商品明細(涵蓋目前列表所有類別)，每行格式為「- [類別] 商品名稱 x數量 @ 單價 幣別」：

            (目前列表沒有任何商品明細)

            請用正體中文、以 Markdown 格式總結這些商品明細，內容包含：
            - 一個 `##` 層級的標題
            - 各品項的品名以及購買的總數量 (如果品名有編號的話，請照編號排序；如果沒有編號的話，請照字母順序排序)

            請以條列與粗體強調重點，全文控制在約 200–300 字。只根據上面提供的資料作答，不要杜撰未出現的商品、數字或結論。
            """)
    }

    /// 驗證指定類別篩選時，提示的完整原文顯示該類別與對應的商品明細
    @Test
    func summaryPrompt_指定類別篩選_顯示類別與明細() {
        // Given
        let item = LedgerOrderItem(
            id: UUID(0),
            name: "A",
            quantity: 2,
            unitPrice: 10
        )
        let orders = [
            LedgerOrder.fixture(date: TestDependencies.fixedNow, items: [item], categories: ["書籍"]),
        ]

        // When
        let prompt = OrderSummaryPrompt.summaryPrompt(orders: orders, selectedCategories: ["書籍"])

        // Then
        #expect(prompt == """
            你是個人代購 App 的分析助理。以下是目前訂單列表的商品明細(已篩選類別：書籍)，每行格式為「- [類別] 商品名稱 x數量 @ 單價 幣別」：

            - [書籍] A x2 @ 10 TWD

            請用正體中文、以 Markdown 格式總結這些商品明細，內容包含：
            - 一個 `##` 層級的標題
            - 各品項的品名以及購買的總數量 (如果品名有編號的話，請照編號排序；如果沒有編號的話，請照字母順序排序)

            請以條列與粗體強調重點，全文控制在約 200–300 字。只根據上面提供的資料作答，不要杜撰未出現的商品、數字或結論。
            """)
    }
}

// MARK: - Nested Types

extension OrderSummaryPromptTests {

    /// 摘要提示的類別範圍與預期文字
    struct CategoryScopeCase: Sendable {

        /// 已選取類別
        let categories: Set<String>

        /// 規格表對應的範圍文字
        let expectedScope: String
    }

    /// 二百筆明細上限前後的輸入與完整預期
    struct ItemLimitCase: Sendable {

        /// 測試訂單的品項數
        let count: Int

        /// 依固定格式組出的預期商品明細文字
        let expected: String
    }
}
