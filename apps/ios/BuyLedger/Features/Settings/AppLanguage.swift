//
//  AppLanguage.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/17.
//

import Foundation

/// App 介面語言偏好
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {

    // MARK: - Cases

    /// 正體中文
    case traditionalChinese

    /// 英文
    case english

    // MARK: - Identifiable Properties

    /// 偏好的穩定識別值
    var id: String { rawValue }

    // MARK: - Init

    /// 從持久化值建立語言偏好；缺值或未知值一律安全回退正體中文
    /// - Parameter storedValue: `UserDefaults` 儲存的 raw value
    init(storedValue: String?) {
        self = storedValue.flatMap(Self.init(rawValue:)) ?? .traditionalChinese
    }

    // MARK: - Computed Properties

    /// 顯示在介面中的名稱
    var title: LocalizedStringResource {
        switch self {
        case .traditionalChinese:
            "正體中文"
        case .english:
            "English"
        }
    }

    /// 對應 Foundation locale identifier
    var localeIdentifier: String {
        switch self {
        case .traditionalChinese:
            "zh-Hant"
        case .english:
            "en"
        }
    }

    /// 對應 Foundation locale
    var locale: Locale {
        Locale(identifier: localeIdentifier)
    }
}
