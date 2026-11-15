//
//  LedgerOrderItem.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// 訂單中的商品項目
struct LedgerOrderItem: Equatable, Identifiable, Sendable {

    // MARK: - Properties

    /// 商品項目的穩定識別值
    let id: UUID

    /// 商品名稱
    var name: String

    /// 商品數量
    var quantity: Int

    /// 商品單價
    var unitPrice: Decimal

    // MARK: - Init

    /// 建立一筆訂單項目；不指定識別值時自動產生新的
    ///
    /// - Parameters:
    ///   - id: 商品項目的穩定識別值
    ///   - name: 商品名稱
    ///   - quantity: 商品數量
    ///   - unitPrice: 商品單價
    init(
        id: UUID = UUID(),
        name: String,
        quantity: Int,
        unitPrice: Decimal
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unitPrice = unitPrice
    }
}

// MARK: - Nested Types

extension LedgerOrderItem {

    /// `Codable` 使用的鍵；刻意排除 `id`
    private enum CodingKeys: String, CodingKey {

        /// 商品名稱
        case name

        /// 商品數量
        case quantity

        /// 商品單價
        case unitPrice
    }
}

// MARK: - Computed Properties

extension LedgerOrderItem {

    /// 商品在原始幣別中的小計
    var subtotal: Decimal {
        unitPrice * Decimal(quantity)
    }
}

// MARK: - Codable

extension LedgerOrderItem: Codable {

    /// 從解碼器還原訂單項目
    ///
    /// - Parameter decoder: 用來讀取訂單項目的解碼器
    /// - Throws: 解碼器無法讀取訂單項目時拋出錯誤
    init(from decoder: Decoder) throws(any Error) {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let quantity = try container.decode(Int.self, forKey: .quantity)
        let unitPrice = try container.decode(Decimal.self, forKey: .unitPrice)
        self.init(name: name, quantity: quantity, unitPrice: unitPrice)
    }

    /// 將訂單項目編碼成 JSON 或 `SwiftData` 資料
    ///
    /// - Parameter encoder: 用來寫入訂單項目的編碼器
    /// - Throws: 編碼器無法寫入訂單項目時拋出錯誤
    func encode(to encoder: Encoder) throws(any Error) {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(unitPrice, forKey: .unitPrice)
    }
}
