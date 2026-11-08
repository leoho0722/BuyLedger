//
//  AppLanguage.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/17.
//

import SwiftUI

/// App 介面語言偏好
enum AppLanguage: String, CaseIterable, Sendable {

    /// 正體中文
    case traditionalChinese

    /// 英文
    case english

    // MARK: - Init

    /// 從持久化值建立語言偏好；缺值或未知值一律安全回退正體中文
    ///
    /// - Parameter storedValue: `UserDefaults` 儲存的 raw value
    init(storedValue: String?) {
        self = storedValue.flatMap(Self.init(rawValue:)) ?? .traditionalChinese
    }

    /// 從 SwiftUI 注入的 locale 判斷對應語言 (非中文一律視為英文)
    ///
    /// - Parameter locale: 目前套用的 locale，通常來自 `@Environment(\.locale)`
    init(locale: Locale) {
        self = locale.language.languageCode?.identifier == "zh" ? .traditionalChinese : .english
    }
}

// MARK: - Computed Properties

extension AppLanguage {

    /// 顯示在介面中的名稱 (原文自稱 Endonym)
    var title: String {
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

    /// 使用此 App 語言解析 String Catalog resource
    ///
    /// - Parameter resource: 要解析的 `LocalizedStringResource`
    /// - Returns: 依此 App 語言解析後的字串
    func resolve(_ resource: LocalizedStringResource) -> String {
        var resource = resource
        resource.locale = locale
        return String(localized: resource)
    }

    /// 依指定 Locale 判斷 App 語言並解析 String Catalog resource
    ///
    /// - Parameters:
    ///   - resource: 要解析的 `LocalizedStringResource`
    ///   - locale: 目前的 Locale，通常來自 `@Environment(\.locale)`
    /// - Returns: 依該 App 語言解析後的字串
    static func resolve(_ resource: LocalizedStringResource, locale: Locale) -> String {
        AppLanguage(locale: locale).resolve(resource)
    }
}

// MARK: - Identifiable

extension AppLanguage: Identifiable {

    /// 偏好的穩定識別值
    var id: String {
        rawValue
    }
}

// MARK: - rootNavigationTitle

extension View {

    /// 以 App 語言解析根分頁標題
    ///
    /// - Parameters:
    ///   - resource: String Catalog resource
    ///   - language: 用來解析標題的目前 App 語言
    /// - Returns: 套用解析後導覽標題的 view
    func rootNavigationTitle(
        _ resource: LocalizedStringResource,
        language: AppLanguage
    ) -> some View {
        navigationTitle(language.resolve(resource))
    }
}
