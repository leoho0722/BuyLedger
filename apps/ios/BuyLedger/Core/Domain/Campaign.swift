//
//  Campaign.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation

// MARK: - Computed Properties

extension Campaign {

    /// 是否已結團
    var isSettled: Bool {
        settledDate != nil
    }

    // MARK: 訂購提醒

    /// 訂購提醒行事曆事件的標題
    var reminderTitle: String {
        "「\(name)」訂購提醒"
    }
}
