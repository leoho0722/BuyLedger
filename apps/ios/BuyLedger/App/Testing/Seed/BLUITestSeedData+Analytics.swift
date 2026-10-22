//
//  BLUITestSeedData+Analytics.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/17.
//

import Foundation

#if DEBUG

// MARK: - Internal Method

extension BLUITestSeedData {

    /// 產生 `customerRanking` 的訂單：4 位客戶、金額高低差明顯的 5 筆 (第 1 位客戶佔 2 筆)
    ///
    /// - Parameter referenceDate: 推導日期的基準時間點
    /// - Returns: 供客戶排行的訂單種子
    static func makeCustomerRankingOrders(referenceDate: Date) -> [LedgerOrder] {
        let entries: [(
            id: String,
            name: String,
            initials: String,
            tier: CustomerTier,
            daysBefore: Int,
            charged: Decimal,
            cost: Decimal
        )] = [
            (
                id: "UITEST-RNK-001",
                name: "林書宇",
                initials: "SY",
                tier: .vip,
                daysBefore: 2,
                charged: 60_000,
                cost: 36_000
            ),
            (
                id: "UITEST-RNK-002",
                name: "林書宇",
                initials: "SY",
                tier: .vip,
                daysBefore: 5,
                charged: 20_000,
                cost: 12_000
            ),
            (
                id: "UITEST-RNK-003",
                name: "Mika 周",
                initials: "MZ",
                tier: .regular,
                daysBefore: 3,
                charged: 45_000,
                cost: 27_000
            ),
            (
                id: "UITEST-RNK-004",
                name: "Ariel 陳",
                initials: "AC",
                tier: .regular,
                daysBefore: 4,
                charged: 24_000,
                cost: 14_000
            ),
            (
                id: "UITEST-RNK-005",
                name: "Iris 楊",
                initials: "IY",
                tier: .new,
                daysBefore: 6,
                charged: 12_000,
                cost: 7_000
            ),
        ]

        return entries.enumerated().map { index, entry in
            makeOrder(
                id: entry.id,
                customer: makeCustomer(entry.name, entry.initials, tier: entry.tier),
                status: .delivered,
                date: date(daysBefore: entry.daysBefore, from: referenceDate),
                items: [
                    makeItem(
                        seed: 400 + index,
                        name: "代購商品 \(index + 1)",
                        quantity: 1,
                        unitPrice: entry.cost
                    ),
                ],
                itemCost: entry.cost,
                chargedAmount: entry.charged
            )
        }
    }

    /// 產生 `insightsRange` 的訂單：自參考日往前 12 個月每月各 1 筆 (共 12 筆)，金額逐月遞減
    ///
    /// - Parameter referenceDate: 推導日期的基準時間點
    /// - Returns: 供分析區間的訂單種子
    static func makeInsightsRangeOrders(referenceDate: Date) -> [LedgerOrder] {
        (0..<12).map { offset in
            let charged = Decimal(30_000 - offset * 2_000)
            let cost = Decimal(18_000 - offset * 1_200)

            return makeOrder(
                id: String(format: "UITEST-INS-%03d", offset + 1),
                customer: makeCustomer("Vivi 王", "VW"),
                status: .delivered,
                date: date(monthsBefore: offset, from: referenceDate),
                items: [
                    makeItem(
                        seed: 500 + offset,
                        name: "月度代購商品 \(offset + 1)",
                        quantity: 1,
                        unitPrice: cost
                    ),
                ],
                itemCost: cost,
                orderSource: orderSourceNames[offset % orderSourceNames.count],
                categories: [categoryNames[offset % categoryNames.count]],
                chargedAmount: charged
            )
        }
    }
}

#endif
