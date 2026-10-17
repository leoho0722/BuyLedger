## Context

proposal 已列出 2026-09-25 的實測現況與四輪使用者裁決，本檔只寫實作方式。三份調查的結論是以下設計的前提：

- **持久化方法全是同步的**：`Core/Persistence/` 內 `async`／`await` 零命中 (2026-09-25 grep)，交易都在一個 actor turn 內完成，中途不會重入。
- **只有 `OrderPersistence` 是長命實例**：由 `OrderRepository.PersistenceInstanceProvider` 保證單一實例。其餘 5 個持久化型別在每次 repository 呼叫時經 `await MainActor.run { X(modelContainer:) }` 新建，context 實際上是一次性的，但彼此之間沒有串行化。
- **殘留機制 (2026-09-25 實測)**：
  - 長命 context 的 save 失敗後，即使呼叫 `rollback()` 讓 `hasChanges` 變成 `false`，SwiftData 的 model 實例仍留著改過的值或刪除標記。
  - 之後對同一筆資料的寫入會把殘留帶進 store。
  - 無關資料的寫入不會帶出殘留；中間若做過一次完整讀取，記憶體會被刷回 store 的值。
  - 調查時以探測測試確認上述行為，task 0.3 以同樣的做法在 repo 內重現並記錄 result bundle；缺陷的四個情境已改寫成正式守門測試 `OrderServiceResidueTests`，探測測試檔已刪除 (使用者 2026-09-27 裁決)。
- **錯誤型別已有一致形狀**：`OrderPersistenceError`、`PaymentMethodPersistenceError`、`CurrencyMetadataPersistenceError` 都有 `case storage(PersistenceError)`。
- **`@ModelActor` 的 init 帶 main actor 隔離**：`@ModelActor` 只能在 async context 建立，所以同步的 computed `liveValue` 無法直接建立它。
- **swift-dependencies 的快取**：`CachedValues` 會快取 `liveValue`，computed `static var liveValue` 在同一個 context 只求值一次。`@Dependency` property wrapper 在建立時就擷取 `DependencyValues._current`。
- **`unimplemented` 的行為** (本機 xctest-dynamic-overlay checkout 的 `IssueReporting/Unimplemented.swift`)：`unimplemented(_:placeholder:)` 回傳不會拋錯的 async closure，依函式子型別規則可以指派給 typed throws 的 closure 型別。

## Goals / Non-Goals

**Goals:**

- 資料庫存取只經過 `BuyLedgerDatabase` 的 `read`／`write`／`quarantineStore` 三個技術操作。每次讀寫都用一次性 `ModelContext`，失敗的寫入不留下任何會被後續寫入帶進 store 的變更。
- Feature 型別只透過 `DependencyValues` 屬性取得 Service，不直接取得 Database、Client、Store。
- 17 個 Service 全部符合 2.0.0 Service 規則：
  - struct 裝 closure，每個 closure 都有 typealias
  - `testValue` 全部 `unimplemented`
  - `liveValue` 為 computed，以 `@Dependency` 取得下層依賴
  - `previewValue` 放在 `+Preview` 檔、整檔 `#if DEBUG`，getter 第一行 assert
- `HTTPClient`、`UserDefaultsStore`、`AppConfigurationStore` 符合 2.0.0 Client／Store 規則：protocol 加實作、`enum XxxKey` 註冊、不宣告 `testValue`、Mock 放在測試 target。
- 全庫不再以型別下標取用依賴，並以原始碼掃描守住。
- 依賴 `testValue` 空實作的測試全部改成明確覆寫；持久化測試改寫成 Service 測試，測試數逐檔對帳。
- 本 change 改到的每個既有 Swift 檔，寫法與排版整檔符合 ios-dev-kit；只限本 change 本來就會改到的檔案 (使用者 2026-09-25 追加，分類見「被改到的既有檔案整檔修正寫法與排版」)。

**Non-Goals:**

- **跨 Feature 共用的 Service 本次不搬進 Feature** (2.0.0 三塊中的第 3 塊)：`Core/Dependencies/` 內 8 個 Service 登記為過渡例外，搬遷時程見下方「過渡例外的登記與排程」。
- **錯誤型別不改名**：`OrderPersistenceError`、`PaymentMethodPersistenceError`、`CurrencyMetadataPersistenceError`、`PersistenceRecoveryError`、`CalendarReminderError`、`APIError` 維持原名。唯一例外是 `CurrencyMetadataRepositoryError` 改成 `CurrencyMetadataServiceError`，因為名稱裡的 Repository 已經不存在。
  - 2.0.0 的 `<Feature>Error` 屬於 Feature 的 Domain 層，隨第 3 塊處理。
- **系統 framework 不另外抽 Client**：EventKit、LocalAuthentication、PhotosUI、UIApplication、Firebase 由各 Service 的 `liveValue` 直接呼叫，不再拆一層技術性 Client。
- **`CrashDiagnosticsClient` 不動**：它不是 `DependencyKey`，只由 `AppLaunchConfigurator.configure(crashDiagnosticsClient:)` 以參數預設值取得；登記為第 10 步待決定。
- 不改 schema、遷移、store 位置、排序、upsert 語意、連帶更新與刪除語意。唯一刻意的行為變更是 ② 的殘留修正，以及主檔／開團 upsert 因單一 Database 而串行化。
- **被改到的既有檔案不做結構性重構**：拆檔 (含 16 個既有超過 300 行的檔)、抽子 Feature、Action 分組與 case 改名、`Reduce` 分段整併或改成 `Reduce(core)`、`extension <Feature>.State` 移回本體、邏輯在 View／reducer／State 之間搬移、View body 拆 Private Views、移除 `exhaustivity = .off`，都留給第 5 至 8 步。
- 不動 `.xcstrings`、snapshot 基準圖與 UI 測試的 identifier。
- 不重整測試 target 的扁平目錄 (只新增 `BuyLedgerTests/Mocks/`)。
- 不把 `+Preview` 檔集中到 `Preview Content` 資料夾：專案沒有這個資料夾，也沒有設定 `DEVELOPMENT_ASSET_PATHS`。`+Preview` 放在 Service 旁邊，靠整檔 `#if DEBUG` 排除於 Release 之外。
- 跨 await 的非原子序列不變：`refreshIfStale` 的網路呼叫、付款方式更正的 plan 與確認、開團儲存後改名與行事曆，這三條本來就不是單一交易。

## Decisions

### Database 用普通 actor 並以一次性 context 執行每次讀寫

`BuyLedgerDatabase` 是普通 `actor`，持有 `ModelContainer` (本身 `Sendable`) 與 store 位置：

- `read` 在 actor 內建立 `ModelContext(modelContainer)` 並交給 closure，closure 結束就丟棄。
- `write` 同樣建立一次性 context，closure 成功後只呼叫一次 `save()`。closure 拋錯或 `save()` 失敗時直接丟棄 context，不呼叫 `rollback()`。

理由：

- **② 的成因是長命 context**。一次性 context 讓失敗的變更沒有地方殘留，`performWithRollback`／`rollbackPendingOrderRecords` 可以整組刪除。
- **串行化保證維持**：Database 在一個 process 的 live context 只有一個實例 (依賴快取加 `PersistenceContainer.bootstrap` 只解析一次)。`read`／`write` 是 actor 方法、closure 是同步的，所以「查撞號再插入」仍在同一個 actor turn 內完成，而且查的是 store 的真實狀態。
- 原本每次新建實例、沒有串行化的主檔／開團／付款方式 upsert，改走同一個 actor 後也串行化了。
- 長命 context 在其他 context 改寫 `OrderRecord` 後讀到舊值的風險，隨長命 context 消失。

替代方案：

- `@ModelActor`：macro 綁定單一長命 `modelContext`，正是殘留的成因，而且 init 需要 MainActor。不採用。
- 保留長命 context，寫入失敗時丟棄快取實例：治標，其他型別的問題不處理。不採用。

### write 的錯誤合約以 StorageFailureWrapping 泛型化

新增 `protocol StorageFailureWrapping: Error { static func storage(_ error: PersistenceError) -> Self }`：

- `PersistenceError` 以回傳自身遵循。
- 三個 domain 錯誤的 `case storage(PersistenceError)` 直接當作 protocol witness (enum case 可以滿足 static func 需求)。

**遵循寫在各錯誤型別所在的檔案**，不寫在 protocol 檔：依 `formatting.md` 的分區順序，protocol 遵循 extension (`// MARK: - StorageFailureWrapping`) 屬於遵循型別自己的檔案，排在 Internal Method 之後、Private Method 之前；`StorageFailureWrapping.swift` 只放 protocol。四個錯誤 enum 目前同在 `PersistenceError.swift`，遵循先緊接在各自 enum 之後，task 6.2 拆檔時隨 enum 一起搬。

`write` 的 `Failure` 限定為 `StorageFailureWrapping`，讓 Database 能把 `save()` 失敗包成呼叫端的錯誤型別 (`.storage(.saveFailed(underlying:))`)。`read` 的 `Failure` 只要求 `Error`。closure 內 `context.fetch`／`context.save` 的框架錯誤仍以既有的 `PersistenceError.mapFetch`／`mapSave` 橋接 (`error as NSError`)。

替代方案：

- `write` 固定拋 `PersistenceError`，由 Service 自行轉換：撞號這類語意錯誤會失去型別。不採用。
- `write` 拋 `DatabaseWriteError<Failure>`：每個呼叫端都要多解一層。不採用。

### 交易主體必須同步，跨 await 的序列留在 Service

`read`／`write` 的 closure 型別是 `@Sendable (ModelContext) throws(Failure) -> Value`，不接受 `async`。

- closure 內要完成 record 與 domain 之間的轉換，回傳值必須是 `Sendable` 的 domain 值，不得回傳 `@Model` 或 `ModelContext`。
- 需要 await 的步驟 (網路、行事曆、使用者確認) 一律在 Service 或 Feature 裡，分成多次 `read`／`write`，並維持現有的非原子語意。

`Sendable` closure 在 actor 內以非 `Sendable` 的一次性 context 為參數同步呼叫，是 region-based isolation 允許的寫法，但本專案尚未實測。task 1.3 先寫最小可編譯的形狀。若 Swift 6 編譯器拒絕，就停下來回報，改用 `sending` 參數或 `isolated` 參數的寫法再與使用者確認。

### 業務邏輯移到 Service 並依職責拆檔

6 個持久化型別的業務邏輯移到對應 Service：

- 查詢條件、撞號檢查、upsert、合併、主檔改名合併、開團連鎖刪除、幣別清單替換、排序
- 以 `extension XxxService` 的 static 方法實作，每個方法收 `ModelContext` 並在 `write`／`read` 的 closure 內被呼叫
- `LookupRecordRenamer` 的邏輯移到 `OrderService` 的改名交易檔

拆檔規則：

- 超過 300 行 (不含檔頭與空行) 的依職責拆成 `XxxService+<Domain>.swift`，例如 `OrderService+Writes.swift`、`OrderService+Renames.swift`、`OrderService+Reads.swift`。
- Record 與 domain 的轉換 (`OrderRecord.init(order:)`、`apply(_:)`、`toDomain(includingPhotos:)` 等) 維持在 `Core/Persistence/` 的 Record 檔。

必須逐字保留的細微差異 (調查已確認)：

- 付款方式**改名**以 OR 合併旗標，**編輯**則覆寫旗標。
- `applyPaymentMethodEdit` 只擋空字串，不擋與舊名相同 (同名編輯只改旗標)。
- `OrderRecord.apply(_:)` 永不寫照片。
- `fetchOrders` 以 `propertiesToFetch` 排除照片。
- `mergeOrders` 跳過 newID。
- 開團刪除回傳行事曆事件 id。
- 類別改名要撈全表 (陣列 contains 無法寫成 predicate)。
- 幣別清單為空時拋 `.emptyCodeList` 且不動快取。
- 排序一律用 `localizedStandardCompare`。

### Service 配置表

「位置」依使用者裁決：只有一個 Feature 使用的放進該 Feature 的 `Data/`；跨 Feature 共用的留 `Core/Dependencies/` 當過渡例外。

| Service | 取代 | 位置 | 保留的 closure | 刪除的 closure | 下層依賴 |
|---|---|---|---|---|---|
| `OrderService` | `OrderRepository` | `Core/Dependencies/` | fetchOrders、createOrder、saveOrder、saveOrders、fetchOrderPhotos、saveOrderPersistingPhotos、removeOrder、mergeOrders、applyOrderSourceRename、applyCategoryRename、applyPaymentMethodRename、applyReconciliationStatusRename、renameOrderCampaign | — | `\.buyLedgerDatabase` |
| `CampaignService` | `CampaignRepository` | `Core/Dependencies/` | fetchCampaigns、saveCampaign、removeCampaign | — | `\.buyLedgerDatabase` |
| `CategoryService` | `CategoryRepository` | `Core/Dependencies/` | fetchCategories、addCategory、removeCategory | renameCategory | `\.buyLedgerDatabase` |
| `OrderSourceService` | `OrderSourceRepository` | `Core/Dependencies/` | fetchOrderSources、addOrderSource、removeOrderSource | renameOrderSource | `\.buyLedgerDatabase` |
| `ReconciliationStatusService` | `ReconciliationStatusRepository` | `Core/Dependencies/` | fetchReconciliationStatuses、addReconciliationStatus、removeReconciliationStatus | renameReconciliationStatus | `\.buyLedgerDatabase` |
| `PaymentMethodService` | `PaymentMethodRepository` | `Core/Dependencies/` | fetchPaymentMethodInfos、addPaymentMethod、removePaymentMethod、applyPaymentMethodEdit | fetchPaymentMethods、renamePaymentMethod、setPaymentMethodIsCardless | `\.buyLedgerDatabase` |
| `CurrencyMetadataService` | `CurrencyMetadataRepository` | `Core/Dependencies/` | fetchCodes、refreshIfStale | forceRefresh | `\.buyLedgerDatabase`、`\.httpClient`、`\.appConfigurationStore`、`\.date` |
| `ExchangeRateService` | `ExchangeRateClient` | `Core/Dependencies/` | fetchLatest | fetchSupportedCodes (邏輯移到 `CurrencyMetadataService`) | `\.httpClient`、`\.appConfigurationStore`、`\.date` |
| `CampaignReminderService` | `CampaignReminderRepository` | `Features/Campaigns/Data/` | fetchLinks、saveLink、removeLink | — | `\.buyLedgerDatabase` |
| `CalendarReminderService` | `CalendarReminderClient` | `Features/Campaigns/Data/` | requestAccess、addReminder、removeReminder | reminderExists | EventKit |
| `OpenSettingsService` | `OpenSettingsClient` | `Features/Campaigns/Data/` | open | — | UIApplication |
| `PhotoService` | `PhotoClient` | `Features/Orders/Data/` | importPhotos | — | PhotosUI、`PhotoDataProcessor` |
| `BiometricAuthService` | `BiometricAuthClient` | `Features/App/Data/` | isAvailable、authenticate、biometryType | — | LocalAuthentication |
| `PersistenceRecoveryService` | `PersistenceStoreQuarantineClient` | `Features/App/Data/` | quarantineStore | — | `\.buyLedgerDatabase` |
| `AISummaryService` | `OllamaClient` | `Features/AISummary/Data/` | streamSummary (以 `httpClient.stream(...)` 送出，401／403 的 `.http(statusCode:)` 在 Service 內轉成 `.invalidKey`)、apiKey (新增，取代 Feature 直接讀 `\.appConfiguration.ollamaAPIKey`) | — | `\.httpClient`、`\.appConfigurationStore` |
| `SettingsService` | `SettingsStore` | `Features/Settings/Data/` | load、save | — | `\.userDefaultsStore` |
| `TelemetryService` | `TelemetryClient` | `App/` (與 `AppLaunchConfigurator` 同資料夾) | enablePreInitializationCollection、enableCollection | — | Firebase |

- `DependencyValues` 屬性名稱是型別名首字小寫 (`\.orderService`、`\.aiSummaryService`)。
- 隨 Service 搬移的附屬型別各自一檔，放在 Service 旁邊：`CampaignReminderLink`、`CalendarReminderError`、`PhotoImportResult`、`CurrencyMetadataServiceError`、`OllamaChatRequest`、`OllamaChatResponse` (後兩者只被 `AISummaryService` 使用，隨它搬到 `Features/AISummary/Data/`)。
- 被 Feature 引用的巢狀型別跟著改名：`BiometricAuthService.AuthenticationResult`／`.BiometryKind` (原 `BiometryType`，見裁決表「closure 屬性的 typealias 與巢狀型別撞名」)、`AISummaryService.overallStreamDuration`。
- `ExchangeRateService` 與 `CurrencyMetadataService` 共用的請求組裝與解碼收進 `Core/Networking/ExchangeRateEndpoint.swift`。它是無 case 的 enum，只放 static 方法，不是依賴，避免 Service 依賴 Service。
- `SettingsService` 留在 `Features/Settings/`，但 `OrdersFeature` 的 `aiSummaryTapped` 與 `BuyLedgerApp.init` 也取用它。前者跨 Feature，列入過渡例外；後者是 App 組合根，不算違規。

### HTTPClient 改為 Client，設定與偏好改為 Store

- **`HTTPClient`**：拆成 `protocol HTTPClientProtocol: Sendable`，含 `data(for:)` 與 `bytes(for:)` 兩個技術操作，加上 `struct HTTPClient`。
  - `send(url:method:headers:body:timeout:)` 與 `decode(_:from:)` 移到 protocol extension，呼叫端寫法不變。
  - protocol extension 另加串流版 `stream(url:method:headers:body:timeout:)`，回傳 `URLSession.AsyncBytes`。它和 `send` 共用同一段請求組裝 (`URLRequestBuilder`) 與 2xx 驗證 (非 2xx 丟 `.http(statusCode:)`)，差別只在底層呼叫 `bytes(for:)`。
    - `send` 經 `data(for:)` 等整個回應收完才回傳，AI 摘要改用它會失去逐段顯示，所以另加串流版，不直接呼叫 `send`。
    - 使用者 2026-09-26 review 指出 `OllamaClient.streamSummary` 自行以 `URLRequestBuilder` 組請求、自行驗狀態碼，應改用 `HTTPClientProtocol` 提供的共用實作；由 task 4.2 的 `AISummaryService` 落實。
  - `HTTPClient+Dependency.swift` 以 `enum HTTPClientKey` 註冊，`\.httpClient` 型別為 `any HTTPClientProtocol`。
  - `#if DEBUG` 的 `PreviewHTTPClient` 一律拋 transport 錯誤 (與現行 previewValue 相同)。
  - 不宣告 `testValue`。
- **`UserDefaultsStore`** (`Core/Storage/`)：只提供技術操作，包括 `string(forKey:)`、`double(forKey:)`、`bool(forKey:)`、`hasValue(forKey:)` 與三個 `set(_:forKey:)`。
  - `SettingsService` 持有 key 名稱與快照組裝規則。
  - 「key 不存在時月度目標回預設 80,000」改寫成 `hasValue(forKey:) == false`。
  - 六個 UserDefaults key 字串逐字不變。
- **`AppConfigurationStore`** (`Core/Storage/`)：只提供 `string(forKey:)`，讀 Info.plist 並套用既有的正規化 (trim、空字串與未展開的 build setting 佔位字串視為 `nil`)。
  - `EXCHANGE_RATE_API_KEY`、`OLLAMA_API_KEY` 兩個 key 名稱由 `ExchangeRateService`／`CurrencyMetadataService`／`AISummaryService` 持有。
- 三者都遵循 `data/Service.swift` 樣板改後綴，`+Dependency` 從 `tca/DependencyKey.swift` 複製。Mock 從 `tests/MockService.swift` 複製到 `BuyLedgerTests/Mocks/`。
- **protocol 與實作各自一檔**：`data/Service.swift` 樣板把 protocol 與實作放同一檔，但 `apps/ios/CLAUDE.md`「一個檔只放一個頂層型別」優先於 skill，所以拆成 `XxxProtocol.swift` (protocol) 與 `Xxx.swift` (實作)，兩檔內容仍依樣板的分區與 doc 寫法。`BuyLedgerDatabase` 同樣拆成 `BuyLedgerDatabaseProtocol.swift` 與 `BuyLedgerDatabase.swift`。

### testValue 一律 unimplemented 並改為明確覆寫

每個 Service 的 `testValue` 對每個 closure 寫 `unimplemented("<Service>.<屬性>")`：

- 有回傳值的加 `placeholder:`，填中性值：`[]`、`[:]`、`nil`、空字串、`PhotoImportResult(photos: [], failedCount: 0)`、`SettingsSnapshot.default`。
- 回傳 `AsyncThrowingStream` 的用立即 `finish()` 的 stream。

測試端的改法：

- 約 34 個依賴空實作的測試 (靜態掃描估計；以 task 2.2、3.4、3.5、4.1 至 4.5 實際轉紅的清單為準)，改成只覆寫該測試會呼叫到的 closure (`$0.orderService.saveOrder = { _ in }`)。
- 以 `XxxRepository.testValue` 為底再覆寫的寫法照舊可用 (底座改成 unimplemented)。
- 直接斷言舊 `testValue` 行為的 4 個測試，改寫成斷言新 Mock 或 Service 的行為：`ExchangeRateClientTests` 的 testValue 診斷、`HTTPClientTests.unconfiguredHTTPClientUsesDependencyDiagnostic`、`OllamaClientTests.testValueThrowsWhenInvoked`、`AppConfigurationTests.testValueProvidesNothing`。
- 不得以新增 `exhaustivity = .off` 解決；上限仍由 `TestSuiteIntegrityTests` 守住。

### previewValue 以單一 seed 過的 Preview Database 提供

- `BuyLedgerDatabase+Preview.swift` (整檔 `#if DEBUG`) 的 `previewValue` 建立一個 in-memory container，seed 一次 `LedgerOrder.sampleOrders`，所有 Database Service 共用。主檔 seed 內容與現況相同 (都是空的)，差別是主檔、訂單、開團從此在同一個 container。
- 以 Database 為下層的 Service，`+Preview` 的 `previewValue` 在 assert 之後回傳 `liveValue`。getter 在 Preview context 中求值，`@Dependency(\.buyLedgerDatabase)` 會解析到 Preview Database，這就是使用者裁決的「保留容器寫法」。
- 其餘 Service 的 `previewValue` 回傳固定假資料，沿用現有內容。`PhotoService` 與 `OpenSettingsService` 目前沒有 previewValue，新增為空結果與 no-op。
- assert 用新增的 `Core/Environment/RuntimeEnvironment.swift` (從 `core/RuntimeEnvironment.swift` 樣板複製)。`isUITesting` 改判啟動參數 `-BLUITest`，因為本專案 UI 測試不帶樣板的 `-uiTesting`。

### 單元測試 host 不建立根畫面

單元測試以 App 為 host。目前 `BuyLedgerApp.init` 會解析正式的持久化啟動、呼叫 `SettingsStore.load()`、建立 `RootFeature` store，`RootView` 的 `.task` 還會觸發 `refreshIfStale`。`testValue` 改成 `unimplemented` 之後，這些呼叫會在沒有測試執行時回報 issue，並被歸到隨機的測試上。

改法：

- `BuyLedgerApp` 在 `RuntimeEnvironment.isUnitTesting` 時只顯示空白 scene：不建立 store、不解析持久化啟動、不讀設定。`store` 改成 `StoreOf<RootFeature>?`，`WindowGroup` 內以 `if let store` 決定是否顯示 `RootView`，scenePhase 轉送也以 `store` 為 nil 時略過。
- `BuyLedgerApp` 移除 `modelContainer` 屬性與 `.modelContainer(...)` modifier，只從持久化啟動取 `status`：全 App 沒有 `@Query`，也沒有讀 `\.modelContext` (2026-09-25 grep 為 0)。這樣正式 container 在 production 只剩 Database 一個使用者，符合 persistence-failure-recovery 的修改後條文。`AppLaunchConfigurator.activePersistenceBootstrap` 同步縮成只提供 status。
- `AppLaunchConfigurator.configure` 在同一條件下直接返回。
- `TelemetryService` 在 `AppLaunchConfigurator` 改用 `@Dependency(\.telemetryService)` 取得。`configure` 由 AppDelegate 在 `BuyLedgerApp.init` 之後呼叫，這時 UI 測試的 `prepareDependencies` 已經完成；原本「刻意直接走 liveValue」的註解一併移除。

### UI 測試 harness 以注入 Database 組出 Service

`BLUITestDependencyOverrides` 改成：

- 先設 `$0.buyLedgerDatabase = BuyLedgerDatabase(modelContainer: container, storeLocation: …)`：`BLUITestHarness` 的 in-memory 模式傳 `.inMemory`，persistent 模式傳 `.directory(<UI 測試 store 所在目錄>)`，不得一律標成 in-memory (UI 流程固定 `.healthy` 走不到隔離，但位置資訊仍要正確)。
- 需要失敗注入的 Service 以 `withDependencies { $0.buyLedgerDatabase = database } operation: { OrderService.liveValue }` 明確建立、包上失敗 closure，再指派給 `$0.orderService`。
- **不得在 `prepareDependencies` 的 closure 內讀 `$0.xxxService` 當作底座**：`@Dependency` 在 `liveValue` 建立時擷取的是當下的 `_current`，不是正在準備的 `$0`，會拿到正式 store。
- 既有的失敗注入旗標與行為不變：`-BLUITestLoadFailure` 的 `orders`／`ordersFirstReadOnly`／`campaigns`／`lookups`，以及 `-BLUITestLookupWriteFailure`。
- 旗標原本改寫的 closure 若已刪除 (`fetchPaymentMethods`、`forceRefresh`)，就從覆寫清單移除。

### 殘留缺陷的重現與守門

- **改動前 (task 0.3)**：把調查用探測測試的做法整理成四個情境，對現行 `OrderPersistence` 執行，預期全部失敗並記錄 result bundle，作為缺陷存在的證據。失敗注入方式是在同一個 context 插入違反子項上限的測試專用 model，讓 `save()` 以驗證錯誤失敗、store 不變、之後的 save 可成功。
  - 刪除失敗後再刪一次，資料要真的消失
  - 刪除失敗後以同 id 建立，要得到撞號錯誤且只有一筆
  - 刪除失敗後以同 id 更新，只有一筆
  - 編輯失敗後改同一筆的開團名稱，失敗那次的欄位不得落盤
- **改動後 (task 3.2)**：新測試對 `OrderService.liveValue` 注入 `MockBuyLedgerDatabase`，由它在指定那次 `write` 的同一個一次性 context 插入違規子項 (真的 save 失敗)，驗證同一組四個情境全部通過。
- **測試用 schema 與 fixture**：真的 save 失敗需要容器 schema 內有違規用的 model。比照探測測試的 `makeDiskFixture`，在暫存目錄建立磁碟 store，schema 為 `ResidueProbeModels.schema`：`OrderRecord`、`CategoryRecord`、`PaymentMethodRecord`、`CampaignRecord`、`CampaignReminderRecord` 與兩個探測 model (主檔兩個 record 供付款方式與改名的 save 失敗測試使用，開團兩個 record 供開團刪除的 save 失敗測試使用)；兩個探測 model 放在測試 target 的新檔 `BuyLedgerTests/ResidueProbeModels.swift`，不進 App target。驗證落盤結果時，以 `ResidueProbeModels.storeURL(in:)` 的同一個 store URL 另建一個 `BuyLedgerDatabase` 讀回。task 1.3 的 `BuyLedgerDatabaseTests` 中「真的 save 失敗」案例使用同一套 fixture。
- **變異驗證**：暫時讓 `BuyLedgerDatabase` 改用長命 context，四條至少一條要轉紅；還原後以 SHA-256 比對確認檔案回到原狀。
- `MockBuyLedgerDatabase` 包住一個真的 `BuyLedgerDatabase`，提供三種模式：
  - 直通
  - 讀取失敗：指定次序的 `read` 直接拋錯
  - 寫入失敗：在 closure 執行後插入違規子項，讓真的 `save()` 失敗；或 closure 執行後直接拋出指定錯誤

  它取代原本的 `consumedOrderFetcher`／`lookupRenameOrderFetcher` 測試縫與 `makeUnsavablePersistence`。

### 依賴規範的原始碼掃描守門

新增 `DependencyConventionScanTests` (比照 `ActionGroupingScanTests` 附自我測試案例表)。掃描前去掉註解；找不到 source root 時失敗而不是略過。規則如下：

1. `BuyLedger/` 與 `BuyLedgerTests/` 不得出現 `@Dependency(<型別>.self)`，也不得出現以識別字接 `[<型別>.self]` 的依賴下標。`extension DependencyValues` 的 `self[<型別>.self]` 除外，而且只限 `+Dependency.swift` 檔。`Schema([X.self])` 這類陣列字面值不受影響。
2. `Features/**` 除 `Features/*/Data/` 外，不得出現 `\.buyLedgerDatabase`、`\.httpClient`、`\.userDefaultsStore`、`\.appConfigurationStore`，也不得出現 `ModelContext`、`ModelContainer`。另外，任何 `*Service*.swift` 都不得以 `@Dependency(\.xxxService)` 取用其他 Service (Service 不依賴 Service)。
3. 每個 `*Service+Dependency.swift` 的 `testValue` 中，每個 closure 引數都必須以 `unimplemented(` 開頭；Client／Store／Database 的 `+Dependency.swift` 不得宣告 `testValue`。
4. App 與單元測試程式碼都不得引用 `PersistenceContainer.shared` (對齊 spec「No source file」與兩棵樹的掃描範圍)；App 程式碼不得宣告 `static let shared`／`static var shared`。系統 API 如 `UIApplication.shared` 不受限。使用者 2026-09-29 裁決

每條規則都要做變異驗證 (暫時注入違規寫法，確認轉紅且實際執行數大於 0)，還原後比對 SHA-256。

### 過渡例外的登記與排程

完成後在 `apps/ios/CLAUDE.md`「ios-dev-kit 規範與既有差異」改寫 Core 依賴那一條，列出仍與 2.0.0 不同之處與排程：

| 差異 | 排程 |
|---|---|
| `Core/Dependencies/` 內跨 Feature 共用的 Service：Order、Campaign、Category、OrderSource、ReconciliationStatus、PaymentMethod | 第 5 至 8 步搬遷 |
| 同上：ExchangeRate、CurrencyMetadata | 第 10 步決定 |
| `SettingsService` 被 `OrdersFeature` 跨 Feature 取用 | 第 6 步 |
| 錯誤型別仍用 `XxxPersistenceError` 命名 | 隨第 3 塊 |
| 系統 framework 由 Service 直接呼叫 | 第 10 步 |
| `CrashDiagnosticsClient` 以參數預設值注入 | 第 10 步 |
| `+Preview` 放在 Service 旁邊而非 `Preview Content` | 第 10 步 |
| 被放進 Feature 的 Service 只在 `Data/`，Feature 其餘檔案仍是扁平結構 | 第 10 步 |

同時刪除 `apps/ios/CLAUDE.md` 已失效的條目：「Repository 以 type-based `@Dependency(SomeRepository.self)` 注入」「所有 repository 的 `liveValue` 共用 `PersistenceContainer.shared`」，以及屬性包裝器範例中的 `@Dependency(X.self)`。

### 被改到的既有檔案整檔修正寫法與排版

使用者 2026-09-25 追加：被本 change 改到的既有檔案，發現寫法與排版不符合 ios-dev-kit 時整檔一併修正；結構性重構仍留給第 5 至 8 步 (使用者選「整檔修寫法與排版」，未選「整檔完全對齊」或「只修改到的區塊」)。

**「被改到」的定義**：本 change 結束時 `git diff` 中狀態為修改 (M) 的既有 Swift 檔，包括只改了呼叫端或測試覆寫的檔。新增檔與整檔改寫的檔本來就要完全符合規範，包含 300 行上限。

**要修 (寫法與排版)**：

| 類別 | 項目 |
|---|---|
| 檔頭與 import | 檔頭四行格式、日期不補零且不改原日期；import 排序 |
| 註解 | 每個宣告的 `///`，含 `- Parameter`／`- Returns`／`- Throws` 與摘要後的空 `///`；enum case 的 associated value 補 `- Parameter`；註解結尾不加中文句號、不用破折號、用半形括號 |
| 分區 | MARK 段名在允許清單內、頂層分區順序、同一分區不重複、區塊內容與段名相符、巢狀型別內不放 MARK、protocol 遵循放獨立 extension (巢狀型別成員就地) |
| 排版 | 縮排 4 格、行寬 100 (以字元計)、無尾隨空白、enum 與 switch 的 case 之間空行、參數與引數依 ios-dev-kit 3.1.0「參數與引數對齊」：未達斷行條件 (整行不超過 100 且不超過三個) 一律寫在同一行，達到就每個一行 |
| 寫法 | 宣告的大括號本體換行；屬性包裝器與宣告同行；closure 具名參數與 `sorted { lhs, rhs in` 寫法；typed throws closure 短式 (`{ () throws(E) in`、`{ order throws(E) in`)；存取控制從 `private` 起手；禁 `!`／`try!`／`as!`；不用 `switch`／`if` 運算式賦值；非公開、不影響 Action／State 形狀與跨檔介面的識別字命名 |
| 測試寫法 | 每個測試的 `///`；測試本體 Given／When／Then 且標記下方有程式碼；`receive` 用 case key path；`send`／`receive`／`withDependencies` 的 closure 用 `$0`；失敗替身以 typealias 宣告的 `let` 注入；呼叫紀錄與可變狀態用 `LockIsolated`，取代測試檔底部自訂的 `private final class …Box` |
| 一檔一型別 (`TOP`) | 同檔的其他頂層型別搬到同名新檔，檔名對應的型別留在原檔：`CampaignFeature.swift` 搬出 `CampaignDateSection`、`CampaignSubgroup`、`CampaignGrouping`；`PersistenceError.swift` 保留 `PersistenceError`，搬出其餘 4 個錯誤 enum。搬移時型別宣告與內容不改，只有型別本體內的 computed property 依下一列 (`MK5`) 移到 extension (兩列同時適用時 `MK5` 優先)。測試檔底部的 private box (共 10 個，分布在 `OrdersFeatureTests`、`CampaignFeatureTests`、`ExchangeRateClientTests`) 依「測試寫法」改用 `LockIsolated` 而移除。無法改用 `LockIsolated` 的 private 測試夾具改成所在測試型別內的 private 巢狀型別：`SchemaMigrationTests` 的 `IndexAdditionNoIndexSchema`／`IndexAdditionIndexedSchema`、`PersistenceRecoveryTests` 的 `BelowMigrationFloorSchema`。`App/Testing/BLUITestDependencyOverrides.swift` 的 6 個 private 型別 (`BLUITestStubs`、`BLUITestPhotoCache`、`BLUITestLoadSource`、`BLUITestErrorFactory`、`BLUITestFirstReadGate`、`BLUITestSettingsStore`) 各自連同其 private extension 搬到 `App/Testing/` 同名新檔，型別與 extension 都改為 internal，讓原檔的呼叫點仍能存取 (該資料夾整個在 `#if DEBUG` 內)；`BLUITestDependencyOverrides.swift` 留下 `extension DependencyValues` |
| 型別本體內的 computed property (`MK5`) | 依 `formatting.md` 移到 extension 的 `Computed Properties` 分區；protocol 要求的實作 (如 `VersionedSchema.models`) 移到以該 protocol 為段名的遵循 extension；TCA `State` 的衍生值與 `var body` 依 `tca-architecture.md` 留在本體 |

**不修 (結構性，只登記給第 5 至 8 步)**：見 Non-Goals 第一條。16 個既有超過 300 行的檔 (2026-09-25 以檢查腳本實測)：

- production：`CampaignFeature` 1,063、`OrdersFeature` 974、`OrderEditFeature` 812、`BLUITestDependencyOverrides` 549、`RootFeature` 398
- 測試：`OrdersFeatureTests` 2,984、`RootFeatureTests` 1,868、`CampaignFeatureTests` 1,555、`OrderEditFeatureTests` 1,214、`CampaignReminderFailureTests` 519、`SchemaMigrationTests` 491、`QuoteFeatureTests` 464、`OrderMergeFeatureTests` 459、`SnapshotTests` 394、`SettingsFeatureTests` 326、`PersistenceRecoveryTests` 306

**修正時機與檢查方式**：

- 遷移批次 (2.x 至 5.x) 只做功能遷移，避免把行為改動與排版改動混在同一批難以審查；排版在第 6 組整檔處理。
- 檢查用 `reference/style_checks.py`：由第 4 步腳本改成所有檔整檔檢查，上述 16 檔的 LEN 記為 `LENX`、不算失敗。
- 腳本已知會漏抓 (第 4 步獨立 style agent 另抓到約 80 項)，每組檔案還要由獨立 style agent 對照 `formatting.md`、`coding-style.md`、`tca-architecture.md` 全文與檔末檢查清單逐檔審查。
- 2026-09-25 修正前的實測量：21 個 production 檔 389 筆、26 個測試檔 567 筆 (不含 LEN)。遷移後的檔案集合與內容都會變，所以第 6 組開工前要重跑一次，當作該組的基準。
- **模糊地帶的判定**：若某項修正必須改 Action case 名稱、跨檔 API，或搬動邏輯才能成立，就歸為結構性，登記不修；拿不準時停下來回報。「一檔一型別」的搬檔不算拆檔：拆檔指把**同一個型別**切成多個檔 (`<Name>+<Domain>.swift`)，這才屬結構性。
- 第 6 組因搬檔新增的 Swift 檔屬於新檔，適用 300 行上限與完整規範；這些新檔要列在 6.x 對應 task 行下方。
- 把 `SchemaMigrationTests`／`PersistenceRecoveryTests` 的 `VersionedSchema` 夾具巢狀化後，這兩個測試類別必須全綠；SwiftData 公開 API 不要求 `VersionedSchema` 是頂層型別 (Codex 第三輪依 Apple 文件確認)，但 store 指紋演算法不公開，若巢狀化後任一條遷移測試轉紅，就停下來回報，改為登記例外。

### 規範解讀的使用者裁決 (2026-09-26)

第 1 組獨立 style 審查提出、需要解讀的規範，使用者裁決如下；新檔與本 change 改到的既有檔一律照做，task 7.1 把第 1、3、4、5、6、7 條寫進 `apps/ios/CLAUDE.md`：

| 項目 | 裁決 | 依據與範圍 |
|---|---|---|
| 帶關聯值的 case pattern | 一律 `case .x(let v)`，不用 `case let .x(v)` | `file-templates.md`「switch 內統一用 `case .x(let v)`」；`if case`／`guard case` 同樣寫法以求一致。沒被改到的既有檔留給各自步驟，改到哪個 switch 就整個 switch 一起改 |
| `DependencyValues` 屬性的 accessor | `get { self[Key.self] }`／`set { self[Key.self] = newValue }` 維持單行 | `tca/DependencyKey.swift` 樣板寫法，視為「宣告大括號本體換行」的例外 |
| 不會失敗的 Client／Store／Service 操作 | 不加 `throws` | 鐵則 7「一律 typed throws」解讀為「會失敗的操作一律 typed throws」，`UserDefaultsStore`／`AppConfigurationStore` 的讀寫不硬加；使用者 2026-09-27 看 `SettingsService` 的 `load`／`save` 時延伸到 Service closure |
| `guard` 的 `else` 內容 | 測試的前置取值改用 `try #require`，`else` 內不放斷言；Mock 的 `preconditionFailure` (型別不符即程式錯誤) 保留並以 `- Note` 說明 | `coding-style.md`「guard 的 else 只放 return、throw、continue、break」 |
| 錯誤對應 helper 的 trailing closure (`PersistenceError.mapFetch`／`mapSave`、`wrapStorage` 等) | 一律多行：`{` 接在呼叫後，本體另起一行縮排 4 格，`}` 單獨一行；不寫成 `mapFetch { try context.fetch(descriptor) }` | 使用者 2026-09-26 要求風格一致；`formatting.md` 單行、多行 closure 都允許，但本 change 既有 49 處為多行、11 處為單行，統一成多行 |
| 函式型別的 typealias 超過 100 字元 | 有參數時照一般行寬規則斷行：參數在括號內各自一行，`)` 與 effects、回傳型別同一行；參數位置的函式型別同樣處理。**無參數時維持一行，不換行** (沒有參數可換行，也不在 `=` 前後斷行) | `formatting.md`「超過 100 也維持一行」只列 `import`、`case` 宣告、closure 簽章三處，typealias 不在其中；單一參數的函式簽章已由 ios-dev-kit 2026-09-26 更新改為要斷行，不再是例外。取代 Claude 先前「單一參數的 typealias 比照函式簽章維持一行」的解讀 |
| 無參數的函式宣告超過 100 字元 | 維持一行，不斷行 (沒有參數可換行，也不在 `)` 後斷行) | `formatting.md`「參數與引數對齊」只規範有參數的簽章，沒有涵蓋無參數的情況；使用者 2026-09-26 看 `makeSaveFailureFixture()` (110 字元) 時裁決比照無參數 typealias |
| 單元測試方法命名 | 依 ios-dev-kit 3.1.0 `file-templates.md` 的 `<方法或行為>_<情境>_<預期>`：第一段照抄方法名或 Action 名 (英文 lowerCamel)，情境與預期用正體中文。本 change 新寫的測試與改到的既有測試檔都現在改名 (其餘寫法與排版仍在第 6 組整檔修正)；之後才被本 change 改到的測試檔，改到時一併改名；沒碰到的測試檔不改 | 使用者 2026-09-26 裁決，推翻 `apps/ios/CLAUDE.md` 舊的「測試方法名稱維持單段 lowerCamel」(已刪除)；既有測試檔的改名時機同日追加裁決提前 |
| extension 內的小分類 MARK (`// MARK: 工廠` 這類不帶 `-` 的) | 移除，只保留 `formatting.md` 的 `// MARK: - <區名>` 分區；長的 extension 需要分組時改成拆檔 | 使用者 2026-09-26 裁決；ios-dev-kit 樣板都沒有這種寫法，`formatting.md` 規定不自創分區名稱 |
| 裝 closure 的依賴 struct 建構呼叫 (Service `Self(` 起) | 建構 Service／Client／Store／Repository 這類裝 closure 的 struct，只要引數含 closure，一律換行：型別名 `(` (或 `Self(`) 與 `)` 各自一行，每個引數一行，即使只有一個 closure 且接成一行不超過 100 (例如 `OpenSettingsClient(open: {})` 也要換行)。不限檔案：`+Dependency`、`+Preview`、`App/Testing/` 的替身、測試的覆寫都適用。`*Service+Dependency.swift`／`+Preview.swift` 的 `Self(` 建構即使引數是 `unimplemented(…)` 也換行 | 使用者 2026-09-26 看 `ExchangeRateService.testValue` 時裁決 `Self(` 一律換行；2026-09-27 看 `BLUITestSettingsStore.makeSettingsStore` (Codex 依 `CALL1` 接成一行) 時擴大為通則。這是 3.1.0「未達斷行條件寫在同一行」的專案例外，checker `CALL1` 豁免、`SELF1` 抓單行寫法 |
| TCA 測試只有 `send` 時的 `// Then` | `send` 連同它的狀態 closure 都算 When；`// Then` 不寫進 `send` 的 closure，而是在 `send` 之後空一行寫 `// Then`，再以 `#expect(store.state.x == 值)` 斷言關鍵結果 (有 `receive` 時照舊，`receive` 放 Then)。三個標記寫在同一縮排層級，不寫進 `send` 或 `do`／`catch` 的 closure (整個本體包在 `withDependencies` 等 closure 內時，三個標記一起在 closure 內) | `tca-architecture.md`「`send` 為 When、`receive` 與 `#expect` 為 Then」沒涵蓋只有 `send` 的測試；使用者 2026-09-26 看 `CampaignFeatureTests` 時裁決，`OrdersFeatureTests` 既有把 `// Then` 寫進 closure 的寫法一併改 |
| 父層測試送出子層動作時，測試名稱第一段的 Action 層級 | 寫受測 Feature 自己的 Action case (最外層)，例如 RootFeatureTests 送 `.lookupManagements(.element(id:, action: .saveButtonTapped))` 時寫 `lookupManagements_`；子層動作寫進情境段。`view` 分組不算一層，`.view(.task)` 寫 `task_` (ios-dev-kit `tca/FeatureTests.swift` 樣板範例)。`binding` 寫 `binding_` | ios-dev-kit 只寫「照抄 TCA 的 Action 名稱」，沒涵蓋巢狀 Action；使用者 2026-09-27 裁決，理由是與受測 Feature 的 `core` switch case 對得上 |
| 前置狀態要跑過 reducer 才能得到時的 Given | 能直接設進 `initial` 的前置狀態就直接設 (例如 `initial.settleConfirmation = …`)；必須跑過 reducer 或 effect 才有的狀態 (例如先讓一次寫入失敗)，Given 可以 `send`／`receive`，並寫出完整狀態變化。When 只留受測的那一次 `send` | ios-dev-kit「`send` 為 When、`receive` 與 `#expect` 為 Then」沒涵蓋前置流程；使用者 2026-09-27 裁決，與第 16 批的處理一致 |
| 覆寫父類別方法的分區 | 比照 protocol 遵循：獨立一個 `extension`，MARK 用父類別名稱 (例如 `// MARK: - URLProtocol`)，位置在 Internal Method 之後、Private Method 之前；不寫在型別本體 | formatting.md 只規定「型別本體只放 stored properties 與 Init」，沒涵蓋 class override；使用者 2026-09-27 看 `MockURLProtocol` 時裁決 |
| 第 6 組測試檔整檔修正的時機 | 提前到 task 4.3 之後、4.4 之前做：本 change 改到的全部測試檔整檔修到合規 (GWT 深層結構、鐵則 3 強制解包、`$0` 規則、guard else、前置狀態直設等)，先補 checker 規則再逐檔嚴格審查；production 檔仍依 6.1、6.2 | 使用者 2026-09-27 看 task 4.3 審查列出三個測試檔數十處 checker 抓不到的既有違規時裁決；OrdersFeatureTests 的「寫入失敗後重新載入」測試在 Then 呼叫 `reloadOrders` (內含 `send(.task)`) 一併重構成 Given 失敗流程、When `send(.task)`、Then `receive` |
| 只有 `send` 的測試，關鍵結果是依賴被呼叫的紀錄 | Then 以 `LockIsolated` 紀錄斷言關鍵結果 (例如 `#expect(saved.value == 快照字面值)`) 即符合「Then 段要有自己的斷言」，不另補重複 `send` closure 狀態變化的 `#expect(store.state…)`；關鍵結果是狀態時才寫 `#expect(store.state.x == 值)` | `tca-architecture.md` 的範例只示範狀態斷言；使用者 2026-09-27 看 `SettingsFeatureTests` 審查時裁決 |
| 測試 helper 收 closure 再轉交給 `withDependencies` 時的 `$0` | 比照 `withDependencies`：多行 closure 仍可用 `$0` (參數就是 `DependencyValues`)，不強制具名 | `coding-style.md` 的 `$0` 例外只點名 `withDependencies`；使用者 2026-09-27 看 `CampaignReminderFailureTests.makeStore` 時裁決 |
| 賦值 `=` 之後斷行 | 禁止。`=` 不放行尾：右側有括號就在括號內斷 (`destination = .rename(` 換行放引數，`)` 單獨一行)；沒有括號就在其他運算子之前斷 (例如三元運算的 `?`／`:` 放續行行首)。checker `OPEOL` 守門，改到的檔整檔修 | `formatting.md`「在逗號之後或運算子之前斷行，運算子放續行行首」與「避免在 `=` 之後斷行把 `{` 移到續行」都沒點名一般賦值；使用者 2026-09-27 看 `RootFeatureTests` 審查時裁決 |
| `OrdersFeatureTests` 的「寫入失敗後重新載入」測試 (批次狀態、刪除、編輯儲存、訂單狀態、收款狀態共 5 條) | 失敗的寫入改用 `OrderServiceTests.makeSaveFailingService(orders:)` 產生的正式 Service (真的資料庫、save 時失敗)，重新載入讀同一個資料庫，讓測試從畫面層守住「寫入失敗不落盤」；結構照「Given 跑失敗流程、When `send(.task)`、Then `receive`」 | 原寫法的失敗寫入是直接丟錯的替身、不碰資料庫，「沒留下半套資料」恆真；使用者 2026-09-27 看 20d 審查時裁決 |
| 與其他測試重複的測試 | 刪除：只靠「覆寫另一個 closure 證明沒被呼叫」區分的測試 (testValue 的 `unimplemented` 已守住)，以及 Given／When 與另一條相同、Then 只拿實際值互比的測試；理由搬進保留那條的 `- Note:` | 使用者 2026-09-27 裁決 (Orders 3 條、Root 1 條) |
| closure 屬性的 typealias 與巢狀型別撞名 | 巢狀型別改名，讓 typealias 維持屬性名稱首字大寫：`BiometricAuthService` 的巢狀 enum `BiometryType` 改名 `BiometryKind`，`biometryType` 的 typealias 為 `BiometryType`；不另取 `BiometryTypeProvider` 這類後綴，也不改 closure 屬性名稱。checker `TANAME` 守門 | `tca-architecture.md`:388 規定 typealias 名稱為屬性名稱首字大寫，沒涵蓋撞名；使用者 2026-09-28 看 task 4.4 審查時裁決 |
| 只有一個呼叫點的獨立演算法 | `apps/ios/CLAUDE.md`「不為了單一呼叫點抽出 helper method」只管為單一呼叫點抽出的小段邏輯 (例如只被一個 computed property 使用的格式化)；有自己輸入輸出、超過約 15 行的獨立演算法 (例如引數切分器、lexer 內的分隔符判斷) 可以獨立成函式或 local function。一兩行就能寫完的仍要寫回呼叫端 | 使用者 2026-09-29 看 task 5.2 掃描測試審查時裁決；task 7.1 寫進 `apps/ios/CLAUDE.md` |
| 掃描測試的自我案例範圍 | 只保留有實際根據的案例：spec 規定的範例與情境、本 change 實際清掉的寫法、repo 現有且可能誤報的寫法、實作過程真的踩到的事件、規則例外的邊界。repo 從未出現的語法 (泛型下標、`?[X.self]`、CRLF、`static nonisolated(unsafe)`、`static let testValue` 等) 不設案例；掃描器裡已寫好的對應處理保留，不守門。之後覆核只修違反規範或對現有程式碼會誤報、漏報的項目，不再為理論邊界加程式與案例 | 使用者 2026-09-29 看 task 5.2 八輪修正後裁決「凍結範圍、移除為了寫而寫的測試、程式保留只刪案例」 |
| 只驗 `BindingReducer` 的 binding 測試 | 保留，當作「body 有接 `BindingReducer()`」的接線守門，doc 寫明守的是接線 | 使用者 2026-09-27 裁決 |
| 測試覆寫的 closure 何時先宣告成 typealias 常數 | 只有會失敗的 closure 先以 typealias 宣告成常數再注入 (常數不標 `throws(E)`，`throw` 用前導點)；回傳特定值、不會失敗的 stub 直接寫在 `withDependencies` 裡 (照 `tca/FeatureTests.swift` 樣板) | `tca-architecture.md`「失敗或特定回傳的 closure 先以 typealias 宣告成常數」與樣板直接賦值 stub 不一致；使用者 2026-09-27 裁決以樣板為準，已請 ios-dev-kit 修 reference 原文 |
| closure 的 `$0` 與多行 (ios-dev-kit 3.6.0，formatting.md:498、:502) | 單一表達式、單一參數的 closure 一律 `$0`，跨行、巢狀都一樣；多敘述或多參數具名；內層要用外層參數時外層具名。修改 `inout` 值的 closure (`send`／`receive`／`withDependencies`／`withLock`／`withValue`) 多敘述也用 `$0`。寫在另一個 closure 內的 closure 一律多行，SwiftUI 的 View builder、modifier、action closure 不論位置一律多行 | 使用者 2026-09-27 陸續裁決，ios-dev-kit 3.6.0 發布；checker `NAMED1`、`NESTSL`、`SWIFTUISL`、`DOLLARML` (含 inout 例外) 守門；本 change 新建的 production Service 檔也要符合，列入第 6 組處理 |

Claude 自行定案的五項：拆成一型別一檔後不再加樣板的 `// MARK: - Protocol`／`// MARK: - Implementation` (一檔已只有一個型別，失去分隔作用)；`BuyLedgerDatabase+Preview` seed 失敗的 `fatalError` 保留並以 `//` 說明「記憶體資料庫 seed 失敗是程式錯誤」；測試以 block 式 `NotificationCenter.addObserver` 同步計數 save 保留並以 `//` 說明 (改 AsyncSequence 會引入排程時序)。另外兩項在 task 6.1 定案：`App/Testing/BLUITestHarness` 建立 container、資料夾與刪檔失敗的 `fatalError` 保留，並以 `//` 說明 UI 測試環境建不起來時直接中止，讓失敗立即浮現；只有註解、沒有任何敘述的 `catch` 算空的 catch，改成 `try?` 並在同一行註明失敗可忽略的理由，而 `catch { return }` 這類有敘述的 catch 不在 coding-style「空的 catch、只 print 的 catch」明文內，不動。

### 驗收沿用既有規矩

- 單元測試與 iPhone UI 測試固定用 iPhone 17 iOS 26.5 模擬器 `DDAA3311-B464-4DD3-96B8-360B26AF1929`，iPad UI 測試固定用 iPad Air 11" (M4) `6B65ED1C-3C2E-42BA-B1E7-08F606F175C5`。UI 回歸用 `BuyLedgerUITests` scheme，跑前確認 `set-appearance` 為淺色。
- 基準與每次回歸的測試數、通過數、失敗清單、result bundle 絕對路徑寫在 `tasks.md` 對應 task 行下方；只存在對話裡不算數。
- 方法層 `-only-testing` 一律帶 `()`；變異驗證要確認實際執行數大於 0；回歸 result bundle 的時間必須晚於最後一次 Swift 寫入 (變異還原也算寫入)。
- 已知 snapshot 像素雜訊 (`orderEditView_合併訂單情境_符合基準圖`、`quoteView_非零試算輸入_顯示成本與建議售價`、`ordersCompactView_多選模式_顯示勾選與工具列`) 轉紅時，以方法層單獨重跑確認，不重錄基準圖。
- 測試數對帳：每個被改寫或刪除的測試檔，在 `tasks.md` 列出「移除 N 條 (列名)、新增 M 條」，與基準差額逐條對上。

### 驗收後追加的三項修正 (使用者 2026-09-30 裁決)

第 8 組驗收時回報的三項遺留，使用者裁決在本 change 內處理，排為第 9 組：

- **CI 保留複製 `GoogleService-Info.example.plist`，只改正文件理由**：
  - 使用者原本裁決「不複製」。實測後推翻這個前提，改為保留：移開本機設定檔後 build 失敗，錯誤來自「Run Script: Crashlytics Symbol Upload」的同步驗證，訊息為 `Could not get GOOGLE_APP_ID in Google Services file from build environment`。
  - 原本寫的理由是「以 App 為宿主的單元測試會在 `FirebaseApp.configure()` 崩潰」。task 1.1 讓單元測試略過 Firebase 初始化之後，這個理由已不成立；task 7.2 暫時改寫成「一般啟動會崩潰」，但那不是 CI 需要這份範本的原因。
  - `.github/workflows/ci.yml` 與 pbxproj 的 Crashlytics build phase 都不動。
- **本機單元測試 target 關閉平行執行**：
  - 崩潰報告 (`~/Library/Logs/DiagnosticReports/BuyLedger-*.ips`) 的崩潰執行緒都在 SwiftData `save`，由 `KeyedEncodingContainer.encodeNil` 丟出 `NSException`。同一時間有其他執行緒正在操作另一個版本化 schema 的容器。
  - 並行的組合是多條 `SchemaMigrationTests` (V15、V16、V17)，或 `SchemaMigrationTests` 與 `OrderServiceResidueTests`。這是 SwiftData 在同一 process 內並行使用多個版本化 schema 的問題，測試端只能讓它們不並行。
  - CI 本來就帶 `-parallel-testing-enabled NO`，只有本機預設會平行執行。修法是在 `BuyLedger.xctestplan` 的 `BuyLedgerTests` 加 `"parallelizable" : false`。
  - 序列執行完整單元回歸約 2 分鐘 (task 8.2 實測)，速度代價可以接受。
  - 替代方案：
    - 在 `SchemaMigrationTests` 加 `.serialized`：只能讓同一個 suite 內序列執行，擋不住跨 suite 的並行，不採用。
    - 以全域鎖包住所有 SwiftData 測試：要動每個測試檔，不採用。
- **補 `TestSuiteIntegrityTests` 的四個守門漏洞** (task 6.5 審查登記的 R1 至 R4)：
  - R1：三條守門都斷言掃到的 `.swift` 檔數大於 0，避免路徑錯誤時「掃不到就通過」。對應 test-guard-effectiveness「A guard whose subject no longer exists is repaired, not left passing」。
  - R2：`default:` 與 `return .none` 分在兩行也要命中。這正是 `ios-unit-tests.md` 點名禁止的規避寫法。
  - R3：窮舉守門把 `withExhaustivity(.off)` 也算入關閉處。對應同一 spec 的「The relaxation count cannot grow」。
  - R4：憑證守門納入成員存取的內插 (如 `\(endpoint.url)`)。
  - 以 task 8.5 當時的程式碼模擬這三條新比對：App target 281 檔、測試目錄 138 檔都是 0 筆，所以補上後現有程式碼不會轉紅。
  - 只補強既有 3 條測試，不新增測試 (測試數 0／0)。
- **範圍**：
  - 可改：`BuyLedger.xctestplan`、`TestSuiteIntegrityTests.swift`、`.claude/rules/ios-firebase-privacy.md`、`.claude/rules/ios-unit-tests.md`、`apps/ios/README.md`。
  - 不改：`ci.yml`、`BuyLedgerUITests.xctestplan`、pbxproj、SwiftData 本身的並行問題、`TestSuiteIntegrityTests` 以外的守門。

### verify／review 之後的補強 (使用者 2026-09-30 裁決)

`/spectra-verify` 與 `/spectra-review` 回報後，使用者裁決在本 change 內處理下列項目，排為 task 9.5 至 9.9：

- **重錄 `orderEditView_一般既有訂單_符合基準圖`、`orderEditView_長訂單識別碼_顯示短識別碼` 兩張基準圖**：
  - 這是 Non-Goals「不動 snapshot 基準圖」的明確例外，只限這兩張。
  - 依據：乾淨的 HEAD 在同一台 DDAA3311 上也是兩條都失敗 (見 task 8.2 的 HEAD 對照紀錄)。差異在 DatePicker 的日期格式，與本 change 無關。
  - 重錄後要以像素差異確認，只有日期欄位的區域不同。
- **補「未覆寫的 Service 被呼叫就讓測試失敗」的直接測試**：
  - 對應 test-guard-effectiveness 的兩個 scenario，目前都沒有直接測試。
  - 以 `withKnownIssue` 斷言 issue 內容帶出 `OrderService.fetchOrders`；另一條只覆寫 `saveOrder` 時，issue 要帶出 `OrderService.removeOrder`。
  - 依賴規範掃描另加一條「App target 不得出現 `.modelContainer(`」，對應 persistence-failure-recovery「The app scene does not attach the production container」。
- **測試範例值對齊 spec**：
  - 並行建立與解碼失敗兩條測試的訂單識別值改為 `order-001`。
  - store 隔離的 sidecar 測試改為檢查 `BuyLedger.store-wal`。
  - 只改測試資料，不改行為。
- **補兩條持久化錯誤測試**：`CampaignService.saveCampaign` 儲存失敗、`CurrencyMetadataService.refreshIfStale` 快取寫入失敗。
  - 以 `MockBuyLedgerDatabase` 的 `.saveFailureAfterBody` 搭磁碟 store 觸發真的 save 失敗。
  - 斷言錯誤 case 與底層錯誤的 domain、code，並斷言資料維持原狀。
  - spec 範例寫的是唯讀 store 與磁碟已滿，這兩種情況在測試中造不出來，改以 save 驗證失敗觸發同一條錯誤路徑。
- **不處理，登記**：
  - Category、OrderSource、ReconciliationStatus 三個 Service 手寫相同的讀取、新增、刪除邏輯：留到第 5 至 8 步搬遷時一併處理。
  - 「Application Support 查找失敗」：原登記為不補測試，已由「verify 第二輪之後的補強」取代。
  - `mergeOrders` 的 `consumedOrderFetcher` 多載：review 認為沒人使用，但 `OrderServiceTests+MergeFailureMapping` 以它注入失敗讀取，屬刻意保留的測試接口，不刪。

### ios-dev-kit 3.8.0 套用 (2026-09-30 發布)

ios-dev-kit 3.8.0 在第 9 組完成後發布，排為第 10 組，套用到本 change 新增與修改的 Swift 檔：

- **多行陣列、字典字面值的最後一個元素後面一律加逗號，單行不加** (formatting.md:37)。checker 新增 `TRAILC` 守門，掃描到 24 處。
- **唯一引數是陣列或字典字面值、要斷行時一律與括號貼合成 `([` … `])`**，兩個以上引數時不用貼合 (formatting.md:97)。checker 新增 `HUG` 守門，本 change 為 0 處：`@Test(arguments: [`、`Schema([` 原本就是貼合寫法；`#expect(x == [` 的引數是運算式，不屬於字面值引數。
- **只 import 用到的模組，以 build 為準** (formatting.md:491)。這條推翻 task 8.1「樣板內建的 `import Foundation` 視為基準保留」的判定。
  - 做法：逐檔拿掉 `import Foundation` 後 build，報「missing import of defining module 'Foundation'」或找不到 Foundation 型別的檔補回。
  - 專案開了 `MemberImportVisibility`，只用到 Foundation 的擴充成員也算用到。
- **驗證範圍** (使用者 2026-09-30 指示)：只跑改到的測試類別，不跑完整回歸。
- **不處理**：
  - `AISummaryFeature.swift` 的 `.merge(` 兩個引數可接成一行 (`CALL1`)。這來自使用者 review 時 stage 的改動，由使用者決定。
  - Foundation 以外的其他 import：本批只處理 kit 這次點名的 `import Foundation`。

### verify 第二輪之後的補強 (使用者 2026-09-30 裁決)

重跑 `/spectra-verify` 後剩下的項目，使用者裁決在本 change 內處理，排為第 11 組：

- **Application Support 解析改為可注入並補測試**：
  - `BuyLedgerDatabase.StoreLocation.applicationSupport` 改成帶解析目錄的 closure：`applicationSupport(resolveDirectory: @Sendable () throws -> URL)`。
  - 真正呼叫 `FileManager.default.url(for: .applicationSupportDirectory, …)` 的程式移到 `BuyLedgerDatabase+Dependency` 的 `liveValue`，那裡是依賴註冊處。
  - 測試傳入會丟錯的 closure，斷言丟出 `PersistenceRecoveryError.directoryResolutionFailed(underlying:)`，且底層錯誤的 domain 與 code 不變。
  - 取代「verify／review 之後的補強」一節「不補測試」的登記。
  - `.applicationSupport` 只有 `+Dependency` 一個呼叫端，`StoreLocation` 沒有遵循 `Equatable`，所以不必放寬存取層級，也不必改 init 的呼叫端。
- **風格驗收條文逐筆列出允許的延後項** (見 Implementation Contract 的驗收條文)。
- **spec 範例改成測試造得出來的失敗**：persistence-error-contract 的 5 個範例原本寫唯讀 store、磁碟已滿、無效設定，改為「SwiftData 因關聯數量超過上限拒絕儲存」與「store 的父路徑是既有檔案」。
  - 「Saving a campaign that SwiftData rejects」的 THEN 原本另要求 localized description 相同，同時刪除這項要求，只留 domain 與 code。測試無法另外取得 SwiftData 回報的原始錯誤來比對 description，而 domain 與 code 才是錯誤合約的內容。
- **小修正**：
  - `OrderServiceTests+WriteFailures` 的訂單儲存失敗、`OrderServiceTests+Reads` 的讀取失敗，補上底層錯誤 domain 與 code 的斷言。
  - `PaymentMethodServiceTests+ApplyEdit` 的缺少訂單案例，識別值改為 spec 的 `order-404`。
  - proposal 影響清單刪除沒有改動的 `PersistenceStoreQuarantine.swift` 與 `LayerBoundaryTests.swift`；文件清單改成一個路徑一行。
- **驗證範圍**：只跑改到的測試類別 (使用者指示)。

## Implementation Contract

**可觀察行為**：

- 使用者操作層面，除了下列兩項，所有畫面行為與文案不變：
  - 寫入失敗後，對同一筆資料的後續操作不再把失敗的變更寫進資料庫：再刪一次會真的刪除、同 id 建立會被撞號擋下、改開團名稱不帶入失敗的欄位。
  - 主檔／開團的並發新增改為串行，不再可能插入同名兩筆。
- Preview 中主檔、訂單、開團共用同一個 in-memory 資料庫。
- 單元測試 host 啟動時不建立根畫面、不開啟正式 store。

**介面形狀**：

```swift
protocol StorageFailureWrapping: Error {
    static func storage(_ error: PersistenceError) -> Self
}

protocol BuyLedgerDatabaseProtocol: Sendable {
    func read<Value: Sendable, Failure: Error>(
        _ body: @Sendable (ModelContext) throws(Failure) -> Value
    ) async throws(Failure) -> Value

    func write<Value: Sendable, Failure: StorageFailureWrapping>(
        _ body: @Sendable (ModelContext) throws(Failure) -> Value
    ) async throws(Failure) -> Value

    func quarantineStore() async throws(PersistenceRecoveryError) -> URL?
}

actor BuyLedgerDatabase: BuyLedgerDatabaseProtocol {
    enum StoreLocation: Sendable {
        case applicationSupport(resolveDirectory: @Sendable () throws -> URL)
        case directory(URL)
        case inMemory
    }

    init(modelContainer: ModelContainer, storeLocation: StoreLocation)
}

extension DependencyValues {
    var buyLedgerDatabase: any BuyLedgerDatabaseProtocol { get set }
    var httpClient: any HTTPClientProtocol { get set }
    var userDefaultsStore: any UserDefaultsStoreProtocol { get set }
    var appConfigurationStore: any AppConfigurationStoreProtocol { get set }
    var orderService: OrderService { get set }
    // 其餘 16 個 Service 同名規則
}
```

- `quarantineStore()` 依 `storeLocation` 決定：`.inMemory` 回 `nil` 且不碰檔案系統；`.applicationSupport` (production `liveValue`，不論啟動是否降級) 在呼叫時解析 Application Support，失敗拋 `directoryResolutionFailed`，行為與現行 `PersistenceStoreQuarantineClient.liveValue` 相同；`.directory(URL)` 對指定目錄執行同樣的搬移。位置由建立者明確給定，不從 container 推斷，所以降級後 container 是 in-memory 仍能隔離磁碟上的 store。
- Service 的 closure 簽章 (參數、回傳、typed throws 型別) 除了改名與刪除之外逐一不變，只是改用 typealias 宣告。刪除的 closure 見 Service 配置表。
- Feature 取用一律寫 `@Dependency(\.orderService) private var orderService` (同行；專案規則優先於 `tca/Feature.swift` 樣板的換行寫法)。

**失敗模式**：

- Database 的 `write` 在 closure 或 `save()` 失敗時丟棄 context，拋出 `Failure`；`save()` 失敗包成 `Failure.storage(.saveFailed(underlying:))`。
- 語意錯誤 (`identifierCollision`、`orderNotFound`、`emptyCodeList`) 型別與攜帶的值不變。
- 測試中呼叫未覆寫的 Service closure 會以 `unimplemented` 回報 issue，讓該測試失敗。測試中存取未覆寫的 Database／Client／Store 會以 swift-dependencies 的 live dependency 存取失敗回報。

**驗收條件**：

- 完整單元回歸全綠，或只剩已知 snapshot 雜訊 (單獨重跑轉綠)。測試數與 task 0.1 基準的差額逐條對帳。
- iPhone 與 iPad UI 主回歸各自與 task 0.2 基準相同，或只剩已知雜訊。
- task 0.3 的四個殘留情境在改動前全紅，task 3.2 的同組情境在改動後全綠，變異驗證可轉紅。
- `DependencyConventionScanTests` 四條規則 (含第 2 條的「Service 不依賴 Service」) 全綠，且各自完成變異驗證。
- `reference/style_checks.py` 對本 change 全部新增與修改的 Swift 檔整檔檢查，結果除了不計失敗的 `WSTR`、`WCL`、`WSIG`、`LENX` 之外，只允許下列已登記的延後項：`MKNX` 6 筆 (`CampaignFeature.swift` 3、`OrderEditFeature.swift` 2、`OrderMergeFeature.swift` 1，`extension <Feature>.State` 移回本體留第 5 至 8 步)、`LEN` 1 筆 (`PaymentMethodCorrectionFeatureTests.swift`，拆檔留第 5 至 8 步)、`CALL1` 1 筆 (`AISummaryFeature.swift` 的 `.merge(`，使用者 2026-09-30 裁決保留)；獨立 style agent 的審查清單處置為 0，或逐筆附使用者裁決。
- 全庫 grep：`Repository` 型別名 0 處 (歷史文件與 `@trace` 除外)、`PersistenceContainer.shared` 0 處、`@Dependency([A-Z]` 0 處。
- task 0.4 與 task 8.4 的讀取延遲量測：500 筆訂單 `fetchOrders` 的中位數，改動後不超過改動前的 2 倍；超過就停下來回報。
- `spectra validate` 通過；`git status` 全部落在下方範圍內。

**範圍邊界**：

- **可改**：proposal Impact 列出的檔案與目錄 (含第 9 組追加的 `BuyLedger.xctestplan`)；design「測試檔清單」的 38 個測試檔；新增的 `StorageFailureWrappingTests.swift`、`ResidueProbeModels.swift`；由 `PersistenceError.swift` 拆出的 `Core/Persistence/{OrderPersistenceError,PaymentMethodPersistenceError,CurrencyMetadataPersistenceError,PersistenceRecoveryError}.swift` (使用者 2026-09-26 要求提前拆檔)；`OrderEditFocusTests.swift`；`SnapshotTests*.swift` (只限為了讓掛 `.task` 的畫面在 snapshot 中覆寫 Service，不得改基準圖)；`LayerBoundaryTests.swift`；`TestSuiteIntegrityTests.swift`；新增的 Service、Store、Client、Mock、測試檔。
- **不可改**：schema 與 `BuyLedgerSchema.swift`、生成檔、`.xcstrings`、snapshot 基準圖、UI 測試 identifier 與 page object (UI 測試不引用依賴型別名)。
- **寫法與排版修正只限本 change 本來就會改到的檔案**，不因為要修排版而多碰其他檔。
- **遇到範圍外必須改動的檔案就停下來回報**，不要自行擴大。

**測試檔清單** (2026-09-25 以型別名 grep 實測)：AISummaryFeatureTests、APIErrorMappingTests、AppConfigurationTests、AppLockFeatureTests、BiometricAuthClientTests、CalendarReminderTests、CampaignFeatureTests、CampaignPersistenceTests、CampaignReminderFailureTests、CurrencyMetadataCacheTests、ExchangeRateClientTests、FxFeatureTests、HTTPClientTests、LookupManagementFeatureTests (含 +AlertTiming、+Failures、+Forms、+PaymentMethodCorrection)、NameLookupPersistenceTests、OllamaClientTests、OrderEditFeatureTests、OrderMergeFeatureTests、OrderPersistence+LookupTesting、OrderPersistenceTests (含 +LookupRename、+LookupRenameFailures)、OrdersFeatureTests、OrdersLoadStateTests、PaymentMethodCorrectionFeatureTests、PaymentMethodPersistenceTests、PersistenceFailureFeatureTests、PersistenceRecoveryTests、QuoteFeatureTests、RecordDecodingTests、RootFeatureTests、SchemaMigrationTests、SettingsFeatureTests、SettingsStoreTests。

## Risks / Trade-offs

- **[Risk] `@Sendable` closure 以非 `Sendable` 的 `ModelContext` 為參數，可能被 Swift 6 拒絕** → task 1.3 先做最小可編譯形狀；不行就停下來，以 `sending` 或 `isolated` 參數的替代寫法回報使用者再決定。
- **[Risk] 每次讀取都建立 `ModelContext` 可能讓大量讀取變慢** → 百筆規模下估計可忽略 (推論)。task 0.4／8.4 以 500 筆量測中位數比較，超過 2 倍就停下來回報。
- **[Risk] 讀取也串行化到 Database actor，長寫入期間讀取要排隊** → 現有寫入都是毫秒級的同步交易 (推論)，由 UI 主回歸與量測確認沒有可見延遲。
- **[Risk] UI 測試 harness 誤用 `$0.xxxService` 當底座而連到正式 store** → design 明文禁止；有 seed 資料的 UI 測試 (主檔管理、訂單詳情) 在錯用時會看不到 seed 而轉紅，可順帶守住。
- **[Risk] snapshot 中掛 `.task` 的畫面 (`OrderEditView`、`QuoteView`) 可能在渲染時呼叫 Service，觸發 `unimplemented`** → 在 snapshot 的 `withDependencies` 補覆寫，不改基準圖；若是渲染結果改變則停下來回報。
- **[Risk] 改動檔案數大 (估計超過 120 檔)，一次審查不易** → 依批次 (主檔、訂單與開團、網路與設定、系統功能) 各自編譯並跑相關測試，每批結束時完整單元回歸必須全綠才進下一批。
- **[Trade-off] 跨 Feature 的 Service 暫留 Core** → 登記為過渡例外並排程，不在本 change 解決。
- **[Trade-off] 系統 framework 不抽 Client** → Service 的 `liveValue` 直接呼叫 framework。Service 測試無法注入 Mock，只能測 Feature 端的覆寫，與現況相同。

## Migration Plan

依 expand → migrate → contract 分段，每段結束時可編譯，而且相關測試與完整單元回歸全綠：

1. **基準 (0.x)**：單元與 UI 基準、殘留重現、讀取延遲量測。
2. **擴充 (1.x)**：`RuntimeEnvironment` 與單元測試 host 防護、`StorageFailureWrapping`、`BuyLedgerDatabase` 與 Mock、`HTTPClient` 的 Client 化、兩個 Store。新型別先與舊型別並存。
3. **遷移 (2.x 至 4.x)**：主檔 Service → 訂單與開團 Service (含殘留守門) → 匯率、幣別、AI 摘要與設定 Service → 系統功能 Service。每批一次改完該組的呼叫端、UI harness 與測試，並刪除被取代的舊型別。
4. **收尾 (5.x)**：移除 `PersistenceContainer.shared`，加上依賴規範掃描守門。
5. **既有檔寫法與排版 (6.x)**：遷移完成後，對被改到的既有檔整檔修正。
6. **文件 (7.x)** 與 **驗收 (8.x)**。

回復方式：未 commit 前可以整批捨棄。本 change 不改 schema，store 內容與舊版完全相容，所以沒有資料遷移風險。
