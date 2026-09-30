//
//  PaymentMethodService+Preview.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

#if DEBUG

// MARK: - DependencyKey

extension PaymentMethodService {

    /// Preview 使用共用的 Preview Database 執行付款方式操作
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "PaymentMethodService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return liveValue
    }
}

#endif
