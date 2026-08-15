//
//  ProjectionWriteBoundaryTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/2.
//

import Foundation
import Testing

/// 確認投影只有 ``RootFeature`` 可以寫入
struct ProjectionWriteBoundaryTests {
    
    // MARK: - Tests
    
    /// 確認投影持有者檔案都存在
    /// - Throws: 原始檔讀取失敗時拋出錯誤
    @Test func projectionOwnerHomeFilesResolveToExistingSwiftFiles() throws(any Error) {
        #expect(
            Self.projectionOwners.count == 4,
            "投影持有 feature 清單應恰為 4 個，目前為 \(Self.projectionOwners.count) 個"
        )
        
        for owner in Self.projectionOwners {
            let url = Self.productionRoot.appending(path: owner.homeFileRelativePath)
            #expect(
                FileManager.default.fileExists(atPath: url.path),
                "找不到 \(owner.name) 的主檔 \(owner.homeFileRelativePath)，投影清單已過時：\(url.path)"
            )
        }
    }
    
    /// 驗證掃描涵蓋足夠的 App 檔案
    /// - Throws: 原始檔讀取失敗時拋出錯誤
    @Test func projectionOwnerDeclarationsAreDiscoverable() throws(any Error) {
        let files = try Self.swiftFiles(under: Self.productionRoot)
        #expect(
            files.count >= Self.minimumProductionFileCount,
            "App target Swift 檔案數量不足，productionRoot：\(Self.productionRoot.path)"
        )
        
        for owner in Self.projectionOwners {
            let found = try Self.ownerStructDeclarationIsDiscoverable(owner: owner, in: files)
            #expect(found, "掃描不到 `struct \(owner.name)` 的宣告，掃描機制或 projectionOwners.name 疑似與現況脫節")
        }
    }
    
    /// 驗證投影屬性只能由 RootFeature.swift 寫入
    /// - Throws: 原始檔掃描失敗時拋出錯誤
    @Test func projectionsAreOnlyWrittenByRootFeature() throws(any Error) {
        let violations = try Self.findViolations()
        
        #expect(
            violations.isEmpty,
            "以下位置寫入了唯讀投影，投影一律只能由 RootFeature 寫入：\(Self.describe(violations))"
        )
    }
}

// MARK: - Nested Types

private extension ProjectionWriteBoundaryTests {
    
    /// 一個投影持有 feature 與它持有的唯讀投影屬性名
    struct ProjectionOwner {
        
        // MARK: - Data Properties
        
        /// feature 型別名稱
        let name: String
        
        /// feature 主檔相對路徑
        let homeFileRelativePath: String
        
        /// 該 feature `State` 內、由 `RootFeature` 單向同步的唯讀投影屬性名
        let properties: [String]
    }
    
    /// 掃描命中的違規位置
    struct Violation {
        
        // MARK: - Data Properties
        
        /// 相對於 App source root 的檔案路徑
        let file: String
        
        /// 命中所在的行號 (1-based)
        let line: Int
        
        /// 被寫入的投影屬性名，或 `inout` 命中時的描述文字
        let property: String
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
        
        /// 位於 `/* ... */` 區塊註解內；可巢狀
        case blockComment
        
        /// 位於 `"""..."""` 多行字串字面值內
        case tripleQuotedString
        
        /// 判斷是否位於單行字串內
        case singleLineString(escaped: Bool)
        
        /// 判斷是否位於字串插值內
        case interpolation(parenDepth: Int)
    }
}

// MARK: - Static Properties

private extension ProjectionWriteBoundaryTests {
    
    /// 測試 target 所在的 iOS 平台目錄
    static var iosRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
    
    /// App target 的掃描根目錄
    static var productionRoot: URL {
        iosRoot.appending(path: "BuyLedger")
    }
    
    /// RootFeature.swift 的相對路徑；掃描時排除唯一合法寫入者
    static let rootFeatureRelativePath = "Features/App/RootFeature.swift"
    
    /// Generated 目錄不納入掃描
    static let excludedDirectoryName = "Generated"
    
    /// App target 檔案數量下限
    static let minimumProductionFileCount = 100
    
    /// 各 feature 持有的投影屬性
    static let projectionOwners: [ProjectionOwner] = [
        ProjectionOwner(
            name: "CampaignFeature",
            homeFileRelativePath: "Features/Campaigns/CampaignFeature.swift",
            properties: ["orders"]
        ),
        ProjectionOwner(
            name: "CustomersFeature",
            homeFileRelativePath: "Features/Customers/CustomersFeature.swift",
            properties: ["orders"]
        ),
        ProjectionOwner(
            name: "DashboardFeature",
            homeFileRelativePath: "Features/Dashboard/DashboardFeature.swift",
            properties: ["orders", "campaigns", "monthlyProfitGoalTwd", "loadState"]
        ),
        ProjectionOwner(
            name: "InsightsFeature",
            homeFileRelativePath: "Features/Insights/InsightsFeature.swift",
            properties: ["orders", "campaigns", "loadState"]
        ),
    ]
    
    /// 可能改變陣列或字典內容的 mutating 方法
    static let mutatingMethodNames = [
        "append", "removeAll", "remove", "insert", "sort", "swapAt",
        "removeFirst", "removeLast", "removeSubrange", "replaceSubrange",
        "reserveCapacity", "shuffle", "reverse",
    ]
}

// MARK: - Private Method

private extension ProjectionWriteBoundaryTests {
    
    // MARK: 違規掃描：主流程
    
    /// 掃描各 feature 的寫入位置
    /// - Returns: 違規清單
    /// - Throws: 原始檔讀取失敗時拋出錯誤
    static func findViolations() throws(any Error) -> [Violation] {
        var violations: [Violation] = []
        let files = try swiftFiles(under: productionRoot).filter {
            relativePath(of: $0, under: productionRoot) != rootFeatureRelativePath
        }
        
        for owner in projectionOwners {
            for file in files {
                let relative = relativePath(of: file, under: productionRoot)
                violations += try findBlockContextViolations(
                    in: file, relativePath: relative, owner: owner)
                violations += try findInoutParameterViolations(
                    in: file, relativePath: relative, owner: owner)
            }
        }
        
        return violations.sorted { ($0.file, $0.line) < ($1.file, $1.line) }
    }
    
    // MARK: 違規掃描：區塊上下文 (prong 1)
    
    /// 掃描單一檔案中的 owner 區塊
    /// - Parameters:
    ///   - file: 要掃描的檔案
    ///   - relativePath: 檔案相對路徑
    ///   - owner: 投影擁有者
    /// - Returns: 區塊上下文違規清單
    /// - Throws: 原始檔解析失敗時拋出錯誤
    static func findBlockContextViolations(
        in file: URL,
        relativePath: String,
        owner: ProjectionOwner
    ) throws(any Error) -> [Violation] {
        let content = try String(contentsOf: file, encoding: .utf8)
        let rawLines = content.components(separatedBy: "\n")
        var stripMode = StripMode.normal
        var depth = 0
        var ownerBlockStartDepths: [Int] = []
        var violations: [Violation] = []
        
        for (index, rawLine) in rawLines.enumerated() {
            let stripped = stripCommentsAndStrings(from: rawLine, mode: &stripMode)
            
            if stripped.contains("{"), opensOwnerContext(stripped, ownerName: owner.name) {
                ownerBlockStartDepths.append(depth + 1)
            }
            
            depth += stripped.count { $0 == "{" }
            depth -= stripped.count { $0 == "}" }
            
            while let top = ownerBlockStartDepths.last, depth < top {
                ownerBlockStartDepths.removeLast()
            }
            
            guard !ownerBlockStartDepths.isEmpty else { continue }
            
            for property in owner.properties where isWritten(property, in: stripped) {
                violations.append(
                    Violation(file: relativePath, line: index + 1, property: property))
            }
        }
        
        return violations
    }
    
    /// 判斷是否為 owner 區塊標頭
    /// - Returns: 是否開啟 owner context
    static func opensOwnerContext(_ strippedLine: String, ownerName: String) -> Bool {
        let escapedOwner = NSRegularExpression.escapedPattern(for: ownerName)
        let pattern = try! NSRegularExpression(
            pattern: #"\b(?:struct|extension)\s+"# + escapedOwner + #"\b"#)
        return pattern.firstMatch(in: strippedLine, range: fullRange(of: strippedLine)) != nil
    }
    
    // MARK: 違規掃描：inout 整份 state 取得寫入權 (prong 2)
    
    /// 掃描單一檔案中的 owner 區塊
    /// - Parameters:
    ///   - file: 要掃描的檔案
    ///   - relativePath: 檔案相對路徑
    ///   - owner: 投影擁有者
    /// - Returns: inout 參數違規清單
    /// - Throws: 原始檔解析失敗時拋出錯誤
    static func findInoutParameterViolations(
        in file: URL,
        relativePath: String,
        owner: ProjectionOwner
    ) throws(any Error) -> [Violation] {
        guard relativePath != owner.homeFileRelativePath else { return [] }
        
        let content = try String(contentsOf: file, encoding: .utf8)
        let rawLines = content.components(separatedBy: "\n")
        var stripMode = StripMode.normal
        var violations: [Violation] = []
        let escapedOwner = NSRegularExpression.escapedPattern(for: owner.name)
        let pattern = try! NSRegularExpression(
            pattern: #"\binout\s+"# + escapedOwner + #"\.State\b"#)
        
        for (index, rawLine) in rawLines.enumerated() {
            let stripped = stripCommentsAndStrings(from: rawLine, mode: &stripMode)
            if pattern.firstMatch(in: stripped, range: fullRange(of: stripped)) != nil {
                violations.append(
                    Violation(
                        file: relativePath, line: index + 1,
                        property: "inout \(owner.name).State 參數"))
            }
        }
        
        return violations
    }
    
    // MARK: 寫入樣式判定
    
    /// 判斷單行是否修改指定 property
    /// - Returns: 是否有寫入
    static func isWritten(_ property: String, in line: String) -> Bool {
        for prefix in ["state", "self"] {
            if assignmentPattern(prefix: prefix, property: property).firstMatch(
                in: line, range: fullRange(of: line)) != nil {
                return true
            }
            if mutatingCallPattern(prefix: prefix, property: property).firstMatch(
                in: line, range: fullRange(of: line)) != nil {
                return true
            }
        }
        if bareAssignmentPattern(property: property).firstMatch(
            in: line, range: fullRange(of: line)) != nil {
            return true
        }
        if bareMutatingCallPattern(property: property).firstMatch(
            in: line, range: fullRange(of: line)) != nil {
            return true
        }
        return false
    }
    
    /// 建立有前綴的賦值樣式
    /// - Returns: 指派比對規則
    static func assignmentPattern(prefix: String, property: String) -> NSRegularExpression {
        let escapedProperty = NSRegularExpression.escapedPattern(for: property)
        let escapedPrefix = NSRegularExpression.escapedPattern(for: prefix)
        return try! NSRegularExpression(
            pattern: #"\b"# + escapedPrefix + #"\."# + escapedProperty
                + #"\b\s*(?:\[[^\]]*\]\s*)?(?:=(?!=)|\+=|-=|\*=|/=)"#
        )
    }
    
    /// 建立裸賦值樣式
    /// - Returns: 不含前綴的指派比對規則
    static func bareAssignmentPattern(property: String) -> NSRegularExpression {
        let escaped = NSRegularExpression.escapedPattern(for: property)
        return try! NSRegularExpression(
            pattern: #"(?<![\w.])"# + escaped + #"\b\s*(?:\[[^\]]*\]\s*)?(?:=(?!=)|\+=|-=|\*=|/=)"#
        )
    }
    
    /// 建立「有前綴 mutating 方法呼叫」樣式：`<prefix>.<property>.<方法名>(`
    /// - Returns: 變更呼叫比對規則
    static func mutatingCallPattern(prefix: String, property: String) -> NSRegularExpression {
        let escapedProperty = NSRegularExpression.escapedPattern(for: property)
        let escapedPrefix = NSRegularExpression.escapedPattern(for: prefix)
        let alternation = mutatingMethodNames.map(NSRegularExpression.escapedPattern(for:)).joined(
            separator: "|")
        return try! NSRegularExpression(
            pattern: #"\b"# + escapedPrefix + #"\."# + escapedProperty + #"\.(?:"# + alternation
                + #")\s*\("#
        )
    }
    
    /// 建立裸 mutating 方法呼叫樣式
    /// - Returns: 不含前綴的變更呼叫比對規則
    static func bareMutatingCallPattern(property: String) -> NSRegularExpression {
        let escaped = NSRegularExpression.escapedPattern(for: property)
        let alternation = mutatingMethodNames.map(NSRegularExpression.escapedPattern(for:)).joined(
            separator: "|")
        return try! NSRegularExpression(
            pattern: #"(?<![\w.])"# + escaped + #"\.(?:"# + alternation + #")\s*\("#
        )
    }
    
    // MARK: 輔助
    
    /// 判斷是否有零縮排的 owner struct 宣告
    /// - Parameters:
    ///   - owner: 要尋找的投影擁有者
    ///   - files: 要搜尋的檔案清單
    /// - Returns: 是否找到 owner struct 宣告
    /// - Throws: 原始檔解析失敗時拋出錯誤
    static func ownerStructDeclarationIsDiscoverable(owner: ProjectionOwner, in files: [URL]) throws(any Error) -> Bool {
        let escapedOwner = NSRegularExpression.escapedPattern(for: owner.name)
        let pattern = try! NSRegularExpression(pattern: #"\bstruct\s+"# + escapedOwner + #"\b"#)
        
        for file in files {
            let content = try String(contentsOf: file, encoding: .utf8)
            var stripMode = StripMode.normal
            for rawLine in content.components(separatedBy: "\n") {
                let stripped = stripCommentsAndStrings(from: rawLine, mode: &stripMode)
                if pattern.firstMatch(in: stripped, range: fullRange(of: stripped)) != nil {
                    return true
                }
            }
        }
        return false
    }
    
    /// 整個字串的 `NSRange`
    /// - Returns: 完整字串範圍
    static func fullRange(of text: String) -> NSRange {
        NSRange(text.startIndex..<text.endIndex, in: text)
    }
    
    /// 把違規清單格式化為人可讀的條列訊息
    /// - Returns: 人可讀的違規說明
    static func describe(_ violations: [Violation]) -> String {
        violations.map { "\($0.file):\($0.line) (\($0.property))" }.joined(separator: "、")
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
    
    /// 把檔案絕對路徑轉為相對於掃描根目錄的路徑
    /// - Returns: 檔案相對路徑
    static func relativePath(of file: URL, under root: URL) -> String {
        let filePath = file.standardizedFileURL.path
        let rootPath = root.standardizedFileURL.path
        guard filePath.hasPrefix(rootPath) else {
            return filePath
        }
        return String(filePath.dropFirst(rootPath.count + 1))
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
}
