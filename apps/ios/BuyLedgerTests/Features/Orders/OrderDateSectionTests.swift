//
//  OrderDateSectionTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/7.
//

import Foundation
import Testing

@testable import BuyLedger

/// `OrderDateSection` 的單元測試，涵蓋空清單、午夜邊界與排序
struct OrderDateSectionTests {

    /// 驗證沒有訂單時，分組結果不產生任何日期區段
    @Test
    func group_沒有訂單_回傳空區段() {
        // Given
        let orders: [LedgerOrder] = []

        // When
        let sections = OrderDateSection.group(
            orders,
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar,
            locale: Locale(identifier: "zh-Hant")
        )

        // Then
        #expect(sections.isEmpty)
    }

    /// 驗證未排序的訂單依日分組，午夜前一秒歸入昨天、午夜當下歸入今天，各區段與區段內都由新到舊排列
    @Test
    func group_午夜邊界與未排序訂單_依日分組並由新到舊() {
        // Given
        let now = TestDependencies.fixedNow
        let orders = [
            LedgerOrder.fixture(id: "yesterday", date: now.addingTimeInterval(-1)),
            LedgerOrder.fixture(id: "today-early", date: now),
            LedgerOrder.fixture(id: "older", date: now.addingTimeInterval(-172_800)),
            LedgerOrder.fixture(
                id: "previous-year",
                date: Date(timeIntervalSince1970: 1_767_139_200)
            ),
            LedgerOrder.fixture(id: "today-late", date: now.addingTimeInterval(43_200)),
        ]

        // When
        let sections = OrderDateSection.group(
            orders,
            referenceDate: now,
            calendar: TestDependencies.fixedCalendar,
            locale: Locale(identifier: "zh-Hant")
        )

        // Then
        #expect(
            sections.map(\.id) == [
                Date(timeIntervalSince1970: 1_777_507_200),
                Date(timeIntervalSince1970: 1_777_420_800),
                Date(timeIntervalSince1970: 1_777_334_400),
                Date(timeIntervalSince1970: 1_767_139_200),
            ]
        )
        #expect(sections.map(\.title) == ["今天", "昨天", "4月28日週二", "2025年12月31日"])
        #expect(
            sections.map { $0.orders.map(\.id) } == [
                ["today-late", "today-early"],
                ["yesterday"],
                ["older"],
                ["previous-year"],
            ]
        )
    }
}
