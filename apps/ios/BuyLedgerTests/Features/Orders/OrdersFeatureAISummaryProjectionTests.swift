//
//  OrdersFeatureAISummaryProjectionTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `OrdersFeature` 的單元測試，以 TestStore 逐步驗證 AI 摘要設定投影對摘要目的地與模型的影響
@MainActor
struct OrdersFeatureAISummaryProjectionTests {

    /// 驗證 AI 摘要已開啟時，直接使用狀態中記下的模型呈現摘要，不另外讀取設定
    @Test
    func list_摘要投影啟用且設定服務未覆寫_呈現指定模型() async {
        // Given
        var initial = OrdersFeature.State()
        initial.aiSummarySettings = OrderAISummarySettings(
            isEnabled: true,
            model: "projection-model"
        )
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.list(.delegate(.requested(.aiSummary)))) {
            $0.presentation.destination = .aiSummary(
                AISummaryFeature.State(
                    prompt: """
                        你是個人代購 App 的分析助理。以下是目前訂單列表的商品明細(涵蓋目前列表所有類別)，每行格式為「- [類別] 商品名稱 x數量 @ 單價 幣別」：

                        (目前列表沒有任何商品明細)

                        請用正體中文、以 Markdown 格式總結這些商品明細，內容包含：
                        - 一個 `##` 層級的標題
                        - 各品項的品名以及購買的總數量 (如果品名有編號的話，請照編號排序；如果沒有編號的話，請照字母順序排序)

                        請以條列與粗體強調重點，全文控制在約 200–300 字。只根據上面提供的資料作答，不要杜撰未出現的商品、數字或結論。
                        """,
                    model: "projection-model"
                )
            )
        }

        // Then
        #expect(store.state.presentation.destination?.aiSummary?.model == "projection-model")
    }

    /// 驗證 AI 摘要已停用時，不讀取設定，直接呈現需要先開啟的提示
    @Test
    func list_摘要投影停用且設定服務未覆寫_呈現啟用提示() async {
        // Given
        var initial = OrdersFeature.State()
        initial.aiSummarySettings = OrderAISummarySettings(isEnabled: false, model: "unused-model")
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.list(.delegate(.requested(.aiSummary)))) {
            $0.presentation.destination = .aiDisabled
        }

        // Then
        #expect(store.state.presentation.destination?.alert != nil)
    }
}
