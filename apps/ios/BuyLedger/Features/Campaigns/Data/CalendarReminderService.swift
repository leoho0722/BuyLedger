//
//  CalendarReminderService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

import ComposableArchitecture
import EventKit
import Foundation

/// 系統行事曆提醒的操作入口；
/// 正式實作在 `liveValue`、Preview 假資料在 `previewValue`、測試預設值在 `testValue`
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
    /// - Throws: 找不到可寫入行事曆時丟出 `.noWritableCalendar`；
    ///   儲存失敗時丟出 `.system(underlying:)`；
    ///   取不到事件識別碼時丟出 `.eventIdentifierMissing`
    var addReminder: AddReminder

    /// 依識別碼移除事件；找不到時不做任何事
    ///
    /// - Parameter eventIdentifier: 要移除的事件識別碼
    /// - Throws: 系統移除失敗時丟出 `.system(underlying:)`
    var removeReminder: RemoveReminder
}

// MARK: - Nested Types

extension CalendarReminderService {

    /// `requestAccess` 的函式型別
    typealias RequestAccess = @Sendable () async -> CalendarAccessResult

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
}

// MARK: - DependencyKey

extension CalendarReminderService: DependencyKey {

    /// 正式 App 使用 `EKEventStore` 操作系統行事曆
    static var liveValue: Self {
        Self(
            requestAccess: {
                let store = EKEventStore()
                // 受限狀態 (家長監護、企業的裝置管理) 請求前就能判定，短路避免徒勞請求
                if EKEventStore.authorizationStatus(for: .event) == .restricted {
                    return .restricted
                }
                let isGranted: Bool
                do {
                    isGranted = try await store.requestFullAccessToEvents()
                } catch {
                    if EKEventStore.authorizationStatus(for: .event) == .restricted {
                        return .restricted
                    }
                    return .denied
                }
                if isGranted {
                    return .granted
                }
                // 請求回傳 `false` 時以最新授權狀態區分受限與使用者拒絕
                if EKEventStore.authorizationStatus(for: .event) == .restricted {
                    return .restricted
                }
                return .denied
            },
            addReminder: { title, date, alarmOffset throws(CalendarReminderError) in
                let store = EKEventStore()
                guard let calendar = store.defaultCalendarForNewEvents,
                      calendar.allowsContentModifications else {
                    throw .noWritableCalendar
                }
                let event = EKEvent(eventStore: store)
                event.title = title
                event.isAllDay = true
                event.startDate = date
                event.endDate = date
                event.calendar = calendar
                // 全天事件的提示從當天 00:00 起算
                event.addAlarm(EKAlarm(relativeOffset: alarmOffset))
                do {
                    try store.save(event, span: .thisEvent, commit: true)
                } catch {
                    throw .system(underlying: error as NSError)
                }
                guard let identifier = event.eventIdentifier else {
                    throw .eventIdentifierMissing
                }
                return identifier
            },
            removeReminder: { eventIdentifier throws(CalendarReminderError) in
                let store = EKEventStore()
                guard let event = store.event(withIdentifier: eventIdentifier) else {
                    return
                }
                do {
                    try store.remove(event, span: .thisEvent, commit: true)
                } catch {
                    throw .system(underlying: error as NSError)
                }
            }
        )
    }

    #if DEBUG

    /// Preview 不觸碰系統行事曆，只回傳固定的提醒結果
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "CalendarReminderService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return Self(
            requestAccess: { .denied },
            addReminder: { _, _, _ in "preview-event-identifier" },
            removeReminder: { _ in }
        )
    }

    #endif

    /// 測試預設拒絕行事曆權限，未覆寫的操作會回報未實作 issue
    static var testValue: Self {
        Self(
            requestAccess: unimplemented(
                "CalendarReminderService.requestAccess",
                placeholder: .denied
            ),
            addReminder: unimplemented("CalendarReminderService.addReminder", placeholder: ""),
            removeReminder: unimplemented("CalendarReminderService.removeReminder")
        )
    }
}

// MARK: - DependencyValues

extension DependencyValues {

    /// 供開團功能取得系統行事曆提醒操作
    var calendarReminderService: CalendarReminderService {
        get { self[CalendarReminderService.self] }
        set { self[CalendarReminderService.self] = newValue }
    }
}
