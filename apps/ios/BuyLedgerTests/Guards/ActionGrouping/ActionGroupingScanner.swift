//
//  ActionGroupingScanner.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/23.
//

import Foundation
import Testing

/// 掃描 View 的 `store.send` 與 reducer 的子 Feature view action，供 action 分組守門使用
enum ActionGroupingScanner {

    // MARK: - Properties

    /// 已遷移且受 View action 規則掃描的檔案
    private static let migratedViewPaths = [
        "Features/FX/Presentation/Root/FxView.swift",
        "Features/Quote/Presentation/Root/QuoteView.swift",
        "Features/Settings/Presentation/Root/SettingsView.swift",
        "Features/AISummary/Presentation/Root/AISummaryView.swift",
        "Features/Customers/Presentation/Root/CustomersView.swift",
        "Features/Lookups/Presentation/Root/Views/LookupManagementView.swift",
        "Features/Campaigns/Presentation/Root/CampaignView.swift",
        "Features/Campaigns/Presentation/CampaignList/Views/CampaignListView.swift",
        "Features/Campaigns/Presentation/CampaignDetail/CampaignDetailView.swift",
        "Features/Campaigns/Presentation/CampaignEdit/CampaignEditView.swift",
        "Features/Orders/Presentation/OrderEdit/Views/OrderEditView.swift",
        "Features/Orders/Presentation/OrderEditPhotos/OrderEditPhotosSection.swift",
        "Features/Orders/Presentation/OrderEdit/Views/OrderEditSelectionRow.swift",
        "Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditBasicSection.swift",
        "Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditStatusSection.swift",
        "Features/Orders/Presentation/OrderEdit/Views/OrderEditDecimalField.swift",
        "Features/Orders/Presentation/OrderEdit/Views/OrderEditPercentField.swift",
        "Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditPaymentSection.swift",
        "Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditCostSection.swift",
        "Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditFeesSection.swift",
        "Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditCampaignSection.swift",
        "Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditItemsSection.swift",
        "Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditNotesSection.swift",
        "Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditOriginalSection.swift",
        "Features/Orders/Presentation/OrderEdit/Views/OrderEditPickerDestination.swift",
        "Features/Orders/Presentation/Root/Views/OrdersView.swift",
        "Features/Orders/Presentation/Root/Views/OrdersCompactView.swift",
        "Features/Orders/Presentation/Root/Views/OrdersRegularListColumn.swift",
        "Features/Orders/Presentation/Root/Views/OrdersRegularDetailColumn.swift",
        "Features/Orders/Presentation/OrderDetail/Views/OrderDetailView.swift",
        "Features/Orders/Presentation/OrderDetail/Views/OrderDetailContentView.swift",
        "Features/Orders/Presentation/OrderDetail/Views/OrderDetailCostView.swift",
        "Features/Orders/Presentation/OrderDetail/Views/OrderDetailItemsView.swift",
        "Features/Orders/Presentation/OrderDetail/Views/OrderDetailMenu.swift",
        "Features/Orders/Presentation/OrderDetail/Views/OrderDetailNotesView.swift",
        "Features/Orders/Presentation/OrderDetail/Views/OrderDetailSummaryView.swift",
        "Features/Orders/Presentation/OrderMerge/OrderMergeCandidateSheet.swift",
        "Features/Orders/Presentation/OrderMerge/MergePhotoPickerSheet.swift",
        "Features/Orders/Presentation/Root/Views/OrdersToolbarContent.swift",
        "Features/Orders/Presentation/OrderList/Views/OrderSelectableRow.swift",
        "Features/Orders/Presentation/Components/OrderRowView.swift",
        "Features/Orders/Presentation/Components/OrderDetailRowMenu.swift",
        "Features/Orders/Presentation/OrderFilter/Views/OrderFilterSheet.swift",
        "Features/Orders/Presentation/OrderList/Views/OrdersCompactListView.swift",
        "Features/Orders/Presentation/OrderFilter/Views/OrderFilterDateSection.swift",
        "Features/Orders/Presentation/OrderFilter/Views/OrderFilterPaymentMethodSection.swift",
        "Features/Orders/Presentation/OrderFilter/Views/OrderFilterCategorySection.swift",
        "Features/App/Presentation/Root/RootView.swift",
        "Features/App/Presentation/Root/RootTabLayout.swift",
        "Features/App/Presentation/Root/RootSidebarLayout.swift",
        "Features/App/Presentation/AppLock/AppLockView.swift",
        "Features/App/Presentation/PersistenceFailure/PersistenceFailureView.swift",
        "Features/More/Presentation/Root/MoreView.swift",
        "Features/Dashboard/Presentation/Root/Views/DashboardView.swift",
        "Features/Dashboard/Presentation/Root/Views/DashboardOngoingCampaignsSection.swift",
        "Features/Dashboard/Presentation/Root/Views/DashboardRecentOrdersSection.swift",
        "Features/Insights/Presentation/Root/Views/InsightsView.swift",
    ]

    /// 已遷移 View 的元件目錄
    private static let migratedComponentDirectories = [
        "Features/FX/Presentation/Root",
        "Features/Quote/Presentation/Root",
        "Features/Lookups/Presentation/Root",
        "Features/Campaigns/Presentation/CampaignList",
        "Features/Campaigns/Presentation/CampaignDetail",
        "Features/Campaigns/Presentation/CampaignEdit",
        "Features/Orders/Presentation",
    ]
}

// MARK: - Nested Types

extension ActionGroupingScanner {

    /// 一筆暫時性 action allowlist 條目
    struct AllowlistEntry: Sendable {

        /// 相對於 App source root 的檔案路徑
        let relativePath: String

        /// 送出內容必須完全相符的開頭
        let prefix: String

        /// 保留豁免的原因
        let reason: String

        /// 應移除豁免的實作步驟
        let removalStep: String

        /// 由檔案與送出前綴組成的穩定 allowlist key
        var key: String {
            "\(relativePath)|\(prefix)"
        }
    }

    /// 一個檔案或片段的掃描結果
    struct ScanResult: Sendable {

        /// 掃描到的違規
        let violations: [Violation]

        /// 已命中的 allowlist key
        let usedAllowlistKeys: Set<String>
    }

    /// 掃描命中的違規位置
    struct Violation: Sendable {

        /// 相對於 App source root 的檔案路徑
        let file: String

        /// 命中的程式碼或 allowlist 說明
        let detail: String
    }
}

// MARK: - Computed Properties

extension ActionGroupingScanner {

    /// 所有 Feature production source 的根目錄
    static var featuresRoot: URL {
        productionRoot.appending(path: "Features")
    }
}

// MARK: - Internal Method

extension ActionGroupingScanner {

    /// 掃描所有已遷移 View 的 `store.send` 呼叫
    ///
    /// - Parameter allowlist: 暫時性 action 豁免清單
    /// - Returns: 送出點與 allowlist 使用狀態
    /// - Throws: 原始檔讀取失敗時丟出錯誤
    static func scanMigratedViewFiles(allowlist: [AllowlistEntry]) throws -> ScanResult {
        var files = migratedViewPaths.map { productionRoot.appending(path: $0) }
        for directory in migratedComponentDirectories {
            files.append(
                contentsOf: try SwiftSourceFiles.swiftFiles(
                    under: productionRoot.appending(path: directory),
                    shouldIncludeGenerated: true
                )
            )
        }

        var violations: [Violation] = []
        var usedAllowlistKeys = Set<String>()
        let sortedFiles = Set(files).sorted { lhs, rhs in lhs.path < rhs.path }
        for file in sortedFiles {
            let source = try String(contentsOf: file, encoding: .utf8)
            let result = scanStoreSendContents(
                source,
                relativePath: SwiftSourceFiles.relativePath(of: file, under: productionRoot),
                allowlist: allowlist
            )
            violations.append(contentsOf: result.violations)
            usedAllowlistKeys.formUnion(result.usedAllowlistKeys)
        }

        violations.append(
            contentsOf: unusedAllowlistViolations(allowlist: allowlist, usedKeys: usedAllowlistKeys)
        )
        return ScanResult(violations: violations, usedAllowlistKeys: usedAllowlistKeys)
    }

    /// 掃描單一檔案或片段中的 View `store.send` 呼叫
    ///
    /// - Parameters:
    ///   - source: 要掃描的原始碼
    ///   - relativePath: 相對於 App source root 的路徑
    ///   - allowlist: 暫時性 action 豁免清單
    /// - Returns: 掃描結果，不含未使用 allowlist 的追加違規
    static func scanStoreSendContents(
        _ source: String,
        relativePath: String,
        allowlist: [AllowlistEntry]
    ) -> ScanResult {
        let stripped = stripCommentsAndStrings(from: source)
        var violations: [Violation] = []
        var usedAllowlistKeys = Set<String>()

        for match in stripped.matches(of: storeSendPattern) {
            let suffix = String(stripped[match.range.upperBound...])
            let entry = allowlist.first {
                $0.relativePath == relativePath && suffix.hasPrefix($0.prefix)
            }
            if let entry {
                usedAllowlistKeys.insert(entry.key)
                continue
            }

            guard suffix.firstMatch(of: viewActionPrefixPattern) == nil else {
                continue
            }
            violations.append(
                Violation(file: relativePath, detail: "View store.send 違規：\(snippet(suffix))")
            )
        }

        return ScanResult(violations: violations, usedAllowlistKeys: usedAllowlistKeys)
    }

    /// 找出 Features 內把子 Feature 的 view action 包在父 action 內的寫法
    ///
    /// - Parameter files: 要掃描的 production Swift 檔案
    /// - Returns: 子 Feature view action 違規清單
    /// - Throws: 原始檔讀取失敗時丟出錯誤
    static func reducerChildViewViolations(in files: [URL]) throws -> [Violation] {
        var violations: [Violation] = []
        for file in files {
            let source = try String(contentsOf: file, encoding: .utf8)
            violations.append(
                contentsOf: reducerChildViewViolations(
                    in: source,
                    relativePath: SwiftSourceFiles.relativePath(of: file, under: productionRoot)
                )
            )
        }
        return violations
    }

    /// 找出指定檔案內容中子 Feature 的 view action 違規
    ///
    /// - Parameters:
    ///   - source: 要掃描的原始碼
    ///   - relativePath: 相對於 App source root 的路徑
    /// - Returns: 子 Feature view action 違規清單
    static func reducerChildViewViolations(in source: String, relativePath: String) -> [Violation] {
        let stripped = stripCommentsAndStrings(from: source)
        return stripped.matches(of: reducerChildViewPattern).map { match in
            let detail = "reducer 子層 view action 違規：\(snippet(String(stripped[match.range])))"
            return Violation(file: relativePath, detail: detail)
        }
    }

    /// 找出未被任何送出點使用的 allowlist 條目
    ///
    /// - Parameters:
    ///   - allowlist: 暫時性 action 豁免清單
    ///   - usedKeys: 已命中的 allowlist key
    /// - Returns: 未使用條目的違規清單
    static func unusedAllowlistViolations(
        allowlist: [AllowlistEntry],
        usedKeys: Set<String>
    ) -> [Violation] {
        allowlist.compactMap { entry in
            guard !usedKeys.contains(entry.key) else {
                return nil
            }
            return Violation(
                file: entry.relativePath,
                detail: "未使用 allowlist：\(entry.prefix)，理由：\(entry.reason)，移除：\(entry.removalStep)"
            )
        }
    }

    /// 把掃描違規格式化為人可讀的條列訊息
    ///
    /// - Parameter violations: 違規清單
    /// - Returns: 違規說明
    static func describe(_ violations: [Violation]) -> String {
        guard !violations.isEmpty else {
            return "無"
        }
        return violations.map { "\($0.file) (\($0.detail))" }.joined(separator: "、")
    }
}

// MARK: - Private Method

private extension ActionGroupingScanner {

    /// 測試 target 所在的 iOS 平台目錄
    static var iosRoot: URL {
        TestPaths.iosRoot
    }

    /// App 正式程式碼的根目錄
    static var productionRoot: URL {
        iosRoot.appending(path: "BuyLedger")
    }

    /// View 送出 action 的掃描模式
    ///
    /// - Note: `Regex` 不是 `Sendable`，不能存成非隔離的 `static let`，改為每次取用時建立
    static var storeSendPattern: Regex<Substring> {
        #/\b(?:store|\w+Store)\s*\.\s*send\s*\(\s*/#
    }

    /// View action 必須以 `.view(` 開頭的掃描模式
    ///
    /// - Note: `Regex` 不是 `Sendable`，不能存成非隔離的 `static let`，改為每次取用時建立
    static var viewActionPrefixPattern: Regex<Substring> {
        #/^\.\s*view\s*\(/#
    }

    /// reducer 包裝子 Feature `.view(` 寫法的掃描模式
    ///
    /// - Note: `Regex` 不是 `Sendable`，不能存成非隔離的 `static let`，改為每次取用時建立
    static var reducerChildViewPattern: Regex<Substring> {
        #/\.\s*(?!send\b|view\b)[a-z]\w*\s*\(\s*\.\s*view\s*\(/#
    }

    /// 移除註解與字串字面值，保留程式碼空白與換行
    ///
    /// - Parameter source: 原始碼文字
    /// - Returns: 移除註解與字串後的程式碼文字
    static func stripCommentsAndStrings(from source: String) -> String {
        let stringPattern = #/"""[\s\S]*?"""|"([^"\\]|\\.)*"/#
        let commentPattern = #/\/\/[^\r\n]*|\/\*[\s\S]*?\*\//#
        return source
            .replacing(stringPattern, with: "")
            .replacing(commentPattern, with: "")
    }

    /// 把命中內容壓成適合錯誤訊息的一行
    ///
    /// - Parameter text: 命中後的原始文字
    /// - Returns: 可讀的短片段
    static func snippet(_ text: String) -> String {
        let normalized = text
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
        return String(normalized.prefix(96))
    }
}
