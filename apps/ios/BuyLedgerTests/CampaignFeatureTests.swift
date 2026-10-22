//
//  CampaignFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// 以 `TestStore` 逐步驗證 `CampaignFeature` 的狀態轉換與副作用
@MainActor
struct CampaignFeatureTests {

    /// 容器收到變更狀態請求時先寫入，成功後才更新清單
    @Test
    func list_要求變更開團狀態_寫入後更新清單狀態() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "團",
            closeDate: nil,
            status: .ongoing
        )
        let initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }

        let savedCampaigns = LockIsolated<[Campaign]>([])
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.campaignService.saveCampaign = { savedCampaign in
                savedCampaigns.withValue {
                    $0.append(savedCampaign)
                }
            }
        }

        // When
        await store.send(.list(.delegate(.requested(.changeStatus(id: "C1", status: .closed)))))

        // Then
        await store.receive(\.writes.statusChangeRequested) {
            $0.$campaigns.withLock {
                $0[0].status = .closed
            }
        }
        await store.receive(\.writes.statusResponse.success)
        await store.finish()
        var expectedCampaign = campaign
        expectedCampaign.status = .closed
        #expect(savedCampaigns.value == [expectedCampaign])
    }

    /// 未結算的開團按下結團時，先呈現點明無法改回的確認對話框，不直接寫入
    @Test
    func list_要求結團_呈現結團確認() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "團",
            closeDate: nil,
            status: .closed
        )
        let initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.list(.delegate(.requested(.settle("C1"))))) {
            $0.presentation.destination = Self.settleAlert(id: "C1", name: "團")
        }

        // Then
        #expect(store.state.presentation.destination == Self.settleAlert(id: "C1", name: "團"))
    }

    /// 點選刪除開團時，呈現包含資料影響說明的確認對話框
    @Test
    func list_清單中的開團要求刪除_呈現刪除確認() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "團",
            closeDate: nil,
            status: .ongoing
        )
        let initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.list(.view(.deleteCampaignTapped("C1"))))

        // Then
        await store.receive(\.list.delegate.requested) {
            $0.presentation.destination = Self.deletionAlert(id: "C1", name: "團")
        }
        #expect(store.state.presentation.destination == Self.deletionAlert(id: "C1", name: "團"))
    }

    /// 容器收到切換收款請求時只送出 `delegate`，不直接修改 `State.orders`
    @Test
    func list_要求切換收款狀態_送出委派且不改本地狀態() async {
        // Given
        let order = LedgerOrder.fixture(id: "O1", campaignNames: ["四月團"])
        let initial = CampaignFeature.State()
        initial.$orders.withLock {
            $0 = [order]
        }

        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(
            .list(.delegate(.requested(.toggleReceipt(orderID: "O1", status: .received))))
        )

        // Then
        await store.receive(\.delegate.receiptStatusToggled)
        #expect(store.state.orders == [order])
    }
}
