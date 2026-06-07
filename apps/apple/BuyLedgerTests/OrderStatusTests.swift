//
//  OrderStatusTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/6/6.
//

import Foundation
import Testing
@testable import BuyLedger

@MainActor
struct OrderStatusTests {

    // MARK: - Tests

    @Test func mergedCaseHasExpectedRawValueAndTitle() {
        #expect(OrderStatus.merged.rawValue == "merged")
        #expect(OrderStatus.merged.title == "已合併")
    }

    @Test func mergedIsOrderedAfterCancelled() {
        #expect(OrderStatus.allCases.last == .merged)
    }

    @Test func mergedIsExcludedFromRealizedStatuses() {
        #expect(!OrderStatus.realizedStatuses.contains(.merged))
        #expect(OrderStatus.realizedStatuses == [.confirmed, .purchased, .shipping, .delivered])
    }

    @Test func statusFilterBrowsingCasesIncludeMerged() {
        // spec「Merged orders remain findable」：訂單列表的狀態篩選需包含「已合併」，讓使用者找回被合併的舊單。
        #expect(OrderStatusFilter.orderBrowsingCases.contains(.status(.merged)))
    }
}
