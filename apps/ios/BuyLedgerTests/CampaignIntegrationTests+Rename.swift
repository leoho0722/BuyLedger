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

    /// 列表開啟編輯並儲存新名稱，先存好新名稱，再改寫目標訂單的歸屬，並由根功能同步全部投影
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
        let order1 = Self.makeOrder(id: "O1", campaign: "舊團")
        let order2 = Self.makeOrder(id: "O2", campaign: "舊團")
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
        let expectedOrder1 = LedgerOrder(
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
            campaignNames: ["新團"],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
        let expectedOrder2 = LedgerOrder(
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
            campaignNames: ["新團"],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
        let expectedOrders = [
            expectedOrder1,
            expectedOrder2,
            other,
            unassigned,
        ]
        let expectedCampaign = Campaign(
            id: "C1",
            name: "新團",
            openDate: Date(timeIntervalSince1970: 1_777_507_200),
            closeDate: Date(timeIntervalSince1970: 1_777_507_200),
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let cascade = OrdersCascadeOperations.Request.campaignRenamed(from: "舊團", to: "新團")
        let calls = LockIsolated<[String]>([])
        let saved = LockIsolated<[Campaign]>([])
        let initial = Self.makeRootState(campaigns: [campaign], orders: initialOrders)
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
        await store.send(.campaigns(.list(.view(.editCampaignTapped("C1")))))
        await store.receive(\.campaigns.list.delegate.requested) {
            $0.campaigns.presentation.destination = .edit(
                CampaignEditFeature.State(
                    original: campaign,
                    link: nil,
                    id: UUID(0),
                    now: Date(timeIntervalSince1970: 1_777_507_200),
                    calendar: TestDependencies.fixedCalendar
                )
            )
        }
        await store.send(
            .campaigns(
                .presentation(.destination(.presented(.edit(.binding(.set(\.draftName, "新團"))))))
            )
        ) {
            $0.campaigns.presentation.destination?.modify(\.edit) {
                $0.draft.name = "新團"
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
            $0.orders.campaigns = [expectedCampaign]
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
