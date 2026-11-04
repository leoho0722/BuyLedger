//
//  OrdersWriteOutcome.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

/// 寫入結果套用到各子層的計畫，只承載值、不修改任何狀態
struct OrdersWriteOutcome {

    // MARK: - Properties

    /// 寫入後要移除的訂單詳情識別值
    var detailPopIDs: [LedgerOrder.ID] = []

    /// 是否在合併失敗時移除已不存在的訂單詳情
    var shouldPopUnavailableDetails = false

    /// 刪除時要一併關閉其編輯表單的訂單識別值
    var closesEditOf: LedgerOrder.ID?

    /// 寫入失敗的一次性通知
    var notice: OrdersPresentationFeature.Destination.State?
}
