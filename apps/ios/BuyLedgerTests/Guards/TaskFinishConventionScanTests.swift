//
//  TaskFinishConventionScanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/9.
//

import Foundation
import Testing

/// 掃描 Feature 畫面的 `.task`，要求等待 `.finish()` 時寫明豁免理由
struct TaskFinishConventionScanTests {

    /// 驗證 `.task` 內沒有豁免標記的 `.finish()` 會被判定為違規
    ///
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    @Test
    func taskFinish_缺少豁免標記_判定違規() throws {
        // Given
        let source = """
            Text("內容").task {
                await store.send(.view(.task)).finish()
            }
            """

        // When
        let violations = try Self.findViolations(in: source, relativePath: "Sample.swift")

        // Then
        #expect(violations.map(\.locationDescription) == ["Sample.swift:2"])
    }

    /// 驗證豁免標記只有空白理由時仍會判定為違規
    ///
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    @Test
    func taskFinish_豁免理由空白_判定違規() throws {
        // Given
        let source = """
            Text("內容").task {
                // task-finish-exempt:
                await store.send(.view(.task)).finish()
            }
            """

        // When
        let violations = try Self.findViolations(in: source, relativePath: "Sample.swift")

        // Then
        #expect(violations.map(\.locationDescription) == ["Sample.swift:3"])
    }

    /// 驗證 `.finish()` 同一行有非空白理由時會判定為合法
    ///
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    @Test
    func taskFinish_同一行有理由_判定合法() throws {
        // Given
        let source = """
            Text("內容").task {
                await store.send(.view(.task)).finish() // task-finish-exempt: 畫面專屬串流
            }
            """

        // When
        let violations = try Self.findViolations(in: source, relativePath: "Sample.swift")

        // Then
        #expect(violations.count == 0)
    }

    /// 驗證 `.finish()` 上一行有非空白理由時會判定為合法
    ///
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    @Test
    func taskFinish_上一行有理由_判定合法() throws {
        // Given
        let source = """
            Text("內容").task {
                // task-finish-exempt: 畫面專屬串流
                await store.send(.view(.task)).finish()
            }
            """

        // When
        let violations = try Self.findViolations(in: source, relativePath: "Sample.swift")

        // Then
        #expect(violations.count == 0)
    }

    /// 驗證 `.task` 只送出 action 時不違規，closure 外的 `.finish()` 不列入掃描
    ///
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    @Test
    func taskClosure_只送出事件_判定合法() throws {
        // Given
        let source = """
            store.send(.view(.task)).finish()
            Text("內容").task {
                store.send(.view(.task))
            }
            """

        // When
        let violations = try Self.findViolations(in: source, relativePath: "Sample.swift")

        // Then
        #expect(violations.count == 0)
    }

    /// 驗證 enum 比較式中的 `.task` 不論是否寫出型別名，都不會被當成 SwiftUI modifier
    ///
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    @Test
    func taskFinish_比較式中的列舉值_不判定違規() throws {
        // Given
        let source = """
            enum Work: Equatable {
                case task
            }

            func closeIfNeeded(_ work: Work, continuation: AsyncStream<Void>.Continuation) {
                if work == .task {
                    continuation.finish()
                }
                if work == Work.task {
                    continuation.finish()
                }
            }
            """

        // When
        let violations = try Self.findViolations(in: source, relativePath: "Sample.swift")

        // Then
        #expect(violations.count == 0)
    }

    /// 驗證註解與字串裡的 `.finish()` 不會被當成程式碼
    ///
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    @Test
    func taskFinish_註解與字串中的文字_不判定違規() throws {
        // Given
        let source = """
            Text("內容").task {
                // store.send(.view(.task)).finish()
                let example = ".finish()"
                store.send(.view(.task))
            }
            """

        // When
        let violations = try Self.findViolations(in: source, relativePath: "Sample.swift")

        // Then
        #expect(violations.count == 0)
    }

    /// 驗證字串字面值中的豁免標記不會讓 `.finish()` 通過
    ///
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    @Test
    func taskFinish_上一行字串含豁免標記_判定違規() throws {
        // Given
        let source = """
            Text("內容").task {
                let note = "// task-finish-exempt: 範例文字"
                await store.send(.view(.task)).finish()
            }
            """

        // When
        let violations = try Self.findViolations(in: source, relativePath: "Sample.swift")

        // Then
        #expect(violations.map(\.locationDescription) == ["Sample.swift:3"])
    }

    /// 驗證區塊註解中的豁免標記不會讓 `.finish()` 通過
    ///
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    @Test
    func taskFinish_區塊註解含豁免標記_判定違規() throws {
        // Given
        let source = """
            Text("內容").task {
                /* // task-finish-exempt: 假理由 */
                await store.send(.view(.task)).finish()
            }
            """

        // When
        let violations = try Self.findViolations(in: source, relativePath: "Sample.swift")

        // Then
        #expect(violations.map(\.locationDescription) == ["Sample.swift:3"])
    }

    /// 驗證帶 `id` 參數的 `.task` closure 也會掃描其中的 `.finish()`
    ///
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    @Test
    func taskFinish_帶識別參數_判定違規() throws {
        // Given
        let source = """
            Text("內容").task(id: currentID) {
                await store.send(.view(.task)).finish()
            }
            """

        // When
        let violations = try Self.findViolations(in: source, relativePath: "Sample.swift")

        // Then
        #expect(violations.map(\.locationDescription) == ["Sample.swift:2"])
    }

    /// 驗證 Features 目錄的 `.task` closure 沒有未豁免的 `.finish()`
    ///
    /// - Throws: 目錄列舉、原始碼讀取或正規表示式建立失敗時丟出錯誤
    @Test
    func taskFinish_功能目錄_沒有未豁免命中() throws {
        // Given

        // When
        let scan = try Self.scanFeatureSources()

        // Then
        let violationLocations = scan.violations
            .map(\.locationDescription)
            .joined(separator: "、")
        #expect(scan.fileCount > 0, "Features/ 目錄沒有掃描到 Swift 檔")
        #expect(
            scan.violations.count == 0,
            "Features/ 有未豁免的 .task `.finish()`：\(violationLocations)"
        )
    }
}

// MARK: - Nested Types

private extension TaskFinishConventionScanTests {

    /// 原始碼掃描找到的違規位置
    struct Violation: Equatable {

        /// 相對於 `apps/ios` 的檔案路徑
        let file: String

        /// `.finish()` 所在的原始碼行號
        let line: Int

        /// 含相對路徑與行號的診斷文字
        var locationDescription: String {
            "\(file):\(line)"
        }
    }
}

// MARK: - Private Method

private extension TaskFinishConventionScanTests {

    /// 找出 `.task` closure 內沒有有效豁免理由的 `.finish()`
    ///
    /// - Parameters:
    ///   - source: 要掃描的原始 Swift 原始碼
    ///   - relativePath: 用於診斷的相對檔案路徑
    /// - Returns: 依行號排序的違規位置
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    static func findViolations(in source: String, relativePath: String) throws -> [Violation] {
        var stripMode = SwiftSourceStripping.StripMode.normal
        let strippedCode = source.components(separatedBy: "\n")
            .map {
                SwiftSourceStripping.stripCommentsAndStrings(from: $0, mode: &stripMode)
            }
            .joined(separator: "\n")
        let code = strippedCode as NSString
        let taskRanges = try matchingRanges(for: #"\.task\b"#, in: strippedCode)
        let finishRanges = try matchingRanges(for: #"\.finish\s*\(\s*\)"#, in: strippedCode)
        let lineComments = lineCommentContents(in: source)
        var violations: [Violation] = []
        var scannedFinishLocations: Set<Int> = []

        for taskRange in taskRanges {
            // modifier 依 kit 一行一個，`.task` 在行首；同一行只接受緊接在呼叫或閉包結尾之後
            let precedingCode = code.substring(to: taskRange.location)
            let isLineStart = precedingCode
                .components(separatedBy: "\n")
                .last?
                .allSatisfy(\.isWhitespace) ?? true
            let previousCharacter = precedingCode
                .reversed()
                .first { !$0.isWhitespace }
            let isExpressionEnd = previousCharacter == ")"
                || previousCharacter == "}"
                || previousCharacter == "]"
            guard isLineStart || isExpressionEnd else {
                continue
            }

            guard let openingBrace = taskClosureOpeningBrace(
                in: code,
                after: NSMaxRange(taskRange)
            ),
                  let closingBrace = matchingBrace(in: code, startingAt: openingBrace) else {
                continue
            }

            for finishRange in finishRanges where
                finishRange.location > openingBrace && finishRange.location < closingBrace {
                guard scannedFinishLocations.insert(finishRange.location).inserted else {
                    continue
                }
                let line = code.substring(to: finishRange.location)
                    .filter { $0 == "\n" }
                    .count + 1
                let hasValidExemption = [line, line - 1].contains { exemptionLineNumber in
                    let lineIndex = exemptionLineNumber - 1
                    guard lineComments.indices.contains(lineIndex),
                          let comment = lineComments[lineIndex],
                          let markerRange = comment.range(of: "task-finish-exempt:") else {
                        return false
                    }
                    return !comment[markerRange.upperBound...]
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .isEmpty
                }
                guard !hasValidExemption else {
                    continue
                }
                violations.append(Violation(file: relativePath, line: line))
            }
        }

        return violations.sorted { left, right in
            left.line < right.line
        }
    }

    /// 取得符合正規表示式的所有範圍
    ///
    /// - Parameters:
    ///   - pattern: 要比對的正規表示式
    ///   - source: 要比對的文字
    /// - Returns: 依原始順序排列的文字範圍
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    static func matchingRanges(for pattern: String, in source: String) throws -> [NSRange] {
        let expression = try NSRegularExpression(pattern: pattern)
        let sourceNSString = source as NSString
        let range = NSRange(location: 0, length: sourceNSString.length)
        return expression.matches(in: source, range: range).map(\.range)
    }

    /// 從含豁免標記的原始碼行取得真正的 `//` 註解內容
    ///
    /// - Parameter source: 要檢查的 Swift 原始碼
    /// - Returns: 各行的註解內容；沒有行註解時為 `nil`
    static func lineCommentContents(in source: String) -> [String?] {
        let lines = source.components(separatedBy: "\n")
        return lines.enumerated().map { lineNumber, line in
            guard line.contains("task-finish-exempt:") else {
                return nil
            }
            var searchStart = line.startIndex
            while let commentRange = line.range(of: "//", range: searchStart..<line.endIndex) {
                let linePrefix = String(line[..<commentRange.lowerBound])
                let sourcePrefix = lines.prefix(lineNumber).joined(separator: "\n")
                let probePrefix = lineNumber == 0 ? linePrefix : sourcePrefix + "\n" + linePrefix
                let probe = DependencyConventionLexing.blankedCommentsAndStrings(
                    in: probePrefix + "@@"
                )
                if probe.hasSuffix("@@") {
                    return String(line[commentRange.upperBound...])
                }
                searchStart = commentRange.upperBound
            }
            return nil
        }
    }

    /// 找到 `.task` 後方 closure 的起始大括號
    ///
    /// - Parameters:
    ///   - code: 已移除註解與字串的程式碼
    ///   - taskEnd: `.task` 名稱結尾的 UTF-16 offset
    /// - Returns: closure 的起始大括號 offset，沒有 trailing closure 時為 `nil`
    static func taskClosureOpeningBrace(in code: NSString, after taskEnd: Int) -> Int? {
        var index = skipWhitespace(in: code, startingAt: taskEnd)
        if index < code.length, code.character(at: index) == 40 {
            var parenthesesDepth = 0
            var foundClosingParenthesis = false
            while index < code.length, !foundClosingParenthesis {
                let character = code.character(at: index)
                if character == 40 {
                    parenthesesDepth += 1
                } else if character == 41 {
                    parenthesesDepth -= 1
                    if parenthesesDepth == 0 {
                        foundClosingParenthesis = true
                    }
                }
                index += 1
            }
            guard foundClosingParenthesis else {
                return nil
            }
            index = skipWhitespace(in: code, startingAt: index)
        }

        guard index < code.length, code.character(at: index) == 123 else {
            return nil
        }
        return index
    }

    /// 略過空格、tab 與換行並回傳下一個字元位置
    ///
    /// - Parameters:
    ///   - code: 已移除註解與字串的程式碼
    ///   - startingIndex: 要開始略過空白的 UTF-16 offset
    /// - Returns: 第一個非空白字元的 UTF-16 offset，或文字結尾
    static func skipWhitespace(in code: NSString, startingAt startingIndex: Int) -> Int {
        var index = startingIndex
        while index < code.length {
            let character = code.character(at: index)
            guard character == 9 || character == 10 || character == 13 || character == 32 else {
                break
            }
            index += 1
        }
        return index
    }

    /// 找到 closure 起始大括號配對的結尾
    ///
    /// - Parameters:
    ///   - code: 已移除註解與字串的程式碼
    ///   - openingBrace: closure 起始大括號的 UTF-16 offset
    /// - Returns: 配對的結尾大括號 offset，沒有配對時為 `nil`
    static func matchingBrace(in code: NSString, startingAt openingBrace: Int) -> Int? {
        guard openingBrace < code.length, code.character(at: openingBrace) == 123 else {
            return nil
        }
        var depth = 0
        for index in openingBrace..<code.length {
            let character = code.character(at: index)
            if character == 123 {
                depth += 1
            } else if character == 125 {
                depth -= 1
                if depth == 0 {
                    return index
                }
            }
        }
        return nil
    }

    /// 掃描 Features 目錄下所有 Swift 檔並列出未豁免的 `.finish()`
    ///
    /// - Returns: 掃描檔案數與依路徑、行號排序的違規清單
    /// - Throws: 目錄列舉、原始檔讀取或正規表示式建立失敗時丟出錯誤
    static func scanFeatureSources() throws -> (fileCount: Int, violations: [Violation]) {
        let iosRoot = TestPaths.iosRoot
        let featureRoot = iosRoot
            .appending(path: "BuyLedger")
            .appending(path: "Features")
        let files = try SwiftSourceFiles.swiftFiles(
            under: featureRoot,
            shouldIncludeGenerated: true
        )
        var violations: [Violation] = []

        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            let relativePath = SwiftSourceFiles.relativePath(of: file, under: iosRoot)
            violations += try findViolations(in: source, relativePath: relativePath)
        }

        let sortedViolations = violations.sorted { left, right in
            if left.file == right.file {
                return left.line < right.line
            }
            return left.file < right.file
        }
        return (files.count, sortedViolations)
    }
}
