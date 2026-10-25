//
//  LocalizationCatalogLiteralScan.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation
import Testing

/// 掃描使用者可見的字串字面值與禁止的導覽標題寫法
enum LocalizationCatalogLiteralScan {

    // MARK: - Properties

    /// native `navigationTitle` 不得直接接收的本地化字面值 pattern
    private static let forbiddenNavigationTitlePatterns = [
        ".navigationTitle(\"",
        ".navigationTitle(Text(\"",
        ".navigationTitle(Text(LocalizedStringKey(",
    ]

    /// modifier 字串引數前的最大比對長度
    private static let modifierArgumentLookaheadLimit = 160

    /// 往回檢查行事曆標題的行數
    private static let calendarTitleLookbackLines = 3
}

// MARK: - Nested Types

extension LocalizationCatalogLiteralScan {

    /// 掃描結果中的單一缺漏字串；位置只用於讓失敗訊息能直接回到原始碼
    struct MissingCodeLiteral: Hashable {

        /// 未收錄於字串目錄的字串 key
        let key: String

        /// 字串所在的原始檔相對路徑與行號
        let location: String
    }
}

// MARK: - Computed Properties

extension LocalizationCatalogLiteralScan {

    /// 測試 target 所在的 iOS 平台目錄 (`apps/ios`)，由 `TestPaths.iosRoot` 取得
    static var iosRootURL: URL {
        TestPaths.iosRoot
    }
}

// MARK: - Internal Method

extension LocalizationCatalogLiteralScan {

    /// 掃描候選使用者可見字串，再套用排除規則
    ///
    /// - Parameters:
    ///   - sourceRoot: 原始碼根目錄
    ///   - catalogKeys: 已知的本地化 key
    /// - Returns: 待本地化字串清單
    /// - Throws: 原始檔讀取或掃描失敗時丟出錯誤
    static func missingUserVisibleCodeLiterals(
        in sourceRoot: URL,
        catalogKeys: Set<String>
    ) throws -> [MissingCodeLiteral] {
        let enumerator = try #require(
            FileManager.default.enumerator(at: sourceRoot, includingPropertiesForKeys: nil)
        )
        var missing = Set<MissingCodeLiteral>()

        for case let file as URL in enumerator where file.pathExtension == "swift" {
            let relativePath = file.path.replacingOccurrences(of: sourceRoot.path + "/", with: "")

            // 排除規則 1：測試替身與 Preview 資料不進入正式介面
            guard !relativePath.contains("App/Testing/"),
                  !relativePath.hasSuffix("+Samples.swift") else {
                continue
            }

            let source = try String(contentsOf: file, encoding: .utf8)
            let sanitizedSource = source.withPreviewBlocksRemoved()
            let lineRanges = sanitizedSource.lineRanges
            let lines = sanitizedSource.components(separatedBy: "\n")
            let literalMatches = sanitizedSource.literalMatches
            let visibleStarts = try Self.visibleLiteralStarts(
                in: sanitizedSource,
                literalMatches: literalMatches,
                lineRanges: lineRanges,
                lines: lines
            )
            let tokenExcludedStarts = try Self.tokenAnchoredExclusionStarts(in: sanitizedSource)

            for literal in literalMatches where visibleStarts.contains(literal.start) {
                let lineNumber = String.SourceLineRange.lineNumber(
                    containingUTF16Offset: literal.start,
                    in: lineRanges
                )
                let isLiteralExcluded = Self.isExcluded(
                    literal: literal,
                    lineNumber: lineNumber,
                    lines: lines,
                    tokenExcludedStarts: tokenExcludedStarts,
                    catalogKeys: catalogKeys
                )
                guard !isLiteralExcluded else {
                    continue
                }

                let variants = literal.localizationKeyVariants
                let key = variants.first ?? literal.raw
                let location = "\(relativePath):\(lineNumber + 1)"
                missing.insert(MissingCodeLiteral(key: key, location: location))
            }
        }

        return missing.sorted { lhs, rhs in
            lhs.key == rhs.key ? lhs.location < rhs.location : lhs.key < rhs.key
        }
    }

    /// 將原始碼中的連續空白折疊，讓掃描可涵蓋換行與不同縮排
    ///
    /// - Parameter source: 要正規化的原始碼文字
    /// - Returns: 連續空白被折疊成單一空白的文字
    static func normalizedWhitespace(_ source: String) -> String {
        source.replacing(/\s+/, with: " ")
    }

    /// 判斷 `source` 是否含有任一禁止的 `navigationTitle` pattern
    ///
    /// - Parameter source: 要檢查的 Swift 原始碼
    /// - Returns: 命中任一禁止 pattern 時為 `true`
    static func containsForbiddenNavigationTitlePattern(in source: String) -> Bool {
        forbiddenNavigationTitlePatterns.contains(where: source.contains)
    }
}

// MARK: - Private Method

private extension LocalizationCatalogLiteralScan {

    /// 收錄規則 A／B／C：找出候選使用者可見字串字面值的 start offset
    ///
    /// - Parameters:
    ///   - source: 原始碼
    ///   - literalMatches: 找到的字串字面值
    ///   - lineRanges: 原始碼行範圍
    ///   - lines: 原始碼行
    /// - Returns: 字串字面值的起始位置
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    static func visibleLiteralStarts(
        in source: String,
        literalMatches: [String.SourceLiteral],
        lineRanges: [String.SourceLineRange],
        lines: [String]
    ) throws -> Set<Int> {
        var visibleStarts = Set<Int>()

        // 大寫型別呼叫的未標籤字串視為顯示文字
        // 多行字串只處理 regex 可辨識的部分
        let structuralInitializerPattern = "\\b[A-Z][A-Za-z0-9]*\\s*\\(\\s*\"((?:\\\\.|[^\"\\\\])*)\""
        try visibleStarts.formUnion(
            source.literalCaptureStarts(matching: structuralInitializerPattern)
        )

        // 規則 B：SwiftUI modifier 的字串參數也算可見文字
        let visiblePatterns = [
            "\\bLocalizedStringKey\\s*\\([^\\n)]{0,\(Self.modifierArgumentLookaheadLimit)}?\"((?:\\\\.|[^\"\\\\])*)\"",
            "\\.(?:navigationTitle|accessibilityLabel|accessibilityValue|accessibilityHint|prompt|alert|confirmationDialog|rootNavigationTitle|help)\\s*\\(\\s*(?:Text\\s*\\(\\s*)?\"((?:\\\\.|[^\"\\\\])*)\"",
            "\\b(?:title|label|message|description|emptyTitle|emptyDescription|addButtonTitle|addAlertTitle|namePlaceholder|submitTitle|unit|centerTitle|accessibilitySummary|retryTitle|delta)\\s*:\\s*\"((?:\\\\.|[^\"\\\\])*)\"",
            "\\bsend\\s*\\(\\s*\\.[A-Za-z0-9_]+\\s*\\(\\s*\"((?:\\\\.|[^\"\\\\])*)\"",
            "\\b(?:errorMessage|truncationMessage)\\s*=\\s*\"((?:\\\\.|[^\"\\\\])*)\"",
        ]
        for pattern in visiblePatterns {
            try visibleStarts.formUnion(source.literalCaptureStarts(matching: pattern))
        }

        // 規則 C：display 與本地化型別的回傳值也算可見文字
        try visibleStarts.formUnion(
            source.literalStartsInsideDisplayScopes(
                literalMatches: literalMatches,
                lineRanges: lineRanges,
                lines: lines
            )
        )

        return visibleStarts
    }

    /// 找出排除規則中緊鄰字串開頭的模式
    ///
    /// - Parameter source: 原始碼
    /// - Returns: 排除標記的起始位置
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    static func tokenAnchoredExclusionStarts(in source: String) throws -> Set<Int> {
        let patterns = [
            // 排除規則 3：`Text(verbatim:)` 不需本地化
            "\\bText\\s*\\(\\s*verbatim\\s*:\\s*\"((?:\\\\.|[^\"\\\\])*)\"",
            // 排除 `APIError.message`：它只供網路層使用，UI 會轉成 `userMessage`
            "\\bAPIError\\.[A-Za-z0-9_]+\\s*\\(\\s*message\\s*:\\s*\"((?:\\\\.|[^\"\\\\])*)\"",
            // 排除規則 5a：錯誤與 log 格式字串只供診斷
            "\\.error\\s*\\(\\s*\"((?:\\\\.|[^\"\\\\])*)\"",
            "\\bos_log\\s*\\(\\s*\"((?:\\\\.|[^\"\\\\])*)\"",
            // 排除資源名稱參數，例如 `Color` 與 `Image` 的字串引數
            "\\bColor\\s*\\(\\s*\"((?:\\\\.|[^\"\\\\])*)\"",
            "\\bImage\\s*\\(\\s*\"((?:\\\\.|[^\"\\\\])*)\"",
            // 排除 `ModelConfiguration` 的資料庫配置名稱
            "\\bModelConfiguration\\s*\\(\\s*\"((?:\\\\.|[^\"\\\\])*)\"",
        ]
        var starts = Set<Int>()
        for pattern in patterns {
            try starts.formUnion(source.literalCaptureStarts(matching: pattern))
        }
        return starts
    }

    /// 套用無法用單一 pattern 表達的排除規則
    ///
    /// - Parameters:
    ///   - literal: 要判斷的字串字面值
    ///   - lineNumber: 字面值所在的行號
    ///   - lines: 原始碼行
    ///   - tokenExcludedStarts: 已由 token 規則排除的字面值起始位置
    ///   - catalogKeys: 已知的本地化 key
    /// - Returns: 字串是否應排除
    static func isExcluded(
        literal: String.SourceLiteral,
        lineNumber: Int,
        lines: [String],
        tokenExcludedStarts: Set<Int>,
        catalogKeys: Set<String>
    ) -> Bool {
        // 排除規則 2：註解不是使用者介面
        guard !String.isCommentOnly(lineNumber: lineNumber, in: lines) else {
            return true
        }

        if tokenExcludedStarts.contains(literal.start) {
            return true
        }

        let sourceLine = lines[lineNumber]

        // 排除 `Logger` 的字串參數，避免把診斷訊息當成文案
        if sourceLine.contains("Logger(") {
            return true
        }

        // 排除規則 6：EventKit 標題不需本地化
        let windowStart = max(0, lineNumber - Self.calendarTitleLookbackLines)
        let precedingWindow = lines[windowStart...lineNumber]
        if (precedingWindow.contains { $0.contains("reminderTitle") }) {
            return true
        }

        // 排除規則 7：系統品牌名、原文自稱與專有名詞依規格維持原文 (Verbatim)
        let verbatimLiterals: Set<String> = ["BuyLedger", "BL", "VIP", "正體中文", "English"]
        if verbatimLiterals.contains(literal.raw) {
            return true
        }

        let variants = literal.localizationKeyVariants

        // 排除規則 8：純動態插值 (字面值本身不含任何靜態可翻譯文字)
        if Set(variants) == ["%lld", "%@"] {
            return true
        }

        // 排除規則 9：單獨空白或標點不是可翻譯文字
        let isBlank = variants.allSatisfy {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let hasLetterOrNumber = variants.contains {
            $0.contains {
                $0.isLetter || $0.isNumber
            }
        }
        return isBlank || !hasLetterOrNumber || variants.contains(where: catalogKeys.contains)
    }
}
