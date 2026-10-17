//
//  CalendarReminderService+Dependency.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

import ComposableArchitecture
import EventKit

// MARK: - DependencyKey

extension CalendarReminderService: DependencyKey {

    /// 正式 App 使用 `EKEventStore` 操作系統行事曆
    static var liveValue: Self {
        Self(
            requestAccess: {
                let store = EKEventStore()
                // 受限狀態 (家長監護／MDM) 請求前就能判定，短路避免徒勞請求
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
                // 請求回傳 false 時以最新授權狀態區分受限與使用者拒絕
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
