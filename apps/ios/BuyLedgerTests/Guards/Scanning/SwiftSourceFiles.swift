//
//  SwiftSourceFiles.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation
import Testing

/// 列舉守門掃描的 Swift 檔案並轉換顯示路徑
enum SwiftSourceFiles {}

// MARK: - Internal Method

extension SwiftSourceFiles {

    /// 列出根目錄下的 Swift 原始檔
    ///
    /// - Parameters:
    ///   - root: 掃描根目錄
    ///   - shouldIncludeGenerated: 是否納入生成檔目錄
    /// - Returns: 根目錄下的 Swift 檔案，預設排除路徑中含 Generated 目錄的檔案
    /// - Throws: 無法列舉目錄時丟出測試需求失敗
    static func swiftFiles(under root: URL, shouldIncludeGenerated: Bool = false) throws -> [URL] {
        let enumerator = try #require(
            FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        )
        var files: [URL] = []
        for case let file as URL in enumerator {
            if !shouldIncludeGenerated && file.pathComponents.contains("Generated") {
                continue
            }
            if file.pathExtension == "swift" {
                files.append(file)
            }
        }
        return files
    }

    /// 把檔案絕對路徑轉為相對於掃描根目錄的路徑
    ///
    /// - Parameters:
    ///   - file: 要顯示路徑的檔案
    ///   - root: 相對路徑的根目錄
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
