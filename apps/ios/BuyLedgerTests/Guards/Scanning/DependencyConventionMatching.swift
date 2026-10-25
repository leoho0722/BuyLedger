//
//  DependencyConventionMatching.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

import Foundation

/// 以正規表示式比對原始碼並保留命中範圍與擷取文字，供依賴規範與服務擁有權守門共用
enum DependencyConventionMatching {}

// MARK: - Nested Types

extension DependencyConventionMatching {

    /// 一次正規表示式命中的字元範圍與擷取群組 (正規表示式中用括號框起、要單獨取出的片段)
    struct ScanMatch: Sendable {

        /// 命中在原始碼字串中的範圍
        let range: Range<String.Index>

        /// 各括號擷取片段的文字；未參與匹配的群組為 `nil`
        let captures: [String?]
    }
}

// MARK: - Internal Method

extension DependencyConventionMatching {

    /// 執行正規表示式並保留命中範圍與括號所圈出的文字
    ///
    /// - Parameters:
    ///   - pattern: `NSRegularExpression` 使用的規則文字
    ///   - source: 要比對的原始碼
    /// - Returns: 命中位置與各括號圈出的文字片段
    /// - Note: 內建規則無效屬於程式碼錯誤，因此直接中止
    static func matches(_ pattern: String, in source: String) -> [ScanMatch] {
        let expression: NSRegularExpression
        do {
            expression = try NSRegularExpression(pattern: pattern)
        } catch {
            // 內建規則由程式碼寫定，無效代表掃描器本身有誤，無法繼續
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
}
