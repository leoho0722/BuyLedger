//
//  BLUITestSeedData+Campaigns.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/17.
//

import Foundation

#if DEBUG

// MARK: - Internal Method

extension BLUITestSeedData {

    /// 產生 `revenueAttribution` 的開團資料
    ///
    /// - Parameter referenceDate: 推導日期的基準時間點
    /// - Returns: 供營收歸屬驗收的兩筆開團
    static func makeRevenueAttributionCampaigns(referenceDate: Date) -> [Campaign] {
        [
            Campaign(
                id: "UITEST-REV-CAM-001",
                name: "營收驗收美妝團",
                openDate: date(daysBefore: 10, from: referenceDate),
                closeDate: nil,
                status: .ongoing,
                settledDate: nil,
                notes: ""
            ),
            Campaign(
                id: "UITEST-REV-CAM-002",
                name: "營收驗收服飾團",
                openDate: date(daysBefore: 10, from: referenceDate),
                closeDate: nil,
                status: .ongoing,
                settledDate: nil,
                notes: ""
            ),
        ]
    }

    /// 產生 `revenueAttribution` 的訂單：兩筆來源訂單與一筆合併結果
    ///
    /// - Parameters:
    ///   - referenceDate: 推導日期的基準時間點
    ///   - campaigns: 已寫入的開團，依序對應兩筆來源訂單
    /// - Returns: 供總覽、趨勢、類別與開團排行交叉核對的訂單
    static func makeRevenueAttributionOrders(
        referenceDate: Date,
        campaigns: [Campaign]
    ) -> [LedgerOrder] {
        guard campaigns.count >= 2 else {
            return []
        }

        let firstSourceID = "UITEST-REV-001"
        let secondSourceID = "UITEST-REV-002"

        let firstSource = makeOrder(
            id: firstSourceID,
            customer: makeCustomer("營收驗收甲", "RA"),
            status: .delivered,
            date: date(daysBefore: 1, from: referenceDate),
            items: [
                makeItem(
                    seed: 701,
                    name: "營收驗收美妝品",
                    quantity: 1,
                    unitPrice: 6_000
                ),
            ],
            itemCost: 6_000,
            categories: ["美妝"],
            chargedAmount: 10_000,
            campaignNames: [campaigns[0].name],
            paymentReceiptStatus: .received
        )

        let secondSource = makeOrder(
            id: secondSourceID,
            customer: makeCustomer("營收驗收乙", "RB"),
            status: .delivered,
            date: date(daysBefore: 2, from: referenceDate),
            items: [
                makeItem(
                    seed: 702,
                    name: "營收驗收服飾品",
                    quantity: 1,
                    unitPrice: 5_000
                ),
            ],
            itemCost: 5_000,
            categories: ["服飾"],
            chargedAmount: 8_000,
            campaignNames: [campaigns[1].name],
            paymentReceiptStatus: .received
        )

        let mergeResult = makeOrder(
            id: "UITEST-REV-RESULT",
            customer: makeCustomer("營收驗收合併", "RC"),
            status: .delivered,
            date: date(daysBefore: 0, from: referenceDate),
            items: [
                makeItem(
                    seed: 703,
                    name: "營收驗收合併品",
                    quantity: 1,
                    unitPrice: 11_000
                ),
            ],
            itemCost: 11_000,
            orderSource: "官方網站",
            categories: [],
            chargedAmount: 18_000,
            campaignNames: [],
            paymentReceiptStatus: .received,
            mergedSourceIDs: [firstSourceID, secondSourceID]
        )

        return [firstSource, secondSource, mergeResult]
    }

    /// 把 `Campaign.sampleCampaigns` 改寫成相對日期，產生 `campaignsWithOrders` 的開團 (共 2 筆)
    ///
    /// - Parameter referenceDate: 推導日期的基準時間點
    /// - Returns: 開團種子
    static func makeCampaigns(referenceDate: Date) -> [Campaign] {
        let schedules: [(open: Int, close: Int, settled: Int?)] = [
            (open: 20, close: -7, settled: nil),
            (open: 60, close: 45, settled: 25),
        ]

        return zip(Campaign.sampleCampaigns, schedules).map { campaign, schedule in
            Campaign(
                id: campaign.id,
                name: campaign.name,
                openDate: date(daysBefore: schedule.open, from: referenceDate),
                closeDate: date(daysBefore: schedule.close, from: referenceDate),
                status: campaign.status,
                settledDate: schedule.settled.map {
                    date(daysBefore: $0, from: referenceDate)
                },
                notes: campaign.notes
            )
        }
    }

    /// 產生 `campaignsWithOrders` 的訂單資料
    ///
    /// - Parameters:
    ///   - referenceDate: 推導日期的基準時間點
    ///   - campaigns: 已寫入的開團
    /// - Returns: 歸屬到指定開團的訂單種子
    static func makeCampaignOrders(referenceDate: Date, campaigns: [Campaign]) -> [LedgerOrder] {
        let orders = makeFullOrders(referenceDate: referenceDate)

        guard campaigns.count >= 2 else {
            print("[BuyLedger][UITest] 開團少於 2 筆，campaignsWithOrders 的訂單改為全部未歸團")

            return orders
        }

        let assignments: [(name: String, receipt: PaymentReceiptStatus, daysBefore: Int)] = [
            (name: campaigns[0].name, receipt: .received, daysBefore: 4),
            (name: campaigns[0].name, receipt: .pending, daysBefore: 6),
            (name: campaigns[1].name, receipt: .received, daysBefore: 50),
            (name: campaigns[0].name, receipt: .received, daysBefore: 9),
        ]

        let assigned = zip(orders.prefix(assignments.count), assignments).map { order, assignment in
            rebuild(
                order,
                date: date(daysBefore: assignment.daysBefore, from: referenceDate),
                campaignNames: [assignment.name],
                paymentReceiptStatus: assignment.receipt
            )
        }

        return assigned + orders.dropFirst(assignments.count)
    }
}

#endif
