//
//  StoreConstructionSamples.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/15.
//

/// Store 建立守門的合成原始碼與字面預期，供掃描器的參數化測試使用
enum StoreConstructionSamples {

    // MARK: - Properties

    /// Store、快照例外、相似名稱、註解與泛型建立的七個樣本
    ///
    /// - Note: 樣本的左括號以 `\u{28}` 表示，避免目錄掃描命中本檔；改回「(」會讓 Store 守門失敗
    static let all: [Sample] = [
        Sample(
            name: "一般 Store 建立回報原始行號",
            relativePath: "Features/Settings/SettingsFeatureTests.swift",
            source: """
            func example() {
                    _ = Store\u{28}initialState: SettingsFeature.State()) { SettingsFeature() }
            }
            """,
            expectedFindings: ["Features/Settings/SettingsFeatureTests.swift:2"]
        ),
        Sample(
            name: "快照測試內的 Store 建立排除",
            relativePath: "SnapshotTests/SettingsViewSnapshotTests.swift",
            source: """
            func example() {
                    _ = Store\u{28}initialState: SettingsFeature.State()) { SettingsFeature() }
            }
            """,
            expectedFindings: []
        ),
        Sample(
            name: "TestStore 名稱不算 Store 建立",
            relativePath: "Features/Settings/SettingsFeatureTests.swift",
            source: """
            let store = TestStore(initialState: SettingsFeature.State()) { SettingsFeature() }
            """,
            expectedFindings: []
        ),
        Sample(
            name: "種子 helper 名稱不算 Store 建立",
            relativePath: "Features/Settings/SettingsFeatureTests.swift",
            source: "let store = seedV15Store(container)",
            expectedFindings: []
        ),
        Sample(
            name: "整行註解內的 Store 建立排除",
            relativePath: "Features/Settings/SettingsFeatureTests.swift",
            source: """
            // _ = Store\u{28}initialState: SettingsFeature.State()) { SettingsFeature() }
            """,
            expectedFindings: []
        ),
        Sample(
            name: "StoreOf 泛型建立回報原始行號",
            relativePath: "Features/Settings/SettingsFeatureTests.swift",
            source: """
            let store = StoreOf<SettingsFeature>\u{28}initialState: SettingsFeature.State()) { \
            SettingsFeature() }
            """,
            expectedFindings: ["Features/Settings/SettingsFeatureTests.swift:1"]
        ),
        Sample(
            name: "Store 明列 State 與 Action 泛型建立回報原始行號",
            relativePath: "Features/Settings/SettingsFeatureTests.swift",
            source: """
            let store = Store<SettingsFeature.State, SettingsFeature.Action>\u{28}\
            initialState: SettingsFeature.State()) { SettingsFeature() }
            """,
            expectedFindings: ["Features/Settings/SettingsFeatureTests.swift:1"]
        ),
    ]
}

// MARK: - Nested Types

extension StoreConstructionSamples {

    /// Store 掃描的一筆原始碼輸入與字面預期
    struct Sample: Sendable {

        /// 樣本名稱，供失敗訊息辨識
        let name: String

        /// 合成檔案相對於測試目錄的路徑
        let relativePath: String

        /// 合成的原始碼
        let source: String

        /// 預期命中的「相對路徑:行號」，空陣列代表沒有違規
        let expectedFindings: [String]
    }
}
