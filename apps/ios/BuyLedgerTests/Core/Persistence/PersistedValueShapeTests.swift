//
//  PersistedValueShapeTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/15.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// 落盤記錄內嵌值型別的形狀測試，鎖住編碼鍵、儲存屬性、raw value 與幣別代碼
struct PersistedValueShapeTests {

    // MARK: - Properties

    /// 持久化形狀改變時附在失敗訊息上的指引
    private static let shapeChangedComment: Comment = "持久化形狀改變，見 `.claude/rules/ios-data-layer.md`"

    /// 驗證訂單項目編碼後只含名稱、數量與單價三個鍵，不寫出識別碼
    ///
    /// - Throws: 編碼失敗時丟出錯誤
    @Test
    func encode_固定識別碼與整數單價_只輸出名稱數量與單價() throws {
        // Given
        let item = LedgerOrderItem(
            id: UUID(0),
            name: "Tote",
            quantity: 2,
            unitPrice: 1200
        )
        let expectedJSON = #"{"name":"Tote","quantity":2,"unitPrice":1200}"#
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        // When
        let data = try encoder.encode(item)
        let json = String(decoding: data, as: UTF8.self)

        // Then
        #expect(json == expectedJSON, Self.shapeChangedComment)
    }

    /// 驗證缺少識別碼的 JSON 可解碼成訂單項目，且名稱、數量與單價相同
    ///
    /// - Throws: 資料缺少名稱、數量或單價而無法解碼時丟出錯誤
    @Test
    func decode_缺少識別碼的資料_還原名稱數量與單價() throws {
        // Given
        let data = Data(#"{"name":"Tote","quantity":2,"unitPrice":1200}"#.utf8)

        // When
        let item = try JSONDecoder().decode(LedgerOrderItem.self, from: data)

        // Then
        #expect(item.name == "Tote", Self.shapeChangedComment)
        #expect(item.quantity == 2, Self.shapeChangedComment)
        #expect(item.unitPrice == 1200, Self.shapeChangedComment)
    }

    /// 驗證訂單項目的儲存屬性依宣告順序為識別碼、名稱、數量與單價，型別分別為 UUID、文字、整數與十進位數
    @Test
    func storedProperties_訂單項目_依宣告順序為識別碼名稱數量與單價() {
        // Given
        let item = LedgerOrderItem(
            id: UUID(0),
            name: "Tote",
            quantity: 2,
            unitPrice: 1200
        )
        // Apple 平台上 `Decimal` 的執行期型別名稱是 `NSDecimal`
        let expectedProperties = [
            "id: UUID",
            "name: String",
            "quantity: Int",
            "unitPrice: NSDecimal",
        ]

        // When
        let properties = Mirror(reflecting: item).children
            .map { "\($0.label ?? ""): \(type(of: $0.value))" }

        // Then
        #expect(properties == expectedProperties, Self.shapeChangedComment)
    }

    /// 驗證客戶編碼後的鍵只有縮寫、名稱與分級
    ///
    /// - Throws: 編碼失敗或輸出不是 JSON 物件時丟出錯誤
    @Test
    func encode_客戶_只輸出縮寫名稱與分級三個鍵() throws {
        // Given
        let customer = LedgerCustomer(name: "Mika", initials: "MK", tier: .vip)

        // When
        let data = try JSONEncoder().encode(customer)
        let object = try JSONSerialization.jsonObject(with: data)
        let json = try #require(object as? [String: Any])

        // Then
        #expect(Set(json.keys) == ["initials", "name", "tier"], Self.shapeChangedComment)
    }

    /// 驗證客戶的儲存屬性依宣告順序為名稱、縮寫與分級，型別分別為文字、文字與客戶分級
    @Test
    func storedProperties_客戶_依宣告順序為名稱縮寫與分級() {
        // Given
        let customer = LedgerCustomer(name: "Mika", initials: "MK", tier: .vip)
        let expectedProperties = ["name: String", "initials: String", "tier: CustomerTier"]

        // When
        let properties = Mirror(reflecting: customer).children
            .map { "\($0.label ?? ""): \(type(of: $0.value))" }

        // Then
        #expect(properties == expectedProperties, Self.shapeChangedComment)
    }

    /// 驗證訂單狀態每個狀態值的 raw value 集合與落盤字面值相同
    @Test
    func rawValue_訂單狀態_等於落盤字面值集合() {
        // Given
        let expectedRawValues: Set<String> = [
            "quoting",
            "confirmed",
            "purchased",
            "shipping",
            "partiallyArrived",
            "arrived",
            "delivered",
            "pickedUp",
            "cancelled",
            "merged",
        ]

        // When
        let rawValues = Set(OrderStatus.allCases.map(\.rawValue))

        // Then
        #expect(rawValues == expectedRawValues, Self.shapeChangedComment)
    }

    /// 驗證開團狀態每個狀態值的 raw value 集合與落盤字面值相同
    @Test
    func rawValue_開團狀態_等於落盤字面值集合() {
        // Given
        let expectedRawValues: Set<String> = ["ongoing", "closed"]

        // When
        let rawValues = Set(CampaignStatus.allCases.map(\.rawValue))

        // Then
        #expect(rawValues == expectedRawValues, Self.shapeChangedComment)
    }

    /// 驗證收款狀態每個狀態值的 raw value 集合與落盤字面值相同
    @Test
    func rawValue_收款狀態_等於落盤字面值集合() {
        // Given
        let expectedRawValues: Set<String> = ["pending", "received"]

        // When
        let rawValues = Set(PaymentReceiptStatus.allCases.map(\.rawValue))

        // Then
        #expect(rawValues == expectedRawValues, Self.shapeChangedComment)
    }

    /// 驗證客戶分級的 raw value 與落盤字面值相同
    ///
    /// - Parameter tier: 要驗證的客戶分級
    /// - Note: 分級無法列舉：新增分級時 `switch` 會無法編譯，補上後也要加進 `arguments` 清單才會被執行
    @Test(arguments: [CustomerTier.new, .regular, .vip])
    func rawValue_客戶分級_等於落盤字面值(tier: CustomerTier) {
        // Given
        let expectedRawValue: String
        switch tier {
        case .new:
            expectedRawValue = "new"

        case .regular:
            expectedRawValue = "regular"

        case .vip:
            expectedRawValue = "vip"
        }

        // When
        let rawValue = tier.rawValue

        // Then
        #expect(rawValue == expectedRawValue, Self.shapeChangedComment)
    }

    /// 驗證內建幣別常數的代碼與落盤字面值相同
    @Test
    func rawValue_內建幣別常數_等於幣別代碼字面值() {
        // Given
        let currencies: [CurrencyCode] = [.twd, .krw, .jpy, .usd, .cny]
        let expectedRawValues = ["TWD", "KRW", "JPY", "USD", "CNY"]

        // When
        let rawValues = currencies.map(\.rawValue)

        // Then
        #expect(rawValues == expectedRawValues, Self.shapeChangedComment)
    }

    /// 驗證幣別代碼編碼成單一字串，作為搬移 `Codable` 實作的安全網
    ///
    /// - Throws: 編碼失敗時丟出錯誤
    @Test
    func encode_幣別代碼_輸出單一字串() throws {
        // Given
        let currency = CurrencyCode(rawValue: "JPY")
        let expectedJSON = #""JPY""#

        // When
        let data = try JSONEncoder().encode(currency)
        let json = String(decoding: data, as: UTF8.self)

        // Then
        #expect(json == expectedJSON, "幣別代碼的單值字串編碼改變")
    }

    /// 驗證單一字串可解碼成幣別代碼，作為搬移 `Codable` 實作的安全網
    ///
    /// - Throws: 資料不是單一字串而無法解碼時丟出錯誤
    @Test
    func decode_單一字串_還原幣別代碼() throws {
        // Given
        let data = Data(#""JPY""#.utf8)

        // When
        let currency = try JSONDecoder().decode(CurrencyCode.self, from: data)

        // Then
        #expect(currency.rawValue == "JPY", "幣別代碼的單值字串解碼改變")
    }
}
