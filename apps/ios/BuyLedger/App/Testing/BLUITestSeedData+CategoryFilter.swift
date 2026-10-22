//
//  BLUITestSeedData+CategoryFilter.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/18.
//

import Foundation
import SwiftData

#if DEBUG

// MARK: - Internal Method

extension BLUITestSeedData {

    /// 寫入 `categoryFilter` 的主檔、開團與訂單
    ///
    /// - Parameters:
    ///   - context: 寫入用的 context
    ///   - referenceDate: 推導日期的基準時間點
    /// - Note: 使用基本六種付款方式與此情境的八個商品類別
    static func seedCategoryFilter(into context: ModelContext, referenceDate: Date) {
        insertLookups(into: context, categoryNames: categoryFilterCategoryNames)
        for campaign in makeCategoryFilterCampaigns(referenceDate: referenceDate) {
            context.insert(CampaignRecord(campaign: campaign))
        }
        insertOrders(makeCategoryFilterOrders(referenceDate: referenceDate), into: context)
    }
}

// MARK: - Private Method

private extension BLUITestSeedData {

    /// 提供 `categoryFilter` 情境的八個商品類別
    ///
    /// - Note: 以 2026-04-30 UTC 為參考時間，預期分組如下
    ///   - 開團中：「美妝」、「3C」、「零食」
    ///   - 已收單：「書籍」、「aespa Lemonade QQ 音樂限定禮包」、「服飾」、「精品」、「生活雜貨」
    static var categoryFilterCategoryNames: [String] {
        categoryNames + [
            "3C",
            "零食",
            "書籍",
            "aespa Lemonade QQ 音樂限定禮包",
        ]
    }

    /// 分類篩選情境的進行中開團甲
    static var categoryFilterCampaignA: String {
        "分類驗收進行中甲"
    }

    /// 分類篩選情境的進行中開團乙
    static var categoryFilterCampaignB: String {
        "分類驗收進行中乙"
    }

    /// 分類篩選情境的已收單開團丙
    static var categoryFilterCampaignC: String {
        "分類驗收已收團丙"
    }

    /// 產生 `categoryFilter` 的開團：兩個進行中 (甲、乙) 與一個已收單 (丙)
    ///
    /// - Parameter referenceDate: 推導日期的基準時間點
    /// - Returns: 分類篩選一般情境的開團種子
    static func makeCategoryFilterCampaigns(referenceDate: Date) -> [Campaign] {
        [
            Campaign(
                id: "UITEST-CF-CMP-A",
                name: categoryFilterCampaignA,
                openDate: date(daysBefore: 20, from: referenceDate),
                closeDate: date(daysBefore: -15, from: referenceDate),
                status: .ongoing,
                settledDate: nil,
                notes: ""
            ),
            Campaign(
                id: "UITEST-CF-CMP-B",
                name: categoryFilterCampaignB,
                openDate: date(daysBefore: 12, from: referenceDate),
                closeDate: date(daysBefore: -5, from: referenceDate),
                status: .ongoing,
                settledDate: nil,
                notes: ""
            ),
            Campaign(
                id: "UITEST-CF-CMP-C",
                name: categoryFilterCampaignC,
                openDate: date(daysBefore: 30, from: referenceDate),
                closeDate: date(daysBefore: 20, from: referenceDate),
                status: .closed,
                settledDate: date(daysBefore: 5, from: referenceDate),
                notes: ""
            ),
        ]
    }

    /// 產生 `categoryFilter` 的 10 筆訂單
    ///
    /// - Parameter referenceDate: 推導日期的基準時間點
    /// - Returns: 分類篩選一般情境的訂單種子
    /// - Note: 以 2026-04-30 UTC 為參考時間，預期篩選結果如下
    ///   - 不限條件：10 筆
    ///   - 本月、信用卡、類別 {美妝, 書籍}：4 筆，依序為
    ///     「UITEST-CF-001」、「UITEST-CF-004」、「UITEST-CF-007」、「UITEST-CF-010」
    static func makeCategoryFilterOrders(referenceDate: Date) -> [LedgerOrder] {
        [
            makeCategoryFilterOrder(
                number: 1,
                categories: ["美妝"],
                paymentMethod: "信用卡",
                daysBefore: 2,
                campaignName: categoryFilterCampaignA,
                referenceDate: referenceDate
            ),
            makeCategoryFilterOrder(
                number: 2,
                categories: ["3C"],
                paymentMethod: "信用卡",
                daysBefore: 3,
                campaignName: categoryFilterCampaignA,
                referenceDate: referenceDate
            ),
            makeCategoryFilterOrder(
                number: 3,
                categories: ["美妝"],
                paymentMethod: "銀行轉帳",
                daysBefore: 4,
                campaignName: categoryFilterCampaignB,
                referenceDate: referenceDate
            ),
            makeCategoryFilterOrder(
                number: 4,
                categories: ["書籍"],
                paymentMethod: "信用卡",
                daysBefore: 5,
                campaignName: categoryFilterCampaignC,
                referenceDate: referenceDate
            ),
            makeCategoryFilterOrder(
                number: 5,
                categories: ["aespa Lemonade QQ 音樂限定禮包"],
                paymentMethod: "信用卡",
                daysBefore: 6,
                campaignName: categoryFilterCampaignC,
                referenceDate: referenceDate
            ),
            makeCategoryFilterOrder(
                number: 6,
                categories: ["美妝"],
                paymentMethod: "信用卡",
                daysBefore: 40,
                campaignName: categoryFilterCampaignA,
                referenceDate: referenceDate
            ),
            makeCategoryFilterOrder(
                number: 7,
                categories: ["美妝"],
                paymentMethod: "信用卡",
                daysBefore: 10,
                campaignName: nil,
                referenceDate: referenceDate
            ),
            makeCategoryFilterOrder(
                number: 8,
                categories: ["零食"],
                paymentMethod: "信用卡",
                daysBefore: 8,
                campaignName: categoryFilterCampaignB,
                referenceDate: referenceDate
            ),
            makeCategoryFilterOrder(
                number: 9,
                categories: ["書籍"],
                paymentMethod: "無卡",
                daysBefore: 9,
                campaignName: categoryFilterCampaignC,
                referenceDate: referenceDate
            ),
            makeCategoryFilterOrder(
                number: 10,
                categories: ["美妝"],
                paymentMethod: "信用卡",
                daysBefore: 12,
                campaignName: categoryFilterCampaignB,
                referenceDate: referenceDate
            ),
        ]
    }

    /// 組出分類篩選情境的單筆訂單，編號即訂單識別值後三碼
    ///
    /// - Parameters:
    ///   - number: 訂單序號，從 1 起算
    ///   - categories: 訂單的商品類別
    ///   - paymentMethod: 付款方式名稱
    ///   - daysBefore: 訂單日期距參考日的天數
    ///   - campaignName: 歸屬的開團名稱，nil 代表未歸團
    ///   - referenceDate: 推導日期的基準時間點
    /// - Returns: 組出的訂單
    static func makeCategoryFilterOrder(
        number: Int,
        categories: [String],
        paymentMethod: String,
        daysBefore: Int,
        campaignName: String?,
        referenceDate: Date
    ) -> LedgerOrder {
        makeOrder(
            id: String(format: "UITEST-CF-%03d", number),
            customer: makeCustomer("分類驗收客", "CF"),
            status: .confirmed,
            date: date(daysBefore: daysBefore, from: referenceDate),
            items: [
                makeItem(
                    seed: 9_000 + number,
                    name: categories.joined(separator: "、"),
                    quantity: 1,
                    unitPrice: 1_000
                ),
            ],
            itemCost: 1_000,
            categories: categories,
            paymentMethod: paymentMethod,
            chargedAmount: 1_500,
            campaignNames: campaignName.map { [$0] } ?? [],
            paymentReceiptStatus: .pending
        )
    }
}

#endif
