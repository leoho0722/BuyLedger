## Why

平台指引明訂「破壞性操作先確認、再寫入，寫入成功才改狀態，不做樂觀更新加回滾」，規格層也已有一條對應要求，但它只涵蓋刪除。訂單的其餘寫入路徑全部是相反的作法：先改畫面狀態，再送出寫入，失敗時只送一行紅字，不回滾。

實際樣態是：狀態變更、批次狀態變更、收款狀態變更三條路徑都先把重建後的訂單寫回畫面狀態，才進入寫入副作用；失敗的處理只是設定一個錯誤訊息字串。結果是畫面顯示新狀態、資料庫仍是舊狀態，而且這個不一致會持續到下次冷啟動重新載入為止。使用者看到「已送達」，重開 App 後發現還是「運送中」，中間沒有任何提示。

錯誤訊息本身還有第二個問題：它被畫在列表標頭當一行紅字，而唯一的清空點在載入成功的分支，該分支被「已載入」旗標守住，整個 App 生命週期內不會再跑第二次。也就是說任何一次操作失敗後，那行紅字會一直釘在列表上直到冷啟動，即使後續操作全部成功。

這是規則存在、但只套在示範點上的典型：規格與指引都寫對了，只有刪除照做。

## What Changes

- 訂單的五條寫入路徑（單筆狀態變更、批次狀態變更、收款狀態變更、刪除、編輯儲存）一律改為寫入成功才更新畫面狀態。失敗時畫面維持原狀，使用者看到的仍是資料庫裡真正的內容。
- 錯誤呈現拆成兩種：載入失敗屬於畫面的持續狀態，維持既有的失敗與重試呈現；單次操作失敗屬於一次性事件，改以確認對話框呈現，關閉即消失，不再殘留於列表標頭。
- 因此移除「錯誤訊息一旦在載入後被設定就再也清不掉」的缺陷，其根因是唯一的清空點被已載入旗標永久擋住。
- 把規格層既有的「刪除必須寫入成功才改狀態」推廣為涵蓋訂單所有寫入路徑，讓這條規則不再只保護一個示範點。
- 批次狀態變更的原子性要求補上失敗語意：單次寫入失敗時，被選取的訂單一筆都不改變，不出現部分套用。

## Non-Goals

- 不改動合併路徑既有的快照回滾機制。那是在本次改造之前就存在的刻意例外，先寫後改全面落地後可另行評估是否收斂，本次不動。
- 不拆分訂單功能檔。該檔的規模問題屬於後續的結構重構變更。
- 不改動開團的寫入路徑。開團的先寫後改與連動刪除屬於下一個變更。
- 不改變任何狀態轉換規則、業務計算或篩選邏輯。
- 不改動載入失敗的既有呈現方式與重試行為。

## Capabilities

### New Capabilities

- `order-write-ordering`: 訂單寫入路徑的狀態更新順序契約，涵蓋畫面狀態何時可以改變、失敗時畫面必須維持什麼，以及一次性操作失敗與持續性載入失敗的呈現必須如何區分。

### Modified Capabilities

- `destructive-action-safeguard`: 既有的「刪除必須寫入成功才改狀態」推廣為涵蓋訂單的所有寫入路徑，而非只有刪除。
- `order-batch-status-update`: 既有的批次原子性要求補上失敗語意，明訂寫入失敗時被選取訂單一筆都不改變。

## Impact

- Affected specs: `order-write-ordering`（新增）、`destructive-action-safeguard`（修改）、`order-batch-status-update`（修改）
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
    - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
    - apps/ios/BuyLedgerTests/OrdersLoadStateTests.swift
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - New: （無）
  - Removed: （無）
- 不涉及 SwiftData schema 或資料形狀；既有資料零影響。
- 次序約束：本變更必須排在訂單編號與寫入完整性之後（兩者都改同一個功能檔的寫入呼叫點），並排在訂單功能拆分之前。
