//
//  OrdersFilterOperationsTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/23.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 提供訂單篩選測試共用的測試資料與日期工具
enum OrdersFilterOperationsTestSupport {}

// MARK: - Internal Method

extension OrdersFilterOperationsTestSupport {

    /// 以固定行事曆與 UTC 時區建立指定年月日的日期
    ///
    /// - Parameters:
    ///   - year: 西元年
    ///   - month: 月份
    ///   - day: 日期
    /// - Returns: 指定日期 UTC 零時的時間值
    /// - Throws: 年月日無法組成日期時丟出測試錯誤
    static func date(year: Int, month: Int, day: Int) throws -> Date {
        var components = DateComponents()
        components.calendar = TestDependencies.fixedCalendar
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        return try #require(components.date)
    }

    /// 建立僅供篩選測試使用的最小訂單；非相關欄位以零值或佔位填入
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - status: 訂單狀態
    ///   - date: 訂單日期
    ///   - category: 商品類別
    ///   - paymentMethod: 付款方式
    /// - Returns: 建立的測試訂單
    static func makeOrder(
        id: String,
        status: OrderStatus = .quoting,
        date: Date = TestDependencies.fixedNow,
        category: String = "類別",
        paymentMethod: String = "付款"
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "客戶\(id)", initials: "XX", tier: .new),
            status: status,
            currency: .twd,
            date: date,
            items: [
                LedgerOrderItem(
                    id: UUID(0),
                    name: "商品",
                    quantity: 1,
                    unitPrice: 100
                ),
            ],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "來源",
            categories: [category],
            paymentMethod: paymentMethod,
            notes: "",
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
}
