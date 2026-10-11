//
//  CampaignListFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 開團列表的日期投影與使用者請求測試
@MainActor
struct CampaignListFeatureTests {

    /// 列表出現時更新日期脈絡，並把載入需求交給容器
    @Test
    func task_列表出現_更新日期脈絡並委派載入() async {
        // Given
        let store = TestStore(initialState: Self.makeState()) {
            CampaignListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.task)) {
            $0.dateContext = CampaignDateContext(
                now: Date(timeIntervalSince1970: 1_777_507_200),
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        await store.receive(\.delegate.loadRequested)
        await store.finish()
        #expect(store.state.hasLoaded == false)
        #expect(store.state.isLoading == false)
    }

    /// 重試只更新日期脈絡並發出載入需求，錯誤由載入子層清除
    @Test
    func retryTapped_載入失敗_委派載入並保留唯讀錯誤() async {
        // Given
        let initial = Self.makeState()
        initial.$errorMessage = SharedReader(value: "campaigns.list.message.campaignsLoadedTry")
        let store = TestStore(initialState: initial) {
            CampaignListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.view(.retryTapped)) {
            $0.dateContext = CampaignDateContext(
                now: Date(timeIntervalSince1970: 1_777_507_200),
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        await store.receive(\.delegate.loadRequested)
        await store.finish()
        #expect(store.state.loadState == .failed("campaigns.list.message.campaignsLoadedTry"))
    }
}

// MARK: - Internal Method

extension CampaignListFeatureTests {

    /// 建立列表的唯讀開團與訂單共享資料
    ///
    /// - Parameters:
    ///   - campaigns: 初始開團清單
    ///   - orders: 初始訂單投影
    /// - Returns: 尚未載入的列表狀態
    static func makeState(
        campaigns: [Campaign] = [],
        orders: [LedgerOrder] = []
    ) -> CampaignListFeature.State {
        CampaignListFeature.State(
            campaigns: SharedReader(value: campaigns),
            orders: SharedReader(value: orders)
        )
    }
}
