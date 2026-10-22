//
//  SourceTextScannerTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation
import Testing

/// `SourceTextScanner` 與 `String.literalMatches` 的單元測試，位置一律為 UTF-16 offset
struct SourceTextScannerTests {

    /// 字面值本體含 `\"` 跳脫引號時，結束位置是真正的結尾引號
    ///
    /// fixture 為不含開頭引號的字面值本體，從 0 起掃描
    @Test
    func scanStringLiteralBody_含跳脫引號_回傳真正的結尾引號位置() {
        // Given
        let scanner = SourceTextScanner(#"say \"hi\" ok" tail"#)

        // When
        let end = scanner.scanStringLiteralBody(from: 0)

        // Then
        #expect(end == 13)
    }

    /// 插值內的巢狀括號與巢狀字串配對完成後，字面值才會結束
    ///
    /// - Parameter testCase: 字面值本體 (不含開頭引號) 與預期的結尾引號位置
    @Test(arguments: [
        PositionCase(source: #"a\(f(x)) b" tail"#, start: 0, expected: 10),
        PositionCase(source: #"a\(f(x) + g("y")) b" tail"#, start: 0, expected: 19),
    ])
    func scanStringLiteralBody_插值含巢狀括號_括號配對後才結束(testCase: PositionCase) {
        // Given
        let scanner = SourceTextScanner(testCase.source)

        // When
        let end = scanner.scanStringLiteralBody(from: testCase.start)

        // Then
        #expect(end == testCase.expected)
    }

    /// 只回傳頂層插值的範圍，巢狀括號不另外切成多段，被跳脫的反斜線後方括號不算插值
    ///
    /// - Parameter testCase: 掃描的字串與預期的頂層插值範圍
    @Test(arguments: [
        RangesCase(
            source: #"a\(f(x)) b \(y)"#,
            expected: [NSRange(location: 1, length: 7), NSRange(location: 11, length: 4)]
        ),
        RangesCase(source: #"\\(x) \(y)"#, expected: [NSRange(location: 6, length: 4)]),
        RangesCase(source: "plain text", expected: []),
    ])
    func topLevelInterpolationRanges_字串含插值_回傳頂層插值範圍(testCase: RangesCase) {
        // Given
        let scanner = SourceTextScanner(testCase.source)

        // When
        let ranges = scanner.topLevelInterpolationRanges()

        // Then
        #expect(ranges == testCase.expected)
    }

    /// 指定位置之後還有換行時，回傳下一個換行字元的位置
    ///
    /// - Parameter testCase: 原始碼、起點與預期的換行位置
    @Test(arguments: [
        PositionCase(source: "ab\ncd", start: 0, expected: 2),
        PositionCase(source: "ab\ncd", start: 2, expected: 2),
        PositionCase(source: "ab\ncd\nef", start: 3, expected: 5),
    ])
    func endOfLineIndex_後方有換行_回傳換行位置(testCase: PositionCase) {
        // Given
        let scanner = SourceTextScanner(testCase.source)

        // When
        let index = scanner.endOfLineIndex(from: testCase.start)

        // Then
        #expect(index == testCase.expected)
    }

    /// 指定位置之後沒有換行時，回傳 UTF-16 code unit 的總數
    ///
    /// - Parameter testCase: 原始碼、起點與預期的行尾位置
    @Test(arguments: [
        PositionCase(source: "abcd", start: 0, expected: 4),
        PositionCase(source: "ab\ncd", start: 3, expected: 5),
    ])
    func endOfLineIndex_後方沒有換行_回傳來源長度(testCase: PositionCase) {
        // Given
        let scanner = SourceTextScanner(testCase.source)

        // When
        let index = scanner.endOfLineIndex(from: testCase.start)

        // Then
        #expect(index == testCase.expected)
    }

    /// 區塊註解有結尾時，回傳結尾 `*/` 之後的位置
    ///
    /// - Parameter testCase: 原始碼、`/*` 之後的起點與預期的結尾後位置
    @Test(arguments: [
        PositionCase(source: "/* c */ x", start: 2, expected: 7),
        PositionCase(source: "/* c */", start: 2, expected: 7),
    ])
    func skipBlockComment_有結尾_回傳結尾之後的位置(testCase: PositionCase) {
        // Given
        let scanner = SourceTextScanner(testCase.source)

        // When
        let end = scanner.skipBlockComment(from: testCase.start)

        // Then
        #expect(end == testCase.expected)
    }

    /// 區塊註解沒有結尾時回傳 `nil`
    @Test
    func skipBlockComment_沒有結尾_回傳nil() {
        // Given
        let scanner = SourceTextScanner("/* c *")

        // When
        let end = scanner.skipBlockComment(from: 2)

        // Then
        #expect(end == nil)
    }

    /// 行註解內的引號不當成字面值，下一行真正的字面值仍被找到
    @Test
    func literalMatches_行註解內含引號_只找出真正的字面值() {
        // Given
        let source = #"""
            let a = "real1" // "x"
            let b = "real2"
            """#

        // When
        let literals = source.literalMatches

        // Then
        #expect(literals.count == 2)
        #expect(literals.map(\.raw) == ["real1", "real2"])
        #expect(literals.map(\.start) == [9, 32])
    }

    /// 區塊註解內的引號不當成字面值，同行註解之後真正的字面值仍被找到
    @Test
    func literalMatches_區塊註解內含引號_只找出真正的字面值() {
        // Given
        let source = #"""
            let a = "real1"
            /* "y" */ let b = "real2"
            """#

        // When
        let literals = source.literalMatches

        // Then
        #expect(literals.count == 2)
        #expect(literals.map(\.raw) == ["real1", "real2"])
        #expect(literals.map(\.start) == [9, 35])
    }
}

// MARK: - Nested Types

extension SourceTextScannerTests {

    /// 位置類方法的測試案例
    ///
    /// - Note: 用於測試方法的參數型別，須為 internal
    struct PositionCase: Sendable {

        /// 要掃描的原始碼片段
        let source: String

        /// 傳給掃描方法的起點 (UTF-16 offset)
        let start: Int

        /// 獨立寫成字面值的預期位置 (UTF-16 offset)
        let expected: Int
    }

    /// 頂層插值範圍的測試案例
    ///
    /// - Note: 用於測試方法的參數型別，須為 internal
    struct RangesCase: Sendable {

        /// 要掃描的字串
        let source: String

        /// 獨立寫成字面值的預期插值範圍 (UTF-16 offset)
        let expected: [NSRange]
    }
}
