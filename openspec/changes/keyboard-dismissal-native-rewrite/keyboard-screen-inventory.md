# 會呈現鍵盤的畫面清點

以文字輸入元件（`TextField` / `TextEditor` / `.searchable`）的使用位置逐檔清點，
確認移除全域手勢後沒有畫面失去收鍵盤能力。清點自 2026-07-20 的 `main`（commit `b66e31b`）。

## 清單

| # | 畫面 | 輸入型別 | return 鍵 | 鍵盤工具列 | 捲動收起 | 背景點擊 | 焦點狀態位置 |
|---|------|----------|-----------|------------|----------|----------|--------------|
| 1 | `OrderEditView` | 文字 + 數字混合 | ✓（文字欄） | ✓（僅數字欄聚焦時） | ✓ | 本 change 導入 | `OrderEditFeature.State.focusedField` |
| 2 | `CampaignEditView` | 文字 | ✓ | — | ✓ | 本 change 導入 | 本 change 加入 `CampaignEditFeature` |
| 3 | `FxView` | 數字 | ✗（無 return 鍵） | ✓ | ✓ | 本 change 導入 | `FxFeature.State.isAmountFieldFocused` |
| 4 | `QuoteView` | 數字 | ✗ | ✓ | ✓ | 本 change 導入 | `QuoteFeature.State.isAmountFieldFocused` |
| 5 | `SettingsView` | 數字 | ✗ | ✓ | ✓ | 本 change 導入 | `SettingsFeature.State.isGoalFieldFocused` |
| 6 | `LookupNameEditorSheet` | 文字 | ✓ | — | ✓ | 本 change 導入 | 元件本地（同上） |
| 7 | `OptionPickerSheet` | 搜尋 + 新增 alert | ✓ | — | ✓ | 本 change 導入 | 元件本地（閉包式可重用元件的既有例外） |
| 8 | `PaymentMethodEditorSheet` | 文字 | ✓ | — | ✓ | 本 change 導入 | 元件本地（同上） |
| 9 | `OrdersCompactView` | 系統搜尋 | ✓ | — | ✓（本 change 由立即改互動模式） | 系統搜尋列自帶 Cancel | 系統搜尋自持 |
| 10 | `OrdersView` | 系統搜尋 | ✓ | — | ✓ | 系統搜尋列自帶 Cancel | 系統搜尋自持 |
| 11 | `OrderFilterSheet` | 系統搜尋 | ✓ | — | ✓ | 系統搜尋列自帶 Cancel | 系統搜尋自持 |
| 12 | `OrderMergeCandidateSheet` | 系統搜尋 | ✓ | — | ✓ | 系統搜尋列自帶 Cancel | 系統搜尋自持 |

## 結論

- **需要導入背景點擊修飾子的畫面：8 個**（#1–#8）。
- `LookupManagementView` 本身已無文字輸入：其新增與重新命名的輸入欄在 `navigation-integrity` 中移入
  `LookupNameEditorSheet` 與 `PaymentMethodEditorSheet`，因此焦點狀態歸這兩個元件本地持有，
  不需在 `LookupManagementFeature` 加欄位（原任務 3.5 據此判定為無適用對象）。
- **不需導入的畫面：4 個**（#9–#12）——皆為系統 `.searchable`，其 Cancel 鈕與捲動收合由系統提供，
  再加背景點擊會與系統搜尋的既有行為重疊。
- 每一個畫面至少有兩條收鍵盤路徑，沒有畫面在移除全域手勢後會失去收鍵盤能力。
- 數字鍵盤畫面（#3、#4、#5）沒有 return 鍵，其鍵盤工具列由 `touch-target-and-input` 建立，
  是這些畫面的主要收起路徑；背景點擊為次要路徑。

## 前置條件確認（task 1.1）

- `design-system-component-reduction`：自製搜尋欄 `BLSearchField` 已刪除，其焦點狀態隨之消失 ✓
- `touch-target-and-input`：`OrderEditFeature` 已導入焦點狀態與鍵盤工具列 ✓
- `ui-polish-and-safeguards`：`BuyLedgerUITests/KeyboardDismissTests` 收鍵盤回歸測試已建立 ✓
