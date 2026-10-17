//
//  DesignSystemSourceScanTests+ScaledMetricScanner.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/17.
//

import Foundation

// MARK: - Internal Method

extension DesignSystemSourceScanTests {

    /// 規則十二：掃描產品程式碼把 `@ScaledMetric` 屬性傳進元件自行縮放的參數
    ///
    /// - Returns: 按檔名與行號排序的違規清單
    /// - Throws: 原始檔讀取或目錄掃描失敗時拋出錯誤
    static func doubleScaledArgumentViolations() throws(any Error) -> [Violation] {
        let parameters = try scaledComponentParameters()
        var violations: [Violation] = []

        for file in try swiftFiles(under: productionRoot) {
            let source = try String(contentsOf: file, encoding: .utf8)
            let lineNumbers = doubleScaledArgumentLineNumbers(
                in: source,
                scaledParameters: parameters
            )
            for lineNumber in lineNumbers {
                violations.append(
                    Violation(file: relativePath(of: file, under: productionRoot), line: lineNumber)
                )
            }
        }

        return violations.sorted { left, right in
            (left.file, left.line) < (right.file, right.line)
        }
    }

    /// 列出設計系統元件以 `@ScaledMetric` 自行縮放、由呼叫端傳入的參數
    ///
    /// - Returns: 元件型別名稱對應的縮放參數名稱
    /// - Throws: 原始檔讀取或目錄掃描失敗時拋出錯誤
    /// - Note: 一個檔只放一個頂層型別，元件名稱取自檔名
    /// - Note: `private` 與 `fileprivate` 屬性不是建構參數，不列入
    static func scaledComponentParameters() throws(any Error) -> [String: Set<String>] {
        var parameters: [String: Set<String>] = [:]

        for file in try swiftFiles(under: designSystemRoot) {
            let source = try String(contentsOf: file, encoding: .utf8)
            let text = strippedText(of: source)
            let names = scaledMetricNames(in: text, isPrivateIncluded: false)
            guard !names.isEmpty else {
                continue
            }
            parameters[file.deletingPathExtension().lastPathComponent] = names
        }

        return parameters
    }

    /// 以規則十二分類記憶體內的原始碼，忽略註解與字串內容
    ///
    /// - Parameters:
    ///   - source: 待分類的完整原始碼片段
    ///   - scaledParameters: 元件型別名稱對應其自行縮放的參數名稱
    /// - Returns: 把同檔 `@ScaledMetric` 屬性傳給縮放參數的行號，從第一行的 1 起算
    /// - Note: 只辨識以單一識別字傳入的引數，運算式與成員存取不在掃描範圍
    static func doubleScaledArgumentLineNumbers(
        in source: String,
        scaledParameters: [String: Set<String>]
    ) -> [Int] {
        let text = strippedText(of: source)
        let scaledNames = scaledMetricNames(in: text, isPrivateIncluded: true)
        guard !scaledNames.isEmpty else {
            return []
        }

        let nsText = text as NSString
        var lineNumbers: Set<Int> = []
        for (component, parameterNames) in scaledParameters {
            for argumentRange in callArgumentRanges(of: component, in: nsText) {
                let arguments = labeledIdentifierArgumentPattern.matches(
                    in: text,
                    range: argumentRange
                )
                for argument in arguments {
                    let label = nsText.substring(with: argument.range(at: 1))
                    let value = nsText.substring(with: argument.range(at: 2))
                    guard parameterNames.contains(label), scaledNames.contains(value) else {
                        continue
                    }
                    let prefix = nsText.substring(to: argument.range.location)
                    lineNumbers.insert(prefix.components(separatedBy: "\n").count)
                }
            }
        }

        return lineNumbers.sorted()
    }
}

// MARK: - Private Method

private extension DesignSystemSourceScanTests {

    /// 規則十二列出元件縮放參數的掃描目錄
    static var designSystemRoot: URL {
        productionRoot.appending(path: "Shared/DesignSystem")
    }

    /// 逐行剝除註解與字串後以換行接回，行號與原始碼一致
    ///
    /// - Parameter source: 待剝除的完整原始碼
    /// - Returns: 移除註解與字串內容的原始碼
    static func strippedText(of source: String) -> String {
        var mode = StripMode.normal
        return source.components(separatedBy: "\n")
            .map { stripCommentsAndStrings(from: $0, mode: &mode) }
            .joined(separator: "\n")
    }

    /// 找出原始碼宣告的 `@ScaledMetric` 屬性名稱
    ///
    /// - Parameters:
    ///   - text: 已剝除註解與字串的原始碼
    ///   - isPrivateIncluded: 是否列入 `private` 與 `fileprivate` 屬性
    /// - Returns: 符合條件的屬性名稱
    static func scaledMetricNames(in text: String, isPrivateIncluded: Bool) -> Set<String> {
        let nsText = text as NSString
        let declarations = scaledMetricDeclarationPattern.matches(
            in: text,
            range: NSRange(location: 0, length: nsText.length)
        )
        return Set(
            declarations
                .filter { isPrivateIncluded || $0.range(at: 1).location == NSNotFound }
                .map { nsText.substring(with: $0.range(at: 2)) }
        )
    }

    /// 找出元件呼叫的引數範圍，括號依巢狀層級配對
    ///
    /// - Parameters:
    ///   - component: 元件型別名稱
    ///   - text: 已剝除註解與字串的原始碼
    /// - Returns: 每次呼叫左右括號之間的範圍；括號未閉合的呼叫不列入
    static func callArgumentRanges(of component: String, in text: NSString) -> [NSRange] {
        let openParenthesis = UInt16(UInt8(ascii: "("))
        let closeParenthesis = UInt16(UInt8(ascii: ")"))
        var ranges: [NSRange] = []
        var call = text.range(of: component + "(")

        while call.location != NSNotFound {
            let argumentStart = NSMaxRange(call)
            var depth = 1
            var index = argumentStart
            while index < text.length && depth > 0 {
                let character = text.character(at: index)
                if character == openParenthesis {
                    depth += 1
                } else if character == closeParenthesis {
                    depth -= 1
                }
                index += 1
            }
            if depth == 0 {
                ranges.append(NSRange(location: argumentStart, length: index - 1 - argumentStart))
            }
            call = text.range(
                of: component + "(",
                range: NSRange(location: argumentStart, length: text.length - argumentStart)
            )
        }

        return ranges
    }
}
