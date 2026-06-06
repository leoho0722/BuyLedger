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
/// - ``BuyLedgerSchemaV7``：收斂後的 migration floor。`OrderRecord` 與 `PaymentMethodRecord` 皆凍結為內嵌影子型別 (`OrderRecord` 已含 `verificationStatus`、尚未含 V8 的 `campaignName` 與 `paymentReceiptStatus`；`PaymentMethodRecord` 為 `name` / `isCardless` / `isBankTransfer`)。
/// - ``BuyLedgerSchemaV8``：在 V7 之上為 `OrderRecord` 新增 `campaignName` 與 `paymentReceiptStatus`，並加入 ``CampaignRecord`` 新表。`OrderRecord` 與 `PaymentMethodRecord` 皆凍結為內嵌影子型別 (兩者皆尚未含 V9 的 `isCashOnDelivery`)。
/// - ``BuyLedgerSchemaV9``：在 V8 之上為 `OrderRecord` 與 `PaymentMethodRecord` 各新增 `isCashOnDelivery`。`OrderRecord` 凍結為內嵌影子型別 (尚未含 V10 的 `photos`)；`PaymentMethodRecord` 自 V9 起未再變更，維持引用 top-level。
/// - ``BuyLedgerSchemaV10``：當前最新版本 (target)，`models` 引用 top-level `@Model` (已含 ``OrderRecord/photos``)。
///
/// V1~V6 已於 pre-release 階段移除 (見 `prune-legacy-schema-versions` change)。SwiftData 的 migration 為 forward-only：已在 V10 的 store 不會觸發任何 stage，停在 V7～V9 的 store 以 lightweight 逐段遷到 V10。**移除版本會把 floor 往上抬，屬於單向操作**——任何停在低於 floor (V7) 的 store 將失去遷移路徑，開啟時 `ModelContainer` init 會拋錯。因此上架後不可再回頭移除版本。
enum BuyLedgerSchemaV7: VersionedSchema {

    // MARK: - Static Properties

    /// 版本識別。
    static var versionIdentifier: Schema.Version { Schema.Version(7, 0, 0) }

    /// 此版本包含的 model 型別；``OrderRecord`` 與 ``PaymentMethodRecord`` 指向本 enum 內凍結的影子型別，其餘未變更型別 (``CategoryRecord`` / ``CurrencyMetadataRecord`` / ``OrderSourceRecord`` / ``VerificationStatusRecord``) 維持引用 top-level。
    static var models: [any PersistentModel.Type] {
        [
            OrderRecord.self,
            CategoryRecord.self,
            PaymentMethodRecord.self,
            CurrencyMetadataRecord.self,
            OrderSourceRecord.self,
            VerificationStatusRecord.self,
        ]
    }

    /// V7 時代的 ``OrderRecord`` 影子；只在 SwiftData migration 用，與當時版本的屬性集合一致 (已含 V7 的 `verificationStatus`，尚未含 V8 的 `campaignName` 與 `paymentReceiptStatus`)。
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
            verificationStatus: String = ""
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
        }
    }

    /// V7 時代的 ``PaymentMethodRecord`` 影子；凍結當時的屬性集合 (`name` / `isCardless` / `isBankTransfer`)，保住 attribute 指紋，使日後 top-level 新增 `isCashOnDelivery` 不會破壞 V7 的 schema 指紋。
    @Model
    final class PaymentMethodRecord {

        // MARK: - Data Properties

        var name: String
        var isCardless: Bool = false
        var isBankTransfer: Bool = false

        // MARK: - Init

        init(name: String, isCardless: Bool = false, isBankTransfer: Bool = false) {
            self.name = name
            self.isCardless = isCardless
            self.isBankTransfer = isBankTransfer
        }
    }
}

/// V8 schema：在 V7 之上為 ``OrderRecord`` 新增 ``OrderRecord/campaignName`` (歸屬開團) 與 ``OrderRecord/paymentReceiptStatus`` (收款狀態)，並加入獨立主檔 ``CampaignRecord``。
///
/// 三者皆可由 SwiftData lightweight migration 處理 (兩個新欄位帶 default、``CampaignRecord`` 為全新 model)，故 V7 → V8 走 lightweight。
///
/// `OrderRecord` 與 `PaymentMethodRecord` 皆凍結為本 enum 內的影子型別 (兩者皆尚未含 V9 的 `isCashOnDelivery`)；其餘未變更型別維持引用 top-level。
enum BuyLedgerSchemaV8: VersionedSchema {

    // MARK: - Static Properties

    /// 版本識別。
    static var versionIdentifier: Schema.Version { Schema.Version(8, 0, 0) }

    /// 此版本包含的 model 型別；``OrderRecord`` 與 ``PaymentMethodRecord`` 指向本 enum 內凍結的影子型別，其餘 (``CategoryRecord`` / ``CurrencyMetadataRecord`` / ``OrderSourceRecord`` / ``VerificationStatusRecord`` / ``CampaignRecord``) 維持引用 top-level。
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

    /// V8 時代的 ``OrderRecord`` 影子；在 V7 屬性集合上加入 `campaignName` 與 `paymentReceiptStatus`，尚未含 V9 的 `isCashOnDelivery`。
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
            paymentReceiptStatus: String = PaymentReceiptStatus.pending.rawValue
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
        }
    }

    /// V8 時代的 ``PaymentMethodRecord`` 影子；屬性集合與 V7 相同 (`name` / `isCardless` / `isBankTransfer`)，V8 並未變更付款方式主檔，凍結只是為了讓 top-level 新增 `isCashOnDelivery` 後不破壞 V8 指紋。
    @Model
    final class PaymentMethodRecord {

        // MARK: - Data Properties

        var name: String
        var isCardless: Bool = false
        var isBankTransfer: Bool = false

        // MARK: - Init

        init(name: String, isCardless: Bool = false, isBankTransfer: Bool = false) {
            self.name = name
            self.isCardless = isCardless
            self.isBankTransfer = isBankTransfer
        }
    }
}

/// V9 schema：在 V8 之上為 ``OrderRecord`` 與 ``PaymentMethodRecord`` 各新增 `isCashOnDelivery` (貨到付款旗標)。
///
/// 兩個新欄位皆帶 default `false`，可由 SwiftData lightweight migration 處理，故 V8 → V9 走 lightweight。
///
/// `OrderRecord` 凍結為本 enum 內的影子型別 (尚未含 V10 的 `photos`)；`PaymentMethodRecord` 自 V9 起未再變更，與其餘未變更型別一同維持引用 top-level。
enum BuyLedgerSchemaV9: VersionedSchema {

    // MARK: - Static Properties

    /// 版本識別。
    static var versionIdentifier: Schema.Version { Schema.Version(9, 0, 0) }

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

    /// V9 時代的 ``OrderRecord`` 影子；在 V8 屬性集合上加入 `isCashOnDelivery`，尚未含 V10 的 `photos`。
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
            isCashOnDelivery: Bool = false
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
        }
    }
}

/// V10 schema：在 V9 之上為 ``OrderRecord`` 新增 `photos` (訂單照片)。
///
/// 新欄位帶 default 空陣列，可由 SwiftData lightweight migration 處理，故 V9 → V10 走 lightweight。
///
/// V10 為目前最新版本，``models`` 引用 top-level 定義 (已含 `photos`)；V7～V9 的 `OrderRecord` 已凍結為影子型別。
enum BuyLedgerSchemaV10: VersionedSchema {

    // MARK: - Static Properties

    /// 版本識別。
    static var versionIdentifier: Schema.Version { Schema.Version(10, 0, 0) }

    /// 此版本包含的 model 型別；引用 top-level 定義 (已含 V10 新增的 `photos`)。
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

/// BuyLedger SwiftData migration plan。
///
/// 保留 V7 → V8 → V9 → V10 三段 lightweight 遷移：V7 → V8 新增 `campaignName` / `paymentReceiptStatus` 與 ``CampaignRecord`` 新表；V8 → V9 新增 `isCashOnDelivery` 至 `OrderRecord` 與 `PaymentMethodRecord`；V9 → V10 新增 ``OrderRecord/photos``。floor 為 V7：停在 V7 的 store 會逐段遷到 V10，已在 V10 的 store 開啟時 delta 為 0、不觸發任何 stage。新增版本時，於 ``schemas`` 與 ``stages`` append 新版與遷移階段，並把上一版凍結為影子型別保住其 attribute 指紋。
enum BuyLedgerMigrationPlan: SchemaMigrationPlan {

    // MARK: - Static Properties

    /// migration plan 涉及的所有 schema 版本。
    static var schemas: [any VersionedSchema.Type] {
        [
            BuyLedgerSchemaV7.self,
            BuyLedgerSchemaV8.self,
            BuyLedgerSchemaV9.self,
            BuyLedgerSchemaV10.self,
        ]
    }

    /// V7 → V8 (lightweight，新增 default 欄位 `campaignName` / `paymentReceiptStatus` 與 ``CampaignRecord`` 新表)；V8 → V9 (lightweight，新增 default 欄位 `isCashOnDelivery` 至 `OrderRecord` 與 `PaymentMethodRecord`)；V9 → V10 (lightweight，新增 default 空陣列欄位 `photos` 至 `OrderRecord`)。
    static var stages: [MigrationStage] {
        [
            .lightweight(
                fromVersion: BuyLedgerSchemaV7.self,
                toVersion: BuyLedgerSchemaV8.self
            ),
            .lightweight(
                fromVersion: BuyLedgerSchemaV8.self,
                toVersion: BuyLedgerSchemaV9.self
            ),
            .lightweight(
                fromVersion: BuyLedgerSchemaV9.self,
                toVersion: BuyLedgerSchemaV10.self
            ),
        ]
    }
}
