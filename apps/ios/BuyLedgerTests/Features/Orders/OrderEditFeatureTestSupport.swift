//
//  OrderEditFeatureTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 提供訂單編輯測試共用的訂單起始情境與對應的表單狀態
enum OrderEditFeatureTestSupport {

    // MARK: - Properties

    /// 已合併的來源訂單樣本
    static let mergedAwayOrder = LedgerOrder(
        id: "BL-MERGED-AWAY",
        customer: LedgerCustomer(name: "測試客戶", initials: "TC", tier: .regular),
        status: .merged,
        currency: .twd,
        date: Date(timeIntervalSince1970: 1_700_000_000),
        items: [],
        itemCost: 100,
        domesticShipping: 0,
        internationalShipping: 0,
        foreignDomesticShipping: 0,
        cardFeeRate: 0,
        platformFeeRate: 0,
        paymentFeeRate: 0,
        chargedAmount: 500,
        cardlessDeductionAmount: 0,
        cardlessSupplementAmount: 0,
        orderSource: "蝦皮",
        categories: ["美妝"],
        paymentMethod: "信用卡",
        notes: "",
        reconciliationStatus: "",
        campaignNames: [],
        paymentReceiptStatus: .pending,
        isCashOnDelivery: false,
        photos: [],
        mergedSourceIDs: []
    )
}

// MARK: - Nested Types

extension OrderEditFeatureTestSupport {

    /// 表單測試使用的訂單起始情境，涵蓋新建、既有、合併草稿、合併結果與已合併的舊訂單
    ///
    /// - Note: 用於測試方法的參數型別，須為 internal
    enum EditScenario: CaseIterable, Sendable {

        /// 新建訂單
        case newOrder

        /// 編輯一般既有訂單
        case existingOrder

        /// 帶有兩筆合併來源的草稿
        case mergeDraft

        /// 編輯由合併產生的訂單
        case mergedResult

        /// 編輯已被合併的舊訂單
        case mergedAway
    }
}

// MARK: - Internal Method

extension OrderEditFeatureTestSupport {

    /// 依照訂單情境建立編輯表單狀態
    ///
    /// - Parameter scenario: 要建立的訂單起始情境
    /// - Returns: 尚未編輯的表單狀態，識別碼固定為 `UUID(0)`、目前日期固定為 `TestDependencies.fixedNow`
    /// - Throws: 找不到合併產生的樣本訂單時由 `#require` 丟出
    static func makeState(for scenario: EditScenario) throws -> OrderEditFeature.State {
        let state: OrderEditFeature.State
        switch scenario {
        case .newOrder:
            state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)

        case .existingOrder:
            state = OrderEditFeature.State(
                original: LedgerOrder.sampleOrders[0],
                id: UUID(0),
                currentDate: TestDependencies.fixedNow
            )

        case .mergeDraft:
            var initial = OrderEditFeature.State(
                id: UUID(0),
                currentDate: TestDependencies.fixedNow
            )
            initial.mergeSourceIDs = ["BL-A", "BL-B"]
            state = initial

        case .mergedResult:
            let mergedOrder = LedgerOrder.sampleOrders.first {
                !$0.mergedSourceIDs.isEmpty
            }
            let original = try #require(mergedOrder)
            state = OrderEditFeature.State(
                original: original,
                id: UUID(0),
                currentDate: TestDependencies.fixedNow
            )

        case .mergedAway:
            state = OrderEditFeature.State(
                original: Self.mergedAwayOrder,
                id: UUID(0),
                currentDate: TestDependencies.fixedNow
            )
        }
        return state
    }
}
