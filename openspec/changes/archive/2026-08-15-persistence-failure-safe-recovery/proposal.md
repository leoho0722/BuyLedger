## Why

`PersistenceContainer.makeForApp()` 在 `ModelContainer` 初始化失敗時會直接刪除 Application Support 內的 `BuyLedger.store` 與其 `-wal`／`-shm`，重建一個空 store；唯一的告知手段是兩行 `print`，release build 讀不到。使用者會在某次啟動後發現整本帳消失，且沒有任何提示、備份或回復途徑。

程式碼註解把這個策略定位為「開發階段 App 尚未上架」的救援手段，但 `MARKETING_VERSION` 已是 1.7.0 且有正式發版 tag，前提早已失效。這條路徑把「一次 migration 寫錯」放大成「使用者資料全滅且無感」，是全專案唯一不可逆的靜默損失路徑，必須排在所有重構之前處理。

## What Changes

- **BREAKING（失敗路徑行為）**：初始化失敗時不再刪除或覆寫任何 store 檔。改為原地保留、退到 in-memory container 並把啟動結果標記為 degraded。
- 新增全畫面啟動失敗畫面：明示「資料無法開啟、原始資料仍完整保留在裝置上」，degraded 時不渲染分頁列與側邊欄，避免使用者在 in-memory 容器上輸入將於下次啟動蒸發的資料。
- 新增需二次確認的逃生門「改用空白資料庫繼續」：確認後才把 store 三件套搬移（非刪除）到 Application Support 的 `Recovered-<n>` 隔離目錄，完成後提示關閉 App 重開。
- `PersistenceContainer.shared` 背後改為單一 `bootstrap` 值型別（container 加 outcome），`makeForApp()` 降為 private，修掉訂單 repository 內唯一違反「所有 repository 共用 shared container」的工廠呼叫點。
- 診斷輸出由 `print` 改為 OSLog fault（錯誤描述標記為 public，否則系統日誌只剩遮蔽字樣），並新增當機診斷 client 抽象，在 Firebase 完成設定後才上報，避免早於 `FirebaseApp.configure()` 呼叫而崩潰。
- 移除失效的 SwiftLint 抑制指令（全 repo 無 SwiftLint 設定與 build phase），並把 in-memory 兜底的 `try!` 改為 do/catch。
- 示範訂單資料以 `#if DEBUG` 排除出 release binary，`#else` 提供同名空集合讓既有 Preview 與 preview dependency 呼叫點一行不改。
- 修正三處已與現況矛盾的敘述：CloudKit「換一行就能開」的宣稱改為明列前置作業並列為已接受技術債；「App 尚未上架」與「清除舊 store 後重建」改寫為新的保留式策略。

## Capabilities

### New Capabilities

- `persistence-failure-recovery`: 持久層啟動失敗時的處置契約，涵蓋「不得刪除既有資料」「以全畫面阻斷誠實告知」「隔離備份須經使用者確認且為搬移」「失敗須留下可追查的診斷」四項。

### Modified Capabilities

- `schema-migration-plan`: 低於 floor 版本或遷移失敗的 store，結局由「清除後重建」改為「原地保留並明示」。
- `honest-state-feedback`: 載入失敗的誠實回饋要求延伸到啟動層級，涵蓋資料層完全無法開啟的情境。

## Impact

- Affected specs: `persistence-failure-recovery`（新增）、`schema-migration-plan`（修改）、`honest-state-feedback`（修改）
- Affected code:
  - New:
    - apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantine.swift
    - apps/ios/BuyLedger/Core/Dependencies/CrashDiagnosticsClient.swift
    - apps/ios/BuyLedger/Features/App/PersistenceFailureFeature.swift
    - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
    - apps/ios/BuyLedgerTests/PersistenceRecoveryTests.swift
    - apps/ios/BuyLedgerTests/PersistenceFailureFeatureTests.swift
  - Modified:
    - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
    - apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
    - apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift
    - apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
    - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
    - apps/ios/BuyLedger/App/BuyLedgerApp.swift
    - apps/ios/BuyLedger/Features/App/RootFeature.swift
    - apps/ios/BuyLedger/Features/App/RootView.swift
    - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings
    - apps/ios/BuyLedgerTests/RootFeatureTests.swift
    - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
    - apps/ios/BuyLedgerTests/SnapshotTests.swift
    - apps/ios/BuyLedgerTests/SchemaMigrationTests.swift
    - apps/ios/CLAUDE.md
  - Removed: （無檔案刪除；移除的是 PersistenceContainer 內的 store 清除函式與其呼叫點）
- 不影響 SwiftData schema：target 維持 V16、floor 維持 V15、遷移階段一行不動，正常開啟路徑的既有使用者資料零影響。
- 相依：本 change 是 schema-v17-storage-cleanup 與 lookup-single-source-of-truth 的硬前置，必須先落地。
