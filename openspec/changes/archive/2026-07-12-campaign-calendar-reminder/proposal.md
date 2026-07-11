## Why

代購者開團後，需要記得在結單後向供應商下單；目前 App 沒有任何提醒機制，代購者只能自行記憶或另設鬧鐘，容易漏單。將「訂購提醒」直接寫入手機行事曆，讓代購者在開團當下就把下單期限交給系統代管，降低漏單風險。

## What Changes

- 在「新增/編輯開團頁」(CampaignEditView) 的「開團資訊 Section」新增一個提醒 Row：以意圖旗標運作，按鈕只切換是否要建立提醒、不當下碰行事曆；待使用者按「儲存」真正建立/更新開團時，才由 CampaignFeature 一併寫入或移除行事曆事件。「取消」則不留下任何行事曆項目。
- 在「開團詳情頁」(CampaignDetailView) 的「開團資訊 Section」新增一個提醒 Row：對已存在開團的真實行事曆事件立即建立/移除 (比照該頁既有的狀態切換、結團等即時動作)。
- 兩頁的 Row 呈現一致：已建立提醒時顯示紅色「移除提醒」按鈕 (role `.destructive`)；未建立時顯示藍色「新增提醒」按鈕。
- 提醒事件語意：使用者在新增/編輯開團頁的 popup (calendar + 時間 picker) 自選**日期＋提示時間**、以時間戳保存；行事曆建成該日期的全天事件，提示 (EKAlarm) 設在所選時間。popup 預設帶結單日 (無則今天) 09:00，皆可改。事件標題為「「<開團名>」訂購提醒」。開團詳情頁純顯示該提醒時間戳、不提供新增/移除 (管理走編輯頁)。
- 新增 EventKit 整合：因需支援「移除」既有事件，需向使用者請求行事曆完整存取 (full access)，於實際寫入/移除的當下才請求；權限被拒時以 alert 告知，不靜默失敗。

## Non-Goals

- 不做重複規則或多組提醒；本期為單一全天事件、單一提示 (日期與時間由使用者在 popup 自選)。
- 不把行事曆事件識別碼寫入跨平台 Campaign 型別：行事曆 event identifier 是 iOS 裝置本機資料，寫入跨平台生成型別違反「schema 平台中立、不可單平台私加欄位」原則。改以 iOS 端專屬的 SwiftData 新表 (CampaignReminderRecord) 保存 campaignID → eventIdentifier 連結，與跨平台 Campaign 型別解耦。
- 不採用 EventKitUI 的 EKEventEditViewController 系統編輯器：使用者要的是「一鍵新增/一鍵移除」的按鈕流程，而非開啟系統事件編輯畫面。
- 不處理使用者在系統行事曆 App 手動刪除事件後、App 端連結殘留的自動清理 (以移除時 not-found 視為 no-op 保底；完整對帳留待後續)。

## Capabilities

### New Capabilities

- `campaign-calendar-reminder`: 開團訂購提醒與手機行事曆整合——在新增/編輯開團頁與開團詳情頁提供新增/移除提醒的能力，定義提醒事件的日期與標題規則、兩頁不同的建立時機 (儲存時 reconcile vs 立即)、行事曆存取權限請求與失敗處理，以及裝置本機的 campaign→事件連結儲存。

### Modified Capabilities

(none)

## Impact

- Affected specs: 新增 `campaign-calendar-reminder`
- Affected code:
  - New:
    - apps/ios/BuyLedger/Core/Dependencies/CalendarReminderClient.swift
    - apps/ios/BuyLedger/Core/Dependencies/CampaignReminderRepository.swift
    - apps/ios/BuyLedger/Core/Persistence/CampaignReminderRecord.swift
    - apps/ios/BuyLedger/Core/Persistence/CampaignReminderPersistence.swift
    - apps/ios/BuyLedgerTests/CalendarReminderTests.swift
  - Modified:
    - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
    - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
    - apps/ios/BuyLedger/Core/Domain/Campaign.swift
    - apps/ios/BuyLedger/Resources/Info.plist
  - Removed: (none)
- Dependencies: 新引入系統框架 EventKit (autolink)；Info.plist 新增 NSCalendarsFullAccessUsageDescription 權限字串；SwiftData schema 升 V13 (lightweight 加 CampaignReminderRecord 表)。
