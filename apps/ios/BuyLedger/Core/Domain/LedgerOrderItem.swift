//
//  LedgerOrderItem.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

// MARK: - Computed Properties

extension LedgerOrderItem {

    /// 商品在原始幣別中的小計
    var subtotal: Decimal {
        unitPrice * Decimal(quantity)
    }
}

// MARK: - Codable

extension LedgerOrderItem: Codable {

    // MARK: CodingKeys

    /// `Codable` 使用的鍵；刻意排除 `id`
    private enum CodingKeys: String, CodingKey {

        case name

        case quantity

        case unitPrice
    }

    // MARK: Init

    /// 從 decoder 還原
    /// - Parameter decoder: 解碼器
    /// - Throws: decoder 無法讀取訂單項目時拋出錯誤
    init(from decoder: Decoder) throws(any Error) {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let quantity = try container.decode(Int.self, forKey: .quantity)
        let unitPrice = try container.decode(Decimal.self, forKey: .unitPrice)
        self.init(name: name, quantity: quantity, unitPrice: unitPrice)
    }

    /// 編碼成 JSON / SwiftData blob，刻意不寫出 `id` 欄位
    /// - Parameter encoder: 編碼器
    /// - Throws: encoder 無法寫入訂單項目時拋出錯誤
    func encode(to encoder: Encoder) throws(any Error) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(unitPrice, forKey: .unitPrice)
    }
}
