//
//  LocalizationCatalogTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/17.
//

import Foundation
import Testing

/// 驗證本地化字串目錄
struct LocalizationCatalogTests {

    // MARK: - Properties

    /// native `navigationTitle` 不得直接接收的本地化字面值 pattern
    static let forbiddenNavigationTitlePatterns = [
        ".navigationTitle(\"",
        ".navigationTitle(Text(\"",
        ".navigationTitle(Text(LocalizedStringKey(",
    ]

    /// modifier 字串引數前的最大比對長度
    static let modifierArgumentLookaheadLimit = 160

    /// 往回檢查行事曆標題的行數
    static let calendarTitleLookbackLines = 3

    /// 主要字串目錄相對於 `apps/ios` 的路徑
    private static let localizableCatalogPath = "BuyLedger/Resources/Localizable.xcstrings"

    /// Info.plist 字串目錄相對於 `apps/ios` 的路徑
    private static let infoPlistCatalogPath = "BuyLedger/Resources/InfoPlist.xcstrings"

    /// 程式中使用者可見的字串字面值都已收錄於字串目錄
    ///
    /// - Throws: 讀取字串目錄、原始檔或建立掃描規則失敗時拋出錯誤
    @Test
    func missingUserVisibleCodeLiterals_程式字面值_皆已收錄於目錄() throws(any Error) {
        // Given
        let strings = try Self.catalogStrings(atRelativePath: Self.localizableCatalogPath)
        let sourceRoot = Self.iosRootURL.appending(path: "BuyLedger")

        // When
        let missingCodeLiterals = try Self.missingUserVisibleCodeLiterals(
            in: sourceRoot,
            catalogKeys: Set(strings.keys)
        )

        // Then
        #expect(
            missingCodeLiterals.isEmpty,
            "程式使用但目錄未收錄的使用者可見字串：\(missingCodeLiterals.map { "\($0.key) [\($0.location)]" })"
        )
    }

    /// 實機回報過的字串，英文值與已驗收的翻譯相同；完整性由程式字面值的掃描檢查
    ///
    /// - Parameter example: 字串目錄 key 與已驗收的英文值
    /// - Throws: 讀取字串目錄失敗時丟出錯誤
    @Test(arguments: DocumentedEnglishValue.examples)
    func englishValue_已驗收的字串_與驗收值相同(example: DocumentedEnglishValue) throws(any Error) {
        // Given
        let strings = try Self.catalogStrings(atRelativePath: Self.localizableCatalogPath)

        // When
        let englishValue = Self.stringValue(forKey: example.key, language: "en", in: strings)

        // Then
        #expect(englishValue == example.expectedEnglishValue, "字串目錄條目缺少英文值或與驗收值不同：\(example.key)")
    }

    /// 含中文的條目，英文值不得與中文 source 相同
    ///
    /// - Throws: 讀取字串目錄失敗時丟出錯誤
    @Test
    func englishValue_中文來源_不得與英文值相同() throws(any Error) {
        // Given
        let strings = try Self.catalogStrings(atRelativePath: Self.localizableCatalogPath)
        try #require(!strings.isEmpty)

        // When
        let untranslatedChineseKeys = strings
            .filter { Self.hasUntranslatedEnglishValue(key: $0.key, value: $0.value) }
            .keys
            .sorted()

        // Then
        #expect(untranslatedChineseKeys.isEmpty, "英文翻譯仍與中文來源相同：\(untranslatedChineseKeys)")
    }

    /// 每個需要翻譯的條目，正體中文與英文值都不是空白
    ///
    /// - Throws: 讀取字串目錄失敗時丟出錯誤
    @Test
    func localizations_每個需翻譯條目_中英文值皆非空白() throws(any Error) {
        // Given
        let strings = try Self.catalogStrings(atRelativePath: Self.localizableCatalogPath)
        try #require(!strings.isEmpty)

        // When
        let blankLocalizations = Self.findBlankLocalizations(in: strings)

        // Then
        #expect(blankLocalizations.isEmpty, "缺少或空白的本地化值：\(blankLocalizations)")
    }

    /// 字串目錄以正體中文作為來源語言
    ///
    /// - Throws: 讀取字串目錄失敗時丟出錯誤
    @Test
    func sourceLanguage_字串目錄_為正體中文() throws(any Error) {
        // Given
        let root = try Self.catalogRoot(atRelativePath: Self.localizableCatalogPath)

        // When
        let sourceLanguage = root["sourceLanguage"] as? String

        // Then
        #expect(sourceLanguage == "zh-Hant")
    }

    /// 舊 popup 的新增提醒與移除提醒文案未在現行畫面顯示，不得重新收錄於字串目錄
    ///
    /// - Throws: 讀取字串目錄失敗時丟出錯誤
    @Test
    func retiredKeys_舊提醒文案_不得復活於目錄() throws(any Error) {
        // Given
        let strings = try Self.catalogStrings(atRelativePath: Self.localizableCatalogPath)
        let retiredKeys = ["新增提醒", "移除提醒"]

        // When
        let revivedKeys = retiredKeys.filter { strings[$0] != nil }

        // Then
        #expect(revivedKeys.isEmpty, "已退役字串不得復活：\(revivedKeys)")
    }

    /// 行事曆權限說明在 Info.plist 字串目錄有正體中文與英文版本
    ///
    /// - Throws: 讀取字串目錄失敗時丟出錯誤
    @Test
    func calendarUsageDescription_InfoPlist字串目錄_中英文說明皆非空白() throws(any Error) {
        // Given
        let strings = try Self.catalogStrings(atRelativePath: Self.infoPlistCatalogPath)
        let key = "NSCalendarsFullAccessUsageDescription"

        // When
        let chineseValue = Self.stringValue(forKey: key, language: "zh-Hant", in: strings)
        let englishValue = Self.stringValue(forKey: key, language: "en", in: strings)

        // Then
        #expect(chineseValue?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        #expect(englishValue?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
    }
}

// MARK: - Nested Types

extension LocalizationCatalogTests {

    /// 已驗收的英文翻譯，每組字串目錄 key 對應一個參數化案例
    struct DocumentedEnglishValue: Sendable {

        /// 實機回報過、已驗收英文值的字串目錄 key
        static let examples = [
            Self(key: "總覽", expectedEnglishValue: "Overview"),
            Self(key: "訂單", expectedEnglishValue: "Orders"),
            Self(key: "全部", expectedEnglishValue: "All"),
            Self(key: "營業額", expectedEnglishValue: "Revenue"),
            Self(key: "成本", expectedEnglishValue: "Cost"),
            Self(key: "進行中訂單", expectedEnglishValue: "Active Orders"),
            Self(key: "更多", expectedEnglishValue: "More"),
            Self(key: "選擇來源幣別", expectedEnglishValue: "Select Source Currency"),
            Self(key: "選擇預設幣別", expectedEnglishValue: "Select Default Currency"),
            Self(key: "選擇 AI 模型", expectedEnglishValue: "Select AI Model"),
            Self(key: "收款進度", expectedEnglishValue: "Payment Progress"),
            Self(key: "到貨進度", expectedEnglishValue: "Arrival Progress"),
            Self(key: "待收款", expectedEnglishValue: "Pending"),
            Self(key: "已收款", expectedEnglishValue: "Received"),
            Self(key: "到貨", expectedEnglishValue: "Arrived"),
            Self(key: "收款", expectedEnglishValue: "Payment"),
            Self(key: "今天", expectedEnglishValue: "Today"),
            Self(key: "昨天", expectedEnglishValue: "Yesterday"),
            Self(key: "選擇來源", expectedEnglishValue: "Select Source"),
            Self(key: "選擇類別", expectedEnglishValue: "Select Categories"),
            Self(key: "選擇訂單來源", expectedEnglishValue: "Select Order Source"),
            Self(
                key: "輸入新的訂單來源名稱，加入後會立即套用至此訂單。",
                expectedEnglishValue: "Enter a new order source name. It will be applied to this order immediately."
            ),
            Self(key: "選擇商品類別", expectedEnglishValue: "Category"),
            Self(
                key: "輸入新的商品類別名稱，加入後會立即套用至此訂單。",
                expectedEnglishValue: "Enter a new product category name. It will be applied to this order immediately."
            ),
            Self(key: "選擇付款方式", expectedEnglishValue: "Select Payment Method"),
            Self(
                key: "目前列表的商品明細 (類別、品名、數量、單價、幣別) 會送往第三方雲端服務；不含客戶姓名。",
                expectedEnglishValue: "The current list's product details (category, product name, quantity, unit price, and currency) are sent to a third-party cloud service; customer names are not included."
            ),
            Self(key: "改用空白資料庫繼續", expectedEnglishValue: "Continue with a Blank Database"),
            Self(key: "資料無法開啟", expectedEnglishValue: "Unable to Open Data"),
            Self(key: "備份已保留", expectedEnglishValue: "Backup Kept"),
            Self(key: "操作失敗", expectedEnglishValue: "Operation Failed"),
            Self(key: "更正付款方式", expectedEnglishValue: "Correct Payment Method"),
            Self(key: "確認更正", expectedEnglishValue: "Confirm Correction"),
            Self(
                key: "確認後將重算 %lld 筆既有訂單的付款旗標與獲利；折抵、補款或對帳狀態可能被清除。此操作無法復原。",
                expectedEnglishValue: "After confirmation, %lld existing orders will be recalculated for payment flags and profit. Deduction, supplement, or reconciliation status may be cleared. This cannot be undone."
            ),
            Self(
                key: "付款方式編輯失敗，請稍後再試。",
                expectedEnglishValue: "Payment method edit failed. Please try again later."
            ),
            Self(
                key: "AI 總結已達時間上限，以下顯示已取得的內容；摘要已截斷。",
                expectedEnglishValue: "The AI summary reached its time limit. The content received so far is shown; the summary was cut short."
            ),
        ]

        /// 字串目錄的 key
        let key: String

        /// 該 key 已驗收的英文值
        let expectedEnglishValue: String
    }
}

// MARK: - Computed Properties

extension LocalizationCatalogTests {

    /// 測試 target 所在的 iOS 平台目錄 (`apps/ios`)，由本檔位置推得
    static var iosRootURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}

// MARK: - Private Method

private extension LocalizationCatalogTests {

    /// 讀取字串目錄檔的 `strings` 內容
    ///
    /// - Parameter relativePath: 字串目錄檔相對於 `apps/ios` 的路徑
    /// - Returns: 以 key 為索引的條目內容
    /// - Throws: 讀檔失敗，或內容缺少 `strings` 時丟出錯誤
    static func catalogStrings(
        atRelativePath relativePath: String
    ) throws(any Error) -> [String: Any] {
        let root = try Self.catalogRoot(atRelativePath: relativePath)
        return try #require(root["strings"] as? [String: Any])
    }

    /// 讀取字串目錄檔的頂層 JSON 物件
    ///
    /// - Parameter relativePath: 字串目錄檔相對於 `apps/ios` 的路徑
    /// - Returns: 解析後的頂層 JSON 物件
    /// - Throws: 讀檔失敗，或內容不是 JSON 物件時丟出錯誤
    static func catalogRoot(
        atRelativePath relativePath: String
    ) throws(any Error) -> [String: Any] {
        let catalogURL = Self.iosRootURL.appending(path: relativePath)
        let data = try Data(contentsOf: catalogURL)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    /// 取得條目在指定語言下的字串值
    ///
    /// - Parameters:
    ///   - key: 字串目錄的 key
    ///   - language: 語言代碼，例如 `en`
    ///   - strings: 字串目錄的 `strings` 內容
    /// - Returns: 該語言的字串值，缺少條目或該語言時為 `nil`
    static func stringValue(
        forKey key: String,
        language: String,
        in strings: [String: Any]
    ) -> String? {
        let record = strings[key] as? [String: Any]
        let localizations = record?["localizations"] as? [String: Any]
        let localization = localizations?[language] as? [String: Any]
        let stringUnit = localization?["stringUnit"] as? [String: Any]
        return stringUnit?["value"] as? String
    }

    /// 判斷條目是否為含中文、需要翻譯，但英文值仍與正體中文來源相同
    ///
    /// - Parameters:
    ///   - key: 字串目錄的 key
    ///   - value: 該 key 的條目內容
    /// - Returns: 英文值仍與中文來源相同且不在允許清單時為 `true`
    static func hasUntranslatedEnglishValue(key: String, value: Any) -> Bool {
        let allowedSameSourceAndEnglishValues: Set<String> = ["VIP"]
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
            return false
        }
        return true
    }

    /// 找出需要翻譯、卻缺少或只有空白值的語言版本
    ///
    /// - Parameter strings: 字串目錄的 `strings` 內容
    /// - Returns: 依 key 排序的 `key [語言]` 清單
    static func findBlankLocalizations(in strings: [String: Any]) -> [String] {
        var blankLocalizations: [String] = []
        for key in strings.keys.sorted() {
            let record = strings[key] as? [String: Any]
            guard record?["shouldTranslate"] as? Bool != false else {
                continue
            }
            for language in ["zh-Hant", "en"] {
                let value = Self.stringValue(forKey: key, language: language, in: strings)
                let isBlank = value?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
                if isBlank {
                    blankLocalizations.append("\(key) [\(language)]")
                }
            }
        }
        return blankLocalizations
    }
}
