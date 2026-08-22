## Why

金額格式化在五個畫面各有一份私有實作，而五份的內容完全等價：同樣的幣別代碼、同樣的小數位數、同樣依 App 選定的地區設定。差別只在匯率頁多包了一層空值處理，報價頁多包了一層型別轉換。百分比格式化同樣有兩份重複。

專案沒有任何共用的格式化入口，因此這種重複是預設結果而非疏忽：新畫面需要格式化金額時，最省事的作法就是再複製一份。

重複本身不會出錯，但它讓一致性只能靠人維持。金額呈現的任何調整（小數位數、負數表示、幣別符號位置）都得同時改五個地方，漏改一處就會出現同一筆金額在不同畫面長得不一樣，而這種差異不會有任何測試抓到。

同樣的模式也出現在其他地方：多處以手繪形狀模擬系統元件的外觀，而專案的設計系統準則明訂「系統已提供的能力不得重造」，理由是自製版本失去的不是外觀而是那些不可見卻會一併失去的行為。

## What Changes

- 新增共用的格式化入口，承載金額與百分比的呈現規則，並由五個畫面改為呼叫它。空值與型別轉換由呼叫端或入口的多載處理，不再各自複製整段實作。
- 移除五份私有的金額格式化與兩份私有的百分比格式化。
- 把以手繪形狀模擬系統元件外觀之處收斂為使用系統元件或設計系統既有的樣式擴充點，使其取回系統提供的互動行為。
- 為格式化入口補上行為保存測試，確保收斂前後對同一組輸入產生相同輸出。

## Non-Goals

- 不改變任何金額或百分比的呈現結果。本變更是把五份等價實作收斂為一份，不調整小數位數、幣別符號或負數表示。
- 不建立新的設計系統元件。手繪形狀的收斂方向是改用系統元件或既有的樣式擴充點，不是再造一個自訂元件。
- 不收斂空狀態的文案。各畫面的空狀態說明因情境而異，統一措辭會損失資訊。
- 不改動報價頁的數值型別。該頁的型別轉換由財務公式定調的變更處理，本變更排在其後只承接結果。
- 不處理其他類別的重複（雙版面工具列、相似的功能狀態機），那些各有專屬的變更。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `design-system-hygiene`: 跨畫面重複的呈現規則須有單一入口，補上格式化這一類。
- `system-component-preference`: 既有的「不得重造系統元件」補上手繪形狀模擬系統外觀這個具體情形。

## Impact

- Affected specs: `design-system-hygiene`（修改）、`system-component-preference`（修改）
- Affected code:
  - New:
    - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift
    - apps/ios/BuyLedgerTests/BLFormattersTests.swift
  - Modified:
    - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
    - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
    - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
    - apps/ios/BuyLedger/Features/FX/FxView.swift
    - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
  - Removed: （無檔案刪除；移除的是七份私有格式化方法）
- 不涉及 SwiftData schema 或資料形狀。
- 呈現結果不變，因此原則上不需重錄視覺快照；若因手繪形狀收斂而有版面差異則需重錄並逐張確認。
- 次序約束：本變更必須排在報價頁的型別改動之後（否則格式化入口需同時支援兩種型別），並排在設計 token 掃描守門之前（讓掃描器面對的是收斂後的呼叫點）。
