//
//  CalendarAccessResult.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/23.
//

/// 向系統請求行事曆存取權限的結果
enum CalendarAccessResult: CaseIterable, Equatable, Sendable {

    /// 已授予完整存取
    case granted

    /// 使用者拒絕存取
    case denied

    /// 存取受裝置政策限制 (如家長監護、企業的裝置管理)，使用者無法自行到設定開啟
    case restricted
}
