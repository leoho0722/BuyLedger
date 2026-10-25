//
//  RootFeatureCampaignsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試，以 TestStore 驗證開團更新、改名、載入與收款切換時，訂單與各頁投影如何同步
@MainActor
struct RootFeatureCampaignsTests {

    /// 驗證 Root 更新開團後，清單先前取得的共享引用仍讀到新的開團，不必重新取得
    @Test
    func campaigns_根功能更新開團_既有清單引用讀到新值() async {
        // Given
        let campaign = Campaign.fixture(id: "C1", name: "更新團", openDate: TestDependencies.fixedNow)
        let initial = RootFeatureTestSupport.makeIsolatedRootState()
        let listCampaigns = initial.orders.list.$campaigns
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.campaigns(.load(.campaignsResponse(.success([campaign]))))) {
            $0.campaigns.$campaigns.withLock {
                $0 = [campaign]
            }
            $0.campaigns.load.$hasLoaded.withLock {
                $0 = true
            }
            $0.orders.$campaigns.withLock {
                $0 = [campaign]
            }
            $0.dashboard.campaigns = [campaign]
            $0.insights.campaigns = [campaign]
        }

        // Then
        await store.finish()
        #expect(store.state.orders.campaigns == [campaign])
        #expect(store.state.orders.list.campaigns == [campaign])
        #expect(listCampaigns.wrappedValue == [campaign])
    }

    /// 驗證在開團列表編輯並儲存改名時，訂單上的目標開團名稱換成新名稱，其餘開團與其他訂單維持不變，舊名稱前後的空白與換行不影響比對
    @Test
    func campaigns_開團改名_同步更新多開團訂單() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: " \n三月日本團 \t",
            openDate: TestDependencies.fixedNow
        )
        let multi = RootFeatureTestSupport.makeTestOrder(
            id: "T-CAMP",
            categories: ["美妝"],
            customerName: "客",
            campaignNames: ["三月日本團", "四月韓國團"]
        )
        let other = RootFeatureTestSupport.makeTestOrder(
            id: "OTHER",
            categories: ["服飾"],
            customerName: "其他客",
            campaignNames: ["四月韓國團"]
        )
        let renamedMulti = RootFeatureTestSupport.rebuiltOrder(
            multi,
            campaignNames: ["三月日本團 (補)", "四月韓國團"]
        )
        let expectedOrders = [renamedMulti, other]
        var renamedCampaign = campaign
        renamedCampaign.name = "三月日本團 (補)"
        renamedCampaign.closeDate = TestDependencies.fixedNow
        let cascade = OrdersCascadeOperations.Request.campaignRenamed(
            from: " \n三月日本團 \t",
            to: "三月日本團 (補)"
        )
        var initial = CampaignIntegrationTestSupport.makeRootState(
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
                $0 = [renamedCampaign]
            }
            $0.orders.$campaigns.withLock {
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
            $0.dashboard.campaigns = [renamedCampaign]
            $0.insights.campaigns = [renamedCampaign]
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
        #expect(saved.value == [renamedCampaign])
        #expect(calls.value == ["rename", " \n三月日本團 \t", "三月日本團 (補)"])
        #expect(store.state.orders.orders == expectedOrders)
        #expect(store.state.more.orders == expectedOrders)
        #expect(store.state.campaigns.orders == expectedOrders)
        #expect(store.state.dashboard.orders == expectedOrders)
        #expect(store.state.insights.orders == expectedOrders)
        #expect(store.state.orders.orders[0].campaignNames == ["三月日本團 (補)", "四月韓國團"])
        #expect(store.state.orders.orders[1] == other)
    }

    /// 驗證開團列表開始載入時，開團只向服務抓取一次，訂單、總覽與分析頁都拿到同一份開團清單
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
            $0.orders.$campaigns.withLock {
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
            $0.dashboard.campaigns = loaded
            $0.insights.campaigns = loaded
        }
        await store.finish()
        #expect(fetches.value == 1)
        #expect(store.state.orders.campaigns == loaded)
        #expect(store.state.dashboard.campaigns == loaded)
        #expect(store.state.insights.campaigns == loaded)
    }

    /// 驗證在開團詳情切換收款狀態時，訂單在開團、更多與訂單頁立即變為已收款，寫入回應後總覽與分析才更新，其他訂單維持不變
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
        let order = RootFeatureTestSupport.makeTestOrder(
            id: "BL-RS-TOGGLE",
            categories: ["美妝"],
            customerName: "收款測試",
            campaignNames: ["四月韓國團"]
        )
        let other = RootFeatureTestSupport.makeTestOrder(
            id: "OTHER",
            category: "服飾",
            customerName: "其他客"
        )
        let receivedOrder = RootFeatureTestSupport.rebuiltOrder(
            order,
            paymentReceiptStatus: .received
        )
        let expectedOrders = [receivedOrder, other]
        let saved = LockIsolated<[LedgerOrder]>([])
        var initial = CampaignIntegrationTestSupport.makeRootState(
            campaigns: [campaign],
            orders: [order, other]
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
        await store.receive(\.orders.rootRequest.receiptStatusChange)
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
