//
//  DesignSystemSourceLexer.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/5.
//

import Foundation

/// 逐行剝除註解與字串，供設計系統與清單快照守門共用
enum DesignSystemSourceLexer {}

// MARK: - Nested Types

extension DesignSystemSourceLexer {

    /// `stripCommentsAndStrings` 的逐行掃描狀態
    enum StripMode {

        /// 一般程式碼
        case normal

        /// 位於 `/* ... */` 區塊註解內
        case blockComment

        /// 位於 `"""..."""` 多行字串字面值內
        case tripleQuotedString
    }
}

// MARK: - Internal Method

extension DesignSystemSourceLexer {

    /// 逐個 Unicode 碼位剝除 `//` 行註解、非巢狀區塊註解與單行、多行一般字串
    ///
    /// - Parameters:
    ///   - line: 待剝除的一行原始碼
    ///   - mode: 跨行保留的註解或多行字串狀態
    /// - Returns: 移除註解與字串後的內容
    /// - Note: 字串依反斜線跳脫狀態辨識結尾
    /// - Note: 區塊註解結束時補一個空格保留文字邊界
    /// - Note: 多行字串的跳脫狀態不跨行，行尾的反斜線不會跳脫下一行的開頭
    /// - Note: 未建模的詞法形式可能讓之後的程式碼被漏判或誤判
    static func stripCommentsAndStrings(from line: String, mode: inout StripMode) -> String {
        let scalars = Array(line.unicodeScalars)
        var result = String.UnicodeScalarView()
        var index = 0
        var isInSingleLineString = false
        var isEscaped = false

        while index < scalars.count {
            switch mode {
            case .blockComment:
                if hasPrefix(scalars, at: index, marker: ["*", "/"]) {
                    mode = .normal
                    result.append(" ")
                    index += 2
                } else {
                    index += 1
                }
                continue

            case .tripleQuotedString:
                let scalar = scalars[index]
                if isEscaped {
                    isEscaped = false
                    index += 1
                } else if scalar == "\\" {
                    isEscaped = true
                    index += 1
                } else if hasPrefix(scalars, at: index, marker: ["\"", "\"", "\""]) {
                    mode = .normal
                    index += 3
                } else {
                    index += 1
                }
                continue

            case .normal:
                break
            }

            if isInSingleLineString {
                let scalar = scalars[index]
                if isEscaped {
                    isEscaped = false
                } else if scalar == "\\" {
                    isEscaped = true
                } else if scalar == "\"" {
                    isInSingleLineString = false
                }
                index += 1
                continue
            }

            if hasPrefix(scalars, at: index, marker: ["\"", "\"", "\""]) {
                mode = .tripleQuotedString
                isEscaped = false
                index += 3
                continue
            }

            let scalar = scalars[index]

            if scalar == "\"" {
                isInSingleLineString = true
                isEscaped = false
                index += 1
                continue
            }

            if hasPrefix(scalars, at: index, marker: ["/", "*"]) {
                mode = .blockComment
                index += 2
                continue
            }

            if hasPrefix(scalars, at: index, marker: ["/", "/"]) {
                break
            }

            result.append(scalar)
            index += 1
        }

        return String(result)
    }
}

// MARK: - Private Method

private extension DesignSystemSourceLexer {

    /// 判斷碼位陣列在指定索引處是否以給定樣式開頭
    ///
    /// - Parameters:
    ///   - scalars: 原始碼的 Unicode 碼位陣列
    ///   - index: 開始比對的索引
    ///   - marker: 分隔符號的 Unicode 碼位樣式
    /// - Returns: 是否符合指定前綴
    static func hasPrefix(
        _ scalars: [Unicode.Scalar],
        at index: Int,
        marker: [Unicode.Scalar]
    ) -> Bool {
        guard index + marker.count <= scalars.count else {
            return false
        }
        for offset in 0..<marker.count where scalars[index + offset] != marker[offset] {
            return false
        }
        return true
    }
}
