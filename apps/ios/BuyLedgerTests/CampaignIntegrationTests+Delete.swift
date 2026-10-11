//
//  CampaignIntegrationTests+Delete.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension CampaignIntegrationTests {

    /// 列表要求刪除並確認後，Service 刪除成功才由根功能清除訂單歸屬，其他開團與訂單維持不變
    @Test
    func campaigns_列表刪除開團並確認_清除目標歸屬且同步全部投影() async {
        // Given
        let campaign = Campaign(
            id: "C1",
            name: "四月團",
            openDate: Date(timeIntervalSince1970: 1_777_507_200),
            closeDate: nil,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let otherCampaign = Campaign(
            id: "C2",
            name: "其他團",
            openDate: Date(timeIntervalSince1970: 1_777_507_200),
            closeDate: nil,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let first = Self.makeOrder(id: "O1", campaign: "四月團")
        let second = Self.makeOrder(id: "O2", campaign: "四月團")
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
        let expectedFirst = LedgerOrder(
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
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
        let expectedSecond = LedgerOrder(
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
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
        let expectedOrders = [expectedFirst, expectedSecond, other]
        let cascade = OrdersCascadeOperations.Request.campaignDeleted("四月團")
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
            $0.campaigns.presentation.destination = .alert(
                AlertState<CampaignPresentationFeature.Destination.Alert> {
                    TextState("orders.general.label.deleteCampaign")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete("C1")) {
                        TextState("common.action.button.delete")
                    }
                    ButtonState(role: .cancel) {
                        TextState("common.action.cancel")
                    }
                } message: {
                    TextState(
                        LocalizedStringResource(
                            "campaigns.detail.message.deleteUndoneNotice",
                            defaultValue: "\("四月團")"
                        )
                    )
                }
            )
        }

        // When
        await store.send(
            .campaigns(.presentation(.destination(.presented(.alert(.confirmDelete("C1"))))))
        ) {
            $0.campaigns.presentation.destination = nil
        }

        // Then
        await store.receive(\.campaigns.presentation.delegate.deleteConfirmed, "C1") {
            $0.campaigns.$campaigns.withLock {
                $0 = [otherCampaign]
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
        await store.receive(\.campaigns.writes.deleteRequested)
        await store.receive(\.campaigns.writes.deleteResponse.success) {
            $0.orders.campaigns = [otherCampaign]
            $0.dashboard.campaigns = [otherCampaign]
            $0.insights.campaigns = [otherCampaign]
        }
        await store.receive(\.campaigns.writes.delegate.deleted)
        await store.receive(\.campaigns.delegate.campaignDeleted)
        await store.receive(\.campaigns.reminder.campaignRemoved)
        await store.receive(\.orders.cascadeRequested, cascade)
        await store.receive(\.orders.writes.cascadeRequested, cascade) {
            $0.dashboard.orders = expectedOrders
            $0.insights.orders = expectedOrders
        }
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
