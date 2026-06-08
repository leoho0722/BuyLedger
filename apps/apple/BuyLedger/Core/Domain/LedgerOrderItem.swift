//
//  LedgerOrderItem.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//
//  資料形狀 (id / name / quantity / unitPrice、init) 由 Generated/LedgerOrderItem.generated.swift 產生；
//  本檔僅保留手寫業務邏輯 (小計、刻意排除 id 的自訂 Codable)。
//  改欄位請改 shared/data-model/schema/ 後重新 generate。
//

import Foundation

// MARK: - Computed Properties

extension LedgerOrderItem {

    /// 商品在原始幣別中的小計。
    var subtotal: Decimal {
        unitPrice * Decimal(quantity)
    }
}

// MARK: - Codable

extension LedgerOrderItem: Codable {

    // MARK: - Cases

    /// `Codable` 使用的鍵；刻意排除 `id`，讓既有的持久化資料也能被讀回 (缺 id 時自動產生新的 UUID)，同時避免每次寫入都把 UUID 漏進 JSON。
    private enum CodingKeys: String, CodingKey {

        case name

        case quantity

        case unitPrice
    }

    // MARK: - Init

    /// 從 decoder 還原；因生成的 init 對 `id` 帶有 `= UUID()` 預設，未提供 `id` 欄位的資料來源 (例如舊版本寫入的 SwiftData blob) 會自動補上新的 ``UUID``。
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let quantity = try container.decode(Int.self, forKey: .quantity)
        let unitPrice = try container.decode(Decimal.self, forKey: .unitPrice)
        self.init(name: name, quantity: quantity, unitPrice: unitPrice)
    }

    /// 編碼成 JSON / SwiftData blob，刻意不寫出 `id` 欄位。
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(unitPrice, forKey: .unitPrice)
    }
}
