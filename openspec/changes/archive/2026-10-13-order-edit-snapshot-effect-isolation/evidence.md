# 實作與驗證證據

## 環境與範圍

- Change：`order-edit-snapshot-effect-isolation`；schema：`no-spec`
- 模擬器：iPhone 17，iOS 26.5，`DDAA3311-B464-4DD3-96B8-360B26AF1929`；執行前透過 MobileBuildMCP 確認裝置並設定淺色外觀
- Scheme：`BuyLedger`；專案：`apps/ios/BuyLedger.xcodeproj`
- 共用時間相依、正式 reducer、View、Service `testValue` 與 baseline 均不在實作範圍

## 1.1 來源追查

- `OrderEditView.body` 的 `.task` 送 `.view(.task)` 並等待 `finish()`
- `OrderEditFeature.core` 把畫面事件交給 `OrderEditOperations.apply`；其 `.task` 只在新訂單且沒有焦點時設定 `.customerName`，其餘回傳 `.none`。三條 snapshot 都是既有訂單
- `OrderEditPhotosSection.body` 有另一個 `.task`，只送出照片子 Feature 的 `.view(.task)`，不等待 `finish()`；來源註解說明照片區段可能因惰性 Form 或推入選擇器消失，載入不隨區段取消
- `OrderEditPhotosFeature.core` 只在 `orderID` 存在且 `photoLoadPhase == .notLoaded` 時呼叫 `loadPhotos`；該方法先擷取 `orderService`，在 `.run` 裡讀取 `fetchOrderPhotos`，再送 `photosLoadResponse`
- 三條 snapshot 都已把照片標為 `.loaded`，因此上述兩種事件在這組初始 State 下都不應啟動效果，也不需要讀取 Service
- 搜尋 `OrderEdit*.swift`，沒有原 design 所列的六個主檔 Service 或 fetch closure；原本的修正前提已失效。現行選項從 `OrderEditOptions` 在初始化時帶入
- `OrderService.testValue.fetchOrderPhotos` 仍使用 `unimplemented("OrderService.fetchOrderPhotos", placeholder: [])`，適合驗證漏掉照片隔離設定時會立即失敗

## 歷史結果 (不作為本次通過證據)

- 2026-10-06 `progress-title-render-reliability` task 1.1 的實測：五輪中長識別碼 4 輪、合併訂單 2 輪記錄主檔 Service Unimplemented
- 2026-10-06T12:54Z 的一般既有訂單 snapshot 日誌另有六種主檔 Unimplemented 與 No test reporter，xcresult 摘要未完整反映這些 issue；原始 bundle／log 路徑保留於 design 的 Context
- 本次結果另外記錄，不把偶發問題未重現或成功退出碼當成根因證據

## 執行命令

以下命令以 repo 根目錄執行；每次的 bundle 與 log 路徑在結果表逐項記錄。

```sh
mobilebuildmcp simulator-management set-appearance --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 --mode light
mobilebuildmcp --log-level error simulator test --project-path apps/ios/BuyLedger.xcodeproj --scheme BuyLedger --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929 --extra-args '-only-testing:BuyLedgerTests/SnapshotTests'
```

## 本次執行結果

### 修改前整批 (task 1.1)

- 實際執行 38 條：34 通過、4 圖片不符、0 跳過；xcresult 和完整 build/test 日誌均無 Unimplemented 或 No test reporter
- 圖片不符：`campaignEditView_編輯既有開團_符合基準圖()`、`orderEditView_一般既有訂單_符合基準圖()`、`orderEditView_合併訂單情境_符合基準圖()`、`orderEditView_長訂單識別碼_顯示短識別碼()`；這些均發生於 Swift 修改前，差異判讀另記錄
- Bundle：`/Users/leoho/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-12T14-41-28-856Z_pid51069_d5d6bb19.xcresult`
- Log：`/Users/leoho/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/logs/test_sim_2026-10-12T14-41-28-855Z_pid51069_c4707a2f.log`
- 數量與 issue 來源：唯讀 `xcrun xcresulttool get test-results summary --path <bundle>`；日誌以 `Unimplemented:|No test reporter` 搜尋，無 issue 命中 (`Unimplemented.swift` 等相依套件編譯檔名不計為 issue)
- 結論：現行來源顯示六種主檔載入已移除，本次未重現歷史 issue；隔離是否受測試保護仍需 task 1.2 的明確事件與變異證據

### 受控事件測試初次通過 (task 1.2)

- 篩選 `SnapshotTests/task_訂單編輯快照出現_不啟動服務(shouldRepeatTask:)` 與 `SnapshotTests/photos_訂單編輯快照照片區段出現_不啟動服務(shouldRepeatTask:)`；各以 `false`／`true` 涵蓋首次與再次出現
- xcresult：`totalTestCount = 2`、`passedTests = 2`、`failedTests = 0`；statistics 記錄 4 個參數案例。窮舉 TestStore 的 send 無狀態變更，finish 完成，State 與 Given 輸入相同，照片維持 `.loaded`
- Bundle：`/Users/leoho/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-12T14-46-50-991Z_pid57110_1e6ad702.xcresult`
- Log：`/Users/leoho/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/logs/test_sim_2026-10-12T14-46-50-991Z_pid57110_932eef61.log`；Unimplemented issue／No test reporter 均 0

### 移除已載入設定的變異 (task 1.2)

- 暫移除共用 `makeOrderEditSnapshotState` 的 `state.photos.photoLoadPhase = .loaded`，只執行照片區段受控方法；完成後立即還原
- xcresult：`totalTestCount = 1`、`failedTests = 1`，statistics 記錄 2 個參數案例。日誌 2 次 `Unimplemented: OrderService.fetchOrderPhotos`，另有 `.notLoaded → .loading` 未預期狀態差異與未接收的照片回應
- xcresult 的 testFailures 只列首個狀態差異，topInsights 另列 Unimplemented；確認日誌仍不可省略
- Bundle：`/Users/leoho/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-12T14-47-54-674Z_pid58072_dc549893.xcresult`
- Log：`/Users/leoho/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/logs/test_sim_2026-10-12T14-47-54-674Z_pid58072_afa7adf5.log`
- 結論：新增測試確定觸發真實照片載入路徑，漏掉已載入設定會立即失敗；不是依靠 key window 是否碰巧觸發 `.task`

### 修改前圖片差異判讀

使用 Pillow 的 `ImageChops.difference` 比較原始 baseline 與修改前 actual，尺寸均為 1179×2556，並目視左右並排圖片。四條失敗均為日期與時間欄位由同行改為上下排列，帶動後續區段下移，不能列為已知導覽列像素雜訊。

左右並排圖 (左為 baseline，右為修改前 actual)：[訂單編輯](reference/order-date-layout-before-change.png)、[開團編輯](reference/campaign-date-layout-before-change.png)。圖片縮小僅供檢視；下表量測使用原尺寸。

| 方法 | 差異 bbox | 最大單通道差值 |
| --- | --- | --- |
| 開團編輯 | (48, 1199, 1131, 1818) | 255 |
| 訂單編輯一般／合併／長識別碼 (各自量測相同結果) | (48, 811, 1131, 2556) | 255 |

本 change 不修改開團畫面、DatePicker 或 baseline；保留這些修改前已存在的失敗，方法層與最終回歸會再次記錄是否重現。

### 還原後受控測試與三條方法層 snapshot

- 同次篩選兩個受控方法及三條既有 snapshot，各方法完整帶 `()` 或參數標籤 `(shouldRepeatTask:)`
- xcresult：`totalTestCount = 5`、`passedTests = 2`、`failedTests = 3`、0 跳過；受控方法的 4 個參數案例皆通過，三條 snapshot 都確實執行且因上述日期排列差異失敗。沒有 Unimplemented issue 或 No test reporter
- Bundle：`/Users/leoho/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-12T14-48-37-935Z_pid58714_dd1bbc19.xcresult`
- Log：`/Users/leoho/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/logs/test_sim_2026-10-12T14-48-37-935Z_pid58714_2ee91172.log`
- 各自計算 `abs(baseline - actual)`：修改前與還原後三條 snapshot 的差異圖逐像素完全相同，`ImageChops.difference(beforeDifference, afterDifference).getbbox()` 皆為 `None`；未新增圖片差異。先前 actual 的 simulator 暫存目錄會隨 test host 重裝被刪除，此處比較的是已於修改前保存的差異圖，不宣稱直接比對兩份 original actual
- 原 task 1.2 的「三條方法層通過」要求曾因此暫停。使用者已明確確認改採「無新增差異、既有失敗另案處理」，proposal／design／tasks 已透過 spectra-ingest 同步；上述結果符合更新後驗收，圖片方法本身仍記錄為失敗

## 文件與風格檢查

- 文件同步結論：確認無文件影響。未改技術棧、設定、架構、build/test 指令或既有描述；共用測試設定與窮舉 TestStore 沿用既有規範，未形成新的硬規則或測試 gotcha，因此不改 `.claude/rules/ios-unit-tests.md`
- 整檔 style 檢查命令：`python3 openspec/changes/archive/2026-10-10-order-edit-style-compliance/reference/style_checks.py apps/ios/BuyLedgerTests/SnapshotTests+OrderEdit.swift`；實際輸出 `TOTAL {} files 1 PASS`
- ios-dev-kit 自檢：Swift Testing、Given／When／Then、窮舉 TestStore、固定時間／ID／行事曆、私有 helper 與既有 MARK 分區、doc comment、行寬與 import 均符合；變異已還原，無 sleep／輪詢／寬鬆 Service 替身或忽略 issue
- `spectra analyze order-edit-snapshot-effect-isolation --json` 無 findings；`spectra validate order-edit-snapshot-effect-isolation` 通過 (`no-spec` 不含 delta specs 的警告為預期)
- `git status --short apps/ios/BuyLedgerTests/__Snapshots__` 無輸出，基準圖無變更

## 最終整批結果

完整命令、每輪完整 bundle／log 路徑及 xcresult summary 保存在 [verification-results.json](verification-results.json)。所有日誌與 summary 皆另外搜尋 `Unimplemented:|No test reporter`；原始命中與分類保留於 JSON。下表 issue 欄只計未預期的訂單編輯載入 issue 與 No test reporter，完整回歸的兩個刻意預期 issue 另列於下方。

| 執行 | totalTestCount | 通過 | 失敗 | 未預期載入 issue |
| --- | --- | --- | --- | --- |
| snapshot-round-1 | 40 | 36 | 4 | 0 |
| snapshot-round-2 | 40 | 36 | 4 | 0 |
| snapshot-round-3 | 40 | 36 | 4 | 0 |
| snapshot-round-4 | 40 | 36 | 4 | 0 |
| snapshot-round-5 | 40 | 36 | 4 | 0 |

五輪各有 40 個測試方法 (新增的 2 個方法合計 4 個參數案例)，每輪皆只有修改前已存在的四條日期排列圖片失敗，未增加新失敗。整批仍為失敗；依使用者已確認並同步至 design 的驗收，這四條既有失敗另案處理。新增受控測試通過、三條訂單圖片無新增差異、五輪無新增失敗及未預期載入 issue，符合本 change 更新後的驗收。

### 完整單元回歸

- `totalTestCount = 1403`、`passedTests = 1397`、`failedTests = 4`、`expectedFailures = 2`、`skippedTests = 0`；statistics 另記錄參數案例，未以 CLI 的成功退出碼當通過證據
- Bundle：`/Users/leoho/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-12T14-53-46-211Z_pid63105_3a6fcf84.xcresult`
- Log：`/Users/leoho/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/logs/test_sim_2026-10-12T14-53-46-211Z_pid63105_aa18b060.log`
- 失敗仍只有修改前相同的四條日期排列圖片失敗，沒有新失敗。所有新增受控事件案例通過，沒有 `OrderService.fetchOrderPhotos` 或六種歷史主檔載入 issue，沒有 No test reporter
- 日誌兩個 Unimplemented 分別是 `OrderService.fetchOrders` 與 `OrderService.removeOrder`，均位於既有 `ServiceTestValueStrictnessTests` 並明列 recorded a known issue；來源使用 `withKnownIssue` 比對這兩種 closure，xcresult 記錄 2 expectedFailures。這是刻意驗證 Service 預設值保持嚴格的預期結果，與訂單編輯 snapshot 外溢無關，不能當成新回歸，也不能宣稱完整日誌完全沒有 Unimplemented
- 執行器在看到原始 Unimplemented 命中後退出非零；人工對照上述來源、known issue 邊界與 xcresult 完成分類，無需重跑測試

## 目前任務狀態

使用者已確認將圖片驗收改為無新增差異，四條既有日期排列失敗保留並另案處理；Spectra artifacts 已同步並通過 analyze／validate。所有 source／test 變異均已還原，實際已驗證的 Swift 檔 SHA256 為 `a81c3667c81375f440ab82b9258aaeb83f8aa2b54851e3484df341bc14e12181`，本次只有 artifact／證據更新，重用相同程式與環境的有效測試結果。Task 1.1、1.2、2.1、2.2 均依更新後驗收完成，tasks.md 為 4／4；最後 analyze 無 findings、validate 通過，git diff --check 無輸出，基準圖仍無變更。

本 change 為 no-spec，沒有 delta spec Scenario／Example，無待補的 spec 情境測試；新增事件行為由兩個參數化 TestStore 方法的四個案例及照片設定變異覆蓋。
