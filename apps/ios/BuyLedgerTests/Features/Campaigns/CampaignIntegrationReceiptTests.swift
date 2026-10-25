//
//  CampaignIntegrationReceiptTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試，涵蓋從開團詳情切換收款狀態後，同步各頁投影且只寫入目標訂單
@MainActor
struct CampaignIntegrationReceiptTests {

    /// 驗證未收款訂單從詳情改為已收款時，全部投影同步，且只寫入該訂單一次，其他訂單保持不變
    ///
    /// - Throws: 找不到詳情堆疊元素時由 `try #require` 丟出
    @Test
    func campaigns_未收款改為已收款_同步全部投影且只寫目標訂單() async throws {
        // Given
        let context = try makeReceiptToggleContext(isReceivedBeforeToggle: false)
        let store = context.store
        let detailID = context.detailID

        // When
        await store.send(\.campaigns.path[id: detailID].detail.view.receiptToggleTapped, "O1")

        // Then
        await assertReceiptToggleSynced(context)
        #expect(context.saved.value.map(\.paymentReceiptStatus) == [.received])
    }

    /// 驗證已收款訂單從詳情改回未收款時，全部投影同步，且只寫入該訂單一次，其他訂單保持不變
    ///
    /// - Throws: 找不到詳情堆疊元素時由 `try #require` 丟出
    @Test
    func campaigns_已收款改回未收款_同步全部投影且只寫目標訂單() async throws {
        // Given
        let context = try makeReceiptToggleContext(isReceivedBeforeToggle: true)
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

private extension CampaignIntegrationReceiptTests {

    /// 收款測試準備好的根功能 `TestStore`、詳情的 `detailID` 與獨立預期值
    struct ReceiptToggleContext {

        /// 已推入詳情且覆寫訂單寫入的根功能 `TestStore`
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

private extension CampaignIntegrationReceiptTests {

    /// 準備已推入詳情的根功能 `TestStore` 與收款切換的獨立預期值
    ///
    /// - Parameter isReceivedBeforeToggle: 切換前是否已收款
    /// - Returns: 尚未切換收款的 `TestStore`、詳情的 `detailID`、紀錄器與預期訂單
    /// - Throws: 找不到詳情堆疊元素時由 `try #require` 丟出
    func makeReceiptToggleContext(isReceivedBeforeToggle: Bool) throws -> ReceiptToggleContext {
        let campaign = Campaign.fixture(
            id: "C1",
            name: "四月團",
            openDate: TestDependencies.fixedNow,
            status: .ongoing
        )
        let original = CampaignIntegrationTestSupport.rebuilt(
            CampaignIntegrationTestSupport.makeOrder(id: "O1", campaign: "四月團"),
            campaignNames: ["四月團"],
            receiptStatus: isReceivedBeforeToggle ? .received : .pending
        )
        let other = LedgerOrder(
            id: "O2",
            customer: LedgerCustomer(name: "客戶", initials: "XX", tier: .regular),
            status: .confirmed,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_507_200),
            items: [
                LedgerOrderItem(
                    id: UUID(0),
                    name: "item",
                    quantity: 1,
                    unitPrice: 0
                ),
            ],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 100,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            categories: [],
            paymentMethod: "",
            notes: "",
            reconciliationStatus: "",
            campaignNames: ["其他團"],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
        let expected = LedgerOrder(
            id: "O1",
            customer: LedgerCustomer(name: "客戶", initials: "XX", tier: .regular),
            status: .confirmed,
            currency: .twd,
            date: Date(timeIntervalSince1970: 1_777_507_200),
            items: [
                LedgerOrderItem(
                    id: UUID(0),
                    name: "item",
                    quantity: 1,
                    unitPrice: 0
                ),
            ],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 100,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            categories: [],
            paymentMethod: "",
            notes: "",
            reconciliationStatus: "",
            campaignNames: ["四月團"],
            paymentReceiptStatus: isReceivedBeforeToggle ? .pending : .received,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
        let expectedOrders = [expected, other]
        let saved = LockIsolated<[LedgerOrder]>([])
        var initial = CampaignIntegrationTestSupport.makeRootState(
            campaigns: [campaign],
            orders: [original, other]
        )
        initial.campaigns.showDetail(campaignID: "C1")
        let detailID = try #require(initial.campaigns.path.ids.first)
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

        return ReceiptToggleContext(
            store: store,
            detailID: detailID,
            saved: saved,
            expected: expected,
            other: other,
            expectedOrders: expectedOrders
        )
    }

    /// 接收收款切換從詳情到寫入訂單的完整序列，核對目標訂單、其他訂單及全部投影
    ///
    /// - Parameter context: 準備階段建立的 `TestStore` 與獨立預期值
    func assertReceiptToggleSynced(_ context: ReceiptToggleContext) async {
        let store = context.store
        let detailID = context.detailID
        await store.receive(\.campaigns.path[id: detailID].detail.delegate.requested) {
            $0.orders.$orders.withLock {
                $0 = context.expectedOrders
            }
            $0.campaigns.$orders.withLock {
                $0 = context.expectedOrders
            }
            $0.more.$orders.withLock {
                $0 = context.expectedOrders
            }
        }
        await store.receive(\.campaigns.delegate.receiptStatusToggled)
        await store.receive(\.orders.rootRequest.receiptStatusChange)
        await store.receive(\.orders.writes.receiptToggleRequested)
        await store.receive(\.orders.writes.receiptResponse) {
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
