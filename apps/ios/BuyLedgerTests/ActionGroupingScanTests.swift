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
    ]

    /// 已遷移 View 的元件目錄
    static let migratedComponentDirectories = [
        "Features/FX/Components",
        "Features/Quote/Components",
    ]

    /// View 送出 action 的掃描模式
    static let storeSendPattern = /store\s*\.\s*send\s*\(\s*/

    /// View action 必須以 `.view(` 開頭的掃描模式
    static let viewActionPrefixPattern = /^\.\s*view\s*\(/

    /// reducer 不得包裝子層 `.view(` 的掃描模式
    static let reducerChildViewPattern = /\.\s*(?!send\b|view\b)[a-z]\w*\s*\(\s*\.\s*view\s*\(/

    /// 暫時性豁免 SettingsView 的 AppLockFeature action
    static let actionAllowlist = [
        AllowlistEntry(
            relativePath: "Features/Settings/SettingsView.swift",
            prefix: ".appLock(",
            reason: "AppLockFeature 屬 App 殼層，第 8 步補 delegate",
            removalStep: "第 8 步"
        ),
    ]

    // MARK: - Tests

    /// 確認已遷移 Feature 的 View 只送出 view action
    @Test func migratedViewsSendOnlyViewActions() throws(any Error) {
        // Given: 已遷移的 View 清單與唯一的暫時性 allowlist
        let allowlist = Self.actionAllowlist

        // When: 掃描所有已遷移 View 的 store.send 呼叫
        let result = try Self.scanMigratedViewFiles(allowlist: allowlist)

        // Then: 所有送出點符合規則，且每筆 allowlist 都確實被使用
        #expect(
            result.violations.isEmpty,
            "View action 分組違規：\(Self.describe(result.violations))"
        )
        #expect(
            result.usedAllowlistKeys == Set(allowlist.map(\.key)),
            "allowlist 使用狀態不符：\(result.usedAllowlistKeys.sorted())"
        )
    }

    /// 確認 reducer 不送出也不攔截子層的 view action
    @Test func reducersDoNotSendOrInterceptChildViewActions() throws(any Error) {
        // Given: Features 目錄內所有 production Swift 檔
        let files = try Self.swiftFiles(under: Self.featuresRoot)

        // When: 掃描子層 action 包著 view action 的寫法
        let violations = try Self.reducerChildViewViolations(in: files)

        // Then: reducer 不得直接送出或攔截子層的 view action
        #expect(
            violations.isEmpty,
            "reducer 不得包裝子層 view action：\(Self.describe(violations))"
        )
    }

    /// 驗證掃描器自我測試表中的兩條規則判斷正確
    @Test(arguments: ScanScenario.allCases)
    func scannerClassifiesSourceFragments(scenario: ScanScenario) {
        // Given: design 列出的原始碼片段
        let result: ScanResult
        switch scenario.rule {
        case .viewStoreSend:
            result = Self.scanStoreSendContents(
                scenario.source,
                relativePath: "Synthetic/View.swift",
                allowlist: []
            )
        case .reducerChildView:
            result = ScanResult(
                violations: Self.reducerChildViewViolations(
                    in: scenario.source,
                    relativePath: "Synthetic/Reducer.swift"
                ),
                usedAllowlistKeys: []
            )
        }

        // When: 取得掃描器對片段的判斷
        let passed = result.violations.isEmpty

        // Then: 判斷結果與 design 預期一致
        #expect(
            passed == scenario.shouldPass,
            "\(scenario.name) 掃描結果不符：\(Self.describe(result.violations))"
        )
    }

    /// 驗證符合 allowlist 的送出點會被標記為已使用
    @Test func matchingAllowlistEntryIsUsed() {
        // Given: 與 SettingsView 相同形狀的暫時性送出點
        let entry = Self.actionAllowlist[0]
        let source = "store.send(.appLock(.enableToggled(true)))"

        // When: 以對應 allowlist 掃描片段
        let scan = Self.scanStoreSendContents(
            source,
            relativePath: entry.relativePath,
            allowlist: [entry]
        )
        let violations = scan.violations + Self.unusedAllowlistViolations(
            allowlist: [entry],
            usedKeys: scan.usedAllowlistKeys
        )

        // Then: 不產生違規且條目被標記為已使用
        #expect(violations.isEmpty)
        #expect(scan.usedAllowlistKeys == Set([entry.key]))
    }

    /// 驗證沒有對應送出點的 allowlist 會使掃描失敗
    @Test func unusedAllowlistEntryFailsTheScan() {
        // Given: 目前沒有 appLock 送出點的 View 片段
        let entry = Self.actionAllowlist[0]
        let source = "store.send(.view(.task))"

        // When: 以仍存在的 allowlist 掃描片段
        let scan = Self.scanStoreSendContents(
            source,
            relativePath: entry.relativePath,
            allowlist: [entry]
        )
        let violations = scan.violations + Self.unusedAllowlistViolations(
            allowlist: [entry],
            usedKeys: scan.usedAllowlistKeys
        )

        // Then: 失敗訊息指出未使用的條目
        #expect(!violations.isEmpty)
        #expect(Self.describe(violations).contains("未使用 allowlist"))
    }
}
