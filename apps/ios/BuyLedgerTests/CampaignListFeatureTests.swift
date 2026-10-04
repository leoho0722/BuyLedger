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

/// 開團列表的載入、重試、日期投影與使用者請求測試
@MainActor
struct CampaignListFeatureTests {

    /// 載入失敗只更新列表訊息，不改共用開團，也不送出通知請求
    @Test
    func task_開團載入失敗_保留共用清單並呈現列表錯誤() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "既有團",
            closeDate: nil,
            status: .ongoing
        )
        let failingFetch: CampaignService.FetchCampaigns = {
            throw .fetchFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: Self.makeState(campaigns: [campaign])) {
            CampaignListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = failingFetch
        }

        // When
        await store.send(.view(.task)) {
            $0.dateContext = CampaignDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.isLoading = true
        }

        // Then
        await store.receive(\.campaignsResponse.failure) {
            $0.isLoading = false
            $0.errorMessage = "開團載入失敗，請稍後再試。"
        }
        await store.finish()
        #expect(store.state.campaigns == [campaign])
        #expect(store.state.loadState == .failed("開團載入失敗，請稍後再試。"))
    }

    /// 使用者重試時即使已載入，也重新讀取並清除舊錯誤
    @Test
    func retryTapped_已載入列表點重試_重新載入並更新日期脈絡() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "新資料",
            closeDate: nil,
            status: .ongoing
        )
        var initial = Self.makeState()
        initial.hasLoaded = true
        initial.errorMessage = "舊錯誤"
        let calls = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            CampaignListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = {
                calls.withValue {
                    $0 += 1
                }
                return [campaign]
            }
        }

        // When
        await store.send(.view(.retryTapped)) {
            $0.dateContext = CampaignDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.isLoading = true
            $0.errorMessage = nil
        }

        // Then
        await store.receive(\.campaignsResponse.success) {
            $0.isLoading = false
            $0.$campaigns.withLock {
                $0 = [campaign]
            }
        }
        #expect(calls.value == 1)
        #expect(store.state.loadState == .loaded)
    }

    /// 載入失敗後重試會先清除錯誤，成功回應讓列表離開失敗狀態
    @Test
    func retryTapped_載入失敗後點重試_清除錯誤並重新載入成功() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "重試團",
            closeDate: nil,
            status: .ongoing
        )
        var initial = Self.makeState()
        initial.errorMessage = "開團載入失敗，請稍後再試。"
        let calls = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            CampaignListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = {
                calls.withValue {
                    $0 += 1
                }
                return [campaign]
            }
        }

        // When
        await store.send(.view(.retryTapped)) {
            $0.dateContext = CampaignDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.isLoading = true
            $0.errorMessage = nil
        }

        // Then
        await store.receive(\.campaignsResponse.success) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.$campaigns.withLock {
                $0 = [campaign]
            }
        }
        #expect(calls.value == 1)
        #expect(store.state.loadState == .loaded)
    }

    /// 列表正在載入時執行外觀任務，更新日期脈絡並重新讀取開團
    @Test
    func task_正在載入時重複請求_更新日期脈絡並重新讀取() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "外觀任務團",
            closeDate: nil,
            status: .ongoing
        )
        var initial = Self.makeState()
        initial.isLoading = true
        let calls = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            CampaignListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = {
                calls.withValue {
                    $0 += 1
                }
                return [campaign]
            }
        }

        // When
        await store.send(.view(.task)) {
            $0.dateContext = CampaignDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.isLoading = true
        }

        // Then
        await store.receive(\.campaignsResponse) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.$campaigns.withLock {
                $0 = [campaign]
            }
        }
        await store.finish()
        #expect(calls.value == 1)
        #expect(store.state.loadState == .loaded)
    }

    /// 列表正在載入時點選重試，更新日期脈絡並重新讀取開團
    @Test
    func retryTapped_正在載入時重複請求_更新日期脈絡並重新讀取() async {
        // Given
        let campaign = Campaign.fixture(
            id: "C1",
            name: "重試團",
            closeDate: nil,
            status: .ongoing
        )
        var initial = Self.makeState()
        initial.isLoading = true
        let calls = LockIsolated(0)
        let store = TestStore(initialState: initial) {
            CampaignListFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = {
                calls.withValue {
                    $0 += 1
                }
                return [campaign]
            }
        }

        // When
        await store.send(.view(.retryTapped)) {
            $0.dateContext = CampaignDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.isLoading = true
        }

        // Then
        await store.receive(\.campaignsResponse) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.$campaigns.withLock {
                $0 = [campaign]
            }
        }
        await store.finish()
        #expect(calls.value == 1)
        #expect(store.state.loadState == .loaded)
    }
}

// MARK: - Internal Method

extension CampaignListFeatureTests {

    /// 建立列表的可寫開團與唯讀訂單共享資料
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
            campaigns: Shared(value: campaigns),
            orders: SharedReader(value: orders)
        )
    }
}
