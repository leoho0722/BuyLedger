//
//  DashboardStatsTests+Fixtures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation

@testable import BuyLedger

// MARK: - Internal Method

extension DashboardStatsTests {

    /// 取得 2026 年 4 月 (``TestDependencies/fixedNow`` 所在月份) 的指定日期，UTC 零時
    ///
    /// - Parameter day: 日期
    /// - Returns: 指定日期 UTC 零時的時間值
    static func aprilDate(_ day: Int) -> Date {
        utcDate(month: 4, day: day)
    }

    /// 取得 2026 年 3 月 (``TestDependencies/fixedNow`` 前一個月) 的指定日期，UTC 零時
    ///
    /// - Parameter day: 日期
    /// - Returns: 指定日期 UTC 零時的時間值
    static func marchDate(_ day: Int) -> Date {
        utcDate(month: 3, day: day)
    }

    /// 2026 年指定月份與日期的時間值，以 UTC 計算
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

    /// 建立只含 DashboardStats 所需欄位的訂單
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

    /// 建立只替換狀態的訂單複本
    ///
    /// - Parameters:
    ///   - order: 原始訂單
    ///   - status: 新的訂單狀態
    /// - Returns: 套用新狀態後的訂單
    static func replacingStatus(of order: LedgerOrder, with status: OrderStatus) -> LedgerOrder {
        LedgerOrder(
            id: order.id,
            customer: order.customer,
            status: status,
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
            reconciliationStatus: order.reconciliationStatus,
            campaignNames: order.campaignNames,
            paymentReceiptStatus: order.paymentReceiptStatus,
            isCashOnDelivery: order.isCashOnDelivery,
            photos: order.photos,
            mergedSourceIDs: order.mergedSourceIDs
        )
    }
}
