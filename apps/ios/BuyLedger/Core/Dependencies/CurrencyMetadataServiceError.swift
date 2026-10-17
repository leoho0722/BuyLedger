//
//  CurrencyMetadataServiceError.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

/// 讀取或更新幣別主檔時可能拋出的錯誤
enum CurrencyMetadataServiceError: Error, Sendable {

    /// 遠端匯率服務失敗
    ///
    /// - Parameter apiError: 遠端匯率服務拋出的錯誤
    case api(APIError)

    /// 本機幣別資料失敗
    ///
    /// - Parameter currencyMetadataPersistenceError: 本機幣別資料拋出的錯誤
    case persistence(CurrencyMetadataPersistenceError)
}
