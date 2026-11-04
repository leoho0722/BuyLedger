//
//  OrdersRequestOutcome.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

/// 共用請求套用到容器的結果，由容器依值呈現或轉送寫入
enum OrdersRequestOutcome {

    /// 沒有需要套用的變更
    case none

    /// 呈現表單或 alert
    ///
    /// - Parameter destination: 要呈現的目的地
    case present(OrdersPresentationFeature.Destination.State)

    /// 轉送寫入子層的請求
    ///
    /// - Parameter action: 寫入子層的請求
    case write(OrderWritesFeature.Action)
}
