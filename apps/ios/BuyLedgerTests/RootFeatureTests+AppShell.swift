//
//  RootFeatureTests+AppShell.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// 設定頁改語言只保存一次，偏好委派更新根功能，讓根畫面從同一份語言偏好呈現
    @Test
    func more_設定改語言_殼層偏好與更多頁投影同步() async {
        // Given
        let saved = LockIsolated<[SettingsSnapshot]>([])
        let expected = SettingsSnapshot(
            language: .english,
            defaultCurrency: .twd,
            monthlyProfitGoalTWD: 80_000,
            isAISummaryEnabled: false,
            aiSummaryModel: "gemma4:31b-cloud",
            isBiometricUnlockEnabled: false
        )
        var initial = RootFeature.State()
        initial.more.showSettings()
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.settingsService.save = { snapshot in
                saved.withValue {
                    $0.append(snapshot)
                }
            }
        }

        // When
        await store.send(
            .more(.path(.element(id: 0, action: .settings(.binding(.set(\.language, .english))))))
        ) {
            $0.more.path[id: 0, case: \.settings]?.language = .english
        }

        // Then
        await store.receive(\.more.path[id: 0].settings.delegate.preferencesChanged, expected)
        await store.receive(\.more.delegate.preferencesChanged, expected) {
            $0.preferences = expected
            $0.more.preferences = expected
        }
        await store.finish()
        #expect(saved.value == [expected])
        #expect(store.state.preferences.language == .english)
    }

    /// 設定頁修改月目標後，偏好委派同步根偏好與總覽投影，不必再次載入
    @Test
    func more_設定改月目標_總覽目標同步() async {
        // Given
        let saved = LockIsolated<[SettingsSnapshot]>([])
        let expected = SettingsSnapshot(
            language: .traditionalChinese,
            defaultCurrency: .twd,
            monthlyProfitGoalTWD: 120_000,
            isAISummaryEnabled: false,
            aiSummaryModel: "gemma4:31b-cloud",
            isBiometricUnlockEnabled: false
        )
        var initial = RootFeature.State()
        initial.more.showSettings()
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.settingsService.save = { snapshot in
                saved.withValue {
                    $0.append(snapshot)
                }
            }
        }

        // When
        await store.send(
            .more(
                .path(
                    .element(
                        id: 0,
                        action: .settings(.binding(.set(\.monthlyProfitGoalTWD, 120_000)))
                    )
                )
            )
        ) {
            $0.more.path[id: 0, case: \.settings]?.monthlyProfitGoalTWD = 120_000
        }

        // Then
        await store.receive(\.more.path[id: 0].settings.delegate.preferencesChanged, expected)
        await store.receive(\.more.delegate.preferencesChanged, expected) {
            $0.preferences = expected
            $0.more.preferences = expected
            $0.dashboard.monthlyProfitGoalTwd = 120_000
        }
        await store.finish()
        #expect(saved.value == [expected])
        #expect(store.state.dashboard.monthlyProfitGoalTwd == 120_000)
    }

    /// 設定頁可見時已解鎖且沒有失敗標記，關閉保護只同步啟用投影，不重設解鎖狀態
    ///
    /// - Throws: 前置狀態沒有符合設定頁可見條件時拋出錯誤
    @Test
    func more_設定關閉App鎖定_鎖定投影同步為關閉() async throws(any Error) {
        // Given
        var preferences = SettingsSnapshot.default
        preferences.isBiometricUnlockEnabled = true
        var initial = RootFeature.State(preferences: preferences)
        initial.appLock.isLocked = false
        initial.more.showSettings()
        try #require(!initial.appLock.unlockDidFail)
        let saved = LockIsolated<[SettingsSnapshot]>([])
        let expected = SettingsSnapshot.default
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.settingsService.save = { snapshot in
                saved.withValue {
                    $0.append(snapshot)
                }
            }
        }

        // When
        await store.send(
            .more(.path(.element(id: 0, action: .settings(.view(.appLockToggled(false))))))
        ) {
            $0.more.path[id: 0, case: \.settings]?.isBiometricUnlockEnabled = false
        }

        // Then
        await store.receive(\.more.path[id: 0].settings.delegate.preferencesChanged, expected)
        await store.receive(\.more.delegate.preferencesChanged, expected) {
            $0.preferences = expected
            $0.more.preferences = expected
            $0.appLock.isBiometricUnlockEnabled = false
        }
        await store.finish()
        #expect(saved.value == [expected])
        #expect(!store.state.appLock.isLocked)
        #expect(!store.state.appLock.unlockDidFail)
    }

    /// 回到前景只更新更多頁的辨識類型投影，已推入的設定畫面保留建構時的值
    @Test
    func appLock_回到前景_更多頁辨識類型同步() async {
        // Given
        var initial = RootFeature.State(appVersion: "1.7.0 (312)")
        initial.more.showSettings()
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.biometricAuthService.biometryType = {
                .faceID
            }
        }

        // When
        await store.send(.appLock(.view(.scenePhaseChanged(.active)))) {
            $0.appLock.biometryType = .faceID
            $0.more.biometryType = .faceID
        }

        // Then
        await store.receive(\.appLock.delegate.didBecomeActive) {
            $0.campaigns.list.dateContext = CampaignDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        }
        await store.finish()
        #expect(store.state.more.biometryType == .faceID)
        #expect(store.state.more.path[id: 0]?.settings?.biometryType == .unavailable)
        #expect(store.state.preferences == .default)
    }

    /// 跨午夜回到前景時更新日期標題，保留開團狀態且不重新載入
    ///
    /// - Throws: 日期脈絡不存在時由 `try #require` 丟出
    @Test
    func appLock_跨午夜後回到前景_開團日期脈絡改為新的一天() async throws(any Error) {
        // Given
        var calendar = TestDependencies.fixedCalendar
        calendar.firstWeekday = 2
        let locale = Locale(identifier: "zh-Hant_TW")
        let nextDay = Date(timeIntervalSince1970: 1_778_632_200) // 2026-05-13 00:30 UTC
        let campaigns = [
            Campaign.fixture(
                id: "MAY12",
                openDate: Date(timeIntervalSince1970: 1_778_544_000), // 2026-05-12 00:00 UTC
                closeDate: Date(timeIntervalSince1970: 1_778_544_000)
            ),
            Campaign.fixture(id: "Y", openDate: Date(timeIntervalSince1970: 1_778_457_600)),
        ]
        let initial = Self.makeCampaignDateState(
            campaigns: campaigns,
            recordedDate: Date(timeIntervalSince1970: 1_778_580_000), // 2026-05-12 10:00 UTC
            calendar: TestDependencies.fixedCalendar
        )
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(nextDay)
            $0.calendar = calendar
            $0.biometricAuthService.biometryType = {
                .unavailable
            }
        }

        // When
        await store.send(.appLock(.view(.scenePhaseChanged(.active))))

        // Then
        await store.receive(\.appLock.delegate.didBecomeActive) {
            $0.campaigns.list.dateContext = CampaignDateContext(now: nextDay, calendar: calendar)
        }
        await store.finish()
        let context = try #require(store.state.campaigns.list.dateContext)
        let titles = store.state.campaigns.list.dateSections.map {
            CampaignFormatters.sectionTitle($0.title, context: context, locale: locale)
        }
        #expect(titles == ["昨天", "5月11日週一"])
        #expect(store.state.campaigns.campaigns == campaigns)
    }

    /// 停在前景跨午夜時，殼層監聽重大時間變更並刷新標題，不依賴列表再次出現
    ///
    /// - Throws: 日期脈絡不存在時由 `try #require` 丟出
    @Test
    func significantTimeChanged_停在前景跨日_開團日期脈絡改為新的一天() async throws(any Error) {
        // Given
        let calendar = TestDependencies.fixedCalendar
        let locale = Locale(identifier: "zh-Hant_TW")
        let midnight = Date(timeIntervalSince1970: 1_778_630_400) // 2026-05-13 00:00 UTC
        let campaign = Campaign.fixture(openDate: Date(timeIntervalSince1970: 1_778_544_000))
        var initial = Self.makeCampaignDateState(
            campaigns: [campaign],
            recordedDate: Date(timeIntervalSince1970: 1_778_629_800), // 2026-05-12 23:50 UTC
            calendar: calendar
        )
        initial.selectedTab = .campaigns
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(midnight)
            $0.calendar = calendar
            $0.currencyMetadataService.refreshIfStale = { _ in
                false
            }
            $0.significantTimeChangeService.changes = {
                AsyncStream { continuation in
                    continuation.yield(())
                    continuation.finish()
                }
            }
        }

        // When
        await store.send(.view(.task))

        // Then
        await store.receive(\.significantTimeChanged) {
            $0.campaigns.list.dateContext = CampaignDateContext(now: midnight, calendar: calendar)
        }
        await store.finish()
        let context = try #require(store.state.campaigns.list.dateContext)
        let titles = store.state.campaigns.list.dateSections.map {
            CampaignFormatters.sectionTitle($0.title, context: context, locale: locale)
        }
        #expect(titles == ["昨天"])
        #expect(store.state.campaigns.campaigns == [campaign])
    }

    /// 訂單收款寫入成功後，已推入的客戶頁經唯讀共享引用取得最新訂單
    @Test
    func orders_訂單更新_已推入的客戶頁讀到新訂單() async {
        // Given
        let order = LedgerOrder.fixture(id: "SHARED-CUSTOMER")
        let updated = Self.rebuiltOrder(order, paymentReceiptStatus: .received)
        var initial = CampaignIntegrationTests.makeRootState(campaigns: [], orders: [order])
        initial.more.path.append(
            .customers(CustomersFeature.State(orders: SharedReader(initial.more.$orders)))
        )
        let saved = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                saved.withValue {
                    $0.append(order)
                }
            }
        }

        // When
        await store.send(.orders(.receiptStatusChanged(order.id, .received)))

        // Then
        await store.receive(\.orders.receiptStatusChangePersisted) {
            $0.orders.orders = [updated]
            $0.campaigns.$orders.withLock {
                $0 = [updated]
            }
            $0.more.$orders.withLock {
                $0 = [updated]
            }
            $0.dashboard.orders = [updated]
            $0.insights.orders = [updated]
        }
        await store.finish()
        #expect(saved.value == [updated])
        #expect(store.state.more.path[id: 0]?.customers?.orders == [updated])
    }
}
