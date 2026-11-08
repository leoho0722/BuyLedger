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
        let sourceRoot = TestPaths.iosRoot.appending(path: "BuyLedger")
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

    /// 驗證正式程式碼不呼叫舊本地化 API，且動態 `LocalizedStringKey` 只能使用字面值
    ///
    /// - Throws: 原始檔列舉或讀取失敗時丟出錯誤
    @Test
    func localizationSourceRules_所有原始檔_不得使用舊API或動態LocalizedStringKey() throws {
        // Given
        let sourceRoot = TestPaths.iosRoot.appending(path: "BuyLedger")
        let enumerator = try #require(
            FileManager.default.enumerator(at: sourceRoot, includingPropertiesForKeys: nil)
        )
        let swiftFiles = enumerator.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
        var violatingFiles: [String] = []

        // When
        for file in swiftFiles {
            let relativePath = file.path.replacingOccurrences(of: sourceRoot.path + "/", with: "")
            let source = try String(contentsOf: file, encoding: .utf8)
            let violations = LocalizationSourceScanner.violations(
                in: source,
                relativePath: relativePath
            )
            if !violations.isEmpty {
                violatingFiles.append("\(relativePath): \(violations)")
            }
        }

        // Then
        #expect(!swiftFiles.isEmpty, "必須掃描到 apps/ios/BuyLedger 下的 Swift 原始檔")
        #expect(violatingFiles.isEmpty, "本地化原始碼違規：\(violatingFiles)")
    }

    /// 驗證本地化原始碼守門在禁止樣本上失敗，字面值與允許入口不誤判
    ///
    /// - Parameter scenario: 原始碼樣本、路徑與是否預期違規
    @Test(arguments: [
        ForbiddenSourceCase(
            source: "AppLanguage.format(\"orders.list.title\", locale: .current)",
            relativePath: "Features/Orders/OrderFormatters.swift",
            shouldViolate: true
        ),
        ForbiddenSourceCase(
            source: "String(localized: \"orders.list.title\")",
            relativePath: "Features/Orders/OrderFormatters.swift",
            shouldViolate: true
        ),
        ForbiddenSourceCase(
            source: "localizedString(forKey: \"orders.list.title\")",
            relativePath: "Features/Orders/OrderFormatters.swift",
            shouldViolate: true
        ),
        ForbiddenSourceCase(
            source: "extractKeyAndArgs(key)",
            relativePath: "Features/Orders/OrderFormatters.swift",
            shouldViolate: true
        ),
        ForbiddenSourceCase(
            source: "let key: String.LocalizationValue",
            relativePath: "Features/Orders/OrderFormatters.swift",
            shouldViolate: true
        ),
        ForbiddenSourceCase(
            source: "LocalizedStringKey(title)",
            relativePath: "Features/Orders/OrderFormatters.swift",
            shouldViolate: true
        ),
        ForbiddenSourceCase(
            source: "LocalizedStringKey(\n    title\n)",
            relativePath: "Features/Orders/OrderFormatters.swift",
            shouldViolate: true
        ),
        ForbiddenSourceCase(
            source: "LocalizedStringKey(\"a\" + suffix)",
            relativePath: "Features/Orders/OrderFormatters.swift",
            shouldViolate: true
        ),
        ForbiddenSourceCase(
            source: "LocalizedStringKey (title)",
            relativePath: "Features/Orders/OrderFormatters.swift",
            shouldViolate: true
        ),
        ForbiddenSourceCase(
            source: "LocalizedStringKey.init(title)",
            relativePath: "Features/Orders/OrderFormatters.swift",
            shouldViolate: true
        ),
        ForbiddenSourceCase(
            source: "LocalizedStringKey .init (title)",
            relativePath: "Features/Orders/OrderFormatters.swift",
            shouldViolate: true
        ),
        ForbiddenSourceCase(
            source: "LocalizedStringKey.init(\n    title\n)",
            relativePath: "Features/Orders/OrderFormatters.swift",
            shouldViolate: true
        ),
        ForbiddenSourceCase(
            source: "LocalizedStringKey(\"orders.list.title\")",
            relativePath: "Features/Orders/OrderFormatters.swift",
            shouldViolate: false
        ),
        ForbiddenSourceCase(
            source: "LocalizedStringKey.init(\"orders.list.label.merged\")",
            relativePath: "Features/Orders/OrderFormatters.swift",
            shouldViolate: false
        ),
        ForbiddenSourceCase(
            source: "String(localized: resource)\nlocalizedString(forKey: \"key\")",
            relativePath: "Shared/Localization/AppLanguage.swift",
            shouldViolate: false
        ),
        ForbiddenSourceCase(
            source: "// AppLanguage.format(\"orders.list.title\")",
            relativePath: "Features/Orders/OrderFormatters.swift",
            shouldViolate: false
        ),
    ])
    func localizationSourceRules_合成原始碼樣本_命中禁止寫法(scenario: ForbiddenSourceCase) {
        // Given
        let source = scenario.source

        // When
        let violations = LocalizationSourceScanner.violations(
            in: source,
            relativePath: scenario.relativePath
        )

        // Then
        #expect(!violations.isEmpty == scenario.shouldViolate)
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
        let sourceRoot = TestPaths.iosRoot.appending(path: "BuyLedger")
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

    /// 驗證開團詳情分貨區段的收款狀態文字以 `LocalizedStringResource` 直接交給 `Text`，由字串目錄本地化
    ///
    /// - Throws: 分貨區段或收款狀態原始檔讀取失敗時丟出錯誤
    @Test
    func campaignDetailDistributionSection_收款狀態文字_經字串目錄本地化() throws {
        // Given
        let iosRoot = TestPaths.iosRoot
        let sectionURL = iosRoot
            .appending(path: "BuyLedger/Features/Campaigns/Presentation/CampaignDetail")
            .appending(path: "CampaignDetailDistributionSection.swift")
        let statusURL = iosRoot.appending(path: "BuyLedger/Core/Domain/PaymentReceiptStatus.swift")

        // When
        let sectionSource = try String(contentsOf: sectionURL, encoding: .utf8)
        let statusSource = try String(contentsOf: statusURL, encoding: .utf8)

        // Then
        #expect(
            sectionSource.contains("Text(order.paymentReceiptStatus.title)"),
            "開團詳情的收款狀態文字必須直接以 resource 交給 Text"
        )
        #expect(
            !sectionSource.contains("LocalizedStringKey(order.paymentReceiptStatus.title)"),
            "開團詳情的收款狀態文字不得以 String 包 LocalizedStringKey"
        )
        #expect(
            statusSource.contains("var title: LocalizedStringResource"),
            "收款狀態的標題必須以 LocalizedStringResource 攜帶 key"
        )
    }

    /// 驗證精簡訂單列表的篩選摘要不拼接各自本地化的 `Text`
    ///
    /// - Throws: 精簡訂單畫面或拆出的清單內容原始檔讀取失敗時丟出錯誤
    @Test
    func filterSummary_精簡訂單列表_不拼接本地化文字() throws {
        // Given
        let sourceRoot = TestPaths.iosRoot.appending(path: "BuyLedger")
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
        let sourceRoot = TestPaths.iosRoot.appending(path: "BuyLedger")
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

    /// 本地化原始碼守門的合成案例
    struct ForbiddenSourceCase: Sendable {

        /// 要掃描的原始碼片段
        let source: String

        /// 模擬的相對檔案路徑
        let relativePath: String

        /// 是否預期違反本地化規則
        let shouldViolate: Bool
    }

    /// 本地化原始碼的禁用寫法掃描
    private enum LocalizationSourceScanner {

        /// 回傳原始碼中所有違反本地化入口或 key 傳遞規則的寫法
        ///
        /// - Parameters:
        ///   - source: 要掃描的 Swift 原始碼
        ///   - relativePath: 相對於 BuyLedger 根目錄的檔案路徑
        /// - Returns: 違反規則的描述；沒有違規時為空陣列
        static func violations(in source: String, relativePath: String) -> [String] {
            let source = source
                .components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
                .joined(separator: "\n")
            var violations: [String] = []

            if relativePath != "Shared/Localization/AppLanguage.swift" {
                if source.contains("String(localized:") {
                    violations.append("String(localized:")
                }
                if source.contains("localizedString(forKey:") {
                    violations.append("localizedString(forKey:")
                }
            }
            if source.contains("AppLanguage.format") {
                violations.append("AppLanguage.format")
            }
            if source.contains("extractKeyAndArgs") {
                violations.append("extractKeyAndArgs")
            }
            if source.contains("String.LocalizationValue") {
                violations.append("String.LocalizationValue")
            }
            if hasNonLiteralLocalizedStringKey(in: source) {
                violations.append("LocalizedStringKey(non-literal)")
            }
            return violations
        }

        /// 檢查 `LocalizedStringKey` 呼叫 (含 `.init` 寫法) 是否只接一個完整字串字面值
        ///
        /// - Parameter source: 已移除整行註解的 Swift 原始碼
        /// - Returns: 呼叫未接字串字面值或字面值後還有運算式時為 `true`
        private static func hasNonLiteralLocalizedStringKey(in source: String) -> Bool {
            var searchStart = source.startIndex
            while let nameRange = source.range(
                of: "LocalizedStringKey",
                range: searchStart..<source.endIndex
            ) {
                searchStart = nameRange.upperBound
                let previousCharacter = nameRange.lowerBound > source.startIndex
                    ? source[source.index(before: nameRange.lowerBound)]
                    : nil
                let nextCharacter = nameRange.upperBound < source.endIndex
                    ? source[nameRange.upperBound]
                    : nil
                guard previousCharacter.map(isIdentifierCharacter) != true,
                      nextCharacter.map(isIdentifierCharacter) != true else {
                    continue
                }

                guard let openingParen = openingParenthesis(
                    in: source,
                    afterTypeName: nameRange.upperBound
                ) else {
                    continue
                }

                let argumentStart = skipTrivia(
                    in: source,
                    startingAt: source.index(after: openingParen)
                )
                guard argumentStart < source.endIndex, source[argumentStart] == "\"" else {
                    return true
                }

                var stringIndex = source.index(after: argumentStart)
                var closingQuote: String.Index?
                while stringIndex < source.endIndex {
                    if source[stringIndex] == "\\" {
                        let escapedIndex = source.index(after: stringIndex)
                        guard escapedIndex < source.endIndex else {
                            return true
                        }
                        if source[escapedIndex] == "(" {
                            return true
                        }
                        stringIndex = source.index(after: escapedIndex)
                    } else if source[stringIndex] == "\"" {
                        closingQuote = stringIndex
                        break
                    } else {
                        stringIndex = source.index(after: stringIndex)
                    }
                }

                guard let closingQuote else {
                    return true
                }
                let trailingToken = skipTrivia(
                    in: source,
                    startingAt: source.index(after: closingQuote)
                )
                guard trailingToken < source.endIndex,
                      source[trailingToken] == ")" || source[trailingToken] == "," else {
                    return true
                }
            }
            return false
        }

        /// 找出 `LocalizedStringKey` 之後的呼叫開括號，支援 `LocalizedStringKey(` 與 `.init(` 兩種寫法
        ///
        /// - Parameters:
        ///   - source: 已移除整行註解的 Swift 原始碼
        ///   - afterTypeName: 型別名稱結束的位置
        /// - Returns: 開括號的位置；型別名稱之後不是呼叫時為 `nil`
        private static func openingParenthesis(
            in source: String,
            afterTypeName: String.Index
        ) -> String.Index? {
            var index = skipTrivia(in: source, startingAt: afterTypeName)
            if index < source.endIndex, source[index] == "." {
                index = skipTrivia(in: source, startingAt: source.index(after: index))
                guard source[index...].hasPrefix("init") else {
                    return nil
                }
                index = source.index(index, offsetBy: "init".count)
                if index < source.endIndex, isIdentifierCharacter(source[index]) {
                    return nil
                }
                index = skipTrivia(in: source, startingAt: index)
            }
            guard index < source.endIndex, source[index] == "(" else {
                return nil
            }
            return index
        }

        /// 判斷字元是否可出現在 Swift 識別字中
        ///
        /// - Parameter character: 要檢查的字元
        /// - Returns: 字元屬於字母、數字或底線時為 `true`
        private static func isIdentifierCharacter(_ character: Character) -> Bool {
            character.isLetter || character.isNumber || character == "_"
        }

        /// 略過空白與註解，找到下一個 Swift token
        ///
        /// - Parameters:
        ///   - source: 要讀取的 Swift 原始碼
        ///   - startingAt: 開始略過的位置
        /// - Returns: 第一個非空白或註解的位置；沒有時為原始碼結尾
        private static func skipTrivia(
            in source: String,
            startingAt start: String.Index
        ) -> String.Index {
            var index = start
            while index < source.endIndex {
                if source[index].isWhitespace {
                    index = source.index(after: index)
                    continue
                }

                let nextIndex = source.index(after: index)
                guard source[index] == "/", nextIndex < source.endIndex else {
                    break
                }
                if source[nextIndex] == "/" {
                    index = source.index(after: nextIndex)
                    while index < source.endIndex,
                          source[index] != "\n",
                          source[index] != "\r" {
                        index = source.index(after: index)
                    }
                } else if source[nextIndex] == "*" {
                    index = source.index(after: nextIndex)
                    var nestingLevel = 1
                    while index < source.endIndex, nestingLevel > 0 {
                        let commentNextIndex = source.index(after: index)
                        if source[index] == "/",
                           commentNextIndex < source.endIndex,
                           source[commentNextIndex] == "*" {
                            nestingLevel += 1
                            index = source.index(after: commentNextIndex)
                        } else if source[index] == "*",
                                  commentNextIndex < source.endIndex,
                                  source[commentNextIndex] == "/" {
                            nestingLevel -= 1
                            index = source.index(after: commentNextIndex)
                        } else {
                            index = commentNextIndex
                        }
                    }
                } else {
                    break
                }
            }
            return index
        }
    }
}
