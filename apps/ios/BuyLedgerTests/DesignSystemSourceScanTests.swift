//
//  DesignSystemSourceScanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/1.
//

import Foundation
import Testing

/// 掃描式守門：把設計系統的色彩單一入口不變式轉為機器強制
struct DesignSystemSourceScanTests {
    
    // MARK: - Tests
    
    /// 確認掃描根目錄可取得檔案
    /// - Throws: 掃描檔案失敗時拋出錯誤
    @Test func productionRootYieldsScannableFiles() throws(any Error) {
        let files = try Self.swiftFiles(under: Self.productionRoot)
        
        #expect(
            !files.isEmpty, "掃描到 0 個 Swift 檔案，productionRoot 疑似解析錯誤：\(Self.productionRoot.path)")
    }
    
    /// 規則一：資訊性文字使用 `Color.blSecondaryLabel`
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test func systemSecondaryColorIsNotUsedForText() throws(any Error) {
        let violations = try Self.findViolations(
            under: Self.productionRoot, matching: Self.secondaryColorPattern)
        
        #expect(
            violations.isEmpty,
            "以下位置直接使用系統次要色於文字，應改用 Color.blSecondaryLabel：\(Self.describe(violations))"
        )
    }
    
    /// 規則二：不得直接使用系統強調色，一律經色盤的 `accent` 取用
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test func systemAccentColorIsNotUsedDirectly() throws(any Error) {
        let violations = try Self.findViolations(
            under: Self.productionRoot, matching: Self.accentColorPattern)
        
        #expect(
            violations.isEmpty,
            "以下位置直接使用系統強調色，應改為在該處取得色盤實例後呼叫 .accent：\(Self.describe(violations))"
        )
    }
    
    /// 規則三：元件不得直接使用系統色彩，必須經色盤取用
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test func namedSystemHueColorsAreNotUsedDirectly() throws(any Error) {
        let violations = try Self.findViolations(
            under: Self.productionRoot, matching: Self.namedHueTokenPattern)
        
        #expect(
            violations.isEmpty,
            "以下位置直接使用系統色相字面值，應改為在該處取得色盤實例後呼叫對應色彩屬性：\(Self.describe(violations))"
        )
    }
    
    /// 規則四：系統取色 API 只准在色盤檔
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test func systemColorAPIsAppearOnlyInThePalette() throws(any Error) {
        let violations = try Self.findViolations(
            under: Self.productionRoot,
            matching: Self.systemColorAPIPattern,
            excludingFilesNamed: ["BLPalette.swift"]
        )
        
        #expect(
            violations.isEmpty,
            "以下位置在色盤檔之外呼叫系統取色介面，新增系統色請加進色盤的顯示屬性再由呼叫端取用：\(Self.describe(violations))"
        )
    }
    
    /// 規則五：原始色彩建構只出現在色盤與頭像元件
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test func rawColorConstructionAppearsOnlyInItsTwoHomes() throws(any Error) {
        let violations = try Self.findViolations(
            under: Self.productionRoot,
            matching: Self.rawConstructionPattern,
            excludingFilesNamed: ["BLPalette.swift", "BLAvatar.swift"]
        )
        
        #expect(
            violations.isEmpty,
            "以下位置在色盤檔與頭像元件之外從原始分量建構色彩，語意色一律改經色盤的系統取色介面：\(Self.describe(violations))"
        )
    }
    
    /// 規則六：`colorScheme` 只准用於卡片陰影修飾子
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test func colorSchemeEnvironmentDeclarationAppearsOnlyInCardShadow() throws(any Error) {
        let violations = try Self.findViolations(
            under: Self.productionRoot,
            matching: Self.colorSchemeDeclarationPattern,
            excludingFilesNamed: ["BLCardShadow.swift"]
        )
        
        #expect(
            violations.isEmpty,
            "以下位置宣告了外觀環境依賴，僅卡片陰影修飾子真正讀取此值，其餘宣告應移除：\(Self.describe(violations))"
        )
    }
    
    /// 規則七：禁止使用十六進位顏色建構子
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test func hexadecimalColorInitializerHasNoOccurrences() throws(any Error) {
        let violations = try Self.findViolations(
            under: Self.productionRoot, matching: Self.hexInitializerPattern)
        
        #expect(
            violations.isEmpty,
            "以下位置仍存在十六進位顏色建構子，該建構子應已完全移除：\(Self.describe(violations))"
        )
    }
    
    /// 規則八：豁免標記必須有理由
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test func exemptionMarkersCarryNonEmptyReasons() throws(any Error) {
        let markers = try Self.findExemptionMarkers(under: Self.productionRoot)
        
        print("目前全部有效豁免 (\(markers.count) 筆)：")
        for marker in markers {
            print(
                "  \(marker.violation.file):\(marker.violation.line): "
                    + (marker.reason.isEmpty ? "(無理由)" : marker.reason)
            )
        }
        
        let emptyReasonMarkers = markers.filter { $0.reason.isEmpty }
        #expect(
            emptyReasonMarkers.isEmpty,
            "以下豁免標記未附理由，具名豁免標記必須帶非空理由：\(Self.describe(emptyReasonMarkers.map(\.violation)))"
        )
    }
}

// MARK: - Static Properties

private extension DesignSystemSourceScanTests {
    
    /// 測試 target 所在的 iOS 平台目錄
    static var iosRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
    
    /// 受掃描的產品程式碼目錄；只含 App target 本身，排除生成檔目錄
    static var productionRoot: URL {
        iosRoot.appending(path: "BuyLedger")
    }
    
    /// 生成檔目錄不納入設計系統規則掃描
    static let excludedDirectoryName = "Generated"
    
    /// 具名豁免標記的前綴；理由文字為冒號後的內容
    static let exemptionMarkerPrefix = "design-system-scan-exempt:"
    
    /// 規則一：secondary 色彩只用於文字
    static let secondaryColorPattern = try! NSRegularExpression(
        pattern:
            #"\bforegroundStyle\(\.secondary\)|"#
                + #"\bforegroundColor\(\.secondary\)|"#
                + #"\bColor\.secondary\b"#
    )
    
    /// 規則二：禁止直接使用系統強調色
    static let accentColorPattern = try! NSRegularExpression(
        pattern: #"\bColor\.accentColor\b|(?<![\w)])\.accentColor\b"#
    )
    
    /// 規則三：掃描命名系統色的直接使用
    static let namedHueTokenPattern = try! NSRegularExpression(
        pattern:
            #"(?<![\w)])\.(red|green|blue|orange|yellow|purple|pink|teal|indigo|mint|cyan|"#
                + #"brown|gray)\b"#
                + #"|\bColor\.(red|green|blue|orange|yellow|purple|pink|teal|indigo|mint|cyan|"#
                + #"brown|gray)\b"#
    )
    
    /// 規則四：系統取色 API 只准在色盤檔
    static let systemColorAPIPattern = try! NSRegularExpression(
        pattern: #"(?<!\w)Color\(uiColor:|\bUIColor(?:\(|\.)"#
    )
    
    /// 規則五：從原始分量建構色彩，僅色盤檔與頭像元件可用
    static let rawConstructionPattern = try! NSRegularExpression(
        pattern:
            #"(?<!\w)Color\(blHex|(?<!\w)Color\(\s*\.sRGB|"#
                + #"(?<!\w)Color\(\s*red:|(?<!\w)Color\(\s*hue:|"#
                + #"(?<!\w)UIColor\(\s*red:"#
    )
    
    /// 規則六：外觀環境依賴宣告，僅卡片陰影修飾子可用
    static let colorSchemeDeclarationPattern = try! NSRegularExpression(
        pattern: #"@Environment\(\\\.colorScheme\)"#
    )
    
    /// 規則七：十六進位顏色建構子，全庫零命中 (含宣告本身)
    static let hexInitializerPattern = try! NSRegularExpression(
        pattern: #"init\(blHex|Color\(blHex"#
    )
}

// MARK: - Nested Types

private extension DesignSystemSourceScanTests {
    
    /// 掃描命中的違規位置
    struct Violation {
        
        // MARK: - Data Properties
        
        /// 相對於掃描根目錄的檔案路徑
        let file: String
        
        /// 命中所在的行號 (1-based)
        let line: Int
    }
    
    /// 具名豁免標記的命中，含其理由文字
    struct ExemptionMarker {
        
        // MARK: - Data Properties
        
        /// 標記所在位置
        let violation: Violation
        
        /// 標記冒號後的理由文字 (已去除頭尾空白)；為空字串表示未附理由
        let reason: String
    }
    
    /// `stripCommentsAndStrings` 的逐行掃描狀態
    enum StripMode {
        
        // MARK: - Cases
        
        /// 一般程式碼
        case normal
        
        /// 位於 `/* ... */` 區塊註解內
        case blockComment
        
        /// 位於 `"""..."""` 多行字串字面值內
        case tripleQuotedString
    }
}

// MARK: - Private Method

private extension DesignSystemSourceScanTests {
    
    /// 掃描根目錄中的違規位置，忽略註解與字串內容
    /// - Returns: 設計系統違規清單
    static func findViolations(
        under root: URL,
        matching pattern: NSRegularExpression,
        excludingFilesNamed excludedFileNames: Set<String> = []
    ) throws(any Error) -> [Violation] {
        var violations: [Violation] = []
        
        for file in try swiftFiles(under: root)
        where !excludedFileNames.contains(file.lastPathComponent) {
            let rawLines = try String(contentsOf: file, encoding: .utf8).components(
                separatedBy: "\n")
            var stripMode = StripMode.normal
            
            for (index, rawLine) in rawLines.enumerated() {
                let stripped = stripCommentsAndStrings(from: rawLine, mode: &stripMode)
                guard lineViolates(pattern, in: stripped) else { continue }
                guard exemptionReason(onRawLine: rawLine) == nil else { continue }
                
                violations.append(
                    Violation(file: relativePath(of: file, under: root), line: index + 1))
            }
        }
        
        return violations.sorted { ($0.file, $0.line) < ($1.file, $1.line) }
    }
    
    /// 掃描根目錄下所有具名豁免標記
    /// - Parameter root: 掃描根目錄
    /// - Returns: 豁免標記清單
    /// - Throws: 原始檔讀取失敗時拋出錯誤
    static func findExemptionMarkers(under root: URL) throws(any Error) -> [ExemptionMarker] {
        var markers: [ExemptionMarker] = []
        
        for file in try swiftFiles(under: root) {
            let rawLines = try String(contentsOf: file, encoding: .utf8).components(
                separatedBy: "\n")
            
            for (index, rawLine) in rawLines.enumerated() {
                guard let reason = exemptionReason(onRawLine: rawLine) else { continue }
                markers.append(
                    ExemptionMarker(
                        violation: Violation(
                            file: relativePath(of: file, under: root), line: index + 1),
                        reason: reason
                    ))
            }
        }
        
        return markers.sorted {
            ($0.violation.file, $0.violation.line) < ($1.violation.file, $1.violation.line)
        }
    }
    
    /// 該行是否帶具名豁免標記，並回傳其理由文字 (已去除頭尾空白)
    /// - Returns: 豁免原因
    static func exemptionReason(onRawLine rawLine: String) -> String? {
        guard let range = rawLine.range(of: exemptionMarkerPrefix) else { return nil }
        return rawLine[range.upperBound...].trimmingCharacters(in: .whitespaces)
    }
    
    /// 移除行註解、區塊註解與字串內容
    /// - Returns: 移除註解與字串後的內容
    static func stripCommentsAndStrings(from line: String, mode: inout StripMode) -> String {
        let characters = Array(line)
        var result: [Character] = []
        var index = 0
        var isInSingleLineString = false
        var previousInString: Character?
        
        while index < characters.count {
            switch mode {
            case .blockComment:
                if hasPrefix(characters, at: index, marker: ["*", "/"]) {
                    mode = .normal
                    index += 2
                } else {
                    index += 1
                }
                continue
            
            case .tripleQuotedString:
                if hasPrefix(characters, at: index, marker: ["\"", "\"", "\""]) {
                    mode = .normal
                    index += 3
                } else {
                    index += 1
                }
                continue
            
            case .normal:
                break
            }
            
            if isInSingleLineString {
                let character = characters[index]
                if character == "\"" && previousInString != "\\" {
                    isInSingleLineString = false
                }
                previousInString = character
                index += 1
                continue
            }
            
            if hasPrefix(characters, at: index, marker: ["\"", "\"", "\""]) {
                mode = .tripleQuotedString
                index += 3
                continue
            }
            
            let character = characters[index]
            
            if character == "\"" {
                isInSingleLineString = true
                previousInString = character
                index += 1
                continue
            }
            
            if hasPrefix(characters, at: index, marker: ["/", "*"]) {
                mode = .blockComment
                index += 2
                continue
            }
            
            if hasPrefix(characters, at: index, marker: ["/", "/"]) {
                break
            }
            
            result.append(character)
            index += 1
        }
        
        return String(result)
    }
    
    /// 判斷字元陣列在指定索引處是否以給定樣式開頭
    /// - Returns: 是否符合指定前綴
    static func hasPrefix(
        _ characters: [Character],
        at index: Int,
        marker: [Character]
    ) -> Bool {
        guard index + marker.count <= characters.count else { return false }
        for offset in 0..<marker.count where characters[index + offset] != marker[offset] {
            return false
        }
        return true
    }
    
    /// 判定該行 (已剝除註解與字串) 是否命中違例樣式
    /// - Returns: 該行是否違反規則
    static func lineViolates(_ pattern: NSRegularExpression, in text: String) -> Bool {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        var violates = false
        
        pattern.enumerateMatches(in: text, range: range) {
            result,
            _,
            stop in
            guard let result, let matchRange = Range(result.range, in: text) else { return }
            
            if pattern === namedHueTokenPattern, result.range(at: 1).location != NSNotFound {
                guard isBareHueTokenInValuePosition(in: text, matchStart: matchRange.lowerBound)
                else { return }
            }
            
            violates = true
            stop.pointee = true
        }
        
        return violates
    }
    
    /// 判斷裸前置點色相字面值是否落在「顏色值位置」
    /// - Returns: 是否為值位置中的裸 hue token
    static func isBareHueTokenInValuePosition(in text: String, matchStart: String.Index) -> Bool {
        var depth = 0
        var index = matchStart
        
        while index > text.startIndex {
            index = text.index(before: index)
            let character = text[index]
            
            if character == ")" || character == "]" {
                depth += 1
                continue
            }
            guard character == "(" || character == "[" else { continue }
            guard depth == 0 else {
                depth -= 1
                continue
            }
            
            if character == "[" {
                return true
            }
            
            var identifierStart = index
            while identifierStart > text.startIndex {
                let previous = text.index(before: identifierStart)
                guard text[previous].isLetter || text[previous].isNumber || text[previous] == "_"
                else { break }
                identifierStart = previous
            }
            guard identifierStart < index else { return true }
            
            let precededByDot =
                identifierStart > text.startIndex
                && text[text.index(before: identifierStart)] == "."
            let isTypeInitializerCall = !precededByDot && text[identifierStart].isUppercase
            return !isTypeInitializerCall
        }
        
        return false
    }
    
    /// 列出根目錄下所有 Swift 原始檔，排除生成檔目錄
    /// - Parameter root: 掃描根目錄
    /// - Returns: Swift 檔案清單
    /// - Throws: 目錄讀取失敗時拋出錯誤
    static func swiftFiles(under root: URL) throws(any Error) -> [URL] {
        let enumerator = try #require(
            FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        )
        
        var files: [URL] = []
        for case let file as URL in enumerator {
            if file.pathComponents.contains(excludedDirectoryName) {
                continue
            }
            if file.pathExtension == "swift" {
                files.append(file)
            }
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
    /// - Returns: 人可讀的違規說明
    static func describe(_ violations: [Violation]) -> String {
        violations.map { "\($0.file):\($0.line)" }.joined(separator: "、")
    }
}
