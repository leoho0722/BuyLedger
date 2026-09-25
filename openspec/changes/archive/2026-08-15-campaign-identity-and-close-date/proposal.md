## Why

**開團名稱沒有唯一性檢查。** 儲存時只做去除前後空白與判空，同名的開團可以被建立任意多個。而開團與訂單之間是以名稱字串關聯的，因此同名會造成三種實際損害：彙總時以名稱比對成員，同一批訂單會被同時算進兩個團；改名的連動更新會誤傷另一個同名團的訂單；從訂單深入開團的導覽以名稱取第一個命中，永遠只會進到其中一個。

**結單日的自動收單以時間戳比較，但輸入只能選日期。** 建立新開團時結單日的初值是建立當下的完整時間戳，而表單上的選擇器只顯示日期部分，因此使用者選「今天」實際存下的是「今天的某時某分」。自動轉換的判定是「結單日早於現在」，於是今天下午建立、結單日選今天的開團，過幾分鐘重新載入就會被自動收單，並從訂單編輯的可歸屬清單中消失。使用者的認知是「今天截止」，系統的行為是「剛才就截止了」。

兩者都是資料正確性問題，且都在使用者無感的情況下發生。

## What Changes

- 開團儲存時檢查名稱是否與其他開團重複（排除自身），重複時拒絕儲存並在表單上明示原因，不寫入。
- 自動收單的判定改為以日為粒度：結單日當天維持進行中，隔日起才轉為已收單。這讓「結單日設為今天」符合使用者的認知。
- 既有的同名開團資料不做自動清理或改名。偵測與提示留給後續變更，本次只擋住新的重複。

## Non-Goals

- 不改變開團與訂單之間以名稱字串關聯的結構。改用識別碼當歸屬鍵是更大的資料模型變更，且會連動彙總、篩選與深層連結。
- 不清理既有的同名資料，也不強制使用者改名。本次只讓新的重複無法產生。
- 不處理既有重名資料造成的彙總重複計算。那需要偵測與提示流程，屬於後續變更；本次在規格中明記為已知限制。
- 不改動開團的寫入順序與連動刪除。那屬於下一個變更。
- 不改動結單日的輸入形式（維持只選日期）。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `campaign-management`: 開團名稱新增唯一性要求；自動收單的時間判定由時間戳粒度改為日粒度。

## Impact

- Affected specs: `campaign-management`（修改）
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Core/Domain/Campaign.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
    - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
    - apps/ios/BuyLedgerTests/CampaignFeatureTests.swift
    - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
    - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
    - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
    - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings
    - apps/ios/CLAUDE.md
  - New: （無）
  - Removed: （無）
- 不涉及 SwiftData schema 或資料形狀；既有資料零影響，包含既有的同名開團仍可正常讀寫。
- 次序約束：本變更必須排在開團寫入順序與連動刪除之前，讓同名守門先落在「寫入之前」的位置；否則後者改寫同一段儲存流程時會需要重寫本變更剛完成的分支。
