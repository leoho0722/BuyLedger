//
//  CampaignFeatureTests+Navigation.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension CampaignFeatureTests {

    /// 指定開團存在時，詳情以共用資料推入堆疊，成為唯一的詳情
    ///
    /// - Throws: 堆疊沒有詳情時由 `try #require` 丟出
    @Test
    func showDetail_開團存在_推入指向該團的詳情() throws(any Error) {
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

    /// 找不到指定開團時堆疊維持原樣，不清空也不推入
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

    /// 堆疊已有詳情時，推入另一個開團會取代它，堆疊只剩新的詳情
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

    /// 列表點擊開團走請求流程推入詳情，得到的堆疊與深連結直接推入的相同
    @Test
    func list_點選開團_推入與深連結相同的詳情堆疊() async {
        // Given
        let campaign = Campaign.fixture(id: "C1", name: "團")
        let initial = CampaignFeature.State()
        initial.$campaigns.withLock {
            $0 = [campaign]
        }
        var deepLinked = initial
        deepLinked.showDetail(campaignID: "C1")
        let expectedContents = deepLinked.path.map { $0.detail?.content }
        let store = TestStore(initialState: initial) {
            CampaignFeature()
        }

        // When
        await store.send(.list(.view(.campaignTapped("C1"))))

        // Then
        await store.receive(\.list.delegate.requested) {
            // 前置的 showDetail 已先配走 #0
            $0.path[id: 1] = Self.detailPath("C1", in: $0)
        }
        #expect(store.state.path.map { $0.detail?.content } == expectedContents)
    }

    /// 刪除成功時從堆疊移除該開團的詳情
    @Test
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

    /// 刪除的是其他開團時，目前顯示的詳情維持不動
    @Test
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

private extension CampaignFeatureTests {

    /// 建立只含刪除結果的寫入回報，沒有提醒事件
    ///
    /// - Parameter id: 已刪除的開團識別值
    /// - Returns: 名稱固定為「已刪團」的刪除結果
    static func deletion(id: Campaign.ID) -> CampaignWritesFeature.Deletion {
        CampaignWritesFeature.Deletion(id: id, name: "已刪團", eventIdentifier: nil)
    }
}
