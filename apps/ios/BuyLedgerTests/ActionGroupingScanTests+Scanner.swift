//
//  ActionGroupingScanTests+Scanner.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/23.
//

import Foundation
import Testing

// MARK: - Nested Types

extension ActionGroupingScanTests {

    /// Action 分組守門的掃描規則
    enum ScanRule: Sendable {

        /// View 的 store.send 只能送 view action
        case viewStoreSend

        /// reducer 不得包裝子層 view action
        case reducerChildView
    }

    /// 一筆暫時性 action allowlist 條目
    struct AllowlistEntry: Sendable {

        /// 相對於 App source root 的檔案路徑
        let relativePath: String

        /// 送出內容必須完全相符的開頭
        let prefix: String

        /// 保留豁免的原因
        let reason: String

        /// 應移除豁免的實作步驟
        let removalStep: String

        /// 用檔案與送出前綴組成穩定的 allowlist key
        var key: String {
            "\(relativePath)|\(prefix)"
        }
    }

    /// 一個檔案或片段的掃描結果
    struct ScanResult: Sendable {

        /// 掃描到的違規
        let violations: [Violation]

        /// 已命中的 allowlist key
        let usedAllowlistKeys: Set<String>
    }

    /// 掃描命中的違規位置
    struct Violation: Sendable {

        /// 相對於 App source root 的檔案路徑
        let file: String

        /// 命中的程式碼或 allowlist 說明
        let detail: String
    }

}

// MARK: - Computed Properties

extension ActionGroupingScanTests {

    /// 測試 target 所在的 iOS 平台目錄
    static var iosRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    /// App production source root
    static var productionRoot: URL {
        iosRoot.appending(path: "BuyLedger")
    }

    /// 所有 Feature production source 的根目錄
    static var featuresRoot: URL {
        productionRoot.appending(path: "Features")
    }
}

// MARK: - Private Method

extension ActionGroupingScanTests {

    /// 掃描所有已遷移 View 的 store.send 呼叫
    ///
    /// - Parameter allowlist: 暫時性 action 豁免清單
    /// - Returns: 送出點與 allowlist 使用狀態
    /// - Throws: 原始檔讀取失敗時拋出錯誤
    static func scanMigratedViewFiles(allowlist: [AllowlistEntry]) throws(any Error) -> ScanResult {
        var files = migratedViewPaths.map { productionRoot.appending(path: $0) }
        for directory in migratedComponentDirectories {
            files.append(contentsOf: try swiftFiles(
                under: productionRoot.appending(path: directory)
            ))
        }

        var violations: [Violation] = []
        var usedAllowlistKeys = Set<String>()
        for file in files.sorted(by: { $0.path < $1.path }) {
            let source = try String(contentsOf: file, encoding: .utf8)
            let result = scanStoreSendContents(
                source,
                relativePath: relativePath(of: file, under: productionRoot),
                allowlist: allowlist
            )
            violations.append(contentsOf: result.violations)
            usedAllowlistKeys.formUnion(result.usedAllowlistKeys)
        }

        violations.append(contentsOf: unusedAllowlistViolations(
            allowlist: allowlist,
            usedKeys: usedAllowlistKeys
        ))
        return ScanResult(violations: violations, usedAllowlistKeys: usedAllowlistKeys)
    }

    /// 掃描單一檔案或片段中的 View store.send 呼叫
    ///
    /// - Parameters:
    ///   - source: 要掃描的原始碼
    ///   - relativePath: 相對於 App source root 的路徑
    ///   - allowlist: 暫時性 action 豁免清單
    /// - Returns: 掃描結果，不含未使用 allowlist 的追加違規
    static func scanStoreSendContents(
        _ source: String,
        relativePath: String,
        allowlist: [AllowlistEntry]
    ) -> ScanResult {
        let stripped = stripCommentsAndStrings(from: source)
        var violations: [Violation] = []
        var usedAllowlistKeys = Set<String>()

        for match in stripped.matches(of: storeSendPattern) {
            let suffix = String(stripped[match.range.upperBound...])
            if let entry = allowlist.first(where: {
                $0.relativePath == relativePath && suffix.hasPrefix($0.prefix)
            }) {
                usedAllowlistKeys.insert(entry.key)
                continue
            }

            guard suffix.firstMatch(of: viewActionPrefixPattern) == nil else {
                continue
            }
            violations.append(
                Violation(
                    file: relativePath,
                    detail: "View store.send 違規：\(snippet(suffix))"
                )
            )
        }

        return ScanResult(violations: violations, usedAllowlistKeys: usedAllowlistKeys)
    }

    /// 找出 Features 內包裝子層 view action 的寫法
    ///
    /// - Parameter files: 要掃描的 production Swift 檔案
    /// - Returns: 子層 view action 違規清單
    /// - Throws: 原始檔讀取失敗時拋出錯誤
    static func reducerChildViewViolations(in files: [URL]) throws(any Error) -> [Violation] {
        var violations: [Violation] = []
        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            violations.append(contentsOf: reducerChildViewViolations(
                in: source,
                relativePath: relativePath(of: file, under: productionRoot)
            ))
        }
        return violations
    }

    /// 找出指定檔案內容中的子層 view action 違規
    ///
    /// - Parameters:
    ///   - source: 要掃描的原始碼
    ///   - relativePath: 相對於 App source root 的路徑
    /// - Returns: 子層 view action 違規清單
    static func reducerChildViewViolations(
        in source: String,
        relativePath: String
    ) -> [Violation] {
        let stripped = stripCommentsAndStrings(from: source)
        return stripped.matches(of: reducerChildViewPattern).map { match in
            let detail = "reducer 子層 view action 違規：\(snippet(String(stripped[match.range])))"
            return Violation(
                file: relativePath,
                detail: detail
            )
        }
    }

    /// 找出未被任何送出點使用的 allowlist 條目
    ///
    /// - Parameters:
    ///   - allowlist: 暫時性 action 豁免清單
    ///   - usedKeys: 已命中的 allowlist key
    /// - Returns: 未使用條目的違規清單
    static func unusedAllowlistViolations(
        allowlist: [AllowlistEntry],
        usedKeys: Set<String>
    ) -> [Violation] {
        allowlist.compactMap { entry in
            guard !usedKeys.contains(entry.key) else {
                return nil
            }
            return Violation(
                file: entry.relativePath,
                detail: "未使用 allowlist：\(entry.prefix)，理由：\(entry.reason)，移除：\(entry.removalStep)"
            )
        }
    }

    /// 移除註解與字串字面值，保留程式碼空白與換行
    ///
    /// - Parameter source: 原始碼文字
    /// - Returns: 移除註解與字串後的程式碼文字
    static func stripCommentsAndStrings(from source: String) -> String {
        let stringPattern = #/"""[\s\S]*?"""|"([^"\\]|\\.)*"/#
        let commentPattern = #/\/\/[^\r\n]*|\/\*[\s\S]*?\*\//#
        return source
            .replacing(stringPattern, with: "")
            .replacing(commentPattern, with: "")
    }

    /// 把命中內容壓成適合錯誤訊息的一行
    ///
    /// - Parameter text: 命中後的原始文字
    /// - Returns: 可讀的短片段
    static func snippet(_ text: String) -> String {
        let normalized = text
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
        return String(normalized.prefix(96))
    }

    /// 把掃描違規格式化為人可讀的條列訊息
    ///
    /// - Parameter violations: 違規清單
    /// - Returns: 違規說明
    static func describe(_ violations: [Violation]) -> String {
        guard !violations.isEmpty else {
            return "無"
        }
        return violations.map { "\($0.file) (\($0.detail))" }.joined(separator: "、")
    }

    /// 列出根目錄下所有 Swift 原始檔
    ///
    /// - Parameter root: 掃描根目錄
    /// - Returns: Swift 檔案清單
    /// - Throws: 目錄讀取失敗時拋出錯誤
    static func swiftFiles(under root: URL) throws(any Error) -> [URL] {
        let enumerator = try #require(
            FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        )
        return enumerator.compactMap { item in
            guard let file = item as? URL, file.pathExtension == "swift" else {
                return nil
            }
            return file
        }
    }

    /// 把檔案絕對路徑轉成相對於 source root 的路徑
    ///
    /// - Parameters:
    ///   - file: 檔案絕對路徑
    ///   - root: 相對路徑的根目錄
    /// - Returns: 相對路徑
    static func relativePath(of file: URL, under root: URL) -> String {
        let filePath = file.standardizedFileURL.path
        let rootPath = root.standardizedFileURL.path
        guard filePath.hasPrefix(rootPath) else {
            return filePath
        }
        return String(filePath.dropFirst(rootPath.count + 1))
    }
}
