//
//  UITestConventionScanner.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/15.
//

import Foundation

/// 掃描 UI 測試 target 的檔名、`@discardableResult` 回傳與失敗出口，守門 UI 測試規範
enum UITestConventionScanner {

    // MARK: - Properties

    /// `Tests/` 下測試檔允許的檔名後綴
    static let allowedNameSuffixes = ["UITests.swift", "TestSupport.swift"]

    /// 不符合檔名後綴但保留的檔案，以檔名列出並寫明理由
    static let namingExceptions: [NamingException] = [
        NamingException(
            fileName: "LaunchPerformanceTests.swift",
            reason: "kit 的效能測試命名為 `<TypeUnderTest>PerformanceTests`"
        ),
        NamingException(
            fileName: "AdaptiveLayoutCheckCounterexampleTests.swift",
            reason: "不啟動 App 的純值自我檢查"
        ),
    ]

    /// 允許呼叫非拋錯失敗出口的診斷檔，路徑相對於 UI target 根目錄
    static let diagnosticsRelativePaths: Set<String> = [
        "Support/XCTestCase+Diagnostics.swift",
        "Support/XCUIApplication+Diagnostics.swift",
    ]
}

// MARK: - Nested Types

extension UITestConventionScanner {

    /// 三條守門規則
    enum Rule: Sendable {

        /// `Tests/` 下測試檔的檔名
        case naming

        /// `@discardableResult` 後接回傳 `Bool` 的函式
        case discardableBool

        /// `Support/`、`Screens/` 與 `*TestSupport.swift` 中的非拋錯失敗出口
        case failureExit
    }

    /// 不符合檔名後綴但保留的檔案與理由
    struct NamingException: Sendable {

        /// 檔案名稱，不含目錄
        let fileName: String

        /// 保留此檔名的理由
        let reason: String
    }

    /// 一筆守門違規
    struct Violation: Sendable {

        /// 相對於 UI target 根目錄的檔案路徑
        let file: String

        /// 違規所在的行號，從 1 起算；檔名違規固定為第 1 行
        let line: Int

        /// 違規說明
        let detail: String

        /// `相對路徑:行號` 格式的位置
        var location: String {
            "\(file):\(line)"
        }
    }

    /// 一次規則掃描的結果
    struct ScanReport: Sendable {

        /// 納入該規則掃描範圍的檔案數
        let fileCount: Int

        /// 命中的違規，依檔案路徑與行號排列
        let violations: [Violation]
    }

    /// 掃描範圍內的一個檔案
    struct ScannedFile: Sendable {

        /// 相對於 UI target 根目錄的檔案路徑
        let relativePath: String

        /// 檔案的原始碼
        let source: String
    }
}

// MARK: - Computed Properties

extension UITestConventionScanner {

    /// UI 測試 target 的原始碼根目錄 (`apps/ios/BuyLedgerUITests`)
    static var uiRoot: URL {
        TestPaths.iosRoot.appending(path: "BuyLedgerUITests")
    }
}

// MARK: - Internal Method

extension UITestConventionScanner {

    /// 掃描 UI target 內規則範圍的所有檔案
    ///
    /// - Parameters:
    ///   - rule: 要套用的守門規則
    ///   - root: UI target 的根目錄
    /// - Returns: 掃描到的檔案數與違規清單
    /// - Throws: 列舉目錄或讀取原始碼失敗時丟出錯誤
    static func scan(_ rule: Rule, under root: URL) throws -> ScanReport {
        let files = try sourceFiles(under: root).filter { isInScope($0.relativePath, for: rule) }
        let findings = files.flatMap {
            violations(for: rule, relativePath: $0.relativePath, source: $0.source)
        }
        return ScanReport(fileCount: files.count, violations: findings)
    }

    /// 依規則檢查單一檔案，不在規則範圍內的檔案不回報
    ///
    /// - Parameters:
    ///   - rule: 要套用的守門規則
    ///   - relativePath: 相對於 UI target 根目錄的檔案路徑
    ///   - source: 檔案的原始碼
    /// - Returns: 該檔案的違規清單
    static func violations(for rule: Rule, relativePath: String, source: String) -> [Violation] {
        switch rule {
        case .naming:
            return namingViolations(relativePath: relativePath)

        case .discardableBool:
            return discardableBoolViolations(in: source, relativePath: relativePath)

        case .failureExit:
            return failureExitViolations(in: source, relativePath: relativePath)
        }
    }

    /// 判斷檔案是否屬於規則的掃描範圍
    ///
    /// - Parameters:
    ///   - relativePath: 相對於 UI target 根目錄的檔案路徑
    ///   - rule: 守門規則
    /// - Returns: 檔案是否在規則範圍內
    static func isInScope(_ relativePath: String, for rule: Rule) -> Bool {
        switch rule {
        case .naming:
            return relativePath.hasPrefix("Tests/")

        case .discardableBool:
            return true

        case .failureExit:
            return isFailureExitScope(relativePath)
        }
    }

    /// 檢查 `Tests/` 下的檔名是否使用允許的後綴，列名的例外除外
    ///
    /// - Parameter relativePath: 相對於 UI target 根目錄的檔案路徑
    /// - Returns: 檔名不符時回傳一筆違規，固定回報第 1 行
    static func namingViolations(relativePath: String) -> [Violation] {
        guard isInScope(relativePath, for: .naming) else {
            return []
        }
        let fileName = URL(fileURLWithPath: relativePath).lastPathComponent
        let isException = namingExceptions.contains { $0.fileName == fileName }
        let hasAllowedSuffix = allowedNameSuffixes.contains { fileName.hasSuffix($0) }
        let isAllowed = isException || hasAllowedSuffix
        guard !isAllowed else {
            return []
        }
        let violation = Violation(
            file: relativePath,
            line: 1,
            detail: "檔名應為 `<Name>UITests.swift` 或 `<Name>TestSupport.swift`"
        )
        return [violation]
    }

    /// 找出 `@discardableResult` 後接回傳 `Bool` 的函式，比對範圍為整個宣告直到左大括號
    ///
    /// - Parameters:
    ///   - source: 檔案的原始碼
    ///   - relativePath: 相對於 UI target 根目錄的檔案路徑
    /// - Returns: 違規清單，位置為 `@discardableResult` 所在行
    static func discardableBoolViolations(
        in source: String,
        relativePath: String
    ) -> [Violation] {
        let text = strippedLines(of: source).joined(separator: "\n")
        let pattern = #/@discardableResult\b[^{]*->\s*Bool\s*\{/#.wordBoundaryKind(.simple)
        return text.matches(of: pattern).map {
            Violation(
                file: relativePath,
                line: lineNumber(of: $0.range.lowerBound, in: text),
                detail: "@discardableResult 回傳 Bool，呼叫端可能丟棄結果而漏判"
            )
        }
    }

    /// 找出範圍內的檔案中呼叫非拋錯失敗出口的行
    ///
    /// - Parameters:
    ///   - source: 檔案的原始碼
    ///   - relativePath: 相對於 UI target 根目錄的檔案路徑
    /// - Returns: 違規清單，每個命中的行各回報一筆
    static func failureExitViolations(in source: String, relativePath: String) -> [Violation] {
        guard isInScope(relativePath, for: .failureExit) else {
            return []
        }
        // 預設的 Unicode 字詞邊界不在「字母.字母」之間斷開，`app.failWithDiagnostics(` 會漏判，改用簡單邊界
        let pattern = #/\bfailWithDiagnostics\s*\(|\bXCTFail\s*\(|\bXCTAssert\w*/#
            .wordBoundaryKind(.simple)
        var findings: [Violation] = []
        for (index, line) in strippedLines(of: source).enumerated() {
            guard let match = line.firstMatch(of: pattern) else {
                continue
            }
            let token = String(line[match.range])
            findings.append(
                Violation(
                    file: relativePath,
                    line: index + 1,
                    detail: "非拋錯的失敗出口 `\(token)`，應改用拋錯的 `stopWithDiagnostics` 或 `requireCondition`"
                )
            )
        }
        return findings
    }

    /// 把守門違規格式化為人可讀的條列訊息
    ///
    /// - Parameter violations: 違規清單
    /// - Returns: 違規說明，沒有違規時為「無」
    static func describe(_ violations: [Violation]) -> String {
        guard !violations.isEmpty else {
            return "無"
        }
        return violations.map { "\($0.location) (\($0.detail))" }.joined(separator: "、")
    }
}

// MARK: - Private Method

private extension UITestConventionScanner {

    /// 列出 UI target 內的 Swift 檔並讀取原始碼，依相對路徑排序
    ///
    /// - Parameter root: UI target 的根目錄
    /// - Returns: 每個檔案的相對路徑與原始碼
    /// - Throws: 列舉目錄或讀取檔案失敗時丟出錯誤
    static func sourceFiles(under root: URL) throws -> [ScannedFile] {
        let urls = try SwiftSourceFiles.swiftFiles(under: root)
        var files: [ScannedFile] = []
        for url in urls {
            let source = try String(contentsOf: url, encoding: .utf8)
            let relativePath = SwiftSourceFiles.relativePath(of: url, under: root)
            files.append(ScannedFile(relativePath: relativePath, source: source))
        }
        return files.sorted { $0.relativePath < $1.relativePath }
    }

    /// 逐行剝除註解與字串內容，保留每行位置以便回報行號
    ///
    /// - Parameter source: 檔案的原始碼
    /// - Returns: 每行剝除後的程式碼，索引加 1 即為行號
    static func strippedLines(of source: String) -> [String] {
        var mode = SwiftSourceStripping.StripMode.normal
        var lines: [String] = []
        for line in source.components(separatedBy: "\n") {
            lines.append(SwiftSourceStripping.stripCommentsAndStrings(from: line, mode: &mode))
        }
        return lines
    }

    /// 計算文字位置所在的行號，從 1 起算
    ///
    /// - Parameters:
    ///   - index: 文字中的位置
    ///   - text: 以換行符號分行的文字
    /// - Returns: 位置所在的行號
    static func lineNumber(of index: String.Index, in text: String) -> Int {
        text.unicodeScalars[..<index].filter { $0 == "\n" }.count + 1
    }

    /// 判斷檔案是否屬於失敗出口的範圍：`Support/`、`Screens/` 與 `Tests/` 下的 `*TestSupport.swift`，診斷檔除外
    ///
    /// - Parameter relativePath: 相對於 UI target 根目錄的檔案路徑
    /// - Returns: 檔案是否在失敗出口範圍內
    static func isFailureExitScope(_ relativePath: String) -> Bool {
        guard !diagnosticsRelativePaths.contains(relativePath) else {
            return false
        }
        if relativePath.hasPrefix("Support/") || relativePath.hasPrefix("Screens/") {
            return true
        }
        return relativePath.hasPrefix("Tests/") && relativePath.hasSuffix("TestSupport.swift")
    }
}
