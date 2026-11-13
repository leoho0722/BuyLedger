//
//  AccessibilityIdentifierDeclaration.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/13.
//

import Foundation

/// 一個宣告的記號視圖，以相對於宣告第一個記號的位置取得記號與空隙
struct AccessibilityIdentifierDeclaration: Sendable {

    // MARK: - Properties

    /// 所屬原始檔的對照
    let model: AccessibilityIdentifierSourceModel

    /// 宣告在記號陣列中的索引範圍
    let range: Range<Int>

    /// 宣告內各記號的文字
    let texts: [String]

    /// 尾端空隙的結束位置，即下一個宣告的第一個記號或外層結尾
    private let tailEnd: Int

    // MARK: - Init

    /// 以切分出的記號範圍建立視圖
    ///
    /// - Parameters:
    ///   - model: 所屬原始檔的對照
    ///   - range: 宣告在記號陣列中的索引範圍
    ///   - tailEnd: 尾端空隙的結束位置
    init(model: AccessibilityIdentifierSourceModel, range: Range<Int>, tailEnd: Int) {
        self.model = model
        self.range = range
        self.tailEnd = tailEnd
        texts = model.tokens[range].map(\.text)
    }
}

// MARK: - Computed Properties

extension AccessibilityIdentifierDeclaration {

    /// 宣告的記號數
    var count: Int {
        texts.count
    }

    /// 宣告第一個記號所在的行號
    var firstLine: Int {
        model.line(at: model.tokens[range.lowerBound].start)
    }

    /// 最後一個記號之後的空隙，字面值與註解都在這裡
    var tail: AccessibilityIdentifierSourceModel.Gap {
        model.gap(from: model.tokens[range.upperBound - 1].end, to: tailEnd)
    }
}

// MARK: - Internal Method

extension AccessibilityIdentifierDeclaration {

    /// 找出位於宣告結尾的大括號區塊的閉括號，區塊之後不可再有內容
    ///
    /// - Parameter offset: 開大括號的位置
    /// - Returns: 閉大括號的位置；不是大括號、閉括號不在最後一個記號，或宣告之間夾有字面值時為 `nil`
    func closingOffsetOfTrailingBlock(openingAt offset: Int) -> Int? {
        guard text(at: offset) == "{",
              let close = closingOffset(forOpeningAt: offset),
              close == count - 1,
              hasTriviaGaps(in: 1...offset),
              tail == .trivia
        else {
            return nil
        }
        return close
    }

    /// 找出開括號對應的閉括號
    ///
    /// - Parameter offset: 開括號 `(`、`{` 或 `[` 的位置
    /// - Returns: 對應閉括號的位置，找不到時為 `nil`
    func closingOffset(forOpeningAt offset: Int) -> Int? {
        let closers = ["(": ")", "{": "}", "[": "]"]
        guard let open = text(at: offset), let close = closers[open] else {
            return nil
        }
        var depth = 0
        for index in offset..<count {
            if texts[index] == open {
                depth += 1
            } else if texts[index] == close {
                depth -= 1
                if depth == 0 {
                    return index
                }
            }
        }
        return nil
    }

    /// 指定的各記號之前的空隙是否都只有空白與註解
    ///
    /// - Parameter offsets: 相對於宣告第一個記號的位置
    /// - Returns: 是否都沒有字面值
    func hasTriviaGaps(in offsets: some Sequence<Int>) -> Bool {
        offsets.allSatisfy { gap(before: $0) == .trivia }
    }

    /// 分類指定記號之前的空隙
    ///
    /// - Parameter offset: 相對於宣告第一個記號的位置，至少為 1
    /// - Returns: 該記號與前一個記號之間的內容分類
    func gap(before offset: Int) -> AccessibilityIdentifierSourceModel.Gap {
        let current = model.tokens[range.lowerBound + offset]
        let previous = model.tokens[range.lowerBound + offset - 1]
        return model.gap(from: previous.end, to: current.start)
    }

    /// 指定位置是否為識別字
    ///
    /// - Parameter offset: 相對於宣告第一個記號的位置
    /// - Returns: 是否為識別字記號
    func isIdentifier(at offset: Int) -> Bool {
        texts.indices.contains(offset)
            && model.tokens[range.lowerBound + offset].kind == .identifier
    }

    /// 取得指定位置的記號文字
    ///
    /// - Parameter offset: 相對於宣告第一個記號的位置
    /// - Returns: 記號文字，超出範圍時為 `nil`
    func text(at offset: Int) -> String? {
        texts.indices.contains(offset) ? texts[offset] : nil
    }

    /// 辨識 `static let <名稱> [: String] = "<字面值>"`，等號後可換行，字面值後可接註解
    ///
    /// - Returns: 常數名稱與字面值內容；不是這個形式時為 `nil`
    func fixedLiteral() -> (name: String, value: String)? {
        guard count >= 4,
              texts[0] == "static",
              texts[1] == "let",
              isIdentifier(at: 2)
        else {
            return nil
        }
        let suffix = Array(texts[3...])
        guard suffix == ["="] || suffix == [":", "String", "="],
              hasTriviaGaps(in: 1..<count),
              case .literal(let value) = tail
        else {
            return nil
        }
        return (texts[2], value)
    }
}
