//
//  OrderDetailFeatureDisplayTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderDetailFeature` 的單元測試，涵蓋來源、類別、備註與成本的顯示文字與條件
struct OrderDetailFeatureDisplayTests {

    /// 驗證來源名稱前後的空白不顯示，只留下名稱本身
    @Test
    func orderSourceText_來源有前後空白_去除空白() {
        // Given
        let state = Self.makeState(order: LedgerOrder.fixture(id: "A", orderSource: " 蝦皮 "))

        // When
        let text = state.orderSourceText

        // Then
        #expect(text == "蝦皮")
    }

    /// 驗證來源只有空白時，顯示空狀態符號
    @Test
    func orderSourceText_來源只有空白_顯示空狀態() {
        // Given
        let state = Self.makeState(order: LedgerOrder.fixture(id: "A", orderSource: "   "))

        // When
        let text = state.orderSourceText

        // Then
        #expect(text == "—")
    }

    /// 驗證類別去除空白與空值後，以頓號串接有效類別
    @Test
    func categoriesText_類別含空白與空值_串接有效類別() {
        // Given
        let state = Self.makeState(
            order: LedgerOrder.fixture(id: "A", categories: [" 咖啡 ", "", "點心"])
        )

        // When
        let text = state.categoriesText

        // Then
        #expect(text == "咖啡、點心")
    }

    /// 驗證類別都沒有有效名稱時，顯示空狀態符號
    @Test
    func categoriesText_沒有有效類別_顯示空狀態() {
        // Given
        let state = Self.makeState(order: LedgerOrder.fixture(id: "A", categories: ["", " "]))

        // When
        let text = state.categoriesText

        // Then
        #expect(text == "—")
    }

    /// 驗證開團名稱去除空白與空值後，以頓號串接有效名稱
    @Test
    func campaignNamesText_開團含空白與空值_串接有效名稱() {
        // Given
        let state = Self.makeState(
            order: LedgerOrder.fixture(id: "A", campaignNames: ["  春季 ", "", "夏季"])
        )

        // When
        let text = state.campaignNamesText

        // Then
        #expect(text == "春季、夏季")
    }

    /// 驗證沒有有效開團時回傳 `nil` (畫面依此決定是否顯示本地化的未歸團文字)
    @Test
    func campaignNamesText_沒有有效開團_回傳nil() {
        // Given
        let state = Self.makeState(order: LedgerOrder.fixture(id: "A", campaignNames: ["", " "]))

        // When
        let text = state.campaignNamesText

        // Then
        #expect(text == nil)
    }

    /// 驗證只有空白與換行的備註時，`hasNotes` 為假 (畫面依此決定是否顯示備註卡片)
    @Test
    func hasNotes_只有空白備註_回傳假() {
        // Given
        let state = Self.makeState(order: LedgerOrder.fixture(id: "A", notes: " \n "))

        // When
        let hasNotes = state.hasNotes

        // Then
        #expect(hasNotes == false)
    }

    /// 驗證去除空白後仍有文字的備註時，`hasNotes` 為真 (畫面依此決定是否顯示備註卡片)
    @Test
    func hasNotes_有內容備註_回傳真() {
        // Given
        let state = Self.makeState(order: LedgerOrder.fixture(id: "A", notes: " 注意 "))

        // When
        let hasNotes = state.hasNotes

        // Then
        #expect(hasNotes == true)
    }

    /// 驗證無卡折抵與補款金額都是零時，`hasCardlessAdjustments` 為假 (畫面依此決定是否顯示無卡明細卡片)
    @Test
    func hasCardlessAdjustments_無卡折抵與補款皆為零_回傳假() {
        // Given
        let state = Self.makeState(order: LedgerOrder.fixture(id: "A"))

        // When
        let hasCardlessAdjustments = state.hasCardlessAdjustments

        // Then
        #expect(hasCardlessAdjustments == false)
    }

    /// 驗證有無卡折抵金額時，`hasCardlessAdjustments` 為真 (畫面依此決定是否顯示無卡明細卡片)
    @Test
    func hasCardlessAdjustments_有無卡折抵金額_回傳真() {
        // Given
        let state = Self.makeState(
            order: LedgerOrder.fixture(id: "A", cardlessDeductionAmount: 100)
        )

        // When
        let hasCardlessAdjustments = state.hasCardlessAdjustments

        // Then
        #expect(hasCardlessAdjustments == true)
    }

    /// 驗證只有無卡補款金額時，`hasCardlessAdjustments` 仍為真 (畫面依此決定是否顯示無卡明細卡片)
    @Test
    func hasCardlessAdjustments_只有無卡補款金額_回傳真() {
        // Given
        let state = Self.makeState(
            order: LedgerOrder.fixture(id: "A", cardlessSupplementAmount: 50)
        )

        // When
        let hasCardlessAdjustments = state.hasCardlessAdjustments

        // Then
        #expect(hasCardlessAdjustments == true)
    }

    /// 驗證訂單已從共用資料移除時，`hasCardlessAdjustments` 為假 (畫面依此決定是否顯示無卡明細卡片)
    @Test
    func hasCardlessAdjustments_訂單不存在_回傳假() {
        // Given
        let state = OrderDetailFeature.State(orderID: "missing", orders: SharedReader(value: []))

        // When
        let hasCardlessAdjustments = state.hasCardlessAdjustments

        // Then
        #expect(hasCardlessAdjustments == false)
    }

    /// 驗證總成本為零時，`hasCostBreakdown` 為假 (畫面依此決定是否顯示成本拆解)
    @Test
    func hasCostBreakdown_總成本為零_回傳假() {
        // Given
        let state = Self.makeState(order: LedgerOrder.fixture(id: "A"))

        // When
        let hasCostBreakdown = state.hasCostBreakdown

        // Then
        #expect(hasCostBreakdown == false)
    }

    /// 驗證總成本大於零時，`hasCostBreakdown` 為真 (畫面依此決定是否顯示成本拆解)
    @Test
    func hasCostBreakdown_總成本為正_回傳真() {
        // Given
        let state = Self.makeState(order: LedgerOrder.fixture(id: "A", itemCost: 100))

        // When
        let hasCostBreakdown = state.hasCostBreakdown

        // Then
        #expect(hasCostBreakdown == true)
    }

    /// 驗證訂單已從共用資料移除時，`hasCostBreakdown` 為假 (畫面依此決定是否顯示成本拆解)
    @Test
    func hasCostBreakdown_訂單不存在_回傳假() {
        // Given
        let state = OrderDetailFeature.State(orderID: "missing", orders: SharedReader(value: []))

        // When
        let hasCostBreakdown = state.hasCostBreakdown

        // Then
        #expect(hasCostBreakdown == false)
    }

    /// 驗證訂單已從共用資料移除時，來源顯示空狀態符號
    @Test
    func orderSourceText_訂單不存在_顯示空狀態() {
        // Given
        let state = OrderDetailFeature.State(orderID: "missing", orders: SharedReader(value: []))

        // When
        let text = state.orderSourceText

        // Then
        #expect(text == "—")
    }
}

// MARK: - Private Method

private extension OrderDetailFeatureDisplayTests {

    /// 建立以獨立共用資料顯示指定訂單的詳情狀態
    ///
    /// - Parameter order: 要顯示的訂單
    /// - Returns: 顯示該訂單的詳情狀態
    static func makeState(order: LedgerOrder) -> OrderDetailFeature.State {
        let orders = Shared<[LedgerOrder]>(value: [])
        orders.withLock {
            $0 = [order]
        }
        return OrderDetailFeature.State(orderID: order.id, orders: SharedReader(orders))
    }
}
