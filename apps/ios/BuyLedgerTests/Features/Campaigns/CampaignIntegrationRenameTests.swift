//
//  CampaignIntegrationRenameTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試，涵蓋開團改名後改寫目標訂單歸屬，並同步各頁投影
@MainActor
struct CampaignIntegrationRenameTests {

    /// 驗證列表編輯開團並儲存新名稱後，由根功能改寫目標訂單的歸屬，其他訂單的歸屬保持不變，各頁投影同步
    @Test
    func campaigns_列表編輯開團改名_同步目標訂單並保留其他歸屬() async {
        // Given
        let campaign = Campaign(
            id: "C1",
            name: "舊團",
            openDate: Date(timeIntervalSince1970: 1_777_507_200),
            closeDate: nil,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let order1 = CampaignIntegrationTestSupport.makeOrder(id: "O1", campaign: "舊團")
        let order2 = CampaignIntegrationTestSupport.makeOrder(id: "O2", campaign: "舊團")
        let other = LedgerOrder(
            id: "O3",
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
        let unassigned = LedgerOrder(
            id: "O4",
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
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
        let initialOrders = [order1, order2, other, unassigned]
        let expectedOrder1 = CampaignIntegrationTestSupport.rebuilt(order1, campaignNames: ["新團"])
        let expectedOrder2 = CampaignIntegrationTestSupport.rebuilt(order2, campaignNames: ["新團"])
        let expectedOrders = [
            expectedOrder1,
            expectedOrder2,
            other,
            unassigned,
        ]
        var expectedCampaign = campaign
        expectedCampaign.name = "新團"
        expectedCampaign.closeDate = Date(timeIntervalSince1970: 1_777_507_200)
        let cascade = OrdersCascadeOperations.Request.campaignRenamed(from: "舊團", to: "新團")
        let calls = LockIsolated<[String]>([])
        let saved = LockIsolated<[Campaign]>([])
        var initial = CampaignIntegrationTestSupport.makeRootState(
            campaigns: [campaign],
            orders: initialOrders
        )
        var edit = CampaignEditFeature.State(
            original: campaign,
            id: UUID(0),
            currentDate: Date(timeIntervalSince1970: 1_777_507_200),
            reminderTimestamp: Date(timeIntervalSince1970: 1_777_539_600)
        )
        edit.draft.name = "新團"
        initial.campaigns.presentation.destination = .edit(edit)
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.uuid = .incrementing
            $0.campaignService.renameCampaign = { campaign, previousName in
                saved.withValue {
                    $0.append(campaign)
                }
                calls.withValue {
                    $0.append(contentsOf: ["rename", previousName, campaign.name])
                }
            }
        }

        // When
        await store.send(
            .campaigns(.presentation(.destination(.presented(.edit(.view(.saveButtonTapped))))))
        )

        // Then
        await store.receive(
            \.campaigns.presentation.destination.presented.edit.delegate.saveRequested
        ) {
            $0.campaigns.$campaigns.withLock {
                $0 = [expectedCampaign]
            }
            $0.orders.$campaigns.withLock {
                $0 = [expectedCampaign]
            }
            $0.campaigns.$orders.withLock {
                $0 = expectedOrders
            }
            $0.more.$orders.withLock {
                $0 = expectedOrders
            }
            $0.orders.$orders.withLock {
                $0 = expectedOrders
            }
        }
        await store.receive(\.campaigns.presentation.delegate.saveRequested) {
            $0.campaigns.presentation.destination = nil
            $0.campaigns.presentation.queue.isFormClosing = true
        }
        await store.receive(\.campaigns.writes.saveRequested)
        await store.receive(\.campaigns.writes.saveResponse.success) {
            $0.dashboard.campaigns = [expectedCampaign]
            $0.insights.campaigns = [expectedCampaign]
        }
        await store.receive(\.campaigns.writes.delegate.renamed)
        await store.receive(\.campaigns.writes.delegate.saved)
        await store.receive(\.campaigns.delegate.campaignRenamed)
        await store.receive(\.orders.rootRequest.cascade, cascade)
        await store.receive(\.orders.writes.cascadeRequested, cascade) {
            $0.dashboard.orders = expectedOrders
            $0.insights.orders = expectedOrders
        }
        await store.finish()
        #expect(calls.value == ["rename", "舊團", "新團"])
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
