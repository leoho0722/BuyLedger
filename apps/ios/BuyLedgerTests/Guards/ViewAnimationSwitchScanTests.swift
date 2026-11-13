//
//  ViewAnimationSwitchScanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/13.
//

import Foundation
import Testing

/// UI 測試模式只由 harness 關閉 UIView 動畫，App 不得重新開啟的原始碼守門
struct ViewAnimationSwitchScanTests {

    /// 驗證 App 僅在 UI 測試 harness 以原參數接上 UIView 動畫開關一次，且掃描範圍不是空的
    ///
    /// - Throws: 正規表示式無法建立、目錄無法列舉或原始檔讀取失敗時丟出錯誤
    @Test
    func uiViewSetAnimationsEnabled_生產碼_只在UI測試harness以參數接線一次() throws {
        // Given
        let root = TestPaths.iosRoot.appending(path: "BuyLedger")
        let expression = try NSRegularExpression(
            pattern: #"\bUIView\s*\.\s*setAnimationsEnabled\s*\(\s*\$0\s*\)"#
        )

        // When
        let scan = try Self.countMatches(of: expression, under: root)

        // Then
        #expect(scan.fileCount > 0, "\(root.lastPathComponent) 沒有 .swift 檔可掃描")
        #expect(
            scan.matchCounts == ["App/Testing/BLUITestHarness.swift": 1],
            "UIView.setAnimationsEnabled($0) 的命中位置與次數：\(scan.matchCounts)"
        )
    }

    /// 驗證 App 原始碼的動畫開關呼叫只有 harness 的接線與判斷函式各一處，避免 harness 內外以型別、別名或非字面值參數改動設定，且掃描範圍不是空的
    ///
    /// - Throws: 正規表示式無法建立、目錄無法列舉或原始檔讀取失敗時丟出錯誤
    @Test
    func setAnimationsEnabled_生產碼_只在harness接線與判斷各出現一次() throws {
        // Given
        let root = TestPaths.iosRoot.appending(path: "BuyLedger")
        let expression = try NSRegularExpression(pattern: #"\bsetAnimationsEnabled\s*\("#)

        // When
        let scan = try Self.countMatches(of: expression, under: root)

        // Then
        #expect(scan.fileCount > 0, "\(root.lastPathComponent) 沒有 .swift 檔可掃描")
        #expect(
            scan.matchCounts == ["App/Testing/BLUITestHarness.swift": 2],
            "setAnimationsEnabled 的命中位置與次數：\(scan.matchCounts)"
        )
    }

    /// 驗證 App 不以字面值重新開啟 UIView 動畫，且掃描範圍不是空的
    ///
    /// - Throws: 正規表示式無法建立、目錄無法列舉或原始檔讀取失敗時丟出錯誤
    @Test
    func setAnimationsEnabledTrue_生產碼_不出現() throws {
        // Given
        let root = TestPaths.iosRoot.appending(path: "BuyLedger")
        let expression = try NSRegularExpression(pattern: #"\bsetAnimationsEnabled\s*\(\s*true\b"#)

        // When
        let scan = try Self.countMatches(of: expression, under: root)

        // Then
        #expect(scan.fileCount > 0, "\(root.lastPathComponent) 沒有 .swift 檔可掃描")
        #expect(scan.matchCounts == [:], "setAnimationsEnabled(true 的命中位置與次數：\(scan.matchCounts)")
    }
}

// MARK: - Private Method

private extension ViewAnimationSwitchScanTests {

    /// 遞迴掃描含生成檔的 Swift 原始碼，剝除註解與字串後按相對路徑計算命中次數
    ///
    /// - Parameters:
    ///   - expression: 要比對剝除後原始碼的正規表示式
    ///   - root: 遞迴掃描的資料夾
    /// - Returns: 掃描的 `.swift` 檔數與各命中檔案的相對路徑及次數
    /// - Throws: 目錄無法列舉 (`#require` 失敗) 或原始檔讀取失敗時丟出錯誤
    static func countMatches(
        of expression: NSRegularExpression,
        under root: URL
    ) throws -> (fileCount: Int, matchCounts: [String: Int]) {
        let files = try SwiftSourceFiles.swiftFiles(under: root, shouldIncludeGenerated: true)
        var matchCounts: [String: Int] = [:]
        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            var mode = SwiftSourceStripping.StripMode.normal
            let code = source.components(separatedBy: "\n")
                .map { SwiftSourceStripping.stripCommentsAndStrings(from: $0, mode: &mode) }
                .joined(separator: "\n")
            let range = NSRange(code.startIndex..<code.endIndex, in: code)
            let matchCount = expression.numberOfMatches(in: code, range: range)
            guard matchCount > 0 else {
                continue
            }
            let relativePath = SwiftSourceFiles.relativePath(of: file, under: root)
            matchCounts[relativePath] = matchCount
        }
        return (fileCount: files.count, matchCounts: matchCounts)
    }
}
