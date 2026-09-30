//
//  DependencyConventionScanTests+Lexing.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

// MARK: - Internal Method

extension DependencyConventionScanTests {

    /// 將註解、字串與 `#/…/#` 正規表示式中的內容換成空格並保留換行，供規則跨檔使用
    ///
    /// - Parameter source: 要處理的 Swift 原始碼
    /// - Returns: 非程式碼文字換成空格後、字元位置仍可對應原文的內容
    static func blankedCommentsAndStrings(in source: String) -> String {
        var characters = Array(source)
        var index = 0
        var isInLineComment = false
        var blockCommentDepth = 0
        var blockCommentInterpolationDepth: Int?
        var stringDelimiter: StringDelimiter?
        var stringParentInterpolationDepth: Int?
        var stringParents: [StringParent] = []
        var interpolationDepth: Int?
        var lineCommentInterpolationDepth: Int?

        /// 把非換行字元換成空格，讓命中位置仍對應原始碼
        ///
        /// - Parameter range: 要換成空格的字元位置
        func blank(_ range: Range<Int>) {
            for offset in range where !characters[offset].isNewline {
                characters[offset] = " "
            }
        }

        /// 找出 Swift 字串的起始分隔符組成
        ///
        /// - Parameter offset: 可能的字串起始位置
        /// - Returns: 字串起始分隔符；此處不是字串開頭時回傳 nil
        func openingDelimiter(at offset: Int) -> StringDelimiter? {
            var quoteIndex = offset
            while quoteIndex < characters.count && characters[quoteIndex] == "#" {
                quoteIndex += 1
            }
            guard quoteIndex < characters.count, characters[quoteIndex] == "\"" else {
                return nil
            }

            let hashCount = quoteIndex - offset
            let isMultiline = quoteIndex + 2 < characters.count
                && characters[quoteIndex + 1] == "\""
                && characters[quoteIndex + 2] == "\""
            return StringDelimiter(hashCount: hashCount, quoteCount: isMultiline ? 3 : 1)
        }

        /// 找出目前字串結尾分隔符的長度
        ///
        /// - Parameters:
        ///   - offset: 可能的字串結尾位置
        ///   - delimiter: 目前字串使用的分隔符組成
        /// - Returns: 若此處不是目前字串的結尾分隔符則回傳 nil，否則回傳分隔符長度
        func closingLength(at offset: Int, delimiter: StringDelimiter) -> Int? {
            let quoteEnd = offset + delimiter.quoteCount
            guard quoteEnd <= characters.count,
                  characters[offset..<quoteEnd].allSatisfy({ $0 == "\"" }) else {
                return nil
            }

            let hashEnd = quoteEnd + delimiter.hashCount
            guard hashEnd <= characters.count,
                  characters[quoteEnd..<hashEnd].allSatisfy({ $0 == "#" }) else {
                return nil
            }
            return delimiter.length
        }

        /// 找出字串跳脫符號後第一個不屬於井字號字串分隔符的字元
        ///
        /// - Parameters:
        ///   - offset: 反斜線所在位置
        ///   - delimiter: 目前字串使用的分隔符組成
        /// - Returns: 跳脫目標的位置；不是有效跳脫時回傳 nil
        func escapedCharacterIndex(at offset: Int, delimiter: StringDelimiter) -> Int? {
            var targetIndex = offset + 1
            for _ in 0..<delimiter.hashCount {
                guard targetIndex < characters.count, characters[targetIndex] == "#" else {
                    return nil
                }
                targetIndex += 1
            }
            return targetIndex < characters.count ? targetIndex : nil
        }

        while index < characters.count {
            if isInLineComment {
                if characters[index].isNewline {
                    isInLineComment = false
                    interpolationDepth = lineCommentInterpolationDepth
                } else {
                    blank(index..<(index + 1))
                }
                index += 1
                continue
            }

            if blockCommentDepth > 0 {
                if index + 1 < characters.count,
                   characters[index] == "/",
                   characters[index + 1] == "*" {
                    blank(index..<(index + 2))
                    blockCommentDepth += 1
                    index += 2
                    continue
                }
                if index + 1 < characters.count,
                   characters[index] == "*",
                   characters[index + 1] == "/" {
                    blank(index..<(index + 2))
                    blockCommentDepth -= 1
                    index += 2
                    if blockCommentDepth == 0 {
                        interpolationDepth = blockCommentInterpolationDepth
                    }
                    continue
                }
                if !characters[index].isNewline {
                    blank(index..<(index + 1))
                }
                index += 1
                continue
            }

            if let delimiter = stringDelimiter {
                if characters[index].isNewline && delimiter.quoteCount == 1 {
                    stringDelimiter = nil
                    interpolationDepth = stringParentInterpolationDepth
                    index += 1
                    continue
                }
                if characters[index] == "\\" {
                    if let escapedIndex = escapedCharacterIndex(at: index, delimiter: delimiter) {
                        let isInterpolation = characters[escapedIndex] == "("
                        blank(index..<(escapedIndex + 1))
                        index = escapedIndex + 1
                        if isInterpolation {
                            stringParents.append(
                                StringParent(
                                    delimiter: delimiter,
                                    interpolationDepth: stringParentInterpolationDepth
                                )
                            )
                            stringDelimiter = nil
                            interpolationDepth = 1
                        }
                        continue
                    }
                    blank(index..<(index + 1))
                    index += 1
                    continue
                }

                if let length = closingLength(at: index, delimiter: delimiter) {
                    blank(index..<(index + length))
                    index += length
                    stringDelimiter = nil
                    interpolationDepth = stringParentInterpolationDepth
                    continue
                }

                if !characters[index].isNewline {
                    blank(index..<(index + 1))
                }
                index += 1
                continue
            }

            var regexSlashIndex = index
            while regexSlashIndex < characters.count && characters[regexSlashIndex] == "#" {
                regexSlashIndex += 1
            }
            if regexSlashIndex > index,
               regexSlashIndex < characters.count,
               characters[regexSlashIndex] == "/" {
                var regexIndex = regexSlashIndex + 1
                var isEscaped = false
                var isInCharacterClass = false
                var regexEnd: Int?
                while regexIndex < characters.count {
                    let character = characters[regexIndex]
                    if isEscaped {
                        isEscaped = false
                    } else if character == "\\" {
                        isEscaped = true
                    } else if character == "[" {
                        isInCharacterClass = true
                    } else if character == "]" {
                        isInCharacterClass = false
                    } else if character == "/" && !isInCharacterClass {
                        let hashEnd = regexIndex + 1 + (regexSlashIndex - index)
                        let expectedClosingHashes = String(
                            repeating: "#",
                            count: regexSlashIndex - index
                        )
                        let closingHashRange = (regexIndex + 1)..<hashEnd
                        let hasExpectedClosingHashes = hashEnd <= characters.count
                            && String(characters[closingHashRange]) == expectedClosingHashes
                        if hasExpectedClosingHashes {
                            regexEnd = hashEnd
                            break
                        }
                    }
                    regexIndex += 1
                }
                if let regexEnd {
                    blank(index..<regexEnd)
                    index = regexEnd
                } else {
                    blank(index..<characters.count)
                    index = characters.count
                }
                continue
            }

            if index + 1 < characters.count,
               characters[index] == "/",
               characters[index + 1] == "/" {
                blank(index..<(index + 2))
                lineCommentInterpolationDepth = interpolationDepth
                isInLineComment = true
                index += 2
                continue
            }
            if index + 1 < characters.count,
               characters[index] == "/",
               characters[index + 1] == "*" {
                blank(index..<(index + 2))
                blockCommentInterpolationDepth = interpolationDepth
                blockCommentDepth = 1
                index += 2
                continue
            }

            if let delimiter = openingDelimiter(at: index) {
                blank(index..<(index + delimiter.length))
                stringDelimiter = delimiter
                stringParentInterpolationDepth = interpolationDepth
                index += delimiter.length
                continue
            }

            if let depth = interpolationDepth, characters[index] == "(" {
                interpolationDepth = depth + 1
                index += 1
                continue
            }
            if let depth = interpolationDepth, characters[index] == ")" {
                if depth == 1 {
                    blank(index..<(index + 1))
                    if let parent = stringParents.popLast() {
                        stringDelimiter = parent.delimiter
                        stringParentInterpolationDepth = parent.interpolationDepth
                    }
                    interpolationDepth = nil
                } else {
                    interpolationDepth = depth - 1
                }
                index += 1
                continue
            }

            index += 1
        }
        return String(characters)
    }
}
