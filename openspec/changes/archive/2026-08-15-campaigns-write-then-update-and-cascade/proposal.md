## Why

**開團的寫入失敗完全靜默。** 儲存、狀態切換、結團與兩條刪除路徑都先改畫面狀態才寫入，失敗時送出一個帶訊息的動作，而該訊息寫進畫面狀態的一個字串欄位。這個欄位在全專案沒有任何呈現處讀取它。也就是說開團的所有寫入失敗，使用者連一行紅字都看不到：按下結團看到「已收單」，重啟 App 後發現又變回進行中，中間沒有任何提示。

這比訂單的情況更嚴重。訂單至少把失敗訊息畫在列表標頭，開團是連承載都寫了、卻沒有人讀。

**刪除開團不做連動清理。** 刪除只把開團自畫面移除並自資料表刪除，但訂單上的開團名稱、提醒連結記錄、以及行事曆上的事件都留著。結果是：訂單顯示一個已不存在的開團名稱、提醒連結成為指向已刪開團的孤兒、行事曆上留著一則永遠不會被清掉的提醒。刪除對話框對使用者承諾的「刪除這個開團」，在資料層只兌現了三分之一。

**提醒重建的順序讓中途失敗留下殘影。** 目前是先刪舊事件再建新事件，中途失敗會留下一筆指向已刪除事件的連結記錄。

**權限失敗的分類不足。** 存取權限被限制與被拒絕是兩種不同狀態，前者使用者無法自行改變；找不到可寫入的行事曆也不是權限問題。三者目前共用同一條訊息。

## What Changes

- 開團的五條寫入路徑（儲存、狀態切換、結團、兩條刪除）改為寫入成功才更新畫面狀態，失敗一律以確認對話框呈現原因。
- 移除那個沒有任何呈現處讀取的訊息欄位，改由可呈現的對話框狀態承載一次性失敗；載入失敗維持既有的持續狀態呈現。
- 刪除開團時連動清理：自所有訂單移除該開團名稱、刪除提醒連結記錄、移除行事曆上的對應事件。三者與開團本身的刪除在同一次操作內完成，任一步失敗則整體不生效。
- 兩條逐字重複的刪除處理與其確認對話框建構收斂為單一實作，保留兩個呈現入口以支援不同版面層級。
- 提醒重建改為先建立新事件、成功後才刪除舊事件，讓中途失敗不會留下指向已刪除事件的連結。
- 行事曆存取的失敗分類細化：區分被限制與被拒絕，並為「找不到可寫入的行事曆」提供專屬訊息。

## Non-Goals

- 不改變開團與訂單以名稱字串關聯的結構。改用識別碼當歸屬鍵是更大的資料模型變更。
- 不處理既有的孤兒提醒連結與已殘留在行事曆上的事件。本次只讓新的刪除不再產生孤兒；既有殘留的清理需要掃描與使用者確認流程，屬後續變更。
- 不改動開團名稱的唯一性檢查與結單日的日粒度判定，那些已由前一個變更完成；本次改寫儲存流程時必須保留該守門在寫入之前的位置。
- 不改動提醒的設定方式與呈現形式。
- 不改動訂單側的任何寫入路徑。

## Capabilities

### New Capabilities

- `campaign-write-ordering`: 開團寫入路徑的狀態更新順序與失敗呈現契約，涵蓋畫面狀態何時可以改變、失敗時必須呈現什麼、以及刪除必須連動到哪些資料。

### Modified Capabilities

- `campaign-management`: 刪除開團的語意由「移除開團本身」擴充為「連同其在訂單、提醒連結與行事曆上的所有痕跡一併移除」。
- `campaign-calendar-reminder`: 提醒連結的生命週期補上開團刪除時的連動移除；提醒重建改為先建後刪；行事曆存取的失敗分類細化。

## Impact

- Affected specs: `campaign-write-ordering`（新增）、`campaign-management`（修改）、`campaign-calendar-reminder`（修改）
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
    - apps/ios/BuyLedger/Core/Dependencies/CalendarReminderClient.swift
    - apps/ios/BuyLedger/Core/Dependencies/CampaignReminderRepository.swift
    - apps/ios/BuyLedger/Features/App/RootFeature.swift
    - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
    - apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift
    - apps/ios/BuyLedgerTests/CalendarReminderTests.swift
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - New: （無）
  - Removed: （無檔案刪除；移除的是沒有任何呈現處讀取的訊息欄位）
- 不涉及 SwiftData schema 版本或資料形狀；既有資料零影響。
- 次序約束：本變更必須排在開團名稱唯一性與結單日判定之後（兩者改寫同一段儲存流程），並排在主檔單一來源重構之前。
