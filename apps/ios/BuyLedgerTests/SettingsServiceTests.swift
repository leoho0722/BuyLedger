//
//  SettingsServiceTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/27.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 驗證設定預設值、月度目標讀取與既有偏好 key
struct SettingsServiceTests {

    // MARK: - Tests

    /// 缺少字串偏好時使用語言、幣別與模型預設值，月度目標依儲存狀態讀取並沿用既有 key
    ///
    /// - Parameter scenario: 月度目標的儲存情境
    @Test(arguments: MonthlyGoalScenario.allCases)
    func load_月度目標缺值或已寫入_回傳設定預設值或目標(scenario: MonthlyGoalScenario) {
        // Given
        let userDefaultsStore = MockUserDefaultsStore()
        userDefaultsStore.hasValueResult = scenario.hasStoredGoal
        if let storedGoal = scenario.storedGoal {
            userDefaultsStore.doubleResult = storedGoal
        }
        let service = withDependencies {
            $0.userDefaultsStore = userDefaultsStore
        } operation: {
            SettingsService.liveValue
        }

        // When
        let snapshot = service.load()

        // Then
        #expect(snapshot.language == .traditionalChinese)
        #expect(snapshot.defaultCurrency == .twd)
        #expect(snapshot.monthlyProfitGoalTWD == scenario.expectedGoal)
        #expect(snapshot.isAISummaryEnabled == false)
        #expect(snapshot.aiSummaryModel == "gemma4:31b-cloud")
        #expect(snapshot.isBiometricUnlockEnabled == false)
        #expect(
            userDefaultsStore.stringReceivedArguments
                == ["settings.language", "settings.defaultCurrency", "settings.aiSummaryModel"]
        )
        #expect(userDefaultsStore.hasValueReceivedArguments == ["settings.monthlyProfitGoalTwd"])
        #expect(userDefaultsStore.doubleReceivedArguments == scenario.expectedDoubleReadKeys)
        #expect(
            userDefaultsStore.boolReceivedArguments
                == ["settings.useAiSummary", "settings.isBiometricUnlockEnabled"]
        )
    }

    /// 儲存完整設定快照後可從偏好讀回相同內容
    @Test
    func save_完整設定快照_儲存後讀回相同設定() {
        // Given
        let userDefaultsStore = MockUserDefaultsStore()
        let service = withDependencies {
            $0.userDefaultsStore = userDefaultsStore
        } operation: {
            SettingsService.liveValue
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
        service.save(expected)

        // Then
        let actual = service.load()
        #expect(actual == expected)
        #expect(
            userDefaultsStore.stringSetReceivedArguments.map(\.key)
                == ["settings.language", "settings.defaultCurrency", "settings.aiSummaryModel"]
        )
        #expect(
            userDefaultsStore.stringSetReceivedArguments.map(\.value)
                == ["english", "JPY", "gpt-oss:120b"]
        )
        #expect(
            userDefaultsStore.doubleSetReceivedArguments.map(\.key)
                == ["settings.monthlyProfitGoalTwd"]
        )
        #expect(userDefaultsStore.doubleSetReceivedArguments.map(\.value) == [120_000.0])
        #expect(
            userDefaultsStore.boolSetReceivedArguments.map(\.key)
                == ["settings.useAiSummary", "settings.isBiometricUnlockEnabled"]
        )
        #expect(userDefaultsStore.boolSetReceivedArguments.map(\.value) == [true, true])
    }

    /// 既有偏好 key 仍能還原完整設定快照
    @Test
    func load_既有偏好鍵_還原完整設定快照() {
        // Given
        let userDefaultsStore = MockUserDefaultsStore()
        userDefaultsStore.set("english", forKey: "settings.language")
        userDefaultsStore.set("USD", forKey: "settings.defaultCurrency")
        userDefaultsStore.set(120_000.0, forKey: "settings.monthlyProfitGoalTwd")
        userDefaultsStore.set(true, forKey: "settings.useAiSummary")
        userDefaultsStore.set("gpt-oss:120b", forKey: "settings.aiSummaryModel")
        userDefaultsStore.set(true, forKey: "settings.isBiometricUnlockEnabled")
        let service = withDependencies {
            $0.userDefaultsStore = userDefaultsStore
        } operation: {
            SettingsService.liveValue
        }

        // When
        let snapshot = service.load()

        // Then
        #expect(
            snapshot
                == SettingsSnapshot(
                    language: .english,
                    defaultCurrency: .usd,
                    monthlyProfitGoalTWD: 120_000,
                    isAISummaryEnabled: true,
                    aiSummaryModel: "gpt-oss:120b",
                    isBiometricUnlockEnabled: true
                )
        )
        #expect(
            userDefaultsStore.stringReceivedArguments
                == ["settings.language", "settings.defaultCurrency", "settings.aiSummaryModel"]
        )
        #expect(userDefaultsStore.hasValueReceivedArguments == ["settings.monthlyProfitGoalTwd"])
        #expect(userDefaultsStore.doubleReceivedArguments == ["settings.monthlyProfitGoalTwd"])
        #expect(
            userDefaultsStore.boolReceivedArguments
                == ["settings.useAiSummary", "settings.isBiometricUnlockEnabled"]
        )
    }
}

// MARK: - Nested Types

extension SettingsServiceTests {

    /// 月度目標缺值與已寫入數值的讀取情境
    enum MonthlyGoalScenario: CaseIterable, Sendable {

        /// 尚未寫入月度目標
        case missing

        /// 已寫入零
        case zero

        /// 已寫入 120,000
        case written

        /// 預先設定的月度目標；`nil` 代表未寫入
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

        /// 月度目標是否已有儲存值
        var hasStoredGoal: Bool {
            storedGoal != nil
        }

        /// 此情境預期讀取的月度目標 key
        var expectedDoubleReadKeys: [String] {
            switch self {
            case .missing:
                []

            case .zero, .written:
                ["settings.monthlyProfitGoalTwd"]
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
