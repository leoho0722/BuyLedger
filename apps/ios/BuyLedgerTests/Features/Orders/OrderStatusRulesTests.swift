//
//  OrderStatusRulesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/7.
//

import Testing

@testable import BuyLedger

/// 訂單可選狀態與合併資格的既有行為測試
struct OrderStatusRulesTests {

    /// 一般狀態的選單保留既有順序，排除已合併
    ///
    /// - Parameter status: 一般訂單的目前狀態
    @Test(arguments: [
        OrderStatus.quoting,
        .confirmed,
        .purchased,
        .shipping,
        .partiallyArrived,
        .arrived,
        .delivered,
        .pickedUp,
        .cancelled,
    ])
    func selectableStatuses_一般訂單_排除已合併(status: OrderStatus) {
        // Given
        let expected: [OrderStatus] = [
            .quoting,
            .confirmed,
            .purchased,
            .shipping,
            .partiallyArrived,
            .arrived,
            .delivered,
            .pickedUp,
            .cancelled,
        ]

        // When
        let statuses = OrderStatusRules.selectableStatuses(for: status)

        // Then
        #expect(statuses == expected)
    }

    /// 已合併訂單的選單仍包含已合併狀態
    @Test
    func selectableStatuses_已合併訂單_包含已合併() {
        // Given
        let status = OrderStatus.merged
        let expected: [OrderStatus] = [
            .quoting,
            .confirmed,
            .purchased,
            .shipping,
            .partiallyArrived,
            .arrived,
            .delivered,
            .pickedUp,
            .cancelled,
            .merged,
        ]

        // When
        let statuses = OrderStatusRules.selectableStatuses(for: status)

        // Then
        #expect(statuses == expected)
    }

    /// 所有狀態的合併資格依既有規則判斷
    ///
    /// - Parameters:
    ///   - status: 要判斷的訂單狀態
    ///   - isMergeable: 該狀態是否可合併，直接寫在表格中
    @Test(arguments: [
        (OrderStatus.quoting, true),
        (.confirmed, true),
        (.purchased, true),
        (.shipping, true),
        (.partiallyArrived, true),
        (.arrived, true),
        (.delivered, true),
        (.pickedUp, true),
        (.cancelled, false),
        (.merged, false),
    ])
    func canMerge_所有訂單狀態_僅取消與已合併不可合併(status: OrderStatus, isMergeable: Bool) {
        // Given
        let currentStatus = status

        // When
        let canMerge = OrderStatusRules.canMerge(status: currentStatus)

        // Then
        #expect(canMerge == isMergeable)
    }
}
