//
//  AccessibilityIdentifierRules.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/13.
//

import Foundation

/// 檢查定義清單的形狀、第一段、ASCII、值重複、前綴重疊與空掃描
enum AccessibilityIdentifierRules {}

// MARK: - Internal Method

extension AccessibilityIdentifierRules {

    /// 檢查定義清單的形狀、第一段、ASCII、值重複、前綴重疊與空掃描
    ///
    /// - Parameters:
    ///   - definitions: 命名空間掃描取得的定義清單
    ///   - separators: 三個組字串函式的分隔符號
    /// - Returns: 各規則的違規，未排序
    static func violations(
        of definitions: AccessibilityIdentifierScanner.Definitions,
        separators: AccessibilityIdentifierScanner.Separators
    ) -> [AccessibilityIdentifierScanner.Violation] {
        let fixed = definitions.fixed
        let prefixes = definitions.prefixes
        let queries = prefixes.compactMap { $0.queryPrefix(with: separators) }
        return [
            emptyScanViolations(definitions),
            (fixed + prefixes).flatMap { namingViolations(of: $0) },
            duplicateViolations(fixed) + duplicateViolations(prefixes),
            overlapViolations(fixed: fixed, prefixes: prefixes, queries: queries),
        ].flatMap { $0 }
    }
}

// MARK: - Private Method

private extension AccessibilityIdentifierRules {

    /// 空掃描：沒有檔案、沒有固定值或沒有組出前綴時各記一筆
    ///
    /// - Parameter definitions: 定義清單
    /// - Returns: 空掃描違規
    static func emptyScanViolations(
        _ definitions: AccessibilityIdentifierScanner.Definitions
    ) -> [AccessibilityIdentifierScanner.Violation] {
        var details: [String] = []
        if definitions.fileCount == 0 {
            details.append("命名空間目錄沒有任何原始檔")
        }
        if definitions.fixed.isEmpty {
            details.append("沒有掃到任何固定 identifier")
        }
        if definitions.prefixes.isEmpty {
            details.append("沒有掃到任何組出前綴")
        }
        return details.map {
            AccessibilityIdentifierScanner.Violation(
                rule: .emptyScan,
                path: "BuyLedgerAccessibilityIDs",
                line: 1,
                subject: "BLAccessibilityID.(掃描)",
                value: "",
                detail: $0
            )
        }
    }

    /// 檢查一個固定值或前綴的形狀、第一段與 ASCII
    ///
    /// - Parameter definition: 固定值或前綴
    /// - Returns: 形狀、第一段與只含 ASCII 的違規
    static func namingViolations(
        of definition: AccessibilityIdentifierScanner.Definition
    ) -> [AccessibilityIdentifierScanner.Violation] {
        var violations: [AccessibilityIdentifierScanner.Violation] = []
        if !isValidShape(definition.value) {
            violations.append(
                violation(
                    .shape,
                    definition,
                    detail: "形狀不符：需以 . 分隔成 2 至 4 段，每段以小寫字母開頭且只含字母或數字"
                )
            )
        }
        if let owner = definition.ownerType {
            let expected = lowerCamelCase(owner)
            let first = definition.value
                .split(separator: ".", omittingEmptySubsequences: false)
                .first
                .map { String($0) } ?? ""
            if first != expected {
                violations.append(
                    violation(
                        .firstSegment,
                        definition,
                        detail: "第一段 \(first) 應為所屬型別 \(owner) 的 \(expected)"
                    )
                )
            }
        } else {
            violations.append(violation(.firstSegment, definition, detail: "沒有所屬的巢狀型別"))
        }
        if definition.value.unicodeScalars.contains(where: { !$0.isASCII }) {
            violations.append(violation(.asciiOnly, definition, detail: "含非 ASCII 字元"))
        }
        return violations
    }

    /// 值是否以 `.` 分隔成 2 至 4 段，每段以小寫字母開頭且其餘為字母或數字
    ///
    /// - Parameter value: 固定值或前綴
    /// - Returns: 形狀是否合規，字母與數字以 Unicode 類別判斷
    static func isValidShape(_ value: String) -> Bool {
        let segments = value.split(separator: ".", omittingEmptySubsequences: false)
        guard (2...4).contains(segments.count) else {
            return false
        }
        return segments.allSatisfy { segment in
            guard let first = segment.first, first.isLetter, first.isLowercase else {
                return false
            }
            return segment.dropFirst().allSatisfy {
                $0.isLetter || $0.isNumber
            }
        }
    }

    /// 以固定值或前綴建立違規
    ///
    /// - Parameters:
    ///   - rule: 違反的規則
    ///   - definition: 違規的固定值或前綴
    ///   - detail: 規則說明
    /// - Returns: 違規
    static func violation(
        _ rule: AccessibilityIdentifierScanner.Rule,
        _ definition: AccessibilityIdentifierScanner.Definition,
        detail: String
    ) -> AccessibilityIdentifierScanner.Violation {
        AccessibilityIdentifierScanner.Violation(
            rule: rule,
            path: definition.path,
            line: definition.line,
            subject: definition.subject,
            value: definition.value,
            detail: detail
        )
    }

    /// 把型別名稱轉成 lowerCamelCase：開頭連續大寫字母後接小寫字母時，除最後一個外都轉小寫
    ///
    /// - Parameter name: 巢狀型別名稱
    /// - Returns: 作為第一段的名稱，如 `AISummary` 為 `aiSummary`、`Fx` 為 `fx`
    static func lowerCamelCase(_ name: String) -> String {
        let characters = Array(name)
        let uppercaseRun = characters.prefix { $0.isUppercase }.count
        guard uppercaseRun > 0 else {
            return name
        }
        let isFollowedByLowercase = uppercaseRun < characters.count
            && characters[uppercaseRun].isLowercase
        let loweredCount = isFollowedByLowercase ? max(1, uppercaseRun - 1) : uppercaseRun
        let lowered = characters.prefix(loweredCount).map { $0.lowercased() }.joined()
        return lowered + String(characters.dropFirst(loweredCount))
    }

    /// 值重複：與依路徑、行號排序後第一個同值的宣告，每個後出現者各記一筆
    ///
    /// - Parameter definitions: 同一種定義 (固定值或前綴) 的清單
    /// - Returns: 值重複違規，描述指向第一處
    static func duplicateViolations(
        _ definitions: [AccessibilityIdentifierScanner.Definition]
    ) -> [AccessibilityIdentifierScanner.Violation] {
        let ordered = definitions.sorted { lhs, rhs in
            lhs.path == rhs.path ? lhs.line < rhs.line : lhs.path < rhs.path
        }
        var firstByValue: [String: AccessibilityIdentifierScanner.Definition] = [:]
        var violations: [AccessibilityIdentifierScanner.Violation] = []
        for definition in ordered {
            if let first = firstByValue[definition.value] {
                violations.append(
                    violation(
                        .duplicateValue,
                        definition,
                        detail: "與 \(first.path):\(first.line) 同值"
                    )
                )
            } else {
                firstByValue[definition.value] = definition
            }
        }
        return violations
    }

    /// 前綴重疊：固定值落在某個查詢前綴之下，或某個查詢前綴落在另一個之下 (有序對，含相等)
    ///
    /// - Parameters:
    ///   - fixed: 固定值清單
    ///   - prefixes: 前綴清單
    ///   - queries: 各前綴的查詢前綴，與 `prefixes` 同序
    /// - Returns: 前綴重疊違規
    static func overlapViolations(
        fixed: [AccessibilityIdentifierScanner.Definition],
        prefixes: [AccessibilityIdentifierScanner.Definition],
        queries: [String]
    ) -> [AccessibilityIdentifierScanner.Violation] {
        var violations: [AccessibilityIdentifierScanner.Violation] = []
        for definition in fixed {
            for query in queries where definition.value.hasPrefix(query) {
                violations.append(
                    violation(.prefixOverlap, definition, detail: "落在查詢前綴 \(query) 之下")
                )
            }
        }
        for (index, definition) in prefixes.enumerated() {
            for (otherIndex, other) in queries.enumerated()
            where index != otherIndex && queries[index].hasPrefix(other) {
                violations.append(
                    violation(
                        .prefixOverlap,
                        definition,
                        detail: "查詢前綴 \(queries[index]) 落在查詢前綴 \(other) 之下"
                    )
                )
            }
        }
        return violations
    }
}
