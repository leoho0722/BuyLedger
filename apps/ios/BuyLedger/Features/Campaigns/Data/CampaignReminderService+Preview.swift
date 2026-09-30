//
//  CampaignReminderService+Preview.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

#if DEBUG

// MARK: - DependencyKey

extension CampaignReminderService {

    /// Preview 使用共用的 Preview Database 讀寫開團提醒連結
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "CampaignReminderService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return liveValue
    }
}

#endif
