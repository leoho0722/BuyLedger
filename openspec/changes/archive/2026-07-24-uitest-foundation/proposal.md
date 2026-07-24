## Why

App 目前沒有可用的 UI 自動化防護網：全專案 0 個 `accessibilityIdentifier`，現有 4 支 UI 測試只能用中文字面值定位元素，切到英文模式即整批失效；找不到元素時一律 `XCTSkip`，等於在錯誤環境下靜默全綠。加上模擬器首次啟動是真正的空資料狀態、且無任何啟動參數掛鉤，多數畫面根本走不到，功能實作完或修正完後無法在模擬器上做實際驗證。

本 change 建立「跑得起來」的地基：讓後續各功能區域的 UI 測試只需寫流程，不必各自重造啟動、種子、定位與等待邏輯。

## What Changes

- 新增 App 端測試啟動掛鉤：以 `ProcessInfo` 讀取啟動參數，支援重置狀態、注入種子資料、指定固定時間、切換外部相依 test double、注入載入失敗態；整段以 `#if DEBUG` 圈住，Release build 不含這些分支。
- 新增種子資料組合 (seed profile)：UI 測試模式改用 in-memory `ModelContainer`，依指定 profile 注入確定性的訂單、開團、主檔資料，讓空狀態與有資料兩種畫面都能重現。
- 新增外部相依的 test double：UI 測試模式下 `PhotoClient` 回傳內建測試影像、`CalendarReminderClient` 不觸發系統權限、`ExchangeRateClient` 回固定匯率快照，並略過 Firebase 初始化。
- 新增全 App 共用的 `accessibilityIdentifier` 常數目錄與命名規則，並先套用到根導覽 (tab bar 與 iPad 側邊欄)、總覽頁與設定頁；其餘區域的 identifier 隨各自的覆蓋 change 一併補上。
- 新增測試端共用 Support 層：統一測試基底、啟動選項、compact 與 regular 導覽分流、條件式等待、捲動、文字輸入、選單／sheet／alert 互動、數值解析、共用斷言與失敗診斷，全部抽成可複用 function。
- 新增 Page Object 契約 (`Screen` protocol) 與根導覽、總覽、設定三個 Page Object 作為範本。
- 新增測試計畫檔，鎖定語言與地區、關閉隨機順序、把效能測試移出主回歸集合。
- 改寫既有 4 支 UI 測試：改用 identifier 定位、以硬斷言取代掩蓋性的 `XCTSkip`、以條件式等待取代固定延遲、以 identifier 取代位置索引。
- 補文件：把 UI 測試硬規則寫進 iOS 平台的 AI 協作指引，把執行指令與啟動參數約定寫進 iOS 平台的開發者說明文件。

## Non-Goals

- 不在本 change 涵蓋訂單、開團、客戶、分析、主檔、匯率報價、AI 總結、照片與合併等區域的流程測試；這些由後續各區域的覆蓋 change 逐一交付，本 change 只提供它們共用的地基。
- 不為上述區域預先補 `accessibilityIdentifier`：identifier 與消費它的測試同批交付，避免補了卻無人使用而漂移。
- 不改動 App 的既有產品行為：啟動掛鉤只在 UI 測試模式生效，正式執行路徑的資料來源、導覽與畫面內容維持不變。
- 不引入第三方 UI 測試框架：一律使用 XCTest 與 XCUITest。
- 不在本 change 接上 CI：CI 串接留待全區域覆蓋完成、回歸時間確定後再評估。
- 不調降 UI 測試 target 的部署目標：維持只在 iOS 26.x 模擬器執行，並在文件中明文記錄。

## Capabilities

### New Capabilities

- `ui-test-launch-harness`: App 端的 UI 測試啟動掛鉤，涵蓋狀態重置、種子資料注入、固定時間注入、外部相依 test double 與載入失敗態注入，並保證只存在於 debug 建置。
- `ui-test-element-identity`: 以 `accessibilityIdentifier` 作為 UI 測試唯一定位依據的命名規則與標註規範，涵蓋靜態元素、列舉型集合、使用者資料列與序位集合。
- `ui-test-support-layer`: 測試端可複用的共用基礎層，涵蓋測試基底、啟動選項、導覽分流、等待、捲動、輸入、互動、解析、斷言與診斷，以及 Page Object 契約。

### Modified Capabilities

(none)

## Impact

- Affected specs: `ui-test-launch-harness`、`ui-test-element-identity`、`ui-test-support-layer`
- Affected code:
  - New:
    - apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift
    - apps/ios/BuyLedger/Core/Testing/BLUITestSeedProfile.swift
    - apps/ios/BuyLedger/Core/Testing/BLUITestSeedData.swift
    - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
    - apps/ios/BuyLedger/Shared/Accessibility/BLAccessibilityID.swift
    - apps/ios/BuyLedgerUITests/Support/BLUITestCase.swift
    - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
    - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
    - apps/ios/BuyLedgerUITests/Support/Waiting.swift
    - apps/ios/BuyLedgerUITests/Support/Scrolling.swift
    - apps/ios/BuyLedgerUITests/Support/TextInput.swift
    - apps/ios/BuyLedgerUITests/Support/MenuInteraction.swift
    - apps/ios/BuyLedgerUITests/Support/SheetInteraction.swift
    - apps/ios/BuyLedgerUITests/Support/AlertInteraction.swift
    - apps/ios/BuyLedgerUITests/Support/ValueParsing.swift
    - apps/ios/BuyLedgerUITests/Support/Assertions.swift
    - apps/ios/BuyLedgerUITests/Support/Diagnostics.swift
    - apps/ios/BuyLedgerUITests/Screens/Screen.swift
    - apps/ios/BuyLedgerUITests/Screens/RootNavigationScreen.swift
    - apps/ios/BuyLedgerUITests/Screens/DashboardScreen.swift
    - apps/ios/BuyLedgerUITests/Screens/SettingsScreen.swift
    - apps/ios/BuyLedgerUITests/Tests/Smoke/LaunchSmokeTests.swift
    - apps/ios/BuyLedgerUITests/Tests/Smoke/HarnessSelfCheckTests.swift
    - apps/ios/BuyLedger.xcodeproj/BuyLedgerUITests.xctestplan
  - Modified:
    - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
    - apps/ios/BuyLedger/App/BuyLedgerApp.swift
    - apps/ios/BuyLedger/Features/App/RootTabLayout.swift
    - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
    - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
    - apps/ios/BuyLedger/Features/More/MoreView.swift
    - apps/ios/BuyLedgerUITests/BuyLedgerUITests.swift
    - apps/ios/BuyLedgerUITests/BuyLedgerUITestsLaunchTests.swift
    - apps/ios/BuyLedgerUITests/KeyboardDismissTests.swift
    - apps/ios/BuyLedgerUITests/PhotoViewerPagingTests.swift
    - apps/ios/BuyLedger.xcodeproj/project.pbxproj
    - apps/ios/CLAUDE.md
    - apps/ios/README.md
  - Removed: (none)
