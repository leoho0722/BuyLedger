## Why

訂單清單有兩份版面實作，一份給緊湊尺寸、一份給常規尺寸。兩者的工具列與可勾選列各自維護了一份等價的實作：工具列去除縮排後兩份只相差兩行 (皆為註解)，可勾選列的結構與行為也相同。

這種重複已經造成實際漂移，而非只是理論風險。緊湊版的勾選圖示標記為對輔助技術隱藏，常規版沒有；緊湊版的可勾選列另帶 `.isSelected` 特徵，常規版同樣沒有。也就是說同一個功能在兩種尺寸下對輔助技術呈現不同，而這個差異不會被任何測試抓到，也不會在目視檢查中顯現。

> 更正 (apply 階段發現)：本段原寫「兩版都缺少表達選取狀態的標準特徵」，與程式碼不符：緊湊版當時已有 `.isSelected` 特徵，缺的只有常規版。判斷仍成立 (兩版存在無障礙呈現漂移)，僅前提描述有誤，已於此更正，避免下一案 `accessibility-coverage-sweep` 沿用錯誤前提。

稽核把「常規版缺少選取特徵」報為一條無障礙缺口。但那是症狀。只在常規版補上特徵可以讓那條發現關閉，卻留下同一個成因：兩份各自維護，下一次改動仍會漂移。

## What Changes

- 把工具列與可勾選列各自抽成單一實作，由兩種版面共用。抽取為純粹的搬移，不改變任何呈現或行為。
- 兩種版面改為呼叫共用實作，移除各自的重複定義。
- 抽取後，可勾選列的無障礙屬性只存在一處，使兩種尺寸不可能再漂移。實際補齊選取特徵與裝飾元素隱藏的工作由無障礙覆蓋的變更處理，本變更只負責讓它成為單一定義。

## Non-Goals

- 不新增兩版皆缺少的無障礙特徵。收斂到單一定義時，實作採用 compact 既有行為 (勾選圖示排除於朗讀、`.isSelected` 特徵)，常規版因此連帶獲得原本缺少的這兩項特徵；這是收斂為單一定義的必然結果，不是本變更額外新增的無障礙工作。兩版皆缺、仍待補齊的特徵才屬於無障礙覆蓋的範圍，本變更排在其前，只負責讓那些改動不必做兩次。
- 不改變任何呈現、版面或互動行為。抽取前後兩種尺寸的畫面應完全相同。
- 不合併兩種版面本身。緊湊與常規的版面結構差異是刻意的，本變更只收斂其中等價的部分。
- 不動訂單清單的其他部分，包含篩選、搜尋與列內容。
- 不拆分訂單功能檔。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `design-system-hygiene`: 跨版面重複的元件須有單一定義，補上「同一功能在不同尺寸版面的實作不得各自維護」這一類。
- `order-batch-status-update`: 多選模式的呈現要求明訂在兩種尺寸下由同一份實作提供，使其行為與輔助技術呈現一致。

## Impact

- Affected specs: `design-system-hygiene`（修改）、`order-batch-status-update`（修改）
- Affected code:
  - New:
    - apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift
  - Modified:
    - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
    - apps/ios/CLAUDE.md
  - Removed: （無檔案刪除；移除的是兩份重複的工具列與可勾選列定義）
- 不涉及 SwiftData schema 或資料形狀。
- 呈現不變，因此原則上不需重錄視覺快照；若因抽取造成版面差異則需重錄並確認為非預期並修正。
- 次序約束：本變更必須排在無障礙覆蓋之前，使該變更只需在單一元件補一次特徵，而不是兩份各補一次。
