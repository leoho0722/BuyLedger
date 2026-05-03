//
//  LedgerOrderItem.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import Foundation

/// 訂單中的單一商品項目。
///
/// 為了支援表單內的 inline 編輯（避免 SwiftUI ForEach binding 隨內容變動而 reset focus），id 採用穩定的 ``UUID``，與 `name / quantity / unitPrice` 等內容欄位解耦。
struct LedgerOrderItem: Equatable, Identifiable, Sendable {

    // MARK: - Identifiable Properties

    /// 商品項目的穩定識別值，與內容無關。
    let id: UUID

    // MARK: - Data Properties

    /// 商品名稱。
    var name: String

    /// 商品數量。
    var quantity: Int

    /// 商品在原始幣別中的單價。
    var unitPrice: Decimal

    // MARK: - Init

    /// 建立商品項目。
    /// - Parameters:
    ///   - id: 穩定識別值；預設自動產生新的 ``UUID``。
    ///   - name: 商品名稱。
    ///   - quantity: 商品數量。
    ///   - unitPrice: 商品在原始幣別中的單價。
    init(id: UUID = UUID(), name: String, quantity: Int, unitPrice: Decimal) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unitPrice = unitPrice
    }

    // MARK: - Computed Properties

    /// 商品在原始幣別中的小計。
    var subtotal: Decimal {
        unitPrice * Decimal(quantity)
    }
}

// MARK: - Codable

extension LedgerOrderItem: Codable {

    // MARK: - Cases

    /// `Codable` 使用的鍵；刻意排除 `id`，讓既有的持久化資料也能被讀回（缺 id 時自動產生新的 UUID），同時避免每次寫入都把 UUID 漏進 JSON。
    private enum CodingKeys: String, CodingKey {
        case name
        case quantity
        case unitPrice
    }

    // MARK: - Init

    /// 從 decoder 還原；若資料來源沒有 `id` 欄位（例如舊版本寫入的 SwiftData blob），自動補上新的 ``UUID``。
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.quantity = try container.decode(Int.self, forKey: .quantity)
        self.unitPrice = try container.decode(Decimal.self, forKey: .unitPrice)
    }

    /// 編碼成 JSON / SwiftData blob，刻意不寫出 `id` 欄位。
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(unitPrice, forKey: .unitPrice)
    }
}
