//
//  OrdersLoadState.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

/// 訂單、首頁與分析畫面共用的載入狀態
enum OrdersLoadState: Equatable, Sendable {

    /// 已完成載入，顯示正常內容
    case loaded

    /// 載入失敗，附帶失敗原因
    ///
    /// - Parameter message: 畫面持續顯示的失敗訊息
    case failed(String)

    /// 尚未載入或正在載入
    case loading
}
