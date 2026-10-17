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
    /// - Parameter storedValue: `UserDefaults` 儲存的 raw value
    init(storedValue: String?) {
        self = storedValue.flatMap(Self.init(rawValue:)) ?? .traditionalChinese
    }

    /// 從 SwiftUI 注入的 locale 判斷對應語言 (非中文一律視為英文)
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

    /// 使用此 App 語言的 String Catalog 解析使用者可見字串
    /// - Parameter key: String Catalog source key
    /// - Returns: 解析後的目標語言字串
    func localized(_ key: String.LocalizationValue) -> String {
        if let (baseKey, args) = extractKeyAndArgs(key), !args.isEmpty {
            let format = localizedBundle.localizedString(forKey: baseKey, value: baseKey, table: nil)
            if format != baseKey {
                return localizedString(forKey: baseKey, arguments: args)
            }
        }
        return String(localized: key, bundle: localizedBundle)
    }

    /// 使用此 App 語言的 String Catalog 解析帶引數的格式化字串 (支援單複數與位置引數)
    /// - Parameters:
    ///   - key: String Catalog 鍵值
    ///   - arguments: 格式化引數清單
    /// - Returns: 解析並格式化後的目標語言字串
    func localizedString(forKey key: String, arguments: [CVarArg]) -> String {
        let format = localizedBundle.localizedString(forKey: key, value: key, table: nil)
        return String(format: format, locale: locale, arguments: arguments)
    }

    /// 使用此 App 語言的 String Catalog 解析帶引數的格式化字串 (支援單複數與位置引數)
    /// - Parameters:
    ///   - key: String Catalog 鍵值
    ///   - arguments: 格式化引數清單
    /// - Returns: 解析並格式化後的目標語言字串
    func localizedString(forKey key: String, _ arguments: CVarArg...) -> String {
        localizedString(forKey: key, arguments: arguments)
    }

    /// 依指定的 Locale 解析 App 語言並格式化字串
    /// - Parameters:
    ///   - key: String Catalog 鍵值
    ///   - arguments: 格式化引數清單
    ///   - locale: 目前的 Locale
    /// - Returns: 解析並格式化後的目標語言字串
    static func format(_ key: String, _ arguments: CVarArg..., locale: Locale) -> String {
        AppLanguage(locale: locale).localizedString(forKey: key, arguments: arguments)
    }
}

// MARK: - Identifiable

extension AppLanguage: Identifiable {

    /// 偏好的穩定識別值
    var id: String { rawValue }
}

// MARK: - rootNavigationTitle

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
        if let url = Bundle.main.url(forResource: localeIdentifier, withExtension: "lproj") {
            if let bundle = Bundle(url: url) {
                return bundle
            }
        }

        assertionFailure("Missing \(localeIdentifier).lproj for AppLanguage")
        return .main
    }

    /// 從 String.LocalizationValue 提取結構化 baseKey 與引數清單
    /// - Parameter key: String.LocalizationValue 鍵值
    /// - Returns: 若包含結構化 Key 則返回基底 Key 與引數
    func extractKeyAndArgs(_ key: String.LocalizationValue) -> (baseKey: String, args: [CVarArg])? {
        let mirror = Mirror(reflecting: key)
        var keyStr: String?
        var extractedArgs: [CVarArg] = []

        for child in mirror.children {
            if let k = child.value as? String {
                keyStr = k
            } else {
                let argsMirror = Mirror(reflecting: child.value)
                for argChild in argsMirror.children {
                    let storageMirror = Mirror(reflecting: argChild.value)
                    for s in storageMirror.children {
                        let valMirror = Mirror(reflecting: s.value)
                        for v in valMirror.children {
                            if let cv = v.value as? CVarArg {
                                extractedArgs.append(cv)
                            }
                        }
                    }
                }
            }
        }

        guard let rawKey = keyStr else { return nil }
        guard let firstSpace = rawKey.firstIndex(of: " ") else {
            return (rawKey, extractedArgs)
        }
        let baseKey = String(rawKey[..<firstSpace])
        return (baseKey, extractedArgs)
    }
}
