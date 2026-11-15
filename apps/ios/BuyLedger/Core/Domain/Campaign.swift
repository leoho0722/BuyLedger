//
//  Campaign.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation

/// 一次團購批次，包含開團、結單與結團狀態
struct Campaign: Codable, Equatable, Identifiable, Sendable {

    // MARK: - Properties

    /// 開團的穩定識別值 (UUID 字串)
    let id: String

    /// 開團名稱，也是訂單歸屬的依據
    var name: String

    /// 開團日期
    var openDate: Date

    /// 結單日期；未設定表示持續收單
    var closeDate: Date?

    /// 開團目前狀態
    var status: CampaignStatus

    /// 結團日期；未設定表示尚未結團
    var settledDate: Date?

    /// 開團備註；沒有備註時為空字串
    var notes: String
}

// MARK: - Computed Properties

extension Campaign {

    /// 是否已結團
    var isSettled: Bool {
        settledDate != nil
    }

    /// 訂購提醒行事曆事件的標題
    var reminderTitle: String {
        "「\(name)」訂購提醒"
    }
}

// MARK: - Internal Method

extension Campaign {

    /// 依結單日更新開團狀態
    ///
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
