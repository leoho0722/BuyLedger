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
///
/// 以依賴反轉隔離 `EKEventStore` 的系統呼叫，讓 ``CampaignFeature`` 的提醒流程可在 TestStore 中以 fake 實作完整驗證。因需支援「移除」既有事件 (須先以識別碼讀回事件)，故請求完整存取 (full access) 而非僅寫入
struct CalendarReminderClient: Sendable {

    // MARK: - Dependency Properties

    /// 請求行事曆完整存取，回傳是否獲授權
    var requestAccess: @Sendable () async -> Bool

    /// 以標題、日期與提示位移建立全天提醒事件，回傳事件識別碼
    ///
    /// `alarmOffset` 為提示自事件起始 (當天 00:00) 起算的秒數，由 caller 以每團設定的提示時間換算 (例如 09:00 = `9 * 3600`)
    var addReminder: @Sendable (_ title: String, _ date: Date, _ alarmOffset: TimeInterval) async throws -> String

    /// 依識別碼移除事件；找不到視為 no-op
    var removeReminder: @Sendable (_ eventIdentifier: String) async throws -> Void

    /// 依識別碼查詢事件是否仍存在
    var reminderExists: @Sendable (_ eventIdentifier: String) async -> Bool
}

// MARK: - Nested Types

extension CalendarReminderClient {

    /// 建立提醒事件時可能拋出的錯誤
    enum Failure: Error {

        // MARK: - Cases

        /// 事件已存檔但取不到識別碼 (理論上不應發生)
        case eventIdentifierMissing
    }
}

extension CalendarReminderClient: DependencyKey {

    // MARK: - Dependency Values

    /// App 執行時以真實 `EKEventStore` 操作系統行事曆；每次呼叫建立獨立 store 以符合 `@Sendable` 隔離，事件識別碼為行事曆全域穩定值、跨 store 實例可讀回
    nonisolated static let liveValue = CalendarReminderClient(
        requestAccess: {
            let store = EKEventStore()
            return (try? await store.requestFullAccessToEvents()) ?? false
        },
        addReminder: { title, date, alarmOffset in
            let store = EKEventStore()
            let event = EKEvent(eventStore: store)
            event.title = title
            event.isAllDay = true
            event.startDate = date
            event.endDate = date
            event.calendar = store.defaultCalendarForNewEvents
            // 全天事件的提示以事件起始 (當天 00:00) 起算，alarmOffset 為由每團提示時間換算的秒數
            event.addAlarm(EKAlarm(relativeOffset: alarmOffset))
            try store.save(event, span: .thisEvent, commit: true)
            guard let identifier = event.eventIdentifier else {
                throw Failure.eventIdentifierMissing
            }
            return identifier
        },
        removeReminder: { identifier in
            let store = EKEventStore()
            guard let event = store.event(withIdentifier: identifier) else {
                return
            }
            try store.remove(event, span: .thisEvent, commit: true)
        },
        reminderExists: { identifier in
            let store = EKEventStore()
            return store.event(withIdentifier: identifier) != nil
        }
    )

    /// 測試預設：授權成功、建立回傳固定識別碼、移除為 no-op、查詢一律不存在；TestStore 可透過 `withDependencies` 覆寫
    nonisolated static let testValue = CalendarReminderClient(
        requestAccess: { true },
        addReminder: { _, _, _ in "test-event-identifier" },
        removeReminder: { _ in },
        reminderExists: { _ in false }
    )

    /// SwiftUI Preview 不觸碰系統行事曆
    nonisolated static let previewValue = CalendarReminderClient(
        requestAccess: { false },
        addReminder: { _, _, _ in "preview-event-identifier" },
        removeReminder: { _ in },
        reminderExists: { _ in false }
    )
}
