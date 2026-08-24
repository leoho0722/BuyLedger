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

// MARK: - Internal Method

extension Campaign {

    /// 依結單日更新開團狀態
    /// - Parameters:
    ///   - now: 注入的現在時間
    ///   - calendar: 注入的曆法 (含時區)
    /// - Returns: 評估後的開團；沒有結單日或非進行中狀態時原樣回傳
    func evaluatingAutoClose(asOf now: Date, calendar: Calendar) -> Campaign {
        guard status == .ongoing, let closeDate else {
            return self
        }
        guard let boundary = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: closeDate)
        ) else {
            return self
        }
        guard now >= boundary else {
            return self
        }
        var copy = self
        copy.status = .closed
        return copy
    }
}
