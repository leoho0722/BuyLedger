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
/// 驗證訂單狀態的顯示與分組
struct OrderStatusTests {

    // MARK: - Tests

    @Test func mergedCaseHasExpectedRawValueAndTitle() {
        #expect(OrderStatus.merged.rawValue == "merged")
        #expect(OrderStatus.merged.title == "已合併")
    }

    /// 合併狀態在顯示順序上應排在已取消之後
    ///
    /// - Throws: 狀態清單缺少預期 case 時拋出測試錯誤
    @Test func mergedStatus_isOrderedAfterCancelled() throws {
        // Given：取得所有訂單狀態
        let allCases = OrderStatus.allCases

        // When：找出合併與已取消的順序位置
        let mergedIndex = try #require(allCases.firstIndex(of: .merged))
        let cancelledIndex = try #require(allCases.firstIndex(of: .cancelled))

        // Then：合併應排在已取消之後
        #expect(mergedIndex > cancelledIndex)
    }

    @Test func mergedIsExcludedFromRealizedStatuses() {
        #expect(!OrderStatus.realizedStatuses.contains(.merged))
        #expect(
            OrderStatus.realizedStatuses
                == [
                    .confirmed, .purchased, .shipping, .partiallyArrived, .arrived, .delivered,
                    .pickedUp,
                ]
        )
    }

    @Test func pickedUpCaseHasExpectedRawValueAndTitle() {
        #expect(OrderStatus.pickedUp.rawValue == "pickedUp")
        #expect(OrderStatus.pickedUp.title == "已取貨")
    }

    /// 已取貨是已實現狀態，且顯示順序排在已交付之後
    @Test func pickedUpStatus_isRealized() {
        // Given：取得已實現狀態
        let realizedStatuses = OrderStatus.realizedStatuses

        // When：檢查已取貨是否屬於已實現狀態
        let isRealized = realizedStatuses.contains(.pickedUp)

        // Then：已取貨應屬於已實現狀態
        #expect(isRealized)
    }

    /// 已取貨的顯示順序應排在已交付之後
    ///
    /// - Throws: 狀態清單缺少預期 case 時拋出測試錯誤
    @Test func pickedUpStatus_isOrderedAfterDelivered() throws {
        // Given：取得所有訂單狀態
        let allCases = OrderStatus.allCases

        // When：找出已取貨與已交付的順序位置
        let pickedUpIndex = try #require(allCases.firstIndex(of: .pickedUp))
        let deliveredIndex = try #require(allCases.firstIndex(of: .delivered))

        // Then：已取貨應排在已交付之後
        #expect(pickedUpIndex > deliveredIndex)
    }

    @Test func statusFilterBrowsingCasesIncludeMerged() {
        // 狀態篩選也要包含已合併，讓使用者找得到舊訂單
        #expect(OrderStatusFilter.orderBrowsingCases.contains(.status(.merged)))
    }
}
