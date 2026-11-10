依 design「基準分支」，apply 前先從 `main` 開新分支。

平行組與分工 (2026-11-10 依 `hc ls` 結果指派：實作者與審查終端由主對話代選，審查加派兩個自定義 agent 為使用者指示；apply 時再以 `hc ls` 確認終端仍在，不在時改派並記錄)：

- 組 A (依序)：1.1 → 1.2，改 `apps/ios/BuyLedgerAccessibilityIDs/` 的 `BLAccessibilityID+Dashboard.swift`、`+Insights.swift`、`+Orders.swift`、`+Campaigns.swift`、`+Common.swift` 與 `apps/ios/BuyLedgerTests/AccessibilityIDs/BLAccessibilityIDTests.swift`；實作 t16 (claude-sonnet-xhigh-impl)，兩個任務改同一個測試檔，由同一位實作者依序做。
- 組 B：2.1，只改 `.claude/rules/ios-ui-tests.md`，與組 A 沒有重疊的檔案，可同時進行；實作 t8 (claude-haiku-max-impl)。
- 審查 (3.1)：t17 (審查用終端) 唯讀審查並逐檔逐條做 style 閘門；主對話以 Agent tool 同時加派 `opus-arch-reviewer` 與 `opus-xhigh-reviewer`，主對話自己也同時審查，最後合併取捨。四方都未參與實作。
- 回歸 (3.2)：主對話執行。
- t9 (codex-luna-max-impl)、t1n (codex-sol-xhigh-impl) 不派工，必要時補為審查者。
- 實作者交回前只跑 `swiftc -parse`；每個 task 的建置與測試都由主對話執行，同一時間只跑一組。

## 1. 載入狀態 identifier 改寫為字串

- [x] 1.1 依 design「往字串字面值收斂」、「值不變的守門」與「Implementation Contract」的第一張表，把 `BLAccessibilityID.Dashboard`、`Insights`、`Orders`、`Campaigns` 中經 `Common.loading(_:)`、`loadFailure(_:)`、`loadFailureRetryButton(_:)` 組出的 11 個常數改成完整字串字面值，值與 doc comment 不變，helper 本身此時保留；`BLAccessibilityIDTests` 加一條暫時的參數化測試，以 11 組「新常數、對應的舊 helper 呼叫」逐組斷言相等，命名依 `<方法>_<情境>_<預期>`。驗證：實作者交回前跑 `swiftc -parse`；主對話逐列對照 `git diff` 與對照表，11 個字串全部相符；主對話在 iPhone 17 (iOS 26.5) 跑 `BLAccessibilityIDTests` 通過，暫時測試的 11 組都有執行 (實際執行數大於 0)。
- [x] 1.2 [after: 1.1] (真依賴：helper 先刪會讓尚未改寫的常數編譯失敗，暫時測試也要在 helper 還在時跑過) 刪除 `BLAccessibilityID.Common` 的 `loading(_:)`、`loadFailure(_:)`、`loadFailureRetryButton(_:)`；刪除 `BLAccessibilityIDTests` 的暫時測試、直接呼叫 helper 的 `loadFailure_容器識別碼_附加載入失敗區域`、`loadFailureRetryButton_容器識別碼_附加重試按鈕區域`，以及總覽的 `loading_總覽載入中_使用總覽前綴`、`loadFailure_總覽載入失敗_使用總覽前綴`、`loadFailureRetryButton_總覽重試按鈕_接在失敗區域後`；依 design「函式只在字面值前綴之後接最後一段」與 Implementation Contract 的第二張表，把 `Common.selectedItem(_:)` 改為 `option("common.navigation.selectedItem", key: feature.rawValue)`、doc comment 的格式說明改為 `"common.navigation.selectedItem.<feature>"`，`selectedItem_指定功能範疇_組成符合慣例之ASCII識別碼` 只更新 3 個預期值；`Common` 其餘成員與其他測試不變。驗證：實作者交回前跑 `swiftc -parse`；`apps/ios` 內搜尋 `Common.loading`、`Common.loadFailure` 為 0 筆；主對話在 iPhone 17 (iOS 26.5) 跑 `BLAccessibilityIDTests` 通過，測試函式比 1.1 之前少 5 個，`selectedItem` 測試的 3 組預期值為新值。

## 2. 規則

- [x] 2.1 依 design「規則寫進 ios-ui-tests.md」，在 `.claude/rules/ios-ui-tests.md`「定位與 identifier」第一條的子 bullet「常數集中在 `BuyLedgerAccessibilityIDs/`」之後補一個同層子 bullet，內容與 design 的區塊相同：在常數定義處，固定 identifier 寫完整字串字面值；需要組出的只能由 `option`、`row`、`indexed` 在字面值前綴之後接最後一段變動值。驗證：`git diff` 只多這一行，沿用 4 空格縮排；內容只寫現行規則與理由，不寫本次經過，符合根目錄 `CLAUDE.md` 的標點與空格規範。

## 3. 審查與回歸

- [x] 3.1 [after: 1.2, 2.1] (真依賴：審查全部變更) t17 唯讀審查全部變更檔並逐檔逐條做 style 閘門；主對話同時派 `opus-arch-reviewer` 審架構與長期維護 (形狀規則能否守住、`selectedItem` 改寫後與 `BuyLedgerAccessibilityIDs/` 其他函式的一致性)、`opus-xhigh-reviewer` 逐項驗證正確性 (11 個字面值與 3 個 `selectedItem` 新值對照 Implementation Contract、刪除的 helper 與測試範圍、規則措辭)，主對話自己審查正確性、測試與風格，合併取捨後修正。驗證：審查前後比對 `git status --short` 與變更檔雜湊一致；各審查者的結論、取捨與決策來源寫進 design。
- [x] 3.2 [after: 3.1] (真依賴：回歸跑在審查修正後的版本) 主對話依 design「驗證範圍」回歸驗證，跑前依 `apps/ios/CLAUDE.md`「UI 測試」完成前置 (模擬器外觀鎖淺色、iPad 先單獨跑 `KeyboardDismissTests` 通過)。驗證：完整 `BuyLedgerTests` 在 iPhone 17 (iOS 26.5) 0 失敗、snapshot 不重錄；`DashboardLaunchLoadingTests`、`InsightsLaunchLoadingTests`、`LoadFailureReloadLoopTests`、`OrderListLoadFailureTests`、`CampaignListLoadFailureLoopTests`、`CampaignFlowTests`、`AdaptiveNavigationContinuityUITests` 在 iPhone 17 (iOS 26.5) 與 iPad Air 11-inch (M4) (iPadOS 27.0) 都通過 (依版面宣告略過的既有案例照舊略過)，每個類別的實際執行數大於 0；回歸前後 `git status --short` 一致；結果寫進 design。
