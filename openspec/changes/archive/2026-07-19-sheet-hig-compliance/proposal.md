## Why

剛完成的 Apple HIG「Sheets」合規審視發現兩項需修正的偏差：

- **F1 (資料遺失風險)**：編輯類 sheet 在使用者下滑關閉且有未儲存變更時，草稿會靜默遺失。全專案沒有任何 `interactiveDismissDisabled`，編輯 feature 也沒有 dirty 判斷。HIG 明文要求：有未儲存變更時下滑關閉，要以 action sheet 讓使用者確認。
- **F2 (sheet 疊 sheet)**：作為 sheet 呈現的訂單編輯表單，其各選項選擇器 (訂單來源／類別／開團／付款方式／對帳狀態／幣別) 都是疊在其上的第二層 sheet，付款方式再往下開新增付款方式表單時最深達三層；開團編輯的訂購提醒選擇器亦同。HIG 要求一次只從主介面顯示一個 sheet，關閉內層 sheet 不應退回另一個 sheet。

兩者都是使用者可感知的體驗問題，F1 更會實際造成資料遺失，值得一併補正。

## What Changes

- **F1 — 未儲存變更關閉確認**：為訂單編輯、開團編輯、付款方式編輯三張 sheet 加入 dirty 判斷；當有未儲存變更時，停用 sheet 的互動式下滑關閉，並讓「取消」按鈕改以確認對話框 (action sheet) 提供「捨棄變更」與「繼續編輯」兩個明確選項。無變更時維持原本直接關閉。
- **F2 — 巢狀選擇器改為 push 導覽**：把訂單編輯表單內的選項選擇器與開團編輯的提醒選擇器，從「疊上第二層 sheet」改為「沿宿主 sheet 的 `NavigationStack` push 呈現」，自動獲得系統 Back 按鈕；付款方式的「新增付款方式」表單也改以 push 呈現，消除三層疊 sheet。共用元件 `OptionPickerSheet` 調整為可嵌入模式 (可省略自帶的 `NavigationStack`)，使其既能維持主介面單層 sheet 呼叫點不變，也能作為 push 目的地。
- 主介面單層 sheet 呼叫點 (設定／報價／匯率／訂單頁的篩選選擇器) 行為完全不變。

## Capabilities

### New Capabilities

- `sheet-dismissal-safeguard`: 編輯類 sheet 在有未儲存變更時，攔截下滑關閉並以確認對話框讓使用者選擇捨棄或繼續，避免草稿靜默遺失。
- `sheet-nested-presentation`: 從已呈現的 sheet 內部開啟選項選擇器或子表單時，一律以宿主 sheet 內的 push 導覽 (帶 Back) 呈現，不再疊出第二層 sheet。

### Modified Capabilities

(none)

## Impact

- Affected specs: 新增 `sheet-dismissal-safeguard`、`sheet-nested-presentation`
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
    - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
    - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
    - apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift
    - apps/ios/BuyLedgerTests/CampaignEditFeatureTests.swift
  - New: (none — 若抽出共用「捨棄變更確認」修飾詞，於 design 階段決定放置位置)
  - Removed: (none)
