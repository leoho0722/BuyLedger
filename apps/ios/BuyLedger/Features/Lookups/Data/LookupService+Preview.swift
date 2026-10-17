//
//  LookupService+Preview.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

#if DEBUG

// MARK: - DependencyKey

extension LookupService {

    /// Preview 使用共用的 Preview Database 執行主檔操作
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "LookupService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return liveValue
    }
}

#endif
