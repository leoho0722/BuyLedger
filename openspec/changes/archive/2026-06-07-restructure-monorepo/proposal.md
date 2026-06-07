## Why

目前 repo 根目錄只有單一 Apple 平台 (iOS/iPadOS/macOS) 的 Xcode 專案，但 BuyLedger 後續規劃擴展 Android、Web 與 Backend，且需要跨平台共享 Data Model。多 repo 管理成本高、Data Model 難以共享，因此在新平台動工前先將 repo 重整為 monorepo 佈局，建立可長期擴展的目錄契約。

## What Changes

- 將現有 Xcode 專案整個資料夾以 git mv 從 BuyLedger/ 搬移至 apps/apple/ (含 BuyLedger.xcodeproj、BuyLedger/ source root、BuyLedgerTests/、BuyLedgerUITests/)，保留 git 歷史可追溯 (rename detection)。
- 確立 monorepo 頂層佈局契約：所有可部署單元收在 apps/ 之下 (apps/apple、未來 apps/android、apps/web、apps/backend)，跨平台共享內容收在 shared/ 之下 (未來 shared/data-model)；openspec/、assets/ 與根目錄文件留在原位。
- 未來平台目錄本次不建立 stub 目錄，僅在 README.md 的專案結構章節文件化保留位置。
- 同步更新所有受路徑搬移影響的引用：README.md (~28 處，含專案結構圖與 xcodebuildmcp 指令的 --project-path 參數)、CLAUDE.md (Design System 路徑與測試路徑共 2 處)、.gitignore (Config.xcconfig 與 GoogleService-Info.plist 共 2 處)、openspec/specs 既有 spec 檔內約 1477 處路徑引用 (批次機械性更新，不涉及需求變更)。
- 搬移後以 xcodebuildmcp 序列化驗證 iOS simulator、iPadOS simulator 與 macOS 三平台 build 通過，並重新設定 xcodebuildmcp session defaults 的專案路徑 (本機狀態，不入版控)。

## Non-Goals

- 不建立 Android、Web、Backend 任何程式碼或專案骨架。
- 不建立 shared/data-model 的實際內容與格式 (protobuf/OpenAPI/JSON Schema 等格式選型留待後續 change)。
- 不調整 Xcode 專案內部結構 (App/Core/Features/Shared/Resources 分層維持不變)、不改 scheme 名稱、不改 bundle identifier。
- 不引入 monorepo 工具鏈 (Nx/Turborepo/Bazel 等)；目前單一專案尚無需求。
- 不新增 CI 設定。

## Capabilities

### New Capabilities

- `monorepo-layout`: 定義 repo 頂層目錄佈局契約——可部署單元一律收在 apps/ 之下、跨平台共享內容收在 shared/ 之下、Apple 平台專案位於 apps/apple，以及文件中路徑引用必須與實際佈局一致的要求。

### Modified Capabilities

(無——既有 spec 僅做路徑字串的機械性更新，無任何需求層級的行為變更。)

## Impact

- Affected specs: 新增 monorepo-layout；既有全部 16 個 capability 的 spec.md 內路徑引用批次更新 (非需求變更，不需 delta spec)。
- Affected code:
  - Moved: BuyLedger/ 整個目錄搬移至 apps/apple/ (含 apps/apple/BuyLedger.xcodeproj、apps/apple/BuyLedger、apps/apple/BuyLedgerTests、apps/apple/BuyLedgerUITests)。
  - Modified: README.md、CLAUDE.md、.gitignore、openspec/specs 之下各 capability 的 spec.md 路徑引用。
  - New: (無新增程式碼；僅 README 專案結構章節新增未來目錄的文件化說明。)
  - Removed: (無。)
- 本機開發環境：xcodebuildmcp session defaults 需重設專案路徑；.spectra/ 本地索引為 gitignored 狀態，搬移後如檢索異常需重建。
- 風險：Xcode 專案使用 file system synchronized groups，整資料夾搬移時專案內部相對路徑不變，風險集中在外部引用遺漏——以三平台 build 驗證與全 repo 路徑 grep 收斂。
