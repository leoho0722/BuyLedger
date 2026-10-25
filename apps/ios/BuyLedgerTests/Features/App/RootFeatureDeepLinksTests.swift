//
//  RootFeatureDeepLinksTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試，以 TestStore 驗證總覽、分析與訂單頁的深連結，如何切換分頁、推入詳情、開啟表單與套用篩選
@MainActor
struct RootFeatureDeepLinksTests {

    /// 驗證總覽點選已載入的開團時，切到開團分頁並推入該團詳情，詳情與各頁的訂單內容一致
    @Test
    func dashboard_點選總覽開團_切至開團頁並推入該團詳情() async {
        // Given
        let initial = Self.makeCampaignDeepLinkState()
        let store = Self.makeCampaignDeepLinkStore(initial: initial)

        // When
        await store.send(.dashboard(.delegate(.campaignTapped("四月韓國團")))) {
            $0.selectedTab = .campaigns
            $0.campaigns.path.append(
                CampaignFeatureTestSupport.detailPath("C1", in: initial.campaigns)
            )
        }

        // Then
        await Self.assertCampaignDeepLink(store)
        #expect(store.state.selectedTab == .campaigns)
    }

    /// 驗證總覽點選新增訂單時，切到訂單分頁並開啟新增用的表單，表單不帶原始訂單
    @Test
    func dashboard_點選新增訂單_切至訂單頁並開啟表單() async {
        // Given
        let store = TestStore(initialState: RootFeatureTestSupport.makeIsolatedRootState()) {
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

    /// 驗證總覽點選「查看全部」時，切到訂單分頁
    @Test
    func dashboard_點選檢視全部訂單_切至訂單頁() async {
        // Given
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.dashboard(.delegate(.viewAllOrdersTapped))) {
            $0.selectedTab = .orders
        }

        // Then
        await store.finish()
        #expect(store.state.selectedTab == .orders)
    }

    /// 驗證總覽出現時先經主檔目錄載入請求，再請求訂單載入，不重讀設定
    ///
    /// - Note: 未覆寫 `settingsService.load` 的依賴，若被呼叫會使測試失敗
    /// - Note: 主檔目錄與訂單都已載入，兩個載入請求都不再讀資料，本測試只驗證兩個載入請求依序送出
    @Test
    func dashboard_總覽出現時重新整理_經主檔目錄後請求訂單且不重讀設定() async {
        // Given
        var state = RootFeature.State()
        state.orders.load.$hasLoaded.withLock {
            $0 = true
        }
        state.more.catalog.hasLoaded = true

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.dashboard(.view(.task))) {
            $0.dashboard.dateContext = DashboardDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        }

        // Then
        await store.receive(\.dashboard.delegate.refresh)
        await store.receive(\.more.catalogLoadRequested)
        await store.receive(\.more.catalog.loadRequested)
        await store.receive(\.more.catalog.delegate.loadFinished)
        await store.receive(\.more.delegate.catalogLoadFinished)
        await store.receive(\.orders.rootRequest.load)
        await store.receive(\.orders.load.loadRequested)
        await store.finish()
    }

    /// 驗證分析頁點選已載入的開團時，切到開團分頁並推入該團詳情，詳情與各頁的訂單內容一致
    @Test
    func insights_點選洞察開團_切至開團頁並推入該團詳情() async {
        // Given
        let initial = Self.makeCampaignDeepLinkState()
        let store = Self.makeCampaignDeepLinkStore(initial: initial)

        // When
        await store.send(.insights(.delegate(.campaignTapped("四月韓國團")))) {
            $0.selectedTab = .campaigns
            $0.campaigns.path.append(
                CampaignFeatureTestSupport.detailPath("C1", in: initial.campaigns)
            )
        }

        // Then
        await Self.assertCampaignDeepLink(store)
        #expect(store.state.selectedTab == .campaigns)
    }

    /// 驗證分析頁點選類別排行時，切到訂單分頁，並以該類別取代原本的多類別篩選
    @Test
    func insights_點選洞察分類_切至訂單頁並篩選分類() async {
        // Given
        var state = RootFeature.State()
        state.orders.list.selectedCategories = ["snacks", "books"]
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.insights(.delegate(.categoryTapped("beauty")))) {
            $0.selectedTab = .orders
            $0.orders.list.dateContext = OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            $0.orders.list.selectedCategories = ["beauty"]
        }

        // Then
        await store.finish()
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.orders.list.selectedCategories == ["beauty"])
    }

    /// 驗證更多頁沒有任何頁面時，從 AI 提示前往設定會切到更多頁，並推入唯一的設定頁
    @Test
    func orders_更多頁為空時前往開啟人工智慧設定_推入唯一設定頁() async {
        // Given
        let expectedSnapshot = SettingsSnapshot(
            language: .traditionalChinese,
            defaultCurrency: .twd,
            monthlyProfitGoalTWD: 80_000,
            isAISummaryEnabled: false,
            aiSummaryModel: "gemma4:31b-cloud",
            isBiometricUnlockEnabled: false
        )
        var initial = RootFeature.State()
        initial.orders.presentation.destination = .alert(Self.aiDisabledAlert())
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
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
            $0.more.path[id: 0] = .settings(
                SettingsFeature.State(
                    snapshot: expectedSnapshot,
                    appVersion: "—",
                    biometryType: .unavailable
                )
            )
        }
        await store.finish()
        #expect(store.state.selectedTab == .more)
        #expect(store.state.more.path.count == 1)
        #expect(store.state.more.path[id: 0]?.settings?.snapshot == expectedSnapshot)
    }

    /// 驗證更多頁已有頁面時，從 AI 提示前往設定會先清空所有頁面，再推入唯一的設定頁
    @Test
    func orders_更多頁已有頁面時前往開啟人工智慧設定_只留設定頁() async {
        // Given
        let expectedSnapshot = SettingsSnapshot(
            language: .traditionalChinese,
            defaultCurrency: .twd,
            monthlyProfitGoalTWD: 80_000,
            isAISummaryEnabled: false,
            aiSummaryModel: "gemma4:31b-cloud",
            isBiometricUnlockEnabled: false
        )
        var initial = RootFeature.State()
        initial.more.path.append(.fx(FxFeature.State()))
        initial.more.showSettings()
        initial.more.path.append(.quote(QuoteFeature.State()))
        initial.orders.presentation.destination = .alert(Self.aiDisabledAlert())
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
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
            $0.more.path[id: 3] = .settings(
                SettingsFeature.State(
                    snapshot: expectedSnapshot,
                    appVersion: "—",
                    biometryType: .unavailable
                )
            )
        }
        await store.finish()
        #expect(store.state.selectedTab == .more)
        #expect(store.state.more.path.count == 1)
        #expect(store.state.more.path[id: 3]?.settings?.snapshot == expectedSnapshot)
    }
}

// MARK: - Private Method

private extension RootFeatureDeepLinksTests {

    /// 建立已載入「四月韓國團」與同一筆訂單的根狀態，供總覽與分析頁的開團跳轉測試共用
    ///
    /// - Returns: 已載入開團、尚未處理跳轉的根狀態
    static func makeCampaignDeepLinkState() -> RootFeature.State {
        let campaign = Campaign.fixture(
            id: "C1",
            name: "四月韓國團",
            openDate: TestDependencies.fixedNow
        )
        let order = RootFeatureTestSupport.makeTestOrder(
            id: "DEEP-LINK",
            categories: ["美妝"],
            customerName: "深連結測試",
            campaignNames: ["四月韓國團"]
        )
        let initial = CampaignIntegrationTestSupport.makeRootState(
            campaigns: [campaign],
            orders: [order]
        )
        initial.campaigns.load.$hasLoaded.withLock {
            $0 = true
        }
        return initial
    }

    /// 以指定的根狀態建立開團跳轉用的 TestStore，並固定時間與行事曆
    ///
    /// - Parameter initial: 測試自行建立的根狀態
    /// - Returns: 尚未處理跳轉的根 `store`
    static func makeCampaignDeepLinkStore(initial: RootFeature.State) -> TestStoreOf<RootFeature> {
        TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
    }

    /// 核對跳轉到開團後的詳情，以及各頁面的訂單是否都已同步更新
    ///
    /// - Parameter store: 已完成跳轉狀態更新的根 `store`
    static func assertCampaignDeepLink(_ store: TestStoreOf<RootFeature>) async {
        let order = RootFeatureTestSupport.makeTestOrder(
            id: "DEEP-LINK",
            categories: ["美妝"],
            customerName: "深連結測試",
            campaignNames: ["四月韓國團"]
        )
        await store.finish()
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
    /// - Returns: 含關閉與前往 AI 設定按鈕的 `AlertState`
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
