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
    func navigationTitle_七個根畫面_不得以字面值呼叫原生標題() throws(any Error) {
        // Given
        let sourceRoot = Self.iosRootURL.appending(path: "BuyLedger")
        let rootViews = [
            "Features/Dashboard/DashboardView.swift",
            "Features/Orders/OrdersCompactView.swift",
            "Features/Orders/OrdersView.swift",
            "Features/Campaigns/CampaignListView.swift",
            "Features/Insights/InsightsView.swift",
            "Features/More/MoreView.swift",
            "Features/Settings/SettingsView.swift",
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
            .appending(path: "BuyLedger/Features/Campaigns/Components")
            .appending(path: "CampaignDetailDistributionSection.swift")

        // When
        let source = try String(contentsOf: sourceURL, encoding: .utf8)

        // Then
        #expect(
            source.contains("Text(LocalizedStringKey(order.paymentReceiptStatus.title))"),
            "開團詳情的收款狀態文字必須透過字串目錄本地化"
        )
    }

    /// 側邊欄智慧分組列的朗讀文字不得拼接各自本地化的 `Text`
    ///
    /// - Throws: 側邊欄原始檔讀取失敗時丟出錯誤
    @Test
    func smartGroupRow_側邊欄朗讀文字_不拼接本地化文字() throws(any Error) {
        // Given
        let sourceURL = Self.iosRootURL
            .appending(path: "BuyLedger/Features/App/RootSidebarLayout.swift")
        let forbiddenPattern = Self.normalizedWhitespace(
            "Text(LocalizedStringKey(group.status.title)) + Text(\" \\(count) 件\")"
        )

        // When
        let source = try String(contentsOf: sourceURL, encoding: .utf8)
        let normalizedSource = Self.normalizedWhitespace(source)

        // Then
        #expect(!normalizedSource.contains(forbiddenPattern), "朗讀文字不得拼接各自本地化的文字")
    }

    /// 精簡訂單列表的篩選摘要不得拼接各自本地化的 `Text`
    ///
    /// - Throws: 精簡訂單畫面原始檔讀取失敗時丟出錯誤
    @Test
    func filterSummary_精簡訂單列表_不拼接本地化文字() throws(any Error) {
        // Given
        let sourceURL = Self.iosRootURL
            .appending(path: "BuyLedger/Features/Orders/OrdersCompactView.swift")
        let forbiddenPattern = Self.normalizedWhitespace(
            "Text(\"篩選\") + Text(verbatim: \": \") + summary"
        )

        // When
        let source = try String(contentsOf: sourceURL, encoding: .utf8)
        let normalizedSource = Self.normalizedWhitespace(source)

        // Then
        #expect(!normalizedSource.contains(forbiddenPattern), "篩選摘要不得拼接各自本地化的文字")
    }
}
