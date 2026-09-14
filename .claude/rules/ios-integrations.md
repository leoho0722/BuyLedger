---
paths:
  - "apps/ios/BuyLedger/Core/Networking/**"
  - "apps/ios/BuyLedger/Core/Dependencies/{CalendarReminderClient,CurrencyMetadataRepository}*.swift"
  - "apps/ios/BuyLedger/Core/Persistence/*{CurrencyMetadata,CampaignReminder}*.swift"
  - "apps/ios/BuyLedger/Features/AISummary/**"
  - "apps/ios/BuyLedger/Features/Campaigns/**"
  - "apps/ios/BuyLedger/Features/FX/**"
---

# iOS 外部服務整合

## 外部 API

- **`EXCHANGE_RATE_API_KEY`、`OLLAMA_API_KEY` 內嵌於產物是已評估並接受的風險**，前提是產物不對外散布、金鑰為開發者自有。
    - 前提不成立時 (例如開始對外散布)，金鑰必須移出產物、改為執行期提供。
    - 撤換程序見 `apps/ios/README.md` 的「API 金鑰」一節。
    - 未記錄的內嵌不得僅因無人反對就視為已接受，本條即是該項記錄。
- **金鑰一律放 Authorization header (`Bearer <key>`)，端點網址不帶金鑰**：連結的 `FirebasePerformance` 會自動上傳 `URLSession` 請求網址 (不收 header)。
- **網路層錯誤訊息不內插網址、header 或設定值**，避免金鑰進入使用者可見訊息。
- **`ExchangeRateClient` 送出前獨立拒絕含控制字元的金鑰** (避免注入 Authorization header 值)，不以 `URL(string:)` 的失敗 guard 取代；該 guard 仍要保留。
- **`ExchangeRateClient.serviceError` 是唯一的服務錯誤映射**，`fetchLatest` 與 `fetchSupportedCodes` 共用，不在 endpoint 內複製。
- **幣別清單經 `CurrencyMetadataRepository.refreshIfStale(604_800)` 打 `/codes` 並 cache 7 天**：只有非空結果才替換 cache，空結果保留舊 cache 並回報。
    - `CurrencyMetadataPersistence.replace` 保留防禦性 guard，直接呼叫時也不讓空結果進入先刪後寫。
- **AI 摘要串流整體上限 30 秒**：逾時保留已收到的內容、`phase` 設 `.finished` 並使用 `truncationMessage`，不走 `errorMessage`。

## 行事曆 (EventKit)

- **開團訂購提醒經 `CalendarReminderClient` 寫入與移除系統行事曆，請求 full access (`requestFullAccessToEvents()`)**：移除前要先 `event(withIdentifier:)` 讀回事件，write-only 讀不到。
    - Info.plist 帶 `NSCalendarsFullAccessUsageDescription`；權限在實際新增或移除時才請求，不在啟動時請求。
- **提醒連結存 iOS 專屬的 `CampaignReminderRecord`，不進跨平台 `Campaign` schema**：`eventIdentifier` 是裝置本機資料，寫進生成型別會違反平台中立。
    - 連結以 `CampaignReminderLink` 值型別在 repository 與 reducer 間傳遞。
- **提醒是全天事件 (`isAllDay`)，時間由使用者自選並存成 `reminderTimestamp`**：事件日期取 `calendar.startOfDay(for:)`，`EKAlarm(relativeOffset:)` 以該時間戳當天的分鐘數換算秒數，標題取 `Campaign.reminderTitle`。
    - 預設值為結單日 (沒有則今天) 上午 09:00。
    - 儲存時名稱或時間戳變更即重建事件；開團詳情頁只顯示提醒時間，新增與移除走編輯頁。
- **重建提醒先建新事件、成功後才刪舊事件**：`CampaignFeature` 處理 `.rebuild(oldEventIdentifier)` 時先 `addReminder` 並以 `reminderStored` 更新連結，之後才 `removeReminder`。
    - 新事件建立失敗時連結維持指向舊事件，不呼叫 `removeReminder`；先刪後建在中途失敗會留下無法解析的連結。
    - 刪舊事件失敗時連結已指向新事件 (不回滾)，但要以 `campaignWriteFailed` 告知，不用 `try?` 吞掉。
- **`requestAccess` 回 `granted`／`denied`／`restricted` 三態，寫入另可能拋 `noWritableCalendar`**：四種情境各自呈現對應訊息，不合併成單一「需要權限」。
    - `restricted` (家長監護或 MDM) 使用者無法自行開啟，`noWritableCalendar` 是找不到可寫入的行事曆而非權限問題；兩者的訊息都不得引導前往設定。
