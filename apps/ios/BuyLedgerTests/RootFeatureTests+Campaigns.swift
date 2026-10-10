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

    /// 在開團列表開啟編輯並儲存改名，只換掉目標開團的名稱；同一筆訂單的其他開團與其他訂單維持不變
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
        let cascade = OrdersCascadeOperations.Request.campaignRenamed(
            from: " \n三月日本團 \t",
            to: "三月日本團 (補)"
        )
        var initial = CampaignIntegrationTests.makeRootState(
            campaigns: [campaign],
            orders: [multi, other]
        )
        initial.campaigns.presentation.destination = .edit(
            CampaignEditFeature.State(
                original: campaign,
                link: nil,
                id: UUID(0),
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        )
        initial.campaigns.presentation.destination?.modify(\.edit) {
            $0.draft.name = "三月日本團 (補)"
        }
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

        // When
        await store.send(
            .campaigns(.presentation(.destination(.presented(.edit(.view(.saveButtonTapped))))))
        )

        // Then
        await store.receive(
            \.campaigns.presentation.destination.presented.edit.delegate.saveRequested
        ) {
            $0.campaigns.$campaigns.withLock {
                $0 = [renamedCampaign]
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
            $0.orders.campaigns = [renamedCampaign]
            $0.dashboard.campaigns = [renamedCampaign]
            $0.insights.campaigns = [renamedCampaign]
        }
        await store.receive(\.campaigns.writes.renameResponse)
        await store.receive(\.campaigns.writes.delegate.renamed)
        await store.receive(\.campaigns.writes.delegate.saved)
        await store.receive(\.campaigns.delegate.campaignRenamed)
        await store.receive(\.orders.cascadeRequested, cascade)
        await store.receive(\.orders.writes.cascadeRequested, cascade) {
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

    /// 開團列表開始載入後，訂單、總覽與分析頁都拿到同一份開團清單
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
        let loading = await store.send(.campaigns(.list(.view(.task)))) {
            $0.campaigns.list.dateContext = CampaignDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.campaigns.load.$isLoading.withLock {
                $0 = true
            }
        }

        // Then
        await loading.finish()
        await store.receive(\.campaigns.list.delegate.loadRequested) {
            $0.campaigns.$campaigns.withLock {
                $0 = loaded
            }
            $0.campaigns.load.$isLoading.withLock {
                $0 = false
            }
            $0.campaigns.load.$hasLoaded.withLock {
                $0 = true
            }
        }
        await store.receive(\.campaigns.load.loadRequested)
        await store.receive(\.campaigns.load.campaignsResponse.success) {
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

    /// 在開團詳情按下收款切換後寫入訂單；寫入成功才同步所有頁面的訂單，其他訂單維持不變
    ///
    /// - Throws: 詳情堆疊沒有元素時由 `try #require` 丟出
    @Test
    func campaigns_切換開團收款狀態_更新所有頁面的訂單() async throws {
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
        var initial = CampaignIntegrationTests.makeRootState(
            campaigns: [campaign],
            orders: [order, other]
        )
        initial.campaigns.showDetail(campaignID: "C1")
        let detailID = try #require(initial.campaigns.path.ids.first)
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
        await store.send(\.campaigns.path[id: detailID].detail.view.receiptToggleTapped, order.id)

        // Then
        await store.receive(\.campaigns.path[id: detailID].detail.delegate.requested) {
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
        await store.receive(\.campaigns.delegate.receiptStatusToggled)
        await store.receive(\.orders.receiptStatusChangeRequested)
        await store.receive(\.orders.writes.receiptToggleRequested)
        await store.receive(\.orders.writes.receiptResponse) {
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
