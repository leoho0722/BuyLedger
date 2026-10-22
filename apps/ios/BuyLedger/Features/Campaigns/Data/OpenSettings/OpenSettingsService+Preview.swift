//
//  OpenSettingsService+Preview.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

#if DEBUG

// MARK: - DependencyKey

extension OpenSettingsService {

    /// Preview 不開啟系統設定頁，只做空操作
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "OpenSettingsService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return Self(
            open: {}
        )
    }
}

#endif
