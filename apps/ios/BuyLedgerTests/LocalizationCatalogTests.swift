//
//  LocalizationCatalogTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/17.
//

import Foundation
import Testing
@testable import BuyLedger

/// 驗證本地化字串目錄
struct LocalizationCatalogTests {
    
    // MARK: - Tests
    
    @Test func catalogContainsCompleteTraditionalChineseAndEnglishValues() throws(any Error) {
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
        
        let sourceRoot =
            catalogURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let missingCodeLiterals = try Self.missingUserVisibleCodeLiterals(
            in: sourceRoot,
            catalogKeys: Set(strings.keys)
        )
        #expect(
            missingCodeLiterals.isEmpty,
            "程式使用但目錄未收錄的使用者可見字串：\(missingCodeLiterals.map { "\($0.key) [\($0.location)]" })"
        )
        
        // 只驗證已驗收的英文翻譯；完整性由上方掃描檢查。
        let documentedEnglishValues = [
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
            "輸入新的訂單來源名稱，加入後會立即套用至此訂單。":
                "Enter a new order source name. It will be applied to this order immediately.",
            "選擇商品類別": "Category",
            "輸入新的商品類別名稱，加入後會立即套用至此訂單。":
                "Enter a new product category name. It will be applied to this order immediately.",
            "選擇付款方式": "Select Payment Method",
            "目前列表的商品明細 (類別、品名、數量、單價、幣別) 會送往第三方雲端服務；不含客戶姓名。":
                "The current list's product details (category, product name, quantity, "
                    + "unit price, and currency) are sent to a third-party cloud service; "
                    + "customer names are not included.",
            "改用空白資料庫繼續": "Continue with a Blank Database",
            "資料無法開啟": "Unable to Open Data",
            "備份已保留": "Backup Kept",
            "操作失敗": "Operation Failed",
            "更正付款方式": "Correct Payment Method",
            "確認更正": "Confirm Correction",
            "確認後將重算 %lld 筆既有訂單的付款旗標與獲利；折抵、補款或對帳狀態可能被清除。此操作無法復原。":
                "After confirmation, %lld existing orders will be recalculated for payment flags "
                    + "and profit. Deduction, supplement, or reconciliation status may be cleared. "
                    + "This cannot be undone.",
            "付款方式編輯失敗，請稍後再試。": "Payment method edit failed. Please try again later.",
            "AI 總結已達時間上限，以下顯示已取得的內容；摘要已截斷。":
                "The AI summary reached its time limit. The content received so far is shown; "
                    + "the summary was cut short.",
        ]
        for (key, expectedEnglishValue) in documentedEnglishValues {
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
                !allowedSameSourceAndEnglishValues.contains(key)
            else {
                return nil
            }
            return key
        }
        #expect(
            untranslatedChineseKeys.isEmpty,
            "English translation 仍與中文 source 相同：\(untranslatedChineseKeys)")
        
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
    
    @Test func retiredReminderStringsDoNotReappearInTheCatalog() throws(any Error) {
        let catalogURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "BuyLedger/Resources/Localizable.xcstrings")
        let data = try Data(contentsOf: catalogURL)
        let root = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try #require(root["strings"] as? [String: Any])
        
        // 舊 popup 文案未在現行畫面顯示
        let retiredKeys = ["新增提醒", "移除提醒"]
        let revivedKeys = retiredKeys.filter { strings[$0] != nil }
        #expect(revivedKeys.isEmpty, "已退役字串不得復活：\(revivedKeys)")
    }
    
    @Test func calendarPermissionDescriptionIsLocalized() throws(any Error) {
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
    
    @Test func presentationBoundariesDoNotBypassSelectedAppLocale() throws(any Error) {
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
            "Hard-coded locale found: \(hardCodedTraditionalChineseLocales)"
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
    
    /// 圖表的本地化軸標題與資料序列名稱
    @Test func chartAccessibilityDescriptorStringsResolveUsingTheSelectedAppLanguage() {
        #expect(AppLanguage.english.localized("項目") == "Item")
        #expect(AppLanguage.traditionalChinese.localized("項目") == "項目")
        #expect(AppLanguage.english.localized("數值") == "Value")
        #expect(AppLanguage.traditionalChinese.localized("數值") == "數值")
        #expect(AppLanguage.english.localized("順序") == "Sequence")
        #expect(AppLanguage.traditionalChinese.localized("順序") == "順序")
        #expect(AppLanguage.english.localized("類別") == "Category")
        #expect(AppLanguage.traditionalChinese.localized("類別") == "類別")
        #expect(AppLanguage.english.localized("占比") == "Share")
        #expect(AppLanguage.traditionalChinese.localized("占比") == "占比")
        #expect(AppLanguage.english.localized("長條圖") == "Bar Chart")
        #expect(AppLanguage.traditionalChinese.localized("長條圖") == "長條圖")
        #expect(AppLanguage.english.localized("圈狀圖") == "Donut Chart")
        #expect(AppLanguage.traditionalChinese.localized("圈狀圖") == "圈狀圖")
        #expect(AppLanguage.english.localized("走勢圖") == "Trend Chart")
        #expect(AppLanguage.traditionalChinese.localized("走勢圖") == "走勢圖")
        
        let ordinal = 3
        #expect(AppLanguage.english.localized("第 \(ordinal) 筆") == "Point 3")
        #expect(AppLanguage.traditionalChinese.localized("第 \(ordinal) 筆") == "第 3 筆")
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
    
    @Test func rootNavigationTitlesUseTheExplicitLanguageModifier() throws(any Error) {
        for pattern in Self.forbiddenNavigationTitlePatterns {
            #expect(
                Self.containsForbiddenNavigationTitlePattern(in: pattern),
                "每個禁止的 navigationTitle pattern 都應被 scanner 命中。"
            )
        }
        #expect(
            !Self.containsForbiddenNavigationTitlePattern(
                in: "Text(LocalizedStringKey(\"Orders\"))"
            ),
            "不含禁止 pattern 的 source 不應被 scanner 命中。"
        )

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
            let source = try String(
                contentsOf: sourceRoot.appending(path: relativePath), encoding: .utf8)
            #expect(
                !Self.containsForbiddenNavigationTitlePattern(in: source),
                "\(relativePath) must not pass localized literals to native navigationTitle."
            )
        }
    }
    
    @Test func campaignDetailReceiptStatusesCrossLocalizationBoundary() throws(any Error) {
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
    
    @Test func sidebarSmartGroupAccessibilityDoesNotConcatenateLocalizedText() throws(any Error) {
        let sourceURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "BuyLedger/Features/App/RootSidebarLayout.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)
        
        #expect(
            !source.contains(
                "Text(LocalizedStringKey(group.status.title)) + Text(\" \\(count) 件\")"),
            "Accessibility text must not concatenate separately localized Text values."
        )
    }
    
    @Test func compactOrderFilterSummaryDoesNotConcatenateLocalizedText() throws(any Error) {
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
    
    @Test func englishLocaleFormatsTheJuly18SpecExampleWithoutChineseDateText() throws(any Error) {
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

// MARK: - Nested Types

private extension LocalizationCatalogTests {
    
    /// 掃描結果中的單一缺漏字串；位置只用於讓失敗訊息能直接回到原始碼
    struct MissingCodeLiteral: Hashable {
        let key: String
        let location: String
    }
}

private extension String {
    /// 原始碼中的字串位置與內容
    struct SourceLiteral {
        let raw: String
        let start: Int
        
        /// 解析多行字串內容
        var logicalValue: String {
            guard raw.contains("\n") else {
                return raw
            }
            var rawLines = raw.components(separatedBy: "\n")
            // 移除三引號前後不屬於內容的空白行。
            guard rawLines.count >= 2 else {
                return raw
            }
            let dedentWidth = rawLines.removeLast().count
            rawLines.removeFirst()
            let dedented = rawLines.map { line -> String in
                guard line.count >= dedentWidth else {
                    return line
                }
                return String(line.dropFirst(dedentWidth))
            }
            
            var joined = ""
            for (index, line) in dedented.enumerated() {
                let isLastLine = index == dedented.count - 1
                if !isLastLine, line.hasSuffix("\\") {
                    joined += String(line.dropLast())
                } else if !isLastLine {
                    joined += line + "\n"
                } else {
                    joined += line
                }
            }
            return joined
        }
        
        var localizationKeyVariants: [String] {
            let unescaped =
                logicalValue
                .replacingOccurrences(of: "\\n", with: "\n")
                .replacingOccurrences(of: "\\t", with: "\t")
                .replacingOccurrences(of: "\\\"", with: "\"")
                .replacingOccurrences(of: "\\\\", with: "\\")
            
            let nsValue = unescaped as NSString
            let interpolations = nsValue.topLevelInterpolationRanges()
            guard !interpolations.isEmpty else {
                return [unescaped]
            }
            
            // 將字面值中的 `%` 轉為 String Catalog 的 `%%`。
            var variants = [""]
            var cursor = 0
            for range in interpolations {
                let prefix =
                    nsValue
                    .substring(with: NSRange(location: cursor, length: range.location - cursor))
                    .replacingOccurrences(of: "%", with: "%%")
                variants = variants.flatMap { partial in
                    [partial + prefix + "%@", partial + prefix + "%lld"]
                }
                cursor = range.location + range.length
            }
            let suffix = nsValue.substring(from: cursor).replacingOccurrences(of: "%", with: "%%")
            return Array(Set(variants.map { $0 + suffix })).sorted()
        }
    }
    /// 原始碼的行範圍
    struct SourceLineRange {
        let range: NSRange
        let lineNumber: Int
    }
}

// MARK: - Private Method

private extension LocalizationCatalogTests {
    
    // MARK: 使用者可見字面值掃描

    /// native `navigationTitle` 不得直接接收的本地化字面值 pattern
    static let forbiddenNavigationTitlePatterns = [
        ".navigationTitle(\"",
        ".navigationTitle(Text(\"",
        ".navigationTitle(Text(LocalizedStringKey(",
    ]

    /// 判斷 source 是否含有任一禁止的 navigationTitle pattern
    /// - Parameter source: 要檢查的 Swift 原始碼
    /// - Returns: 命中任一禁止 pattern 時為 `true`
    static func containsForbiddenNavigationTitlePattern(in source: String) -> Bool {
        forbiddenNavigationTitlePatterns.contains(where: source.contains)
    }
    
    /// modifier 字串引數前的最大比對長度
    static let modifierArgumentLookaheadLimit = 160
    
    /// 往回檢查行事曆標題的行數
    static let calendarTitleLookbackLines = 3
    
    /// 掃描候選使用者可見字串，再套用排除規則
    /// - Parameters:
    ///   - sourceRoot: 原始碼根目錄
    ///   - catalogKeys: 已知的本地化 key
    /// - Returns: 待本地化字串清單
    /// - Throws: 原始檔讀取或掃描失敗時拋出錯誤
    static func missingUserVisibleCodeLiterals(
        in sourceRoot: URL,
        catalogKeys: Set<String>
    ) throws(any Error) -> [MissingCodeLiteral] {
        let enumerator = try #require(
            FileManager.default.enumerator(
                at: sourceRoot,
                includingPropertiesForKeys: nil
            )
        )
        var missing = Set<MissingCodeLiteral>()
        
        for case let file as URL in enumerator where file.pathExtension == "swift" {
            let relativePath = file.path.replacingOccurrences(of: sourceRoot.path + "/", with: "")
            
            // 排除規則 1：測試替身與 Preview 資料不進入正式介面。
            guard !relativePath.contains("App/Testing/"), !relativePath.hasSuffix("+Samples.swift")
            else {
                continue
            }
            
            let source = try String(contentsOf: file, encoding: .utf8)
            let sanitizedSource = source.withPreviewBlocksRemoved()
            let lineRanges = sanitizedSource.lineRanges
            let lines = sanitizedSource.components(separatedBy: "\n")
            let literalMatches = sanitizedSource.literalMatches
            let visibleStarts = try Self.visibleLiteralStarts(
                in: sanitizedSource,
                literalMatches: literalMatches,
                lineRanges: lineRanges,
                lines: lines
            )
            let tokenExcludedStarts = try Self.tokenAnchoredExclusionStarts(in: sanitizedSource)
            
            for literal in literalMatches where visibleStarts.contains(literal.start) {
                let lineNumber = lineRanges.lineNumber(containingUTF16Offset: literal.start)
                guard
                    !Self.isExcluded(
                        literal: literal,
                        lineNumber: lineNumber,
                        lines: lines,
                        tokenExcludedStarts: tokenExcludedStarts,
                        catalogKeys: catalogKeys
                    )
                else {
                    continue
                }
                
                let variants = literal.localizationKeyVariants
                let key = variants.first ?? literal.raw
                let location = "\(relativePath):\(lineNumber + 1)"
                missing.insert(MissingCodeLiteral(key: key, location: location))
            }
        }
        
        return missing.sorted { lhs, rhs in
            lhs.key == rhs.key ? lhs.location < rhs.location : lhs.key < rhs.key
        }
    }
    
    /// 收錄規則 A／B／C：找出候選使用者可見字串字面值的 start offset
    /// - Parameters:
    ///   - source: 原始碼
    ///   - literalMatches: 找到的字串字面值
    ///   - lineRanges: 原始碼行範圍
    ///   - lines: 原始碼行
    /// - Returns: 字串字面值的起始位置
    /// - Throws: 字串掃描失敗時拋出錯誤
    static func visibleLiteralStarts(
        in source: String,
        literalMatches: [String.SourceLiteral],
        lineRanges: [String.SourceLineRange],
        lines: [String]
    ) throws(any Error) -> Set<Int> {
        var visibleStarts = Set<Int>()
        
        // 大寫型別呼叫的未標籤字串視為顯示文字
        // 多行字串只處理 regex 可辨識的部分
        let structuralInitializerPattern =
            "\\b[A-Z][A-Za-z0-9]*\\s*\\(\\s*\"((?:\\\\.|[^\"\\\\])*)\""
        visibleStarts.formUnion(
            try source.literalCaptureStarts(matching: structuralInitializerPattern))
        
        // 規則 B：SwiftUI modifier 的字串參數也算可見文字
        let visiblePatterns = [
            "\\bLocalizedStringKey\\s*\\([^\\n)]{0,\(Self.modifierArgumentLookaheadLimit)}?"
                + "\"((?:\\\\.|[^\"\\\\])*)\"",
            "\\.(?:navigationTitle|accessibilityLabel|accessibilityValue|"
                + "accessibilityHint|prompt|alert|confirmationDialog|"
                + "rootNavigationTitle|help)\\s*\\(\\s*(?:Text\\s*\\(\\s*)?"
                + "\"((?:\\\\.|[^\"\\\\])*)\"",
            "\\b(?:title|label|message|description|emptyTitle|emptyDescription|"
                + "addButtonTitle|addAlertTitle|namePlaceholder|submitTitle|unit|"
                + "centerTitle|accessibilitySummary|retryTitle|delta)"
                + "\\s*:\\s*\"((?:\\\\.|[^\"\\\\])*)\"",
            "\\bsend\\s*\\(\\s*\\.[A-Za-z0-9_]+\\s*\\(\\s*\"((?:\\\\.|[^\"\\\\])*)\"",
            "\\b(?:errorMessage|truncationMessage)\\s*=\\s*\"((?:\\\\.|[^\"\\\\])*)\"",
        ]
        for pattern in visiblePatterns {
            visibleStarts.formUnion(try source.literalCaptureStarts(matching: pattern))
        }
        
        // 規則 C：display 與本地化型別的回傳值也算可見文字
        visibleStarts.formUnion(
            source.literalStartsInsideDisplayScopes(
                literalMatches: literalMatches,
                lineRanges: lineRanges,
                lines: lines
            )
        )
        
        return visibleStarts
    }
    
    /// 找出排除規則中緊鄰字串開頭的模式
    /// - Parameter source: 原始碼
    /// - Returns: 排除標記的起始位置
    /// - Throws: 原始檔解析失敗時拋出錯誤
    static func tokenAnchoredExclusionStarts(in source: String) throws(any Error) -> Set<Int> {
        let patterns = [
            // 排除規則 3：Text(verbatim:) 不需本地化。
            "\\bText\\s*\\(\\s*verbatim\\s*:\\s*\"((?:\\\\.|[^\"\\\\])*)\"",
            // 排除 APIError.message：它只供網路層使用，UI 會轉成 userMessage
            "\\bAPIError\\.[A-Za-z0-9_]+\\s*\\(\\s*message\\s*:\\s*\"((?:\\\\.|[^\"\\\\])*)\"",
            // 排除規則 5a：錯誤與 log 格式字串只供診斷。
            "\\.error\\s*\\(\\s*\"((?:\\\\.|[^\"\\\\])*)\"",
            "\\bos_log\\s*\\(\\s*\"((?:\\\\.|[^\"\\\\])*)\"",
            // 排除資源名稱參數，例如 Color 與 Image 的字串引數
            "\\bColor\\s*\\(\\s*\"((?:\\\\.|[^\"\\\\])*)\"",
            "\\bImage\\s*\\(\\s*\"((?:\\\\.|[^\"\\\\])*)\"",
        ]
        var starts = Set<Int>()
        for pattern in patterns {
            starts.formUnion(try source.literalCaptureStarts(matching: pattern))
        }
        return starts
    }
    
    /// 套用無法用單一 pattern 表達的排除規則
    /// - Returns: 字串是否應排除
    static func isExcluded(
        literal: String.SourceLiteral,
        lineNumber: Int,
        lines: [String],
        tokenExcludedStarts: Set<Int>,
        catalogKeys: Set<String>
    ) -> Bool {
        // 排除規則 2：註解不是使用者介面。
        guard !lines.isCommentOnly(lineNumber) else {
            return true
        }
        
        if tokenExcludedStarts.contains(literal.start) {
            return true
        }
        
        let sourceLine = lines[lineNumber]
        
        // 排除 Logger 的字串參數，避免把診斷訊息當成文案
        if sourceLine.contains("Logger(") {
            return true
        }
        
        // 排除規則 6：EventKit 標題不需本地化。
        let precedingWindow = lines[
            max(0, lineNumber - Self.calendarTitleLookbackLines)...lineNumber]
        if precedingWindow.contains(where: { $0.contains("reminderTitle") }) {
            return true
        }
        
        // 排除規則 8：單獨空白或標點不是可翻譯文字。
        let variants = literal.localizationKeyVariants
        guard !variants.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        else {
            return true
        }
        guard variants.contains(where: { $0.contains(where: { $0.isLetter || $0.isNumber }) })
        else {
            return true
        }
        guard !variants.contains(where: catalogKeys.contains) else {
            return true
        }
        
        return false
    }
}

private extension String {
    
    // MARK: 字面值與行號掃描
    
    /// 掃描原始碼中所有頂層字串字面值的起訖位置
    var literalMatches: [SourceLiteral] {
        let nsSource = self as NSString
        let length = nsSource.length
        var results: [SourceLiteral] = []
        var index = 0
        while index < length {
            let character = nsSource.character(at: index)
            if character == quoteCharacter {
                let contentStart = index + 1
                if let contentEnd = nsSource.scanStringLiteralBody(from: contentStart) {
                    let range = NSRange(location: contentStart, length: contentEnd - contentStart)
                    results.append(
                        SourceLiteral(raw: nsSource.substring(with: range), start: contentStart))
                    index = contentEnd + 1
                    continue
                }
            } else if character == slashCharacter, index + 1 < length {
                let next = nsSource.character(at: index + 1)
                if next == slashCharacter {
                    index = nsSource.endOfLineIndex(from: index)
                    continue
                } else if next == starCharacter,
                    let afterComment = nsSource.skipBlockComment(from: index + 2) {
                    index = afterComment
                    continue
                }
            }
            index += 1
        }
        return results
    }
    
    var lineRanges: [SourceLineRange] {
        let nsSource = self as NSString
        var ranges: [SourceLineRange] = []
        var offset = 0
        for (lineNumber, line) in components(separatedBy: "\n").enumerated() {
            let length = (line as NSString).length
            ranges.append(
                SourceLineRange(
                    range: NSRange(location: offset, length: length),
                    lineNumber: lineNumber
                )
            )
            offset += length + (offset + length < nsSource.length ? 1 : 0)
        }
        return ranges
    }
    
    /// 找出符合指定正規表示式的字串 literal 起始位置
    /// - Parameter pattern: 要比對的正規表示式
    /// - Returns: 命中 literal 的 UTF-16 起始位置集合
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    func literalCaptureStarts(matching pattern: String) throws(any Error) -> Set<Int> {
        let expression = try NSRegularExpression(pattern: pattern)
        let nsSource = self as NSString
        let fullRange = NSRange(location: 0, length: nsSource.length)
        var starts = Set<Int>()
        expression.enumerateMatches(in: self, range: fullRange) {
            match,
            _,
            _ in
            guard let match, match.numberOfRanges > 1 else {
                return
            }
            let capture = match.range(at: 1)
            if capture.location != NSNotFound {
                starts.insert(capture.location)
            }
        }
        return starts
    }
    
    /// 找出顯示範圍內的字串位置
    /// - Returns: 顯示範圍內的字串起始位置
    func literalStartsInsideDisplayScopes(
        literalMatches: [SourceLiteral],
        lineRanges: [SourceLineRange],
        lines: [String]
    ) -> Set<Int> {
        var starts = Set<Int>()
        var braceDepth = 0
        // 每個 scope 記錄結束門檻，依 braceDepth 判斷是否結束。
        var activeScopeMinimumDepths: [Int] = []
        let literalsByLine = Dictionary(grouping: literalMatches) { literal in
            lineRanges.lineNumber(containingUTF16Offset: literal.start)
        }
        
        for (lineNumber, line) in lines.enumerated() {
            let startsDisplayScope = line.isDisplayScopeDeclaration
            let opens = line.reduce(into: 0) { count, character in
                if character == "{" { count += 1 }
            }
            let closes = line.reduce(into: 0) { count, character in
                if character == "}" { count += 1 }
            }
            let depthAfterLine = braceDepth + opens - closes
            
            if startsDisplayScope && opens > closes {
                activeScopeMinimumDepths.append(max(depthAfterLine, 1))
            }
            
            if (startsDisplayScope || !activeScopeMinimumDepths.isEmpty),
                !lines.isCommentOnly(lineNumber) {
                for literal in literalsByLine[lineNumber] ?? [] {
                    starts.insert(literal.start)
                }
            }
            
            braceDepth = depthAfterLine
            activeScopeMinimumDepths.removeAll { braceDepth < $0 }
        }
        
        return starts
    }
    
    /// 移除 `#Preview` 區塊內容，保留原始行數供掃描使用
    /// - Returns: 移除 preview 內容後的原始碼
    func withPreviewBlocksRemoved() -> String {
        var output: [String] = []
        var previewBraceDepth = 0
        for line in components(separatedBy: "\n") {
            let isPreviewStart = line.contains("#Preview")
            if isPreviewStart || previewBraceDepth > 0 {
                let opens = line.reduce(into: 0) { count, character in
                    if character == "{" { count += 1 }
                }
                let closes = line.reduce(into: 0) { count, character in
                    if character == "}" { count += 1 }
                }
                previewBraceDepth += opens - closes
                output.append(String(repeating: " ", count: line.utf16.count))
            } else {
                output.append(line)
            }
            if previewBraceDepth <= 0 {
                previewBraceDepth = 0
            }
        }
        return output.joined(separator: "\n")
    }
    
    var isDisplayScopeDeclaration: Bool {
        guard contains("{") else {
            return false
        }
        
        // 依宣告型別判定顯示文字，不逐一列舉屬性名稱。
        // 同時處理計算屬性與函式的本地化型別回傳值
        let typedDeclarationPattern =
            "\\b(?:var|func)\\s+\\w+\\s*(?:\\([^)]*\\))?\\s*:\\s*"
                + "(?:LocalizedStringKey|LocalizedStringResource|String\\.LocalizationValue)\\b"
        do {
            let regex = try NSRegularExpression(pattern: typedDeclarationPattern)
            if regex.firstMatch(in: self, range: NSRange(startIndex..., in: self)) != nil {
                return true
            }
        } catch {
            return false
        }
        if contains("-> LocalizedStringResource") || contains("-> LocalizedStringKey")
            || contains("String.LocalizationValue") {
            return true
        }
        
        // 依名稱辨識無法從型別判定的使用者可見文案。
        let displayProperties = [
            "title", "entryTitle", "addButtonTitle", "emptyTitle", "addAlertTitle",
            "renameSheetTitle", "navigationTitleKey", "daySectionTitle", "sparklineSummary",
            "summaryFailureMessage", "reminderTitle",
        ]
        return displayProperties.contains { name in
            let regex: NSRegularExpression
            do {
                regex = try NSRegularExpression(pattern: "\\b(?:var|func)\\s+\(name)\\b")
            } catch {
                return false
            }
            return regex.firstMatch(in: self, range: NSRange(startIndex..., in: self)) != nil
        }
    }
}

// MARK: 括號／巢狀引號感知的字面值掃描

/// UTF-16 code unit 常數，供逐字元掃描比對用
private let quoteCharacter = UInt16(UnicodeScalar("\"").value)
private let backslashCharacter = UInt16(UnicodeScalar("\\").value)
private let openParenCharacter = UInt16(UnicodeScalar("(").value)
private let closeParenCharacter = UInt16(UnicodeScalar(")").value)
private let slashCharacter = UInt16(UnicodeScalar("/").value)
private let starCharacter = UInt16(UnicodeScalar("*").value)
private let newlineCharacter = UInt16(UnicodeScalar("\n").value)

private extension NSString {
    
    /// 掃描一個字串字面值本體 (開頭引號之後) 直到其配對的結尾引號
    /// - Returns: 字串結束位置
    func scanStringLiteralBody(from start: Int) -> Int? {
        var index = start
        while index < length {
            let character = self.character(at: index)
            if character == backslashCharacter {
                guard index + 1 < length else { return nil }
                if self.character(at: index + 1) == openParenCharacter {
                    guard let afterInterpolation = skipInterpolation(openParenIndex: index + 1)
                    else {
                        return nil
                    }
                    index = afterInterpolation
                } else {
                    index += 2
                }
            } else if character == quoteCharacter {
                return index
            } else {
                index += 1
            }
        }
        return nil
    }
    
    /// 跳過插值內容，依括號深度處理巢狀字串
    /// - Returns: 插值結束位置
    func skipInterpolation(openParenIndex: Int) -> Int? {
        var depth = 1
        var index = openParenIndex + 1
        while index < length {
            let character = self.character(at: index)
            if character == quoteCharacter {
                guard let bodyEnd = scanStringLiteralBody(from: index + 1) else { return nil }
                index = bodyEnd + 1
            } else if character == openParenCharacter {
                depth += 1
                index += 1
            } else if character == closeParenCharacter {
                depth -= 1
                index += 1
                if depth == 0 {
                    return index
                }
            } else if character == backslashCharacter {
                index += 2
            } else {
                index += 1
            }
        }
        return nil
    }
    
    /// 找出字串內的頂層插值範圍
    /// - Returns: 頂層插值範圍
    func topLevelInterpolationRanges() -> [NSRange] {
        var ranges: [NSRange] = []
        var index = 0
        while index < length {
            let character = self.character(at: index)
            if character == backslashCharacter, index + 1 < length,
                self.character(at: index + 1) == openParenCharacter {
                guard let end = skipInterpolation(openParenIndex: index + 1) else {
                    break
                }
                ranges.append(NSRange(location: index, length: end - index))
                index = end
            } else if character == backslashCharacter {
                index += 2
            } else {
                index += 1
            }
        }
        return ranges
    }
    
    /// 找到指定位置所在行的結尾
    /// - Returns: 行尾位置
    func endOfLineIndex(from start: Int) -> Int {
        var index = start
        while index < length, character(at: index) != newlineCharacter {
            index += 1
        }
        return index
    }
    
    /// 跳過一段 `/* ... */` 區塊註解
    /// - Returns: 區塊註解結束位置
    func skipBlockComment(from start: Int) -> Int? {
        var index = start
        while index + 1 < length {
            if character(at: index) == starCharacter, character(at: index + 1) == slashCharacter {
                return index + 2
            }
            index += 1
        }
        return nil
    }
}

// MARK: 行號與註解判定小工具

private extension String.SourceLineRange {
    
    /// 判斷 UTF-16 offset 是否落在此行範圍內
    /// - Parameter utf16Offset: 要檢查的 UTF-16 offset
    /// - Returns: offset 是否位於此行範圍
    func contains(_ utf16Offset: Int) -> Bool {
        NSLocationInRange(utf16Offset, range)
    }
}

private extension Array where Element == String {
    
    /// 判斷指定行是否只有註解或空白
    /// - Parameter lineNumber: 要檢查的行號
    /// - Returns: 指定行是否為註解行
    func isCommentOnly(_ lineNumber: Int) -> Bool {
        guard indices.contains(lineNumber) else {
            return true
        }
        let trimmed = self[lineNumber].trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("//") || trimmed.hasPrefix("*") || trimmed.hasPrefix("/*")
    }
}

private extension Array where Element == String.SourceLineRange {
    
    /// 找出包含指定 UTF-16 offset 的行號
    /// - Parameter offset: 要查詢的 UTF-16 offset
    /// - Returns: 命中的行號
    func lineNumber(containingUTF16Offset offset: Int) -> Int {
        if let exact = first(where: { $0.contains(offset) }) {
            return exact.lineNumber
        }
        // 多行字串起點可能落在換行，回到三引號所在行。
        return last(where: { $0.range.location <= offset })?.lineNumber ?? 0
    }
}
