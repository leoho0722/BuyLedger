//
//  ActionGroupingScanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/23.
//

import Foundation
import Testing

/// `ActionGroupingScanner` 的單元測試，以掃描正式原始碼守門 action 的發送者分組規則
struct ActionGroupingScanTests {

    // MARK: - Properties

    /// 已遷移畫面的暫時性豁免清單，目前沒有任何例外
    private static let actionAllowlist: [ActionGroupingScanner.AllowlistEntry] = []

    /// 驗證已遷移 Feature 的 View 只以 `store.send` 送出 view action，未列在 allowlist 內的送出都算違規
    ///
    /// - Throws: 讀取已遷移 View 的原始碼失敗時丟出
    /// - Note: 掃描範圍是已遷移 View 清單與已遷移元件目錄內的所有 Swift 檔
    /// - Note: 未被任何送出點使用的 allowlist 條目也列為違規，由 `result.violations` 的斷言守住
    @Test
    func scanMigratedViewFiles_已遷移View_只送出ViewAction() throws {
        // Given
        let allowlist = Self.actionAllowlist

        // When
        let result = try ActionGroupingScanner.scanMigratedViewFiles(allowlist: allowlist)

        // Then
        #expect(
            result.violations.isEmpty,
            "View action 分組違規：\(ActionGroupingScanner.describe(result.violations))"
        )
    }

    /// 驗證 Features 內的 reducer 不送出也不攔截子 Feature 的 view action，
    /// 子 Feature 的 view action 只由自己的 reducer 處理
    ///
    /// - Throws: 列舉或讀取 Features 目錄的原始碼失敗時丟出
    /// - Note: 掃描範圍是 Features 目錄內所有正式 Swift 檔
    @Test
    func reducerChildViewViolations_Features原始碼_不包裝子層ViewAction() throws {
        // Given
        let files = try SwiftSourceFiles.swiftFiles(
            under: ActionGroupingScanner.featuresRoot,
            shouldIncludeGenerated: true
        )

        // When
        let violations = try ActionGroupingScanner.reducerChildViewViolations(in: files)

        // Then
        #expect(
            violations.isEmpty,
            "reducer 不得包裝子層 view action：\(ActionGroupingScanner.describe(violations))"
        )
    }

    /// 驗證掃描器對 View 送出點片段的判斷與案例一致：`shouldPass` 為真的片段無違規，為假的片段必有違規
    ///
    /// - Parameter scenario: 一筆掃描器自我測試案例，含原始碼片段、掃描規則與預期結果
    /// - Note: 案例涵蓋 design 列出的每個 View 送出點片段
    @Test(arguments: ActionGroupingScenarios.ScanScenario.viewStoreSendCases)
    func scanStoreSendContents_送出點片段_判斷與預期一致(scenario: ActionGroupingScenarios.ScanScenario) {
        // Given
        let source = scenario.source

        // When
        let result = ActionGroupingScanner.scanStoreSendContents(
            source,
            relativePath: "Synthetic/View.swift",
            allowlist: []
        )

        // Then
        #expect(
            result.violations.isEmpty == scenario.shouldPass,
            "\(scenario.name) 掃描結果不符：\(ActionGroupingScanner.describe(result.violations))"
        )
    }

    /// 驗證掃描器對 reducer 包裝子 Feature view action 片段的判斷與案例一致：`shouldPass` 為真的片段無違規，為假的片段必有違規
    ///
    /// - Parameter scenario: 一筆掃描器自我測試案例，含原始碼片段、掃描規則與預期結果
    /// - Note: 案例涵蓋 design 列出的每個 reducer 送出與攔截 action 片段
    @Test(arguments: ActionGroupingScenarios.ScanScenario.reducerChildViewCases)
    func reducerChildViewViolations_子層片段_判斷與預期一致(scenario: ActionGroupingScenarios.ScanScenario) {
        // Given
        let source = scenario.source

        // When
        let violations = ActionGroupingScanner.reducerChildViewViolations(
            in: source,
            relativePath: "Synthetic/Reducer.swift"
        )

        // Then
        #expect(
            violations.isEmpty == scenario.shouldPass,
            "\(scenario.name) 掃描結果不符：\(ActionGroupingScanner.describe(violations))"
        )
    }

    /// 驗證符合 allowlist 條目的送出點不產生違規，並把該條目標記為已使用
    ///
    /// - Note: 送出點由測試內合成，不來自正式原始碼
    @Test
    func scanStoreSendContents_符合allowlist的送出點_標記為已使用() {
        // Given
        let entry = ActionGroupingScanner.AllowlistEntry(
            relativePath: "Synthetic/View.swift",
            prefix: ".legacy(",
            reason: "自我測試的合成子層送出點",
            removalStep: "只存在自我測試"
        )
        let source = "store.send(.legacy(.perform))"

        // When
        let scan = ActionGroupingScanner.scanStoreSendContents(
            source,
            relativePath: entry.relativePath,
            allowlist: [entry]
        )
        let violations = scan.violations + ActionGroupingScanner.unusedAllowlistViolations(
            allowlist: [entry],
            usedKeys: scan.usedAllowlistKeys
        )

        // Then
        #expect(violations.isEmpty)
        #expect(scan.usedAllowlistKeys == Set(["Synthetic/View.swift|.legacy("]))
    }

    /// 驗證沒有對應送出點的 allowlist 條目會使掃描回報違規，違規訊息指出該條目未使用
    ///
    /// - Note: 片段只送 view action，與條目的 `legacy` 前綴不符，條目因而未被使用
    @Test
    func unusedAllowlistViolations_allowlist沒有對應送出點_回報未使用條目() {
        // Given
        let entry = ActionGroupingScanner.AllowlistEntry(
            relativePath: "Synthetic/View.swift",
            prefix: ".legacy(",
            reason: "自我測試的合成子層送出點",
            removalStep: "只存在自我測試"
        )
        let source = "store.send(.view(.task))"

        // When
        let scan = ActionGroupingScanner.scanStoreSendContents(
            source,
            relativePath: entry.relativePath,
            allowlist: [entry]
        )
        let violations = scan.violations + ActionGroupingScanner.unusedAllowlistViolations(
            allowlist: [entry],
            usedKeys: scan.usedAllowlistKeys
        )

        // Then
        #expect(!violations.isEmpty)
        #expect(ActionGroupingScanner.describe(violations).contains("未使用 allowlist"))
    }
}
