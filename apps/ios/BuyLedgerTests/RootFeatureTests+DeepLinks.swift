//
//  RootFeatureTests+DeepLinks.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// 總覽點選已載入的開團後，切到開團分頁並推入該團的詳情，詳情與訂單共用同一份資料
    @Test
    func dashboard_點選總覽開團_切至開團頁並推入該團詳情() async {
        // Given
        let context = await Self.makeCampaignDeepLinkContext()
        let store = context.store

        // When
        await store.send(.dashboard(.delegate(.campaignTapped("四月韓國團")))) {
            $0.selectedTab = .campaigns
            $0.campaigns.path.append(CampaignFeatureTests.detailPath("C1", in: $0.campaigns))
        }

        // Then
        await Self.assertCampaignDeepLink(store, fetches: context.fetches)
        #expect(store.state.selectedTab == .campaigns)
    }

    /// 總覽點選新增訂單時，切到訂單分頁並開啟新表單
    @Test
    func dashboard_點選新增訂單_切至訂單頁並開啟表單() async {
        // Given
        let store = TestStore(initialState: Self.makeIsolatedRootState()) {
            RootFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.dashboard(.delegate(.newOrderTapped))) {
            $0.selectedTab = .orders
            $0.orders.presentation.destination = .edit(
                OrderEditFeature.State(
                    id: UUID(0),
                    options: OrderEditOptions(
                        currencyCodes: [.twd, .krw, .jpy, .usd, .cny],
                        calendar: TestDependencies.fixedCalendar
                    ),
                    currentDate: TestDependencies.fixedNow
                )
            )
        }

        // Then
        await store.finish()
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.orders.presentation.destination?.edit?.original == nil)
    }

    /// 總覽點選「查看全部」時，切到訂單分頁
    @Test
    func dashboard_點選檢視全部訂單_切至訂單頁() async {
        // Given
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        }

        // When
        await store.send(.dashboard(.delegate(.viewAllOrdersTapped))) {
            $0.selectedTab = .orders
        }

        // Then
        await store.finish()
        #expect(store.state.selectedTab == .orders)
    }

    /// 總覽出現時檢查訂單是否需要載入，不重讀設定
    ///
    /// - Note: 未覆寫 `settingsService.load` 的依賴，若被呼叫會使測試失敗
    @Test
    func dashboard_總覽出現時重新整理_只重新載入訂單() async {
        // Given
        let state = RootFeature.State()
        // 已載入時 `orders.loadRequested` 不再讀資料，本測試只驗轉送
        state.orders.load.$hasLoaded.withLock {
            $0 = true
        }

        let store = TestStore(initialState: state) {
            RootFeature()
        }

        // When
        await store.send(.dashboard(.view(.task)))

        // Then
        await store.receive(\.dashboard.delegate.refresh)
        await store.receive(\.orders.loadRequested)
        await store.receive(\.orders.load.loadRequested)
        await store.finish()
    }

    /// 分析頁點選已載入的開團後，切到開團分頁並推入該團的詳情，詳情與訂單共用同一份資料
    @Test
    func insights_點選洞察開團_切至開團頁並推入該團詳情() async {
        // Given
        let context = await Self.makeCampaignDeepLinkContext()
        let store = context.store

        // When
        await store.send(.insights(.delegate(.campaignTapped("四月韓國團")))) {
            $0.selectedTab = .campaigns
            $0.campaigns.path.append(CampaignFeatureTests.detailPath("C1", in: $0.campaigns))
        }

        // Then
        await Self.assertCampaignDeepLink(store, fetches: context.fetches)
        #expect(store.state.selectedTab == .campaigns)
    }

    /// 分析頁點選類別排行時，切到訂單分頁並套用類別篩選
    @Test
    func insights_點選洞察分類_切至訂單頁並篩選分類() async {
        // Given
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.insights(.delegate(.categoryTapped("美妝")))) {
            $0.selectedTab = .orders
            $0.orders.list.dateContext = OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.orders.list.selectedCategory = "美妝"
        }

        // Then
        await store.finish()
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.orders.list.selectedCategory == "美妝")
    }

    /// 更多頁沒有任何頁面時，從 AI 提示前往設定，只開一個設定頁
    @Test
    func orders_更多頁為空時前往開啟人工智慧設定_推入唯一設定頁() async {
        // Given
        var initial = RootFeature.State()
        initial.orders.presentation.destination = .alert(Self.aiDisabledAlert())
        let store = TestStore(initialState: initial) {
            RootFeature()
        }

        // When
        await store.send(
            .orders(.presentation(.destination(.presented(.alert(.goToAISettings)))))
        ) {
            $0.orders.presentation.destination = nil
        }

        // Then
        await store.receive(\.orders.presentation.delegate.aiSettingsRequested)
        await store.receive(\.orders.delegate.aiSettingsRequested) {
            $0.selectedTab = .more
            $0.more.path[id: 0] = .settings(SettingsFeature.State())
        }
        await store.finish()
        #expect(store.state.selectedTab == .more)
        #expect(store.state.more.path.count == 1)
        #expect(store.state.more.path[id: 0]?.settings?.snapshot == initial.preferences)
    }

    /// 從 AI 提示前往設定時，先清空更多頁已開啟的頁面，再建立唯一的設定頁
    @Test
    func orders_更多頁已有頁面時前往開啟人工智慧設定_只留設定頁() async {
        // Given
        var initial = RootFeature.State()
        initial.more.path.append(.fx(FxFeature.State()))
        initial.more.showSettings()
        initial.more.path.append(.quote(QuoteFeature.State()))
        initial.orders.presentation.destination = .alert(Self.aiDisabledAlert())
        let store = TestStore(initialState: initial) {
            RootFeature()
        }

        // When
        await store.send(
            .orders(.presentation(.destination(.presented(.alert(.goToAISettings)))))
        ) {
            $0.orders.presentation.destination = nil
        }

        // Then
        await store.receive(\.orders.presentation.delegate.aiSettingsRequested)
        await store.receive(\.orders.delegate.aiSettingsRequested) {
            $0.selectedTab = .more
            $0.more.path.removeAll()
            $0.more.path[id: 3] = .settings(SettingsFeature.State())
        }
        await store.finish()
        #expect(store.state.selectedTab == .more)
        #expect(store.state.more.path.count == 1)
        #expect(store.state.more.path[id: 3]?.settings?.snapshot == initial.preferences)
    }
}

// MARK: - Nested Types

private extension RootFeatureTests {

    /// 總覽與分析頁的開團跳轉測試共用的根 `store` 與開團讀取次數紀錄
    struct CampaignDeepLinkContext {

        /// 已載入開團、尚未處理跳轉的根 `store`
        let store: TestStoreOf<RootFeature>

        /// 開團服務被讀取的次數
        let fetches: LockIsolated<Int>
    }
}

// MARK: - Private Method

private extension RootFeatureTests {

    /// 載入「四月韓國團」與同一筆訂單，供總覽與分析頁的開團跳轉測試共用
    ///
    /// - Returns: 已載入開團的根 `store` 與開團服務被讀取的次數紀錄
    static func makeCampaignDeepLinkContext() async -> CampaignDeepLinkContext {
        let campaign = Campaign.fixture(
            id: "C1",
            name: "四月韓國團",
            openDate: TestDependencies.fixedNow
        )
        let order = Self.makeTestOrder(
            id: "DEEP-LINK",
            categories: ["美妝"],
            customerName: "深連結測試",
            campaignNames: ["四月韓國團"]
        )
        let fetches = LockIsolated(0)
        let initial = CampaignIntegrationTests.makeRootState(campaigns: [], orders: [order])
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.campaignService.fetchCampaigns = {
                fetches.withValue {
                    $0 += 1
                }
                return [campaign]
            }
        }
        await CampaignIntegrationTests.loadCampaigns([campaign], into: store)

        return CampaignDeepLinkContext(store: store, fetches: fetches)
    }

    /// 核對跳轉到開團後的詳情，以及各頁面的訂單是否都已同步更新
    ///
    /// - Parameters:
    ///   - store: 已完成跳轉狀態更新的根 `store`
    ///   - fetches: 開團服務被讀取的次數紀錄
    static func assertCampaignDeepLink(
        _ store: TestStoreOf<RootFeature>,
        fetches: LockIsolated<Int>
    ) async {
        let order = Self.makeTestOrder(
            id: "DEEP-LINK",
            categories: ["美妝"],
            customerName: "深連結測試",
            campaignNames: ["四月韓國團"]
        )
        await store.finish()
        #expect(fetches.value == 1)
        #expect(store.state.campaigns.path.first?.detail?.campaignID == "C1")
        #expect(store.state.campaigns.path.first?.detail?.orders == [order])
        #expect(store.state.orders.orders == [order])
        #expect(store.state.more.orders == [order])
        #expect(store.state.campaigns.orders == [order])
        #expect(store.state.dashboard.orders == [order])
        #expect(store.state.insights.orders == [order])
    }

    /// 建立 AI 功能未開啟時顯示的提示
    ///
    /// - Returns: 關閉提示的 `AlertState`
    static func aiDisabledAlert() -> AlertState<OrdersPresentationFeature.Destination.Alert> {
        AlertState {
            TextState("orders.general.label.aiItemSummary")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("common.action.label.close")
            }
            ButtonState(action: .goToAISettings) {
                TextState("orders.general.label.openSettings2")
            }
        } message: {
            TextState("orders.general.message.enableAiItem")
        }
    }
}
