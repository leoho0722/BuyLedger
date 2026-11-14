## Context

`BLUITestHarness.prepareIfNeeded()` 由 `BuyLedgerApp` 的 `init` 經 `AppLaunchConfigurator.prepareUITestHarnessIfNeeded()` 呼叫，早於 store 與第一個 scene 建立；單元測試時 `BuyLedgerApp.init` 先返回，不會進 harness。只有帶 `-BLUITest` 啟動時 harness 才會往下執行，整個 harness 以 `#if DEBUG` 圈住，不進 Release。啟動參數由 UI 測試端的 `LaunchOptions` 組出、App 端的 `BLUITestConfiguration.init(arguments:)` 解析。

問題、觀察與假說見 proposal。設計上要同時滿足三件事：

- 消除 iPad 上「之後每次等閒置都滿 60 秒」的狀態 (轉向、鍵盤輸入、搜尋欄三類觸發)。
- 不讓守「關閉動畫期間呈現下一個提示」競態的 UI 測試失去偵測力 (變異實驗證實會失去，見 proposal 的表)。
- `.spectra.yaml` 開了 `tdd: true`：「是否關閉動畫」是會影響全部 UI 測試的條件分支，要有常駐的自動化守門，不能只靠一次性的連跑。

這次修訂依據五位審查者 (t8、t9、t16、t1n、fable-arch-reviewer) 的提案審查與主對話 2026-11-13 的變異實驗；「呈現競態測試保留動畫」與「單元測試加掃描守門」由使用者選定。

## Goals / Non-Goals

**Goals:**

- UI 測試模式預設關閉 UIKit 的 UIView 動畫，轉向、鍵盤輸入、搜尋欄步驟不再讓閒置等待逾時。
- 呈現競態測試以啟動參數保留動畫，偵測力不變。
- 關閉動畫的判斷與呼叫位置都有自動化守門。
- 規則檔寫明設定、保留參數的使用時機、判讀方式與退場條件；手動實測的說明同步。

**Non-Goals:**

- 不修改任何畫面或 Feature 的動畫寫法，也不處理正式 App 的動畫行為。
- 不保證 SwiftUI 轉場、鍵盤或系統呈現的動畫也停止；UI 測試 helper 的等待邏輯一律保留，不因此刪減。
- 不調查或繞過 XCTest 的閒置等待機制本身 (例如以私有 API 跳過等待)。
- 不在 UI 測試驗證動畫本身 (時長、減少動態效果的替代動畫)。
- 不更新 UI 測試中描述動畫等待的既有註解 (`OrderRegularSearchBarTests`、`OrdersScreen`、`XCTestCase+Orientation` 各一處)：它們描述的是有動畫時的行為，保留動畫的測試與日後移除這個設定時仍然成立。

## Decisions

### 在 BLUITestHarness 啟用時關閉 UIView 動畫

在 `BLUITestHarness.prepareIfNeeded()` 通過 `configuration.isEnabled` 檢查之後、建立 model container 之前，依設定關閉 UIView 動畫。這個位置早於第一個 scene 建立，整個程序存活期間都生效；不帶 `-BLUITest` 時提早返回，不會碰到。

作用範圍是全部 `-BLUITest` 啟動 (含 iPhone 模擬器與實機)，不限 iPad：只有一種時序模式比較好推理，iPhone 上也沒有需要保留動畫的理由。

替代方案：

- 把視窗圖層的 `speed` 調高：動畫仍然存在、XCTest 仍要追蹤，無法排除失步。
- 測試避開轉向：會失去自適應版面的連續性驗證 (13 個測試檔使用轉向 helper，主對話 2026-11-13 以 `grep` 計數)，也解決不了鍵盤與搜尋欄的觸發。
- 以私有 API 縮短或跳過 XCTest 的閒置等待：不受支援，Xcode 更新後可能失效。

### 以啟動參數讓呈現競態測試保留動畫

新增 `-BLUITestKeepViewAnimations`：帶上時 harness 不關閉動畫。驗證「sheet、確認框或提示關閉之後接著呈現提示或確認框」的 UI 測試帶上它。

依據是 proposal 的變異實驗：關閉動畫後，`testRequestDeletion_寫入失敗提示關閉後再刪除_重新呈現確認框` 對「失敗提示與確認框共用呈現狀態」的缺陷由 3 次全抓到變成 3 次全漏掉。這類競態只在關閉動畫期間發生，沒有動畫就不存在。

本 change 帶上保留參數的測試 (以 `grep` 找出設定寫入失敗旗標、且斷言關閉後呈現下一個提示或確認框的測試，主對話 2026-11-13 逐一閱讀確認)：

- `LookupManagementTests`：`testRequestDeletion_刪除寫入失敗_顯示提示並保留項目`、`testRequestDeletion_長按選單刪除寫入失敗_項目保留且筆數不變`、`testRequestDeletion_寫入失敗提示關閉後再刪除_重新呈現確認框`、`testAddItem_新增寫入失敗_顯示提示且清單不出現新名稱`。
- `CampaignFlowTests`：`testSaveButtonTapped_開團寫入失敗_表單關閉後顯示失敗提示`、`testConfirmDelete_失敗提示關閉後再次刪除_確認框仍可開啟`。

`LookupManagementTests/testRequestDeletion_滑動刪除後取消_項目保留且筆數不變` 也設定寫入失敗，但它只驗證取消後項目保留，沒有「關閉後呈現下一個提示」，不帶。開團兩條沒有做變異實驗，依同一類競態推定需要保留。

這些測試保留動畫，仍可能碰到閒置等待；它們都不轉向 (主對話 2026-11-13 閱讀測試本體確認)，有表單輸入的步驟仍可能走到鍵盤路徑的觸發，但只有 6 條，風險低於原本全部測試都暴露。

### 關閉動畫的判斷抽成可注入的函式並以單元測試守住

`BLUITestHarness` 新增 `applyViewAnimationPolicy(for:setAnimationsEnabled:)`：測試模式且未帶保留參數時呼叫一次 `setAnimationsEnabled(false)`，其餘不呼叫。`prepareIfNeeded()` 以 closure 傳入 `UIView.setAnimationsEnabled`。

單元測試以 spy closure 記錄呼叫，不碰 UIKit 的全域狀態，可在單元測試程序平行執行。`BLUITestConfiguration.init(arguments:)` 可直接建構，不依賴 `BLUITestConfiguration.current`。

替代方案：直接在單元測試呼叫 `UIView.setAnimationsEnabled` 後還原，會改到同一程序其他測試 (含 snapshot) 看到的全域狀態，需要序列化，不採用。

### 以原始碼掃描守住動畫開關只由 harness 關閉

新增掃描守門，剝除註解與字串後檢查 `BuyLedger/` (App target，含生成檔) 的原始碼：

- 完整接線 `UIView.setAnimationsEnabled($0)` 恰好出現 1 次，位於 `App/Testing/BLUITestHarness.swift`：守住接線沒被刪掉、也沒有被改成 `!$0` 等寫法。
- 任何 `setAnimationsEnabled(` 呼叫 (不限前綴) 只出現在 `App/Testing/BLUITestHarness.swift`，且恰好 2 次 (接線與 `applyViewAnimationPolicy` 內的 `setAnimationsEnabled(false)`)：守住沒有其他地方改動這個全域開關、harness 內也沒有多出的呼叫，包含 `UIView.self.`、`Self.` 或非字面值參數的寫法。
- 任何檔案 (含 harness) 都不出現 `setAnimationsEnabled(true`：守住 harness 內也沒有以字面值重新開啟。

三條規則在 3.1 審查後由原本的兩條加強而來 (t17 指出只比對前綴時擋不住 `!$0` 與非字面值參數，主對話採用)。

單元測試守「判斷正確」，掃描守門守「判斷有接到 UIKit 且沒有別處改它」，兩者互補。掃描守門釘住實作細節，但這個契約本身就是「這個呼叫存在且沒有別處改它」；日後移除設定時一併刪除。寫法比照 `BuyLedgerTests/Guards/BottomBarPlacementScanTests.swift` (`SwiftSourceFiles` 列舉、剝除註解與字串後比對)。

### 以同一輪的基準與修正後連跑驗證效果

一次性的效果驗證與常駐守門分開。效果驗證在同一天、同一台 iPad Air 11-inch (M4) iPadOS 27.0 模擬器上，先跑未修改的建置當基準，再跑修正後的建置，涵蓋三類觸發：

| 類別 | 測試 | 基準次數 | 修正後次數 |
| --- | --- | --- | --- |
| 轉向 | `AdaptiveNavigationContinuityUITests/testSidebarPreferenceSurvivesTabChange_側邊欄展開_目的地與徽章正確` | 12 | 24 |
| 搜尋欄 | `AdaptiveNavigationContinuityUITests/testSearchKeepsOrClearsSelection_訂單清單並排_命中保留選取且排除後清空` | 3 | 3 |
| 鍵盤輸入 | `OrderEditInputFocusUITests/testFocusChargedAmountFromLeft_零值輸入_即時取代且失焦保留` | 3 | 3 |
| 鍵盤輸入 | `OrderEditInputFocusUITests/testFocusCardFeeRate_未輸入即失焦_還原原值` | 3 | 3 |

- **訊息來源**：`mobilebuildmcp simulator test` 輸出的 Build Logs 檔 (含 XCTest 的步驟紀錄，主對話 2026-11-13 確認訊息會出現在這裡)，以 `grep -c 'App animations complete notification not received'` 計數；先在基準的 log 確認抓得到 (基準沒有觸發時，記為「當天未重現」，該類別的修正後結果只算回歸證據)。
- **第二個偵測量**：每次迭代的耗時。轉向測試每次不超過 120 秒 (正常 38 至 47 秒、觸發時 343 秒以上，量測值)；其他測試不超過 10 分鐘上限。
- **實際執行數**：result bundle 中每條測試的執行次數等於指定次數，0 skip。
- **統計說法**：0 次觸發不證明永遠不會發生。以轉向測試為例，24 次 0 觸發代表修正後觸發率很可能低於約 12% (rule of three，3/24，估算)；與同輪基準比較才有意義。

### 改寫規則檔的閒置等待條目並補手動實測說明

`.claude/rules/ios-ui-tests.md` 中以「iPad 模擬器上 XCUITest 可能多次等滿 60 秒閒置」開頭的主 bullet 與其兩個子 bullet 刪除，新條目移到「資料與相依」一節 (主題是 harness 設定，不是鍵盤)。舊條目的「長時間連續執行會變多」未經證實、「單獨重跑至多兩次」在設定生效後不再適用，一併刪除。

`-BLUITest` 也是 `ui-automation` 手動實測取得種子資料的方式，但 `.claude/rules/ios-ui-tests.md` 只在碰到 UI 測試檔時載入，所以 `apps/ios/CLAUDE.md` 的手動實測一節另補一句。

## Implementation Contract

**行為**

- 帶 `-BLUITest`、不帶 `-BLUITestKeepViewAnimations` 的 Debug 啟動：harness 啟用時關閉 UIKit 的 UIView 動畫一次，程序結束前不會重新開啟。
- 帶 `-BLUITest` 與 `-BLUITestKeepViewAnimations`：不碰動畫開關。
- 不帶 `-BLUITest` 的啟動 (含 `LaunchPerformanceTests` 以 `XCUIApplication().launch()` 啟動、只帶 `-BLUITestKeepViewAnimations`)：不碰動畫開關。
- Release 建置：沒有 harness，行為不變。

**App 端程式碼**

- `BLUITestConfiguration`：新增 `let shouldKeepViewAnimations: Bool`，doc comment 寫明旗標 `-BLUITestKeepViewAnimations` 與預設 (不保留，即關閉動畫)；`init(arguments:)` 以 `arguments.contains("-BLUITestKeepViewAnimations")` 解析，位置與其他布林旗標並列。
- `BLUITestHarness`：
  - 新增 internal `static func applyViewAnimationPolicy(for configuration: BLUITestConfiguration, setAnimationsEnabled: (Bool) -> Void)`：`configuration.isEnabled` 為 `true` 且 `shouldKeepViewAnimations` 為 `false` 時呼叫一次 `setAnimationsEnabled(false)`，其餘不呼叫。多條件 `guard` 的 `else {` 與最後一個條件同行。doc comment 說明為何關閉 (介面變化後 XCTest 的閒置等待可能一直逾時) 與保留參數的用途。
  - `prepareIfNeeded()` 在 `configuration.isEnabled` 的 `guard` 之後、`let container: ModelContainer` 之前呼叫它，以 closure 傳入 `UIView.setAnimationsEnabled($0)`；doc comment 補一行 `- Note:` 說明 UI 測試模式預設關閉 UIView 動畫。
  - import 依字母序補上 `UIKit`。

**UI 測試端程式碼**

- `LaunchOptions`：在既有 stored property 的最後新增 `var shouldKeepViewAnimations = false`，doc comment 寫明旗標；`launchArguments` 在值為 `true` 時加入 `-BLUITestKeepViewAnimations`，位置在既有旗標之後。
- 「以啟動參數讓呈現競態測試保留動畫」列出的 6 條測試，啟動時 `shouldKeepViewAnimations` 設為 `true`，寫法沿用各測試現有的 `LaunchOptions` 組法 (初始化參數或 `options.` 指定)；其他測試不改。

**測試**

- `BuyLedgerTests/App/Testing/BLUITestHarnessViewAnimationTests.swift` (新檔，Swift Testing，比照 `BLUITestConfigurationTests` 以 `#if DEBUG` 圈住、`@testable import BuyLedger`；呼叫 `@MainActor` 的 harness，所以測試方法標 `@MainActor`)：參數化測試 `applyViewAnimationPolicy_各種啟動參數_只在測試模式且未保留時關閉一次`，以 spy closure 收集呼叫，預期值寫字面值：

  | 啟動參數 | 預期呼叫 |
  | --- | --- |
  | `["-BLUITest"]` | `[false]` |
  | `["-BLUITest", "-BLUITestSeed", "lookupsOnly"]` | `[false]` |
  | `["-BLUITest", "-BLUITestKeepViewAnimations"]` | `[]` |
  | `[]` | `[]` |
  | `["-BLUITestKeepViewAnimations"]` | `[]` |

- `BLUITestConfigurationTests`：補上 `shouldKeepViewAnimations` 的解析 (未帶旗標為 `false`、帶旗標為 `true`)，寫法沿用該檔現有的旗標解析測試。
- `BuyLedgerTests/Guards/ViewAnimationSwitchScanTests.swift` (新檔)：依「以原始碼掃描守住動畫開關只由 harness 關閉」的三條規則，各一個測試；斷言訊息列出命中的檔案相對路徑與次數；同時斷言掃描到的 `.swift` 檔數大於 0。

**規則檔文字** (`.claude/rules/ios-ui-tests.md`：刪除舊的閒置等待主 bullet 與其子 bullet；新條目接在「資料與相依」一節以「`DependencyValues+BLUITestOverrides.swift` 以注入的」開頭的主 bullet 與其子 bullet 之後，逐字使用)：

```markdown
- **UI 測試模式關閉 UIView 動畫，App 與 harness 都不重新開啟；驗證呈現競態的測試以 `LaunchOptions.shouldKeepViewAnimations` 保留動畫**：iPad 模擬器上轉向、鍵盤輸入或搜尋欄切換之後，同一個 App 程序可能每次等閒置都等滿 60 秒 (log 出現 `App animations complete notification not received`)，直到 App 被終止；關閉動畫後不再出現，機制推測是 XCTest 對動畫的追蹤失步。
    - 驗證「sheet、確認框或提示關閉之後接著呈現提示或確認框」的測試要帶 `shouldKeepViewAnimations`：這類競態只發生在關閉動畫期間，沒有動畫時測試偵測不到 (參考 `LookupManagementTests` 的刪除寫入失敗案例)。
    - 等框線穩定、鍵盤就位、等視窗轉向等 helper 照常保留：保留動畫的測試仍需要它們，也是日後移除這個設定的前提。
    - UI 測試不驗證動畫本身 (時長、減少動態效果的替代動畫)，這類行為改由單元測試或正式模式、實機確認。
    - 判讀：未保留動畫的測試再出現這段訊息時，先確認 harness 的設定仍在；設定仍在，或訊息出現在保留動畫的測試，就記錄觸發前的步驟並回報，不自行改 helper 或 App。
    - 升級 Xcode 或 iPad 模擬器執行環境時，重新確認是否仍需要關閉動畫：暫時拿掉 harness 的呼叫，跑一次 iPad 完整 UI 回歸，訊息 0 次且全部通過才可移除。
```

**`apps/ios/CLAUDE.md` 文字**：「`ui-automation` 實測」一節中以「**`--launch-args`／`--extra-args` 的純數字值會驗證失敗**」開頭的主 bullet 下方新增一個子 bullet (2 格縮排，與該檔既有子 bullet 一致)，逐字使用：`` - `-BLUITest` 模式會關閉 UIView 動畫：要看轉場或逐格確認動畫時加 `-BLUITestKeepViewAnimations`，或改用正式模式。 ``

**README 文字**：`apps/ios/README.md` 中以「UI 測試以啟動參數宣告前置條件」開頭的段落，在「整套 harness 以 `#if DEBUG` 圈住、不進 Release。」之後補一句，逐字使用：`` UI 測試模式會關閉 UIView 動畫，驗證呈現競態的測試以 `-BLUITestKeepViewAnimations` 保留。 ``

**驗收**

- 建置：`BuyLedger` 與 `BuyLedgerUITests` scheme 在模擬器建置通過。
- 單元測試 TDD：`BLUITestHarnessViewAnimationTests` 先以空實作 (不呼叫 closure) 跑出 `["-BLUITest"]` 那一列失敗，再補實作轉綠；`BLUITestConfigurationTests` 的新案例在未解析旗標時失敗。
- 掃描守門：實作後通過；變異檢查各自讓預期的測試失敗，還原後雜湊一致：刪除 harness 的接線 → 第一、二條失敗；接線改成 `!$0` → 第一條失敗；在 harness 以外的 App 檔加一行 `UIView.setAnimationsEnabled(true)` → 第二、三條失敗 (第一條不受影響)；在 harness 內加一行非字面值參數的 `UIView.setAnimationsEnabled(...)` → 第二條失敗。
- 效果驗證：依「以同一輪的基準與修正後連跑驗證效果」的表與判準。
- 偵測力：修正後的建置套用 proposal 表中的變異 (主檔寫入失敗提示改回與確認框共用 `destination`)，`LookupManagementTests` 的三條刪除寫入失敗測試各跑 3 次，`testRequestDeletion_寫入失敗提示關閉後再刪除_重新呈現確認框` 至少 1 次失敗。
- 執行期確實關閉動畫：同一個變異下，暫時拿掉 `testRequestDeletion_寫入失敗提示關閉後再刪除_重新呈現確認框` 的 `shouldKeepViewAnimations` 再跑 3 次，預期全部通過 (漏抓)，與保留參數時的失敗對照，證明正式接線在執行期關閉了動畫；單元測試只用替身 closure、掃描只比對文字，都證明不了這點。兩項暫改都還原後雜湊一致。
- 完整回歸：iPhone 17 iOS 26.5 完整 `BuyLedgerTests` 0 失敗 (既有 3 條預期失敗除外)，snapshot 不重錄；iPad 先單獨跑 `KeyboardDismissTests` 通過，再於 iPad Air 11-inch (M4) iPadOS 27.0 與 iPhone 17 iOS 26.5 各跑一次完整 UI 回歸 (`-only-testing:BuyLedgerUITests`、`-skip-testing:BuyLedgerUITests/LaunchPerformanceTests`)，0 失敗；log 中上述訊息的次數與發生的測試照實記錄，未保留動畫的測試應為 0 次。
- 文件：規則檔、`apps/ios/CLAUDE.md`、README 的變更與上方文字逐字相同，三檔沒有其他改動；依效果驗證的結果核對文字仍成立。

**範圍**

- 範圍內：本節列出的 App 端、UI 測試端、單元測試與三份文件。
- 範圍外：Feature 與 Design System 的動畫寫法、UI 測試 helper 的等待邏輯、其他測試的 `LaunchOptions` (完整回歸若有失敗，先回報再決定是否另開 change)。

## Risks / Trade-offs

- [依賴動畫過程的 helper 在沒有動畫時行為改變，例如等框線連續相同、無慣性拖曳、`XCUIApplication+SheetInteraction` 的下滑關閉 sheet] → 結構上都是「連續取樣相同」或以最終狀態為終止條件 (五位審查者靜態閱讀一致)，實際行為由兩台完整回歸確認；失敗先回報，不在本 change 內改 helper。
- [修正對鍵盤與搜尋欄路徑無效] → 效果驗證涵蓋這兩類並與同輪基準比較；無效時記錄結果並回報，規則檔的觸發描述依實測修正。
- [保留動畫的測試仍會碰到閒置等待] → 只有 6 條、都不轉向；碰到時依規則檔判讀記錄回報。
- [日後新增呈現競態測試時忘了帶保留參數] → 規則檔寫明判準；這類測試本來就以變異驗證確認會失敗，忘了帶時變異驗證會先發現。
- [日後 Xcode 或 iPadOS 修正了失步，這個設定變成多餘] → 規則檔寫明升級時的重新確認方式與移除條件。
- [測試環境與正式環境的時序不同] → 呈現競態由保留參數守住；其他動畫相關問題本來就不在 UI 測試的斷言範圍，規則檔寫明改由單元測試或正式模式、實機確認。

## 實作與驗證

### 基準量測 (1.1)

主對話 2026-11-13 在未修改的建置 (`main` `59c01fd`) 上，於 iPad Air 11-inch (M4) iPadOS 27.0 模擬器量測；先單獨跑 `KeyboardDismissTests` 2 條通過。訊息次數取自 `mobilebuildmcp` 的 Build Logs 檔 (`grep -c 'App animations complete notification not received'`)，執行數取自 result bundle 摘要。

| 類別 | 測試 | 次數 | 通過 | 訊息次數 | 每次耗時 (秒) |
| --- | --- | --- | --- | --- | --- |
| 轉向 | `testSidebarPreferenceSurvivesTabChange_側邊欄展開_目的地與徽章正確` | 12 | 12 | 0 | 44.1 至 48.2 |
| 搜尋欄 | `testSearchKeepsOrClearsSelection_訂單清單並排_命中保留選取且排除後清空` | 3 | 3 | 0 | 58.9 至 62.5 |
| 鍵盤輸入 | `testFocusChargedAmountFromLeft_零值輸入_即時取代且失焦保留` | 3 | 3 | 0 | 36.3 至 36.8 |
| 鍵盤輸入 | `testFocusCardFeeRate_未輸入即失焦_還原原值` | 3 | 3 | 0 | 41.7 至 42.8 |

- 三類都「當天未重現」：修正後 (4.2) 的連跑只能當回歸證據，不能單獨證明修正降低了觸發率。
- 修法的依據仍是同日稍早的調查：未關閉動畫 18 次觸發 4 次、關閉動畫 16 次 0 次。其中 3 次觸發發生在 App 內掛著暫時診斷 (每 1 秒或每 0.25 秒掃描圖層) 的建置，關閉動畫的 16 次也掛著診斷；診斷可能提高觸發率，兩組條件一致，但與今天未掛診斷的基準不能直接比較。
- 基準的 Build Logs 沒有這段訊息；同一個 `grep` 對同日稍早停掉的 iPad 完整回歸 log 計得 3 次，確認這個取得方式抓得到。

### 實作 (2.1 至 2.4)

- 2.1 (t16) 依 TDD 分兩次交付：先交測試與空實作，主對話在 iPhone 17 iOS 26.5 跑 `BLUITestHarnessViewAnimationTests` 與 `BLUITestConfigurationTests`，14 個測試中只有預期的 3 個失敗 (參數化測試的 `["-BLUITest"]` 列實得 `[]`、`init_帶保留動畫旗標_保留動畫`、`init_提供有效旗標值_解析全部設定`)；補完實作後全部通過。
- 2.2 (t1n) 的掃描守門寫好時 harness 已接線，RED 改由 4.1 的變異檢查取得。
- 2.3 (t9) 完成後以 iPad 跑一次 `testRequestDeletion_寫入失敗提示關閉後再刪除_重新呈現確認框` 通過，確認 UI 測試端可編譯、新參數可啟動。
- 2.4 (t8) 的 `apps/ios/CLAUDE.md` 子 bullet 原依 design 寫成 4 格縮排，該檔既有子 bullet 是 2 格，主對話改為 2 格並同步 design。

### 審查 (3.1)

t17 唯讀審查並逐檔做 style 閘門 (審查前後檔案雜湊一致)，主對話同時審查；沒有 Critical，8 項 Warning、6 項 Suggestion，主對話代選全部採用：

- 程式與測試：參數化測試資料改 `private static let`；測試宣告與一處 `#expect` 未超過行寬卻斷行，改回一行；測試檔未用到的 `import Foundation` 移除 (建置確認)；`LaunchOptions` 與 `BLUITestConfiguration` 新屬性的 doc comment 改為「是否…」並去除重複；harness 與測試的兩處措辭。
- 掃描守門由兩條加強為三條 (見「以原始碼掃描守住動畫開關只由 harness 關閉」)：原本只比對 `UIView.setAnimationsEnabled` 前綴，擋不住接線改成 `!$0` 或以 `UIView.self.`、非字面值參數改動開關。
- 文件：README 全形句號後多出的半形空格刪除；規則檔新條目前後多出的空行刪除 (該節主 bullet 之間沒有空行)，並補回刪舊條目時一起刪掉的「轉向測試」標題前空行。這兩項源自主對話派工說明的錯誤。
- 驗證計畫：4.1 的變異預期依三條規則改寫 (原敘述「每項只讓對應測試失敗」對「加一行 `setAnimationsEnabled(true)`」不成立)；4.3 補一步「同一變異下拿掉保留參數應漏抓」，證明正式接線在執行期確實關閉了動畫。
- 規格與 proposal：spec 的「a confirmation」改為「a confirmation dialog」(`OrderMergeTests` 的 sheet 交接不屬於這類，不帶保留參數)；proposal 的「三種啟動參數組合」更正為四種。
- 修正後主對話在 iPhone 17 iOS 26.5 重跑三個單元測試類別，17 個測試全部通過。

### 守門變異與單元測試 (4.1)

主對話在 iPhone 17 iOS 26.5 逐項暫改、只跑相關測試類別，每項還原後檔案雜湊與改前一致：

| 變異 | 失敗的測試 | 通過的測試 |
| --- | --- | --- |
| 刪除 harness 的接線 | `uiViewSetAnimationsEnabled_生產碼_只在UI測試harness以參數接線一次` | 其餘 2 條掃描測試 |
| 接線改成 `UIView.setAnimationsEnabled(!$0)` | 同上 | 其餘 2 條掃描測試 |
| `AppDelegate.swift` 檔尾加一個呼叫 `UIView.setAnimationsEnabled(true)` 的函式 | `setAnimationsEnabled_harness以外_不出現`、`setAnimationsEnabledTrue_生產碼_不出現` | 接線那一條 |
| `applyViewAnimationPolicy` 的 `guard` 拿掉保留參數條件 | `applyViewAnimationPolicy_各種啟動參數_只在測試模式且未保留時關閉一次` | — |

- 第三項第一次放在沒有 import UIKit 的 `AppLaunchConfigurator.swift`，編譯失敗 (不算失敗證據)，改放 `AppDelegate.swift` 重做。
- 完整 `BuyLedgerTests`：2080 個，2077 通過、0 失敗、0 略過、3 個既有預期失敗；snapshot 未重錄。
- 上表是 verify／review 修正前的舊第二條規則 (排除 harness) 跑出的結果；新規則下的變異結果見「verify／review 建議修正」。

### 修正後連跑 (4.2)

同一台 iPad Air 11-inch (M4) iPadOS 27.0 模擬器、修正後的建置，訊息與執行數的取法同基準：

| 類別 | 測試 | 次數 | 通過 | 訊息次數 | 每次耗時 (秒) | 基準耗時 (秒) |
| --- | --- | --- | --- | --- | --- | --- |
| 轉向 | `testSidebarPreferenceSurvivesTabChange_側邊欄展開_目的地與徽章正確` | 24 | 24 | 0 | 38.7 至 44.5 | 44.1 至 48.2 |
| 搜尋欄 | `testSearchKeepsOrClearsSelection_訂單清單並排_命中保留選取且排除後清空` | 3 | 3 | 0 | 56.3 至 59.8 | 58.9 至 62.5 |
| 鍵盤輸入 | `testFocusChargedAmountFromLeft_零值輸入_即時取代且失焦保留` | 3 | 3 | 0 | 34.3 至 35.1 | 36.3 至 36.8 |
| 鍵盤輸入 | `testFocusCardFeeRate_未輸入即失焦_還原原值` | 3 | 3 | 0 | 40.9 至 42.5 | 41.7 至 42.8 |

- 全部未超過耗時上限 (轉向 120 秒、其他 10 分鐘)，0 skip、0 失敗。
- 基準當天三類都未重現，這些結果只證明關閉動畫後沒有回歸、測試略為變快，不單獨證明觸發率下降；修法效果的依據見「基準量測 (1.1)」。

### 偵測力與執行期關閉 (4.3)

修正後的建置暫時把主檔寫入失敗提示改回與確認框共用 `destination` (proposal 表中的變異)，在 iPad Air 11-inch (M4) iPadOS 27.0 模擬器執行：

| 測試 | 保留參數 | 次數 | 失敗 |
| --- | --- | --- | --- |
| `testRequestDeletion_刪除寫入失敗_顯示提示並保留項目` | 帶 | 3 | 3 |
| `testRequestDeletion_長按選單刪除寫入失敗_項目保留且筆數不變` | 帶 | 3 | 2 |
| `testRequestDeletion_寫入失敗提示關閉後再刪除_重新呈現確認框` | 帶 | 3 | 3 |
| `testRequestDeletion_寫入失敗提示關閉後再刪除_重新呈現確認框` | 暫時拿掉 | 3 | 0 |

- 帶保留參數時缺陷仍被抓到，偵測力保留。
- 同一條測試拿掉保留參數後 3 次全漏，與帶參數時 3 次全抓對照，證明正式接線在執行期確實關閉了動畫 (單元測試與掃描守門證明不了這點)。
- 兩項暫改還原後，`LookupManagementFeature.swift` 與 `LookupManagementTests.swift` 的雜湊與暫改前一致。

### 兩平台完整 UI 回歸 (4.4)

主對話執行，數字取自 xcresult 摘要，訊息次數以 `grep -c` 計 Build Logs：

| 裝置 | 範圍 | 總數 | 通過 | 失敗 | 略過 | 預期失敗 | 訊息次數 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| iPad Air 11-inch (M4) iPadOS 27.0 | `KeyboardDismissTests` | 2 | 2 | 0 | 0 | 0 | 0 |
| iPad Air 11-inch (M4) iPadOS 27.0 | 完整 UI 回歸 | 252 | 227 | 0 | 24 | 1 | 0 |
| iPhone 17 iOS 26.5 | 完整 UI 回歸 | 252 | 184 | 22 | 45 | 1 | 0 |
| iPhone 17 iOS 26.5 | 清除模擬器後重跑失敗的 22 條 | 22 | 18 | 0 | 4 | 0 | 0 |

- 略過的都是依版面宣告略過的既有案例；預期失敗是既有的 `NavigationScenarioUITests.testSelectTab_App鎖定時根分頁不可用_記錄診斷失敗`。
- 訊息在兩台都是 0 次，未保留動畫的測試與帶保留參數的 6 條都沒有出現。
- iPhone 完整回歸的 22 條失敗都是「轉向後 App 視窗寬仍未大於高」，該輪 22 次轉向全部停在直向 (視窗 402×874)，判讀為模擬器環境狀態：
  - 同一台模擬器上單獨跑 `OrientationLayoutTests.testRotateToLandscape_含開團與訂單資料_首頁附上橫向截圖`：現行建置失敗；暫把 `LaunchOptions.shouldKeepViewAnimations` 預設改為 `true` (保留動畫) 同樣失敗、視窗同樣停在直向，所以不是關閉動畫造成。暫改還原後雜湊與改前一致。
  - 主對話以 `simulator-management erase --shutdown-first` 清除模擬器後開機、設回淺色外觀 (沒有先試規則檔「轉向測試」一節的重開機)，同一條在現行建置通過。
  - 重跑失敗的 22 條：0 失敗，22 次轉向全部成功；4 條在轉向後依版面略過 (iPhone 不是 regular 版面)。
  - 規則檔「轉向測試」一節已記載這種環境狀態，不另增條目。
  - 使用者確認以「第一輪加上清除後重跑失敗的 22 條」作為 iPhone 的回歸結果，不再整套重跑。
- 文件核對：helper 照常保留下兩台都通過、訊息 0 次，保留參數的行為與 4.3 一致，規則檔、`apps/ios/CLAUDE.md` 與 README 的新增文字仍成立。
- 文件同步鐵則 (對照 `git status --short` 逐列)：
  - `BLUITestHarness.swift`、`BLUITestConfiguration.swift`：新的硬規則 (UI 測試模式關閉 UIView 動畫、`-BLUITestKeepViewAnimations` 保留)，已寫進規則檔「資料與相依」、`apps/ios/CLAUDE.md` 的 `ui-automation` 實測一節與 README 的 UI 測試段落；舊的 60 秒閒置等待條目已刪除。
  - `LaunchOptions.swift`、`LookupManagementTests.swift`、`CampaignFlowTests.swift`：保留參數的使用時機，已寫進規則檔。
  - `BLUITestConfigurationTests.swift` 與兩個新測試檔：守門測試，沒有目錄結構或 build、test 指令變動；README 的專案結構不列個別守門檔，不需改。
  - `.claude/rules/ios-ui-tests.md`、`apps/ios/CLAUDE.md`、`apps/ios/README.md`、`openspec/changes/ui-test-disable-view-animations/`：本次同步的文件與 change 本身。
  - 結論：有影響，已同步。

### verify／review 建議修正

`/spectra-verify` 與 `/spectra-review` 都沒有 Critical 或 Warning；3 項 Suggestion 由使用者選定全部採納：

- 掃描守門第二條 (verify)：不再排除 harness，改斷言 `setAnimationsEnabled(` 只在 `App/Testing/BLUITestHarness.swift` 出現 2 次，測試改名 `setAnimationsEnabled_生產碼_只在harness接線與判斷各出現一次`；原規則擋不住 harness 內多出的非字面值呼叫。t16 實作。
- 單元測試 (verify)：`scenarios` 補 `["-BLUITest", "-BLUITestSeed", "lookupsOnly"]` → `[false]`，對上 spec 範例的「任何種子資料」。t16 實作。
- 規則檔「判讀」(review)：改為也涵蓋保留動畫的測試，與「保留動畫的測試仍會碰到閒置等待」的風險處置一致。t8 實作。
- 本檔的掃描規則、單元測試表、規則檔文字與驗收的變異預期已同步。

t17 唯讀審查修正 (含 style 閘門)：沒有 Critical、沒有 style 違規。

- 2 項 Warning (變異預期與紀錄仍是舊規則)：主對話採納，改寫驗收並重跑下表；已勾選的 tasks 描述保留原文。
- Suggestion「第二條補 doc comment 的掃描範圍說明」：主對話採納，t16 實作。
- Suggestion「第二條改成也抓沒有呼叫的函式參照 (例如 `let toggle = UIView.setAnimationsEnabled`)」：主對話不採納，寫法罕見、正式程式碼 0 處，本檔規則也只守「呼叫」。

主對話在 iPhone 17 iOS 26.5 以新規則逐項暫改、只跑 `ViewAnimationSwitchScanTests`，每項還原後雜湊與改前一致：

| 變異 | 失敗的測試 | 通過的測試 |
| --- | --- | --- |
| 刪除 harness 的接線 | `uiViewSetAnimationsEnabled_生產碼_只在UI測試harness以參數接線一次`、`setAnimationsEnabled_生產碼_只在harness接線與判斷各出現一次` (harness 剩 1 次) | `setAnimationsEnabledTrue_生產碼_不出現` |
| 接線改成 `UIView.setAnimationsEnabled(!$0)` | `uiViewSetAnimationsEnabled_生產碼_只在UI測試harness以參數接線一次` | 其餘 2 條 |
| `AppDelegate.swift` 檔尾加一個呼叫 `UIView.setAnimationsEnabled(true)` 的函式 | `setAnimationsEnabled_生產碼_只在harness接線與判斷各出現一次`、`setAnimationsEnabledTrue_生產碼_不出現` | 接線那一條 |
| harness 檔尾加一個呼叫 `UIView.setAnimationsEnabled(flag)` 的函式 | `setAnimationsEnabled_生產碼_只在harness接線與判斷各出現一次` (harness 3 次) | 其餘 2 條 |

- 三個單元測試類別 17 個全過，`applyViewAnimationPolicy_各種啟動參數_只在測試模式且未保留時關閉一次` 為 5 個案例。
- 完整 `BuyLedgerTests`：2080 個，2077 通過、0 失敗、0 略過、3 個既有預期失敗；snapshot 未重錄。
- 修正只改測試檔與規則檔，App 程式碼與 UI 測試未變，UI 回歸沿用 4.4 的結果。
