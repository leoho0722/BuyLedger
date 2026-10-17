//
//  OrderRequest.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

/// 清單與詳情交給訂單容器的操作請求
enum OrderRequest: Equatable, Sendable {

    /// 建立空白訂單
    case create

    /// 編輯指定訂單
    ///
    /// - Parameter id: 訂單識別值
    case edit(LedgerOrder.ID)

    /// 選擇要與指定訂單合併的副訂單
    ///
    /// - Parameter id: 主訂單識別值
    case merge(LedgerOrder.ID)

    /// 確認刪除指定訂單
    ///
    /// - Parameter id: 訂單識別值
    case delete(LedgerOrder.ID)

    /// 推入指定訂單的詳情
    ///
    /// - Parameter id: 訂單識別值
    case showDetail(LedgerOrder.ID)

    /// 批次寫入已選訂單的新狀態
    ///
    /// - Parameter orders: 已排除未選取與狀態未變更的訂單
    case batchStatusChange([LedgerOrder])

    /// 變更詳情訂單的狀態
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - status: 新狀態
    case changeStatus(id: LedgerOrder.ID, status: OrderStatus)

    /// 依清單目前的篩選結果產生 AI 摘要
    case aiSummary
}
