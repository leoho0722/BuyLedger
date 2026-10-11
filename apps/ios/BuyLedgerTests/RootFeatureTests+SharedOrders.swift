//
//  RootFeatureTests+SharedOrders.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// 載入結果寫入共用的訂單資料，並在同一次回應中更新開團、更多頁、總覽與分析頁的訂單
    @Test
    func orders_收到載入回應_同次更新開團與更多訂單投影() async {
        // Given
        let loaded = [LedgerOrder.fixture(id: "O1", date: TestDependencies.fixedNow)]
        let initial = Self.makeIsolatedRootState()
        let store = TestStore(initialState: initial) {
            RootFeature()
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
                orders: SharedReader($0.orders.$orders)
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

    /// 載入失敗時，同一次回應就把失敗狀態告知總覽與分析頁
    @Test
    func orders_收到載入失敗_同次更新首頁與分析載入投影() async {
        // Given
        let initial = Self.makeIsolatedRootState()
        initial.orders.load.$isLoading.withLock {
            $0 = true
        }
        let error = PersistenceError.fetchFailed(
            underlying: TestDependencies.makeUnderlyingError(message: "read")
        )
        let outcome = OrdersLoadFeature.Outcome(orders: .failure(error))
        let store = TestStore(initialState: initial) {
            RootFeature()
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
        #expect(store.state.dashboard.loadState == .failed("orders.general.message.ordersLoadedTry"))
        #expect(store.state.insights.loadState == .failed("orders.general.message.ordersLoadedTry"))
    }

    /// 儲存成功後，共用的訂單換成儲存後的版本，並在同一次回應中更新開團、更多頁、總覽與分析頁的訂單
    @Test
    func orders_收到儲存成功回應_同次更新開團與更多訂單投影() async {
        // Given
        let original = LedgerOrder.fixture(id: "O1", date: TestDependencies.fixedNow)
        let saved = LedgerOrder.fixture(id: "O1", date: TestDependencies.fixedNow, notes: "已儲存")
        var initial = Self.makeIsolatedRootState()
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

    /// 收款狀態寫入成功後，已開啟的客戶頁直接讀到更新後的訂單
    @Test
    func orders_訂單更新_已推入的客戶頁讀到新訂單() async {
        // Given
        let order = LedgerOrder.fixture(id: "SHARED-CUSTOMER")
        let updated = Self.rebuiltOrder(order, paymentReceiptStatus: .received)
        var initial = CampaignIntegrationTests.makeRootState(campaigns: [], orders: [order])
        initial.more.path.append(
            .customers(CustomersFeature.State(orders: SharedReader(initial.more.$orders)))
        )
        let saved = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                saved.withValue {
                    $0.append(order)
                }
            }
        }

        // When
        await store.send(.orders(.receiptStatusChangeRequested(id: order.id, status: .received)))

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
