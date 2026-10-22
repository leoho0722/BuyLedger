//
//  OrdersContainerPlanTests+Categories.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrdersContainerPlanTests {

    /// 摘要只使用多類別篩選結果，並列出全部選取類別
    ///
    /// - Throws: 未呈現 AI 摘要時由 `#require` 丟出
    @Test
    func fulfill_多類別篩選後要求摘要_只傳相符明細與完整範圍() throws {
        // Given
        let item = LedgerOrderItem(
            id: UUID(0),
            name: "保留商品",
            quantity: 2,
            unitPrice: 100
        )
        let excludedItem = LedgerOrderItem(
            id: UUID(1),
            name: "排除商品",
            quantity: 1,
            unitPrice: 5
        )
        var state = Self.makeState(orders: [
            LedgerOrder.fixture(id: "A", items: [item], categories: ["美妝"]),
            LedgerOrder.fixture(id: "B", items: [item], categories: ["書籍"]),
            LedgerOrder.fixture(id: "C", items: [excludedItem], categories: ["食品"]),
        ])
        state.aiSummarySettings = OrderAISummarySettings(isEnabled: true, model: "test-model")
        state.list.dateContext = OrderDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.list.selectedCategories = ["書籍", "美妝"]

        // When
        let outcome = OrdersContainerPlan.fulfill(
            .aiSummary,
            state: state,
            context: nil,
            formID: nil
        )

        // Then
        let summary = try #require(outcomeSummary(outcome))
        #expect(summary.model == "test-model")
        #expect(summary.prompt.contains("(已篩選類別：美妝、書籍)"))
        #expect(summary.prompt.contains("- [美妝] 保留商品 x2 @ 100 TWD"))
        #expect(summary.prompt.contains("- [書籍] 保留商品 x2 @ 100 TWD"))
        #expect(summary.prompt.contains("排除商品") == false)
    }
}

// MARK: - Private Method

private extension OrdersContainerPlanTests {

    /// 取出請求結果中的 AI 摘要
    ///
    /// - Parameter outcome: 容器計算的請求結果
    /// - Returns: AI 摘要狀態；其他結果為 `nil`
    func outcomeSummary(_ outcome: OrdersRequestOutcome) -> AISummaryFeature.State? {
        guard case .present(.aiSummary(let summary)) = outcome else {
            return nil
        }
        return summary
    }
}
