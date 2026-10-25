//
//  CampaignIntegrationTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation

@testable import BuyLedger

/// 提供開團整合測試共用的訂單與根狀態建構操作
enum CampaignIntegrationTestSupport {}

// MARK: - Internal Method

extension CampaignIntegrationTestSupport {

    /// 建立供開團整合測試使用的最小訂單
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - campaign: 訂單所屬的開團名稱
    ///   - chargedAmount: 訂單實付金額
    /// - Returns: 日期固定、已確認且待收款的訂單；開團名稱非空時歸屬指定開團
    static func makeOrder(
        id: String,
        campaign: String,
        chargedAmount: Decimal = 100
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "客戶", initials: "XX", tier: .regular),
            status: .confirmed,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [
                LedgerOrderItem(
                    id: UUID(0),
                    name: "item",
                    quantity: 1,
                    unitPrice: 0
                ),
            ],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: chargedAmount,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "",
            categories: [],
            paymentMethod: "",
            notes: "",
            reconciliationStatus: "",
            campaignNames: campaign.isEmpty ? [] : [campaign],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }

    /// 組出指定開團名稱與收款狀態的訂單副本，供 Given 建立前置狀態
    ///
    /// - Parameters:
    ///   - order: 原始訂單
    ///   - campaignNames: 要寫入的開團名稱
    ///   - receiptStatus: 要寫入的收款狀態，未指定時保留原值
    /// - Returns: 開團名稱換成指定內容，收款狀態有指定時一併替換的訂單
    static func rebuilt(
        _ order: LedgerOrder,
        campaignNames: [String],
        receiptStatus: PaymentReceiptStatus? = nil
    ) -> LedgerOrder {
        LedgerOrder(
            id: order.id,
            customer: order.customer,
            status: order.status,
            currency: order.currency,
            date: order.date,
            items: order.items,
            itemCost: order.itemCost,
            domesticShipping: order.domesticShipping,
            internationalShipping: order.internationalShipping,
            foreignDomesticShipping: order.foreignDomesticShipping,
            cardFeeRate: order.cardFeeRate,
            platformFeeRate: order.platformFeeRate,
            paymentFeeRate: order.paymentFeeRate,
            chargedAmount: order.chargedAmount,
            cardlessDeductionAmount: order.cardlessDeductionAmount,
            cardlessSupplementAmount: order.cardlessSupplementAmount,
            orderSource: order.orderSource,
            categories: order.categories,
            paymentMethod: order.paymentMethod,
            notes: order.notes,
            reconciliationStatus: order.reconciliationStatus,
            campaignNames: campaignNames,
            paymentReceiptStatus: receiptStatus ?? order.paymentReceiptStatus,
            isCashOnDelivery: order.isCashOnDelivery,
            photos: order.photos,
            mergedSourceIDs: order.mergedSourceIDs
        )
    }

    /// 建立各頁投影與來源一致的根狀態，讓測試只觀察這次操作造成的差異
    ///
    /// - Parameters:
    ///   - campaigns: 開團來源及三份副本
    ///   - orders: 訂單來源及四份投影
    /// - Returns: 各頁資料一致且尚未載入的根狀態
    static func makeRootState(campaigns: [Campaign], orders: [LedgerOrder]) -> RootFeature.State {
        var state = RootFeature.State()
        state.campaigns.$campaigns.withLock {
            $0 = campaigns
        }
        state.campaigns.$orders.withLock {
            $0 = orders
        }
        state.more.$orders.withLock {
            $0 = orders
        }
        state.orders.$orders.withLock {
            $0 = orders
        }
        state.dashboard.orders = orders
        state.insights.orders = orders
        state.orders.$campaigns.withLock {
            $0 = campaigns
        }
        state.dashboard.campaigns = campaigns
        state.insights.campaigns = campaigns
        return state
    }
}
