## Summary

把 iOS App 的依賴層對齊 ios-dev-kit 2.0.0 的 Service／Client／Store／Database 分層。範圍有三件事：

- SwiftData 持久化收成單一、只提供技術操作的 `BuyLedgerDatabase`，每次讀寫都用一次性 context，從結構上消除「存檔失敗後殘留的變更被下一次寫入帶落盤」這個已實測成立的資料損毀缺陷。
- Feature 直接取用的依賴一律改成符合 2.0.0 Service 規則的 `XxxService`。
- `HTTPClient` 改成真正的 Client，設定與偏好讀寫拆成技術性 Store。

被這些調整改到的既有檔案，寫法與排版不符合 ios-dev-kit 的部分也整檔一併修正 (使用者 2026-09-25 追加)；拆檔、Action 分組這類結構性重構仍留給第 5 至 8 步。

這是 ios-dev-kit 修正順序計劃的第 4.5 步：使用者 2026-09-25 插入，排在第 5 步 Campaigns 之前；前四步已結案。

## Motivation

使用者 2026-09-25 把 ios-dev-kit 升到 2.0.0，依賴規則大幅改寫。

**2026-09-25 實測現況**

| 項目 | 現況 | 2.0.0 要求 |
|---|---|---|
| 依賴型別 | 19 個 `DependencyKey`，其中 8 個叫 `XxxRepository`、9 個叫 `XxxClient` | 鐵則 6 禁止 Repository 層；Feature 直接取用的依賴叫 `<Name>Service` |
| 取用方式 | 型別下標 274 處、分布在 36 檔 (production 59、測試 215) | 一律用 `DependencyValues` 屬性 |
| closure typealias | 0 個 | 每個 closure 屬性都要有 |
| `testValue` | 按依賴型別計：11 個是空實作 (回 `[]` 或 no-op)、5 個回正常值、3 個丟自訂錯誤，合計 19；`unimplemented` 0 處 | Service 每個 closure 都是 `unimplemented`；Client／Store／Database 不宣告 |
| `liveValue` | 全部是 `static let`，8 個用 `PersistenceContainer.shared` | computed `static var`，liveValue 內禁止 `.shared` |
| 持久化型別 | 6 個 `@ModelActor` (共 1,404 行、48 個方法)，方法名稱全帶業務名詞 | Database 只提供技術操作，業務邏輯在 Service |
| 分層依賴 | `ExchangeRateClient`／`OllamaClient` 簽章帶業務名詞，且依賴 `HTTPClient` | Client／Store／Database 不互相依賴；簽章帶業務名詞的就是 Service |

**必須在第 5 步之前處理的理由**

1. **長命 context 殘留會寫壞資料 (實測成立的缺陷)**：2026-09-25 以可恢復的 save 失敗注入 (驗證錯誤 `NSCocoaErrorDomain 1590`) 逐條實測 `OrderPersistence` 的長命 context 寫入路徑。
   - 失敗並 `rollback()` 後，SwiftData 的 model 實例仍留著改過的值或刪除標記；之後對**同一筆**的寫入會把殘留落盤。
   - 實測結果：刪除失敗後再刪一次，回報成功但資料仍在；刪除失敗後以同 id 建立或更新，store 出現兩筆同 id，撞號檢查也沒擋下；編輯失敗後改同一筆的開團名稱，失敗那次的備註、付款方式、金額被寫進資料庫。
   - `OrdersFeature` 採「先寫後改」，失敗只跳 alert 不重讀，使用者依正常操作就會走到這些路徑。
2. **一次改完、不局部混用** (使用者 2026-09-25 裁決)：第 5 至 8 步都會改 Feature 的依賴取用與測試覆寫。先改依賴，同一批檔案才不必改兩次，也不會有兩種寫法並存。
3. **空實作的 `testValue` 讓測試測不出漏接依賴**：測試漏覆寫時會靜默拿到空陣列或 no-op。靜態掃描估計約 34 個測試依賴這種兜底 (推論值，以本 change 改完後的完整單元回歸實際轉紅數為準)。
4. **既有的其他風險一併消失**：Campaign／主檔／付款方式的 upsert 每次都建新 actor，沒有跨呼叫串行化，並發同名新增可能插入兩筆 (依程式結構推論，未實測)。另外長命 context 在其他 context 改寫 `OrderRecord` 後可能讀到舊值，`.claude/rules/ios-data-layer.md` 已登記待評估。

## Proposed Solution

依使用者 2026-09-25 的四輪裁決執行。

**Database 層 (2.0.0 三塊中的第 1 塊)**

- 新增 `BuyLedgerDatabase` (protocol 加 actor)，只提供三種技術操作：
  - `read`、`write`：把 context 交給呼叫端傳入的同步 closure 執行。每次呼叫都建立一次性 `ModelContext`；`write` 只 save 一次，失敗就整個丟棄。
  - `quarantineStore`：store 檔案隔離，取代 `PersistenceStoreQuarantineClient`。
- 6 個 `@ModelActor` 持久化型別、`OrderRepository.PersistenceInstanceProvider`、`performWithRollback`／`rollbackPendingOrderRecords`、`NameLookupOperations` 全部移除，業務邏輯移到各 Service。
- `PersistenceContainer.shared` 移除；production container 只由 Database 的 `liveValue` 從既有的單次啟動解析取得。
- Preview 改用單一個已 seed 範例資料的 in-memory Database，不再是 8 個互不相通的空容器。

**Feature 只看得到 Service (第 2 塊)**

- 8 個 Repository 與 5 個系統功能 Client 改名為 `XxxService`。
- `ExchangeRateClient`、`OllamaClient` 改成 Service (`ExchangeRateService`、`AISummaryService`)；`SettingsStore` 改成 `SettingsService`。
- 每個 Service 依 2.0.0 拆成主檔、`+Dependency`、`+Preview` 三檔：
  - 每個 closure 都有 typealias。
  - `testValue` 全部 `unimplemented`。
  - `liveValue` 改為 computed，以 `@Dependency` 取得 Database／Client／Store。
  - `previewValue` 整檔包在 `#if DEBUG` 內，並 assert 只在 Preview 或測試中使用。
- `HTTPClient` 改成 protocol 加 struct 的 Client。新增兩個技術性 Store：`UserDefaultsStore` 讀寫偏好、`AppConfigurationStore` 讀 Info.plist 設定。三者都以 `enum XxxKey` 註冊、不宣告 `testValue`，測試改用測試 target 的 Mock。
- 全部取用改成 `DependencyValues` 屬性 (`@Dependency(\.orderService) private var orderService`，維持專案「屬性包裝器與宣告同行」的規則)。
- 刪除 8 個沒有 production 呼叫端的 closure：
  - 主檔改名 4 個：`renameCategory`、`renameOrderSource`、`renamePaymentMethod`、`renameReconciliationStatus`
  - 其他 4 個：`fetchPaymentMethods`、`setPaymentMethodIsCardless`、`forceRefresh`、`reminderExists`
  - 只剩這些 closure 使用的持久層方法一併刪除。

**Service 的位置 (第 3 塊的過渡安排)**

- 只有一個 Feature 使用的 Service 這次直接放進該 Feature 的 `Data/`：AISummary、Settings、App (生物辨識、資料庫復原)、Campaigns (行事曆提醒、開團提醒連結、開啟設定)、Orders (照片匯入)。
- 跨 Feature 共用的 Service 暫留 `Core/Dependencies/`，登記為過渡例外：訂單、開團、四種主檔排第 5 至 8 步；匯率與幣別清單排第 10 步。

**被改到的既有檔案一併修正寫法與排版 (使用者 2026-09-25 追加)**

- 本 change 改到的每個既有 Swift 檔，都整檔修正寫法與排版類違規，包括：
  - 檔頭、import 排序
  - `///` 與 `- Parameter`／`- Returns`／`- Throws`，註解句號、破折號與全形括號
  - MARK 分區的名稱、順序、重複與內容
  - 行寬、尾隨空白、空行 (含 switch case 空行)
  - 宣告大括號換行、closure 寫法、屬性包裝器同行、存取控制
  - 測試的 `///`、Given／When／Then、`receive` 用 case key path、`$0` 慣例與失敗替身寫法
- 2026-09-25 以第 4 步的檢查腳本整檔掃描實測：21 個 production 檔 389 筆、26 個測試檔 567 筆 (不含行數上限)。這份腳本已知會漏抓，實際修正數以腳本加上獨立 style agent 的審查為準。
- **結構性重構不在本次**：單檔 300 行上限的拆檔 (實測有 5 個 production 檔、11 個測試檔超過)、抽子 Feature、Action 分組與 case 改名、`Reduce` 分段調整、邏輯在 View／reducer／State 之間搬移、View body 拆分，仍由第 5 至 8 步處理；本次只登記。

**測試與守門**

- 依賴空實作的測試逐一補上明確覆寫；直接斷言舊 `testValue` 行為的 4 個測試改寫。
- 持久化測試改成對 `XxxService.liveValue` 注入 in-memory Database 的 Service 測試，測試數逐條對帳。
- 改動前先以既有實作跑殘留重現測試 (預期失敗)，改完後以新 Database 的失敗注入 Mock 守住同一組情境，並做變異驗證 (改回長命 context 要轉紅)。
- 新增原始碼掃描守門：
  - production 與測試不得以型別下標取用依賴
  - `Features/` 不得直接取用 Database、Client、Store
  - Service 的 `testValue` 必須全為 `unimplemented`
  - 不得出現 `PersistenceContainer.shared`
- 單元測試 host App 不再建立根畫面與正式 store，避免 `unimplemented` 在測試以外被觸發。

## Non-Goals

見 design.md 的 Goals／Non-Goals。

## Alternatives Considered

- **只改取用方式、結構留後續**：6 個非核心依賴只改成 `DependencyValues` 屬性，最省工；但分層違規與 ② 都留著，使用者未採用。
- **連第 3 塊一起做完**：所有 Service 都搬進各 Feature、不跨 Feature 共用。沒有過渡例外，但 change 會大到難以審查；使用者選擇分到第 5 至 8 步。
- **長命 context 保留，只在失敗時丟棄快取實例**：`PersistenceInstanceProvider` 在寫入失敗後捨棄 `OrderPersistence` 並重建。治標，其他持久化型別的 stale read 與串行化問題仍在，也不符合 2.0.0 的 Database 形狀。
- **Database 用 `@ModelActor`**：macro 綁定單一長命 `modelContext`，正是殘留的成因；而且 init 需要 MainActor，`liveValue` 無法是同步的 computed property。改用普通 actor 持有 `ModelContainer`。

## Impact

- Affected specs:
  - Modified：`persistence-error-contract` (7 條，型別與操作改名、rollback 改為丟棄 context)、`order-write-integrity` (並發串行化改由單一 Database actor 保證，新增「失敗寫入不影響後續寫入」)、`persistence-failure-recovery` (單一 container 的取得者改為 Database)、`app-layer-boundaries` (新增依賴分層與取用方式的掃描守門)、`test-guard-effectiveness` (新增未覆寫的 Service 被呼叫就失敗)
  - New：無
- Affected code:
  - Modified：
    - apps/ios/BuyLedger/App/BuyLedgerApp.swift
    - apps/ios/BuyLedger/App/AppLaunchConfigurator.swift
    - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift
    - apps/ios/BuyLedger/App/Testing/BLUITestHarness.swift
    - apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift
    - apps/ios/BuyLedger/Core/Persistence/PersistenceError.swift
    - apps/ios/BuyLedger/Core/Networking/HTTPClient.swift
    - 13 個 Feature 檔：apps/ios/BuyLedger/Features/Orders/{OrdersFeature,OrderEditFeature,OrderMergeFeature}.swift、apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift、apps/ios/BuyLedger/Features/Lookups/{LookupManagementFeature,PaymentMethodCorrectionFeature,LookupItemOperations}.swift、apps/ios/BuyLedger/Features/App/{RootFeature,AppLockFeature,PersistenceFailureFeature}.swift、apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift、apps/ios/BuyLedger/Features/FX/FxFeature.swift、apps/ios/BuyLedger/Features/Quote/QuoteRateFeature.swift、apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
    - 單元測試：直接引用依賴或持久化型別的 38 個測試檔 (2026-09-25 以型別名 grep 實測，清單見 design)，另有未點名型別、但依賴 `testValue` 預設值的 apps/ios/BuyLedgerTests/OrderEditFocusTests.swift，以及要加守門的 apps/ios/BuyLedgerTests/TestSuiteIntegrityTests.swift
    - 文件：
      - apps/ios/CLAUDE.md
      - apps/ios/README.md
      - .claude/rules/ios-data-layer.md
      - .claude/rules/ios-integrations.md
      - .claude/rules/ios-navigation.md
      - .claude/rules/ios-unit-tests.md
      - .claude/rules/ios-ui-tests.md
      - .claude/rules/ios-firebase-privacy.md
    - 測試設定：apps/ios/BuyLedger.xctestplan (第 9 組，`BuyLedgerTests` 關閉平行執行，避免 SwiftData 版本化 schema 並行崩潰)
  - New：
    - apps/ios/BuyLedger/Core/Environment/RuntimeEnvironment.swift
    - apps/ios/BuyLedger/Core/Persistence/{BuyLedgerDatabaseProtocol,BuyLedgerDatabase,BuyLedgerDatabase+Dependency,BuyLedgerDatabase+Preview,StorageFailureWrapping}.swift
    - apps/ios/BuyLedger/Core/Persistence/{OrderPersistenceError,PaymentMethodPersistenceError,CurrencyMetadataPersistenceError,PersistenceRecoveryError}.swift (由 PersistenceError.swift 拆出)
    - apps/ios/BuyLedger/Core/Networking/{HTTPClientProtocol,HTTPClient+Dependency,PreviewHTTPClient,ExchangeRateEndpoint}.swift
    - apps/ios/BuyLedger/Core/Storage/{UserDefaultsStoreProtocol,UserDefaultsStore,UserDefaultsStore+Dependency,PreviewUserDefaultsStore,AppConfigurationStoreProtocol,AppConfigurationStore,AppConfigurationStore+Dependency,PreviewAppConfigurationStore}.swift
    - 17 個 Service 各三檔 (`XxxService.swift`、`XxxService+Dependency.swift`、`XxxService+Preview.swift`)，業務邏輯超過 300 行者另拆 `XxxService+<Domain>.swift`；位置見 design 的 Service 配置表
    - apps/ios/BuyLedgerTests/Mocks/{MockBuyLedgerDatabase,MockHTTPClient,MockUserDefaultsStore,MockAppConfigurationStore}.swift
    - 由持久化測試改名而來的 `XxxServiceTests.swift`，以及殘留守門測試與依賴規範掃描測試
    - openspec/changes/service-database-layer-alignment/reference/ (殘留探測測試與風格檢查腳本的保存副本，不在 Xcode target 內)
  - Removed：
    - apps/ios/BuyLedger/Core/Dependencies/ 下 13 個 Repository／Client 檔、NameLookupOperations.swift、PhotoImportResult.swift (移到 Orders)
    - apps/ios/BuyLedger/Core/Persistence/{OrderPersistence,CampaignPersistence,CampaignReminderPersistence,CurrencyMetadataPersistence,NameLookupPersistence,PaymentMethodPersistence,LookupRecordRenamer,PersistenceStoreQuarantineClient}.swift
    - apps/ios/BuyLedger/Core/Networking/{ExchangeRateClient,OllamaClient,AppConfiguration}.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsStore.swift
    - 被 Service 測試取代的持久化測試檔，以及 apps/ios/BuyLedgerTests/OrderPersistence+LookupTesting.swift
