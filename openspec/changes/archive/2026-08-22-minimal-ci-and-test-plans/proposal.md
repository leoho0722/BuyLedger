## Why

專案已累積可觀的測試資產：367 個單元測試、49 個 UI 測試、8 張 snapshot baseline，以及 shared/data-model 的 40 個 golden-file 測試。但 repo 根目錄沒有 CI 設定、沒有 git hook，170 個 commit 中沒有一個屬於 ci 類型。所有守門都靠人記得手動執行。

其中最脆弱的是 schema 與生成檔的同步：跨平台 data model 宣稱「schema 是唯一來源」，實際上唯一有牙齒的漂移偵測只是一個手動 script，沒有任何觸發點；生成檔的唯讀鎖只是本機工作副本的防線（git 不追蹤 write bit，clone 後即恢復可寫）。改了 schema 忘記重新產生、或解鎖後手改生成檔，都能安靜地進入版本庫。更甚者，測試本身只驗證 fixtures 目錄，從不檢查產線輸出目錄是否同步。

同時主 scheme 沒有測試計畫，語言與地區完全跟隨模擬器系統狀態，而兩張含日期膠囊的 snapshot baseline 正好對此敏感，等於已知的 false-fail 變因沒有被鎖住。兩份 UI 測試計畫也未啟用覆蓋率，導致「哪些檔案完全沒被執行到」只能靠逐檔搜尋才會浮現。

## What Changes

- 新增 CI workflow：codegen job 在 Linux runner 上執行相依安裝、漂移檢查、generator 測試與型別檢查；iOS 單元測試 job 在 macOS runner 上以專案指定的建置 CLI 執行主 scheme 測試。repo 為公開專案，macOS runner 不計費。
- iOS 單元測試 job 首波排除 snapshot 測試與效能測試，待連續穩定後再收回；UI 測試僅在手動觸發時執行，因其需要模擬器且回歸時間長。
- 新增主 scheme 的測試計畫，鎖定語言與地區，取代目前的自動建立測試計畫設定，並把 App target 設為唯一覆蓋率統計對象。
- 兩份既有 UI 測試計畫補上覆蓋率設定，既有的略過與選取測試清單一律不動。
- generator 測試新增一條「產線生成檔與 schema 同步」的斷言，讓產線輸出漂移會讓測試變紅，而不是只有人工執行檢查才抓得到；並補一條鎖住比對標的的斷言，避免有人改設定讓前一條失去對象。
- 新增 Firebase 設定範本檔並排除出 App bundle，讓乾淨 clone 在缺少被忽略的機密設定時仍能建置測試宿主 App。單元測試掛在 App 上，缺少該設定會讓宿主啟動即崩、整組測試在 CI 全紅，這是必須先解掉的前置。
- 同步文件：把「提交前自行執行檢查」的敘述改為「CI 強制、提交前自查為輔」，並記錄新的測試計畫、CI 例外規則與範本檔用途。

## Capabilities

### New Capabilities

- `ci-guardrails`: 版本庫層級的自動守門契約，涵蓋哪些檢查必須由機器在推送時強制執行、哪些刻意維持手動觸發、CI 如何在不引入機密管理的前提下取得建置所需設定，以及 CI 內的工具鏈使用限制。

### Modified Capabilities

- `data-model-codegen`: 漂移偵測從「僅提供手動指令」提升為「由測試與 CI 強制」，且檢查對象自 fixtures 擴及產線輸出目錄。
- `monorepo-layout`: 版本庫層級的自動化設定目錄納入根目錄佈局契約。

## Impact

- Affected specs: `ci-guardrails`（新增）、`data-model-codegen`（修改）、`monorepo-layout`（修改）
- Affected code:
  - New:
    - .github/workflows/ci.yml
    - apps/ios/BuyLedger.xctestplan
    - apps/ios/BuyLedger/Resources/GoogleService-Info.example.plist
  - Modified:
    - apps/ios/BuyLedger.xcodeproj/xcshareddata/xcschemes/BuyLedger.xcscheme
    - apps/ios/BuyLedger.xcodeproj/project.pbxproj
    - apps/ios/BuyLedgerUITests.xctestplan
    - apps/ios/BuyLedgerUITests-Performance.xctestplan
    - shared/data-model/generator/test/datamodel-gen.test.ts
    - README.md
    - CLAUDE.md
    - apps/ios/CLAUDE.md
    - apps/ios/README.md
    - shared/data-model/README.md
  - Removed: （無）
- 不改動任何 App production 程式碼與 SwiftData schema；Release 產物與現行版本逐檔等價（新增的範本檔已排除出 target）。
- 不設覆蓋率門檻；覆蓋率僅作為盤點盲區的資料來源。
