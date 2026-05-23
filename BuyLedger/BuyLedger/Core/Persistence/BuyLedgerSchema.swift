//
//  BuyLedgerSchema.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation
import SwiftData

/// BuyLedger SwiftData schema 的版本化定義。
///
/// 兩個版本：
/// - ``BuyLedgerSchemaV1``：在「幣別主檔（API codes 動態載入）」feature 之前的 schema，`OrderRecord.currency` 是 `enum CurrencyCode`（以 ISO 4217 String 作 rawValue）。
/// - ``BuyLedgerSchemaV2``：當前 schema，`OrderRecord.currency` 改為純 `String`（因為 ``CurrencyCode`` 變成 `struct` wrapper 後 SwiftData 會把 `rawValue` 展開為子 attribute，破壞 in-place migration），且新增 ``CurrencyMetadataRecord``。
///
/// V1 → V2 採用 lightweight 遷移：兩個版本的 `currency` 在 store 內都是 String column（V1 的 enum 本來就是 String rawValue），SwiftData 應該能直接讀回；若實測仍有相容性問題，再升級為 `.custom` 並做明確的 dump-and-restore。
enum BuyLedgerSchemaV1: VersionedSchema {

    // MARK: - Static Properties

    /// 版本識別。
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    /// 此版本包含的 model 型別。
    static var models: [any PersistentModel.Type] {
        [OrderRecord.self, CategoryRecord.self, PaymentMethodRecord.self]
    }

    /// V1 時代的幣別 enum；保留只是為了讓 SwiftData 還能正確解讀舊 store。
    enum V1CurrencyCode: String, Codable, Sendable {

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
    }

    /// V1 時代的 ``OrderRecord`` 影子；屬性名稱／結構與當時版本一致，但只在 migration 路徑內被 SwiftData 載入。
    @Model
    final class OrderRecord {

        // MARK: - Data Properties

        /// 訂單編號。
        var id: String

        /// 客戶資料。
        var customer: LedgerCustomer

        /// 訂單狀態。
        var status: OrderStatus

        /// 商品原始幣別（V1 用 enum 儲存）。
        var currency: V1CurrencyCode

        /// 訂單日期。
        var date: Date

        /// 商品項目。
        var items: [LedgerOrderItem]

        /// 商品折合 TWD 後的成本。
        var itemCost: Decimal

        /// 國內運費成本。
        var domesticShipping: Decimal

        /// 國際集運成本。
        var internationalShipping: Decimal

        /// 刷卡手續費比例。
        var cardFeeRate: Decimal

        /// 平台手續費比例。
        var platformFeeRate: Decimal

        /// 實際向客戶收款的新台幣金額。
        var chargedAmount: Decimal

        /// 商品類別。
        var category: String

        /// 付款方式（後期才加入，帶 default 走 lightweight migration）。
        var paymentMethod: String = ""

        // MARK: - Init

        init(
            id: String,
            customer: LedgerCustomer,
            status: OrderStatus,
            currency: V1CurrencyCode,
            date: Date,
            items: [LedgerOrderItem],
            itemCost: Decimal,
            domesticShipping: Decimal,
            internationalShipping: Decimal,
            cardFeeRate: Decimal,
            platformFeeRate: Decimal,
            chargedAmount: Decimal,
            category: String,
            paymentMethod: String = ""
        ) {
            self.id = id
            self.customer = customer
            self.status = status
            self.currency = currency
            self.date = date
            self.items = items
            self.itemCost = itemCost
            self.domesticShipping = domesticShipping
            self.internationalShipping = internationalShipping
            self.cardFeeRate = cardFeeRate
            self.platformFeeRate = platformFeeRate
            self.chargedAmount = chargedAmount
            self.category = category
            self.paymentMethod = paymentMethod
        }
    }
}

/// 當前 schema：將 ``OrderRecord/currency`` 從 enum 改成純 String，並新增 ``CurrencyMetadataRecord``。
enum BuyLedgerSchemaV2: VersionedSchema {

    // MARK: - Static Properties

    /// 版本識別。
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }

    /// 此版本包含的 model 型別；直接引用 top-level 定義（不再為 V2 建影子型別，避免雙重維護）。
    static var models: [any PersistentModel.Type] {
        [
            OrderRecord.self,
            CategoryRecord.self,
            PaymentMethodRecord.self,
            CurrencyMetadataRecord.self,
        ]
    }
}

/// V1 → V2 的 migration plan。
///
/// 採用 `.custom` 階段並提供完整 dump-and-restore：先在 V1 context 把所有 OrderRecord 序列化進記憶體字典，SwiftData 切到 V2 後再依字典重建。雖然繁瑣，但能確實保留資料；後續若要新增 V3，同樣依此 pattern 擴充。
enum BuyLedgerMigrationPlan: SchemaMigrationPlan {

    // MARK: - Static Properties

    /// migration plan 涉及的所有 schema 版本。
    static var schemas: [any VersionedSchema.Type] {
        [BuyLedgerSchemaV1.self, BuyLedgerSchemaV2.self]
    }

    /// 連結 V1 → V2 的階段；用 willMigrate 抓資料、didMigrate 寫回。
    static var stages: [MigrationStage] {
        [
            .custom(
                fromVersion: BuyLedgerSchemaV1.self,
                toVersion: BuyLedgerSchemaV2.self,
                willMigrate: { context in
                    // 在 V1 context 讀出所有舊訂單與支援表，序列化進 in-memory snapshot；
                    // 不直接呼叫 V2 type，是因為 SwiftData 此時還未切到 V2 schema。
                    let orderDescriptor = FetchDescriptor<BuyLedgerSchemaV1.OrderRecord>()
                    let oldOrders = try context.fetch(orderDescriptor)
                    var snapshot: [PendingOrder] = []
                    for record in oldOrders {
                        snapshot.append(
                            PendingOrder(
                                id: record.id,
                                customer: record.customer,
                                status: record.status,
                                currency: record.currency.rawValue,
                                date: record.date,
                                items: record.items,
                                itemCost: record.itemCost,
                                domesticShipping: record.domesticShipping,
                                internationalShipping: record.internationalShipping,
                                cardFeeRate: record.cardFeeRate,
                                platformFeeRate: record.platformFeeRate,
                                chargedAmount: record.chargedAmount,
                                category: record.category,
                                paymentMethod: record.paymentMethod
                            )
                        )
                    }
                    pendingOrders = snapshot

                    // V1 schema 內的 OrderRecord 在 V2 沒有對應 ID 對映（attribute 型別不同），所以這裡也把舊 row 一併刪除，
                    // 避免 SwiftData 在 schema 切換時嘗試 in-place 轉型而失敗。
                    for record in oldOrders {
                        context.delete(record)
                    }
                    try context.save()
                },
                didMigrate: { context in
                    // 在 V2 context 用 snapshot 重建。
                    let snapshot = pendingOrders
                    for pending in snapshot {
                        let restored = OrderRecord(
                            order: LedgerOrder(
                                id: pending.id,
                                customer: pending.customer,
                                status: pending.status,
                                currency: CurrencyCode(rawValue: pending.currency),
                                date: pending.date,
                                items: pending.items,
                                itemCost: pending.itemCost,
                                domesticShipping: pending.domesticShipping,
                                internationalShipping: pending.internationalShipping,
                                cardFeeRate: pending.cardFeeRate,
                                platformFeeRate: pending.platformFeeRate,
                                chargedAmount: pending.chargedAmount,
                                category: pending.category,
                                paymentMethod: pending.paymentMethod
                            )
                        )
                        context.insert(restored)
                    }
                    try context.save()
                    pendingOrders = []
                }
            )
        ]
    }

    /// 跨 willMigrate / didMigrate 的中介 snapshot；用 `nonisolated(unsafe)` 是因為 migration 為 one-shot、單執行緒，不會有 race。
    nonisolated(unsafe) private static var pendingOrders: [PendingOrder] = []

    // MARK: - PendingOrder

    /// V1 → V2 之間搬運訂單資料用的暫存 struct。
    private struct PendingOrder {

        let id: String
        let customer: LedgerCustomer
        let status: OrderStatus
        let currency: String
        let date: Date
        let items: [LedgerOrderItem]
        let itemCost: Decimal
        let domesticShipping: Decimal
        let internationalShipping: Decimal
        let cardFeeRate: Decimal
        let platformFeeRate: Decimal
        let chargedAmount: Decimal
        let category: String
        let paymentMethod: String
    }
}
