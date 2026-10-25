//
//  OrdersFeatureLoadAndSummaryTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrdersFeature` 的單元測試，以 TestStore 逐步驗證訂單載入、開團投影與 AI 摘要的目的地
@MainActor
struct OrdersFeatureLoadAndSummaryTests {

    /// 驗證根功能要求載入時，先清除舊的錯誤訊息，讀回訂單後自動選取第一筆
    @Test
    func rootRequest_載入訂單清單_選取第一筆訂單() async {
        // Given
        let orders = LedgerOrder.sampleOrders
        var state = OrdersFeature.State()
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        state.load.$errorMessage.withLock {
            $0 = "舊錯誤"
        }
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.orderService.fetchOrders = {
                LedgerOrder.sampleOrders
            }
        }

        // When
        await store.send(.rootRequest(.load)) {
            $0.load.$isLoading.withLock {
                $0 = true
            }
            $0.load.$errorMessage.withLock {
                $0 = nil
            }
        }

        // Then
        await store.receive(\.load.loadRequested) {
            $0.load.$isLoading.withLock {
                $0 = false
            }
            $0.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.$orders.withLock {
                $0 = orders
            }
        }
        await store.receive(\.load.loadResponse) {
            $0.list.selectedOrderID = "BL-2604-018"
            $0.detail.regularDetail = OrderDetailFeature.State(
                orderID: "BL-2604-018",
                orders: SharedReader(state.$orders)
            )
        }
        await store.finish()
    }

    /// 驗證已有開團投影時載入訂單，只更新訂單，開團投影保持不變，不重新讀取或結單
    @Test
    func rootRequest_已有開團投影後載入訂單_保留投影() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            closeDate: Date(timeIntervalSince1970: 1_776_643_200),
            status: .ongoing
        )
        var initial = OrdersFeature.State()
        initial.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.orderService.fetchOrders = {
                []
            }
        }

        // When
        await store.send(.rootRequest(.load)) {
            $0.load.$isLoading.withLock {
                $0 = true
            }
        }

        // Then
        await store.receive(\.load.loadRequested) {
            $0.load.$isLoading.withLock {
                $0 = false
            }
            $0.load.$hasLoaded.withLock {
                $0 = true
            }
        }
        await store.receive(\.load.loadResponse)
        await store.finish()
        #expect(store.state.campaigns == [campaign])
    }

    /// 驗證啟用 AI 摘要後點按摘要，摘要畫面帶入商品明細與指定模型
    @Test
    func list_摘要功能已啟用_呈現摘要畫面() async {
        // Given
        var state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        state.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        state.aiSummarySettings = OrderAISummarySettings(isEnabled: true, model: "gpt-oss:120b")
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.list(.delegate(.requested(.aiSummary)))) {
            $0.presentation.destination = .aiSummary(
                AISummaryFeature.State(
                    prompt: """
                        你是個人代購 App 的分析助理。以下是目前訂單列表的商品明細(涵蓋目前列表所有類別)，每行格式為「- [類別] 商品名稱 x數量 @ 單價 幣別」：

                        - [美妝] Tamburins 香水 Chamo 50ml x1 @ 95000 KRW
                        - [美妝] Gentle Monster Her 02 x1 @ 295000 KRW
                        - [服飾] Snidel 春季針織外套 (M) x1 @ 18700 JPY
                        - [美妝] Aesop Rōzu Eau de Parfum 50ml x1 @ 220000 KRW
                        - [美妝] Hera Black Cushion #21 x2 @ 68000 KRW
                        - [精品] Polène Numéro Un Nano 米色 x1 @ 390 EUR
                        - [美妝] Sulwhasoo 滋陰生 60ml x1 @ 27000 JPY
                        - [美妝] Innisfree 綠茶精華 80ml x1 @ 4500 JPY
                        - [美妝] Le Labo Santal 33 50ml x1 @ 218 USD
                        - [服飾] Adererror 標準 Logo Tee 黑 x2 @ 89000 KRW
                        - [美妝、服飾] Hince 絲絨唇釉 #07 x1 @ 22000 KRW
                        - [美妝、服飾] Matin Kim 寬版牛仔褲 (S) x1 @ 79000 KRW

                        請用正體中文、以 Markdown 格式總結這些商品明細，內容包含：
                        - 一個 `##` 層級的標題
                        - 各品項的品名以及購買的總數量 (如果品名有編號的話，請照編號排序；如果沒有編號的話，請照字母順序排序)

                        請以條列與粗體強調重點，全文控制在約 200–300 字。只根據上面提供的資料作答，不要杜撰未出現的商品、數字或結論。
                        """,
                    model: "gpt-oss:120b"
                )
            )
        }

        // Then
        #expect(store.state.presentation.destination?.aiSummary?.model == "gpt-oss:120b")
        #expect(
            store.state.presentation.destination?.aiSummary?.prompt.contains("(涵蓋目前列表所有類別)") == true
        )
    }

    /// 驗證 AI 摘要未開啟時點按摘要，改為呈現提醒 alert，請使用者到設定開啟
    @Test
    func list_摘要功能已停用_呈現提醒() async {
        // Given
        var initial = OrdersFeature.State()
        initial.aiSummarySettings = OrderAISummarySettings(isEnabled: false, model: "unused-model")
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.list(.delegate(.requested(.aiSummary)))) {
            $0.presentation.destination = .alert(
                AlertState {
                    TextState("orders.general.label.aiItemSummary")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("common.action.label.close")
                    }
                    ButtonState(action: .goToAISettings) {
                        TextState("orders.general.label.openSettings2")
                    }
                } message: {
                    TextState("orders.general.message.enableAiItem")
                }
            )
        }

        // Then
        #expect(store.state.presentation.destination?.alert != nil)
    }
}
