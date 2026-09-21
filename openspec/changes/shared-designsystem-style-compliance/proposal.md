## Summary

把 `apps/ios/BuyLedger/Shared/` 全部 35 個 Swift 檔對齊 `/ios-dev-kit` 規範，並切斷 Design System 對 Core 領域型別與 TCA 的依賴。這是 [ios-dev-kit 修正順序](../archive/2026-09-19-core-codegen-style-compliance/proposal.md) 十步計劃的第 2 步，前一步 `core-codegen-style-compliance` 已於 2026-09-19 結案。

## Motivation

2026-09-14 全庫審查在 Shared 區記錄 **334 筆待修項** (實測值，由報告資料集依區域篩出；已排除 2026-09-16 commit `291d841` 修掉的尾隨空白)，內含 169 筆必擋、135 筆違規、29 筆建議與 1 筆已登記例外。35 個檔全部命中，無一乾淨。

排在第 2 位的理由是 **所有畫面都用這些元件與格式化入口**：Design System 的分區寫法、body 邊界與單一入口若在 Feature 重構之後才動，第 3 至 8 步改過的畫面會因元件簽章再變而重做。

三類問題各自獨立且都必須現在處理：

1. **分層反向**：Design System 認得 Core 的 `OrderStatus`、`CurrencyCode`、`PaymentMethodFlags`，`BLDelayedProgressView` 還 `import ComposableArchitecture` 取 `@Dependency(\.continuousClock)`。既有 `app-layer-boundaries` 規格只禁止 Core 與 Shared 引用 Features，沒有涵蓋 Shared 反向認得 Core 領域型別，所以沒有任何測試擋得住。
2. **呈現規則多份複製，而且彼此不一致**：幣別名稱查表在 production code 共 **13 處** (實測值)。`SettingsView`、`QuoteView`、`FxView`、`OrderEditView`、`OrderDetailView` 各有一份 `currencyDisplayText` 產生畫面上的名稱 (5 處，其中 `OrderDetailView` 用 `AppLanguage` 判斷語言、其餘 4 處用 `locale.language.languageCode?.identifier == "zh"`)；`SettingsView`、`FxView`、`QuoteView`、`OrderEditView` 的幣別 picker 各有 `displayName` 與 `searchKeywords` 兩個 closure 自行查表 (8 處)。四個 picker 的列標題格式**三種不一樣**：前三者是 `"代碼 · 名稱"`、`OrderEditView` 是 `"代碼 (名稱)"`，而畫面其他地方只顯示名稱。`design-system-hygiene` 已要求呈現規則單一來源，但條文只點名金額格式化，幣別顯示名稱沒被涵蓋。
3. **排版與分區偏離規範**：98 筆 MARK 使用規範外的分區名，Shared 內實測 11 種 (`View Properties`、`View Body`、`View Method`、`ViewBuilder`、`Cases`、`Display Properties`、`Static Properties`、`Data Properties`、`Identifiable Properties`、`Private Types`、`Typealias`)；另有 31 筆方法與 computed property 留在型別本體、35 筆檔頭格式、16 筆缺 doc comment 或缺 `- Parameter` / `- Returns`，以及三個圖表的 nested `ChartAccessibilityDescriptor` 把 protocol 實作拆到外部 extension、違反 `formatting.md` 對巢狀型別「就地實作」的規定。

## Proposed Solution

依 2026-09-14 四項裁決與 2026-09-19 本次四項裁決執行。

**切斷對 Core 與 TCA 的依賴 (裁決 1)**

- `BLStatusHue` 整個移出 Design System：`OrderStatus` 到色相的對應併入既有的 `apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift`，`BLStatusHue.swift` 刪除。
- `BLFormatters.twd(_:locale:)` 不再讀 `CurrencyCode.twd.code`，改以字面 ISO 代碼表達新台幣。
- `OptionPickerSheet.onAddPaymentMethod` 與 `PaymentMethodEditorSheet` 的儲存 callback 改收三個具名 `Bool`，由 Feature 端呼叫者組回 `PaymentMethodFlags`。
- `BLDelayedProgressView` 移除 `import ComposableArchitecture` 與 `@Dependency(\.continuousClock)`，延遲改用 `Task.sleep(for:)`。

**呈現規則收斂**

- 新增 `apps/ios/BuyLedger/Shared/Localization/CurrencyDisplayName.swift`，提供 `text(code:language:)` 與 `searchKeywords(code:locale:)` 兩個入口共用同一份查表，收 ISO 代碼字串不收 `CurrencyCode`。
- 5 個 Feature 畫面刪掉各自的 `currencyDisplayText`，4 個幣別 picker 的 8 個 closure 改呼叫此入口。**四個 picker 的列標題統一為語系規則** (中文「新台幣」、英文「TWD」)，由使用者 2026-09-19 裁決；以代碼或名稱搜尋的結果不變。這是本次唯一的可見行為變更。

**分區與排版對齊**

- MARK 分區名與順序改依 `formatting.md`：型別本體只留 stored properties 與 Init，方法與 computed property 一律進 extension；`ViewModifier` / `ButtonStyle` / `ProgressViewStyle` 的 `body` 與 `makeBody` 移進以 protocol 命名的 extension (裁決 3)。
- `body` 內不再宣告區域變數：Shared 內 12 處 `BLPalette()` 實例化中，位於 `body` 或 `makeBody` 的 7 處移進 computed property 或 private method (其餘 4 處在 `#Preview`、1 處是 `Color.blSecondaryLabel` 的取色入口，都不動)。
- `BLPalette.secondaryLabel` 的程式碼維持 `Color(uiColor: .label).opacity(0.6)`，改寫規則文字把它記載為「為達 4.5:1 對比地板的既有例外」，解掉與「文字不透明度一律為 1」的表面矛盾。
- 另有 7 筆需要人判斷的項目逐筆定案：修四筆 (百分比串接 `%`、`BLTone` 的字串 role、`BLProgressViewStyle` 拆檔、進度列百分比入口)、改規則文字一筆 (次要文字色)、登記兩筆例外 (`BLPalette` 型別選擇、進度列的兩個一次性數值)。
- 補齊 doc comment、修正檔頭格式、`switch` case 之間不空行 (裁決 2)。

**新增守門**

- `LayerBoundaryTests` 新增兩條分層掃描：`Shared/DesignSystem/` 不得引用 `Core/Domain/` 的頂層宣告名稱、不得 `import ComposableArchitecture`；`DesignSystemSourceScanTests` 新增呈現規則單一入口掃描，production code 不得在 `CurrencyDisplayName.swift` 以外直接呼叫 `localizedString(forCurrencyCode:)`。幣別守門複用既有的 `findViolations`、`swiftFiles`、註解／字串剝除與豁免標記機制，並以 production root 相對路徑 allowlist 保留唯一入口。分層宣告名擷取仍不能沿用排除 `Generated/` 的既有版本，否則 `OrderStatus` 與 `CurrencyCode` 會落在清單外，守門形同空跑。
- 守門要以變異驗證證明能轉紅，不接受只看綠燈。

## Non-Goals

見 design.md 的 Goals / Non-Goals。

## Impact

- Affected specs: app-layer-boundaries, design-system-hygiene
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Shared/ 底下 34 個 Swift 檔 (35 檔扣除被刪的 BLStatusHue.swift)
    - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
    - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
    - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
    - apps/ios/BuyLedger/Features/FX/FxView.swift
    - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
    - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift (BLProgressView 更名連帶)
    - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift (BLProgressView 更名連帶)
    - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift (BLProgressView 更名連帶)
    - apps/ios/BuyLedger/Features/Insights/InsightsView.swift (BLProgressView 更名連帶)
    - apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift
    - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift (補訂單編輯幣別 picker 入口)
    - apps/ios/BuyLedgerTests/LayerBoundaryTests.swift
    - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
    - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
    - apps/ios/CLAUDE.md
    - .claude/rules/ios-design-system.md
    - .claude/rules/ios-accessibility-localization.md
    - .claude/rules/ios-unit-tests.md
    - .claude/rules/ios-ui-tests.md
  - New:
    - apps/ios/BuyLedger/Shared/Localization/CurrencyDisplayName.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressView.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnailButtonStyle.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/OptionPickerList.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/BLSearchableModifier.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressViewStyle.swift
    - apps/ios/BuyLedgerUITests/Tests/Tools/CurrencyPickerTests.swift
    - apps/ios/BuyLedgerTests/CurrencyDisplayNameTests.swift
  - Removed:
    - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLStatusHue.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
