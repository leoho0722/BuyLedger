//
//  OrderDateContext.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import Foundation

/// 訂單清單出現或 Root 刷新時記錄的日期脈絡
struct OrderDateContext: Equatable, Sendable {

    // MARK: - Properties

    /// 日期篩選與「今天」「昨天」標題的參考時間
    let now: Date

    /// 日期分組與篩選共同使用的行事曆，包含注入的時區
    let calendar: Calendar
}
