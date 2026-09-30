//
//  BLUITestErrorFactory.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

#if DEBUG

import Foundation

/// UI 測試注入用的錯誤工廠
enum BLUITestErrorFactory {}

// MARK: - Internal Method

extension BLUITestErrorFactory {

    /// 產生指定資料來源的持久化讀取失敗
    ///
    /// - Parameter source: 失敗的資料來源
    /// - Returns: 帶資料來源訊息的 `.fetchFailed(underlying:)`
    static func persistenceLoadFailed(source: BLUITestLoadSource) -> PersistenceError {
        .fetchFailed(
            underlying: NSError(
                domain: "com.leoho.BuyLedger.ui-test",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "UI 測試注入的載入失敗 (\(source.rawValue))"]
            )
        )
    }

    /// 產生幣別 metadata Service 讀取失敗
    ///
    /// - Parameter source: 失敗的資料來源
    /// - Returns: 帶資料來源訊息的幣別 metadata Service 錯誤
    static func currencyMetadataLoadFailed(
        source: BLUITestLoadSource
    ) -> CurrencyMetadataServiceError {
        .persistence(.storage(persistenceLoadFailed(source: source)))
    }

    /// 產生 UI 測試注入的持久化寫入失敗
    ///
    /// - Returns: 帶有測試用原因的持久化寫入錯誤
    static func persistenceSaveFailed() -> PersistenceError {
        .saveFailed(
            underlying: NSError(
                domain: "com.leoho.BuyLedger.ui-test",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "UI 測試注入的主檔寫入失敗"]
            )
        )
    }

    /// 產生「匯率替身沒有這個基準幣別」的錯誤
    ///
    /// - Parameter base: 被要求的基準幣別代碼
    /// - Returns: 描述基準幣別不支援的 ``APIError``
    static func unsupportedBase(_ base: String) -> APIError {
        .apiError(code: "unsupported-base-\(base)")
    }
}

#endif
