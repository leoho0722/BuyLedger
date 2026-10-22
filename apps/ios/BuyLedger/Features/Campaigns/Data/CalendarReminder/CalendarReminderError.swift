//
//  CalendarReminderError.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

/// 建立或移除提醒事件時可能拋出的錯誤
enum CalendarReminderError: Error, Sendable {

    /// 事件已存檔但取不到識別碼 (理論上不應發生)
    case eventIdentifierMissing

    /// 已授權，但找不到可寫入的行事曆
    case noWritableCalendar

    /// 系統行事曆 API 回傳其他錯誤
    ///
    /// - Parameter underlying: 系統行事曆 API 原本拋出的錯誤
    case system(underlying: any Error & Sendable)
}
