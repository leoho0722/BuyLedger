//
//  BLUITestCurrencyMetadataConfigurationStore.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

#if DEBUG

/// 提供 UI 測試匯率 API key 的設定來源
struct BLUITestCurrencyMetadataConfigurationStore {}

// MARK: - AppConfigurationStoreProtocol

extension BLUITestCurrencyMetadataConfigurationStore: AppConfigurationStoreProtocol {

    /// 回傳 UI 測試使用的 API key
    ///
    /// - Parameter key: 要讀取的 Info.plist 設定名稱
    /// - Returns: 匯率 API key 或 nil
    func string(forKey key: String) -> String? {
        guard key == ExchangeRateEndpoint.apiKeyConfigurationKey else {
            return nil
        }
        return BLUITestStubs.stubAPIKey
    }
}

#endif
