---
paths:
  - "apps/ios/BuyLedgerTests/**"
---

# iOS 單元測試

- **單元測試放 `apps/ios/BuyLedgerTests/`，檔名對應被測型別或功能** (如 `OrdersFeatureTests.swift`)。
- **Swift Testing 的方法層 `-only-testing` 必須以 `()` 結尾**：例如
  `BuyLedgerTests/OrderPersistenceTests/mergeOrders_sourceFetchFailure_removesInsertedOrder()`；省略括號會安靜地選不到方法。
- **選擇性測試與變異驗證必須確認實際執行數大於 0**：`0 tests executed` 不是通過，不能用成功退出碼判定測試有效。

## TCA TestStore

- **斷言由效果派送的 action 造成的變更前，先 `await store.receive(\.actionName)`**：`exhaustivity = .off` 搭 `store.finish()` 不保證 `.orderWriteFailed`、`.statusChangePersisted` 這類 action 已處理完。
    - 省略這步的斷言可能只是還沒跑到就通過，屬假測試；寫法參考 `CampaignReminderFailureTests`。
- **純 `AlertState` 的 `.ifLet` 收到 `.presented` 動作後會自動清空該呈現**：清空發生在 `base._reduce` 之後，父層 reducer 仍讀得到該次呈現的值；窮舉測試依實際行為核對 `$0.xxx = nil`，不憑直覺增減。
- **`AISummaryFeature` 串流測試一律注入同一個 `TestClock`**：測試環境的 `\.continuousClock` 可能是 `ImmediateClock`，逾時計時器會搶在串流前結束。
    - `$0.continuousClock` 與串流替身共用該 clock 的 `sleep(for:)`，以 `advance(by:)` 推進；替身內不用 `ContinuousClock` 或 `Task.sleep`。
    - 測試 target 要明確連結 `Clocks` product，只靠 `ComposableArchitecture` 轉出可能在連結階段失敗。
    - 以 `OllamaClient.overallStreamDuration` 驅動上限，不新增 `DependencyValues` keyPath 當測試旋鈕。

## 跨測試共用狀態

- **測試直接改寫 `@Shared(.lookupCatalog)` 會污染同批次的其他測試**：`@Shared` 是 process 內共用，`BuyLedger.xctestplan` 又是字母序執行，外溢的狀態會讓排在後面的 snapshot 測試出現只在完整套件下重現、單獨跑卻通過的失敗。
    - 需要改寫主檔目錄的測試一律在隔離 storage 內建立 state：參考 `LookupManagementFeatureTests.withIsolatedCatalog` 與 `RootFeatureTests.makeIsolatedRootState` (以 `defaultInMemoryStorage = InMemoryStorage()` 建立)。
    - 症狀是「完整回歸紅、單獨跑綠」時先查這裡，不要改 snapshot 或重錄基準圖。

## 錯誤斷言

- **錯誤型別不遵循 `Equatable`，斷言一律 `if case` 或 `switch` 比對 case**，不用 `#expect(throws:)` 比對整個值；需要驗證底層錯誤時斷言 `domain`、`code` 與 `localizedDescription`，不斷言物件身分。

## 守門測試 (`TestSuiteIntegrityTests`)

- **`exhaustivity = .off` 的總數不得超過 `exhaustivityOffUpperBound`**：新增一處關閉窮舉時必須同時移除他處的關閉；上限只檢查總數、不檢查位置。
- **App target 內 `default: return .none` 恆為 0**：不得改寫成規避字串比對的形式 (如 `default:` 換行再 `return .none`)。
- **App target 內把含 `url`／`request` 的識別字內插進訊息或診斷輸出恆為 0**：這是憑證外洩契約的守門，屬子字串比對，改名後再內插等迂迴寫法仍要人工複核。

## 效能測試 (`OrdersFeaturePerformanceTests`)

- **用 `ContinuousClock` 計時加顯式上限斷言，不用 `measure { }`**：XcodeBuildMCP 拆成 `build-for-testing` + `test-without-building` 執行，`.xctestrun` 讀不到 baseline，`measure` 恆為通過。
    - 門檻抓數量級退化 (約正常耗時的 6 倍)，不沿用舊 baseline 的 10 倍餘裕 (在此工具鏈下等同恆真)。
    - 已從 `BuyLedger.xctestplan` 排除，單獨跑用 `-only-testing:BuyLedgerTests/OrdersFeaturePerformanceTests`。

## Snapshot 測試

- **每個 snapshot 測試用 `TestDependencies.withFixedNow { ... }` 包住 view 建構與 `assertSnapshot`**，注入固定 `\.date`；測試內不直接呼叫 `Date()`。
    - baseline 在 `BuyLedgerTests/__Snapshots__/`，目前只有 iOS 393×852；record 流程見 `apps/ios/README.md`。
- **執行前的模擬器外觀設定見 `apps/ios/CLAUDE.md`；含 `.borderedProminent` 工具列按鈕的畫面的渲染方式見 `ios-design-system.md`**。
