//
//  LocalizationCatalogAppLanguageTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation
import Testing

@testable import BuyLedger

/// `AppLanguage` 的單元測試，涵蓋所選語言下的導覽標題、日期與字串解析
struct LocalizationCatalogAppLanguageTests {

    /// 驗證根分頁標題依所選 App 語言解析為對應的英文或正體中文
    ///
    /// - Parameter scenario: 受測語言、輸入情境與固定預期結果
    @Test(arguments: [
        LocalizedTitlesCase(
            language: .english,
            expectedTitles: ["Overview", "Orders", "Campaigns", "Insights", "More"]
        ),
        LocalizedTitlesCase(
            language: .traditionalChinese,
            expectedTitles: ["總覽", "訂單", "開團", "分析", "更多"]
        ),
    ])
    func resolve_根導覽標題_依所選語言解析(scenario: LocalizedTitlesCase) {
        // Given
        let titles: [LocalizedStringResource] = [
            LocalizedStringResource("dashboard.overview.title.overview"),
            LocalizedStringResource("orders.list.title"),
            LocalizedStringResource("orders.detail.title.campaigns"),
            LocalizedStringResource("orders.filter.title.insights"),
            LocalizedStringResource("common.action.label.more"),
        ]

        // When
        let localizedTitles = titles.map { scenario.language.resolve($0) }

        // Then
        #expect(localizedTitles == scenario.expectedTitles)
    }

    /// 驗證圖表的本地化軸標題與資料序列名稱依所選 App 語言解析
    ///
    /// - Parameter scenario: 受測語言、輸入情境與固定預期結果
    @Test(arguments: [
        LocalizedTitlesCase(
            language: .english,
            expectedTitles: [
                "Item",
                "Value",
                "Sequence",
                "Category",
                "Share",
                "Bar Chart",
                "Donut Chart",
                "Trend Chart",
                "Point 3",
            ]
        ),
        LocalizedTitlesCase(
            language: .traditionalChinese,
            expectedTitles: ["項目", "數值", "順序", "類別", "占比", "長條圖", "圈狀圖", "走勢圖", "第 3 筆"]
        ),
    ])
    func resolve_圖表描述字串_依所選語言解析(scenario: LocalizedTitlesCase) {
        // Given
        let ordinal = 3
        let ordinalTitle = LocalizedStringResource(
            "common.general.label.pointLd",
            defaultValue: "\(ordinal)"
        )
        let titles: [LocalizedStringResource] = [
            LocalizedStringResource("orders.list.label.text"),
            LocalizedStringResource("orders.detail.label.value"),
            LocalizedStringResource("orders.list.label.sequence"),
            LocalizedStringResource("orders.list.label.category2"),
            LocalizedStringResource("orders.detail.label.share"),
            LocalizedStringResource("insights.chart.label.barChart"),
            LocalizedStringResource("orders.detail.label.donutChart"),
            LocalizedStringResource("dashboard.overview.label.trendChart"),
            ordinalTitle,
        ]

        // When
        let localizedTitles = titles.map { scenario.language.resolve($0) }

        // Then
        #expect(ordinalTitle.key == "common.general.label.pointLd")
        #expect(localizedTitles == scenario.expectedTitles)
    }

    /// 驗證訂單頁導覽標題依選取狀態變化，並依所選 App 語言解析
    ///
    /// - Parameter scenario: 受測語言、輸入情境與固定預期結果
    @Test(arguments: OrdersNavigationTitleExample.examples)
    func navigationTitleKey_各選取狀態_依所選語言解析(scenario: OrdersNavigationTitleExample) {
        // Given
        var state = OrderListFeatureTestSupport.makeState()
        state.isSelecting = scenario.isSelecting
        state.selectedOrderIDs = scenario.selectedOrderIDs

        // When
        let resource = state.navigationTitleKey
        let title = scenario.language.resolve(resource)

        // Then
        #expect(resource.key == scenario.expectedKey)
        #expect(title == scenario.expectedTitle)
    }

    /// 驗證英文語系下 7 月 18 日的日期分段標題寫出 July，且不含中文字
    ///
    /// - Throws: 測試日期建立失敗時丟出錯誤
    @Test
    func daySectionTitle_英文語系的七月十八日_標題不含中文日期文字() throws {
        // Given
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let reportedDate = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 7,
                    day: 18,
                    hour: 12
                )
            )
        )
        let referenceDate = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 7,
                    day: 20,
                    hour: 12
                )
            )
        )

        let chinesePattern = try NSRegularExpression(pattern: #"[\x{3400}-\x{9FFF}]"#)

        // When
        let title = OrderFormatters.daySectionTitle(
            for: reportedDate,
            referenceDate: referenceDate,
            calendar: calendar,
            locale: Locale(identifier: "en")
        )

        // Then
        #expect(title.contains("July"))
        #expect(
            chinesePattern.firstMatch(
                in: title,
                range: NSRange(title.startIndex..., in: title)
            ) == nil
        )
    }

    /// 驗證結構化英文 Key 依所選 App 語言正確解析為中英文
    ///
    /// - Parameter scenario: 受測語言、輸入情境與固定預期結果
    @Test(arguments: LocalizedKeyExample.examples)
    func resolve_結構化英文Key_依所選語言解析(scenario: LocalizedKeyExample) {
        // Given
        let key = scenario.key

        // When
        let value = scenario.language.resolve(key)

        // Then
        #expect(value == scenario.expectedValue, "Key \(key.key) 解析失敗")
    }

    /// 驗證選取筆數依所選語言與單複數正確解析
    ///
    /// - Parameter scenario: 受測語言、輸入情境與固定預期結果
    @Test(arguments: SelectedCountExample.examples)
    func resolve_選取筆數_依單複數解析(scenario: SelectedCountExample) {
        // Given
        let count = scenario.count

        // When
        let resource = LocalizedStringResource(
            "orders.batch.message.selectedCount",
            defaultValue: "\(count)"
        )
        let value = scenario.language.resolve(resource)

        // Then
        #expect(resource.key == "orders.batch.message.selectedCount")
        #expect(value == scenario.expectedValue)
    }

    /// 驗證 `BuyLedger.xctestplan` 鎖定系統語言為 `zh-Hant` 時，resource 依所選 App 語言解析
    ///
    /// - Parameter scenario: 受測語言、resource 與固定預期結果
    /// - Note: 英文案例確認解析依所選 App 語言，而非測試計畫的系統語言
    /// - Note: 1234 案例固定整數依 App 語言加千分位
    @Test(arguments: ResolveResourceExample.examples)
    func resolve_系統語言為正體中文_依所選語言輸出(scenario: ResolveResourceExample) {
        // Given
        let resource = scenario.resource

        // When
        let resolvedValue = scenario.language.resolve(resource)
        let resolvedValueFromLocale = AppLanguage.resolve(
            resource,
            locale: scenario.language.locale
        )

        // Then
        #expect(resource.key == scenario.expectedKey)
        #expect(resolvedValue == scenario.expectedValue)
        #expect(resolvedValueFromLocale == scenario.expectedValue)
    }

    /// 驗證合併照片上限 resource 依位置參數帶入照片總數、上限與已選數量
    ///
    /// - Parameter scenario: 受測語言、輸入情境與固定預期結果
    @Test(arguments: [
        LocalizedFragmentsCase(
            language: .traditionalChinese,
            expectedFirstFragment: "共有 10 張照片，超過上限 5 張",
            expectedSecondFragment: "已選 2/5",
            expectedValue: "兩筆訂單共有 10 張照片，超過上限 5 張；請勾選要保留的照片 (已選 2/5)，按「繼續」帶入合併後的新訂單。"
        ),
        LocalizedFragmentsCase(
            language: .english,
            expectedFirstFragment: "contain 10 photos, exceeding the limit of 5",
            expectedSecondFragment: "2/5 selected",
            expectedValue: "The two orders contain 10 photos, exceeding the limit of 5. Select photos to keep (2/5 selected), then continue."
        ),
    ])
    func resolve_照片上限提示_依位置參數帶入數值(scenario: LocalizedFragmentsCase) {
        // Given
        let totalCount = 10
        let maximumCount = 5
        let selectedCount = 2

        // When
        let resource = LocalizedStringResource(
            "orders.merge.message.photoLimitNotice",
            defaultValue: "\(totalCount)\(maximumCount)\(selectedCount)\(maximumCount)"
        )
        let value = AppLanguage.resolve(resource, locale: scenario.language.locale)

        // Then
        #expect(resource.key == "orders.merge.message.photoLimitNotice")
        #expect(value == scenario.expectedValue)
        #expect(value.contains(scenario.expectedFirstFragment))
        #expect(value.contains(scenario.expectedSecondFragment))
    }

    /// 驗證訂購日期 resource 依所選語言帶入時間戳字串
    ///
    /// - Parameter scenario: 受測語言、輸入情境與固定預期結果
    @Test(arguments: [
        TimestampCase(
            language: .traditionalChinese,
            timestamp: "2026/07/18 12:00",
            expectedValue: "訂購日期：2026/07/18 12:00"
        ),
        TimestampCase(
            language: .english,
            timestamp: "July 18, 2026 at 12:00 PM",
            expectedValue: "Order Date: July 18, 2026 at 12:00 PM"
        ),
    ])
    func resolve_訂購日期_帶入時間戳字串(scenario: TimestampCase) {
        // Given
        let timestamp = scenario.timestamp

        // When
        let resource = LocalizedStringResource(
            "orders.edit.label.orderDateTimestamp",
            defaultValue: "\(timestamp)"
        )
        let value = AppLanguage.resolve(resource, locale: scenario.language.locale)

        // Then
        #expect(resource.key == "orders.edit.label.orderDateTimestamp")
        #expect(value == scenario.expectedValue)
    }

    /// 驗證候選篩選 resource 依所選語言帶入幣別與客戶名稱
    ///
    /// - Parameter scenario: 受測語言、輸入情境與固定預期結果
    @Test(arguments: [
        LocalizedFragmentsCase(
            language: .traditionalChinese,
            expectedFirstFragment: "JPY",
            expectedSecondFragment: "Alice",
            expectedValue: "僅列出與主訂單同幣別 (JPY)、同客戶「Alice」的訂單；選擇後會以兩筆訂單整合的資料開啟確認表單。"
        ),
        LocalizedFragmentsCase(
            language: .english,
            expectedFirstFragment: "JPY",
            expectedSecondFragment: "Alice",
            expectedValue: "Only orders with the same currency (JPY) and customer “Alice” are listed; selecting one opens the confirmation form with merged data."
        ),
    ])
    func resolve_候選篩選提示_帶入幣別與客戶名稱(scenario: LocalizedFragmentsCase) {
        // Given
        let currency = "JPY"
        let customer = "Alice"

        // When
        let resource = LocalizedStringResource(
            "orders.merge.message.candidateFilterNotice",
            defaultValue: "\(currency)\(customer)"
        )
        let value = AppLanguage.resolve(resource, locale: scenario.language.locale)

        // Then
        #expect(resource.key == "orders.merge.message.candidateFilterNotice")
        #expect(value == scenario.expectedValue)
        #expect(value.contains(scenario.expectedFirstFragment))
        #expect(value.contains(scenario.expectedSecondFragment))
    }

    /// 驗證開團訂單摘要依所選語言帶入訂單筆數與金額
    ///
    /// - Parameter scenario: 受測語言、輸入情境與固定預期結果
    @Test(arguments: [
        LocalizedValueCase(language: .traditionalChinese, expectedValue: "12 筆 · NT$3,450"),
        LocalizedValueCase(language: .english, expectedValue: "12 orders · NT$3,450"),
    ])
    func resolve_開團訂單摘要_帶入筆數與金額(scenario: LocalizedValueCase) {
        // Given
        let count = 12
        let amount = "NT$3,450"

        // When
        let resource = LocalizedStringResource(
            "dashboard.overview.label.campaignOrderSummary",
            defaultValue: "\(count)\(amount)"
        )
        let value = scenario.language.resolve(resource)

        // Then
        #expect(resource.key == "dashboard.overview.label.campaignOrderSummary")
        #expect(value == scenario.expectedValue)
    }

    /// 驗證刪除訂單確認訊息依所選語言帶入客戶名稱，且不露出原始 Key
    ///
    /// - Parameter scenario: 受測語言、輸入情境與固定預期結果
    @Test(arguments: [
        LocalizedValueCase(language: .traditionalChinese, expectedValue: "刪除「Alice」的這筆訂單後無法復原。"),
        LocalizedValueCase(
            language: .english,
            expectedValue: "Deleting this order from “Alice” cannot be undone."
        ),
    ])
    func resolve_刪除訂單確認訊息_帶入客戶名稱(scenario: LocalizedValueCase) {
        // Given
        let customer = "Alice"

        // When
        let resource = LocalizedStringResource(
            "orders.detail.message.deleteUndoneNotice",
            defaultValue: "\(customer)"
        )
        let value = scenario.language.resolve(resource)

        // Then
        #expect(resource.key == "orders.detail.message.deleteUndoneNotice")
        #expect(value == scenario.expectedValue)
        #expect(!value.contains("orders.detail"))
    }

    /// 驗證圈狀圖無障礙摘要含本地化項目標籤與金額「NT$41,011」，中英文都不露出原始 key
    ///
    /// - Parameter scenario: 受測語言、輸入情境與固定預期結果
    @Test(arguments: [
        DonutSummaryCase(language: .traditionalChinese, expectedItemCost: "商品金額"),
        DonutSummaryCase(language: .english, expectedItemCost: "Item Cost"),
    ])
    func resolve_圈狀圖無障礙摘要_帶入項目與金額(scenario: DonutSummaryCase) {
        // Given
        let itemCostResource = LocalizedStringResource("orders.detail.label.itemCost")
        let itemCost = scenario.language.resolve(itemCostResource)
        let itemCount = 4
        let amount = "NT$41,011"

        // When
        let resource = LocalizedStringResource(
            "common.ui.accessibility.donutChartSummary",
            defaultValue: "\(itemCount)\(itemCost)\(amount)"
        )
        let value = scenario.language.resolve(resource)

        // Then
        #expect(itemCostResource.key == "orders.detail.label.itemCost")
        #expect(resource.key == "common.ui.accessibility.donutChartSummary")
        #expect(value.contains(scenario.expectedItemCost))
        #expect(value.contains("NT$41,011"))
        #expect(!value.contains("orders.detail.label"))
    }
}

// MARK: - Nested Types

extension LocalizationCatalogAppLanguageTests {

    /// 指定語言與 resource 的固定解析結果
    struct ResolveResourceExample: Sendable {

        /// 每個 resource 在兩種 App 語言下的固定預期案例
        static let examples = [
            Self(
                language: .traditionalChinese,
                resource: LocalizedStringResource("common.action.cancel"),
                expectedKey: "common.action.cancel",
                expectedValue: "取消"
            ),
            Self(
                language: .english,
                resource: LocalizedStringResource("common.action.cancel"),
                expectedKey: "common.action.cancel",
                expectedValue: "Cancel"
            ),
            Self(
                language: .traditionalChinese,
                resource: LocalizedStringResource(
                    "orders.batch.message.selectedCount",
                    defaultValue: "\(0)"
                ),
                expectedKey: "orders.batch.message.selectedCount",
                expectedValue: "已選 0 筆"
            ),
            Self(
                language: .english,
                resource: LocalizedStringResource(
                    "orders.batch.message.selectedCount",
                    defaultValue: "\(0)"
                ),
                expectedKey: "orders.batch.message.selectedCount",
                expectedValue: "0 Selected"
            ),
            Self(
                language: .traditionalChinese,
                resource: LocalizedStringResource(
                    "orders.batch.message.selectedCount",
                    defaultValue: "\(1)"
                ),
                expectedKey: "orders.batch.message.selectedCount",
                expectedValue: "已選 1 筆"
            ),
            Self(
                language: .english,
                resource: LocalizedStringResource(
                    "orders.batch.message.selectedCount",
                    defaultValue: "\(1)"
                ),
                expectedKey: "orders.batch.message.selectedCount",
                expectedValue: "1 Selected"
            ),
            Self(
                language: .traditionalChinese,
                resource: LocalizedStringResource(
                    "orders.batch.message.selectedCount",
                    defaultValue: "\(3)"
                ),
                expectedKey: "orders.batch.message.selectedCount",
                expectedValue: "已選 3 筆"
            ),
            Self(
                language: .english,
                resource: LocalizedStringResource(
                    "orders.batch.message.selectedCount",
                    defaultValue: "\(3)"
                ),
                expectedKey: "orders.batch.message.selectedCount",
                expectedValue: "3 Selected"
            ),
            Self(
                language: .traditionalChinese,
                resource: LocalizedStringResource(
                    "orders.merge.message.photoLimitNotice",
                    defaultValue: "\(10)\(5)\(2)\(5)"
                ),
                expectedKey: "orders.merge.message.photoLimitNotice",
                expectedValue: "兩筆訂單共有 10 張照片，超過上限 5 張；請勾選要保留的照片 (已選 2/5)，按「繼續」帶入合併後的新訂單。"
            ),
            Self(
                language: .english,
                resource: LocalizedStringResource(
                    "orders.merge.message.photoLimitNotice",
                    defaultValue: "\(10)\(5)\(2)\(5)"
                ),
                expectedKey: "orders.merge.message.photoLimitNotice",
                expectedValue: "The two orders contain 10 photos, exceeding the limit of 5. Select photos to keep (2/5 selected), then continue."
            ),
            Self(
                language: .traditionalChinese,
                resource: LocalizedStringResource(
                    "common.general.label.pointLd",
                    defaultValue: "\(1234)"
                ),
                expectedKey: "common.general.label.pointLd",
                expectedValue: "第 1,234 筆"
            ),
            Self(
                language: .english,
                resource: LocalizedStringResource(
                    "common.general.label.pointLd",
                    defaultValue: "\(1234)"
                ),
                expectedKey: "common.general.label.pointLd",
                expectedValue: "Point 1,234"
            ),
        ]

        /// 此案例使用的 App 語言
        let language: AppLanguage

        /// 要解析的 String Catalog resource
        let resource: LocalizedStringResource

        /// 預期的 String Catalog key
        let expectedKey: String

        /// 該語言的字面預期文字
        let expectedValue: String
    }

    /// 同一組標題在指定語言下的固定解析結果
    struct LocalizedTitlesCase: Sendable {

        /// 此案例使用的 App 語言
        let language: AppLanguage

        /// 依輸入順序排列的字面預期標題
        let expectedTitles: [String]
    }

    /// 結構化 Key 在指定語言下的固定預期文字
    struct LocalizedKeyExample: Sendable {

        /// 每個輸入在各語言下的固定預期案例
        static let examples = [
            Self(language: .english, key: "common.action.cancel", expectedValue: "Cancel"),
            Self(language: .traditionalChinese, key: "common.action.cancel", expectedValue: "取消"),
            Self(language: .english, key: "common.action.button.done", expectedValue: "Done"),
            Self(
                language: .traditionalChinese,
                key: "common.action.button.done",
                expectedValue: "完成"
            ),
            Self(language: .english, key: "common.date.today", expectedValue: "Today"),
            Self(language: .traditionalChinese, key: "common.date.today", expectedValue: "今天"),
            Self(language: .english, key: "common.date.yesterday", expectedValue: "Yesterday"),
            Self(language: .traditionalChinese, key: "common.date.yesterday", expectedValue: "昨天"),
            Self(language: .english, key: "orders.list.title", expectedValue: "Orders"),
            Self(language: .traditionalChinese, key: "orders.list.title", expectedValue: "訂單"),
            Self(language: .english, key: "orders.edit.button.save", expectedValue: "Save"),
            Self(
                language: .traditionalChinese,
                key: "orders.edit.button.save",
                expectedValue: "儲存"
            ),
            Self(language: .english, key: "common.action.button.retry", expectedValue: "Retry"),
            Self(
                language: .traditionalChinese,
                key: "common.action.button.retry",
                expectedValue: "重試"
            ),
            Self(
                language: .english,
                key: "orders.filter.status.pendingPayment",
                expectedValue: "Pending Payment"
            ),
            Self(
                language: .traditionalChinese,
                key: "orders.filter.status.pendingPayment",
                expectedValue: "待收款"
            ),
        ]

        /// 此案例使用的 App 語言
        let language: AppLanguage

        /// 要解析的結構化 Key
        let key: LocalizedStringResource

        /// 該語言的字面預期文字
        let expectedValue: String
    }

    /// 選取筆數在指定語言下的單複數預期文字
    struct SelectedCountExample: Sendable {

        /// 每個輸入在各語言下的固定預期案例
        static let examples = [
            Self(language: .english, count: 1, expectedValue: "1 Selected"),
            Self(language: .traditionalChinese, count: 1, expectedValue: "已選 1 筆"),
            Self(language: .english, count: 2, expectedValue: "2 Selected"),
            Self(language: .traditionalChinese, count: 2, expectedValue: "已選 2 筆"),
        ]

        /// 此案例使用的 App 語言
        let language: AppLanguage

        /// 選取的訂單筆數
        let count: Int

        /// 該語言的字面預期文字
        let expectedValue: String
    }

    /// 訂單頁指定選取狀態與語言的固定預期標題
    struct OrdersNavigationTitleExample: Sendable {

        /// 每個輸入在各語言下的固定預期案例
        static let examples = [
            Self(
                language: .english,
                isSelecting: false,
                selectedOrderIDs: [],
                expectedTitle: "Orders",
                expectedKey: "orders.list.title"
            ),
            Self(
                language: .traditionalChinese,
                isSelecting: false,
                selectedOrderIDs: [],
                expectedTitle: "訂單",
                expectedKey: "orders.list.title"
            ),
            Self(
                language: .english,
                isSelecting: true,
                selectedOrderIDs: [],
                expectedTitle: "Select Orders",
                expectedKey: "orders.edit.label.selectOrders"
            ),
            Self(
                language: .traditionalChinese,
                isSelecting: true,
                selectedOrderIDs: [],
                expectedTitle: "選擇訂單",
                expectedKey: "orders.edit.label.selectOrders"
            ),
            Self(
                language: .english,
                isSelecting: true,
                selectedOrderIDs: ["O1", "O2"],
                expectedTitle: "2 Selected",
                expectedKey: "orders.batch.message.selectedCount"
            ),
            Self(
                language: .traditionalChinese,
                isSelecting: true,
                selectedOrderIDs: ["O1", "O2"],
                expectedTitle: "已選 2 筆",
                expectedKey: "orders.batch.message.selectedCount"
            ),
        ]

        /// 此案例使用的 App 語言
        let language: AppLanguage

        /// 是否處於選取模式
        let isSelecting: Bool

        /// 已選取的訂單識別碼
        let selectedOrderIDs: Set<LedgerOrder.ID>

        /// 該語言的字面預期標題
        let expectedTitle: String

        /// 預期的 String Catalog key
        let expectedKey: String
    }

    /// 指定語言下的本地化插值片段與完整預期文字
    struct LocalizedFragmentsCase: Sendable {

        /// 此案例使用的 App 語言
        let language: AppLanguage

        /// 結果須包含的第一段字面文字
        let expectedFirstFragment: String

        /// 結果須包含的第二段字面文字
        let expectedSecondFragment: String

        /// 依該語言解析後的完整預期文字
        let expectedValue: String
    }

    /// 指定語言下的時間戳輸入與固定預期標籤
    struct TimestampCase: Sendable {

        /// 此案例使用的 App 語言
        let language: AppLanguage

        /// 要帶入標籤的時間戳文字
        let timestamp: String

        /// 包含時間戳的字面預期標籤
        let expectedValue: String
    }

    /// 指定語言下的完整本地化字面預期
    struct LocalizedValueCase: Sendable {

        /// 此案例使用的 App 語言
        let language: AppLanguage

        /// 該語言的完整預期文字
        let expectedValue: String
    }

    /// 圈狀圖摘要在指定語言下的字面預期項目標籤
    struct DonutSummaryCase: Sendable {

        /// 此案例使用的 App 語言
        let language: AppLanguage

        /// 摘要須包含的本地化商品金額標籤
        let expectedItemCost: String
    }
}
