//
//  ProjectionWriteBoundaryTests+Scanner.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation

// MARK: - Nested Types

extension ProjectionWriteBoundaryTests {

    /// 共享訂單投影守門的自我測試資料
    struct SharedOrderScenario: Sendable {

        /// 相對於 App 原始碼根目錄的路徑
        let relativePath: String

        /// 待判定的原始碼
        let source: String

        /// 兩條守門規則合計的違規筆數
        let expectedCount: Int
    }

    /// 一個投影持有 feature 與它持有的唯讀投影屬性名
    struct ProjectionOwner {

        /// feature 型別名稱
        let name: String

        /// 根狀態持有此 feature 的屬性名稱
        let rootStateKey: String

        /// feature 主檔相對路徑
        let homeFileRelativePath: String

        /// 該 feature `State` 內、由 `RootFeature` 單向同步的唯讀投影屬性名
        let properties: [String]
    }

    /// 掃描命中的違規位置
    struct Violation {

        /// 相對於 App source root 的檔案路徑
        let file: String

        /// 命中所在的行號 (1-based)
        let line: Int

        /// 被寫入的投影屬性名，或命中規則的描述文字 (`inout`、`withLock`、可寫參考外傳)
        let property: String
    }
}

// MARK: - Internal Method

extension ProjectionWriteBoundaryTests {

    /// 掃描各 feature 的寫入位置
    ///
    /// - Returns: 違規清單
    /// - Throws: 原始檔讀取或規則建立失敗時拋出錯誤
    static func findViolations() throws(any Error) -> [Violation] {
        var violations: [Violation] = []
        let files = try swiftFiles(under: productionRoot).filter {
            relativePath(of: $0, under: productionRoot) != rootFeatureRelativePath
        }

        for file in files {
            let relative = relativePath(of: file, under: productionRoot)
            let source = try String(contentsOf: file, encoding: .utf8)
            violations += try rootProjectionViolations(relativePath: relative, source: source)
        }

        for owner in projectionOwners {
            for file in files {
                let relative = relativePath(of: file, under: productionRoot)
                violations += try findBlockContextViolations(
                    in: file,
                    relativePath: relative,
                    owner: owner
                )
                violations += try findInoutParameterViolations(
                    in: file,
                    relativePath: relative,
                    owner: owner
                )
            }
        }

        return violations.sorted { lhs, rhs in
            (lhs.file, lhs.line) < (rhs.file, rhs.line)
        }
    }

    /// 依檔案路徑與原始碼判定共享訂單投影的兩條守門規則
    ///
    /// - Parameters:
    ///   - relativePath: 相對於 App 原始碼根目錄的路徑
    ///   - source: 原始碼內容
    /// - Returns: 非根功能寫入與開團或更多功能可寫參考外傳的違規位置
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    static func sharedOrderViolations(
        relativePath: String,
        source: String
    ) throws(any Error) -> [Violation] {
        var mode = StripMode.normal
        let stripped = source.components(separatedBy: "\n")
            .map {
                stripCommentsAndStrings(from: $0, mode: &mode)
            }
            .joined(separator: "\n")
        let text = stripped as NSString
        var violations: [Violation] = []

        if relativePath != rootFeatureRelativePath {
            let writes = try NSRegularExpression(pattern: #"\$orders\b\s*\.\s*withLock\b"#)
            for match in writes.matches(in: stripped, range: fullRange(of: stripped)) {
                let prefix = text.substring(to: match.range.location)
                let line = prefix.components(separatedBy: "\n").count
                violations.append(
                    Violation(file: relativePath, line: line, property: "$orders.withLock")
                )
            }
        }

        let readerOnlyDirectories = ["Features/Campaigns/", "Features/More/"]
        guard readerOnlyDirectories.contains(where: relativePath.hasPrefix) else {
            return violations
        }
        let references = try NSRegularExpression(pattern: #"\$orders\b"#)
        let readerPrefix = try NSRegularExpression(
            pattern: #"\bSharedReader\s*\(\s*(?:[\p{L}_$][\p{L}\p{N}_$]*\s*\.\s*)*$"#
        )
        let readerSuffix = try NSRegularExpression(pattern: #"^\s*\)"#)
        for match in references.matches(in: stripped, range: fullRange(of: stripped)) {
            let prefix = text.substring(to: match.range.location)
            let suffix = text.substring(from: NSMaxRange(match.range))
            let prefixMatch = readerPrefix.firstMatch(in: prefix, range: fullRange(of: prefix))
            let suffixMatch = readerSuffix.firstMatch(in: suffix, range: fullRange(of: suffix))
            if prefixMatch == nil || suffixMatch == nil {
                let line = prefix.components(separatedBy: "\n").count
                violations.append(
                    Violation(file: relativePath, line: line, property: "$orders 可寫參考")
                )
            }
        }
        return violations
    }

    /// 禁止根功能以外透過根狀態的子層路徑寫入投影，來源資料不受此規則限制
    ///
    /// - Parameters:
    ///   - relativePath: 相對於 App 原始碼根目錄的路徑
    ///   - source: 待掃描的原始碼
    /// - Returns: 根子層投影被賦值或變異的位置
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    static func rootProjectionViolations(
        relativePath: String,
        source: String
    ) throws(any Error) -> [Violation] {
        guard relativePath != rootFeatureRelativePath else {
            return []
        }
        var mode = StripMode.normal
        let stripped = source.components(separatedBy: "\n")
            .map {
                stripCommentsAndStrings(from: $0, mode: &mode)
            }
            .joined(separator: "\n")
        let text = stripped as NSString
        var violations: [Violation] = []
        for owner in projectionOwners {
            for property in owner.properties {
                let pattern = try rootProjectionWritePattern(
                    rootKey: owner.rootStateKey,
                    property: property
                )
                for match in pattern.matches(in: stripped, range: fullRange(of: stripped)) {
                    let prefix = text.substring(to: match.range.location)
                    let line = prefix.components(separatedBy: "\n").count
                    violations.append(
                        Violation(
                            file: relativePath,
                            line: line,
                            property: "\(owner.rootStateKey).\(property)"
                        )
                    )
                }
            }
        }
        return violations
    }
}

// MARK: - Private Method

private extension ProjectionWriteBoundaryTests {

    /// 掃描單一檔案中的 owner 區塊
    ///
    /// - Parameters:
    ///   - file: 要掃描的檔案
    ///   - relativePath: 檔案相對路徑
    ///   - owner: 投影擁有者
    /// - Returns: 區塊上下文違規清單
    /// - Throws: 原始檔讀取或規則建立失敗時拋出錯誤
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

            if stripped.contains("{"), try opensOwnerContext(stripped, ownerName: owner.name) {
                ownerBlockStartDepths.append(depth + 1)
            }

            depth += stripped.count { $0 == "{" }
            depth -= stripped.count { $0 == "}" }

            while let top = ownerBlockStartDepths.last, depth < top {
                ownerBlockStartDepths.removeLast()
            }

            guard !ownerBlockStartDepths.isEmpty else {
                continue
            }

            for property in owner.properties where try isWritten(property, in: stripped) {
                violations.append(
                    Violation(file: relativePath, line: index + 1, property: property)
                )
            }
        }

        return violations
    }

    /// 判斷是否為 owner 區塊標頭
    ///
    /// - Parameters:
    ///   - strippedLine: 已移除註解與字串內容的程式碼
    ///   - ownerName: 要尋找的投影擁有者名稱
    /// - Returns: 是否開啟投影擁有者區塊
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    static func opensOwnerContext(
        _ strippedLine: String,
        ownerName: String
    ) throws(any Error) -> Bool {
        let escapedOwner = NSRegularExpression.escapedPattern(for: ownerName)
        let pattern = try NSRegularExpression(
            pattern: #"\b(?:struct|extension)\s+"# + escapedOwner + #"\b"#
        )
        return pattern.firstMatch(in: strippedLine, range: fullRange(of: strippedLine)) != nil
    }

    /// 掃描外部檔案取得投影擁有者狀態寫入權的參數
    ///
    /// - Parameters:
    ///   - file: 要掃描的檔案
    ///   - relativePath: 檔案相對路徑
    ///   - owner: 投影擁有者
    /// - Returns: inout 參數違規清單
    /// - Throws: 原始檔讀取或規則建立失敗時拋出錯誤
    static func findInoutParameterViolations(
        in file: URL,
        relativePath: String,
        owner: ProjectionOwner
    ) throws(any Error) -> [Violation] {
        guard relativePath != owner.homeFileRelativePath else {
            return []
        }

        let content = try String(contentsOf: file, encoding: .utf8)
        let rawLines = content.components(separatedBy: "\n")
        var stripMode = StripMode.normal
        var violations: [Violation] = []
        let escapedOwner = NSRegularExpression.escapedPattern(for: owner.name)
        let pattern = try NSRegularExpression(
            pattern: #"\binout\s+"# + escapedOwner + #"\.State\b"#
        )

        for (index, rawLine) in rawLines.enumerated() {
            let stripped = stripCommentsAndStrings(from: rawLine, mode: &stripMode)
            if pattern.firstMatch(in: stripped, range: fullRange(of: stripped)) != nil {
                violations.append(
                    Violation(
                        file: relativePath,
                        line: index + 1,
                        property: "inout \(owner.name).State 參數"
                    )
                )
            }
        }

        return violations
    }
}
