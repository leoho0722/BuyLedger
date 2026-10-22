//
//  RootFeatureTests+AISummaryProjection.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// 建立根狀態時就帶入 AI 摘要設定，第一次要求摘要即使用初始模型
    @Test
    func orders_初始偏好啟用摘要_第一個摘要使用初始模型() async {
        // Given
        var preferences = SettingsSnapshot.default
        preferences.isAISummaryEnabled = true
        preferences.aiSummaryModel = "initial-model"
        let initial = Self.makeIsolatedRootState {
            RootFeature.State(preferences: preferences)
        }
        let store = TestStore(initialState: initial) {
            RootFeature()
        }

        // When
        await store.send(.orders(.list(.delegate(.requested(.aiSummary))))) {
            $0.orders.presentation.destination = .aiSummary(
                AISummaryFeature.State(
                    prompt: """
                        你是個人代購 App 的分析助理。以下是目前訂單列表的商品明細(涵蓋目前列表所有類別)，每行格式為「- [類別] 商品名稱 x數量 @ 單價 幣別」：

                        (目前列表沒有任何商品明細)

                        請用正體中文、以 Markdown 格式總結這些商品明細，內容包含：
                        - 一個 `##` 層級的標題
                        - 各品項的品名以及購買的總數量 (如果品名有編號的話，請照編號排序；如果沒有編號的話，請照字母順序排序)

                        請以條列與粗體強調重點，全文控制在約 200–300 字。只根據上面提供的資料作答，不要杜撰未出現的商品、數字或結論。
                        """,
                    model: "initial-model"
                )
            )
        }

        // Then
        #expect(store.state.orders.aiSummarySettings.isEnabled)
        #expect(store.state.orders.aiSummarySettings.model == "initial-model")
        #expect(store.state.orders.presentation.destination?.aiSummary?.model == "initial-model")
    }

    /// 偏好改動時，已開啟的摘要保留開啟當時的模型，不因設定改動而換成新模型
    @Test
    func more_偏好改動時已開啟的摘要_保留原模型() async {
        // Given
        var preferences = SettingsSnapshot.default
        preferences.isAISummaryEnabled = true
        preferences.aiSummaryModel = "old-model"
        var initial = Self.makeIsolatedRootState {
            RootFeature.State(preferences: preferences)
        }
        initial.orders.presentation.destination = .aiSummary(
            AISummaryFeature.State(prompt: "已開啟的摘要", model: "old-model")
        )
        var disabled = preferences
        disabled.isAISummaryEnabled = false
        disabled.aiSummaryModel = "new-model"
        let store = TestStore(initialState: initial) {
            RootFeature()
        }

        // When
        await store.send(.more(.delegate(.preferencesChanged(disabled)))) {
            $0.preferences = disabled
            $0.more.preferences = disabled
            $0.orders.aiSummarySettings = OrderAISummarySettings(
                isEnabled: false,
                model: "new-model"
            )
        }

        // Then
        #expect(store.state.orders.presentation.destination?.aiSummary?.model == "old-model")
    }

    /// 偏好改動後關閉並重新開啟摘要，新摘要改用新模型
    @Test
    func orders_偏好改動後重新開啟摘要_使用新模型() async {
        // Given
        var preferences = SettingsSnapshot.default
        preferences.isAISummaryEnabled = true
        preferences.aiSummaryModel = "old-model"
        let initial = Self.makeIsolatedRootState {
            RootFeature.State(preferences: preferences)
        }
        var disabled = preferences
        disabled.isAISummaryEnabled = false
        disabled.aiSummaryModel = "new-model"
        var enabled = disabled
        enabled.isAISummaryEnabled = true
        let store = TestStore(initialState: initial) {
            RootFeature()
        }
        await store.send(.more(.delegate(.preferencesChanged(disabled)))) {
            $0.preferences = disabled
            $0.more.preferences = disabled
            $0.orders.aiSummarySettings = OrderAISummarySettings(
                isEnabled: false,
                model: "new-model"
            )
        }
        await store.send(.more(.delegate(.preferencesChanged(enabled)))) {
            $0.preferences = enabled
            $0.more.preferences = enabled
            $0.orders.aiSummarySettings = OrderAISummarySettings(
                isEnabled: true,
                model: "new-model"
            )
        }

        // When
        await store.send(.orders(.list(.delegate(.requested(.aiSummary))))) {
            $0.orders.presentation.destination = .aiSummary(
                AISummaryFeature.State(
                    prompt: """
                        你是個人代購 App 的分析助理。以下是目前訂單列表的商品明細(涵蓋目前列表所有類別)，每行格式為「- [類別] 商品名稱 x數量 @ 單價 幣別」：

                        (目前列表沒有任何商品明細)

                        請用正體中文、以 Markdown 格式總結這些商品明細，內容包含：
                        - 一個 `##` 層級的標題
                        - 各品項的品名以及購買的總數量 (如果品名有編號的話，請照編號排序；如果沒有編號的話，請照字母順序排序)

                        請以條列與粗體強調重點，全文控制在約 200–300 字。只根據上面提供的資料作答，不要杜撰未出現的商品、數字或結論。
                        """,
                    model: "new-model"
                )
            )
        }

        // Then
        #expect(store.state.orders.aiSummarySettings.isEnabled)
        #expect(store.state.orders.aiSummarySettings.model == "new-model")
        #expect(store.state.orders.presentation.destination?.aiSummary?.model == "new-model")
    }
}
