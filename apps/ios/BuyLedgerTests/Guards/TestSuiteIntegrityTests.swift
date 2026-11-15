//
//  TestSuiteIntegrityTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/29.
//

import Foundation
import Testing

/// 測試套件完整性的單元測試，以移除整行註解後的原始碼檢查 TestStore 窮舉上限、App 預設分支、網址憑證內插與 Store 建立範圍
struct TestSuiteIntegrityTests {

    // MARK: - Properties

    /// 測試目錄中關閉 `TestStore` 窮舉檢查的處數上限，涵蓋 `exhaustivity = .off` 與
    /// `withExhaustivity(.off)`；目前為 0，不得新增任何一處
    private static let exhaustivityOffUpperBound = 0

    /// `default:` 與 `return .none` 之間以空白或行尾註解分隔的比對樣式
    private static let defaultNoneBranchPattern = #"default:(?:\s|//[^\n]*\n)*return\s+\.none"#

    /// 字串內插運算式中名稱含 `url`／`request` (不分大小寫) 的識別字或成員名稱的比對樣式
    private static let credentialPattern = #"(?i)\\\([^\n)]*\b\w*(?:url|request)\w*\b[^\n)]*\)"#

    /// 建立 `Store` 的呼叫樣式：`Store(`、`Store<…>(`、`StoreOf<…>(`，前面不可緊接識別字字元或 `.`
    /// 泛型參數內可再含一層 `<…>`
    private static let storeConstructionPattern =
        #"(?<![A-Za-z0-9_.])(?:StoreOf|Store)(?:<(?:[^<>\n]|<[^<>\n]*>)*>)?\("#

    /// 驗證移除整行註解後的測試目錄全文中，關閉 `TestStore` 窮舉檢查的處數不超過 `exhaustivityOffUpperBound`
    ///
    /// - Throws: 建立正規表示式失敗、目錄無法列舉 (`#require` 失敗) 或原始碼讀取失敗時丟出錯誤
    @Test
    func exhaustivityOffUpperBound_窮舉檢查關閉處_不超過記錄上限() throws {
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

    /// 驗證移除整行註解後的 App target 全文不出現 `default:` 接 `return .none` 的預設分支，兩者之間隔著空白或行尾註解也算命中
    ///
    /// - Throws: 建立正規表示式失敗、目錄無法列舉 (`#require` 失敗) 或原始碼讀取失敗時丟出錯誤
    @Test
    func defaultNoneBranches_生產碼預設分支回傳無效果_不存在() throws {
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

    /// 驗證移除整行註解後的 App target 全文中，字串內插不放入名稱含 `url`／`request` (不分大小寫) 的識別字或成員存取，避免網址中的憑證外洩
    ///
    /// - Throws: 建立正規表示式失敗、目錄無法列舉 (`#require` 失敗) 或原始碼讀取失敗時丟出錯誤
    @Test
    func credentialBearingURLInterpolations_生產碼憑證網址內插_不存在() throws {
        // Given
        let pattern = Self.credentialPattern
        let root = Self.productionRoot

        // When
        let scan = try Self.countMatches(pattern: pattern, under: root)

        // Then
        #expect(scan.fileCount > 0, "\(root.lastPathComponent) 沒有 .swift 檔可掃描")
        #expect(scan.matchCount == 0, "\(root.lastPathComponent) 的憑證識別字內插命中 \(scan.matchCount) 處")
    }

    /// 驗證 `SnapshotTests/` 以外的測試檔不建立 `Store`，只比對移除整行註解後的 `Store(`、
    /// `Store<…>(`、`StoreOf<…>(` 呼叫，命中時列出每處的相對路徑與行號
    ///
    /// - Throws: 目錄無法列舉 (`#require` 失敗) 或原始碼讀取失敗時丟出錯誤
    @Test
    func storeConstructions_快照測試以外建立Store_不存在() throws {
        // Given
        let root = Self.testRoot

        // When
        let scan = try Self.storeConstructionFindings(
            under: root,
            excludingPrefix: "SnapshotTests/"
        )

        let failures = Self.storeScanFailures(fileCount: scan.fileCount, findings: scan.findings)

        // Then
        #expect(failures.isEmpty, "Store 建立守門失敗：\(failures.joined(separator: "、"))")
    }

    /// 驗證合成樣本的 Store 建立、快照排除、相似名稱與註解判斷，命中位置與字面預期一致
    ///
    /// - Parameter sample: 原始碼、相對路徑與預期命中位置的合成樣本
    @Test(arguments: StoreConstructionSamples.all)
    func storeConstructionFindings_合成樣本_命中位置與預期一致(sample: StoreConstructionSamples.Sample) {
        // Given
        let source = sample.source
        let relativePath = sample.relativePath

        // When
        let findings = Self.storeConstructionFindings(
            in: source,
            relativePath: relativePath,
            excludingPrefix: "SnapshotTests/"
        )

        // Then
        #expect(findings == sample.expectedFindings, "\(sample.name) 命中位置不符，實際為 \(findings)")
    }

    /// 驗證沒有可掃描的 Swift 檔時，即使命中清單為空仍回報失敗
    @Test
    func storeScanFailures_沒有可掃描的檔案_回報失敗() {
        // Given
        let fileCount = 0
        let findings: [String] = []

        // When
        let failures = Self.storeScanFailures(fileCount: fileCount, findings: findings)

        // Then
        #expect(!failures.isEmpty)
        #expect(failures.contains("沒有 .swift 檔可掃描"))
    }
}

// MARK: - Private Method

private extension TestSuiteIntegrityTests {

    /// 測試 target 所在的 iOS 平台目錄
    static var iosRoot: URL {
        TestPaths.iosRoot
    }

    /// 測試 target 的原始碼目錄，窮舉檢查與 `Store` 建立守門共用
    static var testRoot: URL {
        iosRoot.appending(path: "BuyLedgerTests")
    }

    /// App target 的掃描目錄
    static var productionRoot: URL {
        iosRoot.appending(path: "BuyLedger")
    }

    /// 遞迴讀取目錄下的 .swift 檔，移除整行註解後以完整檔案內容計算命中次數
    ///
    /// - Parameters:
    ///   - pattern: 要比對移除註解後原始碼的正規表示式
    ///   - root: 遞迴掃描的資料夾
    /// - Returns: 掃描的 .swift 檔數與命中總數
    /// - Throws: 正規表示式建立失敗、掃描目錄無法列舉 (`#require` 失敗) 或原始檔讀取失敗時丟出錯誤
    static func countMatches(
        pattern: String,
        under root: URL
    ) throws -> (fileCount: Int, matchCount: Int) {
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

    /// 逐行比對 `root` 下的 .swift 檔，略過排除前綴的檔案與整行註解，列出每個命中的相對路徑與行號
    ///
    /// - Parameters:
    ///   - root: 掃描的資料夾，相對路徑以此為根
    ///   - excludedPrefix: 相對於 `root` 的排除前綴，符合的檔案不掃描
    /// - Returns: 掃描的 .swift 檔數 (不含排除的檔案) 與每個命中的「相對路徑:行號」
    /// - Throws: 目錄無法列舉 (`#require` 失敗) 或原始檔讀取失敗時丟出錯誤
    static func storeConstructionFindings(
        under root: URL,
        excludingPrefix excludedPrefix: String
    ) throws -> (fileCount: Int, findings: [String]) {
        let files = try SwiftSourceFiles.swiftFiles(under: root)
            .sorted { lhs, rhs in lhs.path < rhs.path }

        var fileCount = 0
        var findings: [String] = []
        for file in files {
            let relativePath = SwiftSourceFiles.relativePath(of: file, under: root)
            guard !relativePath.hasPrefix(excludedPrefix) else {
                continue
            }
            let source = try String(contentsOf: file, encoding: .utf8)
            fileCount += 1
            let fileFindings = storeConstructionFindings(
                in: source,
                relativePath: relativePath,
                excludingPrefix: excludedPrefix
            )
            findings.append(contentsOf: fileFindings)
        }
        return (fileCount: fileCount, findings: findings)
    }

    /// 逐行比對合成原始碼中的 Store 建立，略過排除路徑與整行註解並保留原行號
    ///
    /// - Parameters:
    ///   - source: 要掃描的原始碼，不讀取檔案系統
    ///   - relativePath: 原始碼的相對路徑，用於排除判定與命中位置
    ///   - excludedPrefix: 不納入掃描的相對路徑前綴
    /// - Returns: 每個命中的「相對路徑:行號」，符合排除前綴時為空陣列
    static func storeConstructionFindings(
        in source: String,
        relativePath: String,
        excludingPrefix excludedPrefix: String
    ) -> [String] {
        guard !relativePath.hasPrefix(excludedPrefix) else {
            return []
        }
        var findings: [String] = []
        let lines = source.components(separatedBy: "\n")
        for (index, line) in lines.enumerated() where !isCommentLine(line) {
            if line.range(of: storeConstructionPattern, options: .regularExpression) != nil {
                findings.append("\(relativePath):\(index + 1)")
            }
        }
        return findings
    }

    /// 組合 Store 掃描失敗，沒有檔案時先回報掃描範圍失效，再附上所有命中位置
    ///
    /// - Parameters:
    ///   - fileCount: 可掃描的 Swift 檔數
    ///   - findings: 每個 Store 建立的命中位置
    /// - Returns: 零檔案的失敗訊息與原有命中位置，依此順序排列
    static func storeScanFailures(fileCount: Int, findings: [String]) -> [String] {
        var failures: [String] = []
        if fileCount == 0 {
            failures.append("沒有 .swift 檔可掃描")
        }
        return failures + findings
    }
}
