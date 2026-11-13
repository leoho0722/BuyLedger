apply 前從 `main` 開新分支 `features/accessibility-identifier-scan-guard` (design「分支」，主對話代選)。

平行組與分工 (2026-11-13 `hc ls` 查詢當下的終端，實作者與審查終端由主對話代選；apply 前以 `hc ls` 重新確認，不在時改派並記錄)：

- 組 A (守門本體)：1.1 → 1.2 → 3.1。
    - 1.1 只新增 `apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/` 的 `AccessibilityIdentifierScanner.swift`、`AccessibilityIdentifierScanCases.swift`、`AccessibilityIdentifierScanTests.swift`。
    - 1.2 只改 1.1 新增的 `AccessibilityIdentifierScanTests.swift` (必要時補 `AccessibilityIdentifierScanner.swift`)，排在 2.1 之後。
    - 3.1 只改 `apps/ios/BuyLedgerTests/AccessibilityIDs/BLAccessibilityIDTests.swift`。
    - 1.1、1.2 實作 t16 (claude-sonnet-xhigh-impl)，3.1 實作 t8 (claude-haiku-max-impl)。
- 組 B (系統 identifier)：2.1，新增 `apps/ios/BuyLedgerUITests/Support/SystemAccessibilityID.swift`，改 `apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Common.swift` 與 design「系統 identifier 收到 UI 測試端」列出的 UI 測試引用處 (`CampaignDetailScreen`、`SettingsScreen`、`PhotoViewerScreen`、`OptionPickerScreen`、`XCUIApplication+NavigationBackInteraction`、`MoreNavigationSmokeTests`、`NavigationScenarioUITests`、`XCUIApplication+TextInput`、`AppNavigator`、`OrderRegularColumnScopeTests`)；與組 A 沒有重疊的檔案，可與 1.1 同時進行；實作 t1n (codex-sol-xhigh-impl)。
- 組 C (客戶頁重試鍵)：2.2，只改 `apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+More.swift`，可與 1.1、2.1 同時進行；實作 t8 (claude-haiku-max-impl)。
- 組 D (文件)：4.1，只改 `.claude/rules/ios-ui-tests.md`、`apps/ios/README.md`，與其他組沒有重疊；實作 t8 (claude-haiku-max-impl)，t8 依 2.2 → 4.1 → 3.1 的順序進行。
- 審查 (5.1)：t9 (codex-luna-max-impl) 唯讀審查並逐檔逐條做 style 閘門；t17 (leader & reviewer) 逐項驗證正確性；t1p (leader & reviewer) 審架構與長期維護；主對話同時審查，最後合併取捨。三方都未參與實作。
- 回歸 (5.2)：主對話執行。
- 實作者交回前只跑 `swiftc -parse`；建置、測試、變異檢查與勾選 task 都由主對話執行，同一時間只跑一組測試。
- 新增的測試方法一律依 `<方法>_<情境>_<預期>` 命名 (後兩段正體中文)，doc comment 以「驗證」開頭，Given／When／Then。

## 1. 掃描式守門

- [x] 1.1 負責：t16 (claude-sonnet-xhigh-impl) 實作，主對話建置與測試。依 design「以原始碼掃描取得受檢 identifier」「宣告層級封閉的定義形式」「以遮罩後的結構切分宣告」「所屬型別取直接位於 BLAccessibilityID 之下的巢狀型別」「形狀規則採 2 至 4 段並修改規格」「範圍外的擴充判違規」「查詢前綴取代原始前綴比較」「掃描器只處理文字」「以合成原始碼證明每條規則會失敗」與 Implementation Contract，新增只 import Foundation 的 `AccessibilityIdentifierScanner`：輸入命名空間與範圍外目錄的「相對路徑與原文」陣列及三個分隔符號，產生定義清單與八種規則 (定義形式、宣告位置、形狀、第一段、只含 ASCII、值重複、前綴重疊、空掃描) 的違規，違規描述的格式、1 起算行號與排序依 Implementation Contract；另新增 `AccessibilityIdentifierScanCases.swift` 的合成案例，以及 `AccessibilityIdentifierScanTests` 中只跑合成原始碼的測試 (分隔符號一律傳字面值 `.`、`:`、`.index.`)：每筆違規案例回報的規則集合等於案例宣告的預期集合，每條規則至少有一筆預期集合只含該規則的案例，案例清單至少涵蓋 Implementation Contract「測試」列出的項目 (含 spec「Identifier naming scheme」與「Identifier definitions are verified by a source scan」示例表中判為 fails 的列)；合規案例 (同一份清單中的合規項目與示例表中判為 passes 的列) 沒有違規。本 task 不讀正式原始碼。驗證：實作者交回前跑 `swiftc -parse`；主對話在 iPhone 17 (iOS 26.5) 跑 `AccessibilityIdentifierScanTests` 全部通過且實際執行數大於 0；主對話逐一對照 Implementation Contract 的規則表與案例清單，每條規則至少有一筆只破壞該規則的違規案例，並記下掃描器的實際行數 (對照 design Risks 的 300 行估計)。
- [x] 1.2 [after: 1.1, 2.1] (真依賴：要用 1.1 的掃描器並改同一個 `AccessibilityIdentifierScanTests.swift`；`BackButton` 在 2.1 移出命名空間前，正式掃描必然失敗) 負責：t16 (claude-sonnet-xhigh-impl) 實作，主對話建置、測試與變異檢查。依 design「掃描器只處理文字」與 Implementation Contract，在 `AccessibilityIdentifierScanTests` 加入讀檔 (`TestPaths.iosRoot` 下的 `BuyLedgerAccessibilityIDs/`，以及範圍外的 `BuyLedger/`、`BuyLedgerUITests/`)、以 `@testable import BuyLedger` 呼叫三個組字串函式取得分隔符號，與掃描正式原始碼的測試：每條規則一個測試 (形狀與第一段可合為一條) 斷言違規為空並在訊息附違規描述；另一條測試釘住分隔符號依序為 `.`、`:`、`.index.`。驗證：實作者交回前跑 `swiftc -parse`；主對話在 iPhone 17 (iOS 26.5) 跑 `AccessibilityIdentifierScanTests` 全部通過，把掃到的檔案數、固定值數、組出前綴數記進 design「實作與驗證」(預期 8 檔、177、34，不同時先查原因)；依 Implementation Contract 的五項變異檢查逐項暫改正式原始碼，確認只有預期的測試失敗且訊息指出對應宣告，每項還原後比對檔案雜湊與改前一致，結果記進 design。

## 2. identifier 調整

- [x] 2.1 負責：t1n (codex-sol-xhigh-impl) 實作，主對話建置。依 design「系統 identifier 收到 UI 測試端」，新增 `SystemAccessibilityID` (4 個常數，值與名稱依 design 的表，正體中文 doc comment)，把 design 列出的 UI 測試引用處改為引用新常數：`BLAccessibilityID.Common.backButton` 的 7 處、`XCUIApplication+TextInput` 刪除 private `popoverDismissRegionIdentifier` 並改引用 `SystemAccessibilityID.popoverDismissRegion`、`AppNavigator.rootSidebarToggle()` 的陣列依原順序改為 `[SystemAccessibilityID.sidebarToggleButtonAlternate, SystemAccessibilityID.sidebarToggleButton]`、`OrderRegularColumnScopeTests.sidebarColumnFrame` 改引用 `SystemAccessibilityID.sidebarToggleButton`；最後刪除 `BLAccessibilityID.Common.backButton` 與其 doc comment。查詢行為不變，這實現 spec「Single source of identifier constants」的系統 identifier 位置。驗證：實作者交回前對改到的檔案跑 `swiftc -parse`；主對話以 `git grep` 確認 `apps/ios` 內 `Common.backButton` 0 處、`"BackButton"`、`"PopoverDismissRegion"`、`"ToggleSidebar"`、`"ToggleSideBar"` 的字串字面值只出現在 `SystemAccessibilityID.swift`；主對話在模擬器建置 `BuyLedger` 與 `BuyLedgerUITests` scheme 通過；UI 回歸併入 5.2。
- [x] 2.2 負責：t8 (claude-haiku-max-impl) 實作，主對話建置。依 design「客戶頁重試鍵與其他載入失敗重試鍵一致」，把 `BLAccessibilityID.Customers.listLoadFailureRetryButton` 的值改為 `customers.list.loadFailure.retryButton`，常數名稱、doc comment 與引用處不變。驗證：實作者交回前跑 `swiftc -parse`；主對話以 `git grep` 確認 `apps/ios` 內字串 `customers.list.loadFailureRetryButton` 0 處，`git diff` 只改這一行；主對話在模擬器建置 `BuyLedger` scheme 通過；UI 回歸併入 5.2。

## 3. 移除手列清單

- [x] 3.1 [after: 1.2] (真依賴：取代者 1.2 的正式掃描通過後才刪舊守門) 負責：t8 (claude-haiku-max-impl) 實作，主對話建置與測試。依 design「刪除手列的 ASCII 測試」，刪除 `BLAccessibilityIDTests` 的 `staticIdentifiers_靜態識別碼_皆為ASCII字元`，其餘測試與 Nested Types 不改。驗證：實作者交回前跑 `swiftc -parse`；主對話以 `git diff` 確認只刪除該測試的區塊，測試函式由 8 個減為 7 個；在 iPhone 17 (iOS 26.5) 跑 `BLAccessibilityIDTests` 全部通過，xcresult 案例數由 18 減為 10。

## 4. 文件同步

- [x] 4.1 負責：t8 (claude-haiku-max-impl) 實作，主對話審閱。依 design Implementation Contract「文件同步」：在 `.claude/rules/ios-ui-tests.md`「定位與 identifier」的「在 `BuyLedgerAccessibilityIDs/` 定義常數時…」子 bullet 之後補一個同層子 bullet，內容與 design 的區塊逐字相同；同檔把系統返回鍵那句的 `(Common.backButton)` 改為 `(SystemAccessibilityID.backButton)`；在 `apps/ios/README.md` 專案結構 `Guards/` 那一行的多檔守門清單最前面補上 `AccessibilityIdentifier`。規則與 README 描述 spec「Identifier naming scheme」「Single source of identifier constants」「Identifier definitions are verified by a source scan」的現行做法。驗證：主對話以 `git diff` 確認規則檔只有這兩處變更且新子 bullet 與 design 區塊逐字相同、README 只改 `Guards/` 那一行；兩檔的 CJK 與半形間距、括號符合根目錄 `CLAUDE.md` 的標點規範。

## 5. 審查與回歸

- [x] 5.1 [after: 1.2, 2.1, 2.2, 3.1, 4.1] (真依賴：審查全部改動) 負責：t9 (codex-luna-max-impl) 唯讀審查並逐檔逐條做 style 閘門，t17 逐項驗證正確性 (規則邏輯與 spec 示例表、接受與拒絕的寫法、違規描述、系統 identifier 的引用替換)，t1p 審架構與長期維護 (掃描器與 `Guards/Scanning/` 的分工、封閉清單的嚴格度、`SystemAccessibilityID` 的位置)；主對話同時審查並合併取捨。審查前後比對 `git status --short` 與變更檔雜湊，確認審查者沒有改檔。驗證：三方回報與主對話的結論、採納與不採納的理由記進 design「實作與審查」；採納的修正改完後重跑受影響的測試類別通過。
- [x] 5.2 [after: 5.1] (真依賴：審查修正後才跑回歸) 負責：主對話。依 design「驗證範圍」：iPhone 17 (iOS 26.5) 跑完整 `BuyLedgerTests` 0 失敗 (既有標為已知問題的預期失敗照舊)，snapshot 不重錄；iPhone 17 (iOS 26.5) 與 iPad Air 11-inch (M4) (iPadOS 27.0) 各跑一次 `KeyboardDismissTests`、`MoreNavigationSmokeTests`、`NavigationScenarioUITests`、`LaunchSmokeTests`、`OrderRegularColumnScopeTests`、`CustomersLoadStateTests`、`CustomersTests` 通過 (依版面宣告略過的既有案例照舊略過)，每個類別至少在一台的實際執行數大於 0。驗證：單元與 UI 的總數、通過數、略過數與預期失敗數記進 design「回歸驗證」；提交前依根目錄 `CLAUDE.md`「文件同步鐵則」對照 `git status --short` 逐列確認，結論寫進 design。
