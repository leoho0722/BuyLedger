## Context

BuyLedger 的 iOS App 有 83 個畫面、357 條值得自動化的使用者流程，但目前只有 4 支 UI 測試，且三項基礎能力全缺：

- **定位**：全專案 0 個 `accessibilityIdentifier`。既有測試以中文字面值 (「訂單」「新增訂單」) 與位置索引 (`element(boundBy: 1)`) 定位元素。App 支援中英切換且 `accessibilityLabel` 也走 String Catalog，英文模式下這些查詢全部落空。
- **資料**：`OrderRepository.liveValue` 不 seed，主檔也無預設值，模擬器首次啟動是真正的空狀態。沒有資料就走不到篩選、詳情、分析、客戶等多數畫面。
- **隔離**：SwiftData 走磁碟 store、設定寫 `UserDefaults.standard`，前一支測試留下的訂單與語言會污染下一支；App 進入點完全沒有讀 `ProcessInfo` 的掛鉤，測試無從指定前置條件。

另有三個會讓測試不穩的外部相依：`PhotoClient` 走系統 PhotosPicker (跨行程、依賴模擬器相簿內容)、`CalendarReminderClient` 會跳 EventKit 權限彈窗並實際寫入行事曆、`ExchangeRateClient` 打外部 API 且金鑰由 build 期注入。時間相依 (日期區間篩選、日期分組標題、走勢圖與熱力圖) 走 `@Dependency(\.date)`，跨月跨週執行必然 flaky。

既有測試還有一個更隱蔽的問題：找不到元素時一律 `throw XCTSkip`，於是在錯誤環境或空資料庫下靜默全綠，看似有防護網實則沒有。

本 change 只建立地基，不寫各功能區域的流程測試。

## Goals / Non-Goals

**Goals:**

- 讓任何一支 UI 測試能以一行啟動宣告完整前置條件 (資料、語言、時間、外部相依行為)，且與其他測試完全隔離。
- 讓元素定位與顯示文案徹底解耦，中英兩種語言下同一份測試皆可執行。
- 把跨頁面重複的互動 (等待、捲動、填表、開選單、關 sheet、點 alert、解析金額) 抽成可複用 function，後續區域測試只描述流程。
- 建立 Page Object 契約與三個範本實作，讓後續區域照抄結構即可。
- 既有 4 支測試改寫後在中文與英文兩種語言下皆綠，且不含任何掩蓋性 skip。

**Non-Goals:**

- 不寫訂單、開團、客戶、分析、主檔、匯率報價、AI 總結、照片與合併的流程測試。
- 不為上述區域預先補 identifier。
- 不改動 App 正式執行路徑的產品行為。
- 不引入第三方 UI 測試框架。
- 不接 CI。
- 不調降 UI 測試 target 的部署目標。

## Decisions

### 啟動掛鉤集中在 AppLaunchConfigurator

iOS 平台既有硬規則要求啟動設定集中在 `AppLaunchConfigurator`，因此 UI 測試掛鉤不另開進入點：新增 `AppLaunchConfigurator.prepareUITestHarnessIfNeeded()`，由 `BuyLedgerApp.init()` 在建立 store 之前呼叫；`AppLaunchConfigurator.configure()` 則在 UI 測試模式下略過 Firebase 初始化。兩個進入點仍都只呼叫 `AppLaunchConfigurator` 的方法，符合既有規則。

必須在 `init()` 而非 `AppDelegate.didFinishLaunching` 呼叫：TCA 的 `prepareDependencies` 要在任何 dependency 首次被解析前生效，而 `RootFeature` store 於 App 型別建構時就已建立。因此 `BuyLedgerApp` 的 `store` 與 `modelContainer` 由儲存屬性初始式改為在 `init()` 內指派。

整個 harness 以 `#if DEBUG` 圈住，Release build 不含任何分支；`BLUITestConfiguration.isEnabled` 在 Release 直接是編譯期常數 `false`。

**替代方案**：改用獨立的 UI 測試專用 App target。被否決 — 測的就不是同一個 binary，且維護兩份進入點。

### UI 測試模式改用 in-memory container

UI 測試模式下不碰磁碟 store，改建 `ModelContainer(inMemoryOnly: true)`，並把所有 repository 的 dependency 以 `PersistenceContainer` 既有的 `make(inMemoryOnly:)` 與各 repository 既有的 `live(container:)` 工廠重新指向該 container。這讓「隔離」不必依賴刪檔：每次啟動都是全新的空資料庫，不存在殘留。

`UserDefaults` 仍是共用的，故 harness 在啟動時把設定相關的 key 清空後，再依啟動選項寫入指定語言、預設幣別與目標金額。

**替代方案**：保留磁碟 store 並在測試前刪檔。被否決 — 刪檔與 SwiftData 開檔存在競態，且 `-wal`／`-shm` sidecar 容易漏刪。

### 種子資料以 profile 列舉宣告

種子以 `BLUITestSeedProfile` 列舉宣告 (空、僅主檔、少量訂單、完整訂單、含開團的訂單、可合併候選、含照片、客戶排行、跨月分析資料)，每個 profile 對應一組固定資料。

所有日期以「注入的固定現在時間」為基準推導 (今天、昨天、七天前、上月同日)，不寫死絕對日期，也不呼叫系統時鐘。這讓日期分組標題與期間篩選的斷言在任何一天執行都成立。

**替代方案**：直接沿用既有的 `LedgerOrder.sampleOrders`。被否決 — 該資料集為 Preview 而生，筆數與狀態分布無法支撐篩選、合併、排行等斷言；但可作為「完整訂單」profile 的基礎再補齊。

### 外部相依換成 test double

`PhotoClient` 回傳內建的測試影像資料 (不開系統 PhotosPicker)、`CalendarReminderClient` 依啟動選項回傳授權或拒絕且不寫入行事曆、`ExchangeRateClient` 回固定匯率快照與固定幣別清單。

改以 double 而非 `addUIInterruptionMonitor`：中斷處理器只在下一次互動時才觸發、時機不可控，且跨行程元素查詢本身就不穩。真實系統 UI 的驗證留給人工實機驗收。

### 時間與地區在啟動時一次注入

`prepareDependencies` 同時固定 `\.date`、`\.calendar` (公曆)、`\.timeZone` 與 `\.uuid` (遞增序列)。固定時間預設值由啟動選項帶入，未指定時採一個固定的基準時刻。這解掉日期區間篩選、日期分組標題、走勢圖與熱力圖的跨日期 flaky。

### 載入失敗態以啟動選項注入

`BLLoadFailureView` 與載入中骨架在正式路徑幾乎不可能出現。UI 測試模式提供失敗注入選項，讓指定的 repository 讀取直接拋錯，使失敗態與重試按鈕能被覆蓋。

### identifier 命名採 feature 點分層

命名格式為 `<feature>.<screen>.<element>[.<qualifier>]`，全為 ASCII lowerCamelCase 片段：

- 列舉型集合 (狀態、期間、分頁) 以列舉的 rawValue 結尾。
- 使用者資料列以 `<prefix>:<業務鍵>` 結尾，業務鍵取原始字串不翻譯。
- 純序位集合 (照片、商品明細) 以 `<prefix>.index.<n>` 結尾。

常數集中在單一 `BLAccessibilityID` 命名空間，應用端與測試端皆引用常數、不寫字面值。

### identifier 常數以共用資料夾編入兩個 target

UI 測試 bundle 不連結 App binary，兩個 target 無法互相 import。因此常數檔放在新的獨立資料夾，並在 Xcode 專案設定中把該資料夾同時登記為兩個 target 的同步群組成員 — 這是唯一不產生兩份副本的作法。

**替代方案**：兩邊各留一份副本並以測試比對。被否決 — 比對測試看不到另一個 target 的副本，漂移無法自動偵測。

### Support 層依職責分檔

Support 層拆為：測試基底、啟動選項、導覽分流、等待、捲動、文字輸入、選單互動、sheet 互動、alert 互動、數值解析、共用斷言、失敗診斷。每個檔案只放同一職責的 function，Page Object 與各區域測試共同引用，不在測試檔內重寫。

Page Object 遵守 `Screen` 契約：以根 identifier 判定畫面就緒、提供等待與診斷、以語意方法暴露操作 (例如「開新訂單表單」)，不把 `XCUIElement` 查詢細節外洩給測試檔。

### 導覽分流器吸收 compact 與 regular 版面

iPhone 走底部分頁列、iPad 全螢幕走側邊欄，兩者是完全不同的元素樹。`AppNavigator` 以執行期是否存在分頁列判斷版面，對外只暴露「切到某個分頁」等語意方法，讓同一份流程測試在兩種版面皆可執行。

### 廢除掩蓋性 skip

App 自身元素缺失一律 `XCTFail` 並附上截圖與可及性樹；`XCTSkip` 只保留給真正的外部環境差異。既有 4 支測試裡所有「找不到就 skip」一律改寫。

### 測試計畫拆主回歸與效能兩份

主回歸計畫鎖定語言與地區、關閉隨機執行順序、設定失敗重試；啟動效能測試與 Xcode 模板產生的空測試移到另一份計畫，不拖慢回歸回圈。

## Implementation Contract

**Behavior**

- 未帶 UI 測試啟動參數時，App 行為與現況完全相同：讀磁碟 store、初始化 Firebase、打真實匯率 API、走系統照片選擇器與行事曆權限。
- 帶 UI 測試啟動參數時，App 改用 in-memory 資料庫並依 seed profile 注入資料、略過 Firebase、以 test double 取代三個外部相依、以指定時刻固定所有時間相依。
- 根導覽、總覽頁與設定頁的可互動元素具備穩定 identifier，切換語言後 identifier 不變。

**Interface / data shape**

- App 端：`BLUITestConfiguration` 從 `ProcessInfo` 解析啟動參數，暴露是否啟用、seed profile、固定時刻、外部相依行為、載入失敗模式與初始設定值；`BLUITestSeedProfile` 為 profile 列舉；`AppLaunchConfigurator.prepareUITestHarnessIfNeeded()` 為唯一觸發點。
- 測試端：`LaunchOptions` 值型別描述一次啟動的前置條件並序列化為啟動參數；`BLUITestCase` 提供 `launch(_:)` 入口；`Screen` protocol 要求根 identifier 與就緒等待。
- 兩端共用 `BLAccessibilityID` 常數命名空間，identifier 字串只在此宣告一次。

**Failure modes**

- 啟動參數解析不到已知 profile 或模式時，harness 以固定的預設值繼續 (不 crash、不靜默改變語意)，並在主控台印出一行警告。
- 測試端找不到 App 自身元素時失敗並附截圖與可及性樹，不 skip。
- 外部環境差異 (系統彈窗、跨行程 UI) 才允許 skip，且必須寫明原因。

**Acceptance criteria**

- 以 UI 測試 scheme 執行主回歸計畫，改寫後的既有 4 支測試與本 change 新增的冒煙測試在中文與英文兩種語言設定下皆綠。
- 自我檢查測試涵蓋：空 profile 啟動後總覽頁顯示空狀態；有資料 profile 啟動後總覽頁顯示內容；同一支測試連跑兩次結果一致 (證明無殘留)；載入失敗注入後失敗畫面與重試按鈕出現。
- iPhone 與 iPad 兩種模擬器各執行一次主回歸計畫皆綠。
- Release 建置成功且產物不含 UI 測試 harness 符號。
- iOS 與 iPadOS 各 build 一次成功 (確認新增資料夾被兩個 target 正確拾取)。

**Scope boundaries**

- 在範圍內：啟動 harness、種子資料、外部相依 double、identifier 命名規則與常數目錄、根導覽／總覽／設定三處的 identifier 標註、Support 層、`Screen` 契約與三個 Page Object、測試計畫、改寫既有 4 支測試、平台文件更新。
- 不在範圍內：其餘 8 個功能區域的 identifier 與流程測試、CI 串接、部署目標調整、既有產品行為變更。

## Risks / Trade-offs

- [手動編輯 Xcode 專案設定把共用資料夾登記給兩個 target 可能出錯，導致專案無法開啟] → 編輯前備份專案檔，編輯後立即以 iOS 與 iPadOS 各 build 一次驗證；若失敗則還原備份並改請使用者於 Xcode 介面操作。
- [`BuyLedgerApp` 的 store 由儲存屬性初始式改為在 init 內指派，可能影響既有啟動時序] → 冒煙測試涵蓋冷啟動與預設分頁；另以實機或模擬器實跑確認 Firebase 與資料載入行為不變。
- [in-memory container 與磁碟 store 的 migration 路徑不同，UI 測試測不到 migration] → 明確列為非目標；migration 由既有單元測試涵蓋。
- [test double 取代外部相依後，真實系統彈窗流程零覆蓋] → 於平台文件記錄此界線，這三條流程維持人工實機驗收。
- [seed profile 資料集若與各區域測試的斷言脫節，會在後續 change 反覆改動] → profile 只保證「資料的結構與相對關係」，各區域測試斷言結構而非硬編數值；新增 profile 一律加在列舉尾端、不改既有 profile 的內容。
- [identifier 大量加入 View 會稀釋既有版面程式碼可讀性] → identifier 一律取自常數、不寫字面值，且緊接在元素宣告後，不拆散既有修飾子順序。
