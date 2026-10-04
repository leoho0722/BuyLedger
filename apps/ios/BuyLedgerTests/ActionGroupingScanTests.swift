//
//  ActionGroupingScanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/23.
//

import Foundation
import Testing

@testable import BuyLedger

/// 掃描式守門：把 Feature action 的發送者分組規則轉為機器強制
@MainActor
struct ActionGroupingScanTests {

    // MARK: - Properties

    /// 已遷移且受 View action 規則掃描的檔案
    static let migratedViewPaths = [
        "Features/FX/FxView.swift",
        "Features/Quote/QuoteView.swift",
        "Features/Settings/SettingsView.swift",
        "Features/AISummary/AISummaryView.swift",
        "Features/Customers/CustomersView.swift",
        "Features/Lookups/LookupManagementView.swift",
        "Features/Campaigns/CampaignView.swift",
        "Features/Campaigns/CampaignListView.swift",
        "Features/Campaigns/CampaignDetailView.swift",
        "Features/Campaigns/CampaignEditView.swift",
        "Features/App/RootView.swift",
        "Features/App/RootTabLayout.swift",
        "Features/App/RootSidebarLayout.swift",
        "Features/App/AppLockView.swift",
        "Features/App/PersistenceFailureView.swift",
        "Features/More/MoreView.swift",
    ]

    /// 已遷移 View 的元件目錄
    static let migratedComponentDirectories = [
        "Features/FX/Components",
        "Features/Quote/Components",
        "Features/Lookups/Components",
        "Features/Campaigns/Components",
    ]

    /// View 送出 action 的掃描模式
    static let storeSendPattern = /\b(?:store|\w+Store)\s*\.\s*send\s*\(\s*/

    /// View action 必須以 `.view(` 開頭的掃描模式
    static let viewActionPrefixPattern = /^\.\s*view\s*\(/

    /// reducer 不得包裝子層 `.view(` 的掃描模式
    static let reducerChildViewPattern = /\.\s*(?!send\b|view\b)[a-z]\w*\s*\(\s*\.\s*view\s*\(/

    /// 已遷移畫面的暫時性豁免清單，目前沒有任何例外
    private static let actionAllowlist: [AllowlistEntry] = []

    /// 確認已遷移 Feature 的 View 只送出 view action
    ///
    /// - Throws: 讀取已遷移 View 的原始碼失敗時丟出
    /// - Note: 以已遷移的 View 清單與具名 allowlist 掃描所有 `store.send` 呼叫，
    ///   所有送出點符合規則，且每筆 allowlist 都確實被使用
    @Test
    func scanMigratedViewFiles_已遷移View_只送出ViewAction() throws(any Error) {
        // Given
        let allowlist = Self.actionAllowlist

        // When
        let result = try Self.scanMigratedViewFiles(allowlist: allowlist)

        // Then
        #expect(result.violations.isEmpty, "View action 分組違規：\(Self.describe(result.violations))")
        #expect(
            result.usedAllowlistKeys == Set(allowlist.map(\.key)),
            "allowlist 使用狀態不符：\(result.usedAllowlistKeys.sorted())"
        )
    }

    /// 確認 reducer 不送出也不攔截子層的 view action
    ///
    /// - Throws: 列舉或讀取 Features 目錄的原始碼失敗時丟出
    /// - Note: 掃描 Features 目錄內所有 production Swift 檔中子層 action 包著 view action 的寫法，
    ///   reducer 不得直接送出或攔截子層的 view action
    @Test
    func reducerChildViewViolations_Features原始碼_不包裝子層ViewAction() throws(any Error) {
        // Given
        let files = try Self.swiftFiles(under: Self.featuresRoot)

        // When
        let violations = try Self.reducerChildViewViolations(in: files)

        // Then
        #expect(violations.isEmpty, "reducer 不得包裝子層 view action：\(Self.describe(violations))")
    }

    /// 驗證掃描器自我測試表中的兩條規則判斷正確
    ///
    /// - Parameter scenario: 一筆掃描器自我測試案例，含原始碼片段、掃描規則與預期結果
    /// - Note: design 列出的每個原始碼片段，掃描器的判斷結果都與預期一致
    @Test(arguments: ScanScenario.allCases)
    func scanScenario_兩條規則的片段_判斷與預期一致(scenario: ScanScenario) {
        // Given
        let source = scenario.source
        let rule = scenario.rule

        // When
        let result: ScanResult
        switch rule {
        case .viewStoreSend:
            result = Self.scanStoreSendContents(
                source,
                relativePath: "Synthetic/View.swift",
                allowlist: []
            )

        case .reducerChildView:
            result = ScanResult(
                violations: Self.reducerChildViewViolations(
                    in: source,
                    relativePath: "Synthetic/Reducer.swift"
                ),
                usedAllowlistKeys: []
            )
        }

        // Then
        #expect(
            result.violations.isEmpty == scenario.shouldPass,
            "\(scenario.name) 掃描結果不符：\(Self.describe(result.violations))"
        )
    }

    /// 驗證符合 allowlist 的送出點會被標記為已使用
    ///
    /// - Note: 合成的子層送出點以測試內建立的 allowlist 掃描後不產生違規，
    ///   且條目被標記為已使用
    @Test
    func scanStoreSendContents_符合allowlist的送出點_標記為已使用() {
        // Given
        let entry = AllowlistEntry(
            relativePath: "Synthetic/View.swift",
            prefix: ".legacy(",
            reason: "自我測試的合成子層送出點",
            removalStep: "只存在自我測試"
        )
        let source = "store.send(.legacy(.perform))"

        // When
        let scan = Self.scanStoreSendContents(
            source,
            relativePath: entry.relativePath,
            allowlist: [entry]
        )
        let violations = scan.violations + Self.unusedAllowlistViolations(
            allowlist: [entry],
            usedKeys: scan.usedAllowlistKeys
        )

        // Then
        #expect(violations.isEmpty)
        #expect(scan.usedAllowlistKeys == Set(["Synthetic/View.swift|.legacy("]))
    }

    /// 驗證沒有對應送出點的 allowlist 會使掃描失敗
    ///
    /// - Note: View 片段沒有合成的 legacy 送出點，仍存在的 allowlist 掃描後，
    ///   失敗訊息指出未使用的條目
    @Test
    func unusedAllowlistViolations_allowlist沒有對應送出點_回報未使用條目() {
        // Given
        let entry = AllowlistEntry(
            relativePath: "Synthetic/View.swift",
            prefix: ".legacy(",
            reason: "自我測試的合成子層送出點",
            removalStep: "只存在自我測試"
        )
        let source = "store.send(.view(.task))"

        // When
        let scan = Self.scanStoreSendContents(
            source,
            relativePath: entry.relativePath,
            allowlist: [entry]
        )
        let violations = scan.violations + Self.unusedAllowlistViolations(
            allowlist: [entry],
            usedKeys: scan.usedAllowlistKeys
        )

        // Then
        #expect(!violations.isEmpty)
        #expect(Self.describe(violations).contains("未使用 allowlist"))
    }
}
