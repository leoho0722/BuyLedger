//
//  CalendarReminderService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

import Foundation

/// 系統行事曆提醒的操作入口；
/// 正式實作在 `liveValue`、測試預設值在 `testValue`、Preview 假資料在 `previewValue`
struct CalendarReminderService: Sendable {

    // MARK: - Properties

    /// 請求完整行事曆存取權；受裝置政策限制時回報受限狀態
    ///
    /// - Returns: 系統行事曆權限授權結果
    var requestAccess: RequestAccess

    /// 以標題、日期與提示位移建立全天提醒事件
    ///
    /// - Parameters:
    ///   - title: 提醒事件標題
    ///   - date: 事件日期 (全天事件)
    ///   - alarmOffset: 從當天 00:00 到提醒時間的秒數
    /// - Returns: 事件識別碼
    /// - Throws: 找不到可寫入行事曆時丟 `.noWritableCalendar`；儲存失敗時丟 `.system(underlying:)`；
    ///   取不到事件識別碼時丟 `.eventIdentifierMissing`
    var addReminder: AddReminder

    /// 依識別碼移除事件；找不到時不做任何事
    ///
    /// - Parameter eventIdentifier: 要移除的事件識別碼
    /// - Throws: 系統移除失敗時丟 `.system(underlying:)`
    var removeReminder: RemoveReminder
}

// MARK: - Nested Types

extension CalendarReminderService {

    /// `requestAccess` 的函式型別
    typealias RequestAccess = @Sendable () async -> AccessResult

    /// `addReminder` 的函式型別
    typealias AddReminder = @Sendable (
        _ title: String,
        _ date: Date,
        _ alarmOffset: TimeInterval
    ) async throws(CalendarReminderError) -> String

    /// `removeReminder` 的函式型別
    typealias RemoveReminder = @Sendable (
        _ eventIdentifier: String
    ) async throws(CalendarReminderError) -> Void

    /// 行事曆存取請求的結果
    enum AccessResult: Equatable, Sendable {

        /// 已授予完整存取
        case granted

        /// 使用者拒絕存取
        case denied

        /// 存取受裝置政策限制 (如家長監護、MDM)，使用者無法自行到設定開啟
        case restricted
    }
}
