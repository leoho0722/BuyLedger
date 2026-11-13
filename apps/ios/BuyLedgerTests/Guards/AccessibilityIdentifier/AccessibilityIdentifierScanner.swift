//
//  AccessibilityIdentifierScanner.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/13.
//

import Foundation

/// 掃描 `BLAccessibilityID` 命名空間的原始碼，取得受檢 identifier 並找出違反定義形式、命名格式與唯一性的宣告
enum AccessibilityIdentifierScanner {}

// MARK: - Nested Types

extension AccessibilityIdentifierScanner {

    /// 守門檢查的規則，宣告順序同時是同一位置多筆違規的排序依據
    enum Rule: CaseIterable, Sendable {

        /// 宣告或字面值不在接受的定義形式內
        case definitionForm

        /// 命名空間目錄之外擴充或宣告 `BLAccessibilityID`
        case declarationLocation

        /// 範圍外的原始檔以字串字面值重寫系統 identifier，沒有引用 `SystemAccessibilityID`
        case systemIdentifierLiteral

        /// 不是以 `.` 分隔的 2 至 4 段，或有段落不以小寫字母開頭、含字母與數字以外的字元
        case shape

        /// 第一段不等於所屬巢狀型別的 lowerCamelCase，或沒有所屬型別
        case firstSegment

        /// 含非 ASCII 字元
        case asciiOnly

        /// 兩個固定值相同，或兩個組出前綴相同
        case duplicateValue

        /// 固定值落在某個查詢前綴之下，或某個查詢前綴落在另一個之下
        case prefixOverlap

        /// 命名空間沒有檔案、固定值或組出前綴，範圍外目錄沒有檔案，或系統 identifier 檔沒有值
        case emptyScan
    }

    /// 組字串函式的種類，各自在變動段之前插入不同的分隔符號
    enum Composer: Sendable {

        /// `option`，組出列舉型集合的 identifier
        case option

        /// `row`，組出使用者資料列的 identifier
        case row

        /// `indexed`，組出純序位集合的 identifier
        case indexed

        /// 依函式名稱建立組字串函式種類
        ///
        /// - Parameter identifier: 函式名稱，只認 `option`、`row`、`indexed`
        init?(identifier: String) {
            switch identifier {
            case "option":
                self = .option

            case "row":
                self = .row

            case "indexed":
                self = .indexed

            default:
                return nil
            }
        }

        /// 組字串函式呼叫時第二個引數的標籤
        var argumentLabel: String {
            switch self {
            case .option, .row:
                "key"

            case .indexed:
                "index"
            }
        }
    }

    /// 一個待掃描的原始檔
    struct SourceFile: Sendable {

        /// 相對於掃描根目錄的路徑，用於違規描述
        let relativePath: String

        /// 檔案原文
        let text: String
    }

    /// 三個組字串函式在變動段之前插入的分隔符號
    struct Separators: Sendable {

        /// `option` 的分隔符號
        let option: String

        /// `row` 的分隔符號
        let row: String

        /// `indexed` 的分隔符號
        let indexed: String

        /// 取得指定組字串函式的分隔符號
        ///
        /// - Parameter composer: 組字串函式的種類
        /// - Returns: 該函式在變動段之前插入的分隔符號
        func separator(for composer: Composer) -> String {
            switch composer {
            case .option:
                option

            case .row:
                row

            case .indexed:
                indexed
            }
        }
    }

    /// 一個固定 identifier，或一個由包裝函式組出的 identifier 前綴
    struct Definition: Sendable {

        /// 定義種類
        let kind: Kind

        /// 所屬的巢狀型別名稱，沒有所屬型別時為 `nil`
        let ownerType: String?

        /// 常數名稱，前綴則是包裝函式名稱
        let name: String

        /// 字面值內容，前綴則是前綴字面值內容
        let value: String

        /// 宣告所在檔案的相對路徑
        let path: String

        /// 宣告所在行，從 1 起算
        let line: Int

        /// 定義的種類
        enum Kind: Sendable {

            /// 寫成完整字串字面值的固定 identifier
            case fixed

            /// 由包裝函式組出的前綴
            ///
            /// - Parameter composer: 包裝函式呼叫的組字串函式種類
            case prefix(Composer)
        }

        /// 違規描述的 `<型別>.<名稱>`，沒有所屬型別時型別以 `BLAccessibilityID` 代替
        var subject: String {
            "\(ownerType ?? "BLAccessibilityID").\(name)"
        }

        /// 取得組出前綴的查詢前綴，即前綴接上該組字串函式的分隔符號
        ///
        /// - Parameter separators: 三個組字串函式的分隔符號
        /// - Returns: 查詢前綴；固定值沒有查詢前綴，為 `nil`
        func queryPrefix(with separators: Separators) -> String? {
            guard case .prefix(let composer) = kind else {
                return nil
            }
            return value + separators.separator(for: composer)
        }
    }

    /// 命名空間掃描取得的定義清單
    struct Definitions: Sendable {

        /// 掃描的命名空間檔案數
        let fileCount: Int

        /// 固定 identifier，依輸入檔案順序再依宣告順序排列
        let fixed: [Definition]

        /// 組出前綴，依輸入檔案順序再依宣告順序排列
        let prefixes: [Definition]
    }

    /// 一筆違規
    struct Violation: CustomStringConvertible, Sendable {

        /// 違反的規則
        let rule: Rule

        /// 違規宣告所在檔案的相對路徑
        let path: String

        /// 違規宣告所在行，從 1 起算
        let line: Int

        /// 違規宣告的 `<型別>.<名稱>`
        let subject: String

        /// 違規宣告的值，沒有值時為空字串
        let value: String

        /// 規則說明，正體中文
        let detail: String

        /// 單行描述：`<相對路徑>:<行號> <型別>.<名稱> "<值>" <規則說明>`
        var description: String {
            "\(path):\(line) \(subject) \"\(value)\" \(detail)"
        }
    }

    /// 掃描結果：定義清單與已排序的違規
    struct ScanResult: Sendable {

        /// 命名空間掃描取得的定義清單
        let definitions: Definitions

        /// 違規，依相對路徑、行號、規則宣告順序排序
        let violations: [Violation]
    }
}

// MARK: - Internal Method

extension AccessibilityIdentifierScanner {

    /// 掃描命名空間與範圍外目錄，檢查全部規則
    ///
    /// - Parameters:
    ///   - namespaceFiles: 命名空間目錄 (`BuyLedgerAccessibilityIDs/`) 的原始檔
    ///   - outsideFiles: App 與 UI 測試 target 在命名空間目錄之外的原始檔
    ///   - outsideRoots: 範圍外目錄名稱 (相對路徑第一段)，每個都必須有原始檔；空陣列時不檢查
    ///   - systemIdentifierPath: `outsideFiles` 中宣告系統 identifier 的檔案相對路徑；`nil` 時不檢查
    ///   - separators: 三個組字串函式的分隔符號
    /// - Returns: 定義清單與已排序的違規
    static func scan(
        namespaceFiles: [SourceFile],
        outsideFiles: [SourceFile],
        outsideRoots: [String],
        systemIdentifierPath: String?,
        separators: Separators
    ) -> ScanResult {
        let namespace = AccessibilityIdentifierDeclarationParser.scan(namespaceFiles)
        let violations = [
            namespace.violations,
            AccessibilityIdentifierLocationChecker.violations(in: outsideFiles),
            AccessibilityIdentifierLocationChecker.missingRootViolations(
                roots: outsideRoots,
                in: outsideFiles
            ),
            AccessibilityIdentifierSystemLiteralChecker.violations(
                in: outsideFiles,
                systemIdentifierPath: systemIdentifierPath
            ),
            AccessibilityIdentifierRules.violations(
                of: namespace.definitions,
                separators: separators
            ),
        ].flatMap { $0 }
        return ScanResult(
            definitions: namespace.definitions,
            violations: sortedViolations(violations)
        )
    }

    /// 把違規整理成每筆一行的描述
    ///
    /// - Parameter violations: 已排序的違規
    /// - Returns: 每筆一行的描述；沒有違規時為「無」
    static func describe(_ violations: [Violation]) -> String {
        guard !violations.isEmpty else {
            return "無"
        }
        return violations.map(\.description).joined(separator: "\n")
    }
}

// MARK: - Private Method

private extension AccessibilityIdentifierScanner {

    /// 依相對路徑、行號、規則宣告順序、描述排序，讓輸出可重現
    ///
    /// - Parameter violations: 未排序的違規
    /// - Returns: 已排序的違規
    static func sortedViolations(_ violations: [Violation]) -> [Violation] {
        let ruleOrder = Rule.allCases
        return violations.sorted { lhs, rhs in
            if lhs.path != rhs.path {
                return lhs.path < rhs.path
            }
            if lhs.line != rhs.line {
                return lhs.line < rhs.line
            }
            if lhs.rule != rhs.rule {
                let lhsOrder = ruleOrder.firstIndex(of: lhs.rule) ?? 0
                let rhsOrder = ruleOrder.firstIndex(of: rhs.rule) ?? 0
                return lhsOrder < rhsOrder
            }
            return lhs.description < rhs.description
        }
    }
}
