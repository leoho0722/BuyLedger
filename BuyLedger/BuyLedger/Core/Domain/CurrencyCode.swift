//
//  CurrencyCode.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// BuyLedger 用來表示交易幣別的 value type。
///
/// 從原本 `enum String` 改成 `struct` wrapper，目的是不再被 5 個 hardcoded case 綁住——實際可用清單由 ``ExchangeRateClient/fetchSupportedCodes`` 取得後存入 ``CurrencyMetadataRepository``。`rawValue` 仍為 ISO 4217 三位 code（例如 `"USD"`、`"TWD"`），跟舊 enum 的 `rawValue` 完全相同，因此：
/// - SwiftData 既有的 `String` column 不需要 migration plan，lightweight migration 即可
/// - `Codable` 透過 ``Codable/init(from:)`` 與 ``Codable/encode(to:)`` 用 single value container 編 raw string，跨版本 JSON 相容
/// - 在地化名稱不再硬編，view 端使用 ``localizedName(in:)`` 透過 `Locale.localizedString(forCurrencyCode:)` 動態取得（跟隨使用者手機）
struct CurrencyCode: Hashable, Sendable, Identifiable {

    // MARK: - Data Properties

    /// ISO 4217 幣別代碼，例如 `"TWD"`、`"USD"`。
    let rawValue: String

    // MARK: - Identifiable Properties

    /// 以 ``rawValue`` 作為穩定識別值。
    var id: String { rawValue }

    // MARK: - Display Properties

    /// 等同 ``rawValue``，提供給 `FormatStyle.currency(code:)` 等需要 ISO 4217 字串的 API。
    var code: String { rawValue }

    // MARK: - Init

    /// 由 ISO 4217 code 建立。
    /// - Parameter rawValue: ISO 4217 三位代碼。
    init(rawValue: String) {
        self.rawValue = rawValue
    }

    // MARK: - View Method

    /// 取得依指定 locale 的在地化幣別名稱。
    /// - Parameter locale: 想顯示的 locale，預設為 `.current`；view 端常傳手機偏好 locale。
    /// - Returns: 在地化字串，例如 `"美元"`、`"日圓"`；若 locale 無對應翻譯則 fallback 為 ``rawValue``。
    func localizedName(in locale: Locale = .current) -> String {
        locale.localizedString(forCurrencyCode: rawValue) ?? rawValue
    }
}

// MARK: - Codable

extension CurrencyCode: Codable {

    /// 從 single value container 取 raw string；跟舊 enum 的 `Codable` 二進位／JSON 相容。
    /// - Parameter decoder: 解碼器。
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    /// 寫入 raw string 到 single value container。
    /// - Parameter encoder: 編碼器。
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

// MARK: - Static Properties

extension CurrencyCode {

    /// App 預設的「常用幣別」候選集；在 API codes 尚未載入時（首次安裝＋無網路）作為 Picker 可選項，並提供給 sample data 與 unit test 直接引用。
    static let defaults: [CurrencyCode] = [.twd, .krw, .jpy, .usd, .cny]

    /// 新台幣（基準幣別，全 App 預設）。
    static let twd = CurrencyCode(rawValue: "TWD")

    /// 韓圜。
    static let krw = CurrencyCode(rawValue: "KRW")

    /// 日圓。
    static let jpy = CurrencyCode(rawValue: "JPY")

    /// 美元。
    static let usd = CurrencyCode(rawValue: "USD")

    /// 人民幣。
    static let cny = CurrencyCode(rawValue: "CNY")
}
