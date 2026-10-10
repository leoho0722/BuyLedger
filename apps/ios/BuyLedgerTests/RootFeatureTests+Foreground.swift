//
//  RootFeatureTests+Foreground.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension RootFeatureTests {

    /// 回到前景時，更多頁的生物辨識類型跟著更新；已開啟的設定頁保留開啟當時的類型
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
            $0.orders.list.dateContext = OrderDateContext(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
        }
        await store.finish()
        #expect(store.state.more.biometryType == .faceID)
        #expect(store.state.more.path[id: 0]?.settings?.biometryType == .unavailable)
        #expect(store.state.preferences == initial.preferences)
    }

    /// 跨過午夜回到前景時，開團列表的日期標題改為新的一天，開團資料保留且不重新載入
    ///
    /// - Throws: 開團列表的日期資訊不存在時由 `try #require` 丟出
    @Test
    func appLock_跨午夜後回到前景_開團日期脈絡改為新的一天() async throws {
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
            $0.orders.list.dateContext = OrderDateContext(now: nextDay, calendar: calendar)
        }
        await store.finish()
        let context = try #require(store.state.campaigns.list.dateContext)
        let titles = store.state.campaigns.list.dateSections.map {
            CampaignFormatters.sectionTitle($0.title, context: context, locale: locale)
        }
        #expect(titles == ["昨天", "5月11日週一"])
        #expect(store.state.campaigns.campaigns == campaigns)
    }

    /// App 停在前景時跨過午夜，系統送出時間變更通知後，根畫面更新日期標題，不必等開團列表重新出現
    ///
    /// - Throws: 開團列表的日期資訊不存在時由 `try #require` 丟出
    @Test
    func task_停在前景跨日_開團日期脈絡改為新的一天() async throws {
        // Given
        let timeChanges = AsyncStream<Void>.makeStream()
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
        initial.orders.load.$hasLoaded.withLock {
            $0 = true
        }
        let currencyRelease = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(midnight)
            $0.calendar = calendar
            $0.currencyMetadataService.refreshIfStale = { _ in
                var iterator = currencyRelease.stream.makeAsyncIterator()
                _ = await iterator.next()
                return false
            }
            $0.currencyMetadataService.fetchCodes = {
                []
            }
            $0.significantTimeChangeService.changes = {
                timeChanges.stream
            }
        }

        // When
        await store.send(.view(.task))

        // Then
        await Self.receiveLaunchLoadRequests(in: store)
        currencyRelease.continuation.finish()
        await store.receive(\.launch.currencyCodesResponse.success, [])
        timeChanges.continuation.yield(())
        timeChanges.continuation.finish()
        await store.receive(\.launch.delegate.significantTimeChanged) {
            $0.campaigns.list.dateContext = CampaignDateContext(now: midnight, calendar: calendar)
            $0.orders.list.dateContext = OrderDateContext(now: midnight, calendar: calendar)
        }
        await store.finish()
        let context = try #require(store.state.campaigns.list.dateContext)
        let titles = store.state.campaigns.list.dateSections.map {
            CampaignFormatters.sectionTitle($0.title, context: context, locale: locale)
        }
        #expect(titles == ["昨天"])
        #expect(store.state.campaigns.campaigns == [campaign])
    }
}
