//
//  ExchangeRateService+Preview.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

#if DEBUG

// MARK: - DependencyKey

extension ExchangeRateService {

    /// Preview 使用固定匯率資料
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "ExchangeRateService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return Self(
            fetchLatest: { _ in FxRateSnapshot.fallback }
        )
    }
}

#endif
