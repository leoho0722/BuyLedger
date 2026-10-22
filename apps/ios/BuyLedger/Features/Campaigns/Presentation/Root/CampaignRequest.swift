//
//  CampaignRequest.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

/// 列表與詳情交給開團容器處理的操作請求
enum CampaignRequest: Equatable, Sendable {

    /// 顯示指定開團的詳情
    ///
    /// - Parameter id: 開團識別值
    case showDetail(Campaign.ID)

    /// 建立新開團
    case create

    /// 編輯指定開團
    ///
    /// - Parameter id: 開團識別值
    case edit(Campaign.ID)

    /// 確認刪除指定開團
    ///
    /// - Parameter id: 開團識別值
    case delete(Campaign.ID)

    /// 確認結算指定開團
    ///
    /// - Parameter id: 開團識別值
    case settle(Campaign.ID)

    /// 變更開團狀態
    ///
    /// - Parameters:
    ///   - id: 開團識別值
    ///   - status: 新狀態
    case changeStatus(id: Campaign.ID, status: CampaignStatus)

    /// 切換訂單收款狀態
    ///
    /// - Parameters:
    ///   - orderID: 訂單識別值
    ///   - status: 新收款狀態
    case toggleReceipt(orderID: LedgerOrder.ID, status: PaymentReceiptStatus)
}
