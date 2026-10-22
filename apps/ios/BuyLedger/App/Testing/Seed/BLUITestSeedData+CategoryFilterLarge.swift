//
//  BLUITestSeedData+CategoryFilterLarge.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/18.
//

import Foundation
import SwiftData

#if DEBUG

// MARK: - Internal Method

extension BLUITestSeedData {

    /// 寫入 `categoryFilterLarge` 的主檔、開團與訂單
    ///
    /// - Parameters:
    ///   - context: 寫入用的 `context`
    ///   - referenceDate: 推導日期的基準時間點
    /// - Note: 商品類別與付款方式僅使用大量情境的 300 類與 30 種選項
    static func seedCategoryFilterLarge(into context: ModelContext, referenceDate: Date) {
        insertLookups(
            into: context,
            categoryNames: categoryFilterLargeCategoryNames,
            paymentMethods: categoryFilterLargePaymentMethods
        )
        for campaign in makeCategoryFilterLargeCampaigns(referenceDate: referenceDate) {
            context.insert(CampaignRecord(campaign: campaign))
        }
        insertOrders(makeCategoryFilterLargeOrders(referenceDate: referenceDate), into: context)
    }
}

// MARK: - Private Method

private extension BLUITestSeedData {

    /// 提供 `categoryFilterLarge` 的商品類別主檔「類別 001」至「類別 300」
    ///
    /// - Note: 以 2026-04-30 UTC 為參考時間，「類別 001」至「類別 005」屬開團中，其餘 295 個屬已收單
    static var categoryFilterLargeCategoryNames: [String] {
        (1...300).map { String(format: "類別 %03d", $0) }
    }

    /// `categoryFilterLarge` 的付款方式主檔，「付款方式 01」至「付款方式 30」，皆非無卡、非銀行轉帳、非貨到付款
    static var categoryFilterLargePaymentMethods: [PaymentMethodSeed] {
        (1...30).map {
            PaymentMethodSeed(
                name: String(format: "付款方式 %02d", $0),
                isCardless: false,
                isBankTransfer: false,
                isCashOnDelivery: false
            )
        }
    }

    /// 大量分類情境的進行中開團名稱
    static var categoryFilterLargeCampaignName: String {
        "分類驗收大量進行中團"
    }

    /// 產生 `categoryFilterLarge` 的進行中開團，只有前五筆訂單歸屬於它
    ///
    /// - Parameter referenceDate: 推導日期的基準時間點
    /// - Returns: 大量分類情境的進行中開團
    static func makeCategoryFilterLargeCampaigns(referenceDate: Date) -> [Campaign] {
        [
            Campaign(
                id: "UITEST-CFL-CMP",
                name: categoryFilterLargeCampaignName,
                openDate: date(daysBefore: 20, from: referenceDate),
                closeDate: date(daysBefore: -15, from: referenceDate),
                status: .ongoing,
                settledDate: nil,
                notes: ""
            ),
        ]
    }

    /// 產生 `categoryFilterLarge` 的 300 筆訂單，每個類別各一筆
    ///
    /// - Parameter referenceDate: 推導日期的基準時間點
    /// - Returns: 大量分類情境的訂單種子
    /// - Note: 前五筆歸屬大量進行中團，其餘未歸團
    /// - Note: 依序輪流使用 30 種付款方式
    /// - Note: 訂單日期介於參考日前 1 至 28 天
    static func makeCategoryFilterLargeOrders(referenceDate: Date) -> [LedgerOrder] {
        let paymentMethods = categoryFilterLargePaymentMethods

        return categoryFilterLargeCategoryNames.enumerated().map { index, category in
            let number = index + 1
            return makeCategoryFilterLargeOrder(
                number: number,
                category: category,
                paymentMethod: paymentMethods[index % paymentMethods.count].name,
                daysBefore: index % 28 + 1,
                campaignName: number <= 5 ? categoryFilterLargeCampaignName : nil,
                referenceDate: referenceDate
            )
        }
    }

    /// 組出大量分類情境的單筆訂單
    ///
    /// - Parameters:
    ///   - number: 訂單序號，從 1 起算
    ///   - category: 訂單的商品類別
    ///   - paymentMethod: 付款方式名稱
    ///   - daysBefore: 訂單日期距參考日的天數
    ///   - campaignName: 歸屬的開團名稱，`nil` 代表未歸團
    ///   - referenceDate: 推導日期的基準時間點
    /// - Returns: 組出的訂單
    static func makeCategoryFilterLargeOrder(
        number: Int,
        category: String,
        paymentMethod: String,
        daysBefore: Int,
        campaignName: String?,
        referenceDate: Date
    ) -> LedgerOrder {
        makeOrder(
            id: String(format: "UITEST-CFL-%03d", number),
            customer: makeCustomer("大量驗收客", "CL"),
            status: .confirmed,
            date: date(daysBefore: daysBefore, from: referenceDate),
            items: [
                makeItem(
                    seed: 10_000 + number,
                    name: category,
                    quantity: 1,
                    unitPrice: 1_000
                ),
            ],
            itemCost: 1_000,
            categories: [category],
            paymentMethod: paymentMethod,
            chargedAmount: 1_500,
            campaignNames: campaignName.map { [$0] } ?? [],
            paymentReceiptStatus: .pending
        )
    }
}

#endif
