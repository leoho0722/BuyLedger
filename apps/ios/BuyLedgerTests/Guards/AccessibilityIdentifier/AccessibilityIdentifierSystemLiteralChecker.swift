//
//  AccessibilityIdentifierSystemLiteralChecker.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/13.
//

import Foundation

/// 檢查範圍外的原始檔是否以字串字面值重寫 `SystemAccessibilityID` 已宣告的系統 identifier
enum AccessibilityIdentifierSystemLiteralChecker {

    // MARK: - Properties

    /// 系統 identifier 型別的名稱
    private static let typeName = "SystemAccessibilityID"
}

// MARK: - Internal Method

extension AccessibilityIdentifierSystemLiteralChecker {

    /// 找出範圍外檔案中與系統 identifier 完全相同的字串字面值
    ///
    /// - Parameters:
    ///   - files: App 與 UI 測試 target 在命名空間目錄之外的原始檔
    ///   - systemIdentifierPath: 宣告系統 identifier 的檔案相對路徑，`nil` 時不檢查
    /// - Returns: 系統 identifier 字面值違規；檔案不存在或沒有宣告任何值時為一筆空掃描違規
    /// - Note: 受檢值取自該檔每個 `static let` 常數，空字串不算；該檔本身不檢查
    static func violations(
        in files: [AccessibilityIdentifierScanner.SourceFile],
        systemIdentifierPath: String?
    ) -> [AccessibilityIdentifierScanner.Violation] {
        guard let systemIdentifierPath else {
            return []
        }
        let names = constantNames(in: files.first { $0.relativePath == systemIdentifierPath })
        guard !names.isEmpty else {
            return [emptyViolation(path: systemIdentifierPath)]
        }
        return files
            .filter { $0.relativePath != systemIdentifierPath }
            .flatMap { literalViolations(in: $0, names: names) }
    }
}

// MARK: - Private Method

private extension AccessibilityIdentifierSystemLiteralChecker {

    /// 讀出系統 identifier 檔的受檢值，以值對應常數名稱
    ///
    /// - Parameter file: 系統 identifier 檔，不存在時為 `nil`
    /// - Returns: 值對應常數名稱；同值的常數取先宣告者，沒有受檢值時為空
    static func constantNames(
        in file: AccessibilityIdentifierScanner.SourceFile?
    ) -> [String: String] {
        guard let file else {
            return [:]
        }
        let model = AccessibilityIdentifierSourceModel(text: file.text)
        guard model.isAligned else {
            return [:]
        }
        let constants = fixedConstants(
            in: model,
            range: model.tokens.indices,
            endLimit: model.original.count
        )
        var names: [String: String] = [:]
        for constant in constants {
            guard !constant.value.isEmpty, names[constant.value] == nil else {
                continue
            }
            names[constant.value] = constant.name
        }
        return names
    }

    /// 依序取出範圍內每個 `static let <名稱> = "<字面值>"`，含各層大括號本體內的宣告
    ///
    /// - Parameters:
    ///   - model: 原始檔的對照
    ///   - range: 要讀取的記號索引範圍
    ///   - endLimit: 範圍內最後一個宣告的尾端空隙結束位置
    /// - Returns: 依出現順序排列的常數名稱與字面值內容
    static func fixedConstants(
        in model: AccessibilityIdentifierSourceModel,
        range: Range<Int>,
        endLimit: Int
    ) -> [(name: String, value: String)] {
        var constants: [(name: String, value: String)] = []
        for declaration in model.declarations(in: range, endLimit: endLimit) {
            if let constant = declaration.fixedLiteral() {
                constants.append(constant)
                continue
            }
            guard let open = declaration.texts.firstIndex(of: "{"),
                  let close = declaration.closingOffset(forOpeningAt: open),
                  close == declaration.count - 1
            else {
                continue
            }
            let bodyStart = declaration.range.lowerBound + open + 1
            let bodyEnd = declaration.range.lowerBound + close
            constants += fixedConstants(
                in: model,
                range: bodyStart..<bodyEnd,
                endLimit: model.tokens[bodyEnd].start
            )
        }
        return constants
    }

    /// 系統 identifier 檔不存在或沒有受檢值的空掃描違規
    ///
    /// - Parameter path: 系統 identifier 檔的相對路徑
    /// - Returns: 空掃描違規
    static func emptyViolation(path: String) -> AccessibilityIdentifierScanner.Violation {
        AccessibilityIdentifierScanner.Violation(
            rule: .emptyScan,
            path: path,
            line: 1,
            subject: "\(typeName).(掃描)",
            value: "",
            detail: "系統 identifier 檔 \(path) 不存在或沒有宣告任何值"
        )
    }

    /// 找出一個範圍外檔案中與受檢值完全相同的字串字面值
    ///
    /// - Parameters:
    ///   - file: 範圍外的原始檔
    ///   - names: 值對應常數名稱
    /// - Returns: 系統 identifier 字面值違規；遮罩後與原文長度不一致的檔案不檢查，由位置檢查回報
    static func literalViolations(
        in file: AccessibilityIdentifierScanner.SourceFile,
        names: [String: String]
    ) -> [AccessibilityIdentifierScanner.Violation] {
        let model = AccessibilityIdentifierSourceModel(text: file.text)
        guard model.isAligned else {
            return []
        }
        let gapStarts = [0] + model.tokens.map(\.end)
        let gapEnds = model.tokens.map(\.start) + [model.original.count]
        var violations: [AccessibilityIdentifierScanner.Violation] = []
        for (start, end) in zip(gapStarts, gapEnds) {
            guard case .literal(let value) = model.gap(from: start, to: end),
                  let name = names[value]
            else {
                continue
            }
            violations.append(
                AccessibilityIdentifierScanner.Violation(
                    rule: .systemIdentifierLiteral,
                    path: file.relativePath,
                    line: model.line(at: model.skipTrivia(from: start, to: end)),
                    subject: "\(typeName).\(name)",
                    value: value,
                    detail: "系統 identifier 應引用 \(typeName).\(name)，不寫字面值"
                )
            )
        }
        return violations
    }
}
