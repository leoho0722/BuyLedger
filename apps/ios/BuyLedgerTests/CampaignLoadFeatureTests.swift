//
//  CampaignLoadFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 開團載入、錯誤恢復與自動結單的測試
@MainActor
struct CampaignLoadFeatureTests {

    /// 載入成功後更新共用清單與載入旗標
    @Test
    func loadRequested_讀取成功_共用清單與載入狀態更新() async {
        // Given
        let campaign = Campaign(
            id: "C1",
            name: "測試開團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: nil,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let store = TestStore(initialState: Self.makeState()) {
            CampaignLoadFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = {
                [campaign]
            }
        }

        // When
        await store.send(.loadRequested) {
            $0.$isLoading.withLock {
                $0 = true
            }
        }

        // Then
        await store.receive(\.campaignsResponse.success) {
            $0.$isLoading.withLock {
                $0 = false
            }
            $0.$hasLoaded.withLock {
                $0 = true
            }
            $0.$campaigns.withLock {
                $0 = [campaign]
            }
        }
        await store.finish()
        #expect(store.state.campaigns == [campaign])
    }

    /// 載入失敗保留資料，旗標允許下次重試並向容器回報
    @Test
    func loadRequested_讀取失敗_保留共用清單並委派錯誤() async {
        // Given
        let campaign = Campaign(
            id: "C1",
            name: "測試開團",
            openDate: Date(timeIntervalSince1970: 1_775_001_600),
            closeDate: nil,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let failingFetch: CampaignService.FetchCampaigns = {
            throw .fetchFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: Self.makeState(campaigns: [campaign])) {
            CampaignLoadFeature()
        } withDependencies: {
            $0.campaignService.fetchCampaigns = failingFetch
        }

        // When
        await store.send(.loadRequested) {
            $0.$campaigns.withLock {
                $0 = [campaign]
            }
            $0.$isLoading.withLock {
                $0 = true
            }
        }

        // Then
        await store.receive(\.campaignsResponse.failure) {
            $0.$isLoading.withLock {
                $0 = false
            }
            $0.$errorMessage.withLock {
                $0 = "開團載入失敗，請稍後再試。"
            }
        }
        await store.receive(\.delegate.loadFailed)
        await store.finish()
        #expect(store.state.campaigns == [campaign])
        #expect(store.state.hasLoaded == false)
        #expect(store.state.isLoading == false)
    }

    /// 成功載入後重複請求不再呼叫讀取服務
    @Test
    func loadRequested_已載入_略過讀取() async {
        // Given
        let initial = Self.makeState()
        initial.$hasLoaded.withLock {
            $0 = true
        }
        let store = TestStore(initialState: initial) {
            CampaignLoadFeature()
        }

        // When
        await store.send(.loadRequested)

        // Then
        await store.finish()
        #expect(store.state.hasLoaded)
        #expect(store.state.isLoading == false)
    }
}

// MARK: - Internal Method

extension CampaignLoadFeatureTests {

    /// 建立獨立的開團共用資料
    ///
    /// - Parameter campaigns: 初始開團
    /// - Returns: 尚未開始載入的狀態
    static func makeState(campaigns: [Campaign] = []) -> CampaignLoadFeature.State {
        let shared = Shared<[Campaign]>(value: [])
        shared.withLock {
            $0 = campaigns
        }
        return CampaignLoadFeature.State(campaigns: shared)
    }
}
