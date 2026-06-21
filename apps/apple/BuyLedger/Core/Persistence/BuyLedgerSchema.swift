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
/// 目前保留的版本：
/// - ``BuyLedgerSchemaV10``：收斂後的 migration floor。`OrderRecord` 凍結為內嵌影子型別 (含 `photos`、`category` / `campaignName` 仍為單一字串、尚未含 V11 的 `mergedSourceIDs`)；其餘未變更型別維持引用 top-level。
/// - ``BuyLedgerSchemaV11``：把 ``OrderRecord`` 的 `category` / `campaignName` 由單一字串改為字串陣列 (`categories` / `campaignNames`)、新增 `mergedSourceIDs`。`OrderRecord` 形狀自 V11 起未再變更，故 V11 與 V12 皆引用同一 top-level 定義。
/// - ``BuyLedgerSchemaV12``：當前最新版本 (target)，在 V11 之上新增跨裝置同步的本機 sidecar (``SyncMeta`` / ``SyncQueueItem``)；領域 model 形狀不變、`models` 引用 top-level。
///
/// V1~V9 已於 pre-release 階段移除。SwiftData 的 migration 為 forward-only：已在 V12 的 store 不會觸發任何 stage，停在 V10 的 store 以 custom (V10 → V11) 與 lightweight (V11 → V12) 逐段遷到 target。**移除版本會把 floor 往上抬，屬於單向操作**——任何停在低於 floor (V10) 的 store 將失去遷移路徑，開啟時 `ModelContainer` init 會拋錯、進而觸發 `makeForApp()` 砍檔。因此上架後不可再回頭移除版本。
enum BuyLedgerSchemaV10: VersionedSchema {

    // MARK: - Static Properties

    /// 版本識別。
    static var versionIdentifier: Schema.Version { Schema.Version(10, 0, 0) }

    /// 此版本包含的 model 型別；``OrderRecord`` 指向本 enum 內凍結的影子型別，其餘 (``CategoryRecord`` / ``PaymentMethodRecord`` / ``CurrencyMetadataRecord`` / ``OrderSourceRecord`` / ``VerificationStatusRecord`` / ``CampaignRecord``) 維持引用 top-level。
    static var models: [any PersistentModel.Type] {
        [
            OrderRecord.self,
            CategoryRecord.self,
            PaymentMethodRecord.self,
            CurrencyMetadataRecord.self,
            OrderSourceRecord.self,
            VerificationStatusRecord.self,
            CampaignRecord.self,
        ]
    }

    /// 收斂後 migration floor (V10) 的 ``OrderRecord`` 影子；含 `photos`，`category` / `campaignName` 仍為單一字串，尚未含 V11 的 `mergedSourceIDs`。
    @Model
    final class OrderRecord {

        // MARK: - Data Properties

        var id: String
        var customer: LedgerCustomer
        var status: OrderStatus
        var currency: String
        var date: Date
        var items: [LedgerOrderItem]
        var itemCost: Decimal
        var domesticShipping: Decimal
        var internationalShipping: Decimal
        var foreignDomesticShipping: Decimal = 0
        var cardFeeRate: Decimal
        var platformFeeRate: Decimal
        var paymentFeeRate: Decimal = 0
        var chargedAmount: Decimal
        var cardlessDeductionAmount: Decimal = 0
        var cardlessSupplementAmount: Decimal = 0
        var orderSource: String = ""
        var category: String
        var paymentMethod: String = ""
        var notes: String = ""
        var verificationStatus: String = ""
        var campaignName: String = ""
        var paymentReceiptStatus: String = PaymentReceiptStatus.pending.rawValue
        var isCashOnDelivery: Bool = false
        var photos: [Data] = []

        // MARK: - Init

        init(
            id: String,
            customer: LedgerCustomer,
            status: OrderStatus,
            currency: String,
            date: Date,
            items: [LedgerOrderItem],
            itemCost: Decimal,
            domesticShipping: Decimal,
            internationalShipping: Decimal,
            foreignDomesticShipping: Decimal = 0,
            cardFeeRate: Decimal,
            platformFeeRate: Decimal,
            paymentFeeRate: Decimal = 0,
            chargedAmount: Decimal,
            cardlessDeductionAmount: Decimal = 0,
            cardlessSupplementAmount: Decimal = 0,
            orderSource: String = "",
            category: String,
            paymentMethod: String = "",
            notes: String = "",
            verificationStatus: String = "",
            campaignName: String = "",
            paymentReceiptStatus: String = PaymentReceiptStatus.pending.rawValue,
            isCashOnDelivery: Bool = false,
            photos: [Data] = []
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
            self.foreignDomesticShipping = foreignDomesticShipping
            self.cardFeeRate = cardFeeRate
            self.platformFeeRate = platformFeeRate
            self.paymentFeeRate = paymentFeeRate
            self.chargedAmount = chargedAmount
            self.cardlessDeductionAmount = cardlessDeductionAmount
            self.cardlessSupplementAmount = cardlessSupplementAmount
            self.orderSource = orderSource
            self.category = category
            self.paymentMethod = paymentMethod
            self.notes = notes
            self.verificationStatus = verificationStatus
            self.campaignName = campaignName
            self.paymentReceiptStatus = paymentReceiptStatus
            self.isCashOnDelivery = isCashOnDelivery
            self.photos = photos
        }
    }
}

/// V11 schema：在 V10 之上把 ``OrderRecord`` 的 `category` / `campaignName` 由單一字串改為字串陣列 (`categories` / `campaignNames`)，並新增 `mergedSourceIDs` (合併來源訂單編號)。
///
/// 因涉及既有欄位「型別改變」，V10 → V11 必須走 `.custom` 的 dump-and-restore，不可用 lightweight。
///
/// `OrderRecord` 形狀自 V11 起未再變更，V12 仍引用同一 top-level 定義，故 V11 維持引用 top-level (毋須凍結影子)；floor (V10) 的 `OrderRecord` 已凍結為影子型別。
enum BuyLedgerSchemaV11: VersionedSchema {

    // MARK: - Static Properties

    /// 版本識別。
    static var versionIdentifier: Schema.Version { Schema.Version(11, 0, 0) }

    /// 此版本包含的 model 型別；引用 top-level 定義 (已含 V11 的 `categories` / `campaignNames` / `mergedSourceIDs`)。
    static var models: [any PersistentModel.Type] {
        [
            OrderRecord.self,
            CategoryRecord.self,
            PaymentMethodRecord.self,
            CurrencyMetadataRecord.self,
            OrderSourceRecord.self,
            VerificationStatusRecord.self,
            CampaignRecord.self,
        ]
    }
}

/// V12 schema：當前最新版本 (target)，在 V11 之上新增跨裝置同步的本機 sidecar (``SyncMeta`` / ``SyncQueueItem``)；領域 model 形狀不變、``models`` 引用 top-level。
enum BuyLedgerSchemaV12: VersionedSchema {

    // MARK: - Static Properties

    /// 版本識別。
    static var versionIdentifier: Schema.Version { Schema.Version(12, 0, 0) }

    /// 此版本在 V11 之上新增跨裝置同步的本機 sidecar (``SyncMeta`` / ``SyncQueueItem``)；領域 model 形狀不變。
    static var models: [any PersistentModel.Type] {
        [
            OrderRecord.self,
            CategoryRecord.self,
            PaymentMethodRecord.self,
            CurrencyMetadataRecord.self,
            OrderSourceRecord.self,
            VerificationStatusRecord.self,
            CampaignRecord.self,
            SyncMeta.self,
            SyncQueueItem.self,
        ]
    }
}

/// BuyLedger SwiftData migration plan。
///
/// 保留 V10 → V11 一段 custom 與 V11 → V12 一段 lightweight 遷移：V10 → V11 把 `category` / `campaignName` 改為字串陣列並新增 ``OrderRecord/mergedSourceIDs`` (型別改變，走 dump-and-restore)；V11 → V12 新增跨裝置同步的本機 sidecar (``SyncMeta`` / ``SyncQueueItem``) 新表 (走 lightweight)。floor 為 V10：停在 V10 的 store 會逐段遷到 V12，已在 V12 的 store 開啟時 delta 為 0、不觸發任何 stage。新增版本時，於 ``schemas`` 與 ``stages`` append 新版與遷移階段，並把上一版凍結為影子型別保住其 attribute 指紋 (該型別有變更時)。
enum BuyLedgerMigrationPlan: SchemaMigrationPlan {

    // MARK: - Static Properties

    /// migration plan 涉及的所有 schema 版本。
    static var schemas: [any VersionedSchema.Type] {
        [
            BuyLedgerSchemaV10.self,
            BuyLedgerSchemaV11.self,
            BuyLedgerSchemaV12.self,
        ]
    }

    /// V10 → V11 dump-and-restore 的中介 snapshot；one-shot、單執行緒使用，無 race 疑慮。
    nonisolated(unsafe) private static var orderSnapshotsV10: [OrderSnapshotV10] = []

    /// V10 → V11 (custom，`category` / `campaignName` 改為字串陣列、新增 `mergedSourceIDs`——`willMigrate` 把 V10 row 序列化進記憶體後刪除，`didMigrate` 以 V11 形狀重建：非空字串映射為單元素陣列、空字串映射為空陣列、`mergedSourceIDs` 一律空陣列)；V11 → V12 (lightweight，新增跨裝置同步 sidecar ``SyncMeta`` / ``SyncQueueItem`` 新表)。
    static var stages: [MigrationStage] {
        [
            .custom(
                fromVersion: BuyLedgerSchemaV10.self,
                toVersion: BuyLedgerSchemaV11.self,
                willMigrate: { context in
                    let records = try context.fetch(FetchDescriptor<BuyLedgerSchemaV10.OrderRecord>())
                    orderSnapshotsV10 = records.map(OrderSnapshotV10.init(record:))
                    for record in records {
                        context.delete(record)
                    }
                    try context.save()
                },
                didMigrate: { context in
                    for snapshot in orderSnapshotsV10 {
                        context.insert(snapshot.makeV11Record())
                    }
                    orderSnapshotsV10 = []
                    try context.save()
                }
            ),
            .lightweight(
                fromVersion: BuyLedgerSchemaV11.self,
                toVersion: BuyLedgerSchemaV12.self
            ),
        ]
    }
}

// MARK: - Nested Types

private extension BuyLedgerMigrationPlan {

    /// V10 ``OrderRecord`` 的記憶體 snapshot；`willMigrate` 讀出舊 row 暫存於此，`didMigrate` 據此以 V11 形狀重建。
    struct OrderSnapshotV10 {

        // MARK: - Data Properties

        let id: String
        let customer: LedgerCustomer
        let status: OrderStatus
        let currency: String
        let date: Date
        let items: [LedgerOrderItem]
        let itemCost: Decimal
        let domesticShipping: Decimal
        let internationalShipping: Decimal
        let foreignDomesticShipping: Decimal
        let cardFeeRate: Decimal
        let platformFeeRate: Decimal
        let paymentFeeRate: Decimal
        let chargedAmount: Decimal
        let cardlessDeductionAmount: Decimal
        let cardlessSupplementAmount: Decimal
        let orderSource: String
        let category: String
        let paymentMethod: String
        let notes: String
        let verificationStatus: String
        let campaignName: String
        let paymentReceiptStatus: String
        let isCashOnDelivery: Bool
        let photos: [Data]

        // MARK: - Init

        /// 自 V10 影子記錄擷取全部欄位。
        /// - Parameter record: V10 的 ``BuyLedgerSchemaV10/OrderRecord`` 影子。
        init(record: BuyLedgerSchemaV10.OrderRecord) {
            self.id = record.id
            self.customer = record.customer
            self.status = record.status
            self.currency = record.currency
            self.date = record.date
            self.items = record.items
            self.itemCost = record.itemCost
            self.domesticShipping = record.domesticShipping
            self.internationalShipping = record.internationalShipping
            self.foreignDomesticShipping = record.foreignDomesticShipping
            self.cardFeeRate = record.cardFeeRate
            self.platformFeeRate = record.platformFeeRate
            self.paymentFeeRate = record.paymentFeeRate
            self.chargedAmount = record.chargedAmount
            self.cardlessDeductionAmount = record.cardlessDeductionAmount
            self.cardlessSupplementAmount = record.cardlessSupplementAmount
            self.orderSource = record.orderSource
            self.category = record.category
            self.paymentMethod = record.paymentMethod
            self.notes = record.notes
            self.verificationStatus = record.verificationStatus
            self.campaignName = record.campaignName
            self.paymentReceiptStatus = record.paymentReceiptStatus
            self.isCashOnDelivery = record.isCashOnDelivery
            self.photos = record.photos
        }
    }
}

// MARK: - Private Method

private extension BuyLedgerMigrationPlan.OrderSnapshotV10 {

    /// 以 V11 形狀重建 top-level ``OrderRecord``：`category` / `campaignName` 非空字串映射為單元素陣列、空字串映射為空陣列；`mergedSourceIDs` 一律空陣列 (V10 以前不存在合併訂單)。
    /// - Returns: 重建後的 V11 記錄。
    func makeV11Record() -> OrderRecord {
        OrderRecord(
            order: LedgerOrder(
                id: id,
                customer: customer,
                status: status,
                currency: CurrencyCode(rawValue: currency),
                date: date,
                items: items,
                itemCost: itemCost,
                domesticShipping: domesticShipping,
                internationalShipping: internationalShipping,
                foreignDomesticShipping: foreignDomesticShipping,
                cardFeeRate: cardFeeRate,
                platformFeeRate: platformFeeRate,
                paymentFeeRate: paymentFeeRate,
                chargedAmount: chargedAmount,
                cardlessDeductionAmount: cardlessDeductionAmount,
                cardlessSupplementAmount: cardlessSupplementAmount,
                orderSource: orderSource,
                categories: category.isEmpty ? [] : [category],
                paymentMethod: paymentMethod,
                notes: notes,
                verificationStatus: verificationStatus,
                campaignNames: campaignName.isEmpty ? [] : [campaignName],
                paymentReceiptStatus: PaymentReceiptStatus(rawValue: paymentReceiptStatus) ?? .pending,
                isCashOnDelivery: isCashOnDelivery,
                photos: photos,
                mergedSourceIDs: []
            )
        )
    }
}
