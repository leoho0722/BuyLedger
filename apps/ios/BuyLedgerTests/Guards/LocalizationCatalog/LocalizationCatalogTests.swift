//
//  LocalizationCatalogTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/7/17.
//

import Foundation
import Testing

/// 字串目錄 `Localizable.xcstrings` 與 `InfoPlist.xcstrings` 的單元測試，直接解析 JSON 逐條檢查翻譯完整性
struct LocalizationCatalogTests {

    // MARK: - Properties

    /// 主要字串目錄相對於 apps/ios 的路徑
    private static let localizableCatalogPath = "BuyLedger/Resources/Localizable.xcstrings"

    /// `Info.plist` 的本地化字串目錄 `InfoPlist.xcstrings` 相對於 apps/ios 的路徑
    private static let infoPlistCatalogPath = "BuyLedger/Resources/InfoPlist.xcstrings"

    /// 驗證原始碼中的使用者可見字面值都已收錄於字串目錄，缺漏時列出字面值與所在位置
    ///
    /// - Throws: 讀取字串目錄或掃描原始碼失敗時丟出錯誤
    @Test
    func missingUserVisibleCodeLiterals_程式字面值_皆已收錄於目錄() throws {
        // Given
        let strings = try Self.catalogStrings(atRelativePath: Self.localizableCatalogPath)
        let sourceRoot = TestPaths.iosRoot.appending(path: "BuyLedger")

        // When
        let missingCodeLiterals = try LocalizationCatalogLiteralScan.missingUserVisibleCodeLiterals(
            in: sourceRoot,
            catalogKeys: Set(strings.keys)
        )

        // Then
        #expect(
            missingCodeLiterals.isEmpty,
            "程式使用但目錄未收錄的使用者可見字串：\(missingCodeLiterals.map { "\($0.key) [\($0.location)]" })"
        )
    }

    /// 驗證實機回報過的字串在英文目錄的值與已驗收翻譯相同，收錄與否由字面值掃描另行檢查
    ///
    /// - Parameter example: 字串目錄 key 與已驗收的英文值
    /// - Throws: 讀取字串目錄失敗時丟出錯誤
    @Test(arguments: DocumentedEnglishValue.examples)
    func stringValue_已驗收的字串_與驗收值相同(example: DocumentedEnglishValue) throws {
        // Given
        let strings = try Self.catalogStrings(atRelativePath: Self.localizableCatalogPath)

        // When
        let englishValue = Self.stringValue(forKey: example.key, language: "en", in: strings)

        // Then
        #expect(englishValue == example.expectedEnglishValue, "字串目錄條目缺少英文值或與驗收值不同：\(example.key)")
    }

    /// 驗證規格範例的字串目錄條目，`extractionState` 與正體中文、英文值皆與規格相同
    ///
    /// - Parameter example: 規格範例的 key、`extractionState` 與中英文值
    /// - Throws: 讀取字串目錄失敗時丟出錯誤
    @Test(arguments: SpecCatalogEntryExample.examples)
    func catalogEntry_規格範例條目_狀態與中英文值皆與規格相同(example: SpecCatalogEntryExample) throws {
        // Given
        let strings = try Self.catalogStrings(atRelativePath: Self.localizableCatalogPath)

        // When
        let entry = strings[example.key] as? [String: Any]
        let extractionState = entry?["extractionState"] as? String
        let chineseValue = Self.stringValue(forKey: example.key, language: "zh-Hant", in: strings)
        let englishValue = Self.stringValue(forKey: example.key, language: "en", in: strings)

        // Then
        #expect(extractionState == example.expectedExtractionState, "條目狀態與規格不同：\(example.key)")
        #expect(chineseValue == example.expectedChineseValue, "正體中文值與規格不同：\(example.key)")
        #expect(englishValue == example.expectedEnglishValue, "英文值與規格不同：\(example.key)")
    }

    /// 驗證含中文的條目，英文值與正體中文來源不得相同，允許清單內的條目除外
    ///
    /// - Throws: 讀取字串目錄失敗時丟出錯誤
    @Test
    func hasUntranslatedEnglishValue_中文來源_不得與英文值相同() throws {
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

    /// 驗證需要翻譯的條目都有非空白的正體中文與英文值，缺漏時列出該 key 與語言
    ///
    /// - Throws: 讀取字串目錄失敗時丟出錯誤
    @Test
    func findBlankLocalizations_每個需翻譯條目_中英文值皆非空白() throws {
        // Given
        let strings = try Self.catalogStrings(atRelativePath: Self.localizableCatalogPath)
        try #require(!strings.isEmpty)

        // When
        let blankLocalizations = Self.findBlankLocalizations(in: strings)

        // Then
        #expect(blankLocalizations.isEmpty, "缺少或空白的本地化值：\(blankLocalizations)")
    }

    /// 驗證字串目錄的 `sourceLanguage` 為 `zh-Hant`，其餘語言以此為翻譯基準
    ///
    /// - Throws: 讀取字串目錄失敗時丟出錯誤
    @Test
    func sourceLanguage_字串目錄_為正體中文() throws {
        // Given
        let root = try Self.catalogRoot(atRelativePath: Self.localizableCatalogPath)

        // When
        let sourceLanguage = root["sourceLanguage"] as? String

        // Then
        #expect(sourceLanguage == "zh-Hant")
    }

    /// 驗證舊 popup 的新增提醒與移除提醒文案不得重新收錄於字串目錄，這些文案已不在現行畫面顯示
    ///
    /// - Throws: 讀取字串目錄失敗時丟出錯誤
    @Test
    func retiredKeys_舊提醒文案_不得復活於目錄() throws {
        // Given
        let strings = try Self.catalogStrings(atRelativePath: Self.localizableCatalogPath)
        let retiredKeys = ["新增提醒", "移除提醒"]

        // When
        let revivedKeys = retiredKeys.filter { strings[$0] != nil }

        // Then
        #expect(revivedKeys.isEmpty, "已退役字串不得復活：\(revivedKeys)")
    }

    /// 驗證 `NSCalendarsFullAccessUsageDescription` 在 `InfoPlist.xcstrings` 的正體中文與英文值皆非空白
    ///
    /// - Parameter language: 要讀取的字串目錄語言識別字
    /// - Throws: 讀取字串目錄失敗時丟出錯誤
    @Test(arguments: ["zh-Hant", "en"])
    func stringValue_行事曆權限說明_中英文說明皆非空白(language: String) throws {
        // Given
        let strings = try Self.catalogStrings(atRelativePath: Self.infoPlistCatalogPath)
        let key = "NSCalendarsFullAccessUsageDescription"

        // When
        let value = Self.stringValue(forKey: key, language: language, in: strings)

        // Then
        #expect(value?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
    }

    /// 驗證字串目錄的 key 不含中文字元，殘留的中文 key 會列出
    ///
    /// - Throws: 讀取字串目錄或建立正規表示式失敗時丟出錯誤
    @Test
    func noResidualChineseKeys_字串目錄_不得含有中文Key() throws {
        // Given
        let strings = try Self.catalogStrings(atRelativePath: Self.localizableCatalogPath)
        let chinesePattern = try NSRegularExpression(pattern: #"[\x{4E00}-\x{9FFF}]"#)

        // When
        let chineseKeys = strings.keys
            .filter {
                chinesePattern.firstMatch(in: $0, range: NSRange($0.startIndex..., in: $0)) != nil
            }
            .sorted()

        // Then
        #expect(chineseKeys.isEmpty, "字串目錄中仍殘留中文 Key：\(chineseKeys)")
    }

    /// 驗證需翻譯的 key 皆符合 `<domain>.<component>.<elementType>.<descriptor>` 點記號與小駝峰格式
    ///
    /// - Throws: 讀取字串目錄失敗時丟出錯誤
    /// - Note: 結構化 key 至少 475 筆，確保涵蓋全部條目
    @Test
    func structuredKeysFormat_結構化英文Key_符合點記號與小駝峰規範() throws {
        // Given
        let strings = try Self.catalogStrings(atRelativePath: Self.localizableCatalogPath)
        let pattern = "^[a-z]+(\\.[a-z][a-zA-Z0-9]*){2,3}$"
        var invalidKeys: [String] = []
        var structuredCount = 0

        // When
        for (key, entry) in strings {
            let entryDict = entry as? [String: Any]
            let shouldTranslate = entryDict?["shouldTranslate"] as? Bool ?? true
            guard shouldTranslate else {
                continue
            }

            if key.range(of: pattern, options: .regularExpression) == nil {
                invalidKeys.append(key)
            } else {
                structuredCount += 1
            }
        }

        // Then
        #expect(
            invalidKeys.isEmpty,
            "需翻譯之字串 Key 必須 100% 符合結構化英文點記號與 lowerCamelCase 格式：\(invalidKeys)"
        )
        #expect(structuredCount >= 475, "字串目錄中需翻譯之結構化英文 Key 應覆蓋全量條目")
    }

    /// 驗證字串目錄不含 `shouldTranslate` 為 `false` 的非本地化條目，這類文字應以 `Text(verbatim:)` 呈現
    ///
    /// - Throws: 讀取字串目錄失敗時丟出錯誤
    @Test
    func noNonTranslatableEntries_字串目錄_不得含有非本地化條目() throws {
        // Given
        let strings = try Self.catalogStrings(atRelativePath: Self.localizableCatalogPath)

        // When
        let nonTranslatableKeys = strings
            .compactMap { key, value in
                let dict = value as? [String: Any]
                return dict?["shouldTranslate"] as? Bool == false ? key : nil
            }
            .sorted()

        // Then
        #expect(
            nonTranslatableKeys.isEmpty,
            "字串目錄中仍殘留非本地化條目 (應使用 Text(verbatim:))：\(nonTranslatableKeys)"
        )
    }

    /// 驗證已清理的死碼 key (歷史廢棄、重複的通用 key 與無程式引用的條目) 不存在於字串目錄
    ///
    /// - Throws: 讀取字串目錄失敗時丟出錯誤
    @Test
    func prunedDeadKeys_歷史廢棄與重複通用Key_不得存在於目錄() throws {
        // Given
        let strings = try Self.catalogStrings(atRelativePath: Self.localizableCatalogPath)
        let deadKeys = [
            "campaigns.general.label.deleteData",
            "common.action.confirm",
            "common.action.label.back",
            "common.general.action.clearSearch",
            "common.general.label.addReminder",
            "common.general.label.appearanceMode",
            "common.general.label.baseCurrency",
            "common.general.label.estimatedProfit",
            "common.general.label.returning",
            "common.general.label.workspace",
            "common.general.message.afterConfirmationLd",
            "common.ui.label.disabled",
            "common.ui.label.eightLowerThan",
            "common.ui.label.primaryAction",
            "common.ui.label.raisedCardShadow",
            "common.ui.label.secondaryAction",
            "common.ui.label.spendingMonth",
            "common.ui.label.standardCardShadow",
            "common.ui.label.textAction",
            "fx.rates.message.exchangeRatesLoaded",
            "orders.edit.button.saveAndContinue",
            "orders.edit.label.automatic",
            "orders.general.label.traditionalChinese",
            "orders.list.label.date",
            "orders.list.message.tryAnotherSearch",
            "orders.merge.message.photoLimitNoticeLegacy",
        ]

        // When
        let foundDeadKeys = deadKeys.filter { strings[$0] != nil }

        // Then
        #expect(foundDeadKeys.isEmpty, "已清理之死碼 Key 不得存在於目錄：\(foundDeadKeys)")
    }

    /// 驗證字串目錄沒有 `extractionState` 為 `stale` 的條目，殘留的條目需改為 manual 或刪除
    ///
    /// - Throws: 讀取字串目錄失敗時丟出錯誤
    @Test
    func staleKeys_真實目錄_不得有stale條目() throws {
        // Given
        let strings = try Self.catalogStrings(atRelativePath: Self.localizableCatalogPath)

        // When
        let keys = Self.staleKeys(in: strings)

        // Then
        #expect(keys.isEmpty, "字串目錄仍有 stale 條目，需改為 manual 或刪除：\(keys)")
    }

    /// 驗證字串目錄的翻譯值沒有寫死百分比數字，百分比改由 FormatStyle 依語言格式化
    ///
    /// - Throws: 讀取字串目錄或建立正規表示式失敗時丟出錯誤
    @Test
    func literalPercentageKeys_真實目錄_不得含字面百分比() throws {
        // Given
        let strings = try Self.catalogStrings(atRelativePath: Self.localizableCatalogPath)

        // When
        let keys = try Self.literalPercentageKeys(in: strings)

        // Then
        #expect(keys.isEmpty, "翻譯值寫死了百分比數字，應改由 FormatStyle 格式化：\(keys)")
    }

    /// 驗證字面百分比判定規則，數字後接 `%` 的字面值命中，格式指定符與沒有數字的百分比不命中
    ///
    /// - Parameter example: 合成條目 `zh-Hant` 的字串值與預期命中的 key
    /// - Throws: 建立正規表示式失敗時丟出錯誤
    @Test(arguments: LiteralPercentageExample.examples)
    func literalPercentageKeys_合成單一條目_依判定規則回報(example: LiteralPercentageExample) throws {
        // Given
        let strings: [String: Any] = [
            "synthetic.key": [
                "localizations": [
                    "zh-Hant": [
                        "stringUnit": [
                            "state": "translated",
                            "value": example.value,
                        ],
                    ],
                ],
            ],
        ]

        // When
        let keys = try Self.literalPercentageKeys(in: strings)

        // Then
        #expect(keys == example.expectedKeys)
    }

    /// 驗證變體的 `other` 分支含字面百分比時，仍會回報該 key
    ///
    /// - Throws: 建立正規表示式失敗時丟出錯誤
    @Test
    func literalPercentageKeys_變體的other分支含百分比_回報該key() throws {
        // Given
        let strings: [String: Any] = [
            "synthetic.plural": [
                "localizations": [
                    "zh-Hant": [
                        "variations": [
                            "plural": [
                                "other": [
                                    "stringUnit": [
                                        "state": "translated",
                                        "value": "已完成 100%",
                                    ],
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ]

        // When
        let keys = try Self.literalPercentageKeys(in: strings)

        // Then
        #expect(keys == ["synthetic.plural"])
    }

    /// 驗證替代變數的 `one` 分支含字面百分比時，仍會回報該 key
    ///
    /// - Throws: 建立正規表示式失敗時丟出錯誤
    @Test
    func literalPercentageKeys_替代變數的one分支含百分比_回報該key() throws {
        // Given
        let strings: [String: Any] = [
            "synthetic.substitution": [
                "localizations": [
                    "en": [
                        "substitutions": [
                            "count": [
                                "argNum": 1,
                                "formatSpecifier": "lld",
                                "variations": [
                                    "plural": [
                                        "one": [
                                            "stringUnit": [
                                                "state": "translated",
                                                "value": "%1$lld item at 1.5%",
                                            ],
                                        ],
                                    ],
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ]

        // When
        let keys = try Self.literalPercentageKeys(in: strings)

        // Then
        #expect(keys == ["synthetic.substitution"])
    }

    /// 驗證 `staleKeys` 只回傳 `extractionState` 為 `stale` 的條目，manual 與無狀態的條目不回傳
    @Test
    func staleKeys_合成目錄_只回傳stale條目() {
        // Given
        let strings: [String: Any] = [
            "synthetic.stale": ["extractionState": "stale"],
            "synthetic.manual": ["extractionState": "manual"],
            "synthetic.none": [
                "localizations": [
                    "zh-Hant": [
                        "stringUnit": [
                            "state": "translated",
                            "value": "無狀態",
                        ],
                    ],
                ],
            ],
        ]

        // When
        let keys = Self.staleKeys(in: strings)

        // Then
        #expect(keys == ["synthetic.stale"])
    }
}

// MARK: - Nested Types

extension LocalizationCatalogTests {

    /// 已驗收的英文翻譯案例，每筆為一組字串目錄 key 與英文值，供參數化測試逐一驗證
    struct DocumentedEnglishValue: Sendable {

        /// 已驗收的英文翻譯案例清單，每筆的 key 與英文值成對
        static let examples = [
            Self(key: "dashboard.overview.title.overview", expectedEnglishValue: "Overview"),
            Self(key: "orders.list.title", expectedEnglishValue: "Orders"),
            Self(key: "common.action.label.all", expectedEnglishValue: "All"),
            Self(key: "dashboard.overview.label.revenue", expectedEnglishValue: "Revenue"),
            Self(key: "orders.detail.label.cost", expectedEnglishValue: "Cost"),
            Self(
                key: "dashboard.overview.label.activeOrders",
                expectedEnglishValue: "Active Orders"
            ),
            Self(key: "common.action.label.more", expectedEnglishValue: "More"),
            Self(
                key: "fx.rates.label.selectSourceCurrency",
                expectedEnglishValue: "Select Source Currency"
            ),
            Self(
                key: "settings.preference.label.selectDefaultCurrency",
                expectedEnglishValue: "Select Default Currency"
            ),
            Self(
                key: "settings.preference.label.selectAiModel",
                expectedEnglishValue: "Select AI Model"
            ),
            Self(
                key: "campaigns.detail.label.paymentProgress",
                expectedEnglishValue: "Payment Progress"
            ),
            Self(
                key: "campaigns.detail.label.arrivalProgress",
                expectedEnglishValue: "Arrival Progress"
            ),
            Self(
                key: "orders.filter.status.pendingPayment",
                expectedEnglishValue: "Pending Payment"
            ),
            Self(key: "orders.general.status.received", expectedEnglishValue: "Received"),
            Self(key: "campaigns.list.label.arrived", expectedEnglishValue: "Arrived"),
            Self(key: "orders.detail.label.payment", expectedEnglishValue: "Payment"),
            Self(key: "common.date.today", expectedEnglishValue: "Today"),
            Self(key: "common.date.yesterday", expectedEnglishValue: "Yesterday"),
            Self(key: "orders.edit.label.selectSource", expectedEnglishValue: "Select Source"),
            Self(
                key: "orders.edit.label.selectCategories",
                expectedEnglishValue: "Select Categories"
            ),
            Self(
                key: "orders.edit.label.selectOrderSource",
                expectedEnglishValue: "Select Order Source"
            ),
            Self(
                key: "orders.edit.message.enterNewOrder",
                expectedEnglishValue: "Enter a new order source name. It will be applied to this order immediately."
            ),
            Self(key: "orders.list.label.category1", expectedEnglishValue: "Category"),
            Self(
                key: "orders.edit.message.enterNewProduct",
                expectedEnglishValue: "Enter a new product category name. It will be applied to this order immediately."
            ),
            Self(
                key: "orders.list.label.selectPaymentMethod",
                expectedEnglishValue: "Select Payment Method"
            ),
            Self(
                key: "ai.summary.message.currentListsProduct",
                expectedEnglishValue: "The current list's product details (category, product name, quantity, unit price, and currency) are sent to a third-party cloud service; customer names are not included."
            ),
            Self(
                key: "common.general.label.continueBlankDatabase",
                expectedEnglishValue: "Continue with a Blank Database"
            ),
            Self(
                key: "common.general.label.unableOpenData",
                expectedEnglishValue: "Unable to Open Data"
            ),
            Self(key: "common.general.label.backupKept", expectedEnglishValue: "Backup Kept"),
            Self(
                key: "orders.list.label.operationFailed",
                expectedEnglishValue: "Operation Failed"
            ),
            Self(
                key: "orders.lookup.label.correctPaymentMethod",
                expectedEnglishValue: "Correct Payment Method"
            ),
            Self(
                key: "orders.detail.label.confirmCorrection",
                expectedEnglishValue: "Confirm Correction"
            ),
            Self(
                key: "orders.lookup.message.confirmRecalculateNotice",
                expectedEnglishValue: "After confirmation, %lld existing orders will be recalculated for payment flags and profit. Deduction, supplement, or reconciliation status may be cleared. This cannot be undone."
            ),
            Self(
                key: "orders.lookup.message.paymentMethodEdit",
                expectedEnglishValue: "Payment method edit failed. Please try again later."
            ),
            Self(
                key: "ai.summary.message.aiSummaryReached",
                expectedEnglishValue: "The AI summary reached its time limit. The content received so far is shown; the summary was cut short."
            ),
        ]

        /// 字串目錄的 key
        let key: String

        /// 該 key 已驗收的英文值
        let expectedEnglishValue: String
    }

    /// 規格範例的字串目錄條目，每筆為一組 key、狀態與中英文值，供參數化測試逐一驗證
    struct SpecCatalogEntryExample: Sendable {

        /// 規格範例的三筆條目，兩筆沒有 `extractionState`，一筆為 manual
        static let examples = [
            Self(
                key: "dashboard.overview.label.revenue",
                expectedExtractionState: nil,
                expectedChineseValue: "營業額",
                expectedEnglishValue: "Revenue"
            ),
            Self(
                key: "orders.general.message.orderSavedTry",
                expectedExtractionState: nil,
                expectedChineseValue: "訂單儲存失敗，請稍後再試。",
                expectedEnglishValue: "The order could not be saved. Try again later."
            ),
            Self(
                key: "orders.general.label.model",
                expectedExtractionState: "manual",
                expectedChineseValue: "模型",
                expectedEnglishValue: "Model"
            ),
        ]

        /// 字串目錄的 key
        let key: String

        /// 該 key 的 `extractionState`，沒有狀態標記時為 nil
        let expectedExtractionState: String?

        /// 該 key 的正體中文值
        let expectedChineseValue: String

        /// 該 key 的英文值
        let expectedEnglishValue: String
    }

    /// 字面百分比判定的單一案例，合成條目 `zh-Hant` 的字串值與預期命中的 key 清單
    struct LiteralPercentageExample: Sendable {

        /// 判定規則的正反例，預期命中時為含合成 key 的清單，未命中時為空清單
        static let examples = [
            Self(value: "100%", expectedKeys: ["synthetic.key"]),
            Self(value: "1.5%", expectedKeys: ["synthetic.key"]),
            Self(value: "0% ~ 100%", expectedKeys: ["synthetic.key"]),
            Self(value: "8 %", expectedKeys: ["synthetic.key"]),
            Self(value: "50%%", expectedKeys: ["synthetic.key"]),
            Self(value: "100% to", expectedKeys: ["synthetic.key"]),
            Self(value: "目標毛利需低於 100% 才能計算建議售價。", expectedKeys: ["synthetic.key"]),
            Self(value: "Enter 1.5 for 1.5%.", expectedKeys: ["synthetic.key"]),
            Self(
                value: "The target margin must be below 100% to calculate a suggested price.",
                expectedKeys: ["synthetic.key"]
            ),
            Self(value: "1 %1$@ = %2$@ TWD", expectedKeys: []),
            Self(value: "%1$lld 筆", expectedKeys: []),
            Self(value: "%1$lld 筆 · %2$@", expectedKeys: []),
            Self(value: "%@", expectedKeys: []),
        ]

        /// 合成條目 `zh-Hant` 的字串值
        let value: String

        /// 預期命中的 key 清單，未命中時為空陣列
        let expectedKeys: [String]
    }
}

// MARK: - Private Method

private extension LocalizationCatalogTests {

    /// 讀取字串目錄檔的 `strings` 內容
    ///
    /// - Parameter relativePath: 字串目錄檔相對於 apps/ios 的路徑
    /// - Returns: 以 key 為索引的條目內容
    /// - Throws: 讀檔失敗，或內容缺少 `strings` 時丟出錯誤
    static func catalogStrings(atRelativePath relativePath: String) throws -> [String: Any] {
        let root = try Self.catalogRoot(atRelativePath: relativePath)
        return try #require(root["strings"] as? [String: Any])
    }

    /// 讀取字串目錄檔的頂層 JSON 物件
    ///
    /// - Parameter relativePath: 字串目錄檔相對於 apps/ios 的路徑
    /// - Returns: 解析後的頂層 JSON 物件
    /// - Throws: 讀檔失敗，或內容不是 JSON 物件時丟出錯誤
    static func catalogRoot(atRelativePath relativePath: String) throws -> [String: Any] {
        let catalogURL = TestPaths.iosRoot.appending(path: relativePath)
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
        if let stringUnit = localization?["stringUnit"] as? [String: Any] {
            return stringUnit["value"] as? String
        }
        if let variations = localization?["variations"] as? [String: Any],
           let plural = variations["plural"] as? [String: Any] {
            let sample = plural["other"] as? [String: Any] ?? plural["one"] as? [String: Any]
            let stringUnit = sample?["stringUnit"] as? [String: Any]
            return stringUnit?["value"] as? String
        }
        return nil
    }

    /// 判斷條目是否為含中文、需要翻譯，但英文值仍與正體中文來源相同
    ///
    /// - Parameters:
    ///   - key: 字串目錄的 key
    ///   - value: 該 key 的條目內容
    /// - Returns: 英文值仍與中文來源相同且不在允許清單時為 `true`
    static func hasUntranslatedEnglishValue(key: String, value: Any) -> Bool {
        let allowedSameSourceAndEnglishValues: Set<String> = ["VIP"]
        guard key.range(of: #"[\x{3400}-\x{9FFF}]"#, options: .regularExpression) != nil,
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
    /// - Returns: 依 key 排序，每筆格式為 key [語言]
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

    /// 找出 `extractionState` 為 `stale` 的條目 key，依字母序排列
    ///
    /// - Parameter strings: 字串目錄的 `strings` 內容
    /// - Returns: 狀態為 `stale` 的 key
    static func staleKeys(in strings: [String: Any]) -> [String] {
        strings
            .filter { _, entry in
                (entry as? [String: Any])?["extractionState"] as? String == "stale"
            }
            .keys
            .sorted()
    }

    /// 找出任一語言的翻譯值含字面百分比的條目 key，依字母序排列
    ///
    /// - Parameter strings: 字串目錄的 `strings` 內容
    /// - Returns: 命中字面百分比規則的 key
    /// - Throws: 建立正規表示式失敗時丟出錯誤
    static func literalPercentageKeys(in strings: [String: Any]) throws -> [String] {
        var keys: [String] = []
        for (key, entry) in strings {
            for value in Self.localizedValues(inEntry: entry) {
                if try Self.containsLiteralPercentage(value) {
                    keys.append(key)
                    break
                }
            }
        }
        return keys.sorted()
    }

    /// 收集條目 `localizations` 下所有語言的字串值，含 `variations` 與 `substitutions` 的巢狀結構
    ///
    /// - Parameter entry: 字串目錄中單一條目的內容
    /// - Returns: 條目內所有 `stringUnit.value`
    static func localizedValues(inEntry entry: Any) -> [String] {
        guard let localizations = (entry as? [String: Any])?["localizations"] else {
            return []
        }
        return Self.stringUnitValues(in: localizations)
    }

    /// 遞迴走訪 JSON 節點，收集節點以下所有 `stringUnit.value`
    ///
    /// - Parameter node: 字串目錄中任一層的 JSON 節點
    /// - Returns: 節點以下所有字串值
    static func stringUnitValues(in node: Any) -> [String] {
        if let dictionary = node as? [String: Any] {
            var values: [String] = []
            if let stringUnit = dictionary["stringUnit"] as? [String: Any],
               let value = stringUnit["value"] as? String {
                values.append(value)
            }
            for child in dictionary.values {
                values += Self.stringUnitValues(in: child)
            }
            return values
        }
        if let array = node as? [Any] {
            return array.flatMap { Self.stringUnitValues(in: $0) }
        }
        return []
    }

    /// 判斷文字是否含字面百分比，即數字後接 `%` (中間可夾空白)，且該 `%` 不是格式指定符的開頭
    ///
    /// - Parameter text: 字串目錄中單一 `stringUnit.value`
    /// - Returns: 含字面百分比時為 `true`
    /// - Throws: 建立正規表示式失敗時丟出錯誤
    /// - Note: 格式指定符只認 `%` 直接接位置標記、精度、長度修飾與轉換字元，不認旗標與空白；`%%` 不是指定符，視為字面百分比
    static func containsLiteralPercentage(_ text: String) throws -> Bool {
        let regex = try NSRegularExpression(
            pattern: #"[0-9] *%(?!(?:[0-9]+\$)?(?:\.[0-9]+)?(?:hh|ll|h|l|q|z|t|j)?[@dDiuUxXoOfFeEgGcCsSp])"#
        )
        return regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }
}
