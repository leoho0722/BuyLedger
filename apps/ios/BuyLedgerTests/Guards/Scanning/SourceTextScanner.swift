//
//  SourceTextScanner.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation

/// 逐個 UTF-16 code unit 走訪原始碼的掃描器，座標與 `NSRegularExpression` 回傳的 `NSRange` 一致
struct SourceTextScanner {

    // MARK: - Properties

    /// 雙引號的 UTF-16 code unit，供逐字元掃描比對用
    static let quote = UInt16(UnicodeScalar("\"").value)

    /// 斜線的 UTF-16 code unit
    static let slash = UInt16(UnicodeScalar("/").value)

    /// 星號的 UTF-16 code unit
    static let star = UInt16(UnicodeScalar("*").value)

    /// 反斜線的 UTF-16 code unit
    private static let backslash = UInt16(UnicodeScalar("\\").value)

    /// 左括號的 UTF-16 code unit
    private static let openParen = UInt16(UnicodeScalar("(").value)

    /// 右括號的 UTF-16 code unit
    private static let closeParen = UInt16(UnicodeScalar(")").value)

    /// 換行的 UTF-16 code unit
    private static let newline = UInt16(UnicodeScalar("\n").value)

    /// 原始碼的 UTF-16 code unit，索引即 `NSRange` 使用的位置
    let units: [UInt16]

    // MARK: - Init

    /// 以原始碼建立掃描器
    ///
    /// - Parameter source: 要掃描的原始碼
    init(_ source: String) {
        units = Array(source.utf16)
    }
}

// MARK: - Internal Method

extension SourceTextScanner {

    /// 掃描一個字串字面值本體 (開頭引號之後) 直到其配對的結尾引號
    ///
    /// - Parameter start: 開頭引號之後的位置
    /// - Returns: 字串結束位置，找不到配對的結尾引號時為 `nil`
    func scanStringLiteralBody(from start: Int) -> Int? {
        let quote = Self.quote
        let backslash = Self.backslash
        let openParen = Self.openParen
        var index = start
        while index < units.count {
            let character = units[index]
            if character == backslash {
                guard index + 1 < units.count else {
                    return nil
                }
                if units[index + 1] == openParen {
                    guard let next = skipInterpolation(openParenIndex: index + 1) else {
                        return nil
                    }
                    index = next
                } else {
                    index += 2
                }
            } else if character == quote {
                return index
            } else {
                index += 1
            }
        }
        return nil
    }

    /// 找出字串內的頂層插值範圍
    ///
    /// - Returns: 頂層插值範圍
    func topLevelInterpolationRanges() -> [NSRange] {
        let backslash = Self.backslash
        let openParen = Self.openParen
        var ranges: [NSRange] = []
        var index = 0
        while index < units.count {
            let character = units[index]
            if character == backslash,
               index + 1 < units.count,
               units[index + 1] == openParen {
                guard let end = skipInterpolation(openParenIndex: index + 1) else {
                    break
                }
                ranges.append(NSRange(location: index, length: end - index))
                index = end
            } else if character == backslash {
                index += 2
            } else {
                index += 1
            }
        }
        return ranges
    }

    /// 找到指定位置所在行的結尾
    ///
    /// - Parameter start: 開始往後找的位置
    /// - Returns: 行尾位置
    func endOfLineIndex(from start: Int) -> Int {
        var index = start
        while index < units.count, units[index] != Self.newline {
            index += 1
        }
        return index
    }

    /// 跳過一段 `/* ... */` 區塊註解
    ///
    /// - Parameter start: 區塊註解開頭 `/*` 之後的位置
    /// - Returns: 區塊註解結束位置，沒有結尾時為 `nil`
    func skipBlockComment(from start: Int) -> Int? {
        let slash = Self.slash
        let star = Self.star
        var index = start
        while index + 1 < units.count {
            if units[index] == star, units[index + 1] == slash {
                return index + 2
            }
            index += 1
        }
        return nil
    }
}

// MARK: - Private Method

private extension SourceTextScanner {

    /// 跳過插值內容，依括號深度處理巢狀字串
    ///
    /// - Parameter openParenIndex: 插值左括號的位置
    /// - Returns: 插值結束位置，括號沒有配對時為 `nil`
    func skipInterpolation(openParenIndex: Int) -> Int? {
        let quote = Self.quote
        let backslash = Self.backslash
        let openParen = Self.openParen
        let closeParen = Self.closeParen
        var depth = 1
        var index = openParenIndex + 1
        while index < units.count {
            let character = units[index]
            if character == quote {
                guard let bodyEnd = scanStringLiteralBody(from: index + 1) else {
                    return nil
                }
                index = bodyEnd + 1
            } else if character == openParen {
                depth += 1
                index += 1
            } else if character == closeParen {
                depth -= 1
                index += 1
                if depth == 0 {
                    return index
                }
            } else if character == backslash {
                index += 2
            } else {
                index += 1
            }
        }
        return nil
    }
}
