//
//  AppLanguage.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/17.
//

import SwiftUI

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
    
    /// 從 SwiftUI 注入的 locale 判斷對應語言 (非中文一律視為英文)
    /// - Parameter locale: 目前套用的 locale，通常來自 `@Environment(\.locale)`
    init(locale: Locale) {
        self = locale.language.languageCode?.identifier == "zh" ? .traditionalChinese : .english
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

// MARK: - Internal Method

extension AppLanguage {
    
    /// 使用此 App 語言的 String Catalog 解析使用者可見字串
    /// - Parameter key: String Catalog source key
    /// - Returns: 解析後的目標語言字串
    func localized(_ key: String.LocalizationValue) -> String {
        String(localized: key, bundle: localizedBundle)
    }
}

// MARK: - View Method

extension View {
    
    /// 以 App 語言解析根分頁標題
    /// - Parameters:
    ///   - key: String Catalog source key
    ///   - language: 用來解析標題的目前 App 語言
    /// - Returns: 套用解析後導覽標題的 view
    func rootNavigationTitle(
        _ key: String.LocalizationValue,
        language: AppLanguage
    ) -> some View {
        navigationTitle(language.localized(key))
    }
}

// MARK: - Private Method

private extension AppLanguage {
    
    /// 對應語言的 String Catalog bundle
    var localizedBundle: Bundle {
        guard let url = Bundle.main.url(forResource: localeIdentifier, withExtension: "lproj"),
              let bundle = Bundle(url: url) else {
            assertionFailure("Missing \(localeIdentifier).lproj for AppLanguage")
            return .main
        }
        
        return bundle
    }
}
