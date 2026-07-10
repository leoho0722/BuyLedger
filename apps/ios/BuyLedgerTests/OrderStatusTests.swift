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
        #expect(
            OrderStatus.realizedStatuses
                == [.confirmed, .purchased, .shipping, .partiallyArrived, .arrived, .delivered, .pickedUp]
        )
    }

    @Test func pickedUpCaseHasExpectedRawValueAndTitle() {
        #expect(OrderStatus.pickedUp.rawValue == "pickedUp")
        #expect(OrderStatus.pickedUp.title == "已取貨")
    }

    @Test func pickedUpIsRealizedAndOrderedAfterDelivered() {
        // 已取貨是比「已交付」更完整的終態，買家已收到貨，收益必然已實現
        #expect(OrderStatus.realizedStatuses.contains(.pickedUp))
        let allCases = OrderStatus.allCases
        #expect(allCases.firstIndex(of: .pickedUp)! > allCases.firstIndex(of: .delivered)!)
    }

    @Test func statusFilterBrowsingCasesIncludeMerged() {
        // spec「Merged orders remain findable」：訂單列表的狀態篩選需包含「已合併」，讓使用者找回被合併的舊單
        #expect(OrderStatusFilter.orderBrowsingCases.contains(.status(.merged)))
    }
}
