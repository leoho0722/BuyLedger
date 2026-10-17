//
//  SettingsService+Preview.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/27.
//

#if DEBUG

// MARK: - DependencyKey

extension SettingsService {

    /// 預覽使用預設設定；在正式 App 中誤用時偵錯版會立刻中止
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "SettingsService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return Self(
            load: { .default },
            save: { _ in }
        )
    }
}

#endif
