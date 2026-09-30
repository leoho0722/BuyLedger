//
//  TestSuiteIntegrityTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/29.
//

import Foundation
import Testing

/// 移除整行註解後掃描原始碼，守住測試目錄的 `TestStore` 窮舉上限、App target 的預設分支規則與網址憑證內插規則
struct TestSuiteIntegrityTests {

    // MARK: - Properties

    /// 測試目錄中關閉 `TestStore` 窮舉檢查的處數上限，涵蓋 `exhaustivity = .off` 與
    /// `withExhaustivity(.off)`；目前為 0，不得新增任何一處
    private static let exhaustivityOffUpperBound = 0

    /// 比對全文中以空白或註解分隔的 `default:` 與 `return .none`
    private static let defaultNoneBranchPattern = #"default:(?:\s|//[^\n]*\n)*return\s+\.none"#

    /// 比對內插運算式中名稱含 `url`／`request` (不分大小寫) 的識別字或成員名稱
    private static let credentialPattern = #"(?i)\\\([^\n)]*\b\w*(?:url|request)\w*\b[^\n)]*\)"#

    // MARK: - Tests

    /// 掃描移除整行註解後的測試目錄全文，關閉 `TestStore` 窮舉檢查的總處數不得超過 `exhaustivityOffUpperBound`
    ///
    /// - Throws: 建立正規表示式失敗、目錄無法列舉 (`#require` 失敗) 或原始碼讀取失敗時丟出
    @Test
    func exhaustivityOffUpperBound_窮舉檢查關閉處_不超過記錄上限() throws(any Error) {
        // Given
        let pattern = #"exhaustivity\s*=\s*\.off|withExhaustivity\s*\(\s*\.off"#
        let root = Self.testRoot

        // When
        let scan = try Self.countMatches(pattern: pattern, under: root)

        // Then
        #expect(scan.fileCount > 0, "\(root.lastPathComponent) 沒有 .swift 檔可掃描")
        #expect(
            scan.matchCount <= Self.exhaustivityOffUpperBound,
            "\(root.lastPathComponent): \(scan.matchCount) 次，限 \(Self.exhaustivityOffUpperBound)"
        )
    }

    /// 掃描移除整行註解後的 App target 全文，不得出現 `default:` 接 `return .none` 的預設分支
    ///
    /// - Throws: 建立正規表示式失敗、目錄無法列舉 (`#require` 失敗) 或原始碼讀取失敗時丟出
    @Test
    func defaultNoneBranches_生產碼預設分支回傳無效果_不存在() throws(any Error) {
        // Given
        let pattern = Self.defaultNoneBranchPattern
        let root = Self.productionRoot

        // When
        let scan = try Self.countMatches(pattern: pattern, under: root)

        // Then
        #expect(scan.fileCount > 0, "\(root.lastPathComponent) 沒有 .swift 檔可掃描")
        #expect(
            scan.matchCount == 0,
            "\(root.lastPathComponent) 的 default 分支回傳 none 命中 \(scan.matchCount) 處"
        )
    }

    /// 掃描移除整行註解後的 App target 全文，字串內插不得放入名稱含 `url`／`request` 的識別字或成員存取，避免網址中的憑證外洩
    ///
    /// - Throws: 建立正規表示式失敗、目錄無法列舉 (`#require` 失敗) 或原始碼讀取失敗時丟出
    @Test
    func credentialBearingURLInterpolations_生產碼憑證網址內插_不存在() throws(any Error) {
        // Given
        let pattern = Self.credentialPattern
        let root = Self.productionRoot

        // When
        let scan = try Self.countMatches(pattern: pattern, under: root)

        // Then
        #expect(scan.fileCount > 0, "\(root.lastPathComponent) 沒有 .swift 檔可掃描")
        #expect(scan.matchCount == 0, "\(root.lastPathComponent) 的憑證識別字內插命中 \(scan.matchCount) 處")
    }
}

// MARK: - Private Method

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

    /// 遞迴讀取目錄下的 `.swift` 檔，移除整行註解後以完整檔案內容計算命中次數
    ///
    /// - Parameters:
    ///   - pattern: 要比對移除註解後原始碼的正規表示式
    ///   - root: 遞迴掃描的資料夾
    /// - Returns: 掃描的 `.swift` 檔數與命中總數
    /// - Throws: 正規表示式建立失敗、掃描目錄無法列舉 (`#require` 失敗) 或原始檔讀取失敗時丟出
    static func countMatches(
        pattern: String,
        under root: URL
    ) throws(any Error) -> (fileCount: Int, matchCount: Int) {
        let expression = try NSRegularExpression(pattern: pattern)
        let enumerator = try #require(
            FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        )

        var fileCount = 0
        var matchCount = 0
        for case let file as URL in enumerator where file.pathExtension == "swift" {
            fileCount += 1
            let source = try String(contentsOf: file, encoding: .utf8)
            let uncommentedSource = source
                .components(separatedBy: "\n")
                .filter { !isCommentLine($0) }
                .joined(separator: "\n")
            let range = NSRange(
                uncommentedSource.startIndex..<uncommentedSource.endIndex,
                in: uncommentedSource
            )
            matchCount += expression.numberOfMatches(in: uncommentedSource, range: range)
        }
        return (fileCount: fileCount, matchCount: matchCount)
    }

    /// 判斷去掉前後空白後是否以 `//` 開頭，涵蓋 `///` 文件註解與 `// MARK:` 分區
    ///
    /// - Parameter line: 要檢查的原始碼行
    /// - Returns: 以 `//` 開頭時為 `true`
    static func isCommentLine(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces).hasPrefix("//")
    }
}
