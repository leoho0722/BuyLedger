//
//  DependencyConventionScanTests+TestValueRules.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

import Foundation

// MARK: - Internal Method

extension DependencyConventionScanTests {

    /// 檢查 Service 測試值 closure 與其他依賴的 `testValue` 宣告，供 `violations(of:in:)` 跨檔使用
    ///
    /// - Parameter file: 要掃描的 Swift 原始碼
    /// - Returns: 未符合測試值規範的違規
    static func testValueViolations(in file: ScanFile) -> [ScanViolation] {
        let filename = URL(fileURLWithPath: file.relativePath).lastPathComponent
        let source = blankedCommentsAndStrings(in: file.contents)
        if isServiceFilename(filename) {
            return serviceTestValueViolations(in: file, source: source, filename: filename)
        }

        return matches(#"\b(?:var|let)\s+testValue\b"#, in: source).map {
            violation(
                in: file,
                source: source,
                range: $0.range,
                reason: "Client、Store 與 Database 的 Dependency 不得宣告 testValue"
            )
        }
    }
}

// MARK: - Private Method

private extension DependencyConventionScanTests {

    /// 找出 Service 測試值中未使用 `unimplemented` 的 closure
    ///
    /// - Parameters:
    ///   - file: 要掃描的 Service 的 `+Dependency.swift` 檔
    ///   - source: 已移除註解與字串的原始碼
    ///   - filename: Service 的 `+Dependency.swift` 檔名
    /// - Returns: 缺少測試值宣告、建構呼叫或 closure 不符規範，以及內容無法解析的違規
    static func serviceTestValueViolations(
        in file: ScanFile,
        source: String,
        filename: String
    ) -> [ScanViolation] {
        let serviceName = String(filename.dropLast("+Dependency.swift".count))
        let testValueProperties = matches(
            #"\b(?:var\s+testValue\b[^{}]*\{|let\s+testValue\b(?:\s*:\s*[^=\n]+)?\s*=)"#,
            in: source
        )
        guard !testValueProperties.isEmpty else {
            return [
                ScanViolation(
                    file: file.relativePath,
                    line: 1,
                    reference: "testValue",
                    reason: "\(serviceName) 必須宣告測試值"
                ),
            ]
        }

        let escapedServiceName = NSRegularExpression.escapedPattern(for: serviceName)
        let initializerPattern = #"\b(?:Self|\#(escapedServiceName))\s*\("#
        let initializerMatches = matches(initializerPattern, in: source)
        var violations: [ScanViolation] = []
        for property in testValueProperties {
            violations.append(
                contentsOf: testValuePropertyViolations(
                    property,
                    in: file,
                    source: source,
                    serviceName: serviceName,
                    initializerMatches: initializerMatches
                )
            )
        }
        return violations
    }

    /// 檢查一個測試值屬性的建構方式與每個 closure 引數
    ///
    /// - Parameters:
    ///   - property: `testValue` 宣告的命中範圍
    ///   - file: 違規所屬的 Swift 檔案
    ///   - source: 已移除註解與字串的原始碼
    ///   - serviceName: 目前 Service 的型別名稱
    ///   - initializerMatches: 檔案內符合 Service 建構呼叫的命中
    /// - Returns: 這個屬性中的所有違規
    static func testValuePropertyViolations(
        _ property: ScanMatch,
        in file: ScanFile,
        source: String,
        serviceName: String,
        initializerMatches: [ScanMatch]
    ) -> [ScanViolation] {
        let isComputedProperty = source[property.range].contains("{")
        let initializer = initializerMatches.first {
            $0.range.lowerBound >= property.range.upperBound
        }
        let propertyRange: Range<String.Index>
        if isComputedProperty {
            let openingBrace = source.index(before: property.range.upperBound)
            guard let matchedRange = matchingDelimiter(in: source, openingAt: openingBrace) else {
                return [
                    violation(
                        in: file,
                        source: source,
                        range: property.range,
                        reason: "\(serviceName).testValue 本體無法解析"
                    ),
                ]
            }
            propertyRange = matchedRange
        } else {
            guard let initializer else {
                return [
                    violation(
                        in: file,
                        source: source,
                        range: property.range,
                        reason: "\(serviceName).testValue 必須以服務建構呼叫建立"
                    ),
                ]
            }
            let betweenDeclarationAndCall = source[
                property.range.upperBound..<initializer.range.lowerBound
            ]
            guard betweenDeclarationAndCall.allSatisfy({ $0.isWhitespace }) else {
                return [
                    violation(
                        in: file,
                        source: source,
                        range: property.range,
                        reason: "\(serviceName).testValue 必須直接以服務建構呼叫建立"
                    ),
                ]
            }
            let openingParenthesis = source.index(before: initializer.range.upperBound)
            guard let matchedRange = matchingDelimiter(
                in: source,
                openingAt: openingParenthesis
            ) else {
                return [
                    violation(
                        in: file,
                        source: source,
                        range: initializer.range,
                        reason: "\(serviceName).testValue 引數無法解析"
                    ),
                ]
            }
            propertyRange = initializer.range.lowerBound..<matchedRange.upperBound
        }

        guard let initializer, propertyRange.contains(initializer.range.lowerBound) else {
            return [
                violation(
                    in: file,
                    source: source,
                    range: property.range,
                    reason: "\(serviceName).testValue 必須以服務建構呼叫建立"
                ),
            ]
        }

        let openingParenthesis = source.index(before: initializer.range.upperBound)
        guard let arguments = topLevelArguments(
            in: source,
            openingAt: openingParenthesis,
            within: propertyRange
        ) else {
            return [
                violation(
                    in: file,
                    source: source,
                    range: initializer.range,
                    reason: "\(serviceName).testValue 引數無法解析"
                ),
            ]
        }

        var violations: [ScanViolation] = []
        for argumentRange in arguments {
            let argument = String(source[argumentRange])
            let label = matches(#"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*"#, in: argument).first
            let closureName = label?.captures.first.flatMap { $0 } ?? "未命名 closure"
            let expressionStart = label?.range.upperBound ?? argument.startIndex
            let expression = argument[expressionStart...]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard matches(#"^unimplemented\s*\("#, in: expression).isEmpty else {
                continue
            }

            let trimmedArgumentRange = source[argumentRange]
                .firstIndex { !$0.isWhitespace }
                .map { $0..<argumentRange.upperBound } ?? argumentRange
            violations.append(
                violation(
                    in: file,
                    source: source,
                    range: trimmedArgumentRange,
                    reason: "\(serviceName).\(closureName) 必須以 unimplemented( 開頭"
                )
            )
        }
        return violations
    }
}
