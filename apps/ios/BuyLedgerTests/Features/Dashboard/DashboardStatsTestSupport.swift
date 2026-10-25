//
//  DashboardStatsTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation

@testable import BuyLedger

/// 提供總覽統計測試共用的訂單與固定 UTC 日期
enum DashboardStatsTestSupport {}

// MARK: - Internal Method

extension DashboardStatsTestSupport {

    /// 建立供 `DashboardStats` 測試用的訂單，其餘欄位使用固定預設值
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - status: 訂單狀態
    ///   - date: 訂單日期
    ///   - charged: 客戶實付金額
    ///   - itemCost: 商品成本
    ///   - mergedSourceIDs: 被合併的來源訂單編號
    /// - Returns: 建立的測試訂單
    static func makeOrder(
        id: String,
        status: OrderStatus,
        date: Date,
        charged: Decimal,
        itemCost: Decimal = 0,
        mergedSourceIDs: [String] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "客戶", initials: "XX", tier: .regular),
            status: status,
            currency: .twd,
            date: date,
            items: [LedgerOrderItem(name: "item", quantity: 1, unitPrice: 0)],
            itemCost: itemCost,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: charged,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            categories: [],
            paymentMethod: "",
            notes: "",
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: mergedSourceIDs
        )
    }

    /// 取得 2026 年 4 月 (`TestDependencies.fixedNow` 所在月份) 的指定日期，UTC 零時
    ///
    /// - Parameter day: 日期
    /// - Returns: 指定日期 UTC 零時的時間值
    static func aprilDate(_ day: Int) -> Date {
        utcDate(month: 4, day: day)
    }

    /// 取得 2026 年指定月份與日期的時間值，以 UTC 計算
    ///
    /// - Parameters:
    ///   - month: 月份
    ///   - day: 日期
    ///   - hour: 小時，預設為 0
    /// - Returns: 指定時間的 UTC 時間值
    static func utcDate(month: Int, day: Int, hour: Int = 0) -> Date {
        // 2026 年平年，各月月初相對 1 月 1 日的累積天數
        let daysBeforeMonth = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
        let dayIndex = daysBeforeMonth[month - 1] + day - 1
        return Date(timeIntervalSince1970: 1_767_225_600 + Double(dayIndex * 86_400 + hour * 3_600))
    }
}
