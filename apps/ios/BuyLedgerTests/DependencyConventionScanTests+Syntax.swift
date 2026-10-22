//
//  DependencyConventionScanTests+Syntax.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

import Foundation

// MARK: - Internal Method

extension DependencyConventionScanTests {

    /// 找出程式碼中與指定左括號配對的範圍，供規則跨檔使用
    ///
    /// - Parameters:
    ///   - source: 已移除註解與字串的原始碼
    ///   - openingIndex: 左大括號或小括號的位置
    /// - Returns: 含起始與結尾括號的範圍；起始位置超出原始碼、不是 `{` 或 `(`，或括號不成對時回傳 nil
    static func matchingDelimiter(
        in source: String,
        openingAt openingIndex: String.Index
    ) -> Range<String.Index>? {
        guard openingIndex < source.endIndex else {
            return nil
        }
        let openingCharacter = source[openingIndex]
        let closingCharacter: Character
        switch openingCharacter {
        case "{":
            closingCharacter = "}"

        case "(":
            closingCharacter = ")"

        default:
            return nil
        }

        var depth = 0
        var index = openingIndex
        while index < source.endIndex {
            if source[index] == openingCharacter {
                depth += 1
            } else if source[index] == closingCharacter {
                depth -= 1
                if depth == 0 {
                    return openingIndex..<source.index(after: index)
                }
            }
            index = source.index(after: index)
        }
        return nil
    }

    /// 找出 `testValue` 建構呼叫中最上層的引數範圍，供 `testValue` 規則跨檔使用
    ///
    /// - Parameters:
    ///   - source: 已移除註解與字串的原始碼
    ///   - openingIndex: 建構呼叫左小括號的位置
    ///   - propertyRange: 限定解析範圍的 `testValue` 屬性
    /// - Returns: 各引數在原始碼中的範圍；開括號不在屬性範圍或括號不成對時回傳 nil
    static func topLevelArguments(
        in source: String,
        openingAt openingIndex: String.Index,
        within propertyRange: Range<String.Index>
    ) -> [Range<String.Index>]? {
        guard propertyRange.contains(openingIndex) else {
            return nil
        }

        var parenthesisDepth = 1
        var bracketDepth = 0
        var braceDepth = 0
        var index = source.index(after: openingIndex)
        var argumentStart = index
        var arguments: [Range<String.Index>] = []

        while index < propertyRange.upperBound {
            switch source[index] {
            case "(":
                parenthesisDepth += 1

            case ")":
                parenthesisDepth -= 1
                if parenthesisDepth == 0 {
                    let lastArgument = argumentStart..<index
                    let remainder = source[lastArgument]
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if !remainder.isEmpty {
                        arguments.append(lastArgument)
                    }
                    return arguments
                }

            case "[":
                bracketDepth += 1

            case "]":
                bracketDepth -= 1

            case "{":
                braceDepth += 1

            case "}":
                braceDepth -= 1

            case "," where parenthesisDepth == 1 && bracketDepth == 0 && braceDepth == 0:
                arguments.append(argumentStart..<index)
                argumentStart = source.index(after: index)

            default:
                break
            }
            index = source.index(after: index)
        }
        return nil
    }
}
