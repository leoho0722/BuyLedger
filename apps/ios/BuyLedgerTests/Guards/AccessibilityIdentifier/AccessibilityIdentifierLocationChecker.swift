//
//  AccessibilityIdentifierLocationChecker.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/13.
//

import Foundation

/// 檢查命名空間目錄之外的原始檔是否擴充、宣告或轉名 `BLAccessibilityID`，以及範圍外目錄是否都有原始檔
enum AccessibilityIdentifierLocationChecker {

    // MARK: - Properties

    /// 宣告新型別的關鍵字
    private static let typeKeywords: Set<String> = [
        "enum", "struct", "class", "actor", "typealias", "protocol",
    ]

    /// 命名空間的名稱
    private static let namespaceName = "BLAccessibilityID"
}

// MARK: - Internal Method

extension AccessibilityIdentifierLocationChecker {

    /// 找出範圍外檔案中擴充、宣告或轉名 `BLAccessibilityID` 的位置
    ///
    /// - Parameter files: App 與 UI 測試 target 在命名空間目錄之外的原始檔
    /// - Returns: 宣告位置違規
    static func violations(
        in files: [AccessibilityIdentifierScanner.SourceFile]
    ) -> [AccessibilityIdentifierScanner.Violation] {
        files.flatMap { declarationViolations(in: $0) }
    }

    /// 找出沒有任何原始檔的範圍外目錄
    ///
    /// - Parameters:
    ///   - roots: 範圍外目錄名稱，即相對路徑的第一段
    ///   - files: App 與 UI 測試 target 在命名空間目錄之外的原始檔
    /// - Returns: 每個沒有原始檔的目錄一筆空掃描違規；`roots` 為空陣列時沒有違規
    static func missingRootViolations(
        roots: [String],
        in files: [AccessibilityIdentifierScanner.SourceFile]
    ) -> [AccessibilityIdentifierScanner.Violation] {
        let missingRoots = roots.filter { root in
            files.allSatisfy {
                !$0.relativePath.hasPrefix("\(root)/")
            }
        }
        return missingRoots.map {
            AccessibilityIdentifierScanner.Violation(
                rule: .emptyScan,
                path: $0,
                line: 1,
                subject: "\(namespaceName).(掃描)",
                value: "",
                detail: "範圍外目錄 \($0)/ 沒有任何原始檔"
            )
        }
    }
}

// MARK: - Private Method

private extension AccessibilityIdentifierLocationChecker {

    /// 找出一個範圍外檔案中擴充、宣告或轉名 `BLAccessibilityID` 的位置
    ///
    /// - Parameter file: 命名空間目錄之外的原始檔
    /// - Returns: 宣告位置違規
    static func declarationViolations(
        in file: AccessibilityIdentifierScanner.SourceFile
    ) -> [AccessibilityIdentifierScanner.Violation] {
        let model = AccessibilityIdentifierSourceModel(text: file.text)
        guard model.isAligned else {
            return [
                AccessibilityIdentifierScanner.Violation(
                    rule: .declarationLocation,
                    path: file.relativePath,
                    line: 1,
                    subject: "\(namespaceName).(檔案)",
                    value: "",
                    detail: "遮罩後的內容與原文長度不一致，無法掃描"
                ),
            ]
        }
        var violations: [AccessibilityIdentifierScanner.Violation] = []
        for index in model.tokens.indices {
            if let declarationSubject = subject(ofDeclarationAt: index, in: model) {
                violations.append(
                    AccessibilityIdentifierScanner.Violation(
                        rule: .declarationLocation,
                        path: file.relativePath,
                        line: model.line(at: model.tokens[index].start),
                        subject: declarationSubject,
                        value: "",
                        detail: "在命名空間目錄之外宣告 BLAccessibilityID，新增的 identifier 不會被掃描"
                    )
                )
            }
        }
        return violations
    }

    /// 取得一個記號開頭的宣告若擴充、宣告或轉名 `BLAccessibilityID` 時的違規主旨
    ///
    /// - Parameters:
    ///   - index: 宣告關鍵字的記號索引
    ///   - model: 原始檔的對照
    /// - Returns: 違規主旨；記號不是這類宣告的關鍵字，或宣告沒有涉及 `BLAccessibilityID` 時為 `nil`
    static func subject(
        ofDeclarationAt index: Int,
        in model: AccessibilityIdentifierSourceModel
    ) -> String? {
        let keyword = model.tokens[index].text
        let isMemberAccess = index > 0 && model.tokens[index - 1].text == "."
        guard !isMemberAccess else {
            return nil
        }
        if keyword == "extension" {
            let headerEnd = extensionHeaderEnd(in: model, after: index)
            return subject(of: keyword, in: model, searching: (index + 1)..<headerEnd)
        }
        guard typeKeywords.contains(keyword) else {
            return nil
        }
        if qualifiedName(in: model, startingAt: index + 1).first == namespaceName {
            return "\(namespaceName).\(keyword)"
        }
        guard keyword == "typealias" else {
            return nil
        }
        return subject(of: keyword, in: model, searching: aliasTargetRange(in: model, after: index))
    }

    /// 找出 `extension` 的宣告標頭結尾，即第一個開大括號
    ///
    /// - Parameters:
    ///   - model: 原始檔的對照
    ///   - index: `extension` 的記號索引
    /// - Returns: 第一個 `{` 或 `}` 的記號索引；都沒有時為記號總數
    static func extensionHeaderEnd(
        in model: AccessibilityIdentifierSourceModel,
        after index: Int
    ) -> Int {
        let end = ((index + 1)..<model.tokens.count).first {
            ["{", "}"].contains(model.tokens[$0].text)
        }
        return end ?? model.tokens.count
    }

    /// 取得第一個 `BLAccessibilityID` 記號起的限定名稱，組成違規主旨
    ///
    /// - Parameters:
    ///   - keyword: 宣告關鍵字
    ///   - model: 原始檔的對照
    ///   - range: 要搜尋的記號索引範圍
    /// - Returns: `<限定名稱>.<關鍵字>`；範圍內沒有 `BLAccessibilityID` 時為 `nil`
    static func subject(
        of keyword: String,
        in model: AccessibilityIdentifierSourceModel,
        searching range: Range<Int>
    ) -> String? {
        guard let position = range.first(where: { model.tokens[$0].text == namespaceName }) else {
            return nil
        }
        let names = qualifiedName(in: model, startingAt: position)
        return (names + [keyword]).joined(separator: ".")
    }

    /// 讀取以 `.` 連接的識別字名稱，以反引號包住的名稱視同識別字
    ///
    /// - Parameters:
    ///   - model: 原始檔的對照
    ///   - start: 第一個記號的索引
    /// - Returns: 名稱各段；第一個記號不是識別字時為空
    static func qualifiedName(
        in model: AccessibilityIdentifierSourceModel,
        startingAt start: Int
    ) -> [String] {
        var names: [String] = []
        var cursor = start
        while let component = identifierComponent(in: model, at: cursor) {
            names.append(component.name)
            let separator = component.next
            guard separator + 1 < model.tokens.count, model.tokens[separator].text == "." else {
                break
            }
            cursor = separator + 1
        }
        return names
    }

    /// 讀取一個識別字，或一個以反引號包住的識別字
    ///
    /// - Parameters:
    ///   - model: 原始檔的對照
    ///   - cursor: 第一個記號的索引
    /// - Returns: 名稱與其後第一個記號的索引；第一個記號不是識別字時為 `nil`
    static func identifierComponent(
        in model: AccessibilityIdentifierSourceModel,
        at cursor: Int
    ) -> (name: String, next: Int)? {
        let tokens = model.tokens
        guard cursor < tokens.count else {
            return nil
        }
        if tokens[cursor].kind == .identifier {
            return (tokens[cursor].text, cursor + 1)
        }
        guard tokens[cursor].text == "`",
              cursor + 2 < tokens.count,
              tokens[cursor + 1].kind == .identifier,
              tokens[cursor + 2].text == "`" else {
            return nil
        }
        return (tokens[cursor + 1].text, cursor + 3)
    }

    /// 找出 `typealias <名稱> = <右側>` 的右側記號範圍：從等號之後到宣告結束
    ///
    /// - Parameters:
    ///   - model: 原始檔的對照
    ///   - index: `typealias` 的記號索引
    /// - Returns: 右側的記號索引範圍；在下一個宣告開始前找不到等號時為空範圍
    /// - Note: 在括號與角括號之外換行、遇到下一個開啟宣告的關鍵字、`{` 或 `}` 時結束；換行處前後以 `.` 接續同一個名稱時不結束
    static func aliasTargetRange(
        in model: AccessibilityIdentifierSourceModel,
        after index: Int
    ) -> Range<Int> {
        let tokens = model.tokens
        var cursor = index + 1
        while cursor < tokens.count, tokens[cursor].text != "=" {
            if isDeclarationBoundary(tokens[cursor].text) {
                return cursor..<cursor
            }
            cursor += 1
        }
        let start = cursor + 1
        var end = start
        var depth = 0
        while end < tokens.count, !isDeclarationBoundary(tokens[end].text) {
            let gap = model.original[tokens[end - 1].end..<tokens[end].start]
            let isContinuation = tokens[end].text == "." || tokens[end - 1].text == "."
            if end > start, depth == 0, !isContinuation, gap.contains(where: \.isNewline) {
                break
            }
            switch tokens[end].text {
            case "(", "[", "<":
                depth += 1

            case ")", "]", ">":
                depth = max(0, depth - 1)

            default:
                break
            }
            end += 1
        }
        return start..<max(start, end)
    }

    /// 記號是否開啟另一個宣告或結束目前的區塊
    ///
    /// - Parameter text: 記號文字
    /// - Returns: 是宣告關鍵字、`{` 或 `}` 時為 `true`
    static func isDeclarationBoundary(_ text: String) -> Bool {
        let isKeyword = AccessibilityIdentifierSourceModel.startKeywords.contains(text)
        return isKeyword || text == "{" || text == "}"
    }
}
