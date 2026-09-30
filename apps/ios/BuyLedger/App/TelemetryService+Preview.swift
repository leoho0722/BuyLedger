//
//  TelemetryService+Preview.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

#if DEBUG

// MARK: - DependencyKey

extension TelemetryService {

    /// Preview 不送出遙測資料；在正式 App 中誤用時偵錯版會立刻中止
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "TelemetryService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return Self(
            enablePreInitializationCollection: {},
            enableCollection: {}
        )
    }
}

#endif
