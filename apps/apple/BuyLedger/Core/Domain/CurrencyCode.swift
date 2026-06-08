//
//  CurrencyCode.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//
//  資料形狀 (rawValue、Identifiable、init) 由 Generated/CurrencyCode.generated.swift 產生；
//  本檔僅保留手寫業務邏輯 (顯示、在地化、自訂 Codable、常用幣別常數)。
//  改欄位請改 shared/data-model/schema/ 後重新 generate。
//

import Foundation

// MARK: - Display Properties

extension CurrencyCode {

    /// 等同 ``rawValue``，提供給 `FormatStyle.currency(code:)` 等需要 ISO 4217 字串的 API。
    var code: String { rawValue }
}

// MARK: - View Method

extension CurrencyCode {

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
        self.init(rawValue: try container.decode(String.self))
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

    /// App 預設的「常用幣別」候選集；在 API codes 尚未載入時 (首次安裝＋無網路) 作為 Picker 可選項，並提供給 sample data 與 unit test 直接引用。
    static let defaults: [CurrencyCode] = [.twd, .krw, .jpy, .usd, .cny]

    /// 新台幣 (基準幣別，全 App 預設)。
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
