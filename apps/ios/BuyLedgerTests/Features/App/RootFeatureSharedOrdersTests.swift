//
//  RootFeatureSharedOrdersTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試，以 TestStore 驗證訂單載入、儲存與收款更新時，開團、更多、總覽與分析的訂單投影如何同步
@MainActor
struct RootFeatureSharedOrdersTests {

    /// 驗證收到載入回應時，共用的訂單資料與開團、更多頁、總覽與分析頁的訂單在同一次回應中更新
    @Test
    func orders_收到載入回應_同次更新開團與更多訂單投影() async {
        // Given
        let loaded = [LedgerOrder.fixture(id: "O1", date: TestDependencies.fixedNow)]
        let initial = RootFeatureTestSupport.makeIsolatedRootState()
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        let outcome = OrdersLoadFeature.Outcome(orders: .success(loaded))

        // When
        await store.send(.orders(.load(.loadResponse(outcome)))) {
            $0.orders.$orders.withLock {
                $0 = loaded
            }
            $0.orders.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.orders.list.selectedOrderID = "O1"
            $0.orders.detail.regularDetail = OrderDetailFeature.State(
                orderID: "O1",
                orders: SharedReader(value: loaded)
            )
            $0.campaigns.$orders.withLock {
                $0 = loaded
            }
            $0.more.$orders.withLock {
                $0 = loaded
            }
            $0.dashboard.orders = loaded
            $0.dashboard.loadState = .loaded
            $0.insights.orders = loaded
            $0.insights.loadState = .loaded
        }

        // Then
        #expect(store.state.orders.orders == loaded)
        #expect(store.state.campaigns.orders == loaded)
        #expect(store.state.more.orders == loaded)
    }

    /// 驗證載入失敗時，同一次回應就把錯誤訊息同步給總覽與分析頁的載入狀態
    @Test
    func orders_收到載入失敗_同次更新首頁與分析載入投影() async {
        // Given
        let initial = RootFeatureTestSupport.makeIsolatedRootState()
        initial.orders.load.$isLoading.withLock {
            $0 = true
        }
        let error = PersistenceError.fetchFailed(
            underlying: TestDependencies.makeUnderlyingError(message: "read")
        )
        let outcome = OrdersLoadFeature.Outcome(orders: .failure(error))
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.orders(.load(.loadResponse(outcome)))) {
            $0.orders.load.$isLoading.withLock {
                $0 = false
            }
            $0.orders.load.$errorMessage.withLock {
                $0 = "orders.general.message.ordersLoadedTry"
            }
            $0.dashboard.loadState = .failed("orders.general.message.ordersLoadedTry")
            $0.insights.loadState = .failed("orders.general.message.ordersLoadedTry")
        }

        // Then
        await store.receive(\.orders.load.delegate.loadFailed)
        await store.finish()
        #expect(store.state.orders.loadState == .failed("orders.general.message.ordersLoadedTry"))
        #expect(
            store.state.dashboard.loadState == .failed("orders.general.message.ordersLoadedTry")
        )
        #expect(store.state.insights.loadState == .failed("orders.general.message.ordersLoadedTry"))
    }

    /// 驗證儲存成功時，共用的訂單換成儲存後的版本，並在同一次回應中更新開團、更多頁、總覽與分析頁的訂單
    @Test
    func orders_收到儲存成功回應_同次更新開團與更多訂單投影() async {
        // Given
        let original = LedgerOrder.fixture(id: "O1", date: TestDependencies.fixedNow)
        let saved = LedgerOrder.fixture(id: "O1", date: TestDependencies.fixedNow, notes: "已儲存")
        var initial = RootFeatureTestSupport.makeIsolatedRootState()
        initial.orders.$orders.withLock {
            $0 = [original]
        }
        initial.campaigns.$orders.withLock {
            $0 = [original]
        }
        initial.more.$orders.withLock {
            $0 = [original]
        }
        initial.dashboard.orders = [original]
        initial.insights.orders = [original]
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        let result = OrderDraft.WriteResult(
            order: saved,
            isNewOrder: false,
            shouldWritePhotos: false
        )

        // When
        await store.send(.orders(.writes(.saveResponse(.success(result))))) {
            $0.orders.$orders.withLock {
                $0 = [saved]
            }
            $0.campaigns.$orders.withLock {
                $0 = [saved]
            }
            $0.more.$orders.withLock {
                $0 = [saved]
            }
            $0.dashboard.orders = [saved]
            $0.insights.orders = [saved]
        }

        // Then
        await store.receive(\.orders.writes.delegate, .saved(id: "O1", isNewOrder: false))
        await store.finish()
        #expect(store.state.orders.orders == [saved])
        #expect(store.state.campaigns.orders == [saved])
        #expect(store.state.more.orders == [saved])
    }

    /// 驗證收款狀態變更後，已推入的客戶頁直接讀到更新後的訂單，不必重新推入
    @Test
    func orders_訂單更新_已推入的客戶頁讀到新訂單() async {
        // Given
        let order = LedgerOrder.fixture(id: "SHARED-CUSTOMER")
        let updated = RootFeatureTestSupport.rebuiltOrder(order, paymentReceiptStatus: .received)
        var initial = CampaignIntegrationTestSupport.makeRootState(campaigns: [], orders: [order])
        initial.more.path.append(
            .customers(CustomersFeature.State(orders: SharedReader(initial.more.$orders)))
        )
        let saved = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.orderService.saveOrder = { order in
                saved.withValue {
                    $0.append(order)
                }
            }
        }

        // When
        await store.send(
            .orders(.rootRequest(.receiptStatusChange(id: order.id, status: .received)))
        )

        // Then
        await store.receive(\.orders.writes.receiptToggleRequested) {
            $0.orders.$orders.withLock {
                $0 = [updated]
            }
            $0.campaigns.$orders.withLock {
                $0 = [updated]
            }
            $0.more.$orders.withLock {
                $0 = [updated]
            }
        }
        await store.receive(\.orders.writes.receiptResponse) {
            $0.dashboard.orders = [updated]
            $0.insights.orders = [updated]
        }
        await store.finish()
        #expect(saved.value == [updated])
        #expect(store.state.more.path[id: 0]?.customers?.orders == [updated])
    }
}
