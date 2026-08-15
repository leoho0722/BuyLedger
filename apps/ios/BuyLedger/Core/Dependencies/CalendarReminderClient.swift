//
//  CalendarReminderClient.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/11.
//

import ComposableArchitecture
import EventKit
import Foundation

/// 將開團訂購提醒寫入／移除系統行事曆的依賴介面
struct CalendarReminderClient: Sendable {
    
    // MARK: - Dependency Properties
    
    /// 請求系統行事曆權限
    /// - Returns: 系統行事曆權限授權結果
    var requestAccess: @Sendable () async -> Access
    
    /// 以標題、日期與提示位移建立全天提醒事件，回傳事件識別碼
    /// - Parameters:
    ///   - title: 提醒事件標題
    ///   - date: 事件日期 (全天事件)
    ///   - alarmOffset: 從當天 00:00 到提醒時間的秒數
    /// - Returns: 事件識別碼
    /// - Throws: 無可寫入行事曆、事件儲存失敗或取不到事件識別碼
    var addReminder: @Sendable (
        _ title: String,
        _ date: Date,
        _ alarmOffset: TimeInterval
    ) async throws(CalendarReminderError) -> String
    
    /// 依識別碼移除事件；找不到視為 no-op
    /// - Parameter eventIdentifier: 要移除的事件識別碼
    /// - Returns: 無回傳值，找不到事件視為 no-op
    /// - Throws: 行事曆移除失敗時拋出 ``CalendarReminderError``
    var removeReminder: @Sendable (_ eventIdentifier: String) async throws(CalendarReminderError) -> Void
    
    /// 依識別碼查詢事件是否仍存在
    /// - Parameter eventIdentifier: 要查詢的事件識別碼
    /// - Returns: 事件是否仍存在
    var reminderExists: @Sendable (_ eventIdentifier: String) async -> Bool
}

// MARK: - Nested Types

extension CalendarReminderClient {
    
    /// 行事曆存取請求的結果
    enum Access: Equatable, Sendable {
        
        // MARK: - Cases
        
        /// 已授予完整存取
        case granted
        
        /// 使用者拒絕存取
        case denied
        
        /// 存取受裝置政策限制 (如家長監護、MDM)，使用者無法自行到設定開啟
        case restricted
    }
}

/// 建立或移除提醒事件時可能拋出的錯誤
enum CalendarReminderError: Error, Equatable, Sendable {
    
    // MARK: - Cases
    
    /// 事件已存檔但取不到識別碼 (理論上不應發生)
    case eventIdentifierMissing
    
    /// 已授權，但找不到可寫入的行事曆
    case noWritableCalendar
    
    /// 系統行事曆 API 回傳其他錯誤
    case system(message: String)
}

// MARK: - Private Method

private extension CalendarReminderClient {
    
    /// 將事件儲存到系統行事曆
    /// - Parameters:
    ///   - event: 要儲存的事件
    ///   - store: EventKit 行事曆資料庫
    /// - Throws: EventKit 儲存失敗時轉成 ``CalendarReminderError/system(message:)``
    static func saveCalendarEvent(_ event: EKEvent, using store: EKEventStore) throws(CalendarReminderError) {
        do {
            try store.save(event, span: .thisEvent, commit: true)
        } catch {
            throw CalendarReminderError.system(message: error.localizedDescription)
        }
    }
    
    /// 從系統行事曆移除事件
    /// - Parameters:
    ///   - event: 要移除的事件
    ///   - store: EventKit 行事曆資料庫
    /// - Throws: EventKit 移除失敗時轉成 ``CalendarReminderError/system(message:)``
    static func removeCalendarEvent(_ event: EKEvent, using store: EKEventStore) throws(CalendarReminderError) {
        do {
            try store.remove(event, span: .thisEvent, commit: true)
        } catch {
            throw CalendarReminderError.system(message: error.localizedDescription)
        }
    }
    
    /// 請求完整的行事曆存取權限
    /// - Returns: 系統判定的權限結果
    static func requestCalendarAccess() async -> CalendarReminderClient.Access {
        let store = EKEventStore()
        // 受限狀態 (家長監護／MDM) 請求前就能判定，短路避免徒勞請求
        if EKEventStore.authorizationStatus(for: .event) == .restricted {
            return .restricted
        }
        let granted: Bool
        do {
            granted = try await store.requestFullAccessToEvents()
        } catch {
            return EKEventStore.authorizationStatus(for: .event) == .restricted ? .restricted : .denied
        }
        if granted {
            return .granted
        }
        // 請求後再次確認授權狀態
        return EKEventStore.authorizationStatus(for: .event) == .restricted ? .restricted : .denied
    }
    
    /// 建立全天提醒事件
    /// - Parameters:
    ///   - title: 提醒事件標題
    ///   - date: 事件日期
    ///   - alarmOffset: 從當天 00:00 到提醒時間的秒數
    /// - Returns: 事件識別碼
    /// - Throws: 無可寫入行事曆、事件儲存失敗或取不到事件識別碼
    static func addCalendarReminder(
        _ title: String,
        _ date: Date,
        _ alarmOffset: TimeInterval
    ) async throws(CalendarReminderError) -> String {
        let store = EKEventStore()
        guard let calendar = store.defaultCalendarForNewEvents,
              calendar.allowsContentModifications else {
            throw CalendarReminderError.noWritableCalendar
        }
        let event = EKEvent(eventStore: store)
        event.title = title
        event.isAllDay = true
        event.startDate = date
        event.endDate = date
        event.calendar = calendar
        // 全天事件的提示從當天 00:00 起算
        event.addAlarm(EKAlarm(relativeOffset: alarmOffset))
        try saveCalendarEvent(event, using: store)
        guard let identifier = event.eventIdentifier else {
            throw CalendarReminderError.eventIdentifierMissing
        }
        return identifier
    }
    
    /// 依識別碼移除行事曆事件
    /// - Parameter identifier: 事件識別碼
    /// - Throws: EventKit 移除失敗時轉成 ``CalendarReminderError/system(message:)``
    static func removeCalendarReminder(_ identifier: String) async throws(CalendarReminderError) {
        let store = EKEventStore()
        guard let event = store.event(withIdentifier: identifier) else {
            return
        }
        try removeCalendarEvent(event, using: store)
    }
    
    /// 依識別碼確認行事曆事件是否存在
    /// - Parameter identifier: 事件識別碼
    /// - Returns: 事件是否存在
    static func calendarReminderExists(_ identifier: String) -> Bool {
        let store = EKEventStore()
        return store.event(withIdentifier: identifier) != nil
    }
}

// MARK: - Dependency Values

extension CalendarReminderClient: DependencyKey {
    
    /// App 執行時以真實 `EKEventStore` 操作系統行事曆
    nonisolated static let liveValue = CalendarReminderClient(
        requestAccess: Self.requestCalendarAccess,
        addReminder: Self.addCalendarReminder,
        removeReminder: Self.removeCalendarReminder,
        reminderExists: Self.calendarReminderExists
    )
    
    /// 測試用的固定行事曆結果；可用 withDependencies 覆寫
    nonisolated static let testValue = CalendarReminderClient(
        requestAccess: { .granted },
        addReminder: { _, _, _ in "test-event-identifier" },
        removeReminder: { _ in },
        reminderExists: { _ in false }
    )
    
    /// SwiftUI Preview 不觸碰系統行事曆
    nonisolated static let previewValue = CalendarReminderClient(
        requestAccess: { .denied },
        addReminder: { _, _, _ in "preview-event-identifier" },
        removeReminder: { _ in },
        reminderExists: { _ in false }
    )
}
