//
//  AccessibilityIdentifierSourceModel.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/13.
//

import Foundation

/// 原文與遮罩後視圖的對照，提供記號、行號與空隙分類
struct AccessibilityIdentifierSourceModel: Sendable {

    // MARK: - Properties

    /// 開啟新宣告的關鍵字與標記
    static let startKeywords: Set<String> = [
        "static", "let", "var", "func", "enum", "struct", "class", "actor", "protocol",
        "case", "subscript", "init", "deinit", "typealias", "extension", "import",
        "public", "private", "internal", "fileprivate", "final", "override", "mutating",
        "nonisolated", "indirect", "@", "#if", "#elseif", "#else", "#endif",
    ]

    /// 修飾詞，緊接在後的關鍵字與它屬於同一個宣告
    private static let modifiers: Set<String> = [
        "static", "public", "private", "internal", "fileprivate", "final", "override",
        "mutating", "nonisolated", "indirect",
    ]

    /// 原文字元
    let original: [Character]

    /// 遮罩後視圖的程式碼記號，註解與字串內容不在其中
    let tokens: [Token]

    /// 遮罩後視圖與原文的字元數是否一致，不一致時無法對照
    let isAligned: Bool

    // MARK: - Init

    /// 以原文建立對照，遮罩由共用的詞法工具產生
    ///
    /// - Parameter text: 原始檔原文
    init(text: String) {
        let characters = Array(text)
        let masked = Array(DependencyConventionLexing.blankedCommentsAndStrings(in: text))
        let isAligned = characters.count == masked.count
        self.original = characters
        self.isAligned = isAligned
        self.tokens = isAligned ? Self.tokenize(masked) : []
    }
}

// MARK: - Nested Types

extension AccessibilityIdentifierSourceModel {

    /// 遮罩後視圖中的一個程式碼記號
    struct Token: Sendable {

        /// 記號種類
        let kind: Kind

        /// 記號文字
        let text: String

        /// 在原文字元陣列中的起始位置
        let start: Int

        /// 在原文字元陣列中的結束位置，不含
        let end: Int

        /// 記號的種類
        enum Kind: Sendable {

            /// 識別字或關鍵字
            case identifier

            /// 數字
            case number

            /// 單一標點，`@` 也歸此類
            case punctuation

            /// 以 `#` 開頭的編譯指令，如 `#if`
            case directive
        }
    }

    /// 兩個記號之間被遮罩掉的內容，即註解與字串字面值
    enum Gap: Equatable, Sendable {

        /// 只有空白與註解
        case trivia

        /// 恰有一個單行、沒有跳脫與插值的字串字面值，前後只有空白與註解
        ///
        /// - Parameter content: 字面值內容，不含引號
        case literal(String)

        /// 其他內容：插值、raw string、多行字串、多個字面值，或插值之後的字串續行
        case other
    }
}

// MARK: - Internal Method

extension AccessibilityIdentifierSourceModel {

    /// 取得字元位置所在的行號
    ///
    /// - Parameter index: 原文字元位置
    /// - Returns: 從 1 起算的行號
    func line(at index: Int) -> Int {
        original[..<index].filter(\.isNewline).count + 1
    }

    /// 分類兩個位置之間的原文
    ///
    /// - Parameters:
    ///   - start: 起始位置
    ///   - end: 結束位置，不含
    /// - Returns: 只有空白與註解、恰有一個簡單字串字面值，或其他內容
    func gap(from start: Int, to end: Int) -> Gap {
        let first = skipTrivia(from: start, to: end)
        guard first < end else {
            return .trivia
        }
        guard let literal = simpleString(at: first, to: end) else {
            return .other
        }
        let rest = skipTrivia(from: literal.end, to: end)
        return rest == end ? .literal(literal.content) : .other
    }

    /// 跳過空白、行註解與可巢狀的區塊註解
    ///
    /// - Parameters:
    ///   - start: 起始位置
    ///   - limit: 結束位置，不含
    /// - Returns: 第一個不是空白也不是註解的位置，全是空白與註解時為 `limit`
    func skipTrivia(from start: Int, to limit: Int) -> Int {
        var index = start
        while index < limit {
            if original[index].isWhitespace {
                index += 1
            } else if hasPair("/", "/", at: index, limit: limit) {
                while index < limit, !original[index].isNewline {
                    index += 1
                }
            } else if hasPair("/", "*", at: index, limit: limit) {
                index = skipBlockComment(from: index, limit: limit)
            } else {
                break
            }
        }
        return index
    }

    /// 兩個位置之間是否恰為一個單行字串模板：以雙引號開頭與結尾，插值內沒有字串字面值
    ///
    /// - Parameters:
    ///   - start: 起始位置
    ///   - end: 結束位置，不含
    /// - Returns: 開頭可有空白與註解、結尾之後只有空白時為 `true`；多行字串、raw string 與插值內含字串字面值為 `false`
    func isSingleLineTemplate(from start: Int, to end: Int) -> Bool {
        let first = skipTrivia(from: start, to: end)
        guard first < end, original[first] == "\"" else {
            return false
        }
        let isMultiline = first + 2 < end
            && original[first + 1] == "\""
            && original[first + 2] == "\""
        guard !isMultiline else {
            return false
        }
        var index = first + 1
        while index < end {
            let character = original[index]
            if character == "\"" {
                return original[(index + 1)..<end].allSatisfy(\.isWhitespace)
            }
            if character.isNewline {
                return false
            }
            guard character == "\\" else {
                index += 1
                continue
            }
            guard index + 1 < end, !original[index + 1].isNewline else {
                return false
            }
            if original[index + 1] == "(" {
                guard let close = endOfInterpolation(from: index + 2, limit: end) else {
                    return false
                }
                index = close
            } else {
                index += 2
            }
        }
        return false
    }

    /// 在深度為 0 的位置依宣告關鍵字切分記號
    ///
    /// - Parameters:
    ///   - range: 要切分的記號索引範圍
    ///   - endLimit: 最後一個宣告的尾端空隙結束位置
    /// - Returns: 依出現順序排列的宣告
    func declarations(
        in range: Range<Int>,
        endLimit: Int
    ) -> [AccessibilityIdentifierDeclaration] {
        var starts: [Int] = []
        var depth = 0
        var isPreviousModifier = false
        for index in range {
            let token = tokens[index]
            let isStart = Self.startKeywords.contains(token.text) && !isPreviousModifier
            if depth == 0, starts.isEmpty || isStart {
                starts.append(index)
            }
            isPreviousModifier = depth == 0 && Self.modifiers.contains(token.text)
            depth = Self.nextDepth(depth, after: token)
        }
        return starts.indices.map { offset in
            let end = offset + 1 < starts.count ? starts[offset + 1] : range.upperBound
            let tailEnd = end < range.upperBound ? tokens[end].start : endLimit
            return AccessibilityIdentifierDeclaration(
                model: self,
                range: starts[offset]..<end,
                tailEnd: tailEnd
            )
        }
    }
}

// MARK: - Private Method

private extension AccessibilityIdentifierSourceModel {

    /// 把遮罩後的字元切成記號，空白與被遮罩的內容都略過
    ///
    /// - Parameter characters: 遮罩後的字元
    /// - Returns: 依出現順序排列的記號
    static func tokenize(_ characters: [Character]) -> [Token] {
        var tokens: [Token] = []
        var index = 0
        while index < characters.count {
            let start = index
            let character = characters[index]
            let kind: Token.Kind
            if character.isWhitespace {
                index += 1
                continue
            } else if character.isLetter || character == "_" {
                kind = .identifier
                index = end(ofWordStartingAt: index, in: characters)
            } else if character.isNumber {
                kind = .number
                index = end(ofWordStartingAt: index, in: characters)
            } else if character == "#",
                      index + 1 < characters.count,
                      characters[index + 1].isLetter {
                kind = .directive
                index = end(ofWordStartingAt: index + 1, in: characters)
            } else {
                kind = .punctuation
                index += 1
            }
            tokens.append(
                Token(
                    kind: kind,
                    text: String(characters[start..<index]),
                    start: start,
                    end: index
                )
            )
        }
        return tokens
    }

    /// 找出連續字母、數字與底線的結束位置
    ///
    /// - Parameters:
    ///   - start: 起始位置
    ///   - characters: 字元陣列
    /// - Returns: 連續字母、數字與底線之後的第一個位置
    static func end(ofWordStartingAt start: Int, in characters: [Character]) -> Int {
        var index = start
        while index < characters.count, isWordCharacter(characters[index]) {
            index += 1
        }
        return index
    }

    /// 是否為識別字與數字內可出現的字元
    ///
    /// - Parameter character: 要判斷的字元
    /// - Returns: 字母、數字或底線時為 `true`
    static func isWordCharacter(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || character == "_"
    }

    /// 依記號推進括號深度
    ///
    /// - Parameters:
    ///   - depth: 目前的深度
    ///   - token: 剛處理的記號
    /// - Returns: 處理完該記號後的深度
    static func nextDepth(_ depth: Int, after token: Token) -> Int {
        guard token.kind == .punctuation else {
            return depth
        }
        switch token.text {
        case "{", "(", "[":
            return depth + 1

        case "}", ")", "]":
            return max(0, depth - 1)

        default:
            return depth
        }
    }

    /// 指定位置起是否為兩個指定字元
    ///
    /// - Parameters:
    ///   - first: 第一個字元
    ///   - second: 第二個字元
    ///   - index: 檢查的位置
    ///   - limit: 結束位置，不含
    /// - Returns: 是否相符
    func hasPair(
        _ first: Character,
        _ second: Character,
        at index: Int,
        limit: Int
    ) -> Bool {
        index + 1 < limit && original[index] == first && original[index + 1] == second
    }

    /// 跳過可巢狀的區塊註解
    ///
    /// - Parameters:
    ///   - start: 開頭 `/*` 的位置
    ///   - limit: 結束位置，不含
    /// - Returns: 註解結尾之後的位置，沒有結尾時為 `limit`
    func skipBlockComment(from start: Int, limit: Int) -> Int {
        var index = start
        var depth = 0
        while index < limit {
            if hasPair("/", "*", at: index, limit: limit) {
                depth += 1
                index += 2
            } else if hasPair("*", "/", at: index, limit: limit) {
                depth -= 1
                index += 2
                if depth == 0 {
                    return index
                }
            } else {
                index += 1
            }
        }
        return limit
    }

    /// 讀取單行、沒有跳脫與插值的字串字面值
    ///
    /// - Parameters:
    ///   - start: 開頭雙引號的位置
    ///   - limit: 結束位置，不含
    /// - Returns: 字面值內容與結尾之後的位置；raw string、多行字串、含跳脫或插值時為 `nil`
    func simpleString(at start: Int, to limit: Int) -> (content: String, end: Int)? {
        guard original[start] == "\"" else {
            return nil
        }
        let isMultiline = start + 2 < limit
            && original[start + 1] == "\""
            && original[start + 2] == "\""
        guard !isMultiline else {
            return nil
        }
        var index = start + 1
        while index < limit {
            let character = original[index]
            if character == "\"" {
                return (String(original[(start + 1)..<index]), index + 1)
            }
            if character == "\\" || character.isNewline {
                return nil
            }
            index += 1
        }
        return nil
    }

    /// 找出字串插值結尾括號之後的位置，插值內不可有雙引號或換行
    ///
    /// - Parameters:
    ///   - start: 插值開括號之後的第一個位置
    ///   - limit: 結束位置，不含
    /// - Returns: 對應閉括號之後的位置；插值內有雙引號、換行或沒有閉括號時為 `nil`
    func endOfInterpolation(from start: Int, limit: Int) -> Int? {
        var depth = 1
        var index = start
        while index < limit {
            let character = original[index]
            if character == "\"" || character.isNewline {
                return nil
            }
            if character == "(" {
                depth += 1
            } else if character == ")" {
                depth -= 1
                if depth == 0 {
                    return index + 1
                }
            }
            index += 1
        }
        return nil
    }
}
