//
//  LocalizationCatalogSourceGuardsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation
import Testing

/// 本地化原始碼規範的單元測試，以掃描原始碼守住語言、標題與本地化文字規範
struct LocalizationCatalogSourceGuardsTests {

    /// 驗證原始碼沒有寫死 `zh_TW` 語系，語系一律跟隨 App 內選擇的語言
    ///
    /// - Throws: 原始檔列舉或讀取失敗時丟出錯誤
    @Test
    func localeModifier_所有原始檔_不得寫死正體中文地區() throws {
        // Given
        let sourceRoot = LocalizationCatalogLiteralScan.iosRootURL.appending(path: "BuyLedger")
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

    /// 驗證禁止寫法掃描器命中每個禁止的寫法，且不誤判不含禁止寫法的原始碼
    ///
    /// - Parameter scenario: 原始碼片段與是否應命中的固定預期
    @Test(arguments: [
        SourceCase(source: ".navigationTitle(\"Orders\")", shouldMatch: true),
        SourceCase(source: ".navigationTitle(Text(\"Orders\"))", shouldMatch: true),
        SourceCase(
            source: ".navigationTitle(Text(LocalizedStringKey(\"Orders\")))",
            shouldMatch: true
        ),
        SourceCase(source: "Text(LocalizedStringKey(\"Orders\"))", shouldMatch: false),
    ])
    func containsForbiddenNavigationTitlePattern_禁止寫法與乾淨原始碼_只命中禁止寫法(scenario: SourceCase) {
        // Given
        let source = scenario.source

        // When
        let isMatched = LocalizationCatalogLiteralScan
            .containsForbiddenNavigationTitlePattern(in: source)

        // Then
        #expect(isMatched == scenario.shouldMatch, "禁止的導覽標題寫法應命中，其他寫法不應誤判")
    }

    /// 驗證七個根畫面沒有把本地化字面值直接交給原生 `navigationTitle`，該寫法不會隨 App 內語言切換重新解析
    ///
    /// - Throws: 根畫面原始檔讀取失敗時丟出錯誤
    @Test
    func containsForbiddenNavigationTitlePattern_七個根畫面_不得以字面值呼叫原生標題() throws {
        // Given
        let sourceRoot = LocalizationCatalogLiteralScan.iosRootURL.appending(path: "BuyLedger")
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
            if LocalizationCatalogLiteralScan.containsForbiddenNavigationTitlePattern(in: source) {
                violatingViews.append(relativePath)
            }
        }

        // Then
        #expect(violatingViews.isEmpty, "根畫面不得將本地化字面值直接交給原生導覽標題：\(violatingViews)")
    }

    /// 驗證開團詳情分貨區段的收款狀態文字以 `LocalizedStringKey` 交給字串目錄本地化
    ///
    /// - Throws: 分貨區段原始檔讀取失敗時丟出錯誤
    @Test
    func campaignDetailDistributionSection_收款狀態文字_經字串目錄本地化() throws {
        // Given
        let sourceURL = LocalizationCatalogLiteralScan.iosRootURL
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

    /// 驗證精簡訂單列表的篩選摘要不拼接各自本地化的 `Text`
    ///
    /// - Throws: 精簡訂單畫面或拆出的清單內容原始檔讀取失敗時丟出錯誤
    @Test
    func filterSummary_精簡訂單列表_不拼接本地化文字() throws {
        // Given
        let sourceRoot = LocalizationCatalogLiteralScan.iosRootURL.appending(path: "BuyLedger")
        let sourcePaths = [
            "Features/Orders/Presentation/Root/Views/OrdersCompactView.swift",
            "Features/Orders/Presentation/OrderList/Views/OrdersCompactListView.swift",
        ]
        let forbiddenPattern = LocalizationCatalogLiteralScan.normalizedWhitespace(
            "Text(\"篩選\") + Text(verbatim: \": \") + summary"
        )
        var violatingPaths: [String] = []

        // When
        for relativePath in sourcePaths {
            let sourceURL = sourceRoot.appending(path: relativePath)
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            if LocalizationCatalogLiteralScan.normalizedWhitespace(source).contains(
                forbiddenPattern
            ) {
                violatingPaths.append(relativePath)
            }
        }

        // Then
        #expect(violatingPaths.isEmpty, "篩選摘要不得拼接各自本地化的文字：\(violatingPaths)")
    }

    /// 驗證原始碼不在 View 內以加號拼接 `Text` 視圖
    ///
    /// - Throws: 原始檔列舉或讀取失敗時丟出錯誤
    @Test
    func textConcatenation_所有原始檔_不得以加號拼接Text() throws {
        // Given
        let sourceRoot = LocalizationCatalogLiteralScan.iosRootURL.appending(path: "BuyLedger")
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
            if source.range(
                of: "Text\\([^)]*\\)[[:space:]]*\\+[[:space:]]*Text\\(",
                options: .regularExpression
            ) != nil {
                violatingFiles.append(relativePath)
            }
        }

        // Then
        #expect(violatingFiles.isEmpty, "原始碼包含禁止的 Text 拼接反模式：\(violatingFiles)")
    }
}

// MARK: - Nested Types

extension LocalizationCatalogSourceGuardsTests {

    /// 導覽標題原始碼的正反測試案例
    struct SourceCase: Sendable {

        /// 要掃描的原始碼片段
        let source: String

        /// 是否預期命中禁止寫法
        let shouldMatch: Bool
    }
}
