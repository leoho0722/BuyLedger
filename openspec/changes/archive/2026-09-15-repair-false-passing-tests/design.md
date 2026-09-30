## Context

2026-09-14 的全庫審查中，審查員逐檔讀過單元測試與 UI 測試，並對照產品程式碼，確認有一批測試在產品邏輯壞掉時仍會通過；UI 測試支援層另有一個會打錯輸入值的邏輯錯誤。問題清單與型態見 proposal.md。

現況限制：

- 單元測試跑 Swift Testing，UI 測試跑 XCTest，都只能在 iOS 26.x 模擬器執行，UI 測試走獨立的 `BuyLedgerUITests` scheme。
- 單元測試與 UI 測試一律在同一台 iOS 26.x 模擬器上執行，並以 UDID 指定：iPhone 的單元測試與 UI 測試共用 1.1 記錄的同一台 iPhone 模擬器，iPad 的 UI 主回歸固定使用 1.1 記錄的同一台 iPad 模擬器。如此前後結果的差異只來自程式修改，不來自裝置狀態不同。
- UI 支援層的 helper 多半是 `XCUIElement`／`XCUIApplication` 的 extension，拿不到 test case 實例；既有的 `dismissNumericKeyboard(in:file:line:)` 已示範在 extension 內附截圖與可及性樹後 `XCTFail` 的寫法。
- 專案過去的經驗是：「綠燈但守不住」的測試只能靠刻意破壞產品邏輯 (變異測試) 發現，讀程式碼與看覆蓋率都抓不到。
- 本 change 是後續 View 與 reducer 重構的前置安全網，必須先於那些重構完成。

## Goals / Non-Goals

**Goals:**

- 審查列出的每一條無法失敗的單元測試與 UI 測試，改寫成在對應行為壞掉時會失敗；做不到有意義守門的，改名為實際斷言的行為或刪除。
- 修正 `FxScreen`、`QuoteScreen`、`OrderEditScreen` 金額輸入重複的問題。
- UI 支援層的等待、點擊、選單、文字輸入與讀值 helper，不再允許元素缺失時被靜默吸收。
- 每一條修正都有變異驗證紀錄。

**Non-Goals:**

- 測試寫法的規範整理：`@Test(arguments:)` 參數化、「行為_情境_預期」命名、Given／When／Then 註解、fixture 命名與位置、doc comment。這些依修正順序在各 Feature 的 change 處理。
- `OrdersFeaturePerformanceTests` 的門檻調整 (需要逐情境量測基準，另案處理)。
- `BLUITestCase` 未呼叫 `super`、診斷附件邏輯重複、未使用的 helper 與 `SettingsScreen` 清理 (唯一例外是本 change 會處理的 `assertProgressPairing`)。
- 尾隨空白清理與其他 ios-dev-kit 規範修正。
- 產品程式碼的重構。只有在加強後的測試揭露真實產品缺陷時，才於本 change 內做最小修正並記錄。

## Decisions

### 以變異驗證作為每條修正的完成條件

每一條被修正的測試，完成時都要暫時破壞它所守的產品邏輯或 helper，確認測試轉紅，記下破壞內容與失敗訊息原文，再還原。

- 採用原因：這類缺陷的共同點是「現在綠燈」，只看綠燈無法證明修好。
- 替代方案：只靠程式碼審查判定修正是否有鑑別力。不採用，因為原本的缺陷正是通過了審查才留下來。

### 讀回資料改由儲存層提供而非測試餵回

宣稱「寫入失敗後儲存層不變」的測試，重新載入時的資料必須來自寫入目標的儲存層：使用 in-memory container 搭配 `OrderRepository.live(container:)` 這類真實 repository，或讓寫入與讀取共用同一個記錄替身。

- 替代方案：保留直接送出 `.ordersLoaded(...)` 的寫法，只把名稱改成「只驗證畫面狀態不變」。只在儲存層無法以 in-memory 方式讓寫入失敗時才採用，並在測試名稱與 doc 明寫。

### 取樣值必須讓正確與錯誤實作得出不同結果

修正時先寫出「一個合理的錯誤實作」，確認新的輸入會讓它與正確實作產生不同的斷言值。例如：注入秒數非 0 的時間，驗證秒數合併；注入與 fallback 不同的匯率快照，驗證畫面用的是快照。

- 替代方案：增加更多相同型態的斷言。不採用，數量多不等於有鑑別力。

### 無法成為有效守門的測試改名或刪除

整檔以同一字面值自我比較、或斷言必然成立且沒有對應產品行為可守的測試，優先改為觸發真實失敗路徑；若產品沒有可觸發的路徑，就刪除，不留下看似有保護的綠燈。

- 替代方案：保留並加註解說明。不採用，註解無法阻止它被當成守門。

### 等待與點擊 helper 失敗時直接附診斷失敗

UI 支援層新增一組「等不到就失敗」的互動 helper (例如點擊前等待可點、點選單項目、清空並輸入)，逾時時比照 `dismissNumericKeyboard` 附截圖與可及性樹再 `XCTFail`，並接收呼叫端的 `file`／`line`。`waitUntilHittable`、`tapMenuItem` 等回傳 `Bool` 的版本移除 `@discardableResult`，只保留給確實需要分支判斷的呼叫端。

- 實作順序採「先加新 helper、分批遷移呼叫端、最後移除舊寫法」，每一批完成時 UI 測試都能建置並執行。
- 替代方案：只移除 `@discardableResult`，讓編譯器逼每個呼叫端處理。不採用為唯一手段，因為 57 處呼叫 (2026-09-14 grep 實測) 會各自重寫一份失敗處理，反而分散。

### 讀值方法回傳 Optional 區分元素不存在

`DashboardScreen.kpiValue`、`CampaignDetailScreen.summaryValue`、`OrderDetailScreen.summaryValue`、`FxScreen.convertedValue`、`QuoteScreen.suggestedPriceValue`、`InsightsScreen.totalProfitValue` 與 `InsightsScreen.accessibilityValue(of:)` 在元素不存在時回傳 `nil`，不再回傳空字串；呼叫端以附診斷的方式回報元素缺失。

- 替代方案：在讀值方法內直接失敗。不採用，因為部分呼叫端需要把「缺失」與「值不符」分成兩種訊息。

### 金額輸入一律先清空再輸入

`FxScreen.typeAmount`、`QuoteScreen.typePrincipal`、`OrderEditScreen.typeChargedAmount` 改為共用同一個清空後輸入的 helper：欄位有任何既有內容 (含與目標相同的值) 都先刪除，再輸入目標值。

- 替代方案：現值等於目標值時直接返回、不輸入。不採用，因為欄位顯示值可能是格式化後的字串 (例如含千分位)，與輸入字串不一定能直接比對，先清空再輸入的結果最可預期。

### UI 斷言改讀具體結果

UI 測試的斷言改為讀取可觀察的具體結果，而非「元素存在」或「值非空」：

- 匯率與報價頁在測試資料的固定匯率下斷言預期金額，且不是佔位符「—」。
- 期間切換斷言對應分段為選取狀態。
- 確認 alert 以其專屬按鈕辨識。
- 否定斷言先確認目標列原本存在。
- 自我檢查測試的前置條件改為能觸發被測行為的流程：先以有資料的 seed 啟動再以空資料重啟；注入與預設不同的參考時間；經由開團提醒流程觸發行事曆權限請求。

## Implementation Contract

**行為**

- 審查列出的單元測試與 UI 測試，在其名稱或 doc 描述的行為被破壞時會失敗。
- 金額輸入 helper 執行後，欄位內容恰好等於目標金額，與欄位原本的內容無關。
- 元素在逾時內沒有出現或不可點時，UI 測試在該互動點失敗，並附上失敗畫面截圖與可及性樹。

**介面**

- UI 支援層提供會在逾時時附診斷失敗的互動 helper，參數包含逾時秒數與呼叫端的 `file`／`line`。
- `XCUIElement.waitUntilHittable(timeout:)`、`XCUIApplication.tapMenuItem(_:timeout:)` 與 Page Object 的查詢方法 (`hasCustomer`、`hasCampaign`、`hasOrder`、`hasCandidate`、`hasPageCount`) 不標記 `@discardableResult`。
- 前述 7 個讀值方法回傳 `String?`。
- `clearAndType(_:in:)` 與 `OrderEditScreen.typeCustomerName(_:)` 找不到欄位時以附診斷方式失敗，不再直接 `return`。

**失敗模式**

- 元素缺失：測試失敗，訊息指名元素 identifier，附截圖與可及性樹。
- 讀值元素缺失與值為空是兩種不同的失敗訊息。
- 加強後的單元測試若揭露產品缺陷：於本 change 內修正產品程式並在 tasks.md 記錄缺陷、修正與驗證。

**驗收**

- tasks.md 每一條測試修正任務都附變異驗證紀錄：寫明破壞了什麼，以及失敗訊息原文。
- 在 `apps/ios/BuyLedgerUITests/Screens` 與 `apps/ios/BuyLedgerUITests/Support` 下搜尋，不再出現回傳空字串的讀值方法，也沒有以 `_ =` 丟棄等待結果後繼續互動的寫法。
- 本 change 所有單元測試、UI 測試類別與完整回歸，都在 1.1 記錄的模擬器上以 UDID 指定執行；iPhone 的單元測試與 UI 測試使用同一台。
- 主 scheme 單元測試全數通過 (已知環境紅燈除外，須在 tasks.md 列出名稱)；`BuyLedgerUITests` 主回歸在 iPhone 與 iPad 模擬器上，失敗數不多於變更前基準，已知 flaky 依 `apps/ios/CLAUDE.md` 的判讀規則以單獨重跑確認。

**範圍**

- 範圍內：proposal.md Impact 列出的測試檔、UI 支援層與 Page Object，以及加強測試後揭露的產品缺陷的最小修正。
- 範圍外：Goals / Non-Goals 列出的規範整理、效能門檻與清理項目。

## Risks / Trade-offs

- [加強後的測試揭露真實產品缺陷，範圍擴大] → 只做讓該行為正確的最小修正，於 tasks.md 記錄；若修正牽涉架構調整，停下來與使用者確認是否拆出另一個 change。
- [UI helper 簽章調整影響 57 處 `waitUntilHittable()` 與 8 處 `tapMenuItem(` 呼叫 (2026-09-14 grep 實測)] → 先加新 helper，依 Page Object 分批遷移，每批跑對應的 UI 測試類別，最後才移除舊寫法。
- [UI 測試既有 flaky (訂單編輯表單 TextField 偶發 hittability 失敗) 干擾判讀] → 依 `apps/ios/CLAUDE.md` 的規則：失敗集合在連續重跑間不一致即為雜訊，單獨重跑轉綠即可；穩定重現才視為本 change 造成。
- [變異驗證需要暫時改動產品程式碼，可能忘記還原] → 每次變異驗證後以 `git diff` 確認產品檔案已還原，才勾選該任務。
