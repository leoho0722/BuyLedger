## Context

BuyLedger 是純本機 (SwiftData + TCA) 的 iOS/iPadOS 代購記帳 App，目前無任何行事曆整合，也未連結 EventKit。開團 (Campaign) 是有狀態實體 (openDate、選填 closeDate、status、settledDate、notes)，其資料形狀由 shared/data-model 跨平台 schema 生成，iOS 端不得私加欄位。開團的新增/編輯走 `CampaignEditView` + `CampaignEditFeature` (草稿表單，儲存由父層 `CampaignFeature` 攔截 `saveTapped` 實際寫入)；開團詳情走 `CampaignDetailView` 讀 `RootFeature` store。既有 system-call 依賴以 `PhotoClient` 為範本 (struct of `@Sendable` closures + `DependencyKey` 的 liveValue/testValue)。時間與行事曆一律走 `@Dependency(\.date)`、`@Dependency(\.calendar)` 注入。

## Goals / Non-Goals

**Goals:**

- 讓代購者在新增/編輯開團頁自選日期＋時間把該開團的「訂購提醒」加入手機行事曆 (詳情頁純顯示)。
- 提醒的標題規則與連結儲存可在不觸碰 EventKit 的前提下以 unit test 驗證。
- 行事曆副作用與本機連結儲存皆以 `@Dependency` 抽象，讓 `CampaignFeature`/`CampaignEditFeature` 的 action flow 可用 `TestStore` 完整驗證。

**Non-Goals:**

- 重複規則、多組提醒 (本期為單一全天事件、單一提示；日期與提示時間由使用者在 popup 自選)。
- 把 eventIdentifier／提醒時間戳寫入跨平台 Campaign 生成型別 (改以獨立 SwiftData 表保存)。
- 使用 EventKitUI 系統事件編輯器 (改以自建 popup sheet)。
- 自動對帳使用者在系統行事曆手動刪除的事件 (移除時 not-found 視為 no-op 保底)。

## Decisions

### 以 EventKit full access 建立與移除行事曆事件

`CalendarReminderClient` 包裝 `EKEventStore`。因「移除提醒」需先 `event(withIdentifier:)` 取回事件再 `remove(_:span:)`，屬讀取操作，write-only access 無法達成，故請求 full access (`requestFullAccessToEvents()`)，Info.plist 新增 `NSCalendarsFullAccessUsageDescription`。權限僅在實際寫入/移除的當下請求 (lazy)，而非 App 啟動即請求。替代方案 EventKitUI 的 `EKEventEditViewController` 可免權限但會開啟系統編輯畫面，與「一鍵新增/移除」的按鈕流程不符，故不採用。

### CalendarReminderClient 依賴介面 (比照 PhotoClient)

新增 `CalendarReminderClient: Sendable`，含四個 `@Sendable` closure：`requestAccess () async -> Bool`、`addReminder (title:String, date:Date, alarmOffset:TimeInterval) async throws -> String` (回傳 eventIdentifier)、`removeReminder (eventIdentifier:String) async throws -> Void` (not-found 視為 no-op)、`reminderExists (eventIdentifier:String) async -> Bool`。liveValue 走真實 `EKEventStore`；testValue 預設為可控 fake (成功授權、回傳固定 identifier、以記憶體集合模擬存在性)，供 TestStore 覆寫。事件為當天全天事件 (`isAllDay`、`startDate == endDate`)，附 `EKAlarm(relativeOffset: alarmOffset)` (由每團設定的提示時間換算為「當天 00:00 起算秒數」，例如 09:00 = `9 * 3600`)，存到預設行事曆。

### 提醒標題規則為純函式 helper

於 `Campaign.swift` 手寫 extension 提供 `var reminderTitle: String` 回傳「「\(name)」訂購提醒」，可脫離 EventKit 直接 unit test。(中間版本曾有 `reminderDate(calendar:)` 由結單日導出提醒日期，最終改為使用者自選時間戳、日期不再掛結單日，故該 helper 已移除；全天事件日期改於 reducer 以 `calendar.startOfDay(for: reminderTimestamp)` 導出。)

### campaign→eventIdentifier 連結存於本機 SwiftData 新表

新增 iOS 端專屬的 SwiftData `@Model CampaignReminderRecord`(`campaignID`、`eventIdentifier`；比照 `CampaignRecord` 不用 `@Attribute(.unique)`，由 persistence 依 campaignID upsert)、`@ModelActor CampaignReminderPersistence`(fetchAll→`[String:String]`、upsert、delete) 與 `CampaignReminderRepository: Sendable` 依賴(比照 `CampaignRepository`：`fetchLinks () async throws -> [String:String]`、`saveLink (campaignID:eventIdentifier:) async throws`、`removeLink (campaignID:) async throws`；type-based `DependencyKey`,共用 `PersistenceContainer.shared`)。理由:eventIdentifier 是 iOS 裝置本機資料,寫入跨平台生成 `Campaign` 型別違反平台中立/不可單平台私加欄位原則;獨立新表與 `Campaign` 解耦、易清理。schema 升 V13(lightweight 加表),因只加新表、現有 top-level model 形狀不變,毋須凍結 V12 shadow(避開「drop 回既有形狀撞 checksum」的雷,加表產生相異指紋)。testValue 以自訂 `@unchecked Sendable` 記憶體容器實作(測試 target 不引入 `LockIsolated`)。(最終形狀：`fetchLinks` 回傳 `[String:CampaignReminderLink]`、`saveLink` 帶 `reminderTimestamp`——見下方 V15 決策；且 migration floor 其後升至 **V13**，V10/V11/V12 已移除，最新鏈為 V13 floor → V14 → V15。)

### 提醒改存使用者自選時間戳、popup 選日期＋時間、詳情頁純顯示 (schema V15)

> 本決策取代上方「每團可設定的提醒時間 (minuteOfDay，V14)」的中間設計。最終形狀如下。

提醒的**日期與提示時間皆由使用者自選、以時間戳保存**，不再自動掛結單日。`CampaignReminderRecord` 的 `minuteOfDay: Int` 改為 `reminderTimestamp: Date`；schema 升 **V15 lightweight**：把 V14 的 `CampaignReminderRecord` (含 `minuteOfDay`) 凍結為 shadow 保住 V14 指紋 (裝置上已有 V14 store)，V15 引用新 top-level、append `.lightweight(V14→V15)`。`CampaignReminderLink` 改帶 `reminderTimestamp`；`saveLink` 參數改為 `reminderTimestamp`。全天事件的日期＝`calendar.startOfDay(for: reminderTimestamp)`、提示位移＝該時間戳當天分鐘數×60。

- **新增/編輯開團頁**：點「新增提醒」以 **sheet** (graphical `DatePicker([.date, .hourAndMinute])`；`presentationDetents([.fraction(0.7)])` 取螢幕 70% 高) 選日期＋提示時間，預設結單日 (無則今天) 09:00；已開啟時列上顯示所選時間戳、可點擊重開 sheet 編輯，紅色「移除提醒」清意圖。**狀態與流程全在 reducer**：`CampaignEditFeature.State` 持 `draftReminderTimestamp` (sheet 草稿) 與 `isReminderPickerPresented`；action `reminderPickerRequested` (以 `reminderTimestamp` 重設草稿並開啟)、`reminderPickerConfirmed` (草稿提交回 `reminderTimestamp`、開啟 `wantsReminder`、關閉)、`reminderPickerCancelled` (關閉不提交)、`removeReminderTapped` (清 `wantsReminder`)——view 只送 action 與綁定 (`$store.draftReminderTimestamp` / `$store.isReminderPickerPresented`)，不在 view 層做 imperative 的 store 多步變更。儲存時 reconcile：`wantsReminder` × 現有連結 × (名稱或 `reminderTimestamp` 變更) 決定建立/移除/重建。
- **開團詳情頁**：純顯示——有提醒時才顯示一列 `LabeledContent("訂購提醒", value: 時間戳格式化)`，不提供新增/移除 (管理走編輯頁)。移除了中間版本的 `addReminderTapped`/`removeReminderTapped` 即時操作。

> 中間版本曾有「CampaignEditView 用意圖旗標切換」與「CampaignDetailView 即時新增/移除」兩項決策，已由上方 V15 決策 (popup + 詳情頁純顯示) 取代，故不另列。

## Implementation Contract

- **行為 (新增/編輯開團頁)**：「開團資訊 Section」出現「訂購提醒」Row。未設提醒時為藍色「新增提醒」；點擊 → 彈出 sheet (螢幕 70% 高、graphical `DatePicker([.date, .hourAndMinute])`，預設結單日／今天 09:00) 選日期＋提示時間 → 按「加入提醒」→ 記錄意圖與時間戳、Row 顯示所選時間戳＋紅色「移除提醒」(點時間戳可重開 sheet 編輯、點紅色按鈕清意圖)。按「儲存」→ 建立/更新開團後 reconcile 行事曆：意圖開啟且無事件→建立；意圖關閉且有事件→移除；意圖開啟、有事件且 (名稱或時間戳變更)→先移除再重建。全天事件日期＝`startOfDay(時間戳)`、提示＝時間戳當天時間。按「取消」→ 不動行事曆。權限被拒 → 不建立、彈出說明 alert。
- **行為 (開團詳情頁)**：純顯示——僅在該開團已有提醒時，「開團資訊 Section」顯示一列唯讀「訂購提醒｜<日期 時間>」；不提供新增/移除 (管理走編輯頁)。
- **介面 / 資料形狀**：
  - `CalendarReminderClient`：`requestAccess()->Bool`、`addReminder(title:date:alarmOffset:)->String`、`removeReminder(eventIdentifier:)`、`reminderExists(eventIdentifier:)`。事件 `isAllDay`、`startDate == endDate == date`、附 `EKAlarm(relativeOffset: alarmOffset)`。
  - `CampaignReminderLink { eventIdentifier: String; reminderTimestamp: Date }` (含 `timeText` 顯示)；`CampaignReminderRepository`：`fetchLinks()->[String:CampaignReminderLink]`、`saveLink(campaignID:eventIdentifier:reminderTimestamp:)`、`removeLink(campaignID:)`(皆 async throws)；底層 `CampaignReminderRecord` @Model + `CampaignReminderPersistence` @ModelActor。schema **floor V13 → V14 → V15** (V13 建表、V14 加 `minuteOfDay`、V15 改 `reminderTimestamp`；皆 lightweight)。
  - `Campaign.reminderTitle -> String`。
  - `CampaignEditFeature.State`：`wantsReminder: Bool`、`reminderTimestamp: Date`、`draftReminderTimestamp: Date`、`isReminderPickerPresented: Bool`；action `reminderPickerRequested` / `reminderPickerConfirmed` / `reminderPickerCancelled` / `removeReminderTapped`。
  - `CampaignFeature.State`：`reminderLinks: [Campaign.ID: CampaignReminderLink]`、`@Presents var reminderAccessAlert`；action `reminderLinksLoaded([Campaign.ID:CampaignReminderLink])`、`reminderStored(Campaign.ID, CampaignReminderLink?)`、`reminderAccessDenied`。
- **失敗模式**：`removeReminder` 對不存在的 identifier 為 no-op、不丟錯；`addReminder` 失敗 (無權限或 EventKit 錯誤) → 不更新連結、送 `reminderAccessDenied` 顯示 alert；權限被拒不視為程式錯誤。
- **驗收準則**：
  - Unit test：`Campaign.reminderTitle`、`CampaignReminderRepository` round-trip (含 `reminderTimestamp`，in-memory container)。
  - Unit test：`SchemaMigrationTests` 驗 V13 store → V15 遷移 (OrderRecord 完整、CampaignReminderRecord 欄位遷移正確) 與 V15 reopen 指紋守門。
  - Unit test：`CampaignFeature` 以 `TestStore` + fake 驗證連結載入、save-time reconcile (自選時間戳建立、改名重建、改時間戳重建、清意圖移除)、權限被拒 alert；`CampaignEditFeature` 驗 popup 四 action (requested/confirmed/cancelled/removeReminderTapped)。
  - 手動驗收：build and run 到實體 iPhone 15 Plus，編輯頁 popup 選日期＋時間、儲存後於系統行事曆確認全天事件與提示時間；詳情頁純顯示該時間戳。
- **範疇邊界**：
  - In scope：兩頁 Row／popup／純顯示、`CalendarReminderClient`、`CampaignReminderRecord`/`Persistence`/`Repository`、`Campaign.reminderTitle`、`CampaignFeature`/`CampaignEditFeature` 接線、Info.plist 權限字串、SwiftData V13→V15 (含 floor 升至 V13)、對應 unit test。
  - Out of scope：重複/多提醒、EventKitUI、外部刪除自動對帳、Android/其他平台。

## Risks / Trade-offs

- [使用者在系統行事曆手動刪除事件 → App 端連結殘留、Row 仍顯示「移除提醒」] → 移除時 not-found 視為 no-op 保底；完整對帳 (以 `reminderExists` 於進頁時校正) 列為 Non-Goal 的後續。
- [full access 權限範圍大於單純新增所需] → 這是「需支援移除」的必要成本；權限延後到動作當下才請求、usage description 明確說明用途。
- [SwiftData 升 V13 屬最高風險區] → 只做 lightweight 加表、不動現有 model 形狀，故毋須凍結 shadow、不撞 checksum；既有 SchemaMigrationTests (V10→V11、V11 reopen) 不受影響，須全綠。
- [編輯開團改了名稱/結單日但已有提醒 → 事件內容過時] → save-time reconcile 以「先移除再重建」保持事件與開團一致。
- [模擬器/CI 無行事曆權限 → 無法自動化端到端] → 端到端以實機手動驗收；邏輯層 (reconcile、日期規則) 全走 fake client 的 TestStore 覆蓋。
