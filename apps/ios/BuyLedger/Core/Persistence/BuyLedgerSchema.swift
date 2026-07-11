//
//  BuyLedgerSchema.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import Foundation
import SwiftData

/// BuyLedger SwiftData schema 的版本化定義
///
/// 目前保留的版本：
/// - ``BuyLedgerSchemaV13``：收斂後的 migration floor。含開團訂購提醒連結表 (``CampaignReminderRecord``)；V14 改動該表形狀，故 V13 把其凍結為內嵌影子 (僅 `campaignID` / `eventIdentifier`)，其餘 model (``OrderRecord`` 等) 形狀與 top-level 一致、維持引用 top-level
/// - ``BuyLedgerSchemaV14``：為 ``CampaignReminderRecord`` 新增每團提示時間 `minuteOfDay` 欄位；V15 改動該表形狀，故 V14 把其凍結為影子
/// - ``BuyLedgerSchemaV15``：當前最新版本 (target)，把 ``CampaignReminderRecord`` 的 `minuteOfDay` (Int) 換成 `reminderTimestamp` (Date，使用者自選日期＋提示時間)；其餘 model 形狀不變、`models` 引用 top-level
///
/// V1~V12 已於 pre-release 階段移除。
///
/// Migration 為 forward-only：停在 V13 的 store 逐段 lightweight 遷到 V15。
/// **移除版本會把 floor 往上抬 (單向操作)**：停在低於 V13 的 store 將失去遷移路徑、開啟時被 `makeForApp()` 砍檔重建，故上架後不可再回頭移除
enum BuyLedgerSchemaV13: VersionedSchema {

    // MARK: - Static Properties

    /// 版本識別
    static var versionIdentifier: Schema.Version { Schema.Version(13, 0, 0) }

    /// 此版本的 model 型別；``CampaignReminderRecord`` 指向本 enum 內凍結的影子，其餘維持引用 top-level
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
            CampaignReminderRecord.self,
        ]
    }

    /// 收斂後 migration floor (V13) 的 ``CampaignReminderRecord`` 影子：僅 `campaignID` / `eventIdentifier`，尚未含 V14 的 `minuteOfDay`
    @Model
    final class CampaignReminderRecord {

        // MARK: - Data Properties

        var campaignID: String
        var eventIdentifier: String

        // MARK: - Init

        init(campaignID: String, eventIdentifier: String) {
            self.campaignID = campaignID
            self.eventIdentifier = eventIdentifier
        }
    }
}

/// V14 schema：在 V13 之上為 ``CampaignReminderRecord`` 新增每團提示時間 `minuteOfDay` 欄位
///
/// V15 把 ``CampaignReminderRecord`` 的 `minuteOfDay` 改為 `reminderTimestamp`，故此版本把當時的 ``CampaignReminderRecord`` (含 `minuteOfDay`) 凍結為內嵌影子，保住 V14 attribute 指紋；其餘 top-level model 自 V13 未變、維持引用 top-level
enum BuyLedgerSchemaV14: VersionedSchema {

    // MARK: - Static Properties

    /// 版本識別
    static var versionIdentifier: Schema.Version { Schema.Version(14, 0, 0) }

    /// 此版本的 model 型別；``CampaignReminderRecord`` 指向本 enum 內凍結的影子，其餘維持引用 top-level
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
            CampaignReminderRecord.self,
        ]
    }

    /// V14 的 ``CampaignReminderRecord`` 影子：含 `minuteOfDay` (Int)，尚未改為 V15 的 `reminderTimestamp`
    @Model
    final class CampaignReminderRecord {

        // MARK: - Data Properties

        var campaignID: String
        var eventIdentifier: String
        var minuteOfDay: Int = 540

        // MARK: - Init

        init(campaignID: String, eventIdentifier: String, minuteOfDay: Int = 540) {
            self.campaignID = campaignID
            self.eventIdentifier = eventIdentifier
            self.minuteOfDay = minuteOfDay
        }
    }
}

/// V15 schema：當前最新版本 (target)，把 ``CampaignReminderRecord`` 的每團提示時間由 `minuteOfDay` (Int) 改為 `reminderTimestamp` (Date，使用者自選的日期＋提示時間)；其餘 model 形狀不變、``models`` 引用 top-level
///
/// 因僅為既有 model 移除舊欄位、新增帶預設值的新欄位 (非既有欄位的型別變更)，V14 → V15 走 `.lightweight`
enum BuyLedgerSchemaV15: VersionedSchema {

    // MARK: - Static Properties

    /// 版本識別
    static var versionIdentifier: Schema.Version { Schema.Version(15, 0, 0) }

    /// 此版本的 ``CampaignReminderRecord`` 引用新 top-level 定義 (含 `reminderTimestamp`)
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
            CampaignReminderRecord.self,
        ]
    }
}

/// BuyLedger SwiftData migration plan
///
/// 保留 V13 → V14、V14 → V15 兩段 lightweight 遷移：V13 → V14 為 ``CampaignReminderRecord`` 新增 `minuteOfDay` 欄位；V14 → V15 把 `minuteOfDay` 換成帶預設值的 `reminderTimestamp` 欄位。floor 為 V13：停在 V13 的 store 會逐段遷到 V15，已在 V15 的 store 開啟時 delta 為 0、不觸發任何 stage。新增版本時，於 ``schemas`` 與 ``stages`` append 新版與遷移階段，並把上一版凍結為影子型別保住其 attribute 指紋 (該型別有變更時)
enum BuyLedgerMigrationPlan: SchemaMigrationPlan {

    // MARK: - Static Properties

    /// migration plan 涉及的所有 schema 版本
    static var schemas: [any VersionedSchema.Type] {
        [
            BuyLedgerSchemaV13.self,
            BuyLedgerSchemaV14.self,
            BuyLedgerSchemaV15.self,
        ]
    }

    /// V13 → V14 (lightweight，為 ``CampaignReminderRecord`` 新增帶預設值的 `minuteOfDay` 欄位)；V14 → V15 (lightweight，把 `minuteOfDay` 換成帶預設值的 `reminderTimestamp` 欄位)
    static var stages: [MigrationStage] {
        [
            .lightweight(
                fromVersion: BuyLedgerSchemaV13.self,
                toVersion: BuyLedgerSchemaV14.self
            ),
            .lightweight(
                fromVersion: BuyLedgerSchemaV14.self,
                toVersion: BuyLedgerSchemaV15.self
            ),
        ]
    }
}
