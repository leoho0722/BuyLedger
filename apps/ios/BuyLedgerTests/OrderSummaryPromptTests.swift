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

/// AI 商品摘要與完整提示文字的既有行為測試
struct OrderSummaryPromptTests {

    /// 空訂單清單或沒有品項時，提示保留空明細文字
    ///
    /// - Parameter hasOrder: 是否提供沒有品項的訂單
    @Test(arguments: [false, true])
    func summaryPrompt_沒有商品明細_提示保留空明細文字(hasOrder: Bool) {
        // Given
        let orders = hasOrder ? [LedgerOrder.fixture(date: TestDependencies.fixedNow)] : []

        // When
        let prompt = OrderSummaryPrompt.summaryPrompt(orders: orders, selectedCategory: nil)

        // Then
        #expect(prompt.contains("\n\n(目前列表沒有任何商品明細)\n\n"))
    }

    /// 類別與品名去掉首尾空白，空白類別略過、沒有類別時顯示「未分類」，空白品名顯示「未命名商品」，順序與數值不變
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
        let prompt = OrderSummaryPrompt.summaryPrompt(orders: orders, selectedCategory: nil)

        // Then
        let expected = """
            - [書籍、文具] A2 x2 @ 125 JPY
            - [書籍、文具] 未命名商品 x0 @ 0 JPY
            - [未分類] B1 x3 @ -5 TWD
            """
        #expect(prompt.contains("\n\n\(expected)\n\n"))
    }

    /// 摘要在二百筆邊界保留固定筆數，只在超過時顯示省略提示
    ///
    /// - Parameters:
    ///   - count: 測試訂單的品項數
    ///   - expected: 依固定格式組出的期望商品明細文字
    @Test(arguments: [
        (199, String(repeating: "- [未分類] A x1 @ 10 TWD\n", count: 198)
            + "- [未分類] A x1 @ 10 TWD"),
        (200, String(repeating: "- [未分類] A x1 @ 10 TWD\n", count: 199)
            + "- [未分類] A x1 @ 10 TWD"),
        (201, String(repeating: "- [未分類] A x1 @ 10 TWD\n", count: 199)
            + "- [未分類] A x1 @ 10 TWD\n…(其餘 1 個品項未列出)"),
    ])
    func summaryPrompt_品項數在上限前後_只截取二百筆(count: Int, expected: String) {
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
                items: Array(repeating: item, count: count)
            ),
        ]

        // When
        let prompt = OrderSummaryPrompt.summaryPrompt(orders: orders, selectedCategory: nil)

        // Then
        #expect(prompt.contains("\n\n" + expected + "\n\n"))
    }

    /// 品項上限跨訂單累計，省略數也包含後續訂單
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
        let prompt = OrderSummaryPrompt.summaryPrompt(orders: orders, selectedCategory: nil)

        // Then
        #expect(prompt.contains("\n\n" + expected + "\n\n"))
    }

    /// 未篩選類別的提示保留完整原文與空行
    @Test
    func summaryPrompt_沒有類別篩選_顯示所有類別範圍() {
        // Given
        let orders: [LedgerOrder] = []

        // When
        let prompt = OrderSummaryPrompt.summaryPrompt(orders: orders, selectedCategory: nil)

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

    /// 已篩選類別的提示保留指定類別與商品明細
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
        let prompt = OrderSummaryPrompt.summaryPrompt(orders: orders, selectedCategory: "書籍")

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
