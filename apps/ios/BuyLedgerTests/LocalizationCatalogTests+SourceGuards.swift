//
//  LocalizationCatalogTests+SourceGuards.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation
import Testing

extension LocalizationCatalogTests {

    /// 原始碼不得寫死正體中文地區，語系一律跟隨 App 內選擇的語言
    ///
    /// - Throws: 原始檔列舉或讀取失敗時丟出錯誤
    @Test
    func localeModifier_所有原始檔_不得寫死正體中文地區() throws(any Error) {
        // Given
        let sourceRoot = Self.iosRootURL.appending(path: "BuyLedger")
        let enumerator = try #require(
            FileManager.default.enumerator(at: sourceRoot, includingPropertiesForKeys: nil)
        )
        let swiftFiles = enumerator.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
        var hardCodedTraditionalChineseLocales: [String] = []

        // When
        for file in swiftFiles {
            let source = try String(contentsOf: file, encoding: .utf8)
            let relativePath = file.path.replacingOccurrences(of: sourceRoot.path + "/", with: "")

            if source.contains(".locale(Locale(identifier: \"zh_TW\"))") {
                hardCodedTraditionalChineseLocales.append(relativePath)
            }
        }

        // Then
        #expect(
            hardCodedTraditionalChineseLocales.isEmpty,
            "原始碼寫死語系：\(hardCodedTraditionalChineseLocales)"
        )
    }

    /// 禁止 pattern 掃描器會命中每個禁止的寫法，且不誤判不含禁止寫法的原始碼
    @Test
    func containsForbiddenNavigationTitlePattern_禁止寫法與乾淨原始碼_只命中禁止寫法() {
        // Given
        let forbiddenSources = [
            ".navigationTitle(\"Orders\")",
            ".navigationTitle(Text(\"Orders\"))",
            ".navigationTitle(Text(LocalizedStringKey(\"Orders\")))",
        ]
        let cleanSource = "Text(LocalizedStringKey(\"Orders\"))"

        // When
        let forbiddenHits = forbiddenSources.map {
            Self.containsForbiddenNavigationTitlePattern(in: $0)
        }
        let isCleanSourceFlagged = Self.containsForbiddenNavigationTitlePattern(in: cleanSource)

        // Then
        #expect(forbiddenHits == [true, true, true], "每個禁止的導覽標題寫法都應被掃描器命中")
        #expect(!isCleanSourceFlagged, "不含禁止寫法的原始碼不應被掃描器命中")
    }

    /// 根分頁畫面不得把本地化字面值直接交給原生 `navigationTitle`，要走明確語言的 modifier
    ///
    /// - Throws: 根畫面原始檔讀取失敗時丟出錯誤
    @Test
    func containsForbiddenNavigationTitlePattern_七個根畫面_不得以字面值呼叫原生標題() throws(any Error) {
        // Given
        let sourceRoot = Self.iosRootURL.appending(path: "BuyLedger")
        let rootViews = [
            "Features/Dashboard/Presentation/Root/Views/DashboardView.swift",
            "Features/Orders/Presentation/Root/Views/OrdersCompactView.swift",
            "Features/Orders/Presentation/Root/Views/OrdersView.swift",
            "Features/Campaigns/Presentation/CampaignList/Views/CampaignListView.swift",
            "Features/Insights/Presentation/Root/Views/InsightsView.swift",
            "Features/More/Presentation/Root/MoreView.swift",
            "Features/Settings/Presentation/Root/SettingsView.swift",
        ]
        var violatingViews: [String] = []

        // When
        for relativePath in rootViews {
            let sourceURL = sourceRoot.appending(path: relativePath)
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            if Self.containsForbiddenNavigationTitlePattern(in: source) {
                violatingViews.append(relativePath)
            }
        }

        // Then
        #expect(violatingViews.isEmpty, "根畫面不得將本地化字面值直接交給原生導覽標題：\(violatingViews)")
    }

    /// 分貨區段的收款狀態文字保留字串目錄的本地化邊界
    ///
    /// - Throws: 分貨區段原始檔讀取失敗時拋出錯誤
    @Test
    func campaignDetailDistributionSection_收款狀態文字_經字串目錄本地化() throws(any Error) {
        // Given
        let sourceURL = Self.iosRootURL
            .appending(path: "BuyLedger/Features/Campaigns/Presentation/CampaignDetail")
            .appending(path: "CampaignDetailDistributionSection.swift")

        // When
        let source = try String(contentsOf: sourceURL, encoding: .utf8)

        // Then
        #expect(
            source.contains("Text(LocalizedStringKey(order.paymentReceiptStatus.title))"),
            "開團詳情的收款狀態文字必須透過字串目錄本地化"
        )
    }

    /// 精簡訂單列表的篩選摘要不得拼接各自本地化的 `Text`
    ///
    /// - Throws: 精簡訂單畫面或拆出的清單內容原始檔讀取失敗時丟出錯誤
    @Test
    func filterSummary_精簡訂單列表_不拼接本地化文字() throws(any Error) {
        // Given
        let sourceRoot = Self.iosRootURL.appending(path: "BuyLedger")
        let sourcePaths = [
            "Features/Orders/Presentation/Root/Views/OrdersCompactView.swift",
            "Features/Orders/Presentation/OrderList/Views/OrdersCompactListView.swift",
        ]
        let forbiddenPattern = Self.normalizedWhitespace(
            "Text(\"篩選\") + Text(verbatim: \": \") + summary"
        )
        var violatingPaths: [String] = []

        // When
        for relativePath in sourcePaths {
            let sourceURL = sourceRoot.appending(path: relativePath)
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            if Self.normalizedWhitespace(source).contains(forbiddenPattern) {
                violatingPaths.append(relativePath)
            }
        }

        // Then
        #expect(violatingPaths.isEmpty, "篩選摘要不得拼接各自本地化的文字：\(violatingPaths)")
    }

    /// 原始碼不得在 View 內以加號拼接 Text 視圖
    ///
    /// - Throws: 原始檔列舉或讀取失敗時拋出錯誤
    @Test
    func textConcatenation_所有原始檔_不得以加號拼接Text() throws(any Error) {
        // Given
        let sourceRoot = Self.iosRootURL.appending(path: "BuyLedger")
        let enumerator = try #require(
            FileManager.default.enumerator(at: sourceRoot, includingPropertiesForKeys: nil)
        )
        let swiftFiles = enumerator.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
        var violatingFiles: [String] = []

        // When
        for file in swiftFiles {
            let relativePath = file.path.replacingOccurrences(of: sourceRoot.path + "/", with: "")
            guard !relativePath.contains("App/Testing/") else {
                continue
            }
            let source = try String(contentsOf: file, encoding: .utf8)
            if source.range(of: "Text\\([^)]*\\)[[:space:]]*\\+[[:space:]]*Text\\(", options: .regularExpression) != nil {
                violatingFiles.append(relativePath)
            }
        }

        // Then
        #expect(
            violatingFiles.isEmpty,
            "原始碼包含禁止的 Text 拼接反模式：\(violatingFiles)"
        )
    }
}
