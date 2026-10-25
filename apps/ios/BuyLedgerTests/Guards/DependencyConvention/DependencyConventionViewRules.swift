//
//  DependencyConventionViewRules.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation

/// 檢查遵循 `View` 的型別不宣告 `@Dependency`，production 程式碼不讀取裝置曆法
enum DependencyConventionViewRules {}

// MARK: - Nested Types

extension DependencyConventionViewRules {

    /// 原始碼中一個 `struct`、`class`、`enum` 或 `extension` 宣告的名稱、遵循情形與本體範圍
    struct TypeDeclaration: Sendable {

        /// 宣告的型別名稱，巢狀型別取最後一段
        let name: String

        /// 繼承子句 (不含 `where` 子句) 是否含整字 `View`
        let hasViewConformance: Bool

        /// 宣告本體從開括號到閉括號的範圍
        let bodyRange: Range<String.Index>
    }
}

// MARK: - Internal Method

extension DependencyConventionViewRules {

    /// 收集 production 檔中遵循 `View` 的型別名稱，供畫面依賴規則判斷哪些宣告需要檢查
    ///
    /// - Parameter files: 掃描範圍內的 Swift 檔，非 production 檔不計入
    /// - Returns: 遵循 `View` 的型別名稱，巢狀型別取最後一段
    static func collectViewTypeNames(in files: [DependencyScanFile]) -> Set<String> {
        var names: Set<String> = []
        for file in files where file.sourceTree == .production {
            let source = DependencyConventionLexing.blankedCommentsAndStrings(in: file.contents)
            let viewNames = typeDeclarations(in: source)
                .filter(\.hasViewConformance)
                .map(\.name)
            names.formUnion(viewNames)
        }
        return names
    }

    /// 找出遵循 `View` 的型別本體內的 `@Dependency(`，並找出整個檔案中讀取裝置曆法的引用
    ///
    /// - Parameters:
    ///   - file: 要檢查的 production Swift 原始碼
    ///   - viewTypeNames: 整棵 production 目錄中遵循 `View` 的型別名稱
    /// - Returns: 畫面依賴與裝置曆法引用的違規
    static func viewDependencyViolations(
        in file: DependencyScanFile,
        viewTypeNames: Set<String>
    ) -> [DependencyScanViolation] {
        let source = DependencyConventionLexing.blankedCommentsAndStrings(in: file.contents)
        let viewBodies = typeDeclarations(in: source)
            .filter { viewTypeNames.contains($0.name) }
            .map(\.bodyRange)
        var violations: [DependencyScanViolation] = []

        for match in DependencyConventionMatching.matches(#"@Dependency\s*\("#, in: source) {
            guard viewBodies.contains(where: { $0.contains(match.range.lowerBound) }) else {
                continue
            }
            violations.append(
                DependencyConventionRules.violation(
                    in: file,
                    source: source,
                    range: match.range,
                    reason: "遵循 `View` 的型別不得宣告 `@Dependency`，依賴改由 Feature 寫入 State"
                )
            )
        }

        let calendarPattern = #"\bCalendar\s*\.\s*(?:current|autoupdatingCurrent)\b"#
        for match in DependencyConventionMatching.matches(calendarPattern, in: source) {
            violations.append(
                DependencyConventionRules.violation(
                    in: file,
                    source: source,
                    range: match.range,
                    reason: "不得讀取裝置曆法，曆法改由依賴注入的 calendar 提供"
                )
            )
        }
        return violations
    }
}

// MARK: - Private Method

private extension DependencyConventionViewRules {

    /// 切出原始碼中 `struct`、`class`、`enum` 與 `extension` 宣告的名稱、遵循情形與本體範圍
    ///
    /// - Parameter source: 已移除註解與字串的原始碼
    /// - Returns: 找得到本體括號的宣告，依出現順序排列
    static func typeDeclarations(in source: String) -> [TypeDeclaration] {
        let namePattern = #"\b(?:struct|class|enum|extension)\s+(\w+(?:\.\w+)*)"#
        return DependencyConventionMatching.matches(namePattern, in: source).compactMap { match in
            guard let capture = match.captures.first,
                  let qualifiedName = capture,
                  let simpleName = qualifiedName.split(separator: ".").last,
                  let openingBrace = source[match.range.upperBound...].firstIndex(of: "{"),
                  let bodyRange = DependencyConventionSyntax.matchingDelimiter(
                      in: source,
                      openingAt: openingBrace
                  ) else {
                return nil
            }
            let header = String(source[match.range.upperBound..<openingBrace])
            return TypeDeclaration(
                name: String(simpleName),
                hasViewConformance: declaresViewConformance(in: header),
                bodyRange: bodyRange
            )
        }
    }

    /// 判斷宣告頭的繼承子句是否含整字 `View`；泛型參數子句與 `where` 子句不計入
    ///
    /// - Parameter header: 型別名稱之後、本體開括號之前的文字
    /// - Returns: 繼承子句含整字 `View` 時為 `true`；`ViewModifier` 與 `ViewBuilder` 不算
    static func declaresViewConformance(in header: String) -> Bool {
        var clause = header
        // 巢狀的泛型參數子句需由內而外反覆移除
        while true {
            let stripped = clause.replacingOccurrences(
                of: #"<[^<>]*>"#,
                with: "",
                options: .regularExpression
            )
            if stripped == clause {
                break
            }
            clause = stripped
        }
        if let whereRange = clause.range(of: #"\bwhere\b"#, options: .regularExpression) {
            clause = String(clause[..<whereRange.lowerBound])
        }
        let inheritance = clause.trimmingCharacters(in: .whitespacesAndNewlines)
        guard inheritance.hasPrefix(":") else {
            return false
        }
        return !DependencyConventionMatching.matches(#"\bView\b"#, in: inheritance).isEmpty
    }
}
