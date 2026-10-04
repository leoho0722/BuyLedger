//
//  CampaignIntegrationTests+Receipt.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension CampaignIntegrationTests {

    /// 未收款訂單從詳情改為已收款，經 Service 寫入後同步全部投影且保留其他訂單
    ///
    /// - Throws: 找不到詳情堆疊元素時由 `try #require` 丟出
    @Test
    func campaigns_未收款改為已收款_同步全部投影且只寫目標訂單() async throws(any Error) {
        // Given
        let context = try await makeReceiptToggleContext(wasReceived: false)
        let store = context.store
        let detailID = context.detailID

        // When
        await store.send(\.campaigns.path[id: detailID].detail.view.receiptToggleTapped, "O1")

        // Then
        await assertReceiptToggleSynced(context)
        #expect(context.saved.value.map(\.paymentReceiptStatus) == [.received])
    }

    /// 已收款訂單從詳情改回未收款，經 Service 寫入後同步全部投影且保留其他訂單
    ///
    /// - Throws: 找不到詳情堆疊元素時由 `try #require` 丟出
    @Test
    func campaigns_已收款改回未收款_同步全部投影且只寫目標訂單() async throws(any Error) {
        // Given
        let context = try await makeReceiptToggleContext(wasReceived: true)
        let store = context.store
        let detailID = context.detailID

        // When
        await store.send(\.campaigns.path[id: detailID].detail.view.receiptToggleTapped, "O1")

        // Then
        await assertReceiptToggleSynced(context)
        #expect(context.saved.value.map(\.paymentReceiptStatus) == [.pending])
    }
}

// MARK: - Nested Types

private extension CampaignIntegrationTests {

    /// 收款測試準備好的根 store、詳情 id 與獨立預期值
    struct ReceiptToggleContext {

        /// 已推入詳情且覆寫訂單寫入的根 store
        let store: TestStoreOf<RootFeature>

        /// 目前詳情的堆疊識別值
        let detailID: StackElementID

        /// 替身收到的訂單寫入紀錄
        let saved: LockIsolated<[LedgerOrder]>

        /// 切換後只改收款欄位的目標訂單
        let expected: LedgerOrder

        /// 必須保持完整原值的其他訂單
        let other: LedgerOrder

        /// 切換後全部頁面應持有的訂單投影
        let expectedOrders: [LedgerOrder]
    }
}

// MARK: - Private Method

private extension CampaignIntegrationTests {

    /// 準備列表推入詳情的根 store 與收款切換的獨立預期值
    ///
    /// - Parameter wasReceived: 切換前是否已收款
    /// - Returns: 尚未切換收款的 store、詳情 id、紀錄器與預期訂單
    /// - Throws: 找不到詳情堆疊元素時由 `try #require` 丟出
    func makeReceiptToggleContext(
        wasReceived: Bool
    ) async throws(any Error) -> ReceiptToggleContext {
        let campaign = Campaign.fixture(
            id: "C1",
            name: "四月團",
            openDate: TestDependencies.fixedNow,
            status: .ongoing
        )
        let original = Self.rebuilt(
            Self.makeOrder(id: "O1", campaign: "四月團"),
            campaignNames: ["四月團"],
            receiptStatus: wasReceived ? .received : .pending
        )
        let other = Self.makeOrder(id: "O2", campaign: "其他團")
        let expected = Self.rebuilt(
            original,
            campaignNames: ["四月團"],
            receiptStatus: wasReceived ? .pending : .received
        )
        let expectedOrders = [expected, other]
        let saved = LockIsolated<[LedgerOrder]>([])
        let initial = Self.makeRootState(campaigns: [campaign], orders: [original, other])
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                saved.withValue {
                    $0.append(order)
                }
            }
        }
        await store.send(.campaigns(.list(.view(.campaignTapped("C1")))))
        await store.receive(\.campaigns.list.delegate.requested) {
            $0.campaigns.path[id: 0] = CampaignFeatureTests.detailPath("C1", in: $0.campaigns)
        }
        let detailID = try #require(store.state.campaigns.path.ids.first)

        return ReceiptToggleContext(
            store: store,
            detailID: detailID,
            saved: saved,
            expected: expected,
            other: other,
            expectedOrders: expectedOrders
        )
    }

    /// 接收收款切換的完整委派與寫入序列，核對目標訂單、其他訂單及全部投影
    ///
    /// - Parameter context: 準備階段建立的 store 與獨立預期值
    func assertReceiptToggleSynced(_ context: ReceiptToggleContext) async {
        let store = context.store
        let detailID = context.detailID
        await store.receive(\.campaigns.path[id: detailID].detail.delegate.requested) {
            $0.campaigns.$orders.withLock {
                $0 = context.expectedOrders
            }
            $0.more.$orders.withLock {
                $0 = context.expectedOrders
            }
        }
        await store.receive(\.campaigns.delegate.receiptStatusToggled)
        await store.receive(\.orders.receiptStatusChanged)
        await store.receive(\.orders.receiptStatusChangePersisted) {
            $0.orders.orders = context.expectedOrders
            $0.dashboard.orders = context.expectedOrders
            $0.insights.orders = context.expectedOrders
        }
        await store.finish()
        #expect(context.saved.value == [context.expected])
        #expect(context.store.state.orders.orders == context.expectedOrders)
        #expect(context.store.state.more.orders == context.expectedOrders)
        #expect(context.store.state.campaigns.orders == context.expectedOrders)
        #expect(context.store.state.dashboard.orders == context.expectedOrders)
        #expect(context.store.state.insights.orders == context.expectedOrders)
        #expect(context.store.state.orders.orders[1] == context.other)
    }
}
