---
paths:
  - "apps/ios/BuyLedgerTests/**"
---

# iOS 單元測試

- **單元測試放 `apps/ios/BuyLedgerTests/`，檔名對應被測型別或功能** (如 `OrdersFeatureTests.swift`)。
- **Swift Testing 的方法層 `-only-testing` 必須帶完整的參數列**：無參數寫 `()`，例如
  `BuyLedgerTests/OrderServiceTests/fetchOrders_讀取清單_不載入照片位元組()`；省略括號會安靜地選不到方法。
    - 參數化測試 (`@Test(arguments:)`) 要寫出參數標籤，例如 `refreshIfStale_快取年齡在七天門檻前後_依門檻決定是否刷新(ageInSeconds:expectedRefresh:)`；只寫 `()` 同樣會選到 0 條。
- **選擇性測試與變異驗證必須確認實際執行數大於 0**：`0 tests executed` 不是通過，不能用成功退出碼判定測試有效。
- **測試替身的共享可變狀態使用 `LockIsolated`**：同步記錄呼叫與取消訊號，避免自訂 actor 或 class box 帶來不必要的隔離與排程問題。
- **非同步結果不得以 `Task.yield` 輪詢**：用 `TestStore.receive`、`finish` 或注入的 clock 等待明確事件，避免排程快慢造成偶發假失敗。

## 依賴與替身

- **Service 的 `testValue` 全部是 `unimplemented`，測試只覆寫會被呼叫的 closure** (如 `$0.orderService.saveOrder = { _ in }`)：未覆寫的 closure 被呼叫會回報 issue 讓該測試失敗；不為了讓測試過而補滿所有 closure。
    - 以 `XxxService.testValue` 為底再覆寫可行，底座同樣是 `unimplemented`。
- **`BuyLedgerDatabase`、`HTTPClient`、`UserDefaultsStore`、`AppConfigurationStore` 沒有 `testValue`**：測試中存取未覆寫的一律回報失敗，要用就注入 Mock。Mock 放 `BuyLedgerTests/Mocks/`。
- **Service 測試先注入下層的 Database／Client／Store (或其 Mock)，再取得 `liveValue`**：`withDependencies { $0.buyLedgerDatabase = database } operation: { OrderService.liveValue }` (參考 `OrderServiceTests.makeService(database:)`)。
    - 不在另一個 `withDependencies` 的準備 closure 內取 `.liveValue`：`@Dependency` 在 `liveValue` 建立時擷取當下的 `_current`，不是正在準備的 `$0`，會拿到 live 依賴。
- **驗證「寫入失敗不落盤」用 `MockBuyLedgerDatabase` 的 `.saveFailureAfterBody` 搭磁碟 store，不用直接拋錯的替身**：拋錯替身不碰資料庫，「沒留下半套資料」恆真。
    - `.saveFailureAfterBody` 要求容器 schema 含 `ResidueProbeModels` 的探測 model，磁碟 store 以 `ResidueProbeModels.makeDiskFixture` 建立 (參考 `OrderServiceTests.makeSaveFailingService(orders:)`)。
- **單元測試 host 不建立根畫面**：`BuyLedgerApp.init` 與 `AppLaunchConfigurator.configure` 在 `RuntimeEnvironment.isUnitTesting` 時直接略過；啟動時才會呼叫的依賴 (如 `SettingsService.load`) 若寫在略過條件之外，`unimplemented` 會把 issue 歸到隨機的測試。

## TCA TestStore

- **斷言由效果派送的 action 造成的變更前，先 `await store.receive(\.actionName)`**：`exhaustivity = .off` 搭 `store.finish()` 不保證 `.orderWriteFailed`、`.statusChangePersisted` 這類 action 已處理完。
    - 省略這步的斷言可能只是還沒跑到就通過，屬假測試；寫法參考 `CampaignReminderFailureTests`。
- **effect 鏈改變 `@Shared` 時，在 TestStore 第一次觀察到變更的斷言點核對共享狀態**：通常是觸發 effect 的 action 或其後第一個 `receive`，不要等到實際更新它的 `xxxResponse`；TestStore 會在斷言前處理 effect 派送的後續 action，若把預期延後，兩個斷言點都會出現 state mismatch (參考 TCA `SharingState.md` 的 Tests 節)。
- **純 `AlertState` 的 `.ifLet` 收到 `.presented` 動作後會自動清空該呈現**：清空發生在 `base._reduce` 之後，父層 reducer 仍讀得到該次呈現的值；窮舉測試依實際行為核對 `$0.xxx = nil`，不憑直覺增減。
- **`AISummaryFeature` 串流測試一律注入同一個 `TestClock`**：測試環境的 `\.continuousClock` 可能是 `ImmediateClock`，逾時計時器會搶在串流前結束。
    - `$0.continuousClock` 與串流替身共用該 clock 的 `sleep(for:)`，以 `advance(by:)` 推進；替身內不用 `ContinuousClock` 或 `Task.sleep`。
    - 測試 target 要明確連結 `Clocks` product，只靠 `ComposableArchitecture` 轉出可能在連結階段失敗。
    - 以 `AISummaryService.overallStreamDuration` 驅動上限，不新增 `DependencyValues` keyPath 當測試旋鈕。

## 跨測試共用狀態

- **測試直接改寫 `@Shared(.lookupCatalog)` 會污染同批次的其他測試**：`@Shared` 是 process 內共用，`BuyLedger.xctestplan` 又是字母序執行，外溢的狀態會讓排在後面的 snapshot 測試出現只在完整套件下重現、單獨跑卻通過的失敗。
    - 需要改寫主檔目錄的測試一律在隔離 storage 內建立 state：使用 `LookupCatalog.withIsolatedStorage`，根狀態測試另參考 `RootFeatureTests.makeIsolatedRootState` (以 `defaultInMemoryStorage = InMemoryStorage()` 建立)。
    - 症狀是「完整回歸紅、單獨跑綠」時先查這裡，不要改 snapshot 或重錄基準圖。
    - 測試 `UserDefaults` 相依 (例如 `UserDefaultsStore`) 時使用獨立 suite，測試前後清除 persistent domain，避免偏好值跨測試外溢。

## 錯誤斷言

- **錯誤型別不遵循 `Equatable`，斷言一律 `if case` 或 `switch` 比對 case**，不用 `#expect(throws:)` 比對整個值；需要驗證底層錯誤時斷言 `domain`、`code` 與 `localizedDescription`，不斷言物件身分。

## 守門測試 (`TestSuiteIntegrityTests`)

- **三條守門都移除整行註解後以整檔內容比對，並斷言掃到的 `.swift` 檔數大於 0**：掃描路徑失效時測試轉紅，不會因為掃不到檔案而通過。
- **測試目錄內關閉窮舉檢查恆為 0 處，`exhaustivity = .off` 與 `withExhaustivity(.off)` 都算**：`exhaustivityOffUpperBound` 與實際處數都是 0，只檢查總數、不檢查位置；斷言不全時補 `receive` 或明確覆寫依賴，不以關閉窮舉規避。
- **App target 內 `default: return .none` 恆為 0**：`default:` 與 `return .none` 之間隔空白、換行或行尾註解也會命中；不得用其他迂迴寫法規避 (如 `return Effect.none`)。
- **App target 的字串內插中，名稱或成員名稱含 `url`／`request` (不分大小寫) 的運算式恆為 0**：涵蓋 `\(endpoint.url)` 這類成員存取，這是憑證外洩契約的守門。
    - 屬子字串比對，先存成不含 `url`／`request` 名稱的區域變數再內插等迂迴寫法抓不到，仍要人工複核。

## 完整回歸

- **`BuyLedger.xctestplan` 的 `BuyLedgerTests` 關閉平行執行 (`"parallelizable" : false`)，不得改回平行**：同一 process 內並行使用多個版本化 schema 的容器 (`SchemaMigrationTests` 的舊版 schema 與其他 SwiftData 測試) 時，SwiftData `save` 會從 `KeyedEncodingContainer.encodeNil` 丟出 Objective-C 例外，整個測試 process 崩潰。
    - 再出現 `Crash: BuyLedger` 時，先查 test plan 是否被改回平行，以及崩潰報告 `~/Library/Logs/DiagnosticReports/BuyLedger-*.ips` 的崩潰執行緒。

## 效能測試 (`OrdersFeaturePerformanceTests`)

- **用 `ContinuousClock` 計時加顯式上限斷言，不用 `measure { }`**：XcodeBuildMCP 拆成 `build-for-testing` + `test-without-building` 執行，`.xctestrun` 讀不到 baseline，`measure` 恆為通過。
    - 門檻抓數量級退化 (約正常耗時的 6 倍)，不沿用舊 baseline 的 10 倍餘裕 (在此工具鏈下等同恆真)。
    - 已從 `BuyLedger.xctestplan` 排除，單獨跑用 `-only-testing:BuyLedgerTests/OrdersFeaturePerformanceTests`。

## Snapshot 測試

- **每個 snapshot 測試用 `TestDependencies.withFixedNow { ... }` 包住 view 建構與 `assertSnapshot`**，注入固定 `\.date`；測試內不直接呼叫 `Date()`。
    - baseline 在 `BuyLedgerTests/__Snapshots__/`，目前只有 iOS 393×852；record 流程見 `apps/ios/README.md`。
- **執行前的模擬器外觀設定見 `apps/ios/CLAUDE.md`；含 `.borderedProminent` 工具列按鈕的畫面的渲染方式見 `ios-design-system.md`**。
- **完整回歸偶發的 snapshot mismatch 先按已知雜訊處理**：目前已知測試為 `quoteView_非零試算輸入_顯示成本與建議售價`、`orderEditView_長訂單識別碼_顯示短識別碼`、`ordersCompactView_多選模式_顯示勾選與工具列`、`orderEditView_合併訂單情境_符合基準圖`、`orderEditView_一般既有訂單_符合基準圖`。
    - 兩種徵狀：**內容型**是整個文字標籤沒渲染出來 (如 `quoteView_非零試算輸入_顯示成本與建議售價` 的成本拆解，缺的標籤組合每次不同)；**像素型**是肉眼完全相同、差異只在導覽列區域且最大單通道差值個位數 (如 `orderEditView_一般既有訂單_符合基準圖`，實測 0.41% 像素、最大差值 2)。判斷像素型可用 PIL 比對 `ImageChops.difference` 的 bbox 與最大差值。
    - 逐條重跑時 Swift Testing 的方法層 `-only-testing` 必須帶 `()`，並從 xcresult 確認 `totalTestCount` ≥ 1；單獨重跑轉綠才可判定為渲染雜訊。
    - 已知清單外的失敗，或單獨重跑仍失敗，視為真回歸；不得重錄 baseline、放寬斷言或刪除測試。
