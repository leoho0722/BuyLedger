//
//  LanguageProjectionScanner.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/30.
//

import Foundation

/// 掃描功能目錄中宣告 View 且讀取跨功能語言投影的位置，供語言投影守門使用
enum LanguageProjectionScanner {

    // MARK: - Properties

    /// 宣告 SwiftUI 視圖的程式碼標記，涵蓋 `struct X: View` 與 `extension X: View`
    private static let viewDeclarationMarker = ": View"

    /// 根功能偏好投影的讀法，功能目錄的 View 不得直接讀取
    private static let preferenceProjectionMarker = "preferences.language"
}

// MARK: - Nested Types

extension LanguageProjectionScanner {

    /// 讀取跨功能語言投影的單一位置
    struct Hit: Equatable, Sendable {

        /// 相對於 `BuyLedger/` 的檔案路徑
        let file: String

        /// 命中行的行號，從 1 起算
        let line: Int
    }

    /// 語言投影掃描結果
    struct ScanResult: Equatable, Sendable {

        /// 掃描到的 Swift 檔案數
        let scannedFileCount: Int

        /// 所有命中位置，依檔案路徑與行號排序
        let hits: [Hit]
    }
}

// MARK: - Internal Method

extension LanguageProjectionScanner {

    /// 掃描功能目錄內宣告 View 的 Swift 檔案，回傳掃描檔數與讀取跨功能語言投影的位置
    ///
    /// - Returns: 掃描結果，命中位置含根導覽宿主，由呼叫端與白名單比對
    /// - Throws: 目錄列舉或原始檔讀取失敗時丟出錯誤
    static func scan() throws -> ScanResult {
        let productionRoot = LayerBoundaryScanner.featuresRoot.deletingLastPathComponent()
        var scannedFileCount = 0
        var hits: [Hit] = []

        for file in try SwiftSourceFiles.swiftFiles(under: LayerBoundaryScanner.featuresRoot) {
            scannedFileCount += 1
            let lines = try strippedLines(of: file)
            guard lines.contains(where: { $0.contains(viewDeclarationMarker) }) else {
                continue
            }
            let relativePath = SwiftSourceFiles.relativePath(of: file, under: productionRoot)
            for (index, line) in lines.enumerated() where readsCrossFeatureLanguage(line) {
                hits.append(Hit(file: relativePath, line: index + 1))
            }
        }

        let sortedHits = hits.sorted { ($0.file, $0.line) < ($1.file, $1.line) }
        return ScanResult(scannedFileCount: scannedFileCount, hits: sortedHits)
    }

    /// 把命中位置格式化為附帶行號的說明，供測試失敗訊息使用
    ///
    /// - Parameter hits: 掃描命中的位置
    /// - Returns: 以頓號分隔的「檔案:行號」清單
    static func describe(_ hits: [Hit]) -> String {
        hits.map { "\($0.file):\($0.line)" }.joined(separator: "、")
    }
}

// MARK: - Private Method

private extension LanguageProjectionScanner {

    /// 讀取原始檔並逐行移除註解與字串內容
    ///
    /// - Parameter file: 要讀取的原始檔
    /// - Returns: 去除註解與字串後的每一行
    /// - Throws: 檔案讀取失敗時丟出錯誤
    static func strippedLines(of file: URL) throws -> [String] {
        let content = try String(contentsOf: file, encoding: .utf8)
        var stripMode = SwiftSourceStripping.StripMode.normal
        var lines: [String] = []
        for rawLine in content.components(separatedBy: "\n") {
            let stripped = SwiftSourceStripping.stripCommentsAndStrings(
                from: rawLine,
                mode: &stripMode
            )
            lines.append(stripped)
        }
        return lines
    }

    /// 判斷單行程式碼是否讀取跨功能語言投影：根功能偏好投影，或以 `@Shared` 讀取語言相關的共享鍵
    ///
    /// - Parameter line: 已去除註解與字串的程式碼行
    /// - Returns: 命中禁止讀法時為 `true`
    static func readsCrossFeatureLanguage(_ line: String) -> Bool {
        if line.contains(preferenceProjectionMarker) {
            return true
        }
        return line.contains("@Shared") && line.contains("anguage")
    }
}
