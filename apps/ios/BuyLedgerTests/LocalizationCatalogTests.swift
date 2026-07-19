//
//  LocalizationCatalogTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/17.
//

import Foundation
import Testing
@testable import BuyLedger

struct LocalizationCatalogTests {

    // MARK: - Tests

    @Test func catalogContainsCompleteTraditionalChineseAndEnglishValues() throws {
        let catalogURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "BuyLedger/Resources/Localizable.xcstrings")
        let data = try Data(contentsOf: catalogURL)
        let root = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let sourceLanguage = try #require(root["sourceLanguage"] as? String)
        let strings = try #require(root["strings"] as? [String: Any])

        #expect(sourceLanguage == "zh-Hant")
        #expect(!strings.isEmpty)

        let requiredProgrammaticKeys = [
            "自動", "淺色", "深色",
            "報價中", "已確認", "已下單", "集運中", "部分到貨", "已到貨", "已交付", "已取貨", "已取消", "已合併",
            "待收款", "已收款", "新客", "常客", "VIP", "開團中", "已收單",
            "按日分組", "按月分組", "按年分組",
            "全部時間", "本週", "本月", "上月",
            "30 天", "6 個月", "12 個月", "30 天淨獲利", "6 個月淨獲利", "12 個月淨獲利",
            "訂單來源管理", "商品類別管理", "付款方式管理", "對帳狀態管理",
            "管理訂單可選的訂單來源清單。", "管理訂單可選的商品類別清單。", "管理訂單可選的付款方式清單。", "管理訂單可選的對帳狀態清單。",
            "新增來源", "新增類別", "新增付款方式", "新增對帳狀態",
            "尚無來源", "尚無類別", "尚無付款方式", "尚無對帳狀態",
            "透過上方「新增來源」加入第一個訂單來源；訂單編輯時也能新增。",
            "透過上方「新增類別」加入第一個類別；訂單編輯時也能新增。",
            "透過上方「新增付款方式」加入第一個項目；訂單編輯時也能新增。",
            "透過上方「新增對帳狀態」加入第一個對帳狀態；訂單編輯時也能新增。",
            "新增訂單來源", "新增商品類別", "來源名稱", "類別名稱", "對帳狀態名稱",
            "輸入新的訂單來源名稱；不會自動套用到任何既有訂單。",
            "輸入新的商品類別名稱；不會自動套用到任何既有訂單。",
            "輸入新的付款方式名稱；不會自動套用到任何既有訂單。",
            "輸入新的對帳狀態名稱；不會自動套用到任何既有訂單。",
            "無卡", "銀行匯款", "貨到付款",
            "— 無對照", "基準幣別", "尚未連線", "請稍後再試。",
            "搜尋客戶、單號或商品", "返回",
            "商品定價", "當地運費", "國際運費", "刷卡手續費", "金流手續費", "平台手續費", "目標毛利", "商品金額", "TWD/件",
            "重新命名訂單來源", "重新命名商品類別", "重新命名付款方式", "重新命名對帳狀態",
            " %lld 件",
            "即時連線 ExchangeRate-API，將外幣換算為 TWD。",
            "依名稱整理客戶活躍度，快速跳轉到對應訂單。",
            "輸入成本與費率，即時看到建議售價與毛利。"
        ]
        let missingProgrammaticKeys = requiredProgrammaticKeys.filter { strings[$0] == nil }
        #expect(missingProgrammaticKeys.isEmpty, "缺少由程式組成的顯示字串：\(missingProgrammaticKeys)")

        let requiredEnglishValues = [
            "總覽": "Overview",
            "訂單": "Orders",
            "全部": "All",
            "營業額": "Revenue",
            "成本": "Cost",
            "進行中訂單": "Active Orders",
            "更多": "More",
            "選擇來源幣別": "Select Source Currency",
            "選擇預設幣別": "Select Default Currency",
            "選擇 AI 模型": "Select AI Model",
            "收款進度": "Payment Progress",
            "到貨進度": "Arrival Progress",
            "待收款": "Pending",
            "已收款": "Received",
            "到貨": "Arrived",
            "收款": "Payment",
            "今天": "Today",
            "昨天": "Yesterday",
            "選擇來源": "Select Source",
            "選擇類別": "Select Categories",
            "選擇訂單來源": "Select Order Source",
            "輸入新的訂單來源名稱，加入後會立即套用至此訂單。": "Enter a new order source name. It will be applied to this order immediately.",
            "選擇商品類別": "Category",
            "輸入新的商品類別名稱，加入後會立即套用至此訂單。": "Enter a new product category name. It will be applied to this order immediately.",
            "選擇付款方式": "Select Payment Method",
        ]
        for (key, expectedEnglishValue) in requiredEnglishValues {
            let entry = try #require(strings[key] as? [String: Any], "缺少實機回報的 key：\(key)")
            let localizations = try #require(entry["localizations"] as? [String: Any])
            let english = try #require(localizations["en"] as? [String: Any])
            let stringUnit = try #require(english["stringUnit"] as? [String: Any])
            let value = try #require(stringUnit["value"] as? String)
            #expect(value == expectedEnglishValue)
        }

        let allowedSameSourceAndEnglishValues: Set<String> = ["VIP"]
        let untranslatedChineseKeys = strings.compactMap { key, value -> String? in
            guard key.range(of: "[\\u{3400}-\\u{9FFF}]", options: .regularExpression) != nil,
                  let entry = value as? [String: Any],
                  entry["shouldTranslate"] as? Bool != false,
                  let localizations = entry["localizations"] as? [String: Any],
                  let traditionalChinese = localizations["zh-Hant"] as? [String: Any],
                  let traditionalChineseUnit = traditionalChinese["stringUnit"] as? [String: Any],
                  let traditionalChineseValue = traditionalChineseUnit["value"] as? String,
                  let english = localizations["en"] as? [String: Any],
                  let englishUnit = english["stringUnit"] as? [String: Any],
                  let englishValue = englishUnit["value"] as? String,
                  traditionalChineseValue == englishValue,
                  !allowedSameSourceAndEnglishValues.contains(key) else {
                return nil
            }
            return key
        }
        #expect(untranslatedChineseKeys.isEmpty, "English translation 仍與中文 source 相同：\(untranslatedChineseKeys)")

        for (key, value) in strings {
            let entry = try #require(value as? [String: Any], "\(key) 缺少 catalog entry")
            if entry["shouldTranslate"] as? Bool == false {
                continue
            }
            let localizations = try #require(
                entry["localizations"] as? [String: Any],
                "\(key) 缺少 localizations"
            )

            for language in ["zh-Hant", "en"] {
                let localization = try #require(
                    localizations[language] as? [String: Any],
                    "\(key) 缺少 \(language) localization"
                )
                let stringUnit = try #require(
                    localization["stringUnit"] as? [String: Any],
                    "\(key) 缺少 \(language) stringUnit"
                )
                let translatedValue = try #require(
                    stringUnit["value"] as? String,
                    "\(key) 缺少 \(language) value"
                )

                #expect(!translatedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    @Test func calendarPermissionDescriptionIsLocalized() throws {
        let catalogURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "BuyLedger/Resources/InfoPlist.xcstrings")
        let data = try Data(contentsOf: catalogURL)
        let root = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try #require(root["strings"] as? [String: Any])
        let entry = try #require(strings["NSCalendarsFullAccessUsageDescription"] as? [String: Any])
        let localizations = try #require(entry["localizations"] as? [String: Any])

        for language in ["zh-Hant", "en"] {
            let localization = try #require(localizations[language] as? [String: Any])
            let stringUnit = try #require(localization["stringUnit"] as? [String: Any])
            let value = try #require(stringUnit["value"] as? String)
            #expect(!value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    @Test func presentationBoundariesDoNotBypassSelectedAppLocale() throws {
        let sourceRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "BuyLedger")
        let enumerator = try #require(
            FileManager.default.enumerator(
                at: sourceRoot,
                includingPropertiesForKeys: nil
            )
        )
        let swiftFiles = enumerator.compactMap { $0 as? URL }.filter { $0.pathExtension == "swift" }
        var hardCodedTraditionalChineseLocales: [String] = []

        for file in swiftFiles {
            let source = try String(contentsOf: file, encoding: .utf8)
            let relativePath = file.path.replacingOccurrences(of: sourceRoot.path + "/", with: "")

            if source.contains(".locale(Locale(identifier: \"zh_TW\"))") {
                hardCodedTraditionalChineseLocales.append(relativePath)
            }
        }

        #expect(
            hardCodedTraditionalChineseLocales.isEmpty,
            "Presentation formatters must use the selected App locale: \(hardCodedTraditionalChineseLocales)"
        )
    }

    @Test func rootNavigationTitlesResolveUsingTheSelectedAppLanguage() {
        #expect(AppLanguage.english.localized("總覽") == "Overview")
        #expect(AppLanguage.traditionalChinese.localized("總覽") == "總覽")
        #expect(AppLanguage.english.localized("訂單") == "Orders")
        #expect(AppLanguage.traditionalChinese.localized("訂單") == "訂單")
        #expect(AppLanguage.english.localized("開團") == "Campaigns")
        #expect(AppLanguage.traditionalChinese.localized("開團") == "開團")
        #expect(AppLanguage.english.localized("分析") == "Insights")
        #expect(AppLanguage.traditionalChinese.localized("分析") == "分析")
        #expect(AppLanguage.english.localized("更多") == "More")
        #expect(AppLanguage.traditionalChinese.localized("更多") == "更多")
    }

    @Test func ordersNavigationTitleKeysFollowSelectionState() {
        var state = OrdersFeature.State()

        #expect(AppLanguage.english.localized(state.navigationTitleKey) == "Orders")
        #expect(AppLanguage.traditionalChinese.localized(state.navigationTitleKey) == "訂單")

        state.isSelecting = true

        #expect(AppLanguage.english.localized(state.navigationTitleKey) == "Select Orders")
        #expect(AppLanguage.traditionalChinese.localized(state.navigationTitleKey) == "選擇訂單")

        state.selectedOrderIDs = ["O1", "O2"]

        #expect(AppLanguage.english.localized(state.navigationTitleKey) == "2 Selected")
        #expect(AppLanguage.traditionalChinese.localized(state.navigationTitleKey) == "已選 2 筆")
    }

    @Test func rootNavigationTitlesUseTheExplicitLanguageModifier() throws {
        let sourceRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "BuyLedger")
        let rootViews = [
            "Features/Dashboard/DashboardView.swift",
            "Features/Orders/OrdersCompactView.swift",
            "Features/Orders/OrdersView.swift",
            "Features/Campaigns/CampaignListView.swift",
            "Features/Insights/InsightsView.swift",
            "Features/More/MoreView.swift",
            "Features/Settings/SettingsView.swift",
        ]

        for relativePath in rootViews {
            let source = try String(contentsOf: sourceRoot.appending(path: relativePath), encoding: .utf8)
            #expect(
                !source.contains(".navigationTitle(\"")
                    && !source.contains(".navigationTitle(Text(\"")
                    && !source.contains(".navigationTitle(Text(LocalizedStringKey("),
                "\(relativePath) must not pass localized literals to native navigationTitle."
            )
        }
    }

    @Test func campaignDetailReceiptStatusesCrossLocalizationBoundary() throws {
        let sourceURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "BuyLedger/Features/Campaigns/CampaignDetailView.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)

        #expect(
            source.contains("Text(LocalizedStringKey(order.paymentReceiptStatus.title))"),
            "Campaign detail receipt statuses must be resolved through the String Catalog."
        )
    }

    @Test func sidebarSmartGroupAccessibilityDoesNotConcatenateLocalizedText() throws {
        let sourceURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "BuyLedger/Features/App/RootSidebarLayout.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)

        #expect(
            !source.contains("Text(LocalizedStringKey(group.status.title)) + Text(\" \\(count) 件\")"),
            "Accessibility text must not concatenate separately localized Text values."
        )
    }

    @Test func compactOrderFilterSummaryDoesNotConcatenateLocalizedText() throws {
        let sourceURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "BuyLedger/Features/Orders/OrdersCompactView.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)

        #expect(
            !source.contains("Text(\"篩選\") + Text(verbatim: \": \") + summary"),
            "Filter summaries must not concatenate separately localized Text values."
        )
    }

    @Test func englishLocaleFormatsTheJuly18SpecExampleWithoutChineseDateText() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let reportedDate = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 7, day: 18, hour: 12))
        )
        let referenceDate = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 7, day: 20, hour: 12))
        )

        let title = OrderFormatters.daySectionTitle(
            for: reportedDate,
            referenceDate: referenceDate,
            calendar: calendar,
            locale: Locale(identifier: "en")
        )

        #expect(title.contains("July"))
        #expect(title.range(of: "[\\u{3400}-\\u{9FFF}]", options: .regularExpression) == nil)
    }
}
