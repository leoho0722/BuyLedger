//
//  CurrencyDisplayName.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/19.
//

import Foundation

/// 提供幣別顯示名稱與搜尋關鍵字的單一入口
enum CurrencyDisplayName {
}

// MARK: - Internal Method

extension CurrencyDisplayName {

    /// 依 App 語言取得畫面上顯示的幣別名稱
    ///
    /// - Parameters:
    ///   - code: 幣別的 ISO 4217 代碼
    ///   - language: App 目前使用的語言
    /// - Returns: 正體中文時回傳本地化名稱；查不到或為空字串時回傳 ISO 代碼，英文一律回傳 ISO 代碼
    static func text(code: String, language: AppLanguage) -> String {
        guard language == .traditionalChinese else {
            return code
        }

        let name = localizedName(code: code, locale: language.locale)
        return name.isEmpty ? code : name
    }

    /// 取得 picker 搜尋用的目前 locale 本地化名稱
    ///
    /// - Parameters:
    ///   - code: 幣別的 ISO 4217 代碼
    ///   - locale: 查找本地化名稱使用的 locale
    /// - Returns: 本地化名稱；查不到時為空字串
    static func searchKeywords(code: String, locale: Locale) -> String {
        localizedName(code: code, locale: locale)
    }

    /// 建立幣別選擇器共用的顯示名稱與搜尋方式
    ///
    /// - Parameter locale: 目前套用的顯示與搜尋語系
    /// - Returns: 依 App 語言顯示名稱，並依語系提供搜尋補充文字的設定
    static func optionLabeling(locale: Locale) -> OptionPickerSheet.Labeling {
        let language = AppLanguage(locale: locale)
        return OptionPickerSheet.Labeling {
            text(code: $0, language: language)
        } searchKeywords: {
            searchKeywords(code: $0, locale: locale)
        }
    }
}

// MARK: - Private Method

private extension CurrencyDisplayName {

    /// 以 Foundation 查找幣別的本地化名稱
    ///
    /// - Parameters:
    ///   - code: 幣別的 ISO 4217 代碼
    ///   - locale: 查找本地化名稱使用的 locale
    /// - Returns: Foundation 回傳的名稱；查不到時為空字串
    static func localizedName(code: String, locale: Locale) -> String {
        locale.localizedString(forCurrencyCode: code) ?? ""
    }
}
