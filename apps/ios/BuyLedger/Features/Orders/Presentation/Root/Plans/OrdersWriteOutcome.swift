//
//  OrdersWriteOutcome.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import Foundation

/// 寫入結果套用到各子層的計畫，只承載值、不修改任何狀態
struct OrdersWriteOutcome {

    // MARK: - Properties

    /// 寫入後要更新的清單選取，`nil` 代表不變
    var selection: Selection?

    /// 寫入後要移除的訂單詳情識別值
    var detailPopIDs: [LedgerOrder.ID] = []

    /// 合併失敗時要移除已不存在的訂單詳情
    var shouldPopUnavailableDetails = false

    /// 刪除的訂單若正在表單中編輯，要關閉該表單
    var closesEditOf: LedgerOrder.ID?

    /// 寫入失敗的一次性通知
    var notice: OrdersPresentationFeature.Destination.State?
}

// MARK: - Nested Types

extension OrdersWriteOutcome {

    /// 清單選取的變更
    struct Selection: Equatable {

        /// 新的選取訂單識別值，刪除後沒有剩餘訂單時為 `nil`
        var orderID: LedgerOrder.ID?

        /// 是否要以 action 通知清單選取已變更
        var shouldNotify: Bool
    }
}
