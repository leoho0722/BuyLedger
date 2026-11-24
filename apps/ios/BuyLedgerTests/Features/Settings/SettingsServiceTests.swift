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

/// `SettingsService` 的單元測試，涵蓋設定預設值、月度目標讀取、AI 摘要供應商與模型的成對讀寫，以及既有偏好 key 的相容
struct SettingsServiceTests {

    /// 驗證缺少字串偏好時，語言、幣別、供應商與模型使用預設值，月度目標依儲存狀態讀取，並沿用既有的偏好 key
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
        #expect(snapshot.aiSummaryProvider == .anthropic)
        #expect(snapshot.aiSummaryModel == "claude-haiku-5-5")
        #expect(snapshot.isBiometricUnlockEnabled == false)
        #expect(
            userDefaultsStore.stringReceivedArguments
                == ["settings.language", "settings.defaultCurrency", "settings.aiSummaryProvider"]
        )
        #expect(userDefaultsStore.hasValueReceivedArguments == ["settings.monthlyProfitGoalTwd"])
        #expect(userDefaultsStore.doubleReceivedArguments == scenario.expectedDoubleReadKeys)
        #expect(
            userDefaultsStore.boolReceivedArguments
                == ["settings.useAiSummary", "settings.isBiometricUnlockEnabled"]
        )
    }

    /// 驗證儲存完整設定快照後讀回相同內容，並以既有的偏好 key 逐項寫入字串、數值與布林值
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
            aiSummaryProvider: .anthropic,
            aiSummaryModel: "claude-sonnet-5-5",
            isBiometricUnlockEnabled: true
        )

        // When
        service.save(expected)

        // Then
        let actual = service.load()
        #expect(actual == expected)
        #expect(
            userDefaultsStore.stringSetReceivedArguments.map(\.key)
                == [
                    "settings.language",
                    "settings.defaultCurrency",
                    "settings.aiSummaryProvider",
                    "settings.aiSummaryModel",
                ]
        )
        #expect(
            userDefaultsStore.stringSetReceivedArguments.map(\.value)
                == ["english", "JPY", "anthropic", "claude-sonnet-5-5"]
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

    /// 驗證以既有偏好 key 寫入的各項值，載入時能還原為完整的設定快照
    @Test
    func load_既有偏好鍵_還原完整設定快照() {
        // Given
        let userDefaultsStore = MockUserDefaultsStore()
        userDefaultsStore.set("english", forKey: "settings.language")
        userDefaultsStore.set("USD", forKey: "settings.defaultCurrency")
        userDefaultsStore.set(120_000.0, forKey: "settings.monthlyProfitGoalTwd")
        userDefaultsStore.set(true, forKey: "settings.useAiSummary")
        userDefaultsStore.set("anthropic", forKey: "settings.aiSummaryProvider")
        userDefaultsStore.set("claude-sonnet-5-5", forKey: "settings.aiSummaryModel")
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
                    aiSummaryProvider: .anthropic,
                    aiSummaryModel: "claude-sonnet-5-5",
                    isBiometricUnlockEnabled: true
                )
        )
        #expect(
            userDefaultsStore.stringReceivedArguments
                == [
                    "settings.language",
                    "settings.defaultCurrency",
                    "settings.aiSummaryProvider",
                    "settings.aiSummaryModel",
                ]
        )
        #expect(userDefaultsStore.hasValueReceivedArguments == ["settings.monthlyProfitGoalTwd"])
        #expect(userDefaultsStore.doubleReceivedArguments == ["settings.monthlyProfitGoalTwd"])
        #expect(
            userDefaultsStore.boolReceivedArguments
                == ["settings.useAiSummary", "settings.isBiometricUnlockEnabled"]
        )
    }

    /// 驗證已存供應商能辨識時讀取該供應商的模型，沒有存過或無法辨識時回到預設供應商與預設模型，且不讀取已存的舊模型
    ///
    /// - Parameter scenario: 已存供應商與已存模型的組合
    @Test(arguments: AISummaryStoredScenario.allCases)
    func load_已存供應商與模型的各種組合_依規則還原供應商與模型(scenario: AISummaryStoredScenario) {
        // Given
        let userDefaultsStore = MockUserDefaultsStore()
        if let storedProvider = scenario.storedProvider {
            userDefaultsStore.set(storedProvider, forKey: "settings.aiSummaryProvider")
        }
        if let storedModel = scenario.storedModel {
            userDefaultsStore.set(storedModel, forKey: "settings.aiSummaryModel")
        }
        let service = withDependencies {
            $0.userDefaultsStore = userDefaultsStore
        } operation: {
            SettingsService.liveValue
        }

        // When
        let snapshot = service.load()

        // Then
        #expect(snapshot.aiSummaryProvider == .anthropic)
        #expect(snapshot.aiSummaryModel == scenario.expectedModel)
        #expect(userDefaultsStore.stringReceivedArguments == scenario.expectedStringReadKeys)
    }

    /// 驗證儲存供應商與模型後，供應商寫入偏好 key，模型等於預設時寫入空字串，否則寫入模型名稱
    ///
    /// - Parameter scenario: 儲存的模型情境
    @Test(arguments: AISummarySaveScenario.allCases)
    func save_供應商與模型_依是否為預設模型寫入偏好值(scenario: AISummarySaveScenario) {
        // Given
        let userDefaultsStore = MockUserDefaultsStore()
        let service = withDependencies {
            $0.userDefaultsStore = userDefaultsStore
        } operation: {
            SettingsService.liveValue
        }
        let snapshot = SettingsSnapshot(
            language: .english,
            defaultCurrency: .jpy,
            monthlyProfitGoalTWD: 80_000,
            isAISummaryEnabled: false,
            aiSummaryProvider: .anthropic,
            aiSummaryModel: scenario.model,
            isBiometricUnlockEnabled: false
        )

        // When
        service.save(snapshot)

        // Then
        #expect(
            userDefaultsStore.stringSetReceivedArguments.map(\.key)
                == [
                    "settings.language",
                    "settings.defaultCurrency",
                    "settings.aiSummaryProvider",
                    "settings.aiSummaryModel",
                ]
        )
        #expect(
            userDefaultsStore.stringSetReceivedArguments.map(\.value)
                == ["english", "JPY", "anthropic", scenario.expectedStoredModel]
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

    /// 儲存供應商與模型的情境，模型是否等於供應商預設模型決定寫入的值
    enum AISummarySaveScenario: CaseIterable, Sendable {

        /// 模型等於供應商預設模型，儲存時寫入空字串
        case defaultModel

        /// 使用者選擇的自訂模型，儲存時寫入模型名稱
        case customModel

        /// 儲存的模型名稱
        var model: String {
            switch self {
            case .defaultModel:
                "claude-haiku-5-5"

            case .customModel:
                "claude-sonnet-5-5"
            }
        }

        /// 此情境預期寫入 `settings.aiSummaryModel` 的值；空字串代表跟隨供應商預設
        var expectedStoredModel: String {
            switch self {
            case .defaultModel:
                ""

            case .customModel:
                "claude-sonnet-5-5"
            }
        }
    }

    /// 已存的 AI 摘要供應商與模型組合
    enum AISummaryStoredScenario: CaseIterable, Sendable {

        /// 供應商與模型都沒有寫過
        case neverWritten

        /// 沒有寫過供應商，只留有舊的模型名稱
        case legacyModelOnly

        /// 供應商為 `anthropic`，模型為使用者選擇的 `claude-sonnet-5-5`
        case recognizedProviderWithModel

        /// 供應商為 `anthropic`，模型是空字串
        case recognizedProviderWithEmptyModel

        /// 供應商是已下架而無法辨識的 `retired-provider`
        case unrecognizedProvider

        /// 預先寫入的供應商偏好值；`nil` 代表沒有寫過
        var storedProvider: String? {
            switch self {
            case .neverWritten, .legacyModelOnly:
                nil

            case .recognizedProviderWithModel, .recognizedProviderWithEmptyModel:
                "anthropic"

            case .unrecognizedProvider:
                "retired-provider"
            }
        }

        /// 預先寫入的模型偏好值；`nil` 代表沒有寫過
        var storedModel: String? {
            switch self {
            case .neverWritten:
                nil

            case .legacyModelOnly:
                "gemma4:31b-cloud"

            case .recognizedProviderWithModel:
                "claude-sonnet-5-5"

            case .recognizedProviderWithEmptyModel:
                ""

            case .unrecognizedProvider:
                "some-model"
            }
        }

        /// 此情境預期讀回的模型名稱
        var expectedModel: String {
            switch self {
            case .recognizedProviderWithModel:
                "claude-sonnet-5-5"

            case .neverWritten, .legacyModelOnly, .recognizedProviderWithEmptyModel,
                    .unrecognizedProvider:
                "claude-haiku-5-5"
            }
        }

        /// 此情境預期依序讀取的字串偏好 key；供應商無法辨識時不讀取模型
        var expectedStringReadKeys: [String] {
            switch self {
            case .recognizedProviderWithModel, .recognizedProviderWithEmptyModel:
                [
                    "settings.language",
                    "settings.defaultCurrency",
                    "settings.aiSummaryProvider",
                    "settings.aiSummaryModel",
                ]

            case .neverWritten, .legacyModelOnly, .unrecognizedProvider:
                [
                    "settings.language",
                    "settings.defaultCurrency",
                    "settings.aiSummaryProvider",
                ]
            }
        }
    }
}
