## Why

HIG 審查指出 Design System 內有數個元件重造了系統已提供的能力。本 change 處理其中四個：分段控制、搜尋欄、進度條、以及設定頁手繪的 disclosure row。每個自製版本都在某處失去了系統元件原本免費提供的行為——進度條沒有 progress 語意因此 VoiceOver 不會播報百分比、搜尋欄沒有 Cancel 鈕與 Search return 鍵、手繪的 disclosure row 沒有列的按壓 highlight 因此看起來與按起來都不像可點擊。

更值得注意的是分段控制元件在整個 repo 內零呼叫點，只有自己的預覽在用。它不是「還沒接上」，而是規範債：後續實作者看到 Design System 裡有這個元件，會理所當然地採用，於是把已知的缺陷擴散出去。

另有三處自訂控制項缺少系統元件本會提供的互動回饋：按鈕樣式不讀取啟用狀態因此停用態與可用態外觀完全相同、破壞性動作做成視覺樣式而非按鈕角色、照片縮圖用點擊手勢而非按鈕因此沒有按壓態也不支援輔助操作。

## What Changes

### 以系統元件取代重造版本

- 搜尋欄改用系統搜尋呈現，取回 Cancel 鈕、Search return 鍵、聽寫、捲動收合等行為，並移除自製元件。此舉同時解除前一個 change 記錄在案的清除鈕命中區缺口。
- 進度條改用系統進度視圖，取回 progress 無障礙語意，使輔助技術能播報進度值。
- 設定頁手繪的 disclosure row 改用系統元件，取回列的按壓回饋與原生指示符號。
- 刪除零呼叫點的分段控制元件，既有需求一律使用系統分段選擇器。

### 訂單列表承擔自製結構的責任

- 訂單列表維持自製分組結構 (不改用系統清單)，但改以惰性容器建構日期區段，使呈現成本不隨訂單筆數線性增長。

### 自訂控制項補齊互動回饋

- 按鈕樣式讀取啟用狀態，使停用態具備可辨識的視覺差異。
- 破壞性動作改以按鈕角色表達，讓系統負責顏色、語音播報與選單呈現的一致性。
- 照片縮圖的點擊改用按鈕，取得按壓態與輔助操作支援。

## Non-Goals

- 不處理審查報告的 blocker 與 suggestion，本次僅收斂在元件重造與互動回饋類的 warning。
- **不改動訂單列表的自製分組結構**：經評估後決定維持既有的卡片加手工分隔線作法，不改用系統清單。此為知情的取捨——代價是訂單列表繼續沒有系統提供的 swipe actions 與分隔線自動對齊，多選批次操作也繼續以自訂狀態手刻。列回收不在此代價之列：既然刻意保留自製結構，就以惰性容器自行承擔該責任 (見 What Changes)。理由是該改動會同時重寫呈現與多選狀態機，風險與本 change 其餘項目不同級。日後若要重新評估，應獨立成一個 change 並單獨驗收。
- 不刪除零呼叫點但不屬於重造類的元件，例如金額輸入欄與清單列以外的元件，那些屬 suggestion 等級。
- 不改動圖表元件的實作方式：走勢圖以繪製路徑實作有其尺寸考量，該議題屬 suggestion 等級。
- 不重新設計搜尋的資訊架構，例如為開團與客戶名單新增搜尋，那屬 suggestion 等級的功能擴充。
- 不調整卡片、徽章、標籤等未被點名重造的既有元件。

## Capabilities

### New Capabilities

- `system-component-preference`: 介面元件的選用契約——系統已提供的能力不得重造，以及重造版本必須具備何種正當理由。
- `control-interaction-feedback`: 自訂控制項必須提供的互動回饋——按壓態、停用態、以及破壞性語意的表達方式。

### Modified Capabilities

(none)

## Impact

- Affected specs: system-component-preference、control-interaction-feedback
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
    - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
    - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
    - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings
    - apps/ios/BuyLedgerTests/__Snapshots__
  - Removed:
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLSearchField.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/SegmentedControls/BLSegmentedControl.swift
