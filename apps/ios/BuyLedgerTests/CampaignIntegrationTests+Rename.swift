//
//  CampaignIntegrationTests+Rename.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignIntegrationTests {

    /// 列表開啟編輯並儲存新名稱，先完成持久化改名，再由 Root 委派同步目標訂單與全部投影
    @Test
    func campaigns_列表編輯開團改名_同步目標訂單並保留其他歸屬() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "舊團",
            openDate: TestDependencies.fixedNow,
            status: .ongoing
        )
        let order1 = Self.makeOrder(id: "O1", campaign: "舊團")
        let order2 = Self.makeOrder(id: "O2", campaign: "舊團")
        let other = Self.makeOrder(id: "O3", campaign: "其他團")
        let unassigned = Self.makeOrder(id: "O4", campaign: "")
        let initialOrders = [order1, order2, other, unassigned]
        let expectedOrders = [
            Self.rebuilt(order1, campaignNames: ["新團"]),
            Self.rebuilt(order2, campaignNames: ["新團"]),
            other,
            unassigned,
        ]
        var expectedCampaign = campaign
        expectedCampaign.name = "新團"
        expectedCampaign.closeDate = TestDependencies.fixedNow
        let calls = LockIsolated<[String]>([])
        let saved = LockIsolated<[Campaign]>([])
        let initial = Self.makeRootState(campaigns: [campaign], orders: initialOrders)
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .incrementing
            $0.campaignService.saveCampaign = { campaign in
                saved.withValue {
                    $0.append(campaign)
                }
                calls.withValue {
                    $0.append("save")
                }
            }
            $0.orderService.renameOrderCampaign = { from, to in
                calls.withValue {
                    $0.append(contentsOf: ["rename", from, to])
                }
            }
        }
        await store.send(.campaigns(.list(.view(.editCampaignTapped("C1")))))
        await store.receive(\.campaigns.list.delegate.requested) {
            $0.campaigns.destination = .edit(
                CampaignEditFeature.State(
                    original: campaign,
                    link: nil,
                    id: UUID(0),
                    now: TestDependencies.fixedNow,
                    calendar: TestDependencies.fixedCalendar
                )
            )
        }
        await store.send(
            .campaigns(.destination(.presented(.edit(.binding(.set(\.draft.name, "新團"))))))
        ) {
            $0.campaigns.destination?.modify(\.edit) {
                $0.draft.name = "新團"
            }
        }

        // When
        await store.send(.campaigns(.destination(.presented(.edit(.view(.saveButtonTapped))))))

        // Then
        await store.receive(\.campaigns.destination.presented.edit.delegate.saveRequested) {
            $0.campaigns.destination = nil
            $0.campaigns.presentationQueue.isFormClosing = true
            $0.campaigns.$campaigns.withLock {
                $0 = [expectedCampaign]
            }
            $0.campaigns.$orders.withLock {
                $0 = expectedOrders
            }
            $0.more.$orders.withLock {
                $0 = expectedOrders
            }
        }
        await store.receive(\.campaigns.writes.saveRequested)
        await store.receive(\.campaigns.writes.saveResponse.success) {
            $0.orders.campaigns = [expectedCampaign]
            $0.dashboard.campaigns = [expectedCampaign]
            $0.insights.campaigns = [expectedCampaign]
        }
        await store.receive(\.campaigns.writes.renameResponse)
        await store.receive(\.campaigns.writes.delegate.renamed)
        await store.receive(\.campaigns.writes.delegate.saved)
        await store.receive(\.campaigns.delegate.campaignRenamed) {
            $0.orders.orders = expectedOrders
            $0.dashboard.orders = expectedOrders
            $0.insights.orders = expectedOrders
        }
        await store.finish()
        #expect(calls.value == ["save", "rename", "舊團", "新團"])
        #expect(saved.value == [expectedCampaign])
        #expect(store.state.orders.orders == expectedOrders)
        #expect(store.state.more.orders == expectedOrders)
        #expect(store.state.campaigns.orders == expectedOrders)
        #expect(store.state.dashboard.orders == expectedOrders)
        #expect(store.state.insights.orders == expectedOrders)
        #expect(store.state.orders.orders[2] == other)
        #expect(store.state.orders.orders[3].campaignNames == [])
    }
}
