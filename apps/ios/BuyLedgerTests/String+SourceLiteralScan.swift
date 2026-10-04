//
//  String+SourceLiteralScan.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation

// MARK: - Nested Types

extension String {

    /// 原始碼中的字串位置與內容
    struct SourceLiteral {

        /// 字面值在原始碼中的原文，保留跳脫序列與插值
        let raw: String

        /// 字面值內容在原始碼中的 UTF-16 起點
        let start: Int

        /// 字面值可能對應的字串目錄 key，插值依型別展開成 `%@` 與 `%lld` 兩種
        var localizationKeyVariants: [String] {
            let unescaped = logicalValue
                .replacingOccurrences(of: "\\n", with: "\n")
                .replacingOccurrences(of: "\\t", with: "\t")
                .replacingOccurrences(of: "\\\"", with: "\"")
                .replacingOccurrences(of: "\\\\", with: "\\")

            let scanner = SourceTextScanner(unescaped)
            let interpolations = scanner.topLevelInterpolationRanges()
            guard !interpolations.isEmpty else {
                return [unescaped]
            }

            // 將字面值中的 `%` 轉為 String Catalog 的 `%%`
            var variants = [""]
            var cursor = 0
            for range in interpolations {
                let prefixUnits = scanner.units[cursor..<range.location]
                let prefix = String(decoding: prefixUnits, as: UTF16.self)
                    .replacingOccurrences(of: "%", with: "%%")
                variants = variants.flatMap {
                    [$0 + prefix + "%@", $0 + prefix + "%lld"]
                }
                cursor = range.location + range.length
            }
            let suffix = String(decoding: scanner.units[cursor...], as: UTF16.self)
                .replacingOccurrences(of: "%", with: "%%")
            return Array(Set(variants.map { $0 + suffix })).sorted()
        }

        /// 解析多行字串內容
        private var logicalValue: String {
            guard raw.contains("\n") else {
                return raw
            }
            var rawLines = raw.components(separatedBy: "\n")
            // 移除三引號前後不屬於內容的空白行
            guard rawLines.count >= 2 else {
                return raw
            }
            let dedentWidth = rawLines.removeLast().count
            rawLines.removeFirst()
            let dedented = rawLines.map { line in
                guard line.count >= dedentWidth else {
                    return line
                }
                return String(line.dropFirst(dedentWidth))
            }

            var joined = ""
            for (index, line) in dedented.enumerated() {
                let isLastLine = index == dedented.count - 1
                if !isLastLine, line.hasSuffix("\\") {
                    joined += String(line.dropLast())
                } else if !isLastLine {
                    joined += line + "\n"
                } else {
                    joined += line
                }
            }
            return joined
        }
    }

    /// 原始碼的行範圍
    struct SourceLineRange {

        /// 此行在原始碼中的 UTF-16 範圍
        let range: NSRange

        /// 此行的行號，從 0 起算
        let lineNumber: Int

        /// 找出包含指定 UTF-16 offset 的行號
        ///
        /// - Parameters:
        ///   - offset: 要查詢的 UTF-16 offset
        ///   - ranges: 原始碼的行範圍
        /// - Returns: 命中的行號；找不到時回傳 0
        static func lineNumber(
            containingUTF16Offset offset: Int,
            in ranges: [SourceLineRange]
        ) -> Int {
            if let exact = ranges.first(where: { $0.contains(offset) }) {
                return exact.lineNumber
            }
            // 多行字串起點可能落在換行，回到三引號所在行
            return ranges.last { $0.range.location <= offset }?.lineNumber ?? 0
        }

        /// 判斷 UTF-16 offset 是否落在此行範圍內
        ///
        /// - Parameter utf16Offset: 要檢查的 UTF-16 offset
        /// - Returns: offset 是否位於此行範圍
        func contains(_ utf16Offset: Int) -> Bool {
            NSLocationInRange(utf16Offset, range)
        }
    }
}

// MARK: - Computed Properties

extension String {

    /// 掃描原始碼中所有頂層字串字面值的起訖位置
    var literalMatches: [SourceLiteral] {
        let quote = SourceTextScanner.quote
        let slash = SourceTextScanner.slash
        let star = SourceTextScanner.star
        let scanner = SourceTextScanner(self)
        let units = scanner.units
        var results: [SourceLiteral] = []
        var index = 0
        while index < units.count {
            let character = units[index]
            if character == quote {
                let contentStart = index + 1
                if let contentEnd = scanner.scanStringLiteralBody(from: contentStart) {
                    let raw = String(decoding: units[contentStart..<contentEnd], as: UTF16.self)
                    results.append(SourceLiteral(raw: raw, start: contentStart))
                    index = contentEnd + 1
                    continue
                }
            } else if character == slash, index + 1 < units.count {
                let next = units[index + 1]
                if next == slash {
                    index = scanner.endOfLineIndex(from: index)
                    continue
                } else if next == star, let end = scanner.skipBlockComment(from: index + 2) {
                    index = end
                    continue
                }
            }
            index += 1
        }
        return results
    }

    /// 每一行在原始碼中的 UTF-16 範圍與行號
    var lineRanges: [SourceLineRange] {
        let totalLength = utf16.count
        var ranges: [SourceLineRange] = []
        var offset = 0
        for (lineNumber, line) in components(separatedBy: "\n").enumerated() {
            let length = line.utf16.count
            let lineRange = NSRange(location: offset, length: length)
            ranges.append(SourceLineRange(range: lineRange, lineNumber: lineNumber))
            offset += length + (offset + length < totalLength ? 1 : 0)
        }
        return ranges
    }
}

// MARK: - Internal Method

extension String {

    /// 判斷指定行是否只有註解或空白
    ///
    /// - Parameters:
    ///   - lineNumber: 要檢查的行號
    ///   - lines: 原始碼行
    /// - Returns: 指定行是否為註解行；行號超出範圍時視為註解行
    static func isCommentOnly(lineNumber: Int, in lines: [String]) -> Bool {
        guard lines.indices.contains(lineNumber) else {
            return true
        }
        let trimmed = lines[lineNumber].trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("//") || trimmed.hasPrefix("*") || trimmed.hasPrefix("/*")
    }

    /// 移除 `#Preview` 區塊內容，保留原始行數供掃描使用
    ///
    /// - Returns: 移除 preview 內容後的原始碼
    func withPreviewBlocksRemoved() -> String {
        var output: [String] = []
        var previewBraceDepth = 0
        for line in components(separatedBy: "\n") {
            let isPreviewStart = line.contains("#Preview")
            if isPreviewStart || previewBraceDepth > 0 {
                let opens = line.filter { $0 == "{" }.count
                let closes = line.filter { $0 == "}" }.count
                previewBraceDepth += opens - closes
                output.append(String(repeating: " ", count: line.utf16.count))
            } else {
                output.append(line)
            }
            if previewBraceDepth <= 0 {
                previewBraceDepth = 0
            }
        }
        return output.joined(separator: "\n")
    }

    /// 找出符合指定正規表示式的字串 literal 起始位置
    ///
    /// - Parameter pattern: 要比對的正規表示式
    /// - Returns: 命中 literal 的 UTF-16 起始位置集合
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    func literalCaptureStarts(matching pattern: String) throws(any Error) -> Set<Int> {
        let expression = try NSRegularExpression(pattern: pattern)
        let fullRange = NSRange(location: 0, length: utf16.count)
        var starts = Set<Int>()
        expression.enumerateMatches(in: self, range: fullRange) { match, _, _ in
            guard let match, match.numberOfRanges > 1 else {
                return
            }
            let capture = match.range(at: 1)
            if capture.location != NSNotFound {
                starts.insert(capture.location)
            }
        }
        return starts
    }

    /// 找出顯示範圍內的字串位置
    ///
    /// - Parameters:
    ///   - literalMatches: 找到的字串字面值
    ///   - lineRanges: 原始碼行範圍
    ///   - lines: 原始碼行
    /// - Returns: 顯示範圍內的字串起始位置
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    func literalStartsInsideDisplayScopes(
        literalMatches: [SourceLiteral],
        lineRanges: [SourceLineRange],
        lines: [String]
    ) throws(any Error) -> Set<Int> {
        var starts = Set<Int>()
        var braceDepth = 0
        // 每個 scope 記錄結束門檻，依 braceDepth 判斷是否結束
        var activeScopeMinimumDepths: [Int] = []
        let literalsByLine = Dictionary(grouping: literalMatches) {
            SourceLineRange.lineNumber(containingUTF16Offset: $0.start, in: lineRanges)
        }

        for (lineNumber, line) in lines.enumerated() {
            let startsDisplayScope = try line.isDisplayScopeDeclaration
            let opens = line.filter { $0 == "{" }.count
            let closes = line.filter { $0 == "}" }.count
            let depthAfterLine = braceDepth + opens - closes

            if startsDisplayScope && opens > closes {
                activeScopeMinimumDepths.append(max(depthAfterLine, 1))
            }

            if (startsDisplayScope || !activeScopeMinimumDepths.isEmpty),
               !Self.isCommentOnly(lineNumber: lineNumber, in: lines) {
                for literal in literalsByLine[lineNumber] ?? [] {
                    starts.insert(literal.start)
                }
            }

            braceDepth = depthAfterLine
            activeScopeMinimumDepths.removeAll { braceDepth < $0 }
        }

        return starts
    }
}

// MARK: - Private Method

private extension String {

    /// 這一行是否宣告了會回傳使用者可見文案的屬性或函式
    ///
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    var isDisplayScopeDeclaration: Bool {
        get throws(any Error) {
            guard contains("{") else {
                return false
            }

            // 依宣告型別判定顯示文字，不逐一列舉屬性名稱
            // 同時處理計算屬性與函式的本地化型別回傳值
            let typedDeclarationPattern = "\\b(?:var|func)\\s+\\w+\\s*(?:\\([^)]*\\))?\\s*:\\s*(?:LocalizedStringKey|LocalizedStringResource|String\\.LocalizationValue)\\b"
            let regex = try NSRegularExpression(pattern: typedDeclarationPattern)
            if regex.firstMatch(in: self, range: NSRange(startIndex..., in: self)) != nil {
                return true
            }
            if contains("-> LocalizedStringResource") || contains("-> LocalizedStringKey")
                || contains("String.LocalizationValue") {
                return true
            }

            // 依名稱辨識無法從型別判定的使用者可見文案
            let displayProperties = [
                "title",
                "entryTitle",
                "addButtonTitle",
                "emptyTitle",
                "addFormTitle",
                "renameSheetTitle",
                "navigationTitleKey",
                "daySectionTitle",
                "sparklineSummary",
                "summaryFailureMessage",
                "reminderTitle",
            ]
            return try displayProperties.contains { name in
                let regex = try NSRegularExpression(pattern: "\\b(?:var|func)\\s+\(name)\\b")
                return regex.firstMatch(in: self, range: NSRange(startIndex..., in: self)) != nil
            }
        }
    }
}
