//
//  LayerBoundaryTests+Patterns.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation

// MARK: - Computed Properties

extension LayerBoundaryTests {

    /// 比對含屬性標記、限定匯入與子符號的狀態管理套件匯入宣告
    ///
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    static var composableArchitectureImportPattern: NSRegularExpression {
        get throws(any Error) {
            try NSRegularExpression(
                pattern: #"^(?:@[_A-Za-z*][\w().,_ ]*\s+)*"#
                    + #"import\s+(?:\w+\s+)?ComposableArchitecture\b"#
            )
        }
    }

    /// 依序提供型別、別名、函式與變數的宣告擷取規則
    ///
    /// - Throws: 任一正規表示式建立失敗時拋出錯誤
    static var declarationPatterns: [NSRegularExpression] {
        get throws(any Error) {
            [
                try typeDeclarationPattern,
                try typealiasDeclarationPattern,
                try topLevelFunctionPattern,
                try topLevelVariablePattern,
            ]
        }
    }

    /// 比對不應納入對外宣告清單的存取修飾詞
    ///
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    static var accessModifierExclusionPattern: NSRegularExpression {
        get throws(any Error) {
            try NSRegularExpression(pattern: #"\b(?:private|fileprivate)\b"#)
        }
    }
}

// MARK: - Internal Method

extension LayerBoundaryTests {

    /// 從已移除註解與字串的行取得可對外使用的頂層宣告名稱
    ///
    /// - Parameters:
    ///   - strippedLine: 已移除註解與字串內容的程式碼行
    ///   - patterns: 依序嘗試的宣告比對規則
    ///   - exclusionPattern: 用來排除私有宣告的比對規則
    /// - Returns: 命中的頂層宣告名稱
    static func topLevelDeclarationNames(
        in strippedLine: String,
        patterns: [NSRegularExpression],
        exclusionPattern: NSRegularExpression
    ) -> [String] {
        let range = NSRange(strippedLine.startIndex..<strippedLine.endIndex, in: strippedLine)
        var results: [String] = []

        for pattern in patterns {
            guard let match = pattern.firstMatch(in: strippedLine, range: range),
                  let matchRange = Range(match.range(at: 0), in: strippedLine),
                  let nameRange = Range(match.range(at: 1), in: strippedLine) else {
                continue
            }
            guard !isPrivateModifier(strippedLine[matchRange], using: exclusionPattern) else {
                continue
            }
            results.append(String(strippedLine[nameRange]))
        }

        return results
    }
}

// MARK: - Private Method

private extension LayerBoundaryTests {

    /// 比對可接受的頂層型別宣告
    ///
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    static var typeDeclarationPattern: NSRegularExpression {
        get throws(any Error) {
            try NSRegularExpression(
                pattern: modifierPrefix
                    + #"(?:struct|class|enum|actor|protocol)\s+([A-Za-z_][A-Za-z0-9_]*)"#
            )
        }
    }

    /// 比對頂層型別別名宣告
    ///
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    static var typealiasDeclarationPattern: NSRegularExpression {
        get throws(any Error) {
            try NSRegularExpression(
                pattern: modifierPrefix + #"typealias\s+([A-Za-z_][A-Za-z0-9_]*)"#
            )
        }
    }

    /// 比對檔案層級的函式宣告，包含 `static func`
    ///
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    static var topLevelFunctionPattern: NSRegularExpression {
        get throws(any Error) {
            try NSRegularExpression(
                pattern: modifierPrefix + #"(?:static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)"#
            )
        }
    }

    /// 比對檔案層級的常數與變數宣告，包含 `static let` 與 `static var`
    ///
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    static var topLevelVariablePattern: NSRegularExpression {
        get throws(any Error) {
            try NSRegularExpression(
                pattern: modifierPrefix + #"(?:static\s+)?(?:let|var)\s+([A-Za-z_][A-Za-z0-9_]*)"#
            )
        }
    }

    /// 判斷宣告前綴是否含有私有存取修飾詞
    ///
    /// - Parameters:
    ///   - matchedPrefix: 命中的修飾詞前綴與宣告關鍵字
    ///   - pattern: 用來排除私有宣告的比對規則
    /// - Returns: 是否含有 `private` 或 `fileprivate`
    static func isPrivateModifier(
        _ matchedPrefix: Substring,
        using pattern: NSRegularExpression
    ) -> Bool {
        let text = String(matchedPrefix)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return pattern.firstMatch(in: text, range: range) != nil
    }
}
