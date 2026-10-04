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

    /// 列表載入開團後由總覽點選該團，切到開團分頁並推入與投影共用資料的詳情
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
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.date = .constant(TestDependencies.fixedNow)
        }

        // When
        await store.send(.dashboard(.delegate(.newOrderTapped))) {
            $0.selectedTab = .orders
            $0.orders.editOrder = OrderEditFeature.State(
                id: UUID(0),
                currentDate: TestDependencies.fixedNow
            )
        }

        // Then
        await store.finish()
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.orders.editOrder?.original == nil)
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
    /// - Note: `testValue` 的 `settingsService.load` 為 `unimplemented`，非預期重讀會使測試失敗
    @Test
    func dashboard_總覽出現時重新整理_只重新載入訂單() async {
        // Given
        var state = RootFeature.State()
        // 已載入時 `orders.task` 不再讀資料，本測試只驗轉送
        state.orders.hasLoaded = true

        let store = TestStore(initialState: state) {
            RootFeature()
        }

        // When
        await store.send(.dashboard(.task))

        // Then
        await store.receive(\.dashboard.delegate.refresh)
        await store.receive(\.orders.task)
        await store.finish()
    }

    /// 列表載入開團後由分析頁點選該團，切到開團分頁並推入與投影共用資料的詳情
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
            $0.orders.selectedCategory = "美妝"
        }

        // Then
        await store.finish()
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.orders.selectedCategory == "美妝")
    }

    /// AI 功能關閉時從空的更多堆疊前往設定，只推入一份設定頁
    @Test
    func orders_更多頁為空時前往開啟人工智慧設定_推入唯一設定頁() async {
        // Given
        var initial = RootFeature.State()
        initial.orders.aiDisabledAlert = Self.aiDisabledAlert()
        let store = TestStore(initialState: initial) {
            RootFeature()
        }

        // When
        await store.send(.orders(.aiDisabledAlert(.presented(.goToAISettings)))) {
            $0.orders.aiDisabledAlert = nil
        }

        // Then
        await store.receive(\.orders.delegate.aiSettingsRequested) {
            $0.selectedTab = .more
            $0.more.path[id: 0] = .settings(SettingsFeature.State())
        }
        await store.finish()
        #expect(store.state.selectedTab == .more)
        #expect(store.state.more.path.count == 1)
        #expect(store.state.more.path[id: 0]?.settings?.snapshot == .default)
    }

    /// AI 設定深連結先清空工具與設定頁，再以根投影建立唯一設定頁
    @Test
    func orders_更多頁已有頁面時前往開啟人工智慧設定_只留設定頁() async {
        // Given
        var initial = RootFeature.State()
        initial.more.path.append(.fx(FxFeature.State()))
        initial.more.showSettings()
        initial.more.path.append(.quote(QuoteFeature.State()))
        initial.orders.aiDisabledAlert = Self.aiDisabledAlert()
        let store = TestStore(initialState: initial) {
            RootFeature()
        }

        // When
        await store.send(.orders(.aiDisabledAlert(.presented(.goToAISettings)))) {
            $0.orders.aiDisabledAlert = nil
        }

        // Then
        await store.receive(\.orders.delegate.aiSettingsRequested) {
            $0.selectedTab = .more
            $0.more.path.removeAll()
            $0.more.path[id: 3] = .settings(SettingsFeature.State())
        }
        await store.finish()
        #expect(store.state.selectedTab == .more)
        #expect(store.state.more.path.count == 1)
        #expect(store.state.more.path[id: 3]?.settings?.snapshot == .default)
    }
}

// MARK: - Nested Types

private extension RootFeatureTests {

    /// 總覽、洞察深連結共用的根 store 與開團讀取紀錄
    struct CampaignDeepLinkContext {

        /// 已載入開團且尚未處理深連結的根 store
        let store: TestStoreOf<RootFeature>

        /// 開團 Service 的讀取次數
        let fetches: LockIsolated<Int>
    }
}

// MARK: - Private Method

private extension RootFeatureTests {

    /// 載入四月韓國團與一致的訂單投影，供總覽、洞察深連結測試共用
    ///
    /// - Returns: 已載入開團的根 store 與 Service 讀取次數紀錄
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

    /// 核對開團深連結同步完成後的詳情、來源訂單與全部頁面的投影
    ///
    /// - Parameters:
    ///   - store: 已完成深連結狀態更新的根 store
    ///   - fetches: 開團 Service 的讀取次數紀錄
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

    /// 建立 AI 功能關閉時顯示的提示
    ///
    /// - Returns: 關閉提示的 `AlertState`
    static func aiDisabledAlert() -> AlertState<OrdersFeature.Action.Alert> {
        AlertState {
            TextState("AI 商品明細總結")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("關閉")
            }
            ButtonState(action: .goToAISettings) {
                TextState("前往開啟")
            }
        } message: {
            TextState("此功能需要先在「更多 → 設定」開啟 AI 商品明細總結。")
        }
    }
}
