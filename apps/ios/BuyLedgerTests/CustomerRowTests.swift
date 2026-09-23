//
//  CustomerRowTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/23.
//

import Foundation
import Testing

@testable import BuyLedger

/// 驗證客戶彙總列的營收歸屬與保留規則
struct CustomerRowTests {

    // MARK: - Tests

    /// 驗證合併訂單與取消訂單不重複計入營收
    @Test func totalSpentAndOrderCountExcludeCancelledAndMergeResultOrders() {
        // Given
        let orders = [
            LedgerOrder.fixture(
                id: "confirmed",
                customer: LedgerCustomer(name: "Amy", initials: "AM", tier: .regular),
                date: date(2026, 3, 1),
                chargedAmount: 100
            ),
            LedgerOrder.fixture(
                id: "cancelled",
                customer: LedgerCustomer(name: "Amy", initials: "AM", tier: .regular),
                status: .cancelled,
                date: date(2026, 3, 2),
                chargedAmount: 200
            ),
            LedgerOrder.fixture(
                id: "result",
                customer: LedgerCustomer(name: "Amy", initials: "AM", tier: .regular),
                date: date(2026, 3, 3),
                chargedAmount: 500,
                mergedSourceIDs: ["sourceA", "sourceB"]
            ),
            LedgerOrder.fixture(
                id: "sourceA",
                customer: LedgerCustomer(name: "Amy", initials: "AM", tier: .regular),
                date: date(2026, 3, 4),
                chargedAmount: 100
            ),
            LedgerOrder.fixture(
                id: "sourceB",
                customer: LedgerCustomer(name: "Amy", initials: "AM", tier: .regular),
                date: date(2026, 3, 5),
                chargedAmount: 200
            )
        ]

        // When
        let amy = CustomerRow.aggregate(orders: orders).first { $0.name == "Amy" }

        // Then
        #expect(amy?.orderCount == 2)
        #expect(amy?.totalSpent == 600)
        #expect(amy?.lastOrderDate == date(2026, 3, 5))
    }

    /// 驗證只有取消訂單的客戶仍保留且消費為零
    @Test func customerWithOnlyCancelledOrdersRemainsListedWithZeroSpend() {
        // Given
        let orders = [
            LedgerOrder.fixture(
                id: "cancelled",
                customer: LedgerCustomer(name: "Amy", initials: "AM", tier: .regular),
                status: .cancelled,
                date: date(2026, 3, 2),
                chargedAmount: 200
            )
        ]

        // When
        let amy = CustomerRow.aggregate(orders: orders).first { $0.name == "Amy" }

        // Then
        #expect(amy?.orderCount == 0)
        #expect(amy?.totalSpent == 0)
    }
}

// MARK: - Private Method

private extension CustomerRowTests {

    /// 以固定 gregorian/UTC 曆建立指定年月日的日期，確保跨機器一致
    ///
    /// - Parameters:
    ///   - year: 西元年
    ///   - month: 月份
    ///   - day: 日期
    /// - Returns: 指定日期 UTC 零時的時間值
    func date(
        _ year: Int,
        _ month: Int,
        _ day: Int
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        guard let date = calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day
            )
        ) else {
            preconditionFailure("測試日期建立失敗")
        }
        return date
    }
}
