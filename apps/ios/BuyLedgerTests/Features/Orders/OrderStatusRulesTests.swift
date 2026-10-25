//
//  OrderStatusRulesTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/7.
//

import Testing

@testable import BuyLedger

/// `OrderStatusRules` 的單元測試，鎖定既有的可選狀態清單與合併資格
struct OrderStatusRulesTests {

    /// 驗證目前狀態為一般狀態時，選單依既有順序列出九種狀態，且不含已合併
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

    /// 驗證已合併訂單的選單為九種一般狀態加上已合併，且已合併排在最後
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

    /// 驗證各訂單狀態的合併資格，只有已取消與已合併不可合併，其餘皆可合併
    ///
    /// - Parameter testCase: 訂單狀態與預期合併資格
    @Test(arguments: [
        MergeabilityCase(status: .quoting, isMergeable: true),
        MergeabilityCase(status: .confirmed, isMergeable: true),
        MergeabilityCase(status: .purchased, isMergeable: true),
        MergeabilityCase(status: .shipping, isMergeable: true),
        MergeabilityCase(status: .partiallyArrived, isMergeable: true),
        MergeabilityCase(status: .arrived, isMergeable: true),
        MergeabilityCase(status: .delivered, isMergeable: true),
        MergeabilityCase(status: .pickedUp, isMergeable: true),
        MergeabilityCase(status: .cancelled, isMergeable: false),
        MergeabilityCase(status: .merged, isMergeable: false),
    ])
    func canMerge_所有訂單狀態_僅取消與已合併不可合併(testCase: MergeabilityCase) {
        // Given
        let currentStatus = testCase.status

        // When
        let canMerge = OrderStatusRules.canMerge(status: currentStatus)

        // Then
        #expect(canMerge == testCase.isMergeable)
    }
}

// MARK: - Nested Types

extension OrderStatusRulesTests {

    /// 各訂單狀態的合併資格
    struct MergeabilityCase: Sendable {

        /// 要判斷的訂單狀態
        let status: OrderStatus

        /// 該狀態是否可合併 (字面預期值)
        let isMergeable: Bool
    }
}
