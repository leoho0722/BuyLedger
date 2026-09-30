//
//  CurrencyMetadataService+Preview.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

#if DEBUG

// MARK: - DependencyKey

extension CurrencyMetadataService {

    /// Preview 使用固定幣別清單，不存取資料庫或網路
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "CurrencyMetadataService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return Self(
            fetchCodes: { CurrencyCode.defaults },
            refreshIfStale: { _ in false }
        )
    }
}

#endif
