## Why

HIG 審查在觸控與輸入領域找出八項 warning，它們共同的性質是「功能存在但不好用，或只有部分人用得到」。

命中區方面，六處篩選膠囊實測 32 至 34pt、開團詳情的收款狀態切換鈕僅約 16pt，而後者是會直接改資料且無確認無復原的動作。這些都不是視覺問題——它們看起來正常，只是點不太到。

可觸達性方面，刪除開團只存在於長按選單、刪除商品明細只存在於左滑，兩者都沒有可見的按鈕或選單替代。使用語音控制、切換控制或外接鍵盤的使用者加得了資料卻刪不掉。

輸入方面，全專案沒有任何欄位設定內容型別，因此客戶名稱拿不到聯絡人自動填入；數字鍵盤沒有 return 鍵，而專案也沒有任何鍵盤工具列提供「完成」，訂單編輯表單有十個數值欄位密集排列，使用者要收鍵盤只能靠一個未被明示的全域點擊手勢；表單內數值欄位的命中高度僅約 22pt，點在同一列的上下緣不會聚焦；長表單完全沒有焦點管理，欄位之間無法跳轉。

此外全螢幕照片檢視器不支援縮放與雙點放大——而訂單照片上的商品標籤、單號與金額細節正是這個功能存在的理由。

## What Changes

### 命中區補齊

- 六處篩選膠囊抽成共用元件，一次把命中區補到 44pt 並維持既有視覺尺寸。
- 開團收款狀態切換鈕的命中區補到 44pt。

### 手勢一律配可見替代

- 開團詳情的操作選單補上刪除項，使刪除不再只能透過長按選單觸達。
- 商品明細列表提供可見的刪除入口，與既有的可見新增入口對稱。

### 輸入體驗

- 為可自動填入的欄位設定內容型別，使客戶名稱等欄位取得系統的填入建議。
- 為使用數字鍵盤的表單加上鍵盤工具列的完成按鈕，並讓表單支援捲動收鍵盤。
- 表單內數值欄位的命中高度補到 44pt。
- 訂單編輯表單導入焦點管理，使欄位可依視覺順序跳轉，並在新訂單時聚焦第一個欄位。

### 標準手勢語彙

- 全螢幕照片檢視器支援縮放與雙點放大，縮放中停用換頁以免手勢互搶。

## Non-Goals

- 不處理 blocker 與 suggestion 等級的發現。命中區的契約由 hig-blocker-remediation 建立，本 change 將其套用到其餘呼叫點。
- 不新增觸覺回饋，該項屬 suggestion 等級且目前狀態已避開所有相關錯誤。
- 不改動收鍵盤的全域手勢實作，該項屬 suggestion 等級。
- 不調整篩選膠囊的視覺設計，僅擴大其命中區。
- 不為照片檢視器新增縮放與換頁以外的互動。

## Capabilities

### New Capabilities

- `gesture-and-target-affordance`: 可觸達性契約——命中區下限在其餘呼叫點的落實、手勢必須有可見替代、以及標準手勢語彙的遵循。
- `text-input-ergonomics`: 文字與數值輸入的契約——自動填入、鍵盤收合路徑、欄位命中區與焦點順序。

### Modified Capabilities

(none)

## Impact

- Affected specs: gesture-and-target-affordance、text-input-ergonomics
- Affected code:
  - New:
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips（共用篩選膠囊元件）
  - Modified:
    - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
    - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
    - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
    - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
    - apps/ios/BuyLedger/Features/FX/FxView.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings
    - apps/ios/BuyLedgerTests/__Snapshots__
