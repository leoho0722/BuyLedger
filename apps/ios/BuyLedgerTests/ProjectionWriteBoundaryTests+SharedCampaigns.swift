//
//  ProjectionWriteBoundaryTests+SharedCampaigns.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import Foundation
import Testing

extension ProjectionWriteBoundaryTests {

    /// 唯讀開團宣告只允許讀取與傳遞，寫入與重綁仍由正式入口回報
    ///
    /// - Parameters:
    ///   - operation: 唯讀宣告後的讀取、傳遞或寫入片段
    ///   - expectedCount: 固定預期違規筆數
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    @Test(arguments: Self.readerCampaignProjectionScenarios)
    func projectionViolations_唯讀開團宣告檔_禁止寫入並允許讀取與傳遞(
        operation: String,
        expectedCount: Int
    ) throws(any Error) {
        // Given
        let source = "@SharedReader var campaigns: [Campaign]\n" + operation

        // When
        let violations = try Self.projectionViolations(
            relativePath: "Features/Orders/Presentation/OrderList/OrderListFeature.swift",
            source: source
        )

        // Then
        #expect(violations.count == expectedCount)
    }
}

// MARK: - Internal Method

extension ProjectionWriteBoundaryTests {

    /// 訂單端只傳遞開團唯讀引用，容器 backing storage 限於初始化時轉換
    ///
    /// - Parameters:
    ///   - relativePath: 相對於 App 原始碼根目錄的路徑
    ///   - source: 待掃描的原始碼內容
    /// - Returns: 寫入、外傳或重綁可寫開團引用的位置
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    static func sharedCampaignViolations(
        relativePath: String,
        source: String
    ) throws(any Error) -> [Violation] {
        guard relativePath.hasPrefix("Features/Orders/") else {
            return []
        }
        var mode = StripMode.normal
        let stripped = source.components(separatedBy: "\n")
            .map {
                stripCommentsAndStrings(from: $0, mode: &mode)
            }
            .joined(separator: "\n")
        let text = stripped as NSString
        let declaration = #"@SharedReader\s+var\s+campaigns\b"#
        let isReaderFile = relativePath != "Features/Orders/Presentation/Root/OrdersFeature.swift"
            && stripped.range(of: declaration, options: .regularExpression) != nil
        let referencePattern = relativePath == "Features/Orders/Presentation/Root/OrdersFeature.swift"
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
        let rootPattern = try rootProjectionWritePattern(rootKey: "orders", property: "campaigns")
        let rootWrites = rootPattern.matches(in: stripped, range: fullRange(of: stripped))
        let matches = references.matches(in: stripped, range: fullRange(of: stripped))
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
            let isWrite = writeSuffix.firstMatch(in: suffix, range: fullRange(of: suffix)) != nil
            let isStorage = text.substring(with: match.range).hasPrefix("_")
            let isReaderAllowed = try isInsideInitializer(prefix) || !isStorage
            let isReaderConversion = isReaderAllowed
                && readerPrefix.firstMatch(in: prefix, range: fullRange(of: prefix)) != nil
                && readerSuffix.firstMatch(in: suffix, range: fullRange(of: suffix)) != nil
            if !isWrite && (isReaderFile || isReaderConversion) {
                return nil
            }
            let line = prefix.components(separatedBy: "\n").count
            return Violation(file: relativePath, line: line, property: "開團可寫參考")
        }
    }
}

// MARK: - Private Method

private extension ProjectionWriteBoundaryTests {

    /// 唯讀投影的直接寫入、根路徑寫入、合法讀取與傳遞案例
    static var readerCampaignProjectionScenarios: [(String, Int)] {
        [
            ("state.$campaigns.withLock { $0 = [] }", 1),
            ("root.orders.$campaigns = replacement", 1),
            ("state.$campaigns = replacement", 1),
            ("state.$campaigns.wrappedValue = []", 1),
            ("root.orders.$campaigns.withLock { $0 = [] }", 1),
            ("root.orders.$campaigns.wrappedValue = []", 1),
            ("state.$campaigns\n    .wrappedValue\n    = []", 1),
            ("let snapshot = state.$campaigns.wrappedValue", 0),
            ("let isEmpty = state.$campaigns.wrappedValue == []", 0),
            ("OrderFilterFeature.State(campaigns: state.$campaigns)", 0),
            ("// state.$campaigns.withLock { $0 = [] }", 0),
            ("let example = \"state.$campaigns.wrappedValue = []\"", 0),
        ]
    }

    /// 以大括號範圍確認引用仍位於初始化方法內，保留巢狀 closure 的上下文
    ///
    /// - Parameter prefix: 已移除註解與字串的引用前原始碼
    /// - Returns: 引用是否位於尚未結束的初始化方法內
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    static func isInsideInitializer(_ prefix: String) throws(any Error) -> Bool {
        let pattern = try NSRegularExpression(pattern: #"(?<![\w.])init\s*\(|[{}]"#)
        var initializerScopes: [Bool] = []
        var isInitializer = false
        for match in pattern.matches(in: prefix, range: fullRange(of: prefix)) {
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
}
