## Why

ios-dev-kit 4.1.0 規定測試型別過大時要依受測行為拆成獨立的 `<TypeUnderTest><行為>Tests`，不得以跨檔 `extension` 拆分 (例外只有 `<Model>+Fixture.swift`)；`BuyLedgerTests` 與 `BuyLedgerUITests` 目前仍有 309 個含 `+` 的檔案沿用跨檔 extension，靠 `apps/ios/CLAUDE.md` 的過渡例外暫時豁免。Service 已在 `19ef9ccc` 併成單檔，測試是剩下的最後一塊；趁現在一次拆完，之後 style 閘門不必再為既有分檔開例外，新舊測試也只剩一種寫法。

拆分後的 style 閘門另外列出一批既有的測試寫法問題 (預期值由受測程式產生、Given 用 `send` 建立可直設的狀態、等待寫在 Given、一個測試多組 When／Then、tuple 測試參數、`Issue.record` 代替斷言等) 與說明文字不符 kit 的問題；使用者 2026-10-24 決定這些在本 change 一次改完，不再列為範圍外。

## What Changes

- 244 個帶測試的 `<Type>Tests+<行為>.swift` 改成同資料夾的獨立型別 `<TypeUnderTest><行為>Tests` (如 `RootFeatureTests+Sidebar.swift` → `RootFeatureSidebarTests.swift`)，`@MainActor`、`.serialized` 依各新型別實際需要標註；效能測試 `OrdersFeaturePerformanceTests+FilterSheet.swift` 改成 `OrdersFeatureFilterSheetPerformanceTests.swift`
- 原本掛在測試型別上、被多個型別共用的 helper 依使用範圍分三層：只有一個型別用的改成該型別的 `private` 成員；同資料夾多個型別共用的移到同資料夾的 `<TypeUnderTest>TestSupport`；跨資料夾共用的 `<TypeUnderTest>TestSupport` 放 `BuyLedgerTests/Support/`，Guards 之間共用的掃描型別放 `BuyLedgerTests/Guards/Scanning/`
- Guards 的掃描器、lexer、規則與情境資料等 32 個 helper 分檔改成依職責命名的獨立型別 (如 `LayerBoundaryTests+Scanner.swift` → `LayerBoundaryScanner.swift`)
- 快照測試 `SnapshotTests+<X>.swift` 改成 `Snapshot<X>Tests.swift`，16 個基準圖目錄 (74 張圖) 跟著改名，只搬不重錄
- UI 測試：`OrdersScreen+FilterSheet`／`+CategoryPicker` 拆成獨立的 `OrderFilterSheetScreen`／`OrderCategoryPickerScreen` Page Object；同一畫面的片段 (`OrdersScreen+CategoryReveal`／`+RegularFilters`、`CampaignDetailScreen+Content`／`+Toolbar`、`InsightsScreen+LaunchLoading`) 與 UI 測試的 `+Assertions` 併回主檔
- `TestDependencies+Calendar.swift` 併回 `TestDependencies.swift`
- CI 的 `-skip-testing` 改為逐一列出拆出的快照型別與新的效能測試型別，`BuyLedger.xctestplan` 的 `skippedTests` 同步加入新的效能測試型別
- 刪除 `apps/ios/CLAUDE.md` 的「測試拆檔」過渡例外；`.claude/rules/ios-unit-tests.md` 補上共用 helper 三層放置規則；同步 rules 與 `apps/ios/README.md` 中提到舊檔名、舊快照目錄與舊測試識別碼的段落
- `.claude/rules/ios-unit-tests.md` 刪除「只含 `@Test` 的 test extension 不設 MARK」，只保留「helper、fixture、nested type 所在的 extension 照 kit 的區名設 MARK」；`@Test` 一律寫在測試型別本體
- 兩個測試 target 逐檔修正測試寫法，規則清單見 design「測試寫法逐檔修正的規則」：
  - 預期值改字面值
  - Given 直設前置狀態
  - 等待移到 Then
  - 一個測試一組 When／Then
  - 錯誤斷言改 `actualError` 寫法，測試本體不以 `Issue.record` 表達預期
  - tuple 測試參數改具名 `struct`
  - `throws(any Error)` 改 `throws`
  - Bool 命名
  - Service 測試值只覆寫會被呼叫的 closure
  - 恆真斷言改成會失敗的斷言
- UI 測試：40 個測試類別的 `@MainActor` 從逐方法標註改標在類別上；`OrdersScreen.search(_:)` 改用 `hittableSearchField()` 取得搜尋欄
- Guards：`LayerBoundarySourceStripping` 與 `ProjectionWriteBoundarySourceStripping` 兩份相同的剝除註解與字串邏輯合併成 `Guards/Scanning/` 的單一型別
- 兩個測試 target 的 `///` 摘要依 kit 新版的寫法統一動詞開頭，說明文字改白話 (kit `coding-style.md` 註解一節)

## Non-Goals

- 不改 App target 的任何程式碼與行為；測試寫法修正只改測試本身，不為了好測而改正式程式碼
- 不把 `makeOrder` 這類 helper 改寫成 `LedgerOrder.fixture`：預設值不同，改寫會改變測試語意
- 保留延伸非本模組型別的檔案：`Fixtures/Campaign+Fixture.swift`、`Fixtures/LedgerOrder+Fixture.swift`、`Support/LedgerOrder+TestSupport.swift`、`Support/LookupCatalog+TestIsolation.swift`、`Guards/Scanning/String+SourceLiteralScan.swift`
- 不新增禁止跨檔 extension 的守門測試；改由 style 閘門依 kit 審查
- UI 測試類別後綴 `Tests` 改 `UITests` 屬 roadmap 第 8 項，本次不做
- 只被呼叫一次、幾行的短 helper 內聯：使用者決定與 Core 的同類項目另開一輪
- Page Object 回傳 `Bool` 的動作型方法命名 (如 `tapEdit`、`revealElement`) 與 `listColumnBounds` 命名：kit 兩條規則字面相衝、尚未裁定，本次不改
- 不重錄快照、不改 CI 略過快照的策略 (仍以明確的 `-skip-testing` 參數略過)

## Impact

- Affected specs: none
- Affected code:
  - New: 拆出的測試型別、TestSupport 與 Guards 職責型別，逐檔對照見 openspec/changes/test-extension-split/reference/file-list.tsv；apps/ios/BuyLedgerUITests/Screens/Orders/OrderFilterSheetScreen.swift、apps/ios/BuyLedgerUITests/Screens/Orders/OrderCategoryPickerScreen.swift；Guards/Scanning/ 的合併剝除型別
  - Modified: apps/ios/BuyLedgerTests 與 apps/ios/BuyLedgerUITests 下的測試檔 (第 5 至 7 節逐檔修正寫法與說明)、apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__ (目錄改名)、.github/workflows/ci.yml、apps/ios/BuyLedger.xctestplan、apps/ios/CLAUDE.md、apps/ios/README.md、.claude/rules/ios-unit-tests.md、.claude/rules/ios-ui-tests.md、.claude/rules/ios-accessibility-localization.md、.claude/rules/ios-design-system.md、.claude/rules/ios-data-layer.md、openspec/changes/test-extension-split/reference/check_test_extensions.py (測試數量基準)
  - Removed: 304 個跨檔 extension 檔 (309 個含 `+` 的檔案扣除保留的 5 個)、拆完後沒有內容的 apps/ios/BuyLedgerTests/SnapshotTests/SnapshotTests.swift，以及合併後的 `LayerBoundarySourceStripping.swift`、`ProjectionWriteBoundarySourceStripping.swift`
- Compatibility: no capability-level observable behavior changes；測試識別碼改變 (拆檔改型別名、拆開多組 When／Then 新增測試、tuple 參數改 struct 改變參數標籤、Bool 參數改名)，CI、test plan 與文件同步更新
