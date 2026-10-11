//
//  LocalizationCatalogTests+AppLanguage.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation
import Testing

@testable import BuyLedger

extension LocalizationCatalogTests {

    /// 根分頁標題依所選 App 語言解析為對應的英文或正體中文
    @Test
    func localized_根導覽標題_依所選語言解析() {
        // Given
        let titles: [String.LocalizationValue] = ["dashboard.overview.title.overview", "orders.list.title", "orders.detail.title.campaigns", "orders.filter.title.insights", "common.action.label.more"]

        // When
        let englishTitles = titles.map { AppLanguage.english.localized($0) }
        let chineseTitles = titles.map { AppLanguage.traditionalChinese.localized($0) }

        // Then
        #expect(englishTitles == ["Overview", "Orders", "Campaigns", "Insights", "More"])
        #expect(chineseTitles == ["總覽", "訂單", "開團", "分析", "更多"])
    }

    /// 圖表的本地化軸標題與資料序列名稱依所選 App 語言解析
    @Test
    func localized_圖表描述字串_依所選語言解析() {
        // Given
        let ordinal = 3
        let titles: [String.LocalizationValue] = [
            "orders.list.label.text",
            "orders.detail.label.value",
            "orders.list.label.sequence",
            "orders.list.label.category2",
            "orders.detail.label.share",
            "insights.chart.label.barChart",
            "orders.detail.label.donutChart",
            "dashboard.overview.label.trendChart",
            "common.general.label.pointLd \(ordinal)",
        ]

        // When
        let englishTitles = titles.map { AppLanguage.english.localized($0) }
        let chineseTitles = titles.map { AppLanguage.traditionalChinese.localized($0) }

        // Then
        #expect(
            englishTitles == [
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
        )
        #expect(
            chineseTitles == [
                "項目",
                "數值",
                "順序",
                "類別",
                "占比",
                "長條圖",
                "圈狀圖",
                "走勢圖",
                "第 3 筆",
            ]
        )
    }

    /// 訂單頁導覽標題依選取狀態變化，並依所選 App 語言解析
    ///
    /// - Parameter example: 選取狀態與預期的中英文標題
    @Test(arguments: OrdersNavigationTitleExample.examples)
    func navigationTitleKey_各選取狀態_依所選語言解析(example: OrdersNavigationTitleExample) {
        // Given
        var state = OrderListFeatureTests.makeState()
        state.isSelecting = example.isSelecting
        state.selectedOrderIDs = example.selectedOrderIDs

        // When
        let englishTitle = AppLanguage.english.localized(state.navigationTitleKey)
        let chineseTitle = AppLanguage.traditionalChinese.localized(state.navigationTitleKey)

        // Then
        #expect(englishTitle == example.expectedEnglishTitle)
        #expect(chineseTitle == example.expectedChineseTitle)
    }

    /// 英文語系的 7 月 18 日規格範例不含中文日期文字
    ///
    /// - Throws: 測試日期建立失敗時丟出錯誤
    @Test
    func daySectionTitle_英文語系的七月十八日_標題不含中文日期文字() throws(any Error) {
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

        // When
        let title = OrderFormatters.daySectionTitle(
            for: reportedDate,
            referenceDate: referenceDate,
            calendar: calendar,
            locale: Locale(identifier: "en")
        )

        // Then
        #expect(title.contains("July"))
        #expect(title.range(of: "[\\u{3400}-\\u{9FFF}]", options: .regularExpression) == nil)
    }

    /// 結構化英文 Key 依所選 App 語言正確解析為中英文
    @Test
    func localized_結構化英文Key_依所選語言解析() {
        // Given
        let keys: [(key: String.LocalizationValue, en: String, zh: String)] = [
            ("common.action.cancel", "Cancel", "取消"),
            ("common.action.confirm", "Confirm", "確認"),
            ("common.date.today", "Today", "今天"),
            ("common.date.yesterday", "Yesterday", "昨天"),
            ("orders.list.title", "Orders", "訂單"),
            ("orders.edit.button.save", "Save", "儲存"),
            ("orders.edit.button.saveAndContinue", "Save and Continue", "儲存並繼續新增"),
            ("orders.filter.status.pendingPayment", "Pending Payment", "待收款"),
        ]

        // When & Then
        for item in keys {
            let enValue = AppLanguage.english.localized(item.key)
            let zhValue = AppLanguage.traditionalChinese.localized(item.key)
            #expect(enValue == item.en, "Key \(item.key) 英文解析失敗")
            #expect(zhValue == item.zh, "Key \(item.key) 中文解析失敗")
        }
    }

    /// 帶位置標記與 Plural 的結構化 Key 依所選語言正確解析
    @Test
    func localized_多參數位置標記與單複數Key_解析正確() {
        // Given & When
        let zhSelectedOne = AppLanguage.traditionalChinese.localizedString(forKey: "orders.batch.message.selectedCount", 1)
        let enSelectedOne = AppLanguage.english.localizedString(forKey: "orders.batch.message.selectedCount", 1)
        let zhSelectedTwo = AppLanguage.traditionalChinese.localizedString(forKey: "orders.batch.message.selectedCount", 2)
        let enSelectedTwo = AppLanguage.english.localizedString(forKey: "orders.batch.message.selectedCount", 2)

        let zhPhotoNotice = AppLanguage.traditionalChinese.localizedString(
            forKey: "orders.merge.message.photoLimitNotice",
            10, 5, 2, 5
        )
        let enPhotoNotice = AppLanguage.english.localizedString(
            forKey: "orders.merge.message.photoLimitNotice",
            10, 5, 2, 5
        )

        let zhOrderDate = AppLanguage.traditionalChinese.localizedString(
            forKey: "orders.edit.label.orderDateTimestamp",
            "2026/07/18 12:00"
        )
        let enOrderDate = AppLanguage.english.localizedString(
            forKey: "orders.edit.label.orderDateTimestamp",
            "July 18, 2026 at 12:00 PM"
        )

        let zhCandidateNotice = AppLanguage.traditionalChinese.localizedString(
            forKey: "orders.merge.message.candidateFilterNotice",
            "JPY", "Alice"
        )
        let enCandidateNotice = AppLanguage.english.localizedString(
            forKey: "orders.merge.message.candidateFilterNotice",
            "JPY", "Alice"
        )

        let zhCampaignSummary = AppLanguage.traditionalChinese.localizedString(
            forKey: "dashboard.overview.label.campaignOrderSummary",
            12, "NT$3,450"
        )
        let enCampaignSummary = AppLanguage.english.localizedString(
            forKey: "dashboard.overview.label.campaignOrderSummary",
            12, "NT$3,450"
        )

        // Then
        #expect(zhSelectedOne == "已選 1 筆")
        #expect(zhSelectedTwo == "已選 2 筆")
        #expect(enSelectedOne == "1 Selected")
        #expect(enSelectedTwo == "2 Selected")
        #expect(zhPhotoNotice.contains("共有 10 張照片，超過上限 5 張"))
        #expect(zhPhotoNotice.contains("已選 2/5"))
        #expect(enPhotoNotice.contains("contain 10 photos, exceeding the limit of 5"))
        #expect(enPhotoNotice.contains("2/5 selected"))

        #expect(zhOrderDate == "訂購日期：2026/07/18 12:00")
        #expect(enOrderDate == "Order Date: July 18, 2026 at 12:00 PM")

        #expect(zhCandidateNotice.contains("JPY"))
        #expect(zhCandidateNotice.contains("Alice"))
        #expect(enCandidateNotice.contains("JPY"))
        #expect(enCandidateNotice.contains("Alice"))

        #expect(zhCampaignSummary == "12 筆 · NT$3,450")
        #expect(enCampaignSummary == "12 orders · NT$3,450")
    }

    /// 帶引數的確認訊息與圈狀圖無障礙摘要依所選語言正確格式化且不露出原始 Key
    @Test
    func localizedString_帶引數訊息與圈狀圖摘要_依所選語言正確解析() {
        // Given
        let customer = "Alice"
        let zhDeleteNotice = AppLanguage.traditionalChinese.localizedString(
            forKey: "orders.detail.message.deleteUndoneNotice",
            customer
        )
        let enDeleteNotice = AppLanguage.english.localizedString(
            forKey: "orders.detail.message.deleteUndoneNotice",
            customer
        )

        let zhItemCost = AppLanguage.traditionalChinese.localizedString(forKey: "orders.detail.label.itemCost")
        let enItemCost = AppLanguage.english.localizedString(forKey: "orders.detail.label.itemCost")

        let zhDonutSummary = AppLanguage.traditionalChinese.localizedString(
            forKey: "common.ui.accessibility.donutChartSummary",
            4, zhItemCost, "NT$41,011"
        )
        let enDonutSummary = AppLanguage.english.localizedString(
            forKey: "common.ui.accessibility.donutChartSummary",
            4, enItemCost, "NT$41,011"
        )

        // Then
        #expect(zhDeleteNotice == "刪除「Alice」的這筆訂單後無法復原。")
        #expect(enDeleteNotice == "Deleting this order from “Alice” cannot be undone.")
        #expect(!zhDeleteNotice.contains("orders.detail"))
        #expect(!enDeleteNotice.contains("orders.detail"))

        #expect(zhDonutSummary.contains("商品金額"))
        #expect(enDonutSummary.contains("Item Cost"))
        #expect(!zhDonutSummary.contains("orders.detail.label"))
        #expect(!enDonutSummary.contains("orders.detail.label"))
    }
}

// MARK: - Nested Types

extension LocalizationCatalogTests {

    /// 訂單頁導覽標題在各選取狀態下的預期中英文標題
    struct OrdersNavigationTitleExample: Sendable {

        /// 預設、選取模式與已選兩筆三種狀態
        static let examples = [
            Self(
                isSelecting: false,
                selectedOrderIDs: [],
                expectedEnglishTitle: "Orders",
                expectedChineseTitle: "訂單"
            ),
            Self(
                isSelecting: true,
                selectedOrderIDs: [],
                expectedEnglishTitle: "Select Orders",
                expectedChineseTitle: "選擇訂單"
            ),
            Self(
                isSelecting: true,
                selectedOrderIDs: ["O1", "O2"],
                expectedEnglishTitle: "2 Selected",
                expectedChineseTitle: "已選 2 筆"
            ),
        ]

        /// 是否處於選取模式
        let isSelecting: Bool

        /// 已選取的訂單識別碼
        let selectedOrderIDs: Set<LedgerOrder.ID>

        /// 預期的英文標題
        let expectedEnglishTitle: String

        /// 預期的正體中文標題
        let expectedChineseTitle: String
    }
}
