//
//  OrderDraftCustomerTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderDraft.resolveWriteResult` 的單元測試，涵蓋客戶縮寫與分級
struct OrderDraftCustomerTests {

    /// 驗證合併草稿沿用主訂單的縮寫與分級，不依草稿的客戶名稱重新推算，並記下主訂單為合併來源
    @Test
    func resolveWriteResult_合併草稿_沿用主訂單的客戶縮寫與分級() {
        // Given
        let primary = OrderDraftTestSupport.makeOrder(
            id: "BL-PRIMARY",
            customerName: "王小明",
            initials: "PP",
            tier: .vip
        )
        var editState = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        editState.draft.customerName = "王小明"
        editState.mergeSourceIDs = [primary.id]

        // When
        let result = OrderDraft.resolveWriteResult(editState, existingOrders: [primary]) {
            "MERGEID"
        }

        // Then
        #expect(result.order.customer.name == "王小明")
        #expect(result.order.customer.initials == "PP")
        #expect(result.order.customer.tier == .vip)
        #expect(result.order.mergedSourceIDs == ["BL-PRIMARY"])
        #expect(result.order.id == "BL-DRAFT-MERGEID")
    }

    /// 驗證一般新單的縮寫取輸入名稱前兩個字，分級為新客，且沒有合併來源
    @Test
    func resolveWriteResult_一般新單_由名稱取縮寫且分級為新客() {
        // Given
        var editState = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        editState.draft.customerName = "陳大文"

        // When
        let result = OrderDraft.resolveWriteResult(editState, existingOrders: []) { "GENID" }

        // Then
        #expect(result.order.customer.initials == "陳大")
        #expect(result.order.customer.tier == .new)
        #expect(result.order.mergedSourceIDs == [])
    }
}
