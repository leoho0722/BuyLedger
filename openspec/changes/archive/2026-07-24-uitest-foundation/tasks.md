## 1. 共用 identifier 常數與命名規則

- [x] 1.1 依「**identifier 命名採 feature 點分層**」建立 `BLAccessibilityID` 常數命名空間，落實 **Identifier naming scheme** 與 **Identifiers for dynamic collections**：提供靜態元素常數、以列舉 rawValue 組出的集合常數、以業務鍵組出的資料列常數 (前綴加冒號)、以序位組出的序列常數，全部為 ASCII 且不含顯示文案。驗證：對每種組合方式各寫一支單元測試斷言產出的字串形狀 (例如 shipping 狀態膠囊、`ORD-2026-0007` 訂單列、序位 2 的縮圖)。
- [x] 1.2 依「**identifier 常數以共用資料夾編入兩個 target**」把常數檔放進新的獨立資料夾並登記為 `BuyLedger` 與 `BuyLedgerUITests` 兩個 target 的同步群組，落實 **Single source of identifier constants**：兩個 target 都能引用同一份宣告、不存在副本。驗證：編輯前備份專案檔；改完後 iOS 與 iPadOS 各 build 一次成功，且 UI 測試 target 內引用該常數可編譯通過。

## 2. App 端啟動 harness

- [x] 2.1 實作 `BLUITestConfiguration` 解析啟動參數，落實 **UI test mode activation**：無參數時行為與現況相同、帶參數時進入測試模式，整段以 `#if DEBUG` 圈住且 Release 下啟用判斷為編譯期常數 false。驗證：單元測試覆蓋「有參數／無參數／未知參數」三種解析結果；Release build 成功且產物不含 harness 符號。
- [x] 2.2 依「**啟動掛鉤集中在 AppLaunchConfigurator**」新增 `AppLaunchConfigurator.prepareUITestHarnessIfNeeded()`，並讓 `BuyLedgerApp` 改在 `init()` 內於建立 store 前呼叫它、`configure()` 在測試模式略過 Firebase 初始化。行為：測試模式下遙測不初始化，正式模式下啟動流程不變。驗證：以測試模式與正式模式各啟動一次，確認主控台的 Firebase 初始化訊息僅出現在正式模式。
- [x] 2.3 依「**UI 測試模式改用 in-memory container**」以 `prepareDependencies` 一次覆寫全部 repository 指向 in-memory `ModelContainer`，落實 **Test isolation between launches**：測試模式不讀寫磁碟 store，且啟動時先清空設定值再套用啟動選項指定的語言與預設幣別。驗證：`HarnessSelfCheckTests` 新增「建立資料後重啟不殘留」與「切換語言後重啟回到預設語言」兩支測試。
- [x] 2.4 實作 `BLUITestSeedProfile` 與對應資料集，落實 **Deterministic data seeding by profile**，依「**種子資料以 profile 列舉宣告**」讓所有日期由注入的基準時刻推導、未知 profile 退回空集合並印出警告。驗證：`HarnessSelfCheckTests` 斷言空 profile 顯示空狀態、有資料 profile 顯示指定筆數、標示為今天／昨天的訂單落在相對日期分組、未知 profile 不 crash。
- [x] 2.5 依「**時間與地區在啟動時一次注入**」固定 `\.date`、`\.calendar`、`\.timeZone` 與 `\.uuid`，落實 **Environment injection for time, locale, and identifiers**：基準時刻可由啟動參數指定，無法解析時退回固定預設值並印出警告。驗證：同一支測試以兩個不同的系統日期執行 (改模擬器日期或以不同基準時刻參數執行兩次)，日期分組標題與期間篩選結果一致。
- [x] 2.6 [P] 實作三個外部相依的 test double，落實 **External dependency doubles in UI test mode**，依「**外部相依換成 test double**」讓照片匯入直接回傳內建測試影像、行事曆依啟動參數回傳授權或拒絕且不寫入系統、匯率回固定快照且不打網路。驗證：`HarnessSelfCheckTests` 斷言按下加入照片後縮圖出現且未出現跨行程選擇器、匯率畫面顯示固定快照值。
- [x] 2.7 [P] 依「**載入失敗態以啟動選項注入**」實作失敗注入，落實 **Load failure injection**：指定 repository 的讀取拋錯以呈現載入失敗畫面與重試控制，並支援「僅首次失敗」讓重試可成功。驗證：`HarnessSelfCheckTests` 斷言注入失敗後失敗畫面與重試鈕存在、點重試後載入成功。

## 3. 測試端 Support 層

- [x] 3.1 實作 `LaunchOptions` 值型別，落實 **Launch options describe preconditions declaratively**：以型別安全欄位描述 seed profile、基準時刻、語言、行事曆授權結果、載入失敗模式與初始設定，並自行序列化為啟動參數，測試不自行拼字串。驗證：單元測試斷言預設值與各欄位序列化出的參數內容。
- [x] 3.2 實作 `BLUITestCase`，落實 **Shared test case base**：擁有 app 實例、首次失敗即停、固定方向、單一 `launch(_:)` 入口，並在失敗時附上截圖與可及性樹。驗證：刻意讓一支測試失敗，確認測試結果含兩份附件。
- [x] 3.3 依「**導覽分流器吸收 compact 與 regular 版面**」實作 `AppNavigator`，落實 **Layout-agnostic navigation**：執行期偵測版面，對外只暴露「切到某分頁」等語意操作。驗證：同一支導覽測試分別在 iPhone 與 iPad 模擬器執行皆綠。
- [x] 3.4 [P] 實作等待、捲動、文字輸入三組 helper，落實 **Reusable interaction helpers** 的條件式等待、離屏元素捲入可點位置、清空重填與數字鍵盤以工具列收起。驗證：於設定頁的目標金額欄位 (數字鍵盤) 與總覽頁的離屏區塊各寫一支測試實際使用這些 helper。
- [x] 3.5 [P] 實作選單、sheet、alert 三組互動 helper，補齊 **Reusable interaction helpers**：開選單並選項目、關閉 sheet 並處理未儲存變更確認、點擊 alert 按鈕並斷言訊息。驗證：以設定頁的選擇器與捨棄確認流程各寫一支測試實際使用這些 helper。
- [x] 3.6 [P] 實作數值解析與共用斷言 helper，補齊 **Reusable interaction helpers**：金額、百分比與日期一律以當次 locale 格式化後比對，並提供導覽標題、空狀態、命中區尺寸等共用斷言。驗證：同一支斷言測試在中文與英文兩種語言設定下皆綠。
- [x] 3.7 定義 `Screen` protocol，落實 **Page object contract**：要求根 identifier、提供就緒等待與診斷，並以根導覽、總覽、設定三個 Page Object 作為範本，語意操作對外、元素查詢不外洩。驗證：三個 Page Object 的公開介面中不含任何 `XCUIElement` 型別，且冒煙測試僅透過語意方法操作。
- [x] 3.8 依「**Support 層依職責分檔**」確認每個 Support 檔只承載單一職責且不存在跨檔重複實作。驗證：逐檔審視並確認測試檔與 Page Object 皆呼叫共用 function，無重複的等待或捲動實作。

## 4. 根導覽、總覽與設定的 identifier 標註

- [x] 4.1 為根導覽 (分頁列與 iPad 側邊欄) 補上 identifier，落實 **Identifier coverage categories** 的導覽容器與無文字控制項，以及 **Accessibility identifier is the sole locator for UI tests**：切換語言後 identifier 不變。驗證：`RootNavigationTests` 以 identifier 切換全部分頁，並在中英兩種語言下皆綠。
- [x] 4.2 為總覽頁補上 identifier：空狀態容器、KPI 卡容器與其主要數值、進行中開團列、近期訂單列與查看全部控制。驗證：`LaunchSmokeTests` 以空 profile 斷言空狀態容器存在、以有資料 profile 斷言 KPI 主要數值可個別讀取。
- [x] 4.3 為設定頁補上 identifier：語言選擇、預設幣別列、目標金額欄位、AI 開關與版本資訊。驗證：Support 層的輸入與選單 helper 測試 (3.4／3.5) 全程以這些 identifier 操作。
- [x] 4.4 為篩選膠囊等僅以配色表達選取的控制項補上選取 trait，落實 **Selection state is exposed to assistive technology**。驗證：測試斷言選取中的膠囊回報選取 trait、未選取者不回報。

## 5. 測試計畫與既有測試改寫

- [x] 5.1 依「**測試計畫拆主回歸與效能兩份**」建立兩份測試計畫，落實 **Test plan separation**：主回歸鎖定語言與地區、關閉隨機順序並排除效能與模板測試。驗證：主回歸計畫連跑兩次，執行的測試與順序一致且不含啟動效能測量。
- [x] 5.2 依「**廢除掩蓋性 skip**」改寫既有 4 支 UI 測試，落實 **Failures are never masked**：改以 identifier 定位、以硬斷言取代找不到元素就 skip、以條件式等待取代固定延遲、以 identifier 取代位置索引；照片流程改走測試模式的照片 double。驗證：4 支測試在中文與英文兩種語言設定下皆綠，且原始碼中不再有針對 App 自身元素的 skip。
- [x] 5.3 撰寫 `LaunchSmokeTests` 與 `HarnessSelfCheckTests` 作為地基的驗收：冷啟動進入前景、預設分頁正確、五個分頁可切換，以及前述各項 harness 自我檢查。驗證：兩支測試檔在 iPhone 與 iPad 模擬器各執行一次皆綠。

## 6. 收斂與文件

- [x] 6.1 全套測試以 UI 測試 scheme 的主回歸計畫在 iPhone 與 iPad 模擬器各連跑兩次，確認結果一致且無 flaky。驗證：兩台裝置各兩輪皆綠，並記錄總執行時間。
- [x] 6.2 把 UI 測試硬規則寫進 `apps/ios/CLAUDE.md` 的測試準則：一律以 identifier 定位、測試前必須指定 seed 與語言、不得以 skip 掩蓋 App 自身元素缺失、外部相依一律走 double、UI 測試僅覆蓋 iOS 26.x 模擬器。驗證：對照本次 diff 逐項確認規則皆已入檔。
- [x] 6.3 把 UI 測試執行指令、啟動參數約定與新增的共用資料夾寫進 `apps/ios/README.md` 的執行測試與專案結構章節。驗證：照著文件的指令實跑一次主回歸計畫成功。
- [x] 6.4 確認所有新增 Swift 檔的註解符合 Apple 官方 documentation comment 規範且用語精簡：型別與公開方法皆有 `///` 摘要、參數與回傳值有需要時才補、註解結尾不加句號、中英數之間依規範補半形空格。驗證：以獨立的 coding-style 審查逐檔檢視所有新增與修改的檔案。
