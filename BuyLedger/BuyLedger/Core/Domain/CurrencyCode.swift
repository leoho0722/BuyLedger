//
//  CurrencyCode.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// BuyLedger 支援的交易幣別代碼。
enum CurrencyCode: String, CaseIterable, Codable, Identifiable, Sendable {

    // MARK: - Cases

    /// 新台幣。
    case twd = "TWD"

    /// 韓圜。
    case krw = "KRW"

    /// 日圓。
    case jpy = "JPY"

    /// 美元。
    case usd = "USD"

    /// 歐元。
    case eur = "EUR"

    // MARK: - Identifiable Properties

    /// 幣別的穩定識別值。
    var id: String { rawValue }

    // MARK: - Display Properties

    /// 顯示在介面中的幣別旗標。
    var flag: String {
        switch self {
        case .twd:
            "🇹🇼"
        case .krw:
            "🇰🇷"
        case .jpy:
            "🇯🇵"
        case .usd:
            "🇺🇸"
        case .eur:
            "🇪🇺"
        }
    }

    /// 建立 `FormatStyle` 時使用的 ISO 幣別代碼。
    var code: String { rawValue }
}
