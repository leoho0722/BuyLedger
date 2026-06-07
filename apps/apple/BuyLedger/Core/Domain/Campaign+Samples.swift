//
//  Campaign+Samples.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation

extension Campaign {

    // MARK: - Sample Data

    /// SwiftUI Preview 與單元測試使用的開團範例。
    ///
    /// **runtime 不會自動 seed**——`CampaignRepository.liveValue` 預設不填充 sample 資料，使用者首次啟動會看到空狀態。
    nonisolated static let sampleCampaigns: [Campaign] = [
        Campaign(
            id: "CMP-SAMPLE-KR-APR",
            name: "四月韓國團",
            openDate: sampleDate(year: 2026, month: 4, day: 10),
            closeDate: sampleDate(year: 2026, month: 4, day: 30),
            status: .ongoing,
            settledDate: nil,
            notes: "美妝與服飾為主，集運倉收滿即出。"
        ),
        Campaign(
            id: "CMP-SAMPLE-JP-MAR",
            name: "三月日本團",
            openDate: sampleDate(year: 2026, month: 3, day: 1),
            closeDate: sampleDate(year: 2026, month: 3, day: 15),
            status: .closed,
            settledDate: sampleDate(year: 2026, month: 4, day: 5),
            notes: ""
        ),
    ]
}

extension LedgerOrder {

    // MARK: - Sample Data

    /// 把 ``LedgerOrder/sampleOrders`` 前幾筆指派到 ``Campaign/sampleCampaigns``，供開團相關畫面的 Preview 呈現分貨與進度。
    nonisolated static let sampleCampaignOrders: [LedgerOrder] = {
        let assignments: [(campaign: String, receipt: PaymentReceiptStatus)] = [
            ("四月韓國團", .received),
            ("四月韓國團", .pending),
            ("三月日本團", .received),
            ("四月韓國團", .received),
        ]

        let assigned = zip(LedgerOrder.sampleOrders.prefix(assignments.count), assignments).map { order, assignment in
            LedgerOrder(
                id: order.id,
                customer: order.customer,
                status: order.status,
                currency: order.currency,
                date: order.date,
                items: order.items,
                itemCost: order.itemCost,
                domesticShipping: order.domesticShipping,
                internationalShipping: order.internationalShipping,
                foreignDomesticShipping: order.foreignDomesticShipping,
                cardFeeRate: order.cardFeeRate,
                platformFeeRate: order.platformFeeRate,
                paymentFeeRate: order.paymentFeeRate,
                chargedAmount: order.chargedAmount,
                cardlessDeductionAmount: order.cardlessDeductionAmount,
                cardlessSupplementAmount: order.cardlessSupplementAmount,
                orderSource: order.orderSource,
                categories: order.categories,
                paymentMethod: order.paymentMethod,
                notes: order.notes,
                verificationStatus: order.verificationStatus,
                campaignNames: [assignment.campaign],
                paymentReceiptStatus: assignment.receipt,
                isCashOnDelivery: order.isCashOnDelivery,
                photos: order.photos,
                mergedSourceIDs: order.mergedSourceIDs
            )
        }

        return assigned + LedgerOrder.sampleOrders.dropFirst(assignments.count)
    }()
}

// MARK: - Private Method

private extension Campaign {

    /// 建立固定時區的範例日期。
    /// - Parameters:
    ///   - year: 年份。
    ///   - month: 月份。
    ///   - day: 日期。
    /// - Returns: 可重現的範例日期。
    nonisolated static func sampleDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day

        return components.date ?? Date(timeIntervalSince1970: 0)
    }
}
