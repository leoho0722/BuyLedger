## Why

收鍵盤的行為目前由一個掛在 window 上的點擊手勢承擔。因為它掛在 window 級，畫面上每一個觸控都會經過它，所以它必須逐一排除「不該收鍵盤」的情況——互動控制項、文字輸入視圖，以及系統的文字選單、選取控制點與放大鏡。前兩者以公開型別判斷，可靠；後者只能以 Apple 私有型別的類別名稱關鍵字比對。

這個比對的失效是靜默的：iOS 改名時沒有編譯錯誤、沒有執行期警訊，只有使用者選取文字後點「貼上」時鍵盤意外收起——而這正是當初實作這段過濾要修的 bug。change ui-polish-and-safeguards 已為此補上回歸測試，把靜默失效轉為可見失效，但比對本身仍在。

問題的根源不是過濾寫得不夠好，而是架構決定了必須過濾。window 級攔截是黑名單模型：列舉所有不該攔的情況。黑名單必然不完整——目前列了五個私有類別名稱，日後 iOS 新增任何一種文字互動介面都會是漏網之魚，且同樣靜默。

改為 view 級的背景點擊即可讓問題從根消失：手勢只掛在畫面的背景層，系統文字選單根本不在它的命中測試範圍內，因此不需要任何排除邏輯。黑名單變成白名單，同時擺脫 UIKit 與私有 API 依賴。

此改寫在此刻才可行，是因為前置條件已由其他 change 補齊：數字鍵盤原本沒有 return 鍵也沒有其他收起方式，這是 window 級手勢當初存在的主要理由，而 change touch-target-and-input 已排定為使用數字鍵盤的表單加上鍵盤工具列的完成按鈕與捲動收鍵盤。

## What Changes

### 收鍵盤改由四條明確路徑承擔

- 一般鍵盤：return 鍵搭配送出處理。
- 數字鍵盤：鍵盤工具列的完成按鈕 (由 touch-target-and-input 建立)。
- 可捲動畫面：捲動收鍵盤。
- 不可捲動畫面：點擊背景層收鍵盤，以 SwiftUI 焦點狀態實作。

### 焦點狀態擴大到所有輸入畫面

- 為開團編輯、匯率工具、報價試算、設定、主檔管理、選項選擇器、付款方式編輯器等畫面導入焦點狀態，依專案既有慣例決定其放置位置。
- 建立共用的背景點擊收鍵盤修飾子，供上述畫面套用。

### 移除全域手勢

- 移除 window 級點擊手勢及其私有型別名稱比對、視窗追蹤輔助視圖與手勢代理。
- 改寫平台指引中關於收鍵盤實作的硬規則。

## Non-Goals

- 不移除「點空白處收鍵盤」這項行為本身，僅改變其實作方式。使用者感受到的行為在改寫前後應一致。
- 不重新設計任何畫面的輸入流程或欄位順序。焦點狀態的導入僅為承載收鍵盤與既有的跳轉需求。
- 不處理訂單編輯表單的焦點狀態，該項已由 touch-target-and-input 涵蓋；本 change 僅確認其與新機制相容。
- 不新增鍵盤工具列到原本沒有數字鍵盤的畫面。
- 不改動搜尋列的收鍵盤行為，系統搜尋呈現自行處理 (見 design-system-component-reduction)。

## Capabilities

### New Capabilities

- `keyboard-dismissal-paths`: 收鍵盤的路徑契約——每種鍵盤情境都有明確且不依賴全域攔截的收起方式。

### Modified Capabilities

(none)

## Impact

- Affected specs: keyboard-dismissal-paths
- Affected code:
  - New:
    - apps/ios/BuyLedger/Shared/Keyboard（背景點擊收鍵盤的共用修飾子）
  - Modified:
    - apps/ios/BuyLedger/Features/App/RootView.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift
    - apps/ios/BuyLedger/Features/FX/FxView.swift
    - apps/ios/BuyLedger/Features/FX/FxFeature.swift
    - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
    - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
    - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
    - apps/ios/BuyLedgerUITests（收鍵盤回歸測試的沿用與擴充）
    - apps/ios/CLAUDE.md（收鍵盤實作的硬規則改寫）
  - Removed:
    - apps/ios/BuyLedger/Shared/Keyboard/KeyboardDismissOnTap.swift
