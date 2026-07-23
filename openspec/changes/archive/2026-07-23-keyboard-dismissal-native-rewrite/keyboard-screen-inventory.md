# 會呈現鍵盤的畫面清點

以文字輸入元件（`TextField` / `TextEditor` / `.searchable`）的使用位置逐檔清點，
確認移除全域手勢後沒有畫面失去收鍵盤能力。清點自 2026-07-20 的 `main`（commit `b66e31b`）。

## 清單

| # | 畫面 | 輸入型別 | return 鍵 | 鍵盤工具列 | 捲動收起 | 背景點擊 | 焦點狀態位置 |
|---|------|----------|-----------|------------|----------|----------|--------------|
| 1 | `OrderEditView` | 文字 + 數字混合 | ✓（文字欄） | ✓（僅數字欄聚焦時） | ✓ | ✗ 不可行 | `OrderEditFeature.State.focusedField` |
| 2 | `CampaignEditView` | 文字 | ✓ | — | ✓ | ✗ 不可行 | 本 change 加入 `CampaignEditFeature` |
| 3 | `FxView` | 數字 | ✗（無 return 鍵） | ✓ | ✓ | ✗ 不可行 | `FxFeature.State.isAmountFieldFocused` |
| 4 | `QuoteView` | 數字 | ✗ | ✓ | ✓ | ✗ 不可行 | `QuoteFeature.State.isAmountFieldFocused` |
| 5 | `SettingsView` | 數字 | ✗ | ✓ | ✓ | ✗ 不可行 | `SettingsFeature.State.isGoalFieldFocused` |
| 6 | `LookupNameEditorSheet` | 文字 | ✓ | — | ✓ | ✗ 不可行 | 元件本地（同上） |
| 7 | `OptionPickerSheet` | 搜尋 + 新增 alert | ✓ | — | ✓ | ✗ 不可行 | 元件本地（閉包式可重用元件的既有例外） |
| 8 | `PaymentMethodEditorSheet` | 文字 | ✓ | — | ✓ | ✗ 不可行 | 元件本地（同上） |
| 9 | `OrdersCompactView` | 系統搜尋 | ✓ | — | ✓（本 change 由立即改互動模式） | 系統搜尋列自帶 Cancel | 系統搜尋自持 |
| 10 | `OrdersView` | 系統搜尋 | ✓ | — | ✓ | 系統搜尋列自帶 Cancel | 系統搜尋自持 |
| 11 | `OrderFilterSheet` | 系統搜尋 | ✓ | — | ✓ | 系統搜尋列自帶 Cancel | 系統搜尋自持 |
| 12 | `OrderMergeCandidateSheet` | 系統搜尋 | ✓ | — | ✓ | 系統搜尋列自帶 Cancel | 系統搜尋自持 |

## 實作結果修正（2026-07-20）

原訂的「背景層點擊」路徑**經介面測試證實在本專案不可行**，已移除：

- `Form`／`List` 版面：`.background { Color.clear.contentShape(.rect).onTapGesture { … } }` 收不到觸控；
  加上 `.scrollContentBackground(.hidden)` 讓背景層可見後仍然收不到——這兩個容器會消耗空白處的觸控且不向下傳遞。
- `ScrollView` 版面（匯率工具）：同樣未能收到背景點擊。
- 兩次嘗試皆由 `BuyLedgerUITests/KeyboardDismissTests` 實跑驗證，非推測。

因此收鍵盤實際為**三條路徑**：return 鍵、鍵盤工具列、捲動收起。下表「背景點擊」欄一律標為不可行。

## 結論

- **背景點擊路徑經證實不可行，已不導入任何畫面**（詳見上方「實作結果修正」）。
- `LookupManagementView` 本身已無文字輸入：其新增與重新命名的輸入欄在 `navigation-integrity` 中移入
  `LookupNameEditorSheet` 與 `PaymentMethodEditorSheet`，因此焦點狀態歸這兩個元件本地持有，
  不需在 `LookupManagementFeature` 加欄位（原任務 3.5 據此判定為無適用對象）。
- **不需導入的畫面：4 個**（#9–#12）——皆為系統 `.searchable`，其 Cancel 鈕與捲動收合由系統提供，
  再加背景點擊會與系統搜尋的既有行為重疊。
- 每一個畫面至少有兩條收鍵盤路徑，沒有畫面在移除全域手勢後會完全失去收鍵盤能力；
  但**使用者確實失去了「點任意空白處收鍵盤」這個習慣動作**，這是移除 window 級手勢後未被補回的行為差異。
- 數字鍵盤畫面（#3、#4、#5）沒有 return 鍵，其鍵盤工具列由 `touch-target-and-input` 建立，
  是這些畫面的主要收起路徑；背景點擊為次要路徑。

## 前置條件確認（task 1.1）

- `design-system-component-reduction`：自製搜尋欄 `BLSearchField` 已刪除，其焦點狀態隨之消失 ✓
- `touch-target-and-input`：`OrderEditFeature` 已導入焦點狀態與鍵盤工具列 ✓
- `ui-polish-and-safeguards`：`BuyLedgerUITests/KeyboardDismissTests` 收鍵盤回歸測試已建立 ✓
