//
//  CalendarReminderService+Preview.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

#if DEBUG

// MARK: - DependencyKey

extension CalendarReminderService {

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
}

#endif
