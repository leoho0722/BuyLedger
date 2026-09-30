//
//  AppConfigurationStore.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

import Foundation

/// 從指定的 `Bundle` 讀取並正規化 `Info.plist` 字串
struct AppConfigurationStore {

    // MARK: - Properties

    /// 提供 `Info.plist` 設定的 `Bundle`
    private let bundle: Bundle

    // MARK: - Init

    /// 建立正式實作
    ///
    /// - Parameter bundle: 提供 `Info.plist` 的 `Bundle`
    init(bundle: Bundle) {
        self.bundle = bundle
    }
}

// MARK: - AppConfigurationStoreProtocol

extension AppConfigurationStore: AppConfigurationStoreProtocol {

    /// 從注入的 `Bundle` 讀取字串，修剪空白並略過空值或未展開的佔位字串
    ///
    /// - Parameter key: `Info.plist` 中的設定 `key`
    /// - Returns: 正規化後的字串，或在值未設定時回傳 nil
    func string(forKey key: String) -> String? {
        let rawValue = bundle.object(forInfoDictionaryKey: key) as? String
        let trimmed = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines)
        let placeholder = "$(\(key))"

        guard let trimmed, !trimmed.isEmpty, trimmed != placeholder else {
            return nil
        }

        return trimmed
    }
}
