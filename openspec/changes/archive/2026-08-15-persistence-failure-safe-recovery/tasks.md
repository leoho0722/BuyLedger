## 1. 隔離備份型別

- [x] 1.1 [P] 先寫紅燈測試釘住備份契約：`PersistenceRecoveryTests` 涵蓋「搬移後原路徑清空且位元組不變」「已存在 Recovered-1 時落到 Recovered-2」「來源目錄無 store 檔時回傳空值且不建目錄」三條，對應 spec requirement「Store quarantine requires explicit confirmation and moves rather than deletes」。驗證：新增測試在實作前全部失敗（apps/ios/BuyLedgerTests/PersistenceRecoveryTests.swift）。
- [x] 1.2 實作 `PersistenceStoreQuarantine`，使不可開啟的 store 三件套與 legacy store 能被搬進可注入目錄下的隔離子目錄，且全型別不含任何刪除呼叫。依 design「隔離備份型別只搬不刪且目錄可注入」與「隔離備份目錄採遞增索引命名，不用時間戳」。驗證：1.1 三條測試轉綠，且對 apps/ios/BuyLedger/Core/Persistence/ 執行 removeItem 字串搜尋零命中。

## 2. 啟動 bootstrap 不再毀損資料

- [x] 2.1 先寫紅燈測試釘住保留契約：以低於 floor 的實體 store 觸發 bootstrap，斷言 outcome 為 degraded、三件套仍在原路徑且逐 byte 相同、目錄下不存在任何 Recovered 目錄，對應 spec requirement「Persistence bootstrap failure preserves existing store files」。驗證：測試在實作前失敗（apps/ios/BuyLedgerTests/PersistenceRecoveryTests.swift）。
- [x] 2.2 改寫 `PersistenceContainer` 的啟動路徑，使開啟失敗時不刪除或覆寫任何檔案、退到 in-memory 並回報 degraded 結果；同時移除 store 清除函式與其呼叫點。依 design「失敗時預設不動任何檔案，備份降為使用者確認後的逃生門」與「以 bootstrap 值型別傳遞啟動結果，取代可變全域」。驗證：2.1 測試轉綠，且全 repo 對清除函式名稱搜尋零命中。
- [x] 2.3 收斂為每個 process 只解析一次的共用 container，並讓訂單 repository 改用共用 container 而非自行呼叫工廠，對應 spec requirement「A single production container is resolved once per process」。驗證：新增測試斷言兩次取用為同一實例，且全 repo 對工廠方法的外部呼叫點零命中（apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift）。

## 3. 失敗診斷可觀測

- [x] 3.1 讓啟動失敗在 release build 留下可讀診斷：持久層改以 unified logging 的 fault 等級輸出且錯誤描述標記為公開，並新增可注入的當機診斷 client，由啟動設定流程在 crash reporting 設定完成後才上報。依 design「診斷改 OSLog fault，當機診斷延後到 Firebase 設定完成後上報」，對應 spec requirement「Persistence bootstrap failure is recorded as a fault-level diagnostic」。驗證：對 apps/ios/BuyLedger/Core/Persistence/ 執行 print 搜尋零命中、全 repo 對 swiftlint 搜尋零命中，且診斷上報位於 UI 測試提前返回之後（人工檢視 apps/ios/BuyLedger/App/AppLaunchConfigurator.swift）。

## 4. 啟動失敗畫面與逃生門

- [x] 4.1 先寫紅燈測試釘住逃生門流程：以 TestStore 覆蓋「點擊只開確認 alert、不動檔案」「確認後才呼叫備份並切到待重啟階段」「備份拋錯時停留阻斷並更新原因」三條。驗證：測試在實作前失敗（apps/ios/BuyLedgerTests/PersistenceFailureFeatureTests.swift）。
- [x] 4.2 實作 `PersistenceFailureFeature` 與 `PersistenceFailureView`，使 degraded 時呈現全畫面阻斷、說明資料仍完整保留且請勿輸入，並提供需二次確認的復原動作。依 design「degraded 時全畫面阻斷，不做逐路徑停用」，對應 spec requirement「Degraded launch blocks the normal interface」與「Total data-layer failure is surfaced at launch rather than silently absorbed」。驗證：4.1 三條測試轉綠。
- [x] 4.3 讓 degraded 結果在首次渲染前就決定，並在根版面只渲染失敗畫面、不渲染分頁列與側邊欄；補上失敗畫面的 accessibility identifier 與中英文案。驗證：新增 `RootFeatureTests` 斷言失敗子 state 非空時不渲染正常版面、預設為空時不誤擋；英文模式人工確認無中文 fallback（apps/ios/BuyLedger/Features/App/RootView.swift、apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift）。

## 5. Release 產物與過期敘述

- [x] 5.1 [P] 讓示範訂單資料不再進入 release binary，同時保持既有 Preview 與 preview dependency 呼叫點一行不改。依 design「示範資料以 #if DEBUG 排除，#else 提供同名空集合」。驗證：以 Release configuration build 成功，且 Debug 下訂單、總覽、開團三個 Preview 仍顯示示範資料（人工開 Preview 確認）。
- [x] 5.2 [P] 把三處與現況矛盾的敘述改寫為誠實描述：CloudKit 啟用前置作業明列並記為已接受技術債、「尚未上架」與清除策略敘述改為保留式策略，平台指引與 schema 定義檔一併同步。依 design「CloudKit 預留明文轉為已接受技術債」，對應 spec requirement「Removing pre-floor schema versions is a one-way operation」的新結局。驗證：全 repo 對「尚未上架」與清除策略字樣搜尋零命中，含 apps/ios/CLAUDE.md 與 apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift。
- [x] 5.3 [P] 讓新增字串具備英文對照並鎖住失敗畫面外觀：擴充本地化目錄測試的必備字串清單，並新增失敗畫面的 snapshot baseline。驗證：本地化目錄測試綠、snapshot 測試綠（apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift、apps/ios/BuyLedgerTests/SnapshotTests.swift）。
- [x] 5.4 [P] 修正遷移測試檔頭與現況矛盾的註解，使其指向新的復原測試而非已移除的清除 fallback。驗證：人工檢視 apps/ios/BuyLedgerTests/SchemaMigrationTests.swift 檔頭不再描述清除行為。

## 6. 整體驗收

- [x] 6.1 執行靜態驗收掃描：清除函式名稱、swiftlint、持久層 print、「尚未上架」四項字串零命中，且持久層目錄無檔案刪除呼叫。**掃描範圍為 `apps/ios` 的原始碼與現行文件**，明確排除 `openspec/`：本 change 自身的 proposal／design／tasks 必須指名被移除的符號才講得清楚，而 `openspec/changes/archive/` 是不可變的歷史記錄，兩者都不得為了通過掃描而竄改。驗證：四次字串搜尋在上述範圍各回傳零結果。
- [x] 6.2 執行完整建置與測試驗收：主 scheme 單元測試全綠、Release configuration build 成功、iPhone 與 iPad simulator build 各一次（序列執行，build 前先遞增 build number）、UI 主回歸 49 條全綠。驗證：各指令退出碼為 0 並記錄結果。

  **實測結果**：主 scheme 單元測試 382 passed / 0 failed；Release configuration build 成功；iPhone 與 iPad simulator build 各成功一次（build number → 207）；iPhone UI 主回歸 49/49 全綠。

  **iPad UI 主回歸 48/49，且該筆失敗經證實早於本 change**：`OrderCreateTests.testCreateOrderAppearsInList` 失敗於 `BuyLedgerUITests/Support/TextInput.swift:34`，訊息為 `Failed to synthesize event: Neither element nor any descendant has keyboard focus`，目標為 `orderEdit.customerField`。以 detached worktree 檢出未含本 change 任何變更的 HEAD（`91e074c`）後單獨重跑同一條測試，出現**逐字相同**的失敗（同檔名、同行號、同訊息、同 identifier），故非本 change 造成的回歸。成因指向 iPad 模擬器因 CoreSimulator 損毀而被 erase 後的鍵盤焦點環境狀態，屬共用 UI 測試基礎設施議題，已超出本 change 於 design 所載的範圍邊界（持久層啟動路徑、失敗 UI 與其 reducer、隔離備份型別、診斷、示範資料建置組態、過期敘述），另案處理。
