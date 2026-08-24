//
//  NumericInputGroupingScanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/2.
//

import Foundation
import Testing

/// 掃描式守門：數值輸入欄一律停用千分位分隔符
struct NumericInputGroupingScanTests {
    
    // MARK: - Tests
    
    /// 確認掃描能找到 `format: .number` 用法
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test func productionRootContainsNumberFormatFields() throws(any Error) {
        let occurrences = try Self.numberFormatOccurrences(under: Self.productionRoot)
        
        #expect(
            !occurrences.isEmpty, "掃描到 0 處 `format: .number`，掃描樣式疑似失效：\(Self.productionRoot.path)")
    }
    
    /// 每一處 `format: .number` 的 FormatStyle 鏈都必須帶 `.grouping(.never)`
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test func numberFormatFieldsSuppressGroupingSeparator() throws(any Error) {
        let occurrences = try Self.numberFormatOccurrences(under: Self.productionRoot)
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

// MARK: - Static Properties

private extension NumericInputGroupingScanTests {
    
    /// 測試 target 所在的 iOS 平台目錄
    static var iosRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
    
    /// 受掃描的產品程式碼目錄；只含 App target 本身，排除生成檔目錄
    static var productionRoot: URL {
        iosRoot.appending(path: "BuyLedger")
    }
    
    /// Generated 目錄不納入掃描
    static let excludedDirectoryName = "Generated"
    
    /// 掃描比對的錨點；本專案全部 `.number` FormatStyle 用法皆以此字面值開頭
    static let anchor = "format: .number"
}

// MARK: - Nested Types

private extension NumericInputGroupingScanTests {
    
    /// 掃描命中的一處 `format: .number` 用法
    struct Occurrence {
        
        // MARK: - Data Properties
        
        /// 相對於掃描根目錄的檔案路徑
        let file: String
        
        /// 命中所在的行號 (1-based)
        let line: Int
        
        /// 取得 `.number` 後的 FormatStyle 內容
        let tailExpression: String
    }
}

// MARK: - Private Method

private extension NumericInputGroupingScanTests {
    
    /// 掃描根目錄下所有 `format: .number` 用法
    /// - Parameter root: 掃描根目錄
    /// - Returns: 命中清單
    /// - Throws: 原始檔讀取失敗時拋出錯誤
    static func numberFormatOccurrences(under root: URL) throws(any Error) -> [Occurrence] {
        var occurrences: [Occurrence] = []
        
        for file in try swiftFiles(under: root) {
            let content = try String(contentsOf: file, encoding: .utf8)
            var searchStart = content.startIndex
            
            while let anchorRange = content.range(of: anchor, range: searchStart..<content.endIndex) {
                let tailStart = anchorRange.upperBound
                let tail = tailExpression(in: content, startingAt: tailStart)
                let line =
                    content[content.startIndex..<anchorRange.lowerBound].filter { $0 == "\n" }.count
                    + 1
                
                occurrences.append(
                    Occurrence(
                        file: relativePath(of: file, under: root),
                        line: line,
                        tailExpression: tail
                    ))
                searchStart = anchorRange.upperBound
            }
        }
        
        return occurrences.sorted { ($0.file, $0.line) < ($1.file, $1.line) }
    }
    
    /// 依括號深度取出呼叫端內容
    /// - Returns: 尾端表達式
    static func tailExpression(in content: String, startingAt start: String.Index) -> String {
        var depth = 0
        var index = start
        
        while index < content.endIndex {
            let character = content[index]
            if character == "(" {
                depth += 1
            } else if character == ")" {
                guard depth > 0 else { break }
                depth -= 1
            }
            index = content.index(after: index)
        }
        
        return String(content[start..<index])
    }
    
    /// 列出根目錄下所有 Swift 原始檔，排除生成檔目錄
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
    
    /// 把檔案絕對路徑轉為相對於掃描根目錄的路徑，讓違規訊息簡潔可讀
    /// - Returns: 檔案相對路徑
    static func relativePath(of file: URL, under root: URL) -> String {
        let filePath = file.standardizedFileURL.path
        let rootPath = root.standardizedFileURL.path
        guard filePath.hasPrefix(rootPath) else {
            return filePath
        }
        return String(filePath.dropFirst(rootPath.count + 1))
    }
    
    /// 把違規清單格式化為人可讀的條列訊息
    /// - Returns: 人可讀的命中說明
    static func describe(_ violations: [Occurrence]) -> String {
        violations.map { "\($0.file):\($0.line)" }.joined(separator: "、")
    }
}
