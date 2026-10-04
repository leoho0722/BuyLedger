//
//  CampaignDistributionRow.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import Foundation

/// 開團分貨清單中的單一客戶列
struct CampaignDistributionRow: Equatable, Sendable {

    // MARK: - Properties

    /// 客戶名稱 (已去頭尾空白)
    let customerName: String

    /// 該客戶在此開團所有訂單的商品件數加總
    let totalQuantity: Int

    /// 該客戶在此開團所有訂單的應收金額 (`chargedAmount`) 加總
    let totalAmount: Decimal

    /// 是否全部已收款
    let isFullyReceived: Bool

    /// 該客戶在此開團的訂單；供詳情頁展開檢視品項與逐筆收款
    let orders: [LedgerOrder]
}

// MARK: - Identifiable

extension CampaignDistributionRow: Identifiable {

    /// 以客戶名稱作為穩定識別值 (同一開團內客戶名稱唯一)
    var id: String {
        customerName
    }
}
