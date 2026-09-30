//
//  PreviewAppConfigurationStore.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

#if DEBUG

/// Preview 使用固定假值回應設定查詢
struct PreviewAppConfigurationStore {

    // MARK: - Init

    /// 建立只供 Preview 與測試環境使用的設定 stub
    init() {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "PreviewAppConfigurationStore 只能在 Preview、UI Test 或單元測試中使用"
        )
    }
}

// MARK: - AppConfigurationStoreProtocol

extension PreviewAppConfigurationStore: AppConfigurationStoreProtocol {

    /// 不讀取 `Bundle`，固定回傳 Preview 設定值
    ///
    /// - Parameter key: 未使用的 `Info.plist` 設定 `key`
    /// - Returns: 固定的 Preview 假值
    func string(forKey key: String) -> String? {
        "preview-stub-key"
    }
}

#endif
