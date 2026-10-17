//
//  OrderListFeatureTests+FilterLabels.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import Testing

@testable import BuyLedger

extension OrderListFeatureTests {

    /// 未套用商品類別篩選時，回報沒有類別篩選
    @Test
    func hasCategoryFilter_未選類別_回傳否() {
        // Given
        let state = Self.makeState()

        // When
        let hasCategoryFilter = state.hasCategoryFilter

        // Then
        #expect(hasCategoryFilter == false)
    }

    /// 套用商品類別篩選後，回報有類別篩選
    @Test
    func hasCategoryFilter_已選類別_回傳是() {
        // Given
        var state = Self.makeState()
        state.selectedCategory = "美妝"

        // When
        let hasCategoryFilter = state.hasCategoryFilter

        // Then
        #expect(hasCategoryFilter == true)
    }

    /// 未套用付款方式篩選時，回報沒有付款方式篩選
    @Test
    func hasPaymentMethodFilter_未選付款方式_回傳否() {
        // Given
        let state = Self.makeState()

        // When
        let hasPaymentMethodFilter = state.hasPaymentMethodFilter

        // Then
        #expect(hasPaymentMethodFilter == false)
    }

    /// 套用付款方式篩選後，回報有付款方式篩選
    @Test
    func hasPaymentMethodFilter_已選付款方式_回傳是() {
        // Given
        var state = Self.makeState()
        state.selectedPaymentMethod = "信用卡"

        // When
        let hasPaymentMethodFilter = state.hasPaymentMethodFilter

        // Then
        #expect(hasPaymentMethodFilter == true)
    }
}
