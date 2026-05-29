## Why

「無卡」與「銀行匯款」這類付款方式的款項不會即時入帳，店主必須事後人工核對銀行／轉帳是否確實到款，因此需要在訂單上記錄「對帳狀態」(待對帳 / 對帳成功 / 對帳失敗)。目前訂單編輯表單沒有任何對帳欄位，店主只能用備註土法記錄，無法結構化追蹤哪些訂單尚未對帳。本變更在訂單編輯流程中，於這類付款方式底下提供可選的「對帳狀態」欄位，並讓狀態詞彙比照其他主檔可自訂管理。

## What Changes

- 付款方式新增「銀行匯款」分類旗標 `isBankTransfer`，與既有 `isCardless`（無卡）平行；新增付款方式的 medium sheet 加上第二個 Toggle 收集此旗標。**BREAKING**（資料層）：`PaymentMethodRecord` 與 `PaymentMethodInfo` 新增欄位、付款方式新增 API 簽章由 `(name, isCardless)` 改為 `(name, isCardless, isBankTransfer)`。
- 訂單編輯表單在「付款方式」row 底下，當選到的付款方式屬於無卡或銀行匯款時，顯示一個「對帳狀態」row；操作行為比照「新增付款方式」(tap row 開 picker、可新增)，新增動作使用 medium sheet。
- 新增「對帳狀態」為第 4 種可自訂主檔 (`LookupKind.reconciliationStatus`)，可在「更多」頁管理 (新增／更名／刪除)，預設詞彙為待對帳 / 對帳成功 / 對帳失敗 (由使用者於管理頁或訂單編輯時自行新增，不自動 seed，符合空狀態原則)。
- 訂單持久化新增 `reconciliationStatus` 欄位 (`LedgerOrder` 與 `OrderRecord`)；儲存時若付款方式非無卡／銀行匯款，一律把該欄位清成空字串 (比照無卡金額在切換付款方式後歸零的既有作法)。
- SwiftData schema 升版至 `BuyLedgerSchemaV7`：`OrderRecord` 新增 `reconciliationStatus` (default `""`)、`PaymentMethodRecord` 新增 `isBankTransfer` (default `false`)、新增 `ReconciliationStatusRecord` 主檔表；V6 → V7 走 lightweight migration。
- 主檔更名／刪除時，沿用既有 RootFeature cascade 機制把變更同步到 OrdersFeature 的 in-memory 副本與訂單表 (新增對帳狀態主檔的 cascade 分支)。

## Non-Goals

（詳見 design.md 的 Goals / Non-Goals 區段。）

## Capabilities

### New Capabilities

- `order-reconciliation-status`: 訂單層級的「對帳狀態」欄位——付款方式分類旗標 (無卡／銀行匯款) 觸發條件、訂單編輯表單的條件式「對帳狀態」row 與 medium sheet 新增流程、per-order 持久化，以及切換付款方式時的清空規則。

### Modified Capabilities

- `lookup-management`: 新增「對帳狀態」為第 4 種可管理主檔 (新增／更名／刪除與跨平台呈現)，並為付款方式管理列新增「銀行匯款」徽章 (比照既有「無卡」徽章)。
- `option-picker`: 新增「name-only medium sheet」新增流程——當 caller 提供對帳狀態新增 handler 時，新增控制項改以 medium sheet 收集單一名稱 (取代既有 alert)，既有 alert 與付款方式 editor sheet 流程維持不變。

## Impact

- Affected specs:
  - New: `order-reconciliation-status`
  - Modified: `lookup-management`, `option-picker`
- Affected code:
  - New:
    - BuyLedger/BuyLedger/Core/Domain/ReconciliationStatus.swift（若採詞彙常數／預設集合的輕量型別；不一定需要）
    - BuyLedger/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
    - BuyLedger/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
    - BuyLedger/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
    - BuyLedger/BuyLedger/Features/Orders/Components/LookupItemEditorSheet.swift（name-only medium sheet 共用元件）
  - Modified:
    - BuyLedger/BuyLedger/Core/Domain/LedgerOrder.swift
    - BuyLedger/BuyLedger/Core/Domain/PaymentMethodInfo.swift
    - BuyLedger/BuyLedger/Core/Persistence/OrderRecord.swift
    - BuyLedger/BuyLedger/Core/Persistence/PaymentMethodRecord.swift
    - BuyLedger/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift
    - BuyLedger/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
    - BuyLedger/BuyLedger/Core/Persistence/PersistenceContainer.swift
    - BuyLedger/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift
    - BuyLedger/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
    - BuyLedger/BuyLedger/Features/Orders/OrderEditFeature.swift
    - BuyLedger/BuyLedger/Features/Orders/OrderEditView.swift
    - BuyLedger/BuyLedger/Features/Orders/OrdersFeature.swift
    - BuyLedger/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
    - BuyLedger/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
    - BuyLedger/BuyLedger/Features/Lookups/LookupKind.swift
    - BuyLedger/BuyLedger/Features/Lookups/LookupManagementFeature.swift
    - BuyLedger/BuyLedger/Features/Lookups/LookupManagementView.swift
    - BuyLedger/BuyLedger/Features/More/MoreView.swift
    - BuyLedger/BuyLedger/Features/App/RootFeature.swift
    - BuyLedger/BuyLedgerTests/OrderEditFeatureTests.swift
    - BuyLedger/BuyLedgerTests/OrdersFeatureTests.swift
    - BuyLedger/BuyLedgerTests/RootFeatureTests.swift
    - BuyLedger/BuyLedgerTests/OrderCalculationTests.swift
    - BuyLedger/BuyLedgerTests/OrderPersistenceTests.swift
    - BuyLedger/BuyLedgerTests/OrdersFeaturePerformanceTests.swift
    - BuyLedger/BuyLedgerTests/SnapshotTests.swift
  - Removed: （無）
- 資料 / 同步：SwiftData schema V6 → V7 lightweight migration；維持與 CloudKit 同步相容 (不使用 unique constraint、新欄位帶 default)。
