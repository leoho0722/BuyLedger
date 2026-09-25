//
//  SettingsStoreTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/23.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證設定儲存的 UserDefaults 讀寫規則
struct SettingsStoreTests {

    // MARK: - Tests

    /// 驗證月度目標缺值與既有數值都會被正確讀取
    @Test(arguments: MonthlyGoalScenario.allCases)
    func snapshotReadsMonthlyGoal(scenario: MonthlyGoalScenario) throws {
        // Given
        let suiteName = scenario.suiteName
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        if let storedGoal = scenario.storedGoal {
            defaults.set(storedGoal, forKey: "settings.monthlyProfitGoalTwd")
        }

        // When
        let snapshot = SettingsStore.snapshot(from: defaults)

        // Then
        #expect(snapshot.monthlyProfitGoalTWD == scenario.expectedGoal)
    }

    /// 驗證完整設定快照可以往返 UserDefaults
    @Test func snapshotRoundTripsAllSettings() throws {
        // Given
        let suiteName = "BuyLedgerTests.SettingsStoreTests.roundTrip"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        let expected = SettingsSnapshot(
            language: .english,
            defaultCurrency: .jpy,
            monthlyProfitGoalTWD: 120_000,
            isAISummaryEnabled: true,
            aiSummaryModel: "gpt-oss:120b",
            isBiometricUnlockEnabled: true
        )

        // When
        SettingsStore.save(expected, to: defaults)
        let actual = SettingsStore.snapshot(from: defaults)

        // Then
        #expect(actual == expected)
    }

    /// 驗證欄位改名後仍能讀取既有 UserDefaults key
    @Test func snapshotReadsLegacyPreferenceKeys() throws {
        // Given
        let suiteName = "BuyLedgerTests.SettingsStoreTests.legacyKeys"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        defaults.set("english", forKey: "settings.language")
        defaults.set("USD", forKey: "settings.defaultCurrency")
        defaults.set(120_000.0, forKey: "settings.monthlyProfitGoalTwd")
        defaults.set(true, forKey: "settings.useAiSummary")
        defaults.set("gpt-oss:120b", forKey: "settings.aiSummaryModel")
        defaults.set(true, forKey: "settings.isBiometricUnlockEnabled")

        // When
        let snapshot = SettingsStore.snapshot(from: defaults)

        // Then
        #expect(snapshot.language == .english)
        #expect(snapshot.defaultCurrency == .usd)
        #expect(snapshot.monthlyProfitGoalTWD == 120_000)
        #expect(snapshot.isAISummaryEnabled)
        #expect(snapshot.aiSummaryModel == "gpt-oss:120b")
        #expect(snapshot.isBiometricUnlockEnabled)
    }
}

// MARK: - Nested Types

extension SettingsStoreTests {

    /// 月度目標讀取情境
    enum MonthlyGoalScenario: CaseIterable {

        /// UserDefaults 尚未寫入月度目標
        case missing

        /// UserDefaults 已寫入零
        case zero

        /// UserDefaults 已寫入 120,000
        case written

        /// 此情境使用的 UserDefaults 網域名稱
        var suiteName: String {
            switch self {
            case .missing:
                "BuyLedgerTests.SettingsStoreTests.missing"

            case .zero:
                "BuyLedgerTests.SettingsStoreTests.zero"

            case .written:
                "BuyLedgerTests.SettingsStoreTests.written"
            }
        }

        /// 此情境要寫入的月度目標；`nil` 代表保留未寫入狀態
        var storedGoal: Double? {
            switch self {
            case .missing:
                nil

            case .zero:
                0

            case .written:
                120_000
            }
        }

        /// 此情境預期讀回的月度目標
        var expectedGoal: Decimal {
            switch self {
            case .missing:
                80_000

            case .zero:
                0

            case .written:
                120_000
            }
        }
    }
}
