//
//  BottomBarPlacementScanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/3.
//

import Foundation
import Testing

/// 生產碼不使用 `.bottomBar` 的原始碼掃描，底部工具列會被 compact 的分頁列蓋住，iPad 可拖曳視窗的下緣也可能超出螢幕
struct BottomBarPlacementScanTests {

    /// 驗證移除註解與字串後，App target 的生產碼不出現 `.bottomBar`，且掃描到的 `.swift` 檔數大於零
    ///
    /// - Throws: 目錄無法列舉 (`#require` 失敗) 或原始檔讀取失敗時丟出錯誤
    @Test
    func bottomBarPlacement_生產碼_不出現bottomBar() throws {
        // Given
        let root = TestPaths.iosRoot.appending(path: "BuyLedger")
        let expression = try NSRegularExpression(pattern: #"\.bottomBar\b"#)

        // When
        let scan = try Self.countMatches(of: expression, under: root)

        // Then
        #expect(scan.fileCount > 0, "\(root.lastPathComponent) 沒有 .swift 檔可掃描")
        #expect(
            scan.matchCount == 0,
            "\(root.lastPathComponent) 的 .bottomBar 命中 \(scan.matchCount) 處"
        )
    }
}

// MARK: - Private Method

private extension BottomBarPlacementScanTests {

    /// 遞迴列舉目錄下的 Swift 檔，剝除註解與字串後以完整檔案內容計算命中次數
    ///
    /// - Parameters:
    ///   - expression: 要比對剝除後原始碼的正規表示式
    ///   - root: 遞迴掃描的資料夾
    /// - Returns: 掃描的 `.swift` 檔數與命中總數
    /// - Throws: 目錄無法列舉 (`#require` 失敗) 或原始檔讀取失敗時丟出錯誤
    static func countMatches(
        of expression: NSRegularExpression,
        under root: URL
    ) throws -> (fileCount: Int, matchCount: Int) {
        let files = try SwiftSourceFiles.swiftFiles(under: root, shouldIncludeGenerated: true)
        var matchCount = 0
        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            var mode = SwiftSourceStripping.StripMode.normal
            let code = source.components(separatedBy: "\n")
                .map { SwiftSourceStripping.stripCommentsAndStrings(from: $0, mode: &mode) }
                .joined(separator: "\n")
            let range = NSRange(code.startIndex..<code.endIndex, in: code)
            matchCount += expression.numberOfMatches(in: code, range: range)
        }
        return (fileCount: files.count, matchCount: matchCount)
    }
}
