//
//  DependencyConventionScanTests+Matching.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

import Foundation

// MARK: - Internal Method

extension DependencyConventionScanTests {

    /// 執行正規表示式並保留命中範圍與括號所圈出的文字，供規則跨檔使用
    ///
    /// - Parameters:
    ///   - pattern: `NSRegularExpression` 使用的規則文字
    ///   - source: 要比對的原始碼
    /// - Returns: 命中位置與各括號圈出的文字片段
    /// - Note: 正規表示式都是掃描器內寫死的常數；規則無效代表程式碼錯誤，因此直接中止
    static func matches(_ pattern: String, in source: String) -> [ScanMatch] {
        let expression: NSRegularExpression
        do {
            expression = try NSRegularExpression(pattern: pattern)
        } catch {
            preconditionFailure("掃描器內建規則無效：\(error.localizedDescription)")
        }

        let fullRange = NSRange(source.startIndex..<source.endIndex, in: source)
        return expression.matches(in: source, range: fullRange).compactMap { result in
            guard let range = Range(result.range, in: source) else {
                return nil
            }
            let captures: [String?] = (1..<result.numberOfRanges).map { index in
                guard let captureRange = Range(result.range(at: index), in: source) else {
                    return nil
                }
                return String(source[captureRange])
            }
            return ScanMatch(range: range, captures: captures)
        }
    }

    /// 建立含檔案、行號及引用內容的違規，供規則跨檔使用
    ///
    /// - Parameters:
    ///   - file: 違規所屬的原始碼檔
    ///   - source: 已移除註解與字串的原始碼
    ///   - range: 命中在 `source` 中的位置
    ///   - reason: 規則判定違規的原因
    /// - Returns: 可呈現在掃描失敗診斷中的單筆違規
    static func violation(
        in file: ScanFile,
        source: String,
        range: Range<String.Index>,
        reason: String
    ) -> ScanViolation {
        let line = source[..<range.lowerBound].filter { $0.isNewline }.count + 1
        let reference = String(source[range])
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        let referenceLimit = 120 // 避免過長的命中內容淹沒診斷重點
        return ScanViolation(
            file: file.relativePath,
            line: line,
            reference: String(reference.prefix(referenceLimit)),
            reason: reason
        )
    }

    /// 依檔案與行號排序違規，供掃描入口跨檔使用
    ///
    /// - Parameter violations: 原始違規清單
    /// - Returns: 按檔名與行號遞增的清單
    static func sorted(_ violations: [ScanViolation]) -> [ScanViolation] {
        violations.sorted { lhs, rhs in
            (lhs.file, lhs.line) < (rhs.file, rhs.line)
        }
    }
}
