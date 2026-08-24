//
//  LayerBoundaryTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/1.
//

import Foundation
import Testing

/// 掃描式守門：把「Core 與 Shared 不認識 Features」的分層前提轉為機器強制
struct LayerBoundaryTests {
    
    // MARK: - Tests
    
    /// 確認分層掃描可取得檔案
    /// - Throws: 掃描檔案失敗時拋出錯誤
    @Test func productionRootsYieldScannableFiles() throws(any Error) {
        let featuresFiles = try Self.swiftFiles(under: Self.featuresRoot)
        let coreFiles = try Self.swiftFiles(under: Self.coreRoot)
        let sharedFiles = try Self.swiftFiles(under: Self.sharedRoot)
        
        #expect(
            featuresFiles.count >= Self.minimumProductionFileCount,
            "Features 檔案掃描數量不足：\(Self.featuresRoot.path)"
        )
        #expect(
            coreFiles.count >= Self.minimumProductionFileCount,
            "Core 檔案掃描數量不足：\(Self.coreRoot.path)"
        )
        #expect(
            sharedFiles.count >= Self.minimumProductionFileCount,
            "Shared 檔案掃描數量不足：\(Self.sharedRoot.path)"
        )
        
        let names = try Self.featureTopLevelDeclarationNames()
        #expect(
            names.count >= Self.minimumFeatureDeclarationNameCount,
            "Features 頂層宣告掃描數量不足"
        )
    }
    
    /// Core 與 Shared 不得宣告 Features 名稱
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test func coreAndSharedDoNotReferenceFeatureTypes() throws(any Error) {
        let names = try Self.featureTopLevelDeclarationNames()
        let violations = try Self.findViolations(
            featureNames: names, under: [Self.coreRoot, Self.sharedRoot])
        
        #expect(
            violations.isEmpty,
            "Core/Shared 不得引用 Features：\(Self.describe(violations))"
        )
    }
    
    /// 根 store 只能出現在根導覽宿主白名單
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test func rootStoreDeclarationsMatchTheNavigationHostWhitelist() throws(any Error) {
        let declaringFiles = try Self.filesDeclaringRootStore()
        
        #expect(
            declaringFiles == Self.rootStoreWhitelist,
            "根 store 宣告位置不符合白名單：\(declaringFiles.sorted().joined(separator: "、"))"
        )
    }
}

// MARK: - Static Properties

private extension LayerBoundaryTests {
    
    /// 測試 target 所在的 iOS 平台目錄
    static var iosRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
    
    /// App source root，相對路徑訊息以此為基準
    static var productionRoot: URL {
        iosRoot.appending(path: "BuyLedger")
    }
    
    /// 候選宣告名的擷取來源
    static var featuresRoot: URL {
        productionRoot.appending(path: "Features")
    }
    
    /// 受掃描目錄之一
    static var coreRoot: URL {
        productionRoot.appending(path: "Core")
    }
    
    /// 受掃描目錄之一
    static var sharedRoot: URL {
        productionRoot.appending(path: "Shared")
    }
    
    /// Generated 目錄不納入掃描
    static let excludedDirectoryName = "Generated"
    
    /// Features、Core、Shared 的檔案數下限
    static let minimumProductionFileCount = 15
    
    /// feature 宣告數量下限
    static let minimumFeatureDeclarationNameCount = 30
    
    /// 宣告前允許的修飾詞
    static let modifierPrefix =
        #"^(?:@\w+(?:\([^)]*\))?\s+|"#
        + #"(?:public|internal|package|private|fileprivate|open|final)\s+)*"#
    
    /// 可接受的頂層型別宣告
    static let typeDeclarationPattern = try! NSRegularExpression(
        pattern: modifierPrefix
            + #"(?:struct|class|enum|actor|protocol)\s+([A-Za-z_][A-Za-z0-9_]*)"#
    )
    
    /// 候選二：`typealias` 宣告
    static let typealiasDeclarationPattern = try! NSRegularExpression(
        pattern: modifierPrefix + #"typealias\s+([A-Za-z_][A-Za-z0-9_]*)"#
    )
    
    /// 候選三：檔案層級的頂層 `func` (含 `static func`)
    static let topLevelFunctionPattern = try! NSRegularExpression(
        pattern: modifierPrefix + #"(?:static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)"#
    )
    
    /// 候選四：檔案層級的頂層 `let`／`var` (含 `static let`／`static var`)
    static let topLevelVariablePattern = try! NSRegularExpression(
        pattern: modifierPrefix + #"(?:static\s+)?(?:let|var)\s+([A-Za-z_][A-Za-z0-9_]*)"#
    )
    
    /// 依序嘗試的候選擷取樣式；同一行只要命中任一樣式即取得一個候選名稱
    static let declarationPatterns = [
        typeDeclarationPattern,
        typealiasDeclarationPattern,
        topLevelFunctionPattern,
        topLevelVariablePattern,
    ]
    
    /// 排除 `private`／`fileprivate` 頂層宣告
    static let accessModifierExclusionPattern = try! NSRegularExpression(
        pattern: #"\b(?:private|fileprivate)\b"#)
    
    /// 可宣告根 store 的導覽宿主
    static let rootStoreWhitelist: Set<String> = [
        "Features/App/RootView.swift",
        "Features/App/RootTabLayout.swift",
        "Features/App/RootSidebarLayout.swift",
        "Features/More/MoreView.swift",
    ]
}

// MARK: - Nested Types

private extension LayerBoundaryTests {
    
    /// 掃描命中的違規位置
    struct Violation {
        
        // MARK: - Data Properties
        
        /// 相對於 App source root 的檔案路徑
        let file: String
        
        /// 命中所在的行號 (1-based)
        let line: Int
        
        /// 命中的 Features 頂層宣告名
        let typeName: String
    }
    
    /// 掃描模式使用的括號堆疊
    enum StripMode {
        
        // MARK: - Cases
        
        /// 一般程式碼
        case normal
        
        /// 位於 `/* ... */` 區塊註解內
        case blockComment
        
        /// 位於 `"""..."""` 多行字串字面值內
        case tripleQuotedString
    }
    
    /// 掃描模式使用的括號堆疊
    enum ScanFrame {
        
        // MARK: - Cases
        
        /// 一般程式碼 (含插值 `\(...)` 內的運算式)
        case code
        
        /// 判斷是否位於區塊註解內
        case blockComment
        
        /// 位於 `"""..."""` 多行字串字面值內
        case tripleQuotedString
        
        /// 判斷是否位於單行字串內
        case singleLineString(escaped: Bool)
        
        /// 判斷是否位於字串插值內
        case interpolation(parenDepth: Int)
    }
}

// MARK: - Private Method

private extension LayerBoundaryTests {
    
    // MARK: 候選名稱擷取
    
    /// 掃描 Features 下每支檔，擷取所有縮排為零的頂層宣告名
    /// - Returns: Features 頂層宣告名稱
    /// - Throws: 原始檔讀取失敗時拋出錯誤
    static func featureTopLevelDeclarationNames() throws(any Error) -> Set<String> {
        var names = Set<String>()
        
        for file in try swiftFiles(under: featuresRoot) {
            let rawLines = try String(contentsOf: file, encoding: .utf8).components(
                separatedBy: "\n")
            var stripMode = StripMode.normal
            
            for rawLine in rawLines {
                let stripped = stripCommentsAndStrings(from: rawLine, mode: &stripMode)
                names.formUnion(topLevelDeclarationNames(in: stripped))
            }
        }
        
        return names
    }
    
    /// 對移除註解與字串的行套用宣告樣式
    /// - Returns: 頂層宣告名稱
    static func topLevelDeclarationNames(in strippedLine: String) -> [String] {
        let range = NSRange(strippedLine.startIndex..<strippedLine.endIndex, in: strippedLine)
        var results: [String] = []
        
        for pattern in declarationPatterns {
            guard let match = pattern.firstMatch(in: strippedLine, range: range),
                let matchRange = Range(match.range(at: 0), in: strippedLine),
                let nameRange = Range(match.range(at: 1), in: strippedLine)
            else {
                continue
            }
            guard !isPrivateModifier(strippedLine[matchRange]) else {
                continue
            }
            results.append(String(strippedLine[nameRange]))
        }
        
        return results
    }
    
    /// 判斷擷取到的修飾詞前綴 (含宣告關鍵字本身) 是否帶 `private`／`fileprivate`
    /// - Returns: 是否為 private 修飾子
    static func isPrivateModifier(_ matchedPrefix: Substring) -> Bool {
        let text = String(matchedPrefix)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return accessModifierExclusionPattern.firstMatch(in: text, range: range) != nil
    }
    
    // MARK: 根 store 白名單掃描
    
    /// 找出宣告 `StoreOf<RootFeature>` 的檔案
    /// - Returns: 宣告 root store 的檔案名稱
    /// - Throws: 原始檔讀取失敗時拋出錯誤
    static func filesDeclaringRootStore() throws(any Error) -> Set<String> {
        var files = Set<String>()
        
        for file in try swiftFiles(under: featuresRoot) {
            let rawLines = try String(contentsOf: file, encoding: .utf8).components(
                separatedBy: "\n")
            var stripMode = StripMode.normal
            
            for rawLine in rawLines {
                let stripped = stripCommentsAndStrings(from: rawLine, mode: &stripMode)
                if stripped.contains("StoreOf<RootFeature>") {
                    files.insert(relativePath(of: file, under: productionRoot))
                    break
                }
            }
        }
        
        return files
    }
    
    // MARK: 違規掃描
    
    /// 掃描指定根目錄下所有檔案，找出命中任一 Features 頂層宣告名的位置
    /// - Parameters:
    ///   - featureNames: Features 名稱集合
    ///   - roots: 掃描根目錄
    /// - Returns: 層級違規清單
    /// - Throws: 原始檔讀取失敗時拋出錯誤
    static func findViolations(
        featureNames: Set<String>,
        under roots: [URL]
    ) throws(any Error) -> [Violation] {
        guard !featureNames.isEmpty else {
            return []
        }
        
        let alternation = featureNames.sorted()
            .map(NSRegularExpression.escapedPattern(for:))
            .joined(separator: "|")
        let pattern = try NSRegularExpression(pattern: #"\b(?:"# + alternation + #")\b"#)
        
        var violations: [Violation] = []
        
        for root in roots {
            for file in try swiftFiles(under: root) {
                let rawLines = try String(contentsOf: file, encoding: .utf8).components(
                    separatedBy: "\n")
                var stripMode = StripMode.normal
                
                for (index, rawLine) in rawLines.enumerated() {
                    let stripped = stripCommentsAndStrings(from: rawLine, mode: &stripMode)
                    guard let matchedName = firstMatch(pattern, in: stripped) else { continue }
                    
                    violations.append(
                        Violation(
                            file: relativePath(of: file, under: productionRoot),
                            line: index + 1,
                            typeName: matchedName
                        ))
                }
            }
        }
        
        return violations.sorted { ($0.file, $0.line) < ($1.file, $1.line) }
    }
    
    /// 回傳樣式在文字中的第一個命中內容
    /// - Returns: 第一個符合的字串
    static func firstMatch(_ pattern: NSRegularExpression, in text: String) -> String? {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let result = pattern.firstMatch(in: text, range: range),
            let matchRange = Range(result.range, in: text)
        else {
            return nil
        }
        return String(text[matchRange])
    }
    
    // MARK: 註解與字串剝除
    
    /// 移除行註解、區塊註解與字串內容
    /// - Returns: 移除註解與字串後的內容
    static func stripCommentsAndStrings(from line: String, mode: inout StripMode) -> String {
        let characters = Array(line)
        var result: [Character] = []
        var index = 0
        var stack: [ScanFrame]
        
        switch mode {
        case .normal:
            stack = [.code]
        case .blockComment:
            stack = [.blockComment]
        case .tripleQuotedString:
            stack = [.tripleQuotedString]
        }
        
        while index < characters.count {
            switch stack[stack.count - 1] {
            case .blockComment:
                if hasPrefix(characters, at: index, marker: ["/", "*"]) {
                    stack.append(.blockComment)
                    index += 2
                } else if hasPrefix(characters, at: index, marker: ["*", "/"]) {
                    stack.removeLast()
                    if stack.isEmpty { stack = [.code] }
                    index += 2
                } else {
                    index += 1
                }
            
            case .tripleQuotedString:
                if hasPrefix(characters, at: index, marker: ["\"", "\"", "\""]) {
                    stack.removeLast()
                    if stack.isEmpty { stack = [.code] }
                    index += 3
                } else if hasPrefix(characters, at: index, marker: ["\\", "("]) {
                    stack.append(.interpolation(parenDepth: 0))
                    index += 2
                } else {
                    index += 1
                }
            
            case .singleLineString(let escaped):
                let character = characters[index]
                if escaped {
                    stack[stack.count - 1] = .singleLineString(escaped: false)
                    index += 1
                } else if hasPrefix(characters, at: index, marker: ["\\", "("]) {
                    stack.append(.interpolation(parenDepth: 0))
                    index += 2
                } else if character == "\\" {
                    stack[stack.count - 1] = .singleLineString(escaped: true)
                    index += 1
                } else if character == "\"" {
                    stack.removeLast()
                    index += 1
                } else {
                    index += 1
                }
            
            case .interpolation(let parenDepth):
                let character = characters[index]
                if character == "(" {
                    stack[stack.count - 1] = .interpolation(parenDepth: parenDepth + 1)
                    result.append(character)
                    index += 1
                } else if character == ")" {
                    if parenDepth == 0 {
                        stack.removeLast()
                    } else {
                        stack[stack.count - 1] = .interpolation(parenDepth: parenDepth - 1)
                        result.append(character)
                    }
                    index += 1
                } else if hasPrefix(characters, at: index, marker: ["\"", "\"", "\""]) {
                    stack.append(.tripleQuotedString)
                    index += 3
                } else if character == "\"" {
                    stack.append(.singleLineString(escaped: false))
                    index += 1
                } else if hasPrefix(characters, at: index, marker: ["/", "*"]) {
                    stack.append(.blockComment)
                    index += 2
                } else {
                    result.append(character)
                    index += 1
                }
            
            case .code:
                if hasPrefix(characters, at: index, marker: ["\"", "\"", "\""]) {
                    stack.append(.tripleQuotedString)
                    index += 3
                } else if characters[index] == "\"" {
                    stack.append(.singleLineString(escaped: false))
                    index += 1
                } else if hasPrefix(characters, at: index, marker: ["/", "*"]) {
                    stack.append(.blockComment)
                    index += 2
                } else if hasPrefix(characters, at: index, marker: ["/", "/"]) {
                    index = characters.count
                } else {
                    result.append(characters[index])
                    index += 1
                }
            }
        }
        
        switch stack.last {
        case .blockComment:
            mode = .blockComment
        case .tripleQuotedString:
            mode = .tripleQuotedString
        default:
            mode = .normal
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
    
    // MARK: 檔案列舉
    
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
        violations.map { "\($0.file):\($0.line) (\($0.typeName))" }.joined(separator: "、")
    }
}
