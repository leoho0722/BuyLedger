//
//  ProjectionWriteBoundaryScanner.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation

/// 掃描投影擁有者、根狀態與共享資料的寫入邊界
enum ProjectionWriteBoundaryScanner {

    // MARK: - Properties

    /// `RootFeature.swift` 的相對路徑，掃描時排除唯一合法寫入者
    private static let rootFeatureRelativePath = "Features/App/Presentation/Root/RootFeature.swift"

    /// 各 feature 持有的投影屬性
    static let projectionOwners: [ProjectionOwner] = [
        ProjectionOwner(
            name: "OrdersFeature",
            rootStateKey: "orders",
            homeFileRelativePath: "Features/Orders/Presentation/Root/OrdersFeature.swift",
            properties: ["campaigns", "defaultCurrency", "aiSummarySettings"]
        ),
        ProjectionOwner(
            name: "MoreFeature",
            rootStateKey: "more",
            homeFileRelativePath: "Features/More/Presentation/Root/MoreFeature.swift",
            properties: ["preferences", "biometryType"]
        ),
        ProjectionOwner(
            name: "AppLockFeature",
            rootStateKey: "appLock",
            homeFileRelativePath: "Features/App/Presentation/AppLock/AppLockFeature.swift",
            properties: ["isBiometricUnlockEnabled"]
        ),
        ProjectionOwner(
            name: "CampaignFeature",
            rootStateKey: "campaigns",
            homeFileRelativePath: "Features/Campaigns/Presentation/Root/CampaignFeature.swift",
            properties: ["orders"]
        ),
        ProjectionOwner(
            name: "CustomersFeature",
            rootStateKey: "customers",
            homeFileRelativePath: "Features/Customers/Presentation/Root/CustomersFeature.swift",
            properties: ["orders"]
        ),
        ProjectionOwner(
            name: "DashboardFeature",
            rootStateKey: "dashboard",
            homeFileRelativePath: "Features/Dashboard/Presentation/Root/DashboardFeature.swift",
            properties: ["orders", "campaigns", "monthlyProfitGoalTWD", "loadState"]
        ),
        ProjectionOwner(
            name: "InsightsFeature",
            rootStateKey: "insights",
            homeFileRelativePath: "Features/Insights/Presentation/Root/InsightsFeature.swift",
            properties: ["orders", "campaigns", "loadState"]
        ),
    ]
}

// MARK: - Nested Types

extension ProjectionWriteBoundaryScanner {

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

// MARK: - Computed Properties

extension ProjectionWriteBoundaryScanner {

    /// App target 的掃描根目錄
    static var productionRoot: URL {
        iosRoot.appending(path: "BuyLedger")
    }
}

// MARK: - Internal Method

extension ProjectionWriteBoundaryScanner {

    /// 掃描各 feature 的寫入位置
    ///
    /// - Returns: 違規清單
    /// - Throws: 原始檔讀取或規則建立失敗時丟出錯誤
    static func findViolations() throws -> [Violation] {
        var violations: [Violation] = []
        let files = try SwiftSourceFiles.swiftFiles(under: productionRoot)
        for file in files {
            let relative = SwiftSourceFiles.relativePath(of: file, under: productionRoot)
            let source = try String(contentsOf: file, encoding: .utf8)
            violations += try projectionViolations(relativePath: relative, source: source)
        }
        return violations.sorted { lhs, rhs in
            (lhs.file, lhs.line) < (rhs.file, rhs.line)
        }
    }

    /// 以正式掃描的同一入口找出根路徑、擁有者區塊與外部 `State` 參數的違規位置
    ///
    /// - Parameters:
    ///   - relativePath: 相對於 App 原始碼根目錄的路徑
    ///   - source: 待掃描的原始碼內容
    /// - Returns: 投影寫入與外部可寫 `State` 參數的違規位置
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    static func projectionViolations(relativePath: String, source: String) throws -> [Violation] {
        guard relativePath != rootFeatureRelativePath else {
            return []
        }
        var violations = try rootProjectionViolations(relativePath: relativePath, source: source)
        violations += try sharedCampaignViolations(relativePath: relativePath, source: source)
        for owner in projectionOwners {
            violations += try findBlockContextViolations(
                in: source,
                relativePath: relativePath,
                owner: owner
            )
            violations += try ProjectionWriteBoundaryPatterns.stateValueParameterViolations(
                relativePath: relativePath,
                source: source,
                owner: owner
            )
            violations += try findInoutParameterViolations(
                in: source,
                relativePath: relativePath,
                owner: owner
            )
        }
        return violations
    }

    /// 依檔案路徑與原始碼找出共享訂單投影的違規位置，套用兩條守門規則
    ///
    /// - Parameters:
    ///   - relativePath: 相對於 App 原始碼根目錄的路徑
    ///   - source: 原始碼內容
    /// - Returns: 非擁有者寫入與開團或更多功能可寫參考外傳的違規位置
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    static func sharedOrderViolations(relativePath: String, source: String) throws -> [Violation] {
        var mode = SwiftSourceStripping.StripMode.normal
        let stripped = source.components(separatedBy: "\n")
            .map {
                SwiftSourceStripping.stripCommentsAndStrings(from: $0, mode: &mode)
            }
            .joined(separator: "\n")
        let text = stripped as NSString
        var violations: [Violation] = []

        let writerPaths = [
            rootFeatureRelativePath,
            "Features/Orders/Presentation/OrdersLoad/OrdersLoadFeature.swift",
            "Features/Orders/Presentation/OrderWrites/OrderWritesFeature.swift",
        ]
        if !writerPaths.contains(relativePath) {
            let writes = try NSRegularExpression(pattern: #"\$orders\b\s*\.\s*withLock\b"#)
            for match in writes.matches(
                in: stripped,
                range: ProjectionWriteBoundaryPatterns.fullRange(of: stripped)
            ) {
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
        for match in references.matches(
            in: stripped,
            range: ProjectionWriteBoundaryPatterns.fullRange(of: stripped)
        ) {
            let prefix = text.substring(to: match.range.location)
            let suffix = text.substring(from: NSMaxRange(match.range))
            let prefixMatch = readerPrefix.firstMatch(
                in: prefix,
                range: ProjectionWriteBoundaryPatterns.fullRange(of: prefix)
            )
            let suffixMatch = readerSuffix.firstMatch(
                in: suffix,
                range: ProjectionWriteBoundaryPatterns.fullRange(of: suffix)
            )
            if prefixMatch == nil || suffixMatch == nil {
                let line = prefix.components(separatedBy: "\n").count
                violations.append(
                    Violation(file: relativePath, line: line, property: "$orders 可寫參考")
                )
            }
        }
        return violations
    }

    /// 找出根功能以外透過根狀態內各功能路徑寫入投影的位置，來源資料不受此規則限制
    ///
    /// - Parameters:
    ///   - relativePath: 相對於 App 原始碼根目錄的路徑
    ///   - source: 待掃描的原始碼
    /// - Returns: 根狀態內各功能持有的投影被賦值或變異的位置
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    static func rootProjectionViolations(
        relativePath: String,
        source: String
    ) throws -> [Violation] {
        guard relativePath != rootFeatureRelativePath else {
            return []
        }
        var mode = SwiftSourceStripping.StripMode.normal
        let stripped = source.components(separatedBy: "\n")
            .map {
                SwiftSourceStripping.stripCommentsAndStrings(from: $0, mode: &mode)
            }
            .joined(separator: "\n")
        let text = stripped as NSString
        var violations: [Violation] = []
        for owner in projectionOwners {
            for property in owner.properties {
                let pattern = try ProjectionWriteBoundaryPatterns.rootProjectionWritePattern(
                    rootKey: owner.rootStateKey,
                    property: property
                )
                for match in pattern.matches(
                    in: stripped,
                    range: ProjectionWriteBoundaryPatterns.fullRange(of: stripped)
                ) {
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

private extension ProjectionWriteBoundaryScanner {

    /// 測試 target 所在的 iOS 平台目錄
    static var iosRoot: URL {
        TestPaths.iosRoot
    }

    /// 找出訂單端寫入、外傳或重綁可寫開團引用的位置，唯讀訂單狀態的底層共享儲存只允許在初始化時轉換
    ///
    /// - Parameters:
    ///   - relativePath: 相對於 App 原始碼根目錄的路徑
    ///   - source: 待掃描的原始碼內容
    /// - Returns: 寫入、外傳或重綁可寫開團引用的位置
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    static func sharedCampaignViolations(
        relativePath: String,
        source: String
    ) throws -> [Violation] {
        guard relativePath.hasPrefix("Features/Orders/") else {
            return []
        }
        var mode = SwiftSourceStripping.StripMode.normal
        let stripped = source.components(separatedBy: "\n")
            .map {
                SwiftSourceStripping.stripCommentsAndStrings(from: $0, mode: &mode)
            }
            .joined(separator: "\n")
        let text = stripped as NSString
        let declaration = #"@SharedReader\s+var\s+campaigns\b"#
        let isReaderFile = relativePath != "Features/Orders/Presentation/Root/OrdersFeature.swift"
            && stripped.range(of: declaration, options: .regularExpression) != nil
        let referencePattern = relativePath
            == "Features/Orders/Presentation/Root/OrdersFeature.swift"
            ? #"(?:\$|\b_)campaigns\b"# : #"\$campaigns\b"#
        let references = try NSRegularExpression(pattern: referencePattern)
        let readerPrefix = try NSRegularExpression(
            pattern: #"\bSharedReader\s*\(\s*(?:[\p{L}_$][\p{L}\p{N}_$]*\s*\.\s*)*$"#
        )
        let readerSuffix = try NSRegularExpression(pattern: #"^\s*\)"#)
        let assignment = #"(?:\[[^\]]*\]\s*)?(?:=(?!=)|\+=|-=|\*=|/=)"#
        let writeSuffix = try NSRegularExpression(
            pattern: #"^\s*(?:\.\s*withLock\b|(?:\.\s*wrappedValue\s*)?"# + assignment + ")"
        )
        let rootPattern = try ProjectionWriteBoundaryPatterns.rootProjectionWritePattern(
            rootKey: "orders",
            property: "campaigns"
        )
        let rootWrites = rootPattern.matches(
            in: stripped,
            range: ProjectionWriteBoundaryPatterns.fullRange(of: stripped)
        )
        let matches = references.matches(
            in: stripped,
            range: ProjectionWriteBoundaryPatterns.fullRange(of: stripped)
        )
        return try matches.compactMap { match in
            // 根路徑寫入由同一掃描入口的根投影規則回報，避免同一引用重複計數
            let isRootWrite = rootWrites.contains {
                NSLocationInRange(match.range.location, $0.range)
            }
            if isRootWrite {
                return nil
            }
            let prefix = text.substring(to: match.range.location)
            let suffix = text.substring(from: NSMaxRange(match.range))
            let isWrite = writeSuffix.firstMatch(
                in: suffix,
                range: ProjectionWriteBoundaryPatterns.fullRange(of: suffix)
            ) != nil
            let isStorage = text.substring(with: match.range).hasPrefix("_")
            let isReaderAllowed = try isInsideInitializer(prefix) || !isStorage
            let isReaderConversion = isReaderAllowed
                && readerPrefix.firstMatch(
                    in: prefix,
                    range: ProjectionWriteBoundaryPatterns.fullRange(of: prefix)
                ) != nil
                && readerSuffix.firstMatch(
                    in: suffix,
                    range: ProjectionWriteBoundaryPatterns.fullRange(of: suffix)
                ) != nil
            if !isWrite && (isReaderFile || isReaderConversion) {
                return nil
            }
            let line = prefix.components(separatedBy: "\n").count
            return Violation(file: relativePath, line: line, property: "開團可寫參考")
        }
    }

    /// 以大括號範圍確認引用仍位於初始化方法內，保留巢狀 closure 的上下文
    ///
    /// - Parameter prefix: 已移除註解與字串的引用前原始碼
    /// - Returns: 引用是否位於尚未結束的初始化方法內
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    static func isInsideInitializer(_ prefix: String) throws -> Bool {
        let pattern = try NSRegularExpression(pattern: #"(?<![\w.])init\s*\(|[{}]"#)
        var initializerScopes: [Bool] = []
        var isInitializer = false
        for match in pattern.matches(
            in: prefix,
            range: ProjectionWriteBoundaryPatterns.fullRange(of: prefix)
        ) {
            switch (prefix as NSString).substring(with: match.range) {
            case "{":
                initializerScopes.append(isInitializer)
                isInitializer = false

            case "}":
                _ = initializerScopes.popLast()

            default:
                isInitializer = true
            }
        }
        return initializerScopes.contains(true)
    }

    /// 掃描單一檔案中的 `owner` 區塊
    ///
    /// - Parameters:
    ///   - source: 待掃描的原始碼內容
    ///   - relativePath: 檔案相對路徑
    ///   - owner: 投影擁有者
    /// - Returns: 區塊上下文違規清單
    /// - Throws: 原始檔讀取或規則建立失敗時丟出錯誤
    static func findBlockContextViolations(
        in source: String,
        relativePath: String,
        owner: ProjectionOwner
    ) throws -> [Violation] {
        let rawLines = source.components(separatedBy: "\n")
        var stripMode = SwiftSourceStripping.StripMode.normal
        var depth = 0
        var ownerBlockStartDepths: [Int] = []
        var violations: [Violation] = []

        for (index, rawLine) in rawLines.enumerated() {
            let stripped = SwiftSourceStripping.stripCommentsAndStrings(
                from: rawLine,
                mode: &stripMode
            )

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

            for property in owner.properties
                where try ProjectionWriteBoundaryPatterns.isWritten(property, in: stripped) {
                violations.append(
                    Violation(file: relativePath, line: index + 1, property: property)
                )
            }
        }

        return violations
    }

    /// 判斷是否為 `owner` 區塊標頭
    ///
    /// - Parameters:
    ///   - strippedLine: 已移除註解與字串內容的程式碼
    ///   - ownerName: 要尋找的投影擁有者名稱
    /// - Returns: 是否開啟投影擁有者區塊
    /// - Throws: 正規表示式建立失敗時丟出錯誤
    static func opensOwnerContext(_ strippedLine: String, ownerName: String) throws -> Bool {
        let escapedOwner = NSRegularExpression.escapedPattern(for: ownerName)
        let pattern = try NSRegularExpression(
            pattern: #"\b(?:struct|extension)\s+"# + escapedOwner + #"\b"#
        )
        return pattern.firstMatch(
            in: strippedLine,
            range: ProjectionWriteBoundaryPatterns.fullRange(of: strippedLine)
        ) != nil
    }

    /// 找出外部檔案中以 `inout` 取得投影擁有者 `State` 寫入權的參數位置
    ///
    /// - Parameters:
    ///   - source: 待掃描的原始碼內容
    ///   - relativePath: 檔案相對路徑
    ///   - owner: 投影擁有者
    /// - Returns: `inout` 參數違規清單
    /// - Throws: 原始檔讀取或規則建立失敗時丟出錯誤
    static func findInoutParameterViolations(
        in source: String,
        relativePath: String,
        owner: ProjectionOwner
    ) throws -> [Violation] {
        guard relativePath != owner.homeFileRelativePath else {
            return []
        }

        let rawLines = source.components(separatedBy: "\n")
        var stripMode = SwiftSourceStripping.StripMode.normal
        var violations: [Violation] = []
        let escapedOwner = NSRegularExpression.escapedPattern(for: owner.name)
        let pattern = try NSRegularExpression(
            pattern: #"\binout\s+"# + escapedOwner + #"\.State\b"#
        )

        for (index, rawLine) in rawLines.enumerated() {
            let stripped = SwiftSourceStripping.stripCommentsAndStrings(
                from: rawLine,
                mode: &stripMode
            )
            if pattern.firstMatch(
                in: stripped,
                range: ProjectionWriteBoundaryPatterns.fullRange(of: stripped)
            ) != nil {
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
