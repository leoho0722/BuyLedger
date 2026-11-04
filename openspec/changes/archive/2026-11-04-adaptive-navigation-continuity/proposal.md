## Why

Duo 實測已確認訂單詳情在窄版與寬版之間雙向不同步，以及訂單進度膠囊侵入側邊系統區。現有根層替換導覽宿主，訂單分別持有 path 與 regularDetail，iPad「更多」以離頁清空堆疊避開舊容器崩潰；這些行為阻礙連續操作。總覽寬版還省略成本 KPI，分析則另有並排分支，與本次使用者要求的統一排列不符。

## What Changes

- 維持總覽、訂單、開團、分析、更多五個目的地，以同一個 TabView 加 sidebarAdaptable 呈現；iPad 初始使用分頁列並允許切換側邊欄，Duo 沿用原生控制列的自適應位置。
- 訂單、開團、更多使用各自的 NavigationSplitView。清單選取與詳情以同一份功能狀態表示，點選後才顯示詳情，初始不自動選第一筆；較窄空間保留同一目的地並提供系統返回操作。
- 訂單搜尋與篩選保留仍符合條件的目前訂單，排除時清除選取；不偷偷改選第一筆。分頁切換保留各分頁位置與狀態，移除 iPad 清空更多路徑的繞行必須以不崩潰的實測證明。
- 總覽依序呈現日期、本月摘要、四張 KPI、進行中的開團與近期訂單；KPI 為一般字級的二乘二排列，輔助字級改單欄，所有尺寸保留成本卡。分析依序呈現期間、走勢、類別、成本、開團毛利與熱力圖，皆上下排列。
- 欄寬偏好不寫死，各分頁依系統容器、局部尺寸與內容適配收合；摺痕避讓與可操作性優先。總覽、分析、表單與工具依內容採彈性最大寬度，在安全內容區內對齊，保持連續捲動內容的閱讀順序。
- 主檔管理的滑動刪除鈕不再使用 destructive 角色觸發系統的列移除，改以一般按鈕加紅色著色，確認期間、取消後與寫入失敗後都保留該列，成功刪除時不再閃退 (併入原另開的 lookup-swipe-delete-row-retention，決策來源：使用者 2026-10-30)。
- 主檔管理與開團確認刪除後寫入失敗時，「操作失敗」提示一定呈現，關閉提示後仍可再刪除 (寫入失敗通知與確認框改用分開的呈現狀態)；iPad regular 訂單搜尋排除目前訂單時詳情欄一定清空。兩者皆為 4.2 實機回歸發現的間歇性缺陷 (決策來源：使用者 2026-10-31 併入本 change)。
- 主檔改名、新增與付款方式編輯表單在 Duo 摺展後保留草稿、焦點與捨棄確認；訂單詳情在收起側邊欄後摺疊時，狀態與更多選單不再間歇消失。兩者皆為 4.3 Duo 驗證發現的缺陷 (決策來源：使用者 2026-11-01 併入本 change)。
- iPad 分欄清單的選取列文字維持可讀對比；捲動容器閱讀寬度在 `List`／`Form` 遇不對稱安全區時同樣限寬置中；報價輸入列在輔助字級改為堆疊。三者為 4.4 iPad 量測發現的缺陷 (決策來源：使用者 2026-11-02 併入本 change；同日決定清單欄寬維持系統預設)。
- 開團選取列以淺藍底呈現目前詳情；訂單日期脈絡刷新後，目前詳情被日期篩選排除就清空 (決策來源：使用者 2026-11-03 依 `/spectra-verify` 結果併入本 change)。
- 訂單詳情標頭、成本圓餅圖與金額列 (成本圖例、商品明細)、總覽 hero 目標進度、訂單編輯商品列、分析頁走勢圖軸標與類別排行在輔助字級改為可換行或堆疊的排列，不再越界進入系統列或把金額斷在數字中間 (決策來源：使用者 2026-11-02 併入本 change)。
- 補足非對稱 safe area、系統工具列、焦點與草稿的連續性驗收，保留 iOS 26 支援；以真實 TCA path 原型驗證分欄／收合／原生返回，通過後先切換新根；原生宿主、正式 helper 與完整 N1/N5 分成同一前置批的有界任務，整批通過才以完整舊功能入口逐批遷移；跨功能測試隨狀態契約變更更新。

## Capabilities

### New Capabilities

無；沿用既有 capability。

### Modified Capabilities

- `adaptive-layout`：系統自適應根、功能局部空間與統一內容排列。
- `navigation-path-integrity`：單一目的地、明確選取與場景內狀態保留；搜尋排除目前訂單時 regular 詳情欄清空。
- `app-layer-boundaries`：功能自己的 Store 與精確根宿主白名單。
- `standard-navigation-affordance`：原生返回、工具列與安全區可達操作。
- `dynamic-type-adaptation`：輔助字級結構與閱讀寬度自適應。
- `order-category-filter`：過濾後保留仍命中的目前目的地。
- `order-filter-sheet`：套用／清除篩選不隱含首筆選取。
- `ui-test-support-layer`：語意導覽及根模式與功能呈現分開判定。
- `destructive-action-safeguard`：滑動刪除在刪除成功前保留該列，成功刪除不閃退；主檔與開團刪除寫入失敗時提示一定呈現且之後仍可刪除。

## Impact

- Affected specs: adaptive-layout, navigation-path-integrity, app-layer-boundaries, standard-navigation-affordance, dynamic-type-adaptation, order-category-filter, order-filter-sheet, ui-test-support-layer, destructive-action-safeguard
- Affected code:
  - Modified: apps/ios/BuyLedger/Features/App/Presentation/Root/
  - Modified: apps/ios/BuyLedger/Features/Orders/Presentation/
  - Modified: apps/ios/BuyLedger/Features/Campaigns/Presentation/
  - Modified: apps/ios/BuyLedger/Features/More/Presentation/Root/
  - Modified: apps/ios/BuyLedger/Features/Dashboard/Presentation/Root/Views/
  - Modified: apps/ios/BuyLedger/Features/Insights/Presentation/Root/Views/
  - Modified: apps/ios/BuyLedger/Features/Customers/Presentation/
  - Modified: apps/ios/BuyLedger/Features/FX/Presentation/
  - Modified: apps/ios/BuyLedger/Features/Quote/Presentation/
  - Modified: apps/ios/BuyLedger/Features/Lookups/Presentation/
  - Modified: apps/ios/BuyLedger/Features/Settings/Presentation/
  - Modified: apps/ios/BuyLedger/Shared/DesignSystem/Foundations/
  - Modified: apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/
  - Modified: apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/
  - Modified: apps/ios/BuyLedger/Shared/DesignSystem/Components/Forms/
  - Modified: apps/ios/BuyLedger/Shared/DesignSystem/Components/Pickers/
  - Modified: apps/ios/BuyLedger/App/Testing/Configuration/BLUITestConfiguration.swift
  - Modified: apps/ios/BuyLedger.xcodeproj/project.xcproj
  - Modified: apps/ios/BuyLedgerAccessibilityIDs/
  - Modified: apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - Modified: apps/ios/BuyLedgerTests/
  - Modified: apps/ios/BuyLedgerUITests/
  - Modified: apps/ios/CLAUDE.md
  - Modified: apps/ios/README.md
  - Modified: .claude/rules/ios-navigation.md
  - Modified: .claude/rules/ios-accessibility-localization.md
  - Modified: .claude/rules/ios-design-system.md
  - Modified: .claude/rules/ios-ui-tests.md
  - Modified: .claude/rules/ios-unit-tests.md
  - New: apps/ios/BuyLedger/Features/App/Presentation/Root/RootNavigationLayout.swift
  - New: apps/ios/BuyLedger/Features/Orders/Presentation/Root/Views/OrdersLegacyNavigationView.swift (僅遷移期間使用，完成後移除)
  - New: apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLReadableContentLayout.swift
  - New: apps/ios/BuyLedgerUITests/Tests/Orders/OrdersNavigationSmokeTests.swift
  - New: apps/ios/BuyLedgerUITests/Tests/Navigation/AdaptiveNavigationContinuityUITests.swift
  - Removed: apps/ios/BuyLedger/Features/App/Presentation/Root/RootTabLayout.swift
  - Removed: apps/ios/BuyLedger/Features/App/Presentation/Root/RootSidebarLayout.swift
  - Removed: apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLLayoutClass.swift (使用端遷移完才移除)

不變更儲存 schema、財務公式、資料服務或部署最低版本；新增可見提示沿用本地化與 accessibility identifier 機制。上述 New 為規劃路徑，實作時若命名調整須同步 artifacts。
