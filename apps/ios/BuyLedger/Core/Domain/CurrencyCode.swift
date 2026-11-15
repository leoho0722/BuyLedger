//
//  CurrencyCode.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// 交易幣別的 ISO 4217 三位代碼
struct CurrencyCode: Hashable, Sendable {

    // MARK: - Properties

    /// App 預設的「常用幣別」候選集
    static let defaults: [CurrencyCode] = [.twd, .krw, .jpy, .usd, .cny]

    /// 新台幣 (基準幣別，全 App 預設)
    static let twd = CurrencyCode(rawValue: "TWD")

    /// 韓圜
    static let krw = CurrencyCode(rawValue: "KRW")

    /// 日圓
    static let jpy = CurrencyCode(rawValue: "JPY")

    /// 美元
    static let usd = CurrencyCode(rawValue: "USD")

    /// 人民幣
    static let cny = CurrencyCode(rawValue: "CNY")

    /// 實際保存的基礎值
    let rawValue: String
}

// MARK: - Computed Properties

extension CurrencyCode {

    /// ISO 4217 三位幣別代碼
    var code: String {
        rawValue
    }
}

// MARK: - Codable

extension CurrencyCode: Codable {

    /// 從單值容器讀取幣別代碼
    ///
    /// - Parameter decoder: 解碼器
    /// - Throws: 解碼器無法讀取字串時拋出錯誤
    init(from decoder: Decoder) throws(any Error) {
        let container = try decoder.singleValueContainer()
        self.init(rawValue: try container.decode(String.self))
    }

    /// 把幣別代碼寫入單值容器
    ///
    /// - Parameter encoder: 編碼器
    /// - Throws: 編碼器無法寫入字串時拋出錯誤
    func encode(to encoder: Encoder) throws(any Error) {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

// MARK: - Identifiable

extension CurrencyCode: Identifiable {

    /// 穩定識別值，即實際保存的原始字串
    var id: String {
        rawValue
    }
}
