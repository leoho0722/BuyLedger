//
//  DesignSystemSourceScanTests+Scanner.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/5.
//

import Foundation
import Testing

// MARK: - Nested Types

extension DesignSystemSourceScanTests {

    /// 一列來源掃描情境，預期行號由 fixture 獨立指定
    struct SourceScanCase: Sendable {

        /// 包含待辨識引用或應略過內容的原始碼片段
        let source: String

        /// 該片段應回報的違規行號，空陣列表示應通過掃描
        let expectedLineNumbers: [Int]
    }

    /// 掃描命中的違規位置
    struct Violation {

        /// 相對於掃描根目錄的檔案路徑
        let file: String

        /// 命中所在的行號 (從 1 起算)
        let line: Int
    }

    /// 具名豁免標記的命中，含其理由文字
    struct ExemptionMarker {

        /// 標記所在位置
        let violation: Violation

        /// 標記冒號後的理由文字 (已去除頭尾空白)；為空字串表示未附理由
        let reason: String
    }
}

// MARK: - Computed Properties

extension DesignSystemSourceScanTests {

    /// 受掃描的產品程式碼目錄；只含 App target 本身
    static var productionRoot: URL {
        iosRoot.appending(path: "BuyLedger")
    }
}

// MARK: - Internal Method

extension DesignSystemSourceScanTests {

    /// 掃描產品程式碼的幣別名稱查表呼叫
    ///
    /// - Returns: 唯一入口以外命中 `localizedString(forCurrencyCode:)` 的位置
    /// - Throws: 原始檔讀取失敗時拋出錯誤
    static func currencyLookupViolations() throws(any Error) -> [Violation] {
        try findViolations(
            under: productionRoot,
            matching: currencyLookupPattern,
            excludingRelativePaths: ["Shared/Localization/CurrencyDisplayName.swift"]
        )
    }

    /// 掃描產品程式碼由 `locale` 自行推導語言的寫法
    ///
    /// - Returns: 唯一入口以外命中 `languageCode?.identifier` 的位置
    /// - Throws: 原始檔讀取失敗時拋出錯誤
    static func languageDerivationViolations() throws(any Error) -> [Violation] {
        try findViolations(
            under: productionRoot,
            matching: languageDerivationPattern,
            excludingRelativePaths: ["Shared/Localization/AppLanguage.swift"]
        )
    }

    /// 掃描產品程式碼的尺寸分類引用，只允許版面判斷入口使用
    ///
    /// - Returns: 版面判斷入口以外的尺寸分類引用位置
    /// - Throws: 原始檔讀取或目錄掃描失敗時拋出錯誤
    static func sizeClassViolations() throws(any Error) -> [Violation] {
        try findViolations(
            under: productionRoot,
            matching: sizeClassReferencePattern,
            excludingRelativePaths: ["Shared/DesignSystem/Foundations/BLLayoutClass.swift"],
            shouldHonorExemptions: shouldHonorSizeClassExemptions
        )
    }

    /// 以規則十一分類原始碼，與正式掃描共用不接受豁免的設定
    ///
    /// - Parameter source: 待分類的完整原始碼片段
    /// - Returns: 尺寸分類引用的違規行號，從第一行的 1 起算
    static func sizeClassViolations(in source: String) -> [Int] {
        violatingLineNumbers(
            in: source,
            matching: sizeClassReferencePattern,
            shouldHonorExemptions: shouldHonorSizeClassExemptions
        )
    }

    /// 掃描根目錄中的違規位置，忽略註解與字串內容
    ///
    /// - Parameters:
    ///   - root: 要掃描的目錄
    ///   - pattern: 要比對的違規樣式
    ///   - excludedFileNames: 不掃描的檔名集合
    ///   - excludedRelativePaths: 不掃描的相對路徑集合
    ///   - shouldHonorExemptions: 是否略過帶有豁免標記的違規行
    /// - Returns: 按檔名與行號排序的設計系統違規清單
    /// - Throws: 原始檔讀取失敗或無法列出目錄內容時拋出錯誤
    static func findViolations(
        under root: URL,
        matching pattern: NSRegularExpression,
        excludingFilesNamed excludedFileNames: Set<String> = [],
        excludingRelativePaths excludedRelativePaths: Set<String> = [],
        shouldHonorExemptions: Bool = true
    ) throws(any Error) -> [Violation] {
        var violations: [Violation] = []

        for file in try swiftFiles(under: root) {
            let relativeFile = relativePath(of: file, under: root)
            guard !excludedFileNames.contains(file.lastPathComponent),
                  !excludedRelativePaths.contains(relativeFile) else {
                continue
            }

            let source = try String(contentsOf: file, encoding: .utf8)
            let lineNumbers = violatingLineNumbers(
                in: source,
                matching: pattern,
                shouldHonorExemptions: shouldHonorExemptions
            )
            for lineNumber in lineNumbers {
                violations.append(Violation(file: relativeFile, line: lineNumber))
            }
        }

        return violations.sorted { left, right in
            (left.file, left.line) < (right.file, right.line)
        }
    }

    /// 逐行剝除註解與字串，再以指定樣式分類記憶體內的原始碼
    ///
    /// - Parameters:
    ///   - source: 待分類的完整原始碼片段
    ///   - pattern: 要比對的違規樣式
    ///   - shouldHonorExemptions: 是否略過帶有豁免標記的違規行
    /// - Returns: 違規行號，從第一行的 1 起算
    static func violatingLineNumbers(
        in source: String,
        matching pattern: NSRegularExpression,
        shouldHonorExemptions: Bool
    ) -> [Int] {
        var lineNumbers: [Int] = []
        var stripMode = StripMode.normal
        for (index, rawLine) in source.components(separatedBy: "\n").enumerated() {
            let stripped = stripCommentsAndStrings(from: rawLine, mode: &stripMode)
            guard lineViolates(pattern, in: stripped) else {
                continue
            }
            if shouldHonorExemptions && exemptionReason(onRawLine: rawLine) != nil {
                continue
            }
            lineNumbers.append(index + 1)
        }
        return lineNumbers
    }

    /// 掃描根目錄下所有具名豁免標記
    ///
    /// - Parameter root: 掃描根目錄
    /// - Returns: 豁免標記清單
    /// - Throws: 原始檔讀取失敗時拋出錯誤
    static func findExemptionMarkers(under root: URL) throws(any Error) -> [ExemptionMarker] {
        var markers: [ExemptionMarker] = []

        for file in try swiftFiles(under: root) {
            let rawLines = try String(contentsOf: file, encoding: .utf8)
                .components(separatedBy: "\n")

            for (index, rawLine) in rawLines.enumerated() {
                guard let reason = exemptionReason(onRawLine: rawLine) else {
                    continue
                }
                markers.append(
                    ExemptionMarker(
                        violation: Violation(
                            file: relativePath(of: file, under: root),
                            line: index + 1
                        ),
                        reason: reason
                    )
                )
            }
        }

        return markers.sorted { left, right in
            (left.violation.file, left.violation.line)
                < (right.violation.file, right.violation.line)
        }
    }

    /// 列出根目錄下所有 Swift 原始檔，排除生成檔目錄
    ///
    /// - Parameter root: 掃描根目錄
    /// - Returns: Swift 檔案清單
    /// - Throws: 目錄讀取失敗時拋出錯誤
    static func swiftFiles(under root: URL) throws(any Error) -> [URL] {
        let enumerator = try #require(
            FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        )

        var files: [URL] = []
        for case let file as URL in enumerator {
            if file.pathComponents.contains(excludedDirectoryName) {
                continue
            }
            if file.pathExtension == "swift" {
                files.append(file)
            }
        }
        return files
    }

    /// 把違規清單格式化為人可讀的條列訊息
    ///
    /// - Parameter violations: 要呈現在失敗訊息中的違規清單
    /// - Returns: 包含檔案相對路徑與行號的違規說明
    static func describe(_ violations: [Violation]) -> String {
        violations.map { "\($0.file):\($0.line)" }.joined(separator: "、")
    }

    /// 把檔案絕對路徑轉為相對於掃描根目錄的路徑，讓違規訊息簡潔可讀
    ///
    /// - Parameters:
    ///   - file: 要顯示路徑的檔案
    ///   - root: 作為路徑起點的掃描目錄
    /// - Returns: 檔案相對路徑；未以根目錄路徑開頭時保留絕對路徑
    static func relativePath(of file: URL, under root: URL) -> String {
        let filePath = file.standardizedFileURL.path
        let rootPath = root.standardizedFileURL.path
        guard filePath.hasPrefix(rootPath) else {
            return filePath
        }
        return String(filePath.dropFirst(rootPath.count + 1))
    }
}

// MARK: - Private Method

private extension DesignSystemSourceScanTests {

    /// 規則十一固定拒絕行級豁免，正式掃描與記憶體分類共用此設定
    static var shouldHonorSizeClassExemptions: Bool {
        false
    }

    /// 生成檔目錄不納入設計系統規則掃描
    static var excludedDirectoryName: String {
        "Generated"
    }

    /// 具名豁免標記的前綴；理由文字為冒號後的內容
    static var exemptionMarkerPrefix: String {
        "design-system-scan-exempt:"
    }

    /// 測試 target 所在的 iOS 平台目錄
    static var iosRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    /// 取得該行具名豁免標記的理由，去除頭尾空白
    ///
    /// - Parameter rawLine: 尚未剝除註解與字串的一行原始碼
    /// - Returns: 豁免理由；沒有標記時為 `nil`，未附理由時為空字串
    static func exemptionReason(onRawLine rawLine: String) -> String? {
        guard let range = rawLine.range(of: exemptionMarkerPrefix) else {
            return nil
        }
        return rawLine[range.upperBound...].trimmingCharacters(in: .whitespaces)
    }
}
