//
//  JSONValue.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/21.
//

import Foundation

/// 任意 JSON 值的 Codable 封裝，供跨裝置同步的 partial patch 承載異質欄位值
/// (字串、字串陣列、巢狀物件如商品明細等)。後端欄位級合併以欄位為單位，值的型別不一，
/// 故以此型別統一編解碼
enum JSONValue: Codable, Sendable, Equatable {

    // MARK: - Cases

    /// 字串值
    case string(String)

    /// 數值 (統一以 `Double` 承載整數與浮點數)
    case number(Double)

    /// 布林值
    case bool(Bool)

    /// 陣列值，元素同為 ``JSONValue``
    case array([JSONValue])

    /// 物件值，以鍵對應 ``JSONValue``
    case object([String: JSONValue])

    /// 空值 (對應 JSON 的 `null`)
    case null

    // MARK: - Init

    /// 從單一值容器逐型別嘗試解碼；依 `null` → `Bool` → `Double` → `String` → 陣列 → 物件的順序判定，皆不符時拋出解碼錯誤
    /// - Parameter decoder: 來源解碼器
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "無法解碼為 JSONValue"
            )
        }
    }
}

// MARK: - Encodable

extension JSONValue {

    /// 將當前 case 編碼為單一值容器，`null` 編成 JSON 的 `null`、其餘編成對應的原生值
    /// - Parameter encoder: 目標編碼器
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)

        case .number(let value):
            try container.encode(value)

        case .bool(let value):
            try container.encode(value)

        case .array(let value):
            try container.encode(value)

        case .object(let value):
            try container.encode(value)

        case .null:
            try container.encodeNil()
        }
    }
}
