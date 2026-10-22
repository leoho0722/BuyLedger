//
//  LayerBoundaryTests+SourceStripping.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

// MARK: - Nested Types

extension LayerBoundaryTests {

    /// 跨行保留註解或多行字串的掃描模式
    enum StripMode: CaseIterable {

        /// 一般程式碼
        case normal

        /// 位於 `/* ... */` 區塊註解內
        case blockComment

        /// 位於 `"""..."""` 多行字串字面值內
        case tripleQuotedString
    }

    /// 掃描模式使用的括號堆疊
    private enum ScanFrame {

        /// 一般程式碼 (含插值 `\(...)` 內的運算式)
        case code

        /// 位於 `/* ... */` 區塊註解內；可巢狀
        case blockComment

        /// 位於 `"""..."""` 多行字串字面值內
        case tripleQuotedString

        /// 位於單行字串內
        ///
        /// - Parameter escaped: 前一個字元是否為跳脫字元
        case singleLineString(escaped: Bool)

        /// 位於字串插值內
        ///
        /// - Parameter parenDepth: 插值運算式內尚未閉合的括號數
        case interpolation(parenDepth: Int)
    }
}

// MARK: - Internal Method

extension LayerBoundaryTests {

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

            case .singleLineString(let escaped):
                let character = characters[index]
                if escaped {
                    stack[stack.count - 1] = .singleLineString(escaped: false)
                    index += 1
                } else if hasPrefix(characters, at: index, marker: ["\\", "("]) {
                    stack.append(.interpolation(parenDepth: 0))
                    index += 2
                } else if character == "\\" {
                    stack[stack.count - 1] = .singleLineString(escaped: true)
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
                    stack.append(.singleLineString(escaped: false))
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
                    stack.append(.singleLineString(escaped: false))
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

private extension LayerBoundaryTests {

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
