//
//  CampaignSummaryTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation

@testable import BuyLedger

/// 開團彙總測試共用的訂單建立工具
enum CampaignSummaryTestSupport {}

// MARK: - Internal Method

extension CampaignSummaryTestSupport {

    /// 建立只含 `CampaignSummary` 所需欄位的訂單，每筆訂單固定一個商品項目
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - customer: 客戶名稱
    ///   - campaign: 主要開團名稱，空字串代表未歸團
    ///   - charged: 客戶實付金額
    ///   - quantity: 商品數量
    ///   - receipt: 付款收據狀態
    ///   - status: 訂單狀態
    ///   - itemCost: 商品成本
    ///   - campaignNames: 訂單所屬的開團名稱，帶值時取代 `campaign`
    ///   - mergedSourceIDs: 被合併的來源訂單編號
    /// - Returns: 含單項商品、指定金額與收款狀態的訂單
    static func makeOrder(
        id: String,
        customer: String,
        campaign: String,
        charged: Decimal,
        quantity: Int = 1,
        receipt: PaymentReceiptStatus = .pending,
        status: OrderStatus = .confirmed,
        itemCost: Decimal = 0,
        campaignNames: [String]? = nil,
        mergedSourceIDs: [String] = []
    ) -> LedgerOrder {
        LedgerOrder.fixture(
            id: id,
            customer: LedgerCustomer(name: customer, initials: "XX", tier: .regular),
            status: status,
            items: [LedgerOrderItem(name: "item", quantity: quantity, unitPrice: 0)],
            itemCost: itemCost,
            chargedAmount: charged,
            campaignNames: campaignNames ?? (campaign.isEmpty ? [] : [campaign]),
            paymentReceiptStatus: receipt,
            mergedSourceIDs: mergedSourceIDs
        )
    }
}
