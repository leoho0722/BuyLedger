//
//  CampaignIntegrationTests+Delete.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension CampaignIntegrationTests {

    /// 列表要求刪除並確認後，Service 刪除成功才由 Root 清除訂單歸屬，其他開團與訂單維持不變
    @Test
    func campaigns_列表刪除開團並確認_清除目標歸屬且同步全部投影() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "四月團",
            openDate: TestDependencies.fixedNow,
            status: .ongoing
        )
        let otherCampaign = Campaign.fixture(
            id: "C2",
            name: "其他團",
            openDate: TestDependencies.fixedNow,
            status: .ongoing
        )
        let first = Self.makeOrder(id: "O1", campaign: "四月團")
        let second = Self.makeOrder(id: "O2", campaign: "四月團")
        let other = Self.makeOrder(id: "O3", campaign: "其他團")
        let expectedOrders = [
            Self.rebuilt(first, campaignNames: []),
            Self.rebuilt(second, campaignNames: []),
            other,
        ]
        let calls = LockIsolated<[String]>([])
        let initial = Self.makeRootState(
            campaigns: [campaign, otherCampaign],
            orders: [first, second, other]
        )
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.campaignService.removeCampaign = { id, name in
                calls.withValue {
                    $0.append(contentsOf: [id, name])
                }
                return nil
            }
        }
        await store.send(.campaigns(.list(.view(.deleteCampaignTapped("C1")))))
        await store.receive(\.campaigns.list.delegate.requested) {
            $0.campaigns.destination = CampaignFeatureTests.deletionAlert(id: "C1", name: "四月團")
        }

        // When
        await store.send(.campaigns(.destination(.presented(.alert(.confirmDelete("C1")))))) {
            $0.campaigns.destination = nil
        }

        // Then
        await store.receive(\.campaigns.writes.deleteRequested) {
            $0.campaigns.$campaigns.withLock {
                $0 = [otherCampaign]
            }
            $0.campaigns.$orders.withLock {
                $0 = expectedOrders
            }
            $0.more.$orders.withLock {
                $0 = expectedOrders
            }
        }
        await store.receive(\.campaigns.writes.deleteResponse.success) {
            $0.orders.campaigns = [otherCampaign]
            $0.dashboard.campaigns = [otherCampaign]
            $0.insights.campaigns = [otherCampaign]
        }
        await store.receive(\.campaigns.writes.delegate.deleted)
        await store.receive(\.campaigns.delegate.campaignDeleted) {
            $0.orders.orders = expectedOrders
            $0.dashboard.orders = expectedOrders
            $0.insights.orders = expectedOrders
        }
        await store.receive(\.campaigns.reminder.campaignRemoved)
        await store.finish()
        #expect(calls.value == ["C1", "四月團"])
        #expect(store.state.campaigns.campaigns == [otherCampaign])
        #expect(store.state.orders.orders == expectedOrders)
        #expect(store.state.more.orders == expectedOrders)
        #expect(store.state.campaigns.orders == expectedOrders)
        #expect(store.state.dashboard.orders == expectedOrders)
        #expect(store.state.insights.orders == expectedOrders)
        #expect(store.state.orders.orders[0].campaignNames == [])
        #expect(store.state.orders.orders[1].campaignNames == [])
        #expect(store.state.orders.orders[2] == other)
    }
}
