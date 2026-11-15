//
//  UITestConventionScanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/15.
//

import Foundation
import Testing

/// `UITestConventionScanner` 的單元測試，以掃描正式 UI 測試 target 與合成樣本守門 UI 測試規範
struct UITestConventionScanTests {

    /// 驗證 `Tests/` 下的測試檔檔名只使用 `UITests` 或 `TestSupport` 後綴，列名的例外除外
    ///
    /// - Throws: 列舉 UI 測試目錄或讀取原始碼失敗時丟出
    /// - Note: 例外檔名見 `UITestConventionScanner.namingExceptions`
    @Test
    func scanNaming_UI測試Tests目錄_檔名只允許UITests與TestSupport後綴() throws {
        // Given
        let root = UITestConventionScanner.uiRoot

        // When
        let report = try UITestConventionScanner.scan(.naming, under: root)

        // Then
        #expect(report.fileCount > 0, "UI 測試 target 沒有 .swift 檔可掃描")
        #expect(
            report.violations.isEmpty,
            "UI 測試檔名違規：\(UITestConventionScanner.describe(report.violations))"
        )
    }

    /// 驗證 UI 測試 target 內沒有 `@discardableResult` 修飾且回傳 `Bool` 的函式
    ///
    /// - Throws: 列舉 UI 測試目錄或讀取原始碼失敗時丟出
    /// - Note: 比對範圍為整個宣告直到左大括號，因為簽章常跨多行
    @Test
    func scanDiscardableBool_UI測試target_不含回傳Bool的可丟棄函式() throws {
        // Given
        let root = UITestConventionScanner.uiRoot

        // When
        let report = try UITestConventionScanner.scan(.discardableBool, under: root)

        // Then
        #expect(report.fileCount > 0, "UI 測試 target 沒有 .swift 檔可掃描")
        #expect(
            report.violations.isEmpty,
            "可丟棄的 Bool 函式違規：\(UITestConventionScanner.describe(report.violations))"
        )
    }

    /// 驗證 Support、Screens 與 `*TestSupport.swift` 沒有呼叫非拋錯的失敗出口，診斷檔除外
    ///
    /// - Throws: 列舉 UI 測試目錄或讀取原始碼失敗時丟出
    @Test
    func scanFailureExit_Support與Screens與TestSupport_不呼叫非拋錯出口() throws {
        // Given
        let root = UITestConventionScanner.uiRoot

        // When
        let report = try UITestConventionScanner.scan(.failureExit, under: root)

        // Then
        #expect(report.fileCount > 0, "失敗出口掃描範圍內沒有 .swift 檔可掃描")
        #expect(
            report.violations.isEmpty,
            "非拋錯失敗出口違規：\(UITestConventionScanner.describe(report.violations))"
        )
    }

    /// 驗證掃描器對合成樣本的判斷與案例一致：命中的位置與預期位置完全相同，預期無違規的樣本不回報
    ///
    /// - Parameter scenario: 一筆自我測試案例，含規則、檔案路徑、樣本與預期位置
    @Test(arguments: UITestConventionScenarios.all)
    func violations_合成樣本_命中位置與預期一致(scenario: UITestConventionScenarios.Scenario) {
        // Given
        let rule = scenario.rule
        let relativePath = scenario.relativePath
        let source = scenario.source

        // When
        let findings = UITestConventionScanner.violations(
            for: rule,
            relativePath: relativePath,
            source: source
        )

        // Then
        #expect(
            findings.map(\.location) == scenario.expectedLocations,
            "\(scenario.name) 命中位置不符：\(UITestConventionScanner.describe(findings))"
        )
    }
}
