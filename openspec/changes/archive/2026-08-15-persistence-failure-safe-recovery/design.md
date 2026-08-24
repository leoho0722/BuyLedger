## Context

`PersistenceContainer.makeForApp()` 目前的失敗路徑是：`make(cloudKit: .disabled)` 拋錯後印一行 `print`，呼叫 `resetStoreFiles()` 刪掉 `BuyLedger.store` 與其 `-wal`／`-shm`（含 legacy `default.store`），再重建一個空 container；重建仍失敗則以 `try!` 退到 in-memory。整段唯一的告知是 release build 讀不到的 `print`。

檔案內註解自述「開發階段 App 尚未上架，把舊 store 整批清除後重建是最穩定的恢復策略」。這個前提已不成立：pbxproj 的 `MARKETING_VERSION` 是 1.7.0，repo 有 ios-v1.7.0 tag。同時 App 沒有任何匯出或備份入口（設定頁的匯出區塊整段包在 `#if false` 內，由 data-export-and-file-protection 另案處理），因此清除即等於永久遺失。

約束：本專案禁止 production code 直接呼叫 `Date()` 等環境相依 API；bootstrap 執行於 `BuyLedgerApp.init()`，早於 TCA store 建立，取不到注入的 date dependency。Firebase 於 `AppDelegate` 生命週期才設定，bootstrap 早於它。

## Goals / Non-Goals

**Goals:**

- 讓「持久層開不起來」不再造成任何檔案被刪除或覆寫。
- 讓失敗對使用者可見且可理解，並明確指示「先不要輸入資料」。
- 保留一條使用者主動選擇的復原途徑，且該途徑為搬移而非刪除。
- 讓失敗留下 release 環境可追查的診斷。
- 消除三處與現況矛盾的敘述，避免後續施工依據過期資訊。

**Non-Goals:**

- 不做資料匯出或備份檔產生（由 data-export-and-file-protection 負責）。
- 不做備份還原或匯入。
- 不兌現 CloudKit 預留，也不為此補必填屬性的預設值（屬 schema 形狀變更，須另開版本）。
- 不調整 schema target、floor 或遷移階段定義。
- 不改動正常開啟成功時的任何行為。
- 不為既有已被清空的使用者資料提供補救（無從追溯）。

## Decisions

### 失敗時預設不動任何檔案，備份降為使用者確認後的逃生門

原始稽核建議「自動改名備份後重建空 store」。不採用：改名等於把帳本搬走、給使用者一個空 App，資料雖在磁碟上卻沒有使用者能觸及的回頭路。SwiftData 遷移失敗最常見的成因是這一版 migration 寫錯，只要下一版修好，原地不動的 store 下次啟動就會自行復原，這是自動備份拿不到的價值。

因此預設分支完全不碰檔案，只退到 in-memory 並標記 degraded。備份改由使用者在失敗畫面上明確按下並二次確認才執行，符合平台指引「破壞性操作先確認、再寫入」。代價是多一顆按鈕與一次確認流程。

替代方案「只阻斷、不提供任何重建入口」成本更低（可省下整個隔離備份型別與其測試），但使用者在修正版發布前完全無法使用 App，且沒有任何自救手段，故不採用。

### 以 bootstrap 值型別傳遞啟動結果，取代可變全域

需要把「這次啟動是否 degraded」從 `PersistenceContainer` 傳到 UI 層。用 `nonisolated(unsafe)` 可變全域最省事，但會新增一個並行安全豁免，與專案的 Swift 6 strict concurrency 立場相衝突。

改為 `PersistenceContainer` 內宣告一個 Sendable 的 bootstrap 值型別，同時持有 container 與 outcome（healthy 或 degraded 加原因），並以一個 static let 解析一次。`shared` 改為讀取該值的 container。同時把工廠方法降為 private，讓「整個 process 只有一個 production container」從慣例變成型別層的保證。

此決策順帶修掉訂單 repository 內唯一一處直接呼叫工廠的違規點（其餘七個 repository 都用 shared），該處目前會在 in-memory 建構失敗時額外建出第二個 production container。

### 隔離備份目錄採遞增索引命名，不用時間戳

備份目錄需要唯一名稱。時間戳最直觀，但 bootstrap 取不到注入的時間來源，直接呼叫系統時間會違反專案的環境相依注入鐵則，且讓測試不具決定性。

改用 `Recovered-1`、`Recovered-2` 遞增索引：取第一個尚未存在的正整數。同時解決依賴注入與測試決定性兩個問題，代價是使用者從目錄名看不出備份時間（可由檔案系統的建立時間得知，可接受）。

### 隔離備份型別只搬不刪且目錄可注入

備份邏輯抽成獨立型別，對外只提供一個以目標目錄為參數的搬移函式。目錄參數化是為了讓測試指向暫存目錄，production 由呼叫端傳入 Application Support。

硬約束：整個型別不得出現任何檔案刪除呼叫，只使用搬移。這讓「本 change 不刪任何檔案」成為可被靜態掃描驗證的性質，而不是靠審查眼力。

### 診斷改 OSLog fault，當機診斷延後到 Firebase 設定完成後上報

`print` 在 release build 不落地，等於這條最需要可觀測性的路徑沒有可觀測性。改用 OSLog 的 fault 等級。關鍵細節：OSLog 預設把字串插值視為私有資料，正式裝置日誌只會顯示遮蔽字樣，因此錯誤描述必須明確標記為公開；同時確認訊息只含 SwiftData 的 entity 與屬性名，不夾帶訂單或客戶資料。

當機診斷不直接呼叫 Firebase：bootstrap 早於 Firebase 設定，直接呼叫會崩潰。改為新增一層診斷 client 抽象，bootstrap 只把結果留在 outcome 上，由啟動設定流程在 Firebase 設定完成後讀取並上報。抽象化的另一個理由是稽核另有一條風險指出三支遙測 SDK 可能整組移除，包一層可讓那個決定不必回頭改這裡，也讓測試能注入 no-op 替身。

上報動作必須放在 UI 測試模式的提前返回之後，否則 UI 測試會提早觸發 bootstrap 而建出真實 store，破壞 in-memory 測試 harness。

### degraded 時全畫面阻斷，不做逐路徑停用

degraded 時容器是 in-memory，使用者輸入的任何資料都會在下次啟動蒸發，這正是本 change 要消滅的靜默失敗。

採全畫面阻斷：degraded 時只渲染失敗畫面，不渲染分頁列與側邊欄。替代方案「正常 UI 加常駐橫幅並停用所有寫入」需要在每個寫入路徑補判斷，成本更高且漏一處就退化成「有橫幅但仍可輸入」；全畫面阻斷用單一判斷就把整類問題關掉。代價是 degraded 時完全不能使用 App，這正好構成修正 migration 的正確壓力。

失敗狀態的初值必須在 App 進入點就決定並帶入根 state，否則會先閃一下正常 UI 才切換。

### 示範資料以 #if DEBUG 排除，#else 提供同名空集合

示範訂單資料目前會一起進 release binary。直接對整個型別加 `#if DEBUG` 會讓 release build 失敗：這批資料被十餘處 Preview 與 preview 用的 dependency 值引用，那些宣告在 release 一樣接受型別檢查。

作法是只把資料本體包進 `#if DEBUG`，`#else` 分支提供同名的空集合。呼叫點一行不改，release binary 不含示範資料。驗收必須包含一次 release configuration build。

### CloudKit 預留明文轉為已接受技術債

檔頭宣稱換一行即可啟用 CloudKit。實際上 CloudKit 要求所有屬性為 optional 或帶預設值，而訂單 record 有十二個必填屬性、開團 record 與同步 sidecar 也有多個，真的切換會在 container 初始化即失敗，然後撞上本 change 正要移除的清除路徑。

本次不兌現：補預設值屬 schema 形狀變更，須新增版本並凍結現行版本為 shadow，且須重評 floor 收斂決策。改為把檔頭改寫成明列前置作業，並明文記為已接受技術債。

## Implementation Contract

**行為（使用者可觀察）**

- 正常開啟成功時：行為與現況完全一致，無任何可觀察差異。
- 開啟失敗時：App 顯示全畫面失敗畫面，文案說明資料無法開啟、原始資料仍完整保留在裝置上、請先不要新增或修改資料；畫面上不存在分頁列與側邊欄。
- 失敗畫面提供「改用空白資料庫繼續」動作；點擊只開啟確認 alert，不動任何檔案。alert 確認後才執行隔離備份，成功則畫面切為「已保留備份，請關閉 App 後重新開啟」；備份失敗則停留在阻斷狀態並更新顯示原因。

**介面與資料形狀**

- 持久層對外新增一個 Sendable 的 bootstrap 值型別，持有 container 與 outcome；outcome 為 healthy 或 degraded（帶可讀原因字串）。
- 隔離備份型別對外提供單一搬移函式，接受目標目錄、回傳實際建立的備份目錄；目錄下無任何 store 檔時回傳空值且不建立空目錄。
- 新增當機診斷 client 抽象，具備記錄訊息的能力；live 實作呼叫 Crashlytics，測試實作為 no-op。
- 根 feature state 新增一個可為空的失敗子 state，為空時走既有版面。

**失敗模式**

- 持久層開啟失敗：不刪除、不覆寫任何檔案；記錄 OSLog fault 且錯誤描述為公開可讀；退到 in-memory 並標記 degraded。
- in-memory 亦建立失敗：記錄 fault 後終止，並在註解說明此情形代表 schema 定義本身損壞。此為刻意不可復原。
- 隔離備份途中失敗：不吞錯，畫面停留在阻斷狀態並顯示原因。
- 當機診斷上報：刻意在 Firebase 未設定時不執行，不得因此崩潰。

**驗收標準**

- 在 `apps/ios` 原始碼與現行文件中搜尋清除函式名稱零命中 (明確排除 `openspec/`：本 change 自身的規格必須指名被移除的符號，`openspec/changes/archive/` 是不可變歷史)；持久層目錄下無任何檔案刪除呼叫。
- 以低於 floor 的實體 store 觸發 bootstrap 後：outcome 為 degraded、原三件套仍在原路徑且逐 byte 相同、目錄下不存在任何備份目錄。
- 呼叫隔離備份後：三件套自原路徑消失並完整出現在第一個備份目錄且位元組不變；已存在第一個備份目錄時落到第二個；無 store 檔時回傳空值。
- 兩次取用共用 container 為同一實例。
- degraded 初值啟動時只渲染失敗畫面，畫面上不存在任何根分頁 identifier。
- 失敗畫面 reducer 測試涵蓋：點擊只開 alert、確認才呼叫備份並切換階段、備份拋錯時停留阻斷並更新原因。
- `apps/ios` 原始碼內搜尋 SwiftLint 零命中；持久層目錄下 print 零命中；OSLog 錯誤插值帶公開標記。
- release configuration build 成功，且 Debug 下既有 Preview 仍顯示示範資料。
- `apps/ios` 原始碼與現行文件 (含平台指引與 schema 定義檔) 搜尋「尚未上架」與清除策略相關敘述零命中，同樣排除 `openspec/`。
- 主 scheme 單元測試全綠；UI 主回歸在 iPhone 與 iPad 各一次全綠。

**範圍邊界**

- 在範圍內：持久層啟動路徑、啟動失敗 UI 與其 reducer、隔離備份型別、診斷輸出與 client 抽象、示範資料的建置組態隔離、三處過期敘述的改寫、對應測試與規格。
- 不在範圍內：資料匯出與備份檔格式、備份還原、schema 版本與遷移階段、CloudKit 啟用、設定頁其他區塊、既有正常路徑的任何行為。

## Risks / Trade-offs

- [共用 container 改為經由 bootstrap 解析後，若有人再各自呼叫工廠會回到多 container 並存、SwiftData 內部狀態錯亂] → 工廠方法降為 private，唯一呼叫者是 bootstrap；同步修掉訂單 repository 內既有的違規呼叫點；補測試斷言兩次取用為同一實例。
- [為測試而加的 store 位置注入參數，會讓測試與 production 走不同的 configuration 建構形式，可能出現測試綠但 production 壞] → 參數預設為空，空分支與現行建構逐字相同（維持具名 configuration）；既有的實體檔遷移測試維持原寫法作為 production 形式的對照；合入前跑一次冷啟動確認 store 仍落在原路徑。
- [示範資料加上建置組態隔離會讓 release build 失敗，因為它被十餘處 Preview 與 preview dependency 引用] → `#else` 分支提供同名空集合，呼叫點一行不改；驗收明列一次 release configuration build 為必跑項目。
- [當機診斷若在 Firebase 設定前被呼叫會直接崩潰] → bootstrap 只留結果不上報，由啟動設定流程在 Firebase 設定完成後 drain；drain 必須置於 UI 測試模式提前返回之後，否則會破壞 in-memory 測試 harness。
- [OSLog 預設遮蔽字串插值，正式裝置只會看到遮蔽字樣，等於白改] → 錯誤描述明確標記為公開；同時確認訊息不含使用者資料。
- [失敗畫面新增字串漏補英文，英文模式露出中文] → 新字串納入本地化目錄測試的必備清單；目錄以文字插入方式補 entry，不可整檔重新序列化（既有踩雷：Xcode build 會污染該檔）。
- [全畫面阻斷若在正常啟動時誤觸發，等於把可用的 App 鎖死] → degraded 只由失敗分支產生，根 state 的失敗子 state 預設為空；補測試斷言預設不進失敗畫面；UI 主回歸全綠即證明正常路徑未被誤擋。
- [degraded 時 App 完全不可用，對使用者是硬中斷] → 這是刻意取捨：in-memory 上的輸入必然蒸發，讓使用者以為能用才是更大的傷害。失敗畫面同時提供逃生門，使用者不會被永久卡住。
