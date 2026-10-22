//
//  LayerBoundaryTests+FileScan.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation
import Testing

// MARK: - Internal Method

extension LayerBoundaryTests {

    /// 列出指定目錄下的 Swift 原始檔
    ///
    /// - Parameters:
    ///   - root: 掃描根目錄
    ///   - includingGenerated: 是否納入生成檔目錄
    /// - Returns: 符合目錄範圍的 Swift 檔案清單
    /// - Throws: 無法列舉目錄時拋出測試需求失敗
    static func swiftFiles(
        under root: URL,
        includingGenerated: Bool = false
    ) throws(any Error) -> [URL] {
        let enumerator = try #require(
            FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        )

        var files: [URL] = []
        for case let file as URL in enumerator {
            if !includingGenerated && file.pathComponents.contains(excludedDirectoryName) {
                continue
            }
            if file.pathExtension == "swift" {
                files.append(file)
            }
        }
        return files
    }

    /// 把違規清單格式化為附帶檔名與行號的說明
    ///
    /// - Parameter violations: 掃描命中的違規位置
    /// - Returns: 以頓號分隔的違規說明
    static func describe(_ violations: [Violation]) -> String {
        violations.map { "\($0.file):\($0.line) (\($0.typeName))" }.joined(separator: "、")
    }

    /// 把檔案路徑轉為相對於掃描根目錄的路徑
    ///
    /// - Parameters:
    ///   - file: 要轉換路徑的檔案
    ///   - root: 掃描根目錄
    /// - Returns: 根目錄內的相對路徑，或不在根目錄內的原始路徑
    static func relativePath(of file: URL, under root: URL) -> String {
        let filePath = file.standardizedFileURL.path
        let rootPath = root.standardizedFileURL.path
        guard filePath.hasPrefix(rootPath) else {
            return filePath
        }
        return String(filePath.dropFirst(rootPath.count + 1))
    }
}
