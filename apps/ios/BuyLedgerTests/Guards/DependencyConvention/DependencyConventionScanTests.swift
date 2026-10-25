//
//  DependencyConventionScanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

import Foundation
import Testing

/// 依賴規範的單元測試，以掃描 App 與單元測試原始碼守住依賴注入邊界
struct DependencyConventionScanTests {

    /// 驗證 App 與單元測試現行程式碼不違反任何依賴規範，違規時逐筆列出檔案、行號與原因
    ///
    /// - Parameter rule: 要掃描的依賴規則
    /// - Throws: 根目錄不存在或不是目錄時丟 `DependencyScanError.sourceRootNotFound(path:)`；檔案不在
    ///   根目錄下時丟 `DependencyScanError.sourceFileOutsideRoot(path:)`；沒有適用檔案時丟
    ///   `DependencyScanError.noApplicableSourceFiles(rule:)`；子規則沒有適用檔案時丟
    ///   `DependencyScanError.noApplicableSubruleFiles(rule:subrule:)`；讀檔失敗時丟系統錯誤
    @Test(arguments: DependencyScanRule.allCases)
    func scanTree_每條規則掃描App與單元測試程式碼_沒有違規(rule: DependencyScanRule) throws {
        // Given
        let roots = DependencyConventionScanner.appAndTestRoots

        // When
        let violations = try DependencyConventionScanner.scanTree(rule: rule, roots: roots)

        // Then
        #expect(
            violations.isEmpty,
            Comment(rawValue: violations.map(\.diagnostic).joined(separator: "\n"))
        )
    }

    /// 驗證根目錄設錯時掃描失敗並指出路徑，不把未掃到檔案當作沒有違規
    ///
    /// - Throws: 掃描器未丟出 `DependencyScanError` 時由 `try #require` 丟出測試斷言錯誤
    @Test
    func scanTree_根目錄不存在_丟出缺少的路徑() throws {
        // Given
        var actualError: (any Error)?
        let missingPath = "/DependencyConventionScanTests-missing-root"
        let missingRoot = URL(fileURLWithPath: missingPath)

        // When
        do {
            _ = try DependencyConventionScanner.scanTree(
                rule: .dependencyTypeSubscript,
                roots: [DependencyScanRoot(url: missingRoot, sourceTree: .production)]
            )
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError as? DependencyScanError)
        var reportedPath: String?
        if case .sourceRootNotFound(let path) = error {
            reportedPath = path
        }
        #expect(reportedPath == "/DependencyConventionScanTests-missing-root")
    }

    /// 驗證根目錄內沒有可掃描的 Swift 檔時掃描失敗並指出規則，避免未執行的規則顯示通過
    ///
    /// - Throws: 找不到 App 正式程式碼根目錄，或掃描器未丟出 `DependencyScanError` 時由
    ///   `try #require` 丟出測試斷言錯誤
    @Test
    func scanTree_根目錄沒有適用檔案_回報規則() throws {
        // Given
        var actualError: (any Error)?
        let root = try #require(
            DependencyConventionScanner.appAndTestRoots.first { $0.sourceTree == .production }
        )
        let resourcesRoot = root.url.appending(path: "Resources")

        // When
        do {
            _ = try DependencyConventionScanner.scanTree(
                rule: .dependencyTypeSubscript,
                roots: [DependencyScanRoot(url: resourcesRoot, sourceTree: .production)]
            )
        } catch {
            actualError = error
        }

        // Then
        let error = try #require(actualError as? DependencyScanError)
        var reportedRule: DependencyScanRule?
        if case .noApplicableSourceFiles(let rule) = error {
            reportedRule = rule
        }
        #expect(reportedRule == .dependencyTypeSubscript)
    }

    /// 驗證違規案例只回報一筆，且檔案、行號、引用文字與原因都與案例指定的一致
    ///
    /// - Parameter scenario: 要送進掃描器的違規案例
    /// - Throws: 掃描器未回報違規時由 `try #require` 丟出錯誤
    @Test(arguments: DependencyConventionScanScenario.violationCases)
    func fragmentViolations_違規案例_回報位置與原因(scenario: DependencyScanViolationCase) throws {
        // Given
        let file = DependencyScanFile(
            relativePath: scenario.relativePath,
            sourceTree: scenario.sourceTree,
            contents: scenario.source
        )

        // When
        let violations = DependencyConventionScanner.fragmentViolations(
            in: file,
            rules: scenario.rules
        )

        // Then
        let violation = try #require(violations.first)
        #expect(violations.count == 1, Comment(rawValue: scenario.name))
        #expect(violation.file == scenario.relativePath, Comment(rawValue: scenario.name))
        #expect(violation.line == scenario.expectedLine, Comment(rawValue: scenario.name))
        #expect(violation.reference == scenario.expectedReference, Comment(rawValue: scenario.name))
        #expect(violation.reason == scenario.expectedReason, Comment(rawValue: scenario.name))
    }

    /// 驗證各規則的合規寫法，以及字串與註解內的規則文字，都不產生違規
    ///
    /// - Parameter scenario: 要送進掃描器的合規案例
    @Test(arguments: DependencyConventionScanScenario.passingCases)
    func fragmentViolations_合規案例_不回報違規(scenario: DependencyScanPassingCase) {
        // Given
        let file = DependencyScanFile(
            relativePath: scenario.relativePath,
            sourceTree: scenario.sourceTree,
            contents: scenario.source
        )

        // When
        let violations = DependencyConventionScanner.fragmentViolations(
            in: file,
            rules: scenario.rules
        )

        // Then
        #expect(violations.isEmpty, Comment(rawValue: scenario.name))
    }
}
