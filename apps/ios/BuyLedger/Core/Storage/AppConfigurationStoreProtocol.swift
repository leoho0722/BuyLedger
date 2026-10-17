//
//  AppConfigurationStoreProtocol.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

/// App `Info.plist` 字串設定的讀取介面
protocol AppConfigurationStoreProtocol: Sendable {

    /// 讀取並正規化指定 `key` 的字串值
    ///
    /// - Parameter key: `Info.plist` 中的設定 `key`
    /// - Returns: 正規化後的字串，或在值未設定時回傳 nil
    func string(forKey key: String) -> String?
}
