//
//  TestSuiteIntegrityTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/29.
//

import Foundation
import Testing
/// 驗證測試套件完整性
struct TestSuiteIntegrityTests {
    
    // MARK: - Static Properties
    
    /// 整理後的窮舉檢查關閉處上限；只能下降，不可上升
    static let exhaustivityOffUpperBound = 9
    
    // MARK: - Tests
    
    @Test func exhaustivityRelaxationsDoNotExceedTheRecordedBound() throws(any Error) {
        let count = try Self.countMatches(
            pattern: #"exhaustivity\s*=\s*\.off"#,
            under: Self.testRoot
        )
        
        #expect(
            count <= Self.exhaustivityOffUpperBound,
            "窮舉檢查關閉處為 \(count)，不可超過上限 \(Self.exhaustivityOffUpperBound)"
        )
    }
    
    @Test func defaultNoneBranchesRemainAbsent() throws(any Error) {
        let count = try Self.countMatches(
            pattern: #"default:\s*return\s+\.none"#,
            under: Self.productionRoot
        )
        
        #expect(
            count == 0,
            "全庫不應出現 default 分支回傳 none，實際命中 \(count) 處"
        )
    }
    
    @Test func credentialBearingURLInterpolationsRemainAbsent() throws(any Error) {
        let count = try Self.countMatches(
            pattern: Self.credentialLeakingInterpolationPattern,
            under: Self.productionRoot
        )
        
        #expect(
            count == 0,
            "App target 不應把完整 URL／URLRequest 內插進使用者可見訊息或診斷輸出，憑證可能隨網址一併外洩，實際命中 \(count) 處"
        )
    }
}

// MARK: - Static Properties

private extension TestSuiteIntegrityTests {
    
    /// 測試 target 所在的 iOS 平台目錄
    static var iosRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
    
    /// 受窮舉檢查數量守門掃描的測試目錄
    static var testRoot: URL {
        iosRoot.appending(path: "BuyLedgerTests")
    }
    
    /// App target 的掃描目錄
    static var productionRoot: URL {
        iosRoot.appending(path: "BuyLedger")
    }
    
    /// 找出疑似把 URL 或 URLRequest 直接顯示給使用者的樣式
    static let credentialLeakingInterpolationPattern =
        #"(?i)\\\(\s*[A-Za-z0-9_]*(?:url|request)[A-Za-z0-9_]*\s*(?:,[^)]*)?\)"#
        + #"|\\\([^)]*[A-Za-z0-9_]*(?:url|request)[A-Za-z0-9_]*\.(?:absoluteString|url|"#
        + #"description|debugDescription)\b[^)]*\)"#
}

// MARK: - Private Method

private extension TestSuiteIntegrityTests {
    
    /// 計算目錄下 Swift 原始檔的命中數
    /// - Parameters:
    ///   - pattern: 比對樣式
    ///   - root: 掃描根目錄
    /// - Returns: 命中數
    /// - Throws: 原始檔讀取或正規表示式建立失敗時拋出錯誤
    static func countMatches(pattern: String, under root: URL) throws(any Error) -> Int {
        let expression = try NSRegularExpression(pattern: pattern)
        let enumerator = try #require(
            FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: nil
            )
        )
        
        var count = 0
        for case let file as URL in enumerator where file.pathExtension == "swift" {
            let source = try String(contentsOf: file, encoding: .utf8)
            for line in source.components(separatedBy: "\n") where !isCommentLine(line) {
                let range = NSRange(line.startIndex..<line.endIndex, in: line)
                count += expression.numberOfMatches(in: line, range: range)
            }
        }
        return count
    }
    
    /// 該行是否為註解行 (以 `//` 開頭，涵蓋 `///` 文件註解與 `// MARK:`)
    /// - Returns: 該行是否為註解
    static func isCommentLine(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces).hasPrefix("//")
    }
}
