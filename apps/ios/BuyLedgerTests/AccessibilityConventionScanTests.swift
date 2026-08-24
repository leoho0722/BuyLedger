//
//  AccessibilityConventionScanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/31.
//

import Foundation
import Testing

/// 掃描式守門：把兩條原已明訂但只能靠人記得的無障礙規則轉為機器強制
struct AccessibilityConventionScanTests {
    
    // MARK: - Tests
    
    /// 驗證選取狀態使用標準 accessibility trait
    /// - Throws: 掃描檔案或規則驗證失敗時拋出錯誤
    @Test func selectionCheckmarksCarryTheStandardSelectedTrait() throws(any Error) {
        let violations = try Self.findSelectionTraitViolations(under: Self.productionRoot)
        
        #expect(
            violations.isEmpty,
            "以下位置渲染條件式選取勾號卻未加 .isSelected 標準特徵：\(Self.describe(violations))"
        )
    }
    
    /// 驗證選取狀態使用標準 accessibility trait
    /// - Throws: 掃描檔案或規則驗證失敗時拋出錯誤
    @Test func animationDeclarationsConsultTheReduceMotionPreference() throws(any Error) {
        let violations = try Self.findUnguardedAnimationDeclarations(under: Self.productionRoot)
        
        #expect(
            violations.isEmpty,
            "以下位置宣告動畫卻未判斷減少動態效果偏好：\(Self.describe(violations))"
        )
    }
    
    /// 確認掃描根目錄可取得檔案
    /// - Throws: 掃描檔案失敗時拋出錯誤
    @Test func productionRootYieldsScannableFiles() throws(any Error) {
        let files = try Self.swiftFiles(under: Self.productionRoot)
        
        #expect(
            !files.isEmpty, "掃描到 0 個 Swift 檔案，productionRoot 疑似解析錯誤：\(Self.productionRoot.path)")
    }
}

// MARK: - Static Properties

private extension AccessibilityConventionScanTests {
    
    /// 測試 target 所在的 iOS 平台目錄
    static var iosRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
    
    /// App target 的掃描目錄
    static var productionRoot: URL {
        iosRoot.appending(path: "BuyLedger")
    }
    
    /// 找出 Swift 檔案中的 View 建構單元
    static let viewUnitBoundaryPattern =
    #"^\s*(?:private\s+|internal\s+|fileprivate\s+|static\s+)*func\s+\w+\s*\("#
    + #"|^\s*(?:private\s+|internal\s+|fileprivate\s+|static\s+)*var\s+\w+\s*:\s*some\s+View\b"#
}

// MARK: - Nested Types

private extension AccessibilityConventionScanTests {
    
    /// 掃描命中的違規位置
    struct Violation {
        
        // MARK: - Data Properties
        
        /// 相對於掃描根目錄的檔案路徑
        let file: String
        
        /// 命中所在的行號 (1-based)
        let line: Int
    }
    
    /// 掃描出的建構單元
    struct ViewUnit {
        
        // MARK: - Data Properties
        
        /// 該單元涵蓋的原始檔行內容
        let lines: [String]
        
        /// 該單元第一行對應原始檔的行號 (1-based)
        let startLineNumber: Int
    }
}

// MARK: - Private Method

private extension AccessibilityConventionScanTests {
    
    /// 掃描「結構上條件式渲染選取勾號、卻未加標準選取特徵」的呼叫點
    /// - Parameter root: 掃描根目錄
    /// - Returns: 選取特徵違規清單
    /// - Throws: 原始檔解析失敗時拋出錯誤
    static func findSelectionTraitViolations(under root: URL) throws(any Error) -> [Violation] {
        let boundary = try NSRegularExpression(pattern: viewUnitBoundaryPattern)
        var violations: [Violation] = []
        
        for file in try swiftFiles(under: root) {
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
                let hasSelectedTrait =
                unitText.range(
                    of: #"accessibilityAddTraits\([^)]*isSelected"#,
                    options: .regularExpression
                ) != nil
                
                guard !hasSelectedTrait else {
                    continue
                }
                
                for offset in checkmarkOffsets {
                    violations.append(
                        Violation(
                            file: relativePath(of: file, under: root),
                            line: unit.startLineNumber + offset)
                    )
                }
            }
        }
        
        return violations.sorted { ($0.file, $0.line) < ($1.file, $1.line) }
    }
    
    /// 找出條件式勾號圖示的 offset
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
    
    /// 判斷是否為 checkmark SF Symbol
    /// - Returns: 該行是否為勾號圖片
    static func isCheckmarkImageLine(_ line: String) -> Bool {
        !isCommentLine(line) && line.contains("Image(systemName:") && line.contains("\"checkmark")
    }
    
    /// 該行是否為註解行 (以 `//` 開頭，涵蓋 `///` 文件註解與 `// MARK:`)
    /// - Returns: 該行是否為註解
    static func isCommentLine(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces).hasPrefix("//")
    }
    
    /// 判斷該行是否條件式渲染勾號圖示
    /// - Returns: 該行是否為內嵌三元勾號
    static func isInlineTernaryCheckmark(_ line: String) -> Bool {
        isCheckmarkImageLine(line) && line.contains("?") && line.contains(":")
    }
    
    /// 該行是否為 `if` 陳述式的開啟行 (陳述式本身與 `{` 同一行)
    /// - Returns: 該行是否開啟 if 區塊
    static func isIfBlockOpening(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.range(of: #"^if\b.*\{\s*$"#, options: .regularExpression) != nil
    }
    
    /// 掃描「宣告動畫卻未判斷減少動態效果偏好」的呼叫點
    /// - Parameter root: 掃描根目錄
    /// - Returns: 未處理減少動態效果的動畫違規
    /// - Throws: 原始檔解析失敗時拋出錯誤
    static func findUnguardedAnimationDeclarations(under root: URL) throws(any Error) -> [Violation] {
        var violations: [Violation] = []
        
        for file in try swiftFiles(under: root) {
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
                    Violation(file: relativePath(of: file, under: root), line: index + 1))
            }
        }
        
        return violations.sorted { ($0.file, $0.line) < ($1.file, $1.line) }
    }
    
    /// 解析 animation 的 value expression
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
              let symbolRange = Range(match.range(at: 1), in: line)
        else {
            return nil
        }
        
        return String(line[symbolRange])
    }
    
    /// 判斷同檔內某個屬性／函式的宣告本身是否判斷了減少動態效果偏好
    /// - Returns: 宣告是否處理減少動態效果
    static func declarationConsultsReduceMotion(_ symbol: String, in lines: [String]) -> Bool {
        let pattern =
        #"\b(?:var|func)\s+"# + NSRegularExpression.escapedPattern(for: symbol) + #"\b"#
        guard
            let declarationIndex = lines.firstIndex(where: {
                !isCommentLine($0) && $0.range(of: pattern, options: .regularExpression) != nil
            })
        else {
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
    
    /// 依 ``viewUnitBoundaryPattern`` 把檔案切成一段段建構單元
    /// - Returns: View 區塊清單
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
    
    /// 列出根目錄下所有 Swift 原始檔
    /// - Parameter root: 掃描根目錄
    /// - Returns: Swift 檔案清單
    /// - Throws: 目錄讀取失敗時拋出錯誤
    static func swiftFiles(under root: URL) throws(any Error) -> [URL] {
        let enumerator = try #require(
            FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        )
        
        var files: [URL] = []
        for case let file as URL in enumerator where file.pathExtension == "swift" {
            files.append(file)
        }
        return files
    }
    
    /// 把檔案絕對路徑轉為相對於掃描根目錄的路徑，讓違規訊息簡潔可讀
    /// - Returns: 檔案相對路徑
    static func relativePath(of file: URL, under root: URL) -> String {
        let filePath = file.standardizedFileURL.path
        let rootPath = root.standardizedFileURL.path
        guard filePath.hasPrefix(rootPath) else {
            return filePath
        }
        return String(filePath.dropFirst(rootPath.count + 1))
    }
    
    /// 把違規清單格式化為人可讀的條列訊息
    /// - Returns: 人可讀的說明
    static func describe(_ violations: [Violation]) -> String {
        violations.map { "\($0.file):\($0.line)" }.joined(separator: "、")
    }
}
