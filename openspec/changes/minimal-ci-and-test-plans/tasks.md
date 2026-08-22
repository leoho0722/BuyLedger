## 1. 產線生成檔的測試級守門

- [x] 1.1 [P] 讓產線生成檔漂移會使 generator 測試變紅：新增一條對產線 schema 與設定執行漂移檢查的斷言，失敗訊息列出每筆漂移的原因與絕對路徑並附重新產生的指令；同時補一條鎖住產線設定輸出路徑的斷言，避免比對標的被改掉而永遠綠燈。對應 spec requirement「Check mode detects drift between schema and committed output」，依 design「產線生成檔納入測試斷言，並鎖住比對標的」。驗證：在 shared/data-model/generator 執行 bun test 全綠（shared/data-model/generator/test/datamodel-gen.test.ts）。
- [x] 1.2 [P] 以負向手法證明守門真的會擋：解鎖生成檔後手改任一 `*.generated.swift` 一個字元，確認新斷言變紅且訊息含漂移原因與該檔絕對路徑，重新產生後恢復全綠；驗證完畢一律還原。驗證：紅綠兩態各觀察一次並記錄訊息內容。

## 2. 測試計畫與覆蓋率

- [x] 2.1 讓主 scheme 的單元測試在固定語言與地區下執行，且覆蓋率只統計 App target：新增主 scheme 測試計畫，設定語言、地區與執行順序，並以物件形式指定 App target 為唯一覆蓋率統計對象。對應 spec requirement「Test plans pin locale and expose coverage」，依 design「主 scheme 改掛測試計畫並鎖定語言與地區」與「覆蓋率只統計 App target，不使用全目標形式」。驗證：對 apps/ios/BuyLedger.xctestplan 搜尋可同時命中語言、地區與指向 App target 的覆蓋率設定。
- [x] 2.2 讓主 scheme 以該計畫為預設測試計畫，不再自動建立：移除自動建立測試計畫設定並改為引用新計畫，保留原有可測試目標區塊以降低結構落差。驗證：對該 scheme 搜尋自動建立設定零命中且命中計畫引用；於 Xcode 開啟後 Test action 顯示該計畫為預設（人工確認）。
- [x] 2.3 讓兩份 UI 測試計畫也能產出覆蓋率，且既有略過與選取測試清單不受影響。驗證：git diff 對兩檔只出現新增行、無修改行（apps/ios/BuyLedgerUITests.xctestplan、apps/ios/BuyLedgerUITests-Performance.xctestplan）。
- [x] 2.4 確認換計畫後既有測試資產未退化：以新計畫執行主 scheme 全部單元測試、以 UI 計畫執行一次主回歸，並自產出的結果套件讀出 App target 覆蓋率數字。驗證：367 個單元測試全綠、UI 主回歸 49 條全綠、覆蓋率百分比可讀出（不設門檻）。

> **實際執行紀錄（BA46C947 iPhone 17／D5681B27 iPad，皆 `-parallel-testing-enabled NO`）**：
> - 主 scheme 單元測試（`BuyLedger.xctestplan`）：382 個全綠（0 failed、0 skipped；基準因其他 change 新增測試已由 367 增至 382，未變差）。覆蓋率 48.5%（14390／29680 行，BuyLedger.app target）。
> - UI 主回歸 iPhone：48 passed、1 failed（`OrderCreateTests.testCreateOrderAppearsInList`，`Waiting.swift:42` hittability，目標 `orderEdit.customerField`）。覆蓋率 64.1%（19012／29680 行）。
> - UI 主回歸 iPad：48 passed、1 failed（`OrderCreateTests.testCreateOrderAppearsInList`，`TextInput.swift:34` 鍵盤焦點，目標 `orderEdit.customerField`）。覆蓋率 64.4%（19115／29680 行）。
> 兩平台唯一失敗皆為同一條已知 flaky 測試（乾淨 HEAD `91e074c` 三重舉證早於本次工作階段的既有缺陷，非本次改動造成），單元測試零失敗且覆蓋率可讀出，判定測試資產未退化，予以勾選。

## 3. 讓乾淨 clone 可建置

- [x] 3.1 讓沒有任何機密的乾淨 clone 也能建置並啟動測試宿主：新增 Firebase 設定範本檔（值一律為明顯佔位字串、不含真實識別碼），並將其加入建置設定的成員例外清單使其不進 App bundle。對應 spec requirement「Continuous integration requires no repository secrets」，依 design「以入庫的設定範本檔補齊被忽略的機密設定」。驗證：本機建置後檢查產物內不存在該範本檔，且工作樹不出現被忽略的正式設定檔（apps/ios/BuyLedger/Resources/GoogleService-Info.example.plist、apps/ios/BuyLedger.xcodeproj/project.pbxproj）。

## 4. CI workflow

- [ ] 4.1 讓資料模型漂移在推送當下就被擋下：新增 workflow 與其 codegen job，於 Linux runner 依序執行相依安裝、漂移檢查、generator 測試與型別檢查，並設定同分支取消舊執行。對應 spec requirement「Repository-level checks are enforced by remote automation」，依 design「守門放在遠端 CI，不做本機 git hook」與「分兩段建立信任：codegen job 先成為必過關卡」。驗證：推一個「改 schema 但不重新產生」的 commit 後該 job 變紅，還原後轉綠（.github/workflows/ci.yml）。
- [x] 4.2 讓單元測試在 CI 上以專案指定的建置 CLI 執行，且模擬器以識別碼動態解析：新增 iOS 單元測試 job，釘選 CLI 版本、先查詢可用模擬器再以識別碼指定、找不到符合執行環境時明確失敗，並在失敗時上傳測試結果套件。對應 spec requirement「Continuous integration uses the project build CLI and resolves simulators dynamically」，依 design「CI 內一律使用專案指定的建置 CLI，不退回原生工具」。驗證：對 workflow 搜尋原生 Xcode 命令列工具零命中；job 日誌顯示以識別碼而非寫死名稱指定模擬器。GitHub Actions run `32562994733` 的 iOS Unit Tests 通過，並成功上傳 test result bundle。
- [ ] 4.3 讓首波 CI 不被已知環境敏感的測試干擾，且讓未涵蓋範圍是明示的：以具名略過方式排除 snapshot 與效能兩個套件。對應 spec requirement「Unstable suites are excluded until continuous integration is trusted」。驗證：workflow 內可見兩條具名略過參數，且刻意讓一個非排除的單元測試失敗時該 job 仍變紅。
- [ ] 4.4 讓需要模擬器的 UI 回歸不拖慢一般推送：UI 回歸 job 僅在手動觸發時執行，且篩選使用僅測試與略過測試旗標而非測試計畫旗標。對應 spec requirement「Simulator-dependent regression stays on manual dispatch」。驗證：對主分支推一次 commit 後，執行清單中不含該 job；手動觸發一次則該 job 執行。

> **目前尚未完成的額外驗收**：4.1 仍需 schema 漂移的紅綠兩態；4.3 仍需非排除單元測試故意失敗；4.4 仍需手動觸發一次 UI 回歸；6.1 仍需完整的兩紅兩綠端到端驗收。這些不是一般成功 CI run 能取代的驗證。
> `4.2` 已由 GitHub Actions run `32562994733` 完成驗收：iOS Unit Tests job 成功使用動態 simulator UUID 執行，並上傳 test result bundle。

## 5. 文件同步

- [x] 5.1 讓根目錄佈局契約涵蓋版本庫層級自動化目錄，並把守門敘述由「提交前自行執行」改為「CI 強制、提交前自查為輔」。對應 spec requirement「Cross-platform content stays at the repository root」。驗證：README 專案結構樹含自動化目錄一列且佈局契約有對應敘述；CLAUDE 的資料模型守門段落已改寫（README.md、CLAUDE.md）。
- [x] 5.2 讓平台文件記錄新的測試與 CI 硬規則：主 scheme 已有預設測試計畫（語系與覆蓋率由計畫決定、CLI 端篩選一律用僅測試與略過測試旗標）、CI 內選擇工具鏈為「絕不退回原生工具」的第二個明文例外、CI 以範本檔補齊被忽略的設定；平台開發指南補測試計畫說明、覆蓋率讀法與範本檔僅供 CI 的註記；跨平台資料模型說明補上測試已含產線同步斷言。驗證：四份文件各自可搜尋到對應新段落（apps/ios/CLAUDE.md、apps/ios/README.md、shared/data-model/README.md）。

- [x] 5.3 記錄 `.xcodebuildmcp/` 本機 session defaults 忽略條目的歸屬：該條目由本變更的 CI 與測試工具工作產生，忽略其機器專屬絕對路徑與模擬器 UDID，避免被誤夾帶入版本庫。驗證：`.gitignore` 含對應條目，且本任務明確記錄其歸屬。

## 6. 整體驗收

- [ ] 6.1 執行端到端守門驗收：於驗證分支各推一次「schema 漂移」與「單元測試故意失敗」的 commit，確認對應 job 分別變紅並在拉取請求上顯示，還原後兩者轉綠；同時確認整條 workflow 在不使用任何 secret 的情況下完成一次綠燈執行。驗證：四次 CI 執行結果（兩紅兩綠）各記錄一次連結與失敗步驟名稱。
