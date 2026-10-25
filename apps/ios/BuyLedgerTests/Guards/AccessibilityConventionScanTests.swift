//
//  AccessibilityConventionScanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/31.
//

import Foundation
import Testing

/// 無障礙慣例的單元測試，以掃描正式原始碼守門選取特徵與減少動態效果兩條規則
struct AccessibilityConventionScanTests {

    // MARK: - Properties

    /// View 建構單元起點的比對規則
    private static let viewUnitBoundaryPattern = #"^\s*(?:private\s+|internal\s+|fileprivate\s+|static\s+)*func\s+\w+\s*\(|^\s*(?:private\s+|internal\s+|fileprivate\s+|static\s+)*var\s+\w+\s*:\s*some\s+View\b"#

    /// 驗證正式原始碼中以條件式勾號表示選取的列都加上 `isSelected` 標準特徵，讓 VoiceOver 與 rotor 能辨識選取狀態
    ///
    /// - Throws: 讀取原始檔或建立比對規則失敗時丟出錯誤
    @Test
    func findSelectionTraitViolations_正式原始碼_選取勾號使用標準特徵() throws {
        // Given
        let root = Self.productionRoot

        // When
        let violations = try Self.findSelectionTraitViolations(under: root)

        // Then
        #expect(
            violations.isEmpty,
            "以下位置渲染條件式選取勾號卻未加 .isSelected 標準特徵：\(Self.describe(violations))"
        )
    }

    /// 驗證正式原始碼中每個 `animation` 修飾子都在呼叫行與其後兩行內，或動畫值的宣告本體內判斷 `reduceMotion`
    ///
    /// - Throws: 讀取原始檔失敗時丟出錯誤
    @Test
    func findUnguardedAnimationDeclarations_正式原始碼_動畫遵循減少動態效果偏好() throws {
        // Given
        let root = Self.productionRoot

        // When
        let violations = try Self.findUnguardedAnimationDeclarations(under: root)

        // Then
        #expect(violations.isEmpty, "以下位置宣告動畫卻未判斷減少動態效果偏好：\(Self.describe(violations))")
    }

    /// 驗證正式原始碼目錄能掃到 Swift 檔案，避免目錄解析錯誤時因掃描結果為空而通過
    ///
    /// - Throws: 掃描檔案失敗時丟出錯誤
    @Test
    func swiftFiles_正式原始碼目錄_至少有一個可掃描檔案() throws {
        // Given
        let root = Self.productionRoot

        // When
        let files = try SwiftSourceFiles.swiftFiles(under: root, shouldIncludeGenerated: true)

        // Then
        #expect(
            !files.isEmpty,
            "掃描到 0 個 Swift 檔案，productionRoot 疑似解析錯誤：\(Self.productionRoot.path)"
        )
    }
}

// MARK: - Nested Types

private extension AccessibilityConventionScanTests {

    /// 掃描命中的違規位置
    struct Violation {

        /// 相對於掃描根目錄的檔案路徑
        let file: String

        /// 命中所在的行號 (1-based)
        let line: Int
    }

    /// 掃描出的建構單元
    struct ViewUnit {

        /// 該單元涵蓋的原始檔行內容
        let lines: [String]

        /// 該單元第一行對應原始檔的行號 (1-based)
        let startLineNumber: Int
    }
}

// MARK: - Private Method

private extension AccessibilityConventionScanTests {

    /// 測試 target 所在的 iOS 平台目錄
    static var iosRoot: URL {
        TestPaths.iosRoot
    }

    /// App target 的掃描目錄
    static var productionRoot: URL {
        iosRoot.appending(path: "BuyLedger")
    }

    /// 掃描 `root` 內使用 `plain` 按鈕樣式的 View 單元，回報以條件式勾號表示選取卻未加 `isSelected` 特徵的位置
    ///
    /// - Parameter root: 掃描根目錄
    /// - Returns: 選取特徵違規清單
    /// - Throws: 讀取原始檔或建立比對規則失敗時丟出錯誤
    static func findSelectionTraitViolations(under root: URL) throws -> [Violation] {
        let boundary = try NSRegularExpression(pattern: viewUnitBoundaryPattern)
        var violations: [Violation] = []

        for file in try SwiftSourceFiles.swiftFiles(under: root, shouldIncludeGenerated: true) {
            let lines = try String(contentsOf: file, encoding: .utf8).components(separatedBy: "\n")

            for unit in viewUnits(in: lines, boundary: boundary) {
                guard unit.lines.contains(where: { $0.contains(".buttonStyle(.plain)") }) else {
                    continue
                }

                let checkmarkOffsets = conditionalCheckmarkOffsets(in: unit.lines)
                guard !checkmarkOffsets.isEmpty else {
                    continue
                }

                let unitText = unit.lines.joined(separator: "\n")
                let hasSelectedTrait = unitText.range(
                    of: #"accessibilityAddTraits\([^)]*isSelected"#,
                    options: .regularExpression
                ) != nil

                guard !hasSelectedTrait else {
                    continue
                }

                for offset in checkmarkOffsets {
                    violations.append(
                        Violation(
                            file: SwiftSourceFiles.relativePath(of: file, under: root),
                            line: unit.startLineNumber + offset
                        )
                    )
                }
            }
        }

        return violations.sorted { lhs, rhs in (lhs.file, lhs.line) < (rhs.file, rhs.line) }
    }

    /// 依 `viewUnitBoundaryPattern` 把原始碼行切成 View 建構單元
    ///
    /// - Parameters:
    ///   - lines: 原始碼各行
    ///   - boundary: 建構單元的宣告比對規則
    /// - Returns: View 建構單元清單
    static func viewUnits(in lines: [String], boundary: NSRegularExpression) -> [ViewUnit] {
        var markers: [Int] = []
        for (index, line) in lines.enumerated() {
            let range = NSRange(line.startIndex..<line.endIndex, in: line)
            if boundary.firstMatch(in: line, range: range) != nil {
                markers.append(index)
            }
        }
        guard !markers.isEmpty else {
            return []
        }

        return markers.enumerated().map { position, start in
            let end = position + 1 < markers.count ? markers[position + 1] : lines.count
            return ViewUnit(lines: Array(lines[start..<end]), startLineNumber: start + 1)
        }
    }

    /// 找出條件式勾號圖示所在的行索引
    ///
    /// - Parameter lines: 原始碼各行
    /// - Returns: 條件式勾號出現位置
    static func conditionalCheckmarkOffsets(in lines: [String]) -> [Int] {
        var offsets = Set<Int>()

        for (index, line) in lines.enumerated() where isInlineTernaryCheckmark(line) {
            offsets.insert(index)
        }

        for (index, line) in lines.enumerated() where isIfBlockOpening(line) {
            var depth = 1
            var cursor = index + 1
            while cursor < lines.count && depth > 0 {
                let bodyLine = lines[cursor]
                if isCheckmarkImageLine(bodyLine) {
                    offsets.insert(cursor)
                }
                depth += bodyLine.filter { $0 == "{" }.count
                depth -= bodyLine.filter { $0 == "}" }.count
                cursor += 1
            }
        }

        return offsets.sorted()
    }

    /// 判斷該行是否以三元運算式渲染勾號圖示
    ///
    /// - Parameter line: 待檢查的原始碼行
    /// - Returns: 該行是否為內嵌三元勾號
    static func isInlineTernaryCheckmark(_ line: String) -> Bool {
        isCheckmarkImageLine(line) && line.contains("?") && line.contains(":")
    }

    /// 判斷該行是否為 checkmark SF Symbol 圖示
    ///
    /// - Parameter line: 待檢查的原始碼行
    /// - Returns: 該行是否為勾號圖片
    static func isCheckmarkImageLine(_ line: String) -> Bool {
        !isCommentLine(line) && line.contains("Image(systemName:") && line.contains("\"checkmark")
    }

    /// 判斷該行是否為註解行 (以 `//` 開頭，涵蓋 `///` 文件註解與 `// MARK:`)
    ///
    /// - Parameter line: 待檢查的原始碼行
    /// - Returns: 該行是否為註解
    static func isCommentLine(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces).hasPrefix("//")
    }

    /// 判斷該行是否為 `if` 陳述式的開啟行 (陳述式與 `{` 同一行)
    ///
    /// - Parameter line: 待檢查的原始碼行
    /// - Returns: 該行是否開啟 if 區塊
    static func isIfBlockOpening(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.range(of: #"^if\b.*\{\s*$"#, options: .regularExpression) != nil
    }

    /// 把違規清單格式化為人可讀的條列訊息
    ///
    /// - Parameter violations: 掃描命中的違規位置
    /// - Returns: 人可讀的說明
    static func describe(_ violations: [Violation]) -> String {
        violations.map { "\($0.file):\($0.line)" }.joined(separator: "、")
    }

    /// 掃描 `root` 內未判斷減少動態效果的 `animation` 修飾子，回報違規位置
    ///
    /// - Parameter root: 掃描根目錄
    /// - Returns: 未判斷減少動態效果的動畫違規位置清單
    /// - Throws: 讀取原始檔失敗時丟出錯誤
    static func findUnguardedAnimationDeclarations(under root: URL) throws -> [Violation] {
        var violations: [Violation] = []

        for file in try SwiftSourceFiles.swiftFiles(under: root, shouldIncludeGenerated: true) {
            let lines = try String(contentsOf: file, encoding: .utf8).components(separatedBy: "\n")

            for (index, line) in lines.enumerated()
                where line.contains(".animation(") && !isCommentLine(line) {
                let windowEnd = min(lines.count, index + 3)
                let window = lines[index..<windowEnd].joined(separator: "\n")
                if window.contains("reduceMotion") {
                    continue
                }

                if let symbol = animationValueSymbol(in: line),
                   declarationConsultsReduceMotion(symbol, in: lines) {
                    continue
                }

                violations.append(
                    Violation(
                        file: SwiftSourceFiles.relativePath(of: file, under: root),
                        line: index + 1
                    )
                )
            }
        }

        return violations.sorted { lhs, rhs in (lhs.file, lhs.line) < (rhs.file, rhs.line) }
    }

    /// 取出 `animation` 修飾子第一個引數的識別字名稱
    ///
    /// - Parameter line: 含動畫宣告的原始碼行
    /// - Returns: 動畫值的識別名稱
    static func animationValueSymbol(in line: String) -> String? {
        let pattern = #"\.animation\(\s*(?:Self\.|self\.)?([A-Za-z_][A-Za-z0-9_]*)\s*[,)]"#
        let expression: NSRegularExpression
        do {
            expression = try NSRegularExpression(pattern: pattern)
        } catch {
            return nil
        }

        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = expression.firstMatch(in: line, range: range),
              let symbolRange = Range(match.range(at: 1), in: line) else {
            return nil
        }

        return String(line[symbolRange])
    }

    /// 判斷同檔內某個屬性／函式的宣告本身是否判斷了減少動態效果偏好
    ///
    /// - Parameters:
    ///   - symbol: 動畫值的識別名稱
    ///   - lines: 原始碼各行
    /// - Returns: 宣告是否處理減少動態效果
    static func declarationConsultsReduceMotion(_ symbol: String, in lines: [String]) -> Bool {
        let pattern = #"\b(?:var|func)\s+"#
            + NSRegularExpression.escapedPattern(for: symbol)
            + #"\b"#
        guard let declarationIndex = lines.firstIndex(where: {
            !isCommentLine($0) && $0.range(of: pattern, options: .regularExpression) != nil
        }) else {
            return false
        }

        var depth = 0
        var bodyLines: [String] = []
        let scanLimit = min(lines.count, declarationIndex + 60)

        for cursor in declarationIndex..<scanLimit {
            let line = lines[cursor]
            bodyLines.append(line)
            depth += line.filter { $0 == "{" }.count
            depth -= line.filter { $0 == "}" }.count
            if depth <= 0 {
                break
            }
        }

        return bodyLines.joined(separator: "\n").contains("reduceMotion")
    }
}
