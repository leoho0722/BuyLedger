apply 前從 `main` 開新分支 `features/ui-test-disable-view-animations` (主對話代選)。

平行組與分工 (2026-11-13 `hc ls` 查詢當下的終端，實作者與審查者由主對話代選；apply 前以 `hc ls` 重新確認，不在時改派並記錄)：

- 基準 (1.1)：主對話在未修改的建置上量測，App 端與 UI 測試端的實作 (2.1 至 2.3) 都排在它之後。
- 組 A (App 端與單元測試)：2.1，改 `apps/ios/BuyLedger/App/Testing/BLUITestHarness.swift`、`apps/ios/BuyLedger/App/Testing/Configuration/BLUITestConfiguration.swift`、`apps/ios/BuyLedgerTests/App/Testing/BLUITestConfigurationTests.swift`，新增 `apps/ios/BuyLedgerTests/App/Testing/BLUITestHarnessViewAnimationTests.swift`；實作 t16 (claude-sonnet-xhigh-impl)。
- 組 B (掃描守門)：2.2，只新增 `apps/ios/BuyLedgerTests/Guards/ViewAnimationSwitchScanTests.swift`，與組 A 沒有重疊的檔案，可同時實作；實作 t1n (codex-sol-xhigh-impl)。
- 組 C (UI 測試端)：2.3，改 `apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift`、`apps/ios/BuyLedgerUITests/Tests/More/LookupManagementTests.swift`、`apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignFlowTests.swift`，可同時實作；實作 t9 (codex-luna-max-impl)。
- 組 D (文件)：2.4，改 `.claude/rules/ios-ui-tests.md`、`apps/ios/CLAUDE.md`、`apps/ios/README.md`，不影響建置，可在基準量測期間進行；實作 t8 (claude-haiku-max-impl)。
- 審查 (3.1)：t17 (leader & reviewer) 唯讀審查正確性並逐檔逐條做 style 閘門，未參與實作；主對話同時審查，最後合併取捨。
- 驗證 (4.x)：主對話執行，同一時間只跑一組測試，所以 4.1 → 4.2 → 4.3 → 4.4 依序進行。
- 實作者交回前只跑 `swiftc -parse` (文件任務不需要)；建置、測試、變異檢查與勾選 task 都由主對話執行。
- 新增的測試方法依 `<方法>_<情境>_<預期>` 命名 (後兩段正體中文)，doc comment 以「驗證」開頭，Given／When／Then，預期值寫字面值。

## 1. 基準量測

- [x] 1.1 負責：主對話。依 design「以同一輪的基準與修正後連跑驗證效果」，在任何程式碼改動進入工作區之前，以未修改的建置於 iPad Air 11-inch (M4) iPadOS 27.0 模擬器量測三類觸發的基準：轉向測試 12 次、搜尋欄測試 3 次、兩條鍵盤輸入測試各 3 次 (測試名稱見 design 的表)。驗證：每條測試在 result bundle 的實際執行次數等於指定次數；從 Build Logs 檔以 `grep -c` 計出 `App animations complete notification not received` 的次數，並記下觸發的迭代與每次耗時；某類別當天沒有觸發時記為「當天未重現」；結果記進 design 新增的「實作與驗證」一節。

## 2. 實作

- [x] 2.1 [after: 1.1] (真依賴：基準要在未修改的建置上量測) 負責：t16 (claude-sonnet-xhigh-impl) 實作，主對話建置與測試。依 design「在 BLUITestHarness 啟用時關閉 UIView 動畫」「關閉動畫的判斷抽成可注入的函式並以單元測試守住」與 Implementation Contract「App 端程式碼」「測試」，讓 App 實現 spec「View animations are disabled in UI test mode」：`BLUITestConfiguration` 解析 `-BLUITestKeepViewAnimations`，`BLUITestHarness.applyViewAnimationPolicy(for:setAnimationsEnabled:)` 只在測試模式且未帶保留參數時關閉一次動畫，`prepareIfNeeded()` 在 `isEnabled` 的 `guard` 之後、建立 model container 之前以 `UIView.setAnimationsEnabled` 接上。TDD 分兩次交付：先交測試 (`BLUITestHarnessViewAnimationTests` 的四列參數化測試與 `BLUITestConfigurationTests` 的旗標解析案例) 加上不呼叫 closure、不解析旗標的空實作，主對話跑出預期的失敗後再交完整實作。驗證：實作者每次交回前跑 `swiftc -parse`；主對話在 iPhone 17 iOS 26.5 跑兩個測試類別，第一次只有預期的案例失敗 (`["-BLUITest"]` 那一列、帶旗標的解析案例)，第二次全部通過且實際執行數大於 0；`git diff` 只改了上述四個檔案。
- [x] 2.2 [after: 1.1] (真依賴：與 2.1 同樣排在基準之後；GREEN 與變異檢查要等 2.1 接線完成) 負責：t1n (codex-sol-xhigh-impl) 實作，主對話建置與測試。依 design「以原始碼掃描守住動畫開關只由 harness 關閉」與 Implementation Contract「測試」，新增 `ViewAnimationSwitchScanTests`：剝除註解與字串後，`BuyLedger/` 內 `UIView.setAnimationsEnabled` 恰好 1 次且位於 `App/Testing/BLUITestHarness.swift`、`setAnimationsEnabled(true` 為 0 次，掃描檔數大於 0。驗證：實作者交回前跑 `swiftc -parse`；主對話在 2.1 完成後於 iPhone 17 iOS 26.5 跑這個類別全部通過；變異檢查在 4.1 執行。
- [x] 2.3 [after: 1.1] (真依賴：基準要在未修改的建置上量測) 負責：t9 (codex-luna-max-impl) 實作，主對話建置。依 design「以啟動參數讓呈現競態測試保留動畫」與 Implementation Contract「UI 測試端程式碼」，`LaunchOptions` 新增 `shouldKeepViewAnimations` 並在值為 `true` 時輸出 `-BLUITestKeepViewAnimations`，design 列出的 6 條呈現競態測試啟動時帶上它，其他測試不改。驗證：實作者交回前跑 `swiftc -parse`；主對話以 `git diff` 確認只改了 `LaunchOptions` 與這 6 條測試的啟動設定、旗標字串與 design 逐字相同；在模擬器建置 `BuyLedgerUITests` scheme 通過；行為由 4.3、4.4 驗證。
- [x] 2.4 負責：t8 (claude-haiku-max-impl) 實作，主對話審閱。依 design「改寫規則檔的閒置等待條目並補手動實測說明」與 Implementation Contract「規則檔文字」「`apps/ios/CLAUDE.md` 文字」「README 文字」，讓三份文件描述現行做法：UI 測試模式關閉 UIView 動畫、呈現競態測試以保留參數保留動畫、helper 照常保留、判讀與退場條件，以及手動實測時如何看到動畫；舊的閒置等待條目整段刪除。驗證：主對話以 `git diff` 確認三檔的新增內容與 design 文字逐字相同、新條目位於「資料與相依」一節指定位置、沒有其他改動；規則檔中「長時間連續執行」與「單獨重跑，至多兩次」字樣 0 處。

## 3. 審查

- [x] 3.1 [after: 2.1, 2.2, 2.3, 2.4] (真依賴：審查 2.x 的成品) 負責：t17 (leader & reviewer) 唯讀審查並逐檔逐條做 style 閘門，主對話同時審查架構、正確性、測試與文件一致性。審查範圍是 2.1 至 2.4 的 diff，對照 design 的 Decisions 與 Implementation Contract、spec「View animations are disabled in UI test mode」，以及 ios-dev-kit 的排版、命名與註解規範 (明列：多條件 `guard` 的 `else {` 與最後一個條件同行、註解不加句號、單一表達式 closure 用 `$0`、測試的 Given／When／Then 與字面值預期值、行寬以字元計)。驗證：審查者回報逐檔檢查清單與發現 (無發現也列出已檢查的條目)；審查前後比對 `git status --short` 與檔案雜湊，確認審查者沒有改檔；主對話合併取捨後，需要修改的項目改完再建置一次，結果記進 design「實作與驗證」。

## 4. 驗證

- [x] 4.1 [after: 3.1] (真依賴：以審查後的程式碼驗證) 負責：主對話。確認兩種常駐守門都會在契約被破壞時失敗，且單元測試整體不受影響。驗證：依 Implementation Contract「驗收」的掃描守門變異 (刪除 harness 的接線、接線改成 `!$0`、在 harness 以外的 App 檔加一行 `UIView.setAnimationsEnabled(true)`) 與單元測試變異 (`applyViewAnimationPolicy` 忽略 `shouldKeepViewAnimations`) 逐項暫改，每項只讓「驗收」所列的預期測試失敗，還原後雜湊一致；iPhone 17 iOS 26.5 完整 `BuyLedgerTests` 0 失敗 (既有 3 條預期失敗除外)，snapshot 未重錄；結果記進 design「實作與驗證」。
- [x] 4.2 [after: 4.1] (同一時間只跑一組測試) 負責：主對話。依 design「以同一輪的基準與修正後連跑驗證效果」，在與 1.1 同一台 iPad 模擬器上以修正後的建置跑同一組測試 (轉向 24 次，其餘各 3 次)，證明三類觸發不再讓閒置等待逾時。驗證：每條測試實際執行次數等於指定次數、0 skip、0 失敗；Build Logs 中 `App animations complete notification not received` 為 0 次；轉向測試每次不超過 120 秒，其他測試不超過 10 分鐘上限；與 1.1 的基準並列記進 design「實作與驗證」。修正後仍出現時記錄觸發步驟並回報，不改 helper。
- [x] 4.3 [after: 4.2] (同一時間只跑一組測試) 負責：主對話。依 design「以啟動參數讓呈現競態測試保留動畫」與 Implementation Contract「驗收」的偵測力項目，確認帶保留參數的呈現競態測試仍偵測得到缺陷。驗證：修正後的建置暫時把主檔寫入失敗提示改回與確認框共用 `destination`，在 iPad 模擬器跑 `LookupManagementTests` 的三條刪除寫入失敗測試各 3 次，`testRequestDeletion_寫入失敗提示關閉後再刪除_重新呈現確認框` 至少 1 次失敗；同一變異下再暫時拿掉該測試的 `shouldKeepViewAnimations` 跑 3 次，預期全部通過 (證明執行期確實關閉了動畫)；兩項暫改還原後雜湊一致；結果記進 design「實作與驗證」。
- [x] 4.4 [after: 4.3] (同一時間只跑一組測試) 負責：主對話。確認全部 UI 測試在新條件下行為不變。iPad 先單獨跑 `KeyboardDismissTests` 通過，再於 iPad Air 11-inch (M4) iPadOS 27.0 與 iPhone 17 iOS 26.5 各跑一次完整 UI 回歸 (`-only-testing:BuyLedgerUITests`、`-skip-testing:BuyLedgerUITests/LaunchPerformanceTests`)。驗證：兩台 0 失敗；兩台 Build Logs 中上述訊息的次數與發生的測試照實記錄，未保留動畫的測試應為 0 次；有失敗時先回報，不在本 change 內改 UI 測試 helper；依 4.2 至 4.4 的結果核對規則檔、`apps/ios/CLAUDE.md` 與 README 的文字仍成立；結果與文件同步鐵則的審視結論 (對照 `git status --short` 逐列) 記進 design「實作與驗證」。
