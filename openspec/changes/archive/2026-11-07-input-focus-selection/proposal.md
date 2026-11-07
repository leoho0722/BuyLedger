## Problem

點進有既有內容的輸入框時，游標落在點擊位置而不是使用者預期的位置。靠右對齊、預設值為 0 的金額欄最明顯：2026-10-28 實測 iPhone 12 (iOS 26.7.2) 點報價的「商品定價」、iPad Air 5 (iPadOS 27.2) 點訂單的「實付金額」，游標都落在「0」之前，直接輸入 1000 會變成 10000，金額錯一個位數且畫面不提示。UI 測試的 QuoteTests 曾因同一問題假通過 (預期值由錯誤的 10000 換算而來)。一般文字欄位 (客戶名稱、備註、類別名稱等) 也會依點擊位置把游標放在文字中間，接續輸入時插錯位置。

## Root Cause

App 從未在欄位取得焦點時指定游標或選取範圍，全部交給系統依點擊位置決定。數字欄位使用 `TextField(value:format:)`，這個初始化方式沒有選取範圍參數，無法在聚焦時調整；文字欄位使用 `TextField(_:text:)`，也沒有接上 SwiftUI 的 `TextSelection`。報價頁另有結構限制：七個數字欄共用同一個 Bool 焦點，焦點在欄位之間移動時值維持 true，判斷不出哪一欄剛取得焦點。

## Proposed Solution

- 數字欄位 (金額、百分比、匯率、報價、單價、每月目標) 不論值是多少，每次聚焦都先清空，輸入即取代原值；不輸入就離開時回到原本的顯示，綁定值不變；輸入後全部刪掉時還原聚焦當下的值。
- 一般文字欄位 (含多行備註與搜尋欄) 點擊開始輸入時游標一律放在既有內容尾端，不依點擊位置，也不全選或清空；聚焦期間的後續點擊交給系統處理，供微調。
- 文字欄位以 SwiftUI 官方 `TextField(_:text:selection:prompt:axis:)` 與 `TextSelection` 實作，只在焦點由無到有時設定一次游標；數字欄位改以字串草稿編輯，沿用原本的數字格式解析寫回。兩者都是 Design System 共用元件。
- 報價頁改為逐欄焦點，每一欄都能判斷自己的焦點轉換。
- 系統搜尋欄集中於單一入口 `.blSearchable(text:prompt:)` (`BLSearchableModifier`)，搜尋欄與游標處理一起封裝；不開搜尋的選項選擇器由 `OptionPickerSheet` 決定不套用，並以掃描測試守住入口。
- 無卡折抵超過客戶實付時，折抵欄保留輸入值，收款區段底部以紅字提示調整折抵，並停用儲存；表單不再自動改成上限，既有超額訂單開啟時也保留原值並提示。
- 決策來源：使用者 2026-10-28 決定另開 change 修正所有輸入框；使用者 2026-11-04 要求在動工前重新提案，並先後決定游標一律在尾端 (取代原本的「數字欄位聚焦全選」)、值為 0 時先清空，最後決定改成每次輸入時都先清空；量測、單元測試與 UI 測試都用模擬器也是使用者同日決定。「每次清空只套用在數字欄位，文字欄位維持游標在尾端」是主對話的解讀；輸入後全部刪掉時還原聚焦當下的值、報價頁逐欄焦點、新增選項 alert 不遷移、注音組字驗收與輸入欄掃描守門由主對話依程式碼現況提出。搜尋入口收斂由主對話與 Codex 討論後提出，使用者 2026-11-05 核定；`QuoteFeatureTests` 改用 `TestStore` 是使用者同日指示。無卡折抵改為紅字檢核、停用儲存、既有超額保留原值與文案是使用者 2026-11-06 決定，紅字位置由折抵欄正下方改為區段底部是使用者 2026-11-07 決定；移除 3.6 的設定值機制與紅字色彩由主對話提出。

## Success Criteria

- 以 UI Automation 在 iPhone 17 (iOS 26.5) 與 iPad Air 11-inch (M4) (iOS 27.0) 模擬器實測：點預設值為 0 的金額欄左側後直接輸入 1000，欄位值為 1000，不再是 10000；點值為 `0.00` 的費率欄後輸入 5，結束編輯顯示 `5.00`；點已有值的單價與報價欄後輸入，原值被取代；報價頁焦點從一欄直接移到另一欄時同樣先清空；不輸入就離開時回到原本的顯示；輸入後全部刪掉時還原聚焦當下的值。
- 點已有文字的客戶名稱、備註、類別搜尋欄左側後直接輸入，新文字接在原文字尾端；以注音鍵盤組字時組字不被打斷。
- 聚焦期間再點文字欄位其他位置時，游標由系統放置，App 不把它移回尾端；再點數字欄位不會再次清空。
- 既有的數字解析、寫回時機與表單驗證行為不變，只聚焦不輸入不會讓表單變成已修改；對應單元測試與 UI 回歸通過。
- 無卡折抵超過實付時，折抵欄保留輸入值，紅字檢核訊息位於收款區段底部，儲存停用；改到不超過後訊息消失、可儲存；既有超額訂單開啟時保留原值並顯示訊息。
- 全 App 的 `searchable`、`searchFocused`、`searchSelection` 只出現在 `BLSearchableModifier.swift`，違規時掃描測試失敗；不開搜尋的選項選擇器沒有搜尋欄。
- UI 測試共用輸入 helper 不再點欄位右端座標，在新行為下仍能精確輸入要求值；模擬器上 `KeyboardDismissTests.testTapNumericKeyboardDone_數字鍵盤顯示中_收起鍵盤` 與 `QuoteTests` 的多一位數失敗不再出現。

## Impact

- Affected specs: text-input-ergonomics (新增聚焦時游標位置的需求)、order-financial-formula (無卡折抵超過實付改為紅字檢核並停用儲存)
- Affected code:
  - Modified: apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/OrderEditFeature.swift
  - Modified: apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Operations/OrderEditDraftOperations.swift
  - Modified: apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Models/OrderDraft.swift
  - Modified: apps/ios/BuyLedger/Features/Orders/Presentation/OrderMerge/OrderMergeFeature.swift
  - Modified: apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/OrderEditDecimalField.swift
  - Modified: apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/OrderEditPercentField.swift
  - Modified: apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditItemsSection.swift
  - Modified: apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditBasicSection.swift
  - Modified: apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditNotesSection.swift
  - Modified: apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditPaymentSection.swift
  - Modified: apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditFeesSection.swift
  - Modified: apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteFeature.swift
  - Modified: apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteView.swift
  - Modified: apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteInputsCard.swift
  - Modified: apps/ios/BuyLedger/Features/FX/Presentation/Root/FxView.swift
  - Modified: apps/ios/BuyLedger/Features/Settings/Presentation/Root/SettingsView.swift
  - Modified: apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignEdit/CampaignEditView.swift
  - Modified: apps/ios/BuyLedger/Features/Campaigns/Presentation/CampaignEdit/CampaignEditNotesSection.swift
  - Modified: apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupNameEditorSheet.swift
  - Modified: apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
  - Modified: apps/ios/BuyLedger/Features/Orders/Presentation/Components/OrderCategoryFilterRows.swift
  - Modified: apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
  - Modified: apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersRegularListContent.swift
  - Modified: apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersCompactView.swift
  - Modified: apps/ios/BuyLedger/Features/Orders/Presentation/OrderMerge/OrderMergeCandidateSheet.swift
  - Modified: apps/ios/BuyLedger/Resources/Localizable.xcstrings (無卡折抵檢核訊息文案)
  - Modified: apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Orders.swift
  - Modified: apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+More.swift
  - Modified: apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Campaigns.swift
  - Modified: apps/ios/BuyLedgerTests/Features/Quote/QuoteFeatureTests.swift
  - Modified: apps/ios/BuyLedgerTests/Features/Orders/OrderEditFeatureDeductionTests.swift
  - Modified: apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureEditDeductionTests.swift
  - Modified: apps/ios/BuyLedgerTests/Features/Orders/OrderSaveGuardTests.swift
  - Modified: apps/ios/BuyLedgerTests/Features/Orders/OrderMergeFeatureTests.swift
  - Modified: apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderEditSectionsTests/ (商品列輔助字級基準圖)
  - Modified: apps/ios/BuyLedgerUITests/Support/XCUIElement+TextInput.swift
  - Modified: apps/ios/BuyLedgerUITests/Support/XCUIApplication+TextInput.swift
  - Modified: apps/ios/BuyLedgerUITests/Screens/
  - Modified: apps/ios/README.md
  - Modified: apps/ios/CLAUDE.md (ui-automation 在 iPad 輸入數字的方式)
  - Modified: .claude/rules/ios-design-system.md
  - Modified: .claude/rules/ios-navigation.md
  - Modified: .claude/rules/ios-ui-tests.md
  - Modified: .claude/rules/ios-unit-tests.md
  - New: apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/BLNumberField.swift
  - New: apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/BLNumberFieldDraft.swift
  - New: apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/BLTextField.swift
  - New: apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLSearchableModifier.swift
  - New: apps/ios/BuyLedgerTests/Shared/DesignSystem/BLNumberFieldDraftTests.swift
  - New: apps/ios/BuyLedgerTests/Guards/InputFieldConventionScanTests.swift
  - New: apps/ios/BuyLedgerTests/Features/Orders/OrderEditFeatureDisplayTextTests.swift
  - New: apps/ios/BuyLedgerUITests/Support/XCUIElement+FocusTap.swift
  - New: apps/ios/BuyLedgerUITests/Tests/Forms/OrderEditInputFocusUITests.swift
  - New: apps/ios/BuyLedgerUITests/Tests/Forms/QuoteInputFocusUITests.swift
  - New: apps/ios/BuyLedgerUITests/Tests/Forms/ToolsInputFocusUITests.swift
  - New: apps/ios/BuyLedgerUITests/Tests/Forms/EditorTextInputFocusUITests.swift
  - New: apps/ios/BuyLedgerUITests/Tests/Forms/SearchInputFocusUITests.swift
  - Removed: apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/BLSearchableModifier.swift
