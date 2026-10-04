//
//  RootFeatureTests+Campaigns.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// 列表開啟編輯並儲存改名，只替換目標團名，同筆訂單的其他歸屬與其他訂單維持不變
    @Test
    func campaigns_開團改名_同步更新多開團訂單() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: " \n三月日本團 \t",
            openDate: TestDependencies.fixedNow
        )
        let multi = Self.makeTestOrder(
            id: "T-CAMP",
            categories: ["美妝"],
            customerName: "客",
            campaignNames: ["三月日本團", "四月韓國團"]
        )
        let other = Self.makeTestOrder(
            id: "OTHER",
            categories: ["服飾"],
            customerName: "其他客",
            campaignNames: ["四月韓國團"]
        )
        let renamedMulti = Self.rebuiltOrder(multi, campaignNames: ["三月日本團 (補)", "四月韓國團"])
        let expectedOrders = [renamedMulti, other]
        var renamedCampaign = campaign
        renamedCampaign.name = "三月日本團 (補)"
        renamedCampaign.closeDate = TestDependencies.fixedNow
        let initial = CampaignIntegrationTests.makeRootState(
            campaigns: [campaign],
            orders: [multi, other]
        )
        let calls = LockIsolated<[String]>([])
        let saved = LockIsolated<[Campaign]>([])
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
            .campaigns(.destination(.presented(.edit(.binding(.set(\.draft.name, "三月日本團 (補)"))))))
        ) {
            $0.campaigns.destination?.modify(\.edit) {
                $0.draft.name = "三月日本團 (補)"
            }
        }

        // When
        await store.send(.campaigns(.destination(.presented(.edit(.view(.saveButtonTapped))))))

        // Then
        await store.receive(\.campaigns.destination.presented.edit.delegate.saveRequested) {
            $0.campaigns.destination = nil
            $0.campaigns.presentationQueue.isFormClosing = true
            $0.campaigns.$campaigns.withLock {
                $0 = [renamedCampaign]
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
            $0.orders.campaigns = [renamedCampaign]
            $0.dashboard.campaigns = [renamedCampaign]
            $0.insights.campaigns = [renamedCampaign]
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
        #expect(saved.value == [renamedCampaign])
        #expect(calls.value == ["save", "rename", " \n三月日本團 \t", "三月日本團 (補)"])
        #expect(store.state.orders.orders == expectedOrders)
        #expect(store.state.more.orders == expectedOrders)
        #expect(store.state.campaigns.orders == expectedOrders)
        #expect(store.state.dashboard.orders == expectedOrders)
        #expect(store.state.insights.orders == expectedOrders)
        #expect(store.state.orders.orders[0].campaignNames == ["三月日本團 (補)", "四月韓國團"])
        #expect(store.state.orders.orders[1] == other)
    }

    /// 列表畫面觸發 Service 載入後，訂單、總覽與分析頁拿到同一份清單
    @Test
    func campaigns_載入開團清單_同步訂單總覽與分析投影() async {
        // Given
        let loaded = [
            Campaign.fixture(id: "C1", name: "四月韓國團", openDate: TestDependencies.fixedNow),
        ]
        let fetches = LockIsolated(0)
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = {
                fetches.withValue {
                    $0 += 1
                }
                return loaded
            }
        }

        // When
        await store.send(.campaigns(.list(.view(.task)))) {
            $0.campaigns.list.isLoading = true
            $0.campaigns.list.dateContext = CampaignDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        await store.receive(\.campaigns.list.campaignsResponse.success) {
            $0.campaigns.$campaigns.withLock {
                $0 = loaded
            }
            $0.campaigns.list.isLoading = false
            $0.campaigns.list.hasLoaded = true
            $0.orders.campaigns = loaded
            $0.dashboard.campaigns = loaded
            $0.insights.campaigns = loaded
        }
        await store.finish()
        #expect(fetches.value == 1)
        #expect(store.state.orders.campaigns == loaded)
        #expect(store.state.dashboard.campaigns == loaded)
        #expect(store.state.insights.campaigns == loaded)
    }

    /// 詳情按下收款鍵後經委派寫入訂單，成功才同步所有頁面的訂單，其他訂單維持不變
    ///
    /// - Throws: 找不到已推入的詳情時由 `try #require` 丟出
    @Test
    func campaigns_切換開團收款狀態_更新所有頁面的訂單() async throws(any Error) {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "四月韓國團",
            openDate: TestDependencies.fixedNow
        )
        let order = Self.makeTestOrder(
            id: "BL-RS-TOGGLE",
            categories: ["美妝"],
            customerName: "收款測試",
            campaignNames: ["四月韓國團"]
        )
        let other = Self.makeTestOrder(id: "OTHER", category: "服飾", customerName: "其他客")
        let receivedOrder = Self.rebuiltOrder(order, paymentReceiptStatus: .received)
        let expectedOrders = [receivedOrder, other]
        let saved = LockIsolated<[LedgerOrder]>([])
        let initial = CampaignIntegrationTests.makeRootState(
            campaigns: [campaign],
            orders: [order, other]
        )
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

        // When
        await store.send(\.campaigns.path[id: detailID].detail.view.receiptToggleTapped, order.id)

        // Then
        await store.receive(\.campaigns.path[id: detailID].detail.delegate.requested) {
            $0.campaigns.$orders.withLock {
                $0 = expectedOrders
            }
            $0.more.$orders.withLock {
                $0 = expectedOrders
            }
        }
        await store.receive(\.campaigns.delegate.receiptStatusToggled)
        await store.receive(\.orders.receiptStatusChanged)
        await store.receive(\.orders.receiptStatusChangePersisted) {
            $0.orders.orders = expectedOrders
            $0.dashboard.orders = expectedOrders
            $0.insights.orders = expectedOrders
        }
        await store.finish()
        #expect(saved.value == [receivedOrder])
        #expect(store.state.orders.orders == expectedOrders)
        #expect(store.state.more.orders == expectedOrders)
        #expect(store.state.campaigns.orders == expectedOrders)
        #expect(store.state.dashboard.orders == expectedOrders)
        #expect(store.state.insights.orders == expectedOrders)
        #expect(store.state.orders.orders[1] == other)
    }
}
