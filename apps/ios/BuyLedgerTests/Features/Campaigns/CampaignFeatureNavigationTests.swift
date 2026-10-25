//
//  CampaignFeatureNavigationTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `CampaignFeature` 的單元測試，涵蓋開團詳情推入堆疊與刪除後移除對應詳情
struct CampaignFeatureNavigationTests {

    /// 驗證指定開團存在時，堆疊只推入一筆指向該團的詳情，內容取自共用的開團資料
    ///
    /// - Throws: 堆疊沒有詳情時由 `try #require` 丟出
    @Test
    func showDetail_開團存在_推入指向該團的詳情() throws {
        // Given
        let campaign = Campaign.fixture(id: "C1", name: "團")
        var state = CampaignFeature.State()
        state.$campaigns.withLock {
            $0 = [campaign]
        }

        // When
        state.showDetail(campaignID: "C1")

        // Then
        #expect(state.path.count == 1)
        let detail = try #require(state.path.first?.detail)
        #expect(detail.campaignID == "C1")
        #expect(detail.content?.campaign == campaign)
    }

    /// 驗證指定開團不存在時，堆疊維持原樣，已開的詳情不清空也不換成新的
    @Test
    func showDetail_開團不存在_堆疊維持不動() {
        // Given
        let campaign = Campaign.fixture(id: "C1", name: "團")
        var state = CampaignFeature.State()
        state.$campaigns.withLock {
            $0 = [campaign]
        }
        state.showDetail(campaignID: "C1")
        let idsBefore = state.path.ids

        // When
        state.showDetail(campaignID: "missing")

        // Then
        #expect(state.path.ids == idsBefore)
        #expect(state.path.first?.detail?.campaignID == "C1")
    }

    /// 驗證堆疊已有詳情時，推入另一個開團會取代原詳情，堆疊只剩新的一筆
    @Test
    func showDetail_堆疊已有詳情_換成新的唯一詳情() {
        // Given
        let first = Campaign.fixture(id: "A", name: "甲團")
        let second = Campaign.fixture(id: "B", name: "乙團")
        var state = CampaignFeature.State()
        state.$campaigns.withLock {
            $0 = [first, second]
        }
        state.showDetail(campaignID: "A")
        let firstID = state.path.ids.first

        // When
        state.showDetail(campaignID: "B")

        // Then
        #expect(state.path.count == 1)
        #expect(state.path.first?.detail?.campaignID == "B")
        #expect(state.path.ids.first != firstID)
    }

    /// 驗證點選列表中的 C1 開團後，只推入一筆詳情，詳情的開團識別值與內容都對應 C1
    @Test
    @MainActor
    func list_點選開團_推入對應開團的唯一詳情() async {
        // Given
        let campaign = Campaign.fixture(id: "C1", name: "團")
        let initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.list(.view(.campaignTapped("C1"))))

        // Then
        await store.receive(\.list.delegate.requested) {
            $0.path[id: 0] = CampaignFeatureTestSupport.detailPath("C1", in: initial)
        }
        #expect(store.state.path.count == 1)
        #expect(store.state.path.first?.detail?.campaignID == "C1")
        #expect(store.state.path.first?.detail?.content?.campaign == campaign)
    }

    /// 驗證刪除成功時，堆疊移除該開團詳情，依序回報開團已刪除，並將刪除結果交給提醒流程
    @Test
    @MainActor
    func writes_刪除成功_移除對應詳情() async {
        // Given
        let campaign = Campaign.fixture(id: "C1", name: "團")
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        initial.showDetail(campaignID: "C1")
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.writes(.delegate(.deleted(Self.deletion(id: "C1"))))) {
            $0.path.removeAll()
        }

        // Then
        await store.receive(\.delegate.campaignDeleted)
        await store.receive(\.reminder.campaignRemoved)
        #expect(store.state.path.isEmpty)
    }

    /// 驗證刪除的是其他開團時，目前顯示的詳情維持不變，刪除通知照常送出
    @Test
    @MainActor
    func writes_刪除其他開團_保留目前詳情() async {
        // Given
        let shown = Campaign.fixture(id: "A", name: "甲團")
        var initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [shown]
        }
        initial.showDetail(campaignID: "A")
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.writes(.delegate(.deleted(Self.deletion(id: "B")))))

        // Then
        await store.receive(\.delegate.campaignDeleted)
        await store.receive(\.reminder.campaignRemoved)
        #expect(store.state.path.first?.detail?.campaignID == "A")
    }
}

// MARK: - Private Method

private extension CampaignFeatureNavigationTests {

    /// 建立沒有提醒事件的刪除結果
    ///
    /// - Parameter id: 已刪除的開團識別值
    /// - Returns: 名稱固定為「已刪團」的刪除結果
    static func deletion(id: Campaign.ID) -> CampaignWritesFeature.Deletion {
        CampaignWritesFeature.Deletion(id: id, name: "已刪團", eventIdentifier: nil)
    }
}
