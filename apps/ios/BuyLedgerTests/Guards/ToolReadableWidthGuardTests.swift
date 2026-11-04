//
//  ToolReadableWidthGuardTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/30.
//

import Foundation
import Testing

/// 工具頁閱讀寬度的原始碼守門，確認工具的捲動容器與編輯表單直接接上對照表指定類型的閱讀寬度修飾，且工具頁不讀取全域尺寸分類
struct ToolReadableWidthGuardTests {

    // MARK: - Properties

    /// 單一工具容器的閱讀寬度對照項，路徑相對於 `apps/ios`，型別名稱取自檔名
    private struct Expectation {

        /// 相對於 `apps/ios` 的檔案路徑
        let path: String

        /// 必須直接接在容器節點之後的閱讀寬度修飾
        let modifier: String
    }

    /// 工具容器與編輯表單的閱讀寬度對照表
    private static let expectations: [Expectation] = [
        Expectation(
            path: "BuyLedger/Features/Customers/Presentation/Root/CustomersView.swift",
            modifier: ".blReadableScrollContent(.text)"
        ),
        Expectation(
            path: "BuyLedger/Features/FX/Presentation/Root/FxView.swift",
            modifier: ".blReadableScrollContent(.form)"
        ),
        Expectation(
            path: "BuyLedger/Features/Quote/Presentation/Root/QuoteView.swift",
            modifier: ".blReadableScrollContent(.form)"
        ),
        Expectation(
            path: "BuyLedger/Features/Lookups/Presentation/Root/Views/LookupItemList.swift",
            modifier: ".blReadableScrollContent(.text)"
        ),
        Expectation(
            path: "BuyLedger/Features/Lookups/Presentation/Root/Views/LookupNameEditorSheet.swift",
            modifier: ".blReadableScrollContent(.form)"
        ),
        Expectation(
            path: "BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift",
            modifier: ".blReadableScrollContent(.form)"
        ),
        Expectation(
            path: "BuyLedger/Features/Settings/Presentation/Root/SettingsView.swift",
            modifier: ".blReadableScrollContent(.form)"
        ),
    ]

    /// 工具頁的功能目錄，尺寸分類守門的掃描範圍
    static let toolFeatureDirectories = [
        "BuyLedger/Features/Customers",
        "BuyLedger/Features/FX",
        "BuyLedger/Features/Quote",
        "BuyLedger/Features/Lookups",
        "BuyLedger/Features/Settings",
    ]

    /// 工具頁禁止讀取的全域尺寸分類關鍵字
    static let forbiddenSizeClassTokens = [
        "blLayoutClass",
        "horizontalSizeClass",
        "verticalSizeClass",
    ]

    /// 驗證各工具的捲動容器與編輯表單都直接套用對照表指定類型的閱讀寬度修飾
    ///
    /// - Throws: 原始碼讀取失敗時丟出錯誤
    @Test
    func toolContainers_閱讀寬度修飾與類型_符合對照表() throws {
        // Given
        let expectations = Self.expectations

        // When
        var missing: [String] = []
        for expectation in expectations {
            let source = try Self.source(at: expectation.path)
            let reason = Self.modifierMismatch(
                in: source,
                path: expectation.path,
                modifier: expectation.modifier
            )
            if let reason {
                missing.append("\(expectation.path)：\(reason)")
            }
        }

        // Then
        #expect(missing.isEmpty, "以下工具容器或表單未套用對照表指定的閱讀寬度修飾：\(missing.joined(separator: "；"))")
    }

    /// 驗證工具頁的原始碼不讀取全域尺寸分類，閱讀寬度由各容器自己的可用區域決定
    ///
    /// - Throws: 目錄列舉或原始碼讀取失敗時丟出錯誤
    @Test
    func toolViews_工具目錄_不讀取全域尺寸分類() throws {
        // Given
        var files: [URL] = []
        for directory in Self.toolFeatureDirectories {
            let root = Self.iosRoot.appending(path: directory)
            let found = try SwiftSourceFiles.swiftFiles(under: root)
            files += found
        }
        try #require(files.count > 0, "工具目錄沒有掃到任何 Swift 檔，守門的掃描路徑可能已失效")

        // When
        var hits: [String] = []
        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            let code = String(Self.masked(source))
            let relativePath = SwiftSourceFiles.relativePath(of: file, under: Self.iosRoot)
            for token in Self.forbiddenSizeClassTokens where code.contains(token) {
                hits.append("\(relativePath) 含 \(token)")
            }
        }

        // Then
        #expect(hits.isEmpty, "工具頁不應讀取全域尺寸分類：\(hits.joined(separator: "；"))")
    }
}

// MARK: - Private Method

private extension ToolReadableWidthGuardTests {

    /// 測試 target 所在的 iOS 平台目錄 (`apps/ios`)
    static var iosRoot: URL {
        TestPaths.iosRoot
    }

    /// 讀取 `apps/ios` 底下的原始檔全文
    ///
    /// - Parameter relativePath: 相對於 `apps/ios` 的檔案路徑
    /// - Returns: 原始碼全文
    /// - Throws: 檔案讀取失敗時丟出錯誤
    static func source(at relativePath: String) throws -> String {
        try String(contentsOf: iosRoot.appending(path: relativePath), encoding: .utf8)
    }

    /// 檢查檔案中指定型別的宣告內，閱讀寬度修飾是否只出現一次，且直接接在容器節點之後
    ///
    /// - Parameters:
    ///   - source: 檔案原始碼
    ///   - path: 檔案路徑，檔名即要檢查的 View 型別名稱
    ///   - modifier: 對照表指定的閱讀寬度修飾
    /// - Returns: 不符合時的原因；符合時為 `nil`
    static func modifierMismatch(in source: String, path: String, modifier: String) -> String? {
        let chars = masked(source)
        let typeName = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        let scopes = declarationScopes(of: typeName, in: chars)
        guard !scopes.isEmpty else {
            return "找不到 \(typeName) 的宣告"
        }

        let starts = wordStarts(of: ".blReadableScrollContent", in: chars).filter { start in
            scopes.contains { $0.contains(start) }
        }
        guard let start = starts.first else {
            return "未套用閱讀寬度修飾"
        }
        guard starts.count == 1 else {
            return "閱讀寬度修飾出現 \(starts.count) 次，應只掛在容器節點上一次"
        }

        let written = normalized(modifierText(at: start, in: chars))
        guard written == normalized(modifier) else {
            return "套用的修飾為 \(written)，對照表要求 \(normalized(modifier))"
        }
        guard isAttached(modifierAt: start, in: chars, scopes: scopes) else {
            return "閱讀寬度修飾未直接接在 ScrollView、List 或 Form 容器節點之後"
        }
        return nil
    }

    /// 判斷閱讀寬度修飾是否緊接在某個 `ScrollView`、`List` 或 `Form` 容器的結尾大括號之後
    ///
    /// - Parameters:
    ///   - start: 修飾在掃描文字中的起始位置
    ///   - chars: 已遮蔽註解與字串的掃描文字
    ///   - scopes: 指定型別的宣告範圍
    /// - Returns: 修飾緊接在容器之後時為 `true`
    static func isAttached(
        modifierAt start: Int,
        in chars: [Character],
        scopes: [ClosedRange<Int>]
    ) -> Bool {
        for keyword in ["ScrollView", "List", "Form"] {
            for keywordStart in wordStarts(of: keyword, in: chars) {
                guard scopes.contains(where: { $0.contains(keywordStart) }) else {
                    continue
                }
                guard let open = openingBrace(in: chars, after: keywordStart + keyword.count),
                      let close = closingBrace(in: chars, openedAt: open)
                else {
                    continue
                }
                if skipWhitespace(in: chars, from: close + 1) == start {
                    return true
                }
            }
        }
        return false
    }

    /// 取得指定型別的宣告範圍，涵蓋 `struct` 與各個 `extension`，不含 `#Preview` 或其他型別
    ///
    /// - Parameters:
    ///   - typeName: 型別名稱
    ///   - chars: 已遮蔽註解與字串的掃描文字
    /// - Returns: 各宣告的大括號範圍
    static func declarationScopes(
        of typeName: String,
        in chars: [Character]
    ) -> [ClosedRange<Int>] {
        var scopes: [ClosedRange<Int>] = []
        for keyword in ["struct", "extension"] {
            for start in wordStarts(of: keyword, in: chars) {
                let nameStart = skipWhitespace(in: chars, from: start + keyword.count)
                guard matchesWord(typeName, in: chars, at: nameStart),
                      let open = openingBrace(in: chars, after: nameStart + typeName.count),
                      let close = closingBrace(in: chars, openedAt: open)
                else {
                    continue
                }
                scopes.append(open...close)
            }
        }
        return scopes
    }

    /// 將原始碼的註解與字串內容換成空白，保留長度與換行，讓結構比對不受註解與字面值干擾
    ///
    /// - Parameter source: 完整的原始碼
    /// - Returns: 與原始碼等長的字元陣列
    static func masked(_ source: String) -> [Character] {
        let chars = Array(source)
        var result: [Character] = []
        result.reserveCapacity(chars.count)
        var index = 0
        var isInString = false
        while index < chars.count {
            let char = chars[index]
            let next: Character? = index + 1 < chars.count ? chars[index + 1] : nil
            if isInString {
                if char == "\\" {
                    result.append(" ")
                    index += 1
                    if index < chars.count {
                        result.append(chars[index] == "\n" ? "\n" : " ")
                        index += 1
                    }
                    continue
                }
                if char == "\"" {
                    isInString = false
                    result.append(char)
                } else {
                    result.append(char == "\n" ? "\n" : " ")
                }
                index += 1
                continue
            }
            if char == "/", next == "/" {
                while index < chars.count, chars[index] != "\n" {
                    result.append(" ")
                    index += 1
                }
                continue
            }
            if char == "/", next == "*" {
                result.append(" ")
                result.append(" ")
                index += 2
                while index < chars.count {
                    if chars[index] == "*", index + 1 < chars.count, chars[index + 1] == "/" {
                        result.append(" ")
                        result.append(" ")
                        index += 2
                        break
                    }
                    result.append(chars[index] == "\n" ? "\n" : " ")
                    index += 1
                }
                continue
            }
            if char == "\"" {
                isInString = true
            }
            result.append(char)
            index += 1
        }
        return result
    }

    /// 回傳 `word` 以完整單字出現的所有起始位置
    ///
    /// - Parameters:
    ///   - word: 要尋找的關鍵字或修飾名稱
    ///   - chars: 已遮蔽註解與字串的掃描文字
    /// - Returns: 各出現位置的起始索引
    static func wordStarts(of word: String, in chars: [Character]) -> [Int] {
        let pattern = Array(word)
        guard let first = pattern.first, chars.count >= pattern.count else {
            return []
        }
        var starts: [Int] = []
        for start in 0...(chars.count - pattern.count) where chars[start] == first {
            let end = start + pattern.count
            guard chars[start..<end].elementsEqual(pattern) else {
                continue
            }
            let hasLeadingWord = first != "."
                && start > 0
                && isIdentifierCharacter(chars[start - 1])
            let hasTrailingWord = end < chars.count && isIdentifierCharacter(chars[end])
            if !hasLeadingWord, !hasTrailingWord {
                starts.append(start)
            }
        }
        return starts
    }

    /// 判斷 `word` 是否完整出現在指定位置，之後不接續識別字字元
    ///
    /// - Parameters:
    ///   - word: 要比對的名稱
    ///   - chars: 已遮蔽註解與字串的掃描文字
    ///   - start: 比對的起始位置
    /// - Returns: 完整出現時為 `true`
    static func matchesWord(_ word: String, in chars: [Character], at start: Int) -> Bool {
        let pattern = Array(word)
        let end = start + pattern.count
        guard end <= chars.count, chars[start..<end].elementsEqual(pattern) else {
            return false
        }
        return end == chars.count || !isIdentifierCharacter(chars[end])
    }

    /// 從指定位置往後找容器的開始大括號，途中遇到結束大括號、分號或等號時視為不是容器宣告
    ///
    /// - Parameters:
    ///   - chars: 已遮蔽註解與字串的掃描文字
    ///   - start: 搜尋的起始位置
    /// - Returns: 開始大括號的位置；找不到時為 `nil`
    static func openingBrace(in chars: [Character], after start: Int) -> Int? {
        var index = start
        while index < chars.count, index - start <= 300 {
            switch chars[index] {
            case "{":
                return index

            case "}", ";", "=":
                return nil

            default:
                index += 1
            }
        }
        return nil
    }

    /// 回傳與指定開始大括號配對的結束大括號位置
    ///
    /// - Parameters:
    ///   - chars: 已遮蔽註解與字串的掃描文字
    ///   - open: 開始大括號的位置
    /// - Returns: 結束大括號的位置；找不到時為 `nil`
    static func closingBrace(in chars: [Character], openedAt open: Int) -> Int? {
        var depth = 0
        var index = open
        while index < chars.count {
            if chars[index] == "{" {
                depth += 1
            } else if chars[index] == "}" {
                depth -= 1
                if depth == 0 {
                    return index
                }
            }
            index += 1
        }
        return nil
    }

    /// 略過空白與換行，回傳第一個非空白字元的位置
    ///
    /// - Parameters:
    ///   - chars: 已遮蔽註解與字串的掃描文字
    ///   - start: 搜尋的起始位置
    /// - Returns: 第一個非空白字元的位置
    static func skipWhitespace(in chars: [Character], from start: Int) -> Int {
        var index = start
        while index < chars.count, chars[index].isWhitespace {
            index += 1
        }
        return index
    }

    /// 取出從修飾起點開始，到配對右括號為止的文字
    ///
    /// - Parameters:
    ///   - start: 修飾的起始位置
    ///   - chars: 已遮蔽註解與字串的掃描文字
    /// - Returns: 修飾的完整文字
    static func modifierText(at start: Int, in chars: [Character]) -> String {
        var depth = 0
        var index = start
        while index < chars.count {
            if chars[index] == "(" {
                depth += 1
            } else if chars[index] == ")" {
                depth -= 1
                if depth == 0 {
                    return String(chars[start...index])
                }
            }
            index += 1
        }
        return String(chars[start..<chars.count])
    }

    /// 判斷字元是否可構成識別字，用來排除只有前綴或後綴相同的關鍵字
    ///
    /// - Parameter char: 要判斷的字元
    /// - Returns: 字元為字母、數字或底線時為 `true`
    static func isIdentifierCharacter(_ char: Character) -> Bool {
        char.isLetter || char.isNumber || char == "_"
    }

    /// 移除所有空白與換行，讓換行排版不影響比對
    ///
    /// - Parameter text: 要正規化的文字
    /// - Returns: 不含空白與換行的文字
    static func normalized(_ text: String) -> String {
        String(text.filter { !$0.isWhitespace })
    }
}
