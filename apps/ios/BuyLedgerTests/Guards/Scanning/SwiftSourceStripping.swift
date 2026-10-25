//
//  SwiftSourceStripping.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

/// 剝除守門掃描中的註解與字串
enum SwiftSourceStripping {}

// MARK: - Nested Types

extension SwiftSourceStripping {

    /// 跨行保留註解或多行字串的掃描模式
    enum StripMode: CaseIterable {

        /// 一般程式碼
        case normal

        /// 位於 `/* ... */` 區塊註解內
        case blockComment

        /// 位於 `"""..."""` 多行字串字面值內
        case tripleQuotedString
    }

    /// 掃描時的巢狀上下文堆疊，每層記錄目前位於程式碼、註解、字串或插值的哪一種
    private enum ScanFrame {

        /// 一般程式碼，不在註解、字串或插值內
        case code

        /// 位於 `/* ... */` 區塊註解內；可巢狀
        case blockComment

        /// 位於 `"""..."""` 多行字串字面值內
        case tripleQuotedString

        /// 位於單行字串內
        ///
        /// - Parameter isEscaped: 前一個字元是否為跳脫字元
        case singleLineString(isEscaped: Bool)

        /// 位於字串插值內
        ///
        /// - Parameter parenDepth: 插值運算式內尚未閉合的括號數
        case interpolation(parenDepth: Int)
    }
}

// MARK: - Internal Method

extension SwiftSourceStripping {

    /// 移除行註解、區塊註解與字串內容
    ///
    /// - Parameters:
    ///   - line: 要掃描的原始碼單行
    ///   - mode: 跨行延續的註解或多行字串模式
    /// - Returns: 移除註解與字串後的內容
    static func stripCommentsAndStrings(from line: String, mode: inout StripMode) -> String {
        let characters = Array(line)
        var result: [Character] = []
        var index = 0
        var stack: [ScanFrame]

        switch mode {
        case .normal:
            stack = [.code]

        case .blockComment:
            stack = [.blockComment]

        case .tripleQuotedString:
            stack = [.tripleQuotedString]
        }

        while index < characters.count {
            switch stack[stack.count - 1] {
            case .blockComment:
                if hasPrefix(characters, at: index, marker: ["/", "*"]) {
                    stack.append(.blockComment)
                    index += 2
                } else if hasPrefix(characters, at: index, marker: ["*", "/"]) {
                    stack.removeLast()
                    if stack.isEmpty {
                        stack = [.code]
                    }
                    index += 2
                } else {
                    index += 1
                }

            case .tripleQuotedString:
                if hasPrefix(characters, at: index, marker: ["\"", "\"", "\""]) {
                    stack.removeLast()
                    if stack.isEmpty {
                        stack = [.code]
                    }
                    index += 3
                } else if hasPrefix(characters, at: index, marker: ["\\", "("]) {
                    stack.append(.interpolation(parenDepth: 0))
                    index += 2
                } else {
                    index += 1
                }

            case .singleLineString(let isEscaped):
                let character = characters[index]
                if isEscaped {
                    stack[stack.count - 1] = .singleLineString(isEscaped: false)
                    index += 1
                } else if hasPrefix(characters, at: index, marker: ["\\", "("]) {
                    stack.append(.interpolation(parenDepth: 0))
                    index += 2
                } else if character == "\\" {
                    stack[stack.count - 1] = .singleLineString(isEscaped: true)
                    index += 1
                } else if character == "\"" {
                    stack.removeLast()
                    index += 1
                } else {
                    index += 1
                }

            case .interpolation(let parenDepth):
                let character = characters[index]
                if character == "(" {
                    stack[stack.count - 1] = .interpolation(parenDepth: parenDepth + 1)
                    result.append(character)
                    index += 1
                } else if character == ")" {
                    if parenDepth == 0 {
                        stack.removeLast()
                    } else {
                        stack[stack.count - 1] = .interpolation(parenDepth: parenDepth - 1)
                        result.append(character)
                    }
                    index += 1
                } else if hasPrefix(characters, at: index, marker: ["\"", "\"", "\""]) {
                    stack.append(.tripleQuotedString)
                    index += 3
                } else if character == "\"" {
                    stack.append(.singleLineString(isEscaped: false))
                    index += 1
                } else if hasPrefix(characters, at: index, marker: ["/", "*"]) {
                    stack.append(.blockComment)
                    index += 2
                } else {
                    result.append(character)
                    index += 1
                }

            case .code:
                if hasPrefix(characters, at: index, marker: ["\"", "\"", "\""]) {
                    stack.append(.tripleQuotedString)
                    index += 3
                } else if characters[index] == "\"" {
                    stack.append(.singleLineString(isEscaped: false))
                    index += 1
                } else if hasPrefix(characters, at: index, marker: ["/", "*"]) {
                    stack.append(.blockComment)
                    index += 2
                } else if hasPrefix(characters, at: index, marker: ["/", "/"]) {
                    index = characters.count
                } else {
                    result.append(characters[index])
                    index += 1
                }
            }
        }

        switch stack.last {
        case .blockComment:
            mode = .blockComment

        case .tripleQuotedString:
            mode = .tripleQuotedString

        case .code, .singleLineString, .interpolation, nil:
            mode = .normal
        }

        return String(result)
    }
}

// MARK: - Private Method

private extension SwiftSourceStripping {

    /// 判斷字元陣列在指定索引處是否以給定樣式開頭
    ///
    /// - Parameters:
    ///   - characters: 要比對的字元陣列
    ///   - index: 開始比對的位置
    ///   - marker: 要尋找的前綴字元
    /// - Returns: 是否符合指定前綴
    static func hasPrefix(_ characters: [Character], at index: Int, marker: [Character]) -> Bool {
        guard index + marker.count <= characters.count else {
            return false
        }
        for offset in 0..<marker.count where characters[index + offset] != marker[offset] {
            return false
        }
        return true
    }
}
