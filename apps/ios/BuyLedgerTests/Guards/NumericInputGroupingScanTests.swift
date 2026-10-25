//
//  NumericInputGroupingScanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/2.
//

import Foundation
import Testing

/// 數值輸入欄守門規則的單元測試，涵蓋正式原始碼停用千分位分隔符的掃描
struct NumericInputGroupingScanTests {

    // MARK: - Properties

    /// 掃描比對的錨點，本專案的 `format: .number` 用法皆以此字面值開頭
    private static let anchor = "format: .number"

    /// 驗證掃描能找到正式原始碼中的 `format: .number` 用法，找不到時表示掃描樣式已失效
    ///
    /// - Throws: 原始檔掃描失敗時丟出錯誤
    @Test
    func numberFormatOccurrences_正式原始碼_找到數值輸入欄位() throws {
        // Given
        let root = Self.productionRoot

        // When
        let occurrences = try Self.numberFormatOccurrences(under: root)

        // Then
        #expect(
            !occurrences.isEmpty,
            "掃描到 0 處 `format: .number`，掃描樣式疑似失效：\(Self.productionRoot.path)"
        )
    }

    /// 驗證每處 `format: .number` 的 `FormatStyle` 鏈都帶有 `.grouping(.never)`，漏加的位置會列出
    ///
    /// - Throws: 原始檔掃描失敗時丟出錯誤
    @Test
    func numberFormatOccurrences_數值輸入欄位_皆停用千分位分隔符() throws {
        // Given
        let root = Self.productionRoot

        // When
        let occurrences = try Self.numberFormatOccurrences(under: root)

        // Then
        let violations = occurrences.filter { !$0.tailExpression.contains(".grouping(.never)") }
        #expect(
            violations.isEmpty,
            """
            以下數值輸入欄使用 format: .number 卻未加 .grouping(.never)，
            數字鍵盤無逗號鍵卻會被套上千分位分隔符：\(Self.describe(violations))
            """
        )
    }
}

// MARK: - Nested Types

private extension NumericInputGroupingScanTests {

    /// 掃描命中的一處 `format: .number` 用法
    struct Occurrence {

        /// 相對於掃描根目錄的檔案路徑
        let file: String

        /// 命中所在的行號 (1-based)
        let line: Int

        /// `.number` 後方的 `FormatStyle` 內容
        let tailExpression: String
    }
}

// MARK: - Private Method

private extension NumericInputGroupingScanTests {

    /// 測試 target 所在的 iOS 平台目錄
    static var iosRoot: URL {
        TestPaths.iosRoot
    }

    /// 受掃描的產品程式碼目錄；只含 App target 本身，排除生成檔目錄
    static var productionRoot: URL {
        iosRoot.appending(path: "BuyLedger")
    }

    /// 掃描根目錄下所有 `format: .number` 用法
    ///
    /// - Parameter root: 掃描根目錄
    /// - Returns: 命中清單
    /// - Throws: 原始檔讀取失敗時丟出錯誤
    static func numberFormatOccurrences(under root: URL) throws -> [Occurrence] {
        var occurrences: [Occurrence] = []

        for file in try SwiftSourceFiles.swiftFiles(under: root) {
            let content = try String(contentsOf: file, encoding: .utf8)
            var searchStart = content.startIndex

            while let anchorRange = content.range(
                of: anchor,
                range: searchStart..<content.endIndex
            ) {
                let tailStart = anchorRange.upperBound
                let tail = tailExpression(in: content, startingAt: tailStart)
                let precedingText = content[content.startIndex..<anchorRange.lowerBound]
                let line = precedingText.filter { $0 == "\n" }.count + 1

                occurrences.append(
                    Occurrence(
                        file: SwiftSourceFiles.relativePath(of: file, under: root),
                        line: line,
                        tailExpression: tail
                    )
                )
                searchStart = anchorRange.upperBound
            }
        }

        return occurrences.sorted { lhs, rhs in (lhs.file, lhs.line) < (rhs.file, rhs.line) }
    }

    /// 依括號深度取出呼叫端內容
    ///
    /// - Parameters:
    ///   - content: 含數值格式呼叫的原始碼
    ///   - start: 呼叫引數的起始位置
    /// - Returns: 尾端表達式
    static func tailExpression(in content: String, startingAt start: String.Index) -> String {
        var depth = 0
        var index = start

        while index < content.endIndex {
            let character = content[index]
            if character == "(" {
                depth += 1
            } else if character == ")" {
                guard depth > 0 else {
                    break
                }
                depth -= 1
            }
            index = content.index(after: index)
        }

        return String(content[start..<index])
    }

    /// 把違規清單格式化為人可讀的條列訊息
    ///
    /// - Parameter violations: 掃描命中的違規位置
    /// - Returns: 人可讀的命中說明
    static func describe(_ violations: [Occurrence]) -> String {
        violations.map { "\($0.file):\($0.line)" }.joined(separator: "、")
    }
}
