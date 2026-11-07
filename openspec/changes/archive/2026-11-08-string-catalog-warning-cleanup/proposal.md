## Problem

Xcode 27.2 開啟 `apps/ios/BuyLedger.xcodeproj` 時，Issue Navigator 對 `Localizable.xcstrings` 回報 99 筆警告 (2026-11-07 實測，專案其他檔案 0 筆)：

- 96 筆「References to this key could not be found in source code」：key 被標為 stale (過期)，Xcode 提供「Remove from catalog」作為修法，照做會刪掉仍在使用的翻譯。
- 3 筆「Not all languages format percentages in the same way. Format this number in code using a FormatStyle or a NumberFormatter.」：翻譯值內寫死百分比數字 (`common.ui.label.eightLowerThan`、`orders.edit.message.enter1515`、`quote.calculator.message.targetMarginMust`)。

此外每次在 Xcode IDE 建置後，Xcode 會依編譯器抽取結果改寫 catalog，新增 11 種不屬於 catalog 的字串 (共 13 個位置，含兩筆會再觸發百分比警告的預覽文字)，使用者因此每次建置後手動還原整個檔案，stale 標記也就一直留著。

## Root Cause

逐筆比對 catalog 的 `extractionState` 與編譯器抽出的字串 (DerivedData 的 `.stringsdata`，Debug 建置與 Release archive 各一份，2026-11-07 實測；判斷時排除 Xcode 為 manual 條目產生的 `GeneratedStringSymbols_Localizable` 來源)：

| 類別 | 筆數 | 原因 |
| --- | --- | --- |
| 只在預覽引用 | 10 | 字面值在 `#Preview` 內，編譯器會抽取，但 Xcode 的 catalog 同步不把預覽算成引用而標 stale (6.1 實測後更正原推論) |
| 只在 Debug 抽取 | 1 | `orders.general.label.model` 位於 `#if DEBUG`，Release 抽不到 |
| 經非抽取路徑引用 | 82 | key 以 `String` 傳入 `AppLanguage` 解析、存在 State 或由函式回傳、或以字面值傳給型別為 `String` 的元件參數 |
| 已無引用 | 3 | `common.action.confirm`、`orders.edit.button.saveAndContinue` 只剩測試樣本；`orders.list.label.date` 完全無引用 |

另有 5 筆目前沒有 `extractionState` 但抽不到的 key，下次同步會變成新的 stale：4 筆經 `AppLanguage` 解析，`common.general.label.workspace` 完全無引用。

上表「經非抽取路徑引用」的 82 筆加上 5 筆潛在中的 4 筆與 `orders.general.label.model`、`orders.list.message.tryAnotherSearch`，共 87 筆，依引用形態分三類：帶參數格式字串經 `AppLanguage` 解析 32 筆 (第一類)、存在 State 或由函式回傳 21 筆 (第二類)、字面值傳給 `String` 元件參數 32 筆 (第三類)，另 2 筆 (`#if DEBUG` 與只在預覽使用) 不屬三類。

百分比警告的原因是翻譯值把數字與 `%` 寫在字串裡，各語言的百分比格式無法由 locale 決定。

建置後新增的字串來自三種寫法：`#Preview` 內的示範文字走 `LocalizedStringKey`、`BLNumberField("")` 的空白標題、以及把 verbatim 內容經字串插值轉成 `LocalizedStringResource`／`String.LocalizationValue` (`OrderEditFeature.State.campaignsDisplayText`、`OrdersListQuery.navigationTitle`)。

## Proposed Solution

讓 catalog 與手寫程式碼的引用一致，並把百分比數字移到程式碼格式化 (2026-11-07 使用者定案：第三類一併在本 change 改型別，第一、二類與 `AppLanguage` 收斂另開 change)：

1. 第三類 32 筆元件參數 (含 `OptionPickerSheet` 設定、`PaymentMethodEditorSheet`、`LookupNameEditorSheet`、`BLTextField`、成本明細與分析成本模型、`DashboardKPITile`、數字欄位標題等) 改為 `LocalizedStringResource`，字面值改由編譯器抽取，移除 stale 標記；其中 `SettingsView` AI 模型選擇器的 6 筆位於 `#if DEBUG`，Release 抽不到，比照 `orders.general.label.model` 標 manual (實測後更正，使用者 2026-11-07 同意)。
2. 只在預覽引用的 10 筆 (9 筆預覽 key 與 `orders.list.message.tryAnotherSearch`) 刪除，預覽改 verbatim 或語意相符的 production key，並加入死碼 key 守門清單 (6.1 實測後使用者 2026-11-07 決定)。
3. 第一類 32 筆、第二類 21 筆與 `orders.general.label.model` 標成 `manual` (對應 Xcode 的「Keep and manage manually」)，維持現行程式碼，遷移留給後續 change。
4. 已無引用的 5 筆刪除 (含只供 `BLCard` 預覽的 `common.ui.label.eightLowerThan`，預覽改 verbatim)，測試樣本改用仍在使用的 key，並加入死碼 key 守門清單。
5. 兩筆百分比字串改為帶位置參數的格式字串，數字以 `FormatStyle` 依 App 語言的 locale 格式化後傳入；兩筆 key 改為描述用途的名稱 (`quote.calculator.message.targetMarginLimitNotice`、`orders.edit.message.feeRateInputNotice`)。
6. 產生多餘抽取的來源改為不被抽取的寫法 (預覽示範文字走 verbatim 或既有 key、空白標題不經本地化型別、開團名稱改以兩種狀態呈現)。
7. 新增守門測試：catalog 不得含 stale 條目、翻譯值不得寫死百分比數字。

## Non-Goals

- 第一類、第二類 53 筆的型別遷移與 `AppLanguage` API 收斂：使用者決定另開 change，本 change 以 manual 標記維持現狀。
- `LookupKind` 的 7 個 `String` 屬性改型別：屬第二類性質，本 change 只在畫面邊界轉成 `LocalizedStringResource`。

## Success Criteria

- Xcode 27.2 在 IDE 內建置 `BuyLedger` scheme 後，Issue Navigator 對 `Localizable.xcstrings` 的警告為 0 筆，且 catalog 的 SHA-256 與建置前相同。
- Debug 與 Release 建置的 `.stringsdata` (排除 `GeneratedStringSymbols_*` 來源) 與 catalog 比對：抽出的 key 都在 catalog 內、catalog 內非 manual 的 key 都被兩種建置抽出。
- 英文與正體中文模式下，報價計算的目標毛利提示、訂單編輯手續費說明的文案與修改前逐字相同；第三類元件的文字與修改前相同，且在不重開 App 的情況下切換語言即時更新。
- `LocalizationCatalogTests`、`LocalizationCatalogAppLanguageTests` (含新增守門)、受影響的單元與 snapshot 測試全部通過，snapshot 基準圖不重錄。

## Impact

- Affected specs: `app-localization` (新增兩條 requirement：catalog 抽取狀態與原始碼引用同步、百分比於程式碼格式化)
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings
    - apps/ios/BuyLedger/Features/Quote/Presentation/Formatting/QuoteFormatters.swift
    - apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteView.swift
    - apps/ios/BuyLedger/Features/Quote/Presentation/Root/QuoteStatusBanner.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/Formatting/OrderFormatters.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditFeesSection.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerSheet+Configuration.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerList.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerAddSection.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/BLTextField.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/BLNumberField.swift
    - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupNameEditorSheet.swift
    - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupManagementPresentations.swift
    - apps/ios/BuyLedger/Features/Lookups/Presentation/Root/Views/LookupItemRow.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/OrderCostBreakdown.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/Views/OrderDetailCostView.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderDetail/Views/OrderDetailSummaryView.swift
    - apps/ios/BuyLedger/Features/Insights/Domain/InsightsCostSegment.swift
    - apps/ios/BuyLedger/Features/Insights/Presentation/Formatting/InsightsFormatters.swift
    - apps/ios/BuyLedger/Features/Insights/Presentation/Root/Views/InsightsCostStructureCard.swift
    - apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/DashboardKPITile.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/OrderEditPercentField.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/OrderEditDecimalField.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditItemsSection.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/OrderEditFeature.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderEdit/Views/Sections/OrderEditCampaignSection.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/Queries/OrdersListQuery.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/OrderList/OrderListFeature.swift (OrdersListQuery 採退路時)
    - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersCompactView.swift (同上)
    - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersRegularListColumn.swift (同上)
    - apps/ios/BuyLedger/Features/Insights/Presentation/Root/Views/InsightsTrendCard.swift
    - apps/ios/BuyLedger/Features/FX/Presentation/Root/FxStatusBanner.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLReadableContentLayout.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLReadableScrollContentLayout.swift
    - apps/ios/BuyLedgerTests/Features/Quote/QuoteFormattersTests.swift
    - apps/ios/BuyLedgerTests/Features/Orders/OrderFormattersTests.swift
    - apps/ios/BuyLedgerTests/Features/Orders/OrderCostBreakdownTests.swift
    - apps/ios/BuyLedgerTests/Features/Orders/OrderDetailFeatureTests.swift
    - apps/ios/BuyLedgerTests/Features/Insights/InsightsStatsBreakdownTests.swift
    - apps/ios/BuyLedgerTests/Features/Insights/InsightsFormattersTests.swift
    - apps/ios/BuyLedgerTests/Features/Orders/OrderEditFeatureCampaignsTests.swift
    - apps/ios/BuyLedgerTests/Guards/LocalizationCatalog/LocalizationCatalogTests.swift
    - apps/ios/BuyLedgerTests/Guards/LocalizationCatalog/LocalizationCatalogAppLanguageTests.swift
    - .claude/rules/ios-accessibility-localization.md
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift (預覽改 verbatim)
    - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLCardShadow.swift (預覽改 verbatim；style 閘門修正時 `floating:` 改名 `isFloating:`)
    - apps/ios/BuyLedger/Features/FX/Presentation/Root/FxView.swift (預覽改用 production key)
    - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotOrderEditSectionsTests.swift (新增開團列英文 snapshot)
    - apps/ios/README.md、apps/ios/scripts/upload-testflight.sh (catalog 被改寫時的處理說明，文件同步)
  - New:
    - apps/ios/BuyLedger/Core/Formatters/PercentUpToOneFractionDigitFormatStyle.swift
    - apps/ios/BuyLedgerTests/Core/Formatters/PercentUpToOneFractionDigitFormatStyleTests.swift
    - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotOrderEditSectionsTests/ 的兩張開團列基準圖
  - Removed: none
  - 列過但不需修改：apps/ios/BuyLedger/Features/Insights/Domain/InsightsStats.swift (字面值直接成為 `LocalizedStringResource`)
