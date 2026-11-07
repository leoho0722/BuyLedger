//
//  InputFieldConventionScanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/5.
//

import Foundation
import Testing

/// 文字輸入欄與系統搜尋 API 守門規則的單元測試，確認正式原始碼只在允許的位置直接使用
struct InputFieldConventionScanTests {

    // MARK: - Properties

    /// 允許直接宣告 `TextField` 的檔案名稱：兩個共用輸入元件、alert 內的新增選項欄位與 Preview 示範
    private static let allowedFileNames: Set<String> = [
        "BLTextField.swift",
        "BLNumberField.swift",
        "OptionPickerAddSection.swift",
        "BLReadableContentLayout.swift",
    ]

    /// 允許使用 `searchable`、`searchFocused`、`searchSelection` 的檔案相對路徑，只有共用搜尋入口
    private static let allowedSearchPaths: Set<String> = [
        "Shared/DesignSystem/Foundations/ViewModifiers/BLSearchableModifier.swift",
    ]

    /// 比對完整識別字 `TextField` 的樣式
    ///
    /// - Note: 前後不可緊接識別字字元，避免誤判 `BLTextField` 與 `TextFieldStyle`；不要求緊接左括號，泛型特殊化與括號前有空白的寫法才不會漏判
    private static let textFieldPattern = #"(?<![A-Za-z0-9_])TextField(?![A-Za-z0-9_])"#

    /// 比對完整識別字的系統搜尋 API 的樣式
    ///
    /// - Note: 前後不可緊接識別字字元；隱含 `self` 與括號前有空白的寫法也會命中
    private static let searchAPIPattern =
        #"(?<![A-Za-z0-9_])(searchable|searchFocused|searchSelection)(?![A-Za-z0-9_])"#

    /// 驗證允許清單內的檔案至少掃到一處 `TextField`，找不到時表示掃描樣式已失效
    ///
    /// - Throws: 原始檔掃描失敗時丟出錯誤
    @Test
    func textFieldOccurrences_允許清單檔案_至少掃到一處() throws {
        // Given
        let root = Self.productionRoot

        // When
        let occurrences = try Self.occurrences(under: root, matching: Self.textFieldPattern)
        let allowed = occurrences.filter { Self.isAllowedTextField($0) }

        // Then
        #expect(!allowed.isEmpty, "允許清單內掃到 0 處 `TextField`，掃描樣式疑似失效：\(root.path)")
    }

    /// 驗證正式原始碼只有允許清單檔案直接宣告 `TextField`，其餘位置會列出檔案與行號
    ///
    /// - Throws: 原始檔掃描失敗時丟出錯誤
    @Test
    func textFieldOccurrences_正式原始碼_僅允許清單檔案宣告() throws {
        // Given
        let root = Self.productionRoot

        // When
        let occurrences = try Self.occurrences(under: root, matching: Self.textFieldPattern)
        let violations = occurrences.filter { !Self.isAllowedTextField($0) }

        // Then
        #expect(
            violations.isEmpty,
            """
            以下位置直接宣告 `TextField`，文字輸入欄應改用 `BLTextField`，數字輸入欄應改用 `BLNumberField`，\
            焦點由呼叫端以 `FocusState` 傳入：\(Self.describe(violations))
            """
        )
    }

    /// 驗證共用搜尋入口檔案至少掃到一處系統搜尋 API，檔案搬走或樣式失效時測試失敗
    ///
    /// - Throws: 原始檔掃描失敗時丟出錯誤
    @Test
    func searchAPIOccurrences_共用搜尋入口檔案_至少掃到一處() throws {
        // Given
        let root = Self.productionRoot

        // When
        let occurrences = try Self.occurrences(under: root, matching: Self.searchAPIPattern)
        let allowed = occurrences.filter { Self.isAllowedSearchAPI($0) }

        // Then
        #expect(
            !allowed.isEmpty,
            "共用搜尋入口檔案掃到 0 處系統搜尋 API，檔案可能已搬移或掃描樣式失效：\(Self.allowedSearchPaths)"
        )
    }

    /// 驗證正式原始碼只有共用搜尋入口使用 `searchable`、`searchFocused`、`searchSelection`，其餘位置會列出檔案與行號
    ///
    /// - Throws: 原始檔掃描失敗時丟出錯誤
    @Test
    func searchAPIOccurrences_正式原始碼_僅共用搜尋入口使用() throws {
        // Given
        let root = Self.productionRoot

        // When
        let occurrences = try Self.occurrences(under: root, matching: Self.searchAPIPattern)
        let violations = occurrences.filter { !Self.isAllowedSearchAPI($0) }

        // Then
        #expect(
            violations.isEmpty,
            """
            以下位置直接使用 `searchable`、`searchFocused`、`searchSelection`，搜尋欄應改用 `.blSearchable(text:prompt:)`，\
            由共用入口統一套用焦點與游標追蹤：\(Self.describe(violations))
            """
        )
    }
}

// MARK: - Nested Types

private extension InputFieldConventionScanTests {

    /// 掃描命中的一處系統 API 或 `TextField` 宣告
    struct Occurrence {

        /// 相對於掃描根目錄的檔案路徑
        let file: String

        /// 命中所在的行號 (1-based)
        let line: Int
    }
}

// MARK: - Private Method

private extension InputFieldConventionScanTests {

    /// 受掃描的產品程式碼目錄；只含 App target 本身
    static var productionRoot: URL {
        TestPaths.iosRoot.appending(path: "BuyLedger")
    }

    /// 掃描根目錄下符合指定樣式的位置，註解與字串內容不計入
    ///
    /// - Parameters:
    ///   - root: 掃描根目錄
    ///   - pattern: 要比對的正規表示式樣式
    /// - Returns: 命中清單，依檔案與行號排序
    /// - Throws: 原始檔讀取或規則編譯失敗時丟出錯誤
    static func occurrences(under root: URL, matching pattern: String) throws -> [Occurrence] {
        let regex = try NSRegularExpression(pattern: pattern)
        var occurrences: [Occurrence] = []

        for file in try SwiftSourceFiles.swiftFiles(under: root) {
            let text = try String(contentsOf: file, encoding: .utf8)
            let relativePath = SwiftSourceFiles.relativePath(of: file, under: root)
            var mode = DesignSystemSourceLexer.StripMode.normal

            for (index, line) in text.components(separatedBy: "\n").enumerated() {
                let stripped = DesignSystemSourceLexer.stripCommentsAndStrings(
                    from: line,
                    mode: &mode
                )
                let range = NSRange(stripped.startIndex..., in: stripped)
                if regex.firstMatch(in: stripped, range: range) != nil {
                    occurrences.append(Occurrence(file: relativePath, line: index + 1))
                }
            }
        }

        return occurrences.sorted { lhs, rhs in (lhs.file, lhs.line) < (rhs.file, rhs.line) }
    }

    /// 判斷 `TextField` 命中是否位於允許清單檔案中，依檔名比對
    ///
    /// - Parameter occurrence: 掃描命中的位置
    /// - Returns: 命中所在的檔名是否在允許清單內
    static func isAllowedTextField(_ occurrence: Occurrence) -> Bool {
        allowedFileNames.contains((occurrence.file as NSString).lastPathComponent)
    }

    /// 把命中清單轉成可讀的檔案與行號列表
    ///
    /// - Parameter occurrences: 違規的命中清單
    /// - Returns: 以換行串接的檔案與行號字串
    static func describe(_ occurrences: [Occurrence]) -> String {
        occurrences
            .map { "\($0.file):\($0.line)" }
            .joined(separator: "\n")
    }

    /// 判斷系統搜尋 API 命中是否位於共用搜尋入口，依完整相對路徑比對，同名檔放在其他目錄不可通過
    ///
    /// - Parameter occurrence: 掃描命中的位置
    /// - Returns: 命中所在的相對路徑是否在允許清單內
    static func isAllowedSearchAPI(_ occurrence: Occurrence) -> Bool {
        allowedSearchPaths.contains(occurrence.file)
    }
}
