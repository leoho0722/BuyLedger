//
//  CustomerRowTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/23.
//

import Foundation
import Testing

@testable import BuyLedger

/// `CustomerRow` 的單元測試，涵蓋客戶彙總列的營收歸屬與保留規則
struct CustomerRowTests {

    /// 驗證客戶彙總的消費與筆數只計入營收歸屬的訂單，合併來源與取消訂單不計入，合併結果計入，最近訂單日期仍取全部訂單
    @Test
    func aggregate_含取消與合併來源訂單_只計營收歸屬的消費與筆數() {
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
            ),
        ]

        // When
        let amy = CustomerRow.aggregate(orders: orders).first { $0.name == "Amy" }

        // Then
        #expect(amy?.orderCount == 2)
        #expect(amy?.totalSpent == 600)
        #expect(amy?.lastOrderDate == date(2026, 3, 5))
    }

    /// 驗證只有取消訂單的客戶仍保留在名單中，消費與筆數都為零
    @Test
    func aggregate_只有取消訂單的客戶_保留列表且消費為零() {
        // Given
        let orders = [
            LedgerOrder.fixture(
                id: "cancelled",
                customer: LedgerCustomer(name: "Amy", initials: "AM", tier: .regular),
                status: .cancelled,
                date: date(2026, 3, 2),
                chargedAmount: 200
            ),
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

    /// 以固定的公曆與 UTC 時區建立指定年月日的日期，確保跨機器一致
    ///
    /// - Parameters:
    ///   - year: 西元年
    ///   - month: 月份
    ///   - day: 日期
    /// - Returns: 指定日期 UTC 零時的時間值
    func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        guard let date = calendar.date(
            from: DateComponents(year: year, month: month, day: day)
        ) else {
            // 日期皆為測試固定值，無法建立代表前置資料有誤，後續比對無法繼續
            preconditionFailure("測試日期建立失敗")
        }
        return date
    }
}
