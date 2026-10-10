//
//  OrderEditFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderEditFeature` 的單元測試，以 `TestStore` 逐步驗證各 `Action` 的狀態變化與後續 `Action`，並驗證 `State` 的初始值與衍生狀態
@MainActor
struct OrderEditFeatureTests {

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

    /// 三種常用付款方式與對應旗標
    static let paymentMethodCatalog: [PaymentMethodInfo] = [
        PaymentMethodInfo(
            name: "信用卡",
            isCardless: false,
            isBankTransfer: false,
            isCashOnDelivery: false
        ),
        PaymentMethodInfo(
            name: "無卡存款",
            isCardless: true,
            isBankTransfer: false,
            isCashOnDelivery: false
        ),
        PaymentMethodInfo(
            name: "銀行匯款",
            isCardless: false,
            isBankTransfer: true,
            isCashOnDelivery: false
        ),
    ]

    /// 對帳狀態不在可選清單中的既有訂單樣本
    static let orderWithReconciliationStatus = LedgerOrder(
        id: "BL-TEST-RS",
        customer: LedgerCustomer(name: "對帳測試", initials: "RS", tier: .regular),
        status: .confirmed,
        currency: .twd,
        date: Date(timeIntervalSince1970: 0),
        items: [],
        itemCost: 0,
        domesticShipping: 0,
        internationalShipping: 0,
        foreignDomesticShipping: 0,
        cardFeeRate: 0,
        platformFeeRate: 0,
        paymentFeeRate: 0,
        chargedAmount: 0,
        cardlessDeductionAmount: 0,
        cardlessSupplementAmount: 0,
        orderSource: "蝦皮",
        categories: ["美妝"],
        paymentMethod: "銀行匯款",
        notes: "",
        reconciliationStatus: "待對帳",
        campaignNames: [],
        paymentReceiptStatus: .pending,
        isCashOnDelivery: false,
        photos: [],
        mergedSourceIDs: []
    )
}

// MARK: - Nested Types

extension OrderEditFeatureTests {

    /// `binding_成本欄位改變_同步更新草稿(field:)` 逐一代入的草稿金額與費率欄位
    enum CostField: CaseIterable, Sendable {

        /// 商品成本
        case itemCost

        /// 國內運費
        case domesticShipping

        /// 國際運費
        case internationalShipping

        /// 刷卡手續費率
        case cardFeeRate

        /// 平台手續費率
        case platformFeeRate

        /// 取得草稿中對應欄位的路徑，供綁定寫入與讀回結果時使用
        var keyPath: WritableKeyPath<OrderDraft, Decimal> {
            switch self {
            case .itemCost:
                \.itemCost

            case .domesticShipping:
                \.domesticShipping

            case .internationalShipping:
                \.internationalShipping

            case .cardFeeRate:
                \.cardFeeRate

            case .platformFeeRate:
                \.platformFeeRate
            }
        }

        /// 取得各欄位用於測試的固定值
        var value: Decimal {
            switch self {
            case .itemCost:
                5_000

            case .domesticShipping:
                80

            case .internationalShipping:
                320

            case .cardFeeRate:
                0.015

            case .platformFeeRate:
                0.03
            }
        }
    }

    /// 表單測試使用的訂單起始情境，涵蓋新建、既有、合併草稿、合併結果與已合併的舊訂單
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

    /// 合併情境的 `binding` 測試使用的金額或費率欄位
    enum MergeEditField: CaseIterable, Sendable {

        /// 實收金額
        case chargedAmount

        /// 商品成本
        case itemCost

        /// 刷卡手續費率
        case cardFeeRate

        /// 取得結果斷言使用的草稿欄位路徑
        var keyPath: WritableKeyPath<OrderEditFeature.State, Decimal> & Sendable {
            switch self {
            case .chargedAmount:
                \.draft.chargedAmount

            case .itemCost:
                \.draft.itemCost

            case .cardFeeRate:
                \.draft.cardFeeRate
            }
        }
    }

    /// 分類切換測試使用的輸入與預期結果
    struct CategoryToggleCase: Sendable {

        /// 送出 action 前已選取的分類
        let initialCategories: [String]

        /// 要切換的分類
        let category: String

        /// 切換後預期保留的分類
        let expected: [String]
    }

    /// 開團切換測試使用的輸入與預期結果
    struct CampaignToggleCase: Sendable {

        /// 送出 action 前已選取的開團
        let initialCampaigns: [String]

        /// 要切換的開團名稱
        let campaign: String

        /// 切換後預期保留的開團
        let expected: [String]
    }

    /// 合併訂單的 `binding` 測試使用的情境、欄位與要寫入的值
    struct MergeEditCase: Sendable {

        /// 要建立的訂單起始情境
        let scenario: EditScenario

        /// 要更新的金額或費率欄位
        let field: MergeEditField

        /// 要寫入欄位的值
        let value: Decimal
    }
}

// MARK: - Internal Method

extension OrderEditFeatureTests {

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
