## Why

`BuyLedgerAccessibilityIDs/` 的 identifier 定義寫法由 `.claude/rules/ios-ui-tests.md` 規定：固定值寫完整字串字面值，需要組出的只能由 `option`、`row`、`indexed` 在字面值前綴之後接最後一段。目前沒有任何測試守住這條規則，也沒有測試檢查值是否重複。值重複時 UI 測試的查詢會同時找到兩個元素，present／absent 斷言就失效；UI 測試另有 7 個檔案共 16 處以空字串呼叫 ID 函式取得 `BEGINSWITH` 前綴 (主對話 2026-11-13 以 `git grep` 計數，四位審查者各自重算相同)，固定值或另一組前綴落在某個前綴之下時，前綴查詢會誤中別的元素。現有唯一的 ASCII 檢查 `staticIdentifiers_靜態識別碼_皆為ASCII字元` 只手列 8 個常數，新增的 identifier 不受檢。

`load-state-identifier-literals` (2026-11-10 archive) 的架構審查把這個守門列為後續 change；roadmap 把它排在 UI 測試規範修正之前，讓之後新增的 identifier 一加上就受檢。

## What Changes

- 新增掃描式守門測試，受檢對象由掃描 `BuyLedgerAccessibilityIDs/` 原始碼取得、不手列，規則如下：
  - 定義形式：命名空間內只接受封閉清單內的寫法 (固定值的 `static let`、本體恰為一次組字串呼叫的 `static func`、三個組字串函式本身、只有 case 的巢狀列舉)，其他宣告與其他位置的字串字面值都判違規。
  - 宣告位置：App 與 UI 測試 target 在 `BuyLedgerAccessibilityIDs/` 以外擴充 `BLAccessibilityID` 判違規。
  - 形狀：固定值與組出前綴都是 2 至 4 段、以 `.` 分隔、每段以小寫字母開頭的 lowerCamelCase；第一段等於所屬巢狀型別名稱的 lowerCamelCase (例如 `Orders` 對應 `orders`、`AISummary` 對應 `aiSummary`)。
  - 只含 ASCII。
  - 值不重複：固定值之間、組出前綴之間 (不分 `option`／`row`／`indexed`) 都不重複。
  - 前綴不重疊：以「前綴加上該函式的分隔符號」作為查詢前綴，固定值不得以任何查詢前綴開頭，兩個查詢前綴也不得互為開頭。
  - 空掃描：掃不到檔案、固定值或組出前綴時失敗。
- 每條規則都以合成原始碼證明會失敗。
- 刪除 `BLAccessibilityIDTests` 手列 8 個常數的 `staticIdentifiers_靜態識別碼_皆為ASCII字元`，改由掃描式守門涵蓋。
- 系統指定、App 無法改名的 identifier 移出共用命名空間，集中到 UI 測試 `Support/` 的新常數型別 `SystemAccessibilityID`：
  - 刪除 `BLAccessibilityID.Common.backButton` (`BackButton`)，UI 測試 7 個檔案改引用新常數。
  - UI 測試 3 處直接寫的系統字面值 (`PopoverDismissRegion`、`ToggleSidebar`、`ToggleSideBar`) 改引用新常數。
  - 這些值都不變。
- `BLAccessibilityID.Customers.listLoadFailureRetryButton` 的值由 `customers.list.loadFailureRetryButton` 改為 `customers.list.loadFailure.retryButton`，與總覽、分析、訂單清單、開團清單的載入失敗重試鍵寫法一致。
- 修改規格 `ui-test-element-identity`：
  - 命名格式改為 2 至 4 段，feature 段改為所屬巢狀型別。
  - 常數單一來源分成兩處：App 指定的 identifier 在共用命名空間，系統指定的 identifier 在 UI 測試的支援層。
  - 新增「identifier 定義由原始碼掃描守門」的 requirement。
- `.claude/rules/ios-ui-tests.md` 寫明守門與系統 identifier 的位置；`apps/ios/README.md` 的測試目錄說明補上新的守門子資料夾。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `ui-test-element-identity`: 命名格式的段數與 feature 字彙改為符合現況並可機械檢查；常數單一來源區分 App 指定與系統指定的 identifier；新增「identifier 定義由原始碼掃描守門」的 requirement。

## Impact

- Affected specs: `ui-test-element-identity`
- Affected code:
  - New:
    - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierScanner.swift
    - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/ 下拆出的記號、解析與規則型別 (5.1 拆檔，檔名見 design「實作與審查」)
    - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierScanCases.swift
    - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierScanTests.swift
    - apps/ios/BuyLedgerUITests/Support/SystemAccessibilityID.swift
  - Modified:
    - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Common.swift
    - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+More.swift
    - apps/ios/BuyLedgerTests/AccessibilityIDs/BLAccessibilityIDTests.swift
    - apps/ios/BuyLedgerUITests/Screens/Campaigns/CampaignDetailScreen.swift
    - apps/ios/BuyLedgerUITests/Screens/More/SettingsScreen.swift
    - apps/ios/BuyLedgerUITests/Screens/Orders/PhotoViewerScreen.swift
    - apps/ios/BuyLedgerUITests/Screens/Shared/OptionPickerScreen.swift
    - apps/ios/BuyLedgerUITests/Support/XCUIApplication+NavigationBackInteraction.swift
    - apps/ios/BuyLedgerUITests/Support/XCUIApplication+TextInput.swift
    - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
    - apps/ios/BuyLedgerUITests/Tests/More/MoreNavigationSmokeTests.swift
    - apps/ios/BuyLedgerUITests/Tests/Navigation/NavigationScenarioUITests.swift
    - apps/ios/BuyLedgerUITests/Tests/Orders/Regular/OrderRegularColumnScopeTests.swift
    - .claude/rules/ios-ui-tests.md
    - .claude/rules/ios-unit-tests.md
    - apps/ios/README.md
  - Removed: (none)
- 現況 (主對話 2026-11-13 以暫時腳本量測，腳本不進 repo，四位審查者各自重算相同)：178 個 `static let` 全是單一字串字面值，34 個組出前綴全是字面值，37 個 `static func` 是 3 個組字串函式加 34 個本體恰為一次組字串呼叫的包裝函式，沒有 `var`。除 `BackButton` 的形狀與第一段外全部規則 0 違規。
- App 端只有 `CustomersView` 經常數引用改名的重試鍵，程式碼不改；App target 沒有引用 `Common.backButton`。
- 依賴：只用既有的 `TestPaths`、`SwiftSourceFiles` 與 `Guards/Scanning/` 的掃描工具，不新增套件。
- 新守門測試讀 repo 原始碼，與其他 `*ScanTests` 一樣只在模擬器執行。
