## Context

- ios-dev-kit 4.1.0 (`references/file-templates.md` tests 一節、`references/formatting.md`「Extension 的使用時機」) 禁止跨檔 extension 自己的型別，測試 target 同樣適用；測試型別過大時拆成獨立的 `<TypeUnderTest><行為>Tests`，多個測試型別共用的 helper 不留在其中一個型別內。例外只有 `<Model>+Fixture.swift` 與 TCA 的 `+Path`／`+Destination`。
- 現況 (2026-10-23 於 `19ef9ccc` 量測)：`apps/ios/BuyLedgerTests` 與 `apps/ios/BuyLedgerUITests` 有 309 個含 `+` 的檔案，逐檔分類見 `reference/file-list.tsv`：
  - split-test 244 個：帶測試的跨檔 extension
  - guard-type 32 個：Guards 的掃描器、lexer、規則與情境資料
  - support 18 個：掛在測試型別上的 fixture 與 helper，沒有測試
  - merge 8 個：同一個 Page Object 或 UI 測試類別的片段，以及 `TestDependencies+Calendar`
  - page-object 2 個：其實是另一個畫面的 Page Object 片段
  - keep 5 個：延伸非本模組型別，kit 允許
- 拆分前的測試型別之間有 440 處 `<型別>.<成員>` 跨族群引用 (以 `reference/check_test_extensions.py --phase1` 量測，不含 Guards 之間)，例如 `BuyLedgerDatabaseTests.makeInMemoryDatabase` 93 處、`OrdersFeatureTests.makeOrder` 59 處。這些引用橫跨多個拆分任務的檔案，是平行開發的熱點。
- 快照測試的基準圖目錄跟著呼叫 `assertSnapshot` 的測試檔名 (`__Snapshots__/<檔名>/`)，改檔名就要搬目錄。
- CI (`.github/workflows/ci.yml`) 以 `-skip-testing:BuyLedgerTests/SnapshotTests` 與 `-skip-testing:BuyLedgerTests/OrdersFeaturePerformanceTests` 略過快照與效能測試；`apps/ios/BuyLedger.xctestplan` 的 `skippedTests` 也列了 `OrdersFeaturePerformanceTests`。
- 本 change 只動測試 target、CI 參數與文件，App target 的程式碼與行為不變。
- 第 1 至 4 節完成後 (2026-10-24)，4.1 style 閘門另外列出既有的測試寫法問題與說明文字問題，當時列為範圍外；使用者同日決定在本 change 一次改完 (見「測試寫法這輪一併修正」)。量測 (2026-10-24，工作樹)：
  - 規模：`BuyLedgerTests` 474 檔約 8.6 萬行、`BuyLedgerUITests` 78 檔約 1.2 萬行
  - `throws(any Error)` 264 處 (68 檔)、`Issue.record` 24 處、UI 測試類別 40 個 (不含 `BLUITestCase`)，以 grep 量測
  - tuple 形式的 `@Test(arguments:)` 約 40 處：以 grep 找出候選後估計，多行陣列未逐一展開，實際數量以第 6 節各任務的逐檔審查為準
  - 預期值、Given、等待、多組 When／Then 等語意類問題沒有可靠的機械量測，閘門只抽到部分位置，第 6 節逐檔審查才會得到完整清單

## Goals / Non-Goals

**Goals:**

- 測試 target 內不再有跨檔 extension 自己的型別，只剩 5 個保留檔含 `+`
- 共用 helper 不再掛在任何測試型別上，依使用範圍放到固定位置
- 測試函式總數、快照基準圖不變，完整單元測試與 UI 回歸結果與基準一致 (第 1 至 4 節)；第 5 至 7 節只因拆開多組 When／Then 而增加測試數
- 刪除 `apps/ios/CLAUDE.md` 的「測試拆檔」過渡例外
- 兩個測試 target 的寫法與說明文字符合 kit 與專案測試規則，style 閘門不再有範圍外的測試寫法項目

**Non-Goals:** 見 proposal 的 Non-Goals。第 1 至 4 節不調整測試內容、命名與 Mocks、Fixtures 既有檔案；第 5 至 7 節依「測試寫法這輪一併修正」取代這條限制。

## Decisions

### 拆出的測試型別命名

決策來源：主對話依 kit 決定

`<Base>Tests+<Suffix>.swift` → `<Base><Suffix>Tests.swift`，型別同名，放在原資料夾 (如 `CampaignFeatureTests+Reminders` → `CampaignFeatureRemindersTests`)。逐檔名稱已寫進 `reference/file-list.tsv` 的 `target_type`，已確認與既有型別不衝突。

- 快照：`SnapshotTests+<X>` → `Snapshot<X>Tests`，與上式相同；主型別 `SnapshotTests` 只是空殼，拆完刪除。
- 效能測試：`OrdersFeaturePerformanceTests+FilterSheet` → `OrdersFeatureFilterSheetPerformanceTests`，保留 `PerformanceTests` 結尾，方便辨認為 XCTest 效能測試。
- 替代方案：直接併回主檔。kit 4.x 沒有行數上限，可以併回，但使用者要求「拆成獨立測試型別」，而且 kit 把「依受測行為拆型別」列為過大時的做法；照拆可以讓全部族群用同一條規則，不必逐一判斷是否過大。

### 共用 helper 依使用範圍分三層

決策來源：使用者採納主對話的建議

| 使用範圍 | 位置 |
| --- | --- |
| 只有一個型別用 | 該型別的 `private` 成員 |
| 同一資料夾內多個型別共用 | 同資料夾的 `<Base>TestSupport` (無 `case` 的 `enum`，`static` 成員) |
| 跨資料夾共用 | `<Base>TestSupport` 放 `apps/ios/BuyLedgerTests/Support/`；Guards 子資料夾之間共用的掃描型別放 `apps/ios/BuyLedgerTests/Guards/Scanning/` |

- `<Base>` 是原測試型別去掉 `Tests` 的名稱 (如 `OrdersFeatureTests` 的 helper 進 `OrdersFeatureTestSupport`)。一個族群只有一個 TestSupport，位置由使用範圍最廣的成員決定；之後成員範圍擴大時再升級位置。
- Model 資料若是跨 Feature 通用的固定值，照 kit 放 `Fixtures/<Model>+Fixture.swift`；既有的 `makeOrder` 一類 helper 預設值與 `fixture` 不同，維持 helper，不改寫。
- 理由：helper 幾乎只在改同一組測試時才變動，放旁邊改動集中；歸屬清楚，刪除或重寫 Feature 時一起帶走；與正式程式碼「Feature 內 → 共用層」的升級原則一致。
- 替代方案：依 kit 字面全部移到 `Support/`。估計會多出約 25 個只給單一 Feature 用的檔案 (依族群數推估，未逐一量測)，歸屬不清，未採用。
- 提出時 kit 只寫「移到 Fixtures、Mocks 或專案共用的測試 helper」，沒寫可以留在 Feature 資料夾；三層規則已由 ios-dev-kit 4.2.0 收進 `file-templates.md` tests 一節 (見 Open Questions)。

### Guards 的 helper 分檔改成職責型別

決策來源：主對話決定

`<Guard>Tests+<Suffix>` 沒有測試時，改成 `<Guard><Suffix>` 型別 (`<Guard>` 去掉 `Tests` 與結尾的 `Scan`、`Scenario`)，如 `LayerBoundaryTests+Scanner` → `LayerBoundaryScanner`、`DependencyConventionScanScenario+ViewCases` → `DependencyConventionViewCases`。逐檔名稱見 `reference/file-list.tsv`。

- 理由：這些分檔本身是有邏輯的掃描元件 (最多一族 1300 行)，塞進單一 TestSupport 會變成大雜燴；依職責命名的型別也比 TestSupport 好找。
- 被多個 Guards 子資料夾使用的型別 (目前是 `DependencyConventionScanTests` 的 `declaresDependencyKey`、`matches`、`matchingDelimiter`、`blankedCommentsAndStrings`，給 `ServiceOwnership` 用；`DesignSystemSourceScanTests` 的 `StripMode`、`stripCommentsAndStrings`，給 `OrderListSnapshotSourceScanTests` 用) 放 `Guards/Scanning/`。
- 各組的提供者與使用者都在同一個任務內 (2.10 或 2.11)，不需要先抽共用層。

### UI 測試分檔的拆法

決策來源：使用者選擇納入本 change，拆法由主對話決定

- `OrdersScreen+FilterSheet`、`OrdersScreen+CategoryPicker` 各自代表另一個畫面 (各有自己的根元素)，拆成遵循 `Screen` 協定的 `OrderFilterSheetScreen`、`OrderCategoryPickerScreen`；UI 測試的呼叫端 (各約 50 處、6 至 7 個檔) 改成建立對應的 Page Object。
- `OrdersScreen+CategoryReveal`／`+RegularFilters`、`CampaignDetailScreen+Content`／`+Toolbar`、`InsightsScreen+LaunchLoading` 屬於同一畫面，併回主檔，依 kit 分區放入對應的 `// MARK:` extension。
- `OrderFilterSheetTests+Assertions`、`OrderRegularColumnScopeTests+Assertions` 併回各自的測試類別檔，放在同檔的 `// MARK: - Private Method`。

### 快照基準圖只搬不重錄

決策來源：使用者先前的決定

- 每個 `__Snapshots__/SnapshotTests+<X>/` 改名為 `__Snapshots__/Snapshot<X>Tests/`，檔案內容不變；測試函式名稱不變，所以圖檔名也不變。
- agent 以一般的檔案搬移處理，不用 `git mv` (agent 不做 git 寫入)；git 會在提交時辨識為改名。

### CI 逐一列名略過快照

決策來源：使用者選擇

- `.github/workflows/ci.yml` 的 `-skip-testing:BuyLedgerTests/SnapshotTests` 改成每個 `Snapshot<X>Tests` 一條，`OrdersFeaturePerformanceTests` 之外再加 `OrdersFeatureFilterSheetPerformanceTests`。
- `ci-guardrails` 規格要求「以明確的 skip 參數略過快照與效能測試」，逐一列名仍符合，不需改規格。
- 替代方案：快照測試加 tag，CI 改跑排除 tag 的 test plan。新增快照型別時不必維護清單，但要改 CI 流程與規格，未採用。

### 先抽共用 helper 再平行拆分

決策來源：主對話決定

- 依 expand → migrate → contract：
  - 第 1 節先把 440 處跨族群引用的成員搬進 TestSupport，同時改完所有呼叫端。
  - 第 2 節各任務只改自己族群的檔案與自己的 TestSupport，可以平行。
  - 第 3 節最後同步 CI 與文件。
- 1.2 與 1.3 的呼叫端檔案大量重疊 (例如同一個 `OrdersFeatureTests+*.swift` 同時用 `OrderServiceTests.seed` 與 `OrdersFeatureTests.makeOrder`)，只能先後執行。
- 第 2 節各任務的依賴只取決於第 1 節有沒有改到它的檔案，理由寫在各任務的 `[after:]`。

### 主型別沒有測試時刪除主檔

決策來源：主對話決定

`OrdersFeatureTests`、`OrderEditFeatureTests`、`ProjectionWriteBoundaryTests`、`SnapshotTests` 的主檔沒有任何測試，只放 helper：

- helper 依「共用 helper 依使用範圍分三層」移走。
- 主檔沒有內容後刪除。
- 文件中引用這些型別名的地方，在 3.1 改指拆出後的型別或改用族群描述。

### 測試寫法這輪一併修正

決策來源：使用者 (2026-10-24 回覆「這輪一次改」)

- Supersedes：proposal 原本的 Non-Goal「不改任何測試的斷言、Given／When／Then 內容與測試函式名稱；只搬移與改宣告」，以及本文件 Non-Goals 原本的「不調整測試內容與命名」。第 1 至 4 節已完成的工作照原限制執行，不回頭重做；第 5 至 7 節改依下方規則修正。
- 範圍是兩個測試 target 的全部檔案，不限本 change 先前改到的檔：4.1 閘門只審了改到的檔，範圍外項目只是抽樣，逐檔審查才能一次清掉。
- 仍不改 App target：測試寫法問題若要改正式程式碼才能修，記錄下來交給主對話，不在本 change 處理。

### 測試寫法逐檔修正的規則

決策來源：規則條文來自 kit 與專案規則，清單由主對話整理

| 代號 | 規則 | 出處 |
| --- | --- | --- |
| T1 | 預期值不由受測程式產生：不用 production 函式或工廠算預期，不把 Given／When 之後從 store 讀出的值當預期；變動欄位寫字面值，不展開成全欄位字面值 | `.claude/rules/ios-unit-tests.md`「預期值不可由受測程式產生」 |
| T2 | 能直接設進初始 State 的前置條件不用 `send` 建立；必須經 reducer 或 effect 才成立的才在 Given `send`／`receive` | `ios-unit-tests.md`「TCA TestStore」第一條 |
| T3 | 等待 effect 的操作 (`store.finish()`、`clock.advance`、`continuation.yield`／`finish`、`iterator.next()` 這類同步點) 放 Then | `ios-unit-tests.md`「等待 effect 的操作放在 Then」 |
| T4 | 一個測試只有一組 When／Then；多個動作拆成多個測試或改用 `@Test(arguments:)`，新測試照 `<方法>_<情境>_<預期>` 命名 | kit `file-templates.md` tests 一節 |
| T5 | 驗證丟出的錯誤用 `actualError` 寫法 (Given 宣告、When 只 `do`／`catch` 指定、Then `try #require` 後斷言)；測試本體不以 `Issue.record` 表達預期 | kit `file-templates.md` tests 一節 |
| T6 | 測試參數不用 tuple：`@Test(arguments:)` 的 tuple 陣列 (含 `zip`) 改具名 `struct`；超過兩個元素的 tuple 一律改 `struct` | kit `coding-style.md`「型別選擇」 |
| T7 | `throws(any Error)` 改 `throws` | kit 測試樣板寫 `async throws`；兩者等價，統一一種 |
| T8 | Bool 命名 (`is`／`has`／`can`／`should`) 套用到測試參數、`@Test(arguments:)` 欄位與區域變數 | `ios-unit-tests.md` Bool 命名 |
| T9 | Service 測試值只覆寫會被呼叫的 closure，不整個替換 Service | `ios-unit-tests.md`「依賴與替身」 |
| T10 | 恆真或不可能失敗的斷言改成能分辨正確與錯誤實作的斷言 | `ios-unit-tests.md` 寫入失敗與假測試相關條目 |
| T11 | `@MainActor` 範圍：整個型別都需要才標在型別上，否則標在需要的方法上 | kit `file-templates.md` tests 一節 |
| T12 | UI 測試取 searchable 搜尋欄一律 `OrdersScreen.hittableSearchField()` | `.claude/rules/ios-ui-tests.md`「掛不上 identifier 的系統元件」 |
| T13 | Guards 子資料夾之間共用的掃描型別放 `Guards/Scanning/` | `ios-unit-tests.md` 共用 helper 三層 |

- `Issue.record` 只留在回報環境失敗、沒有對應斷言的 helper (例如暫存目錄清除失敗、等待逾時)；決策來源：主對話。
- T1 的子功能 init：測試父層 reducer 的導覽或轉送時，TestStore 的預期 destination 可用子功能的 init (如 `OrderEditFeature.State(…)`) 補齊完整比對，條件是 init 的引數都是字面值或 Given 自建的值 (不讀 store)，且這個測試要驗證的欄位另有字面值斷言；子功能 init 自己的推導由子功能的測試守。理由：子功能 State 的 `draft`、`pickers` 無法以字面值完整組出，強改只會關掉比對或讓測試變弱；決策來源：主對話 (6.6 審查清單提出後裁定)。
- 改到的測試檔一併把舊式英文單段測試名稱改成 `<方法或行為>_<情境>_<預期>` (UI 為 `test` 前綴)：第 6 節的檔案整檔對齊 kit，命名是 kit 規則；量測 (2026-10-24，grep `@Test` 後的函式名稱不足兩個底線)：單元測試 74 條 (6.9 範圍 49、6.7 的 `LookupCatalogTests` 12、6.8 的 Guards 8、6.10 的快照 5)、UI 測試 19 條，改名的識別碼記在各任務下；決策來源：使用者先前的規則「改到的既有測試檔都現在改名」，主對話依此套用到第 6 節。
- UI 測試的 T4：前置導覽一律移到 Given；Then 之後的動作若是在驗證另一個獨立結果才拆成新測試，同一流程的連續步驟 (如開啟、確認、關閉) 保留在一條測試並在說明寫明是情境流程。理由：每條 UI 測試都要重啟 App，全部拆開會新增約 25 條、iPhone 與 iPad 回歸各多約 10 至 15 分鐘 (估計，未實測)；決策來源：使用者 (2026-10-24 選「只拆獨立行為」)。
- T2 與 T3 的交界：前置狀態能直設就直設，這時 Given 不再需要釋放閘門；確實只能經 effect 建立的前置 (審查或實作者查證 State 沒有可直設的欄位) 才在 Given 跑完 `send`／`receive` (含釋放閘門)，並在回報寫明查證結果；決策來源：主對話。
- T6 連 `zip` 一起改：`zip` 產生的也是 tuple，同一條規則不留例外；決策來源：主對話。
- T7 只是寫法統一，不改行為；typed throws 的測試替身仍依 `ios-unit-tests.md` 明確標 `throws(E)`。
- 每個任務先由未參與實作的 haiku-max-implementer 子代理逐檔逐條列出違規清單，實作者照清單修正並補上自己發現的同類項，另一個 agent 唯讀審查，主對話同時審查並跑受影響的測試類別。

### test extension 的 MARK 規則改寫

決策來源：使用者 (2026-10-24 回覆「A+B」：刪掉「只含 `@Test` 的 test extension 不設 MARK」，保留改寫後的「helper、fixture、nested type 所在的 extension 照 kit 的區名設 MARK」)

- 拆檔後已沒有跨檔的 test extension；kit 規定 `@Test` 直接接在測試型別的 Properties 之後 (`file-templates.md` tests 一節)，所以「只含 `@Test` 的 extension」本身就不該存在，舊條文沒有適用對象。
- 唯一的同檔 test extension 是 `OrdersDetailNavigationFeatureTests` (以掃描 `extension … {` 內含 `@Test` 的檔案量測)，測試搬進型別本體。

### 測試說明統一動詞開頭並改白話

決策來源：使用者 (2026-10-24 同意「測試的 `///` 說明統一改成動詞開頭」與「說明文字改白話」)；`@Test` 摘要的具體寫法由 kit 維護 session (`skills-registry-74`) 定案 (ios-dev-kit 4.2.0，見 Open Questions)

- kit `coding-style.md` 註解一節要求摘要動詞開頭，但 `file-templates.md` 的 `@Test` 範例是情境句，兩處矛盾；kit 4.2.0 已定案並改範例，第 7 節照定案原文執行。
- 白話依 kit `coding-style.md` 註解一節的「白話但精簡」與避免冗言贅字；專案規則已定義的領域詞 (如訂單投影) 可保留，架構術語 (委派、子層、容器等) 改寫成實際發生的事。
- 與第 6 節分開：第 6 節改測試語意、第 7 節只改註解，審查重點不同；同一組檔案第 7 節排在第 6 節之後，避免同檔同時被兩個任務改。

### 依資料夾切成 11 組平行修正

決策來源：主對話決定

- 每組約 6 千至 1.1 萬行，讓單一 agent 一個 context 內讀完並修完 (行數以 `wc -l` 量測)。
- 共用層 (`Support/`、`Fixtures/`、`Mocks/`) 歸 6.10 一組；其他組不改共用層與別組資料夾的 TestSupport，需要時記在回報交給主對話排入 6.10 或後續任務，避免檔案重疊。
- UI 測試 (含 T11、T12) 一組，Guards (含 T13) 一組。
- 測試數因 T4 拆分而增加時，各任務記下增加的測試名稱；8.1 依各任務紀錄更新 `check_test_extensions.py` 的數量基準。

### 第 8.2 節接手與獨立重審

決策來源：使用者 (2026-10-24 接受獨立 Codex 代理重審)

- Supersedes：第 8.2 節最後重審必須由 haiku-max-implementer 執行的限制，改由未參與所審範圍實作的獨立 Codex 代理逐檔逐條重審
- 已完成的初次審查與第 6、7 節驗證紀錄保留；最後一輪零違規、完整檔案清單與規則覆蓋的條件不變
- 主對話負責彙整裁定、修正歸屬與建置回歸；修正者不審查自己的修改

## Implementation Contract

- App target 的程式碼與可觀察行為不變；只動測試 target、`.github/workflows/ci.yml`、`apps/ios/BuyLedger.xctestplan` 與文件。
- 完成時 `python3 -I openspec/changes/test-extension-split/reference/check_test_extensions.py` (repo 根目錄) 輸出「[全部] 通過」，代表：
  - 含 `+` 的檔案只剩 5 個保留檔
  - 測試 target 自己宣告的型別沒有被其他檔案 extension
  - unit `@Test` 1744、unit XCTest 測試函式 8 (只計 import XCTest 的檔案)、UI 測試函式 108、快照基準圖 74，皆與基準相同
  - 快照目錄全部改名為 `Snapshot<X>Tests`，且有同名測試檔
  - 拆分前的測試型別不再被其他檔案以 `<型別>.<成員>` 引用
  - `reference/file-list.tsv` 的每一列都已落地
- 第 1 節完成時 `check_test_extensions.py --phase1` 輸出「[共用 helper 階段] 通過」。
- 每個任務完成後由主對話建置並執行該任務改到的測試類別，全數通過；快照測試執行後 `__Snapshots__` 沒有新產生的檔案 (沒有因找不到基準圖而重錄)。
- 拆出的型別各自判斷 `@MainActor` 與 `.serialized`：含 `TestStore` 或 `@MainActor` 隔離型別的才標 `@MainActor`；原主型別有 `.serialized` 或共用可變狀態時，拆出的型別保留同樣的 trait。
- 新增與改到的檔案整檔對齊 ios-dev-kit：
  - 檔頭沿用原 `+` 檔的建立日期
  - 型別有 `///`
  - 分區依 formatting.md
  - 註解為正體中文、半形括號、不加句號
- 完整單元測試與 UI 回歸 (iPhone 與 iPad) 的結果與 1.1 記錄的基準一致：基準中通過的測試全部通過，基準中已知的失敗不增加。
- 第 5 至 7 節：
  - 每個任務結束時，該任務範圍的每個檔案都對過「測試寫法逐檔修正的規則」T1 至 T13 (第 7 節為註解規則)，審查清單逐檔列出，沒有未處理的違規；判定不改的項目寫明理由。
  - 測試名稱只因 T4 拆分、T6 參數改 struct、T8 參數改名而改變，改變的識別碼逐一記在任務下，並同步引用它們的文件。
  - 改寫後的測試仍要能分辨正確與錯誤實作：T1、T10 改過的斷言，實作者在回報寫出它會在什麼錯誤實作下失敗。
  - 全部完成時 `check_test_extensions.py` 依更新後的數量基準輸出「[全部] 通過」，完整單元測試與 UI 回歸與 1.1 基準一致 (新增的拆分測試全數通過)。

## Risks / Trade-offs

- [拆出的型別遺漏原主型別的 suite trait 或共用初始化，導致隔離或順序問題] → 實作者逐一比對原主型別的 `@Suite` 屬性與 `init`；主對話跑該任務的測試類別，完整回歸再確認一次。
- [快照目錄漏搬，被當成缺少基準圖而自動重錄並通過] → 檢查腳本比對 png 總數 74 與目錄名稱；每個任務跑完快照後確認 `__Snapshots__` 沒有新檔，再以 `git status` 確認沒有未預期的新增圖檔。
- [跨族群 helper 在第 2 節才被發現，造成任務間改到同一檔] → 第 1 節以 `--phase1` 檢查清零後才開始依賴它的任務；第 2 節派工前後比對 `git status --short` 確認改動歸屬。
- [任務數 45 個 (第 1 至 4 節 19 個、第 5 至 8 節 26 個)，超過一般建議的 15 個] → 本 change 是大量機械式搬移，依資料夾與族群切開才能三個 agent 平行；每個任務都可獨立驗收，維持單一 change 讓檢查腳本與基準只有一份。
- [測試識別碼改變，CI 或文件仍引用舊名稱] → 3.1 以 grep 檢查 CI、test plan、`apps/ios/CLAUDE.md`、`apps/ios/README.md` 與 `.claude/rules/` 中的舊檔名與舊型別名。
- [Page Object 拆分改到大量 UI 測試呼叫端] → 只改建立 Page Object 的方式與呼叫的接收者，不改操作順序與斷言；以 UI 回歸驗收。
- [改寫預期值或斷言時把測試改弱，綠燈但守不住] → T1、T10 的每處改動在回報寫出會失敗的錯誤實作，審查者逐處核對；必要時主對話做變異驗證 (暫改正式程式碼確認轉紅後還原)。
- [語意類違規沒有機械量測，逐檔審查可能漏看] → 審查與實作分開兩人各看一次，第 8 節 style 閘門再以全規則逐檔審一次。
- [UI 測試類別改標 `@MainActor` 與覆寫的 `setUpWithError` 等 nonisolated 方法衝突] → 目前 40 個子類別都沒有覆寫 lifecycle 方法 (以 grep `override func` 量測)；建置失敗時改回逐方法標註並記錄原因。
- [第 7 節依賴 kit 回覆，可能拖住完成時間] → 第 5、6 節不依賴 kit，可先做完；kit 回覆後第 7 節照新版執行。

## Migration Plan

- 依 tasks.md 的節次執行，每節結束時測試全數可編譯、受影響的測試通過。
- 回退：本 change 只改測試 target、CI 參數與文件，提交前可整批還原；提交後以 revert 該 commit 回退，App 行為不受影響。

## Open Questions

- 已解決 (2026-10-24，kit 維護 session `skills-registry-74` 回覆 ios-dev-kit 4.2.0 定案；使用者在 kit session 指示後已 commit 958a05e、push 並安裝)：
  - `@Test` 與 UI 測試 `func test…()` 的 `///` 摘要一律以「驗證」開頭，接情境與預期寫成一句白話，補上名稱沒說的資訊 (受測的是哪一方、預期細節、為什麼這樣預期)，只把名稱三段換句話說屬複述名稱；helper 與 `setUpWithError` 等其他方法照一般方法動詞開頭；型別寫「`X` 的單元測試」、屬性寫名詞片語、`Bool` 屬性用「是否」問句，不加「驗證」。第 7 節依此執行。
  - 共用 helper 三層規則已收進 kit `file-templates.md` tests 一節；`private` 型別的邊界改寫為「不能出現在非 `private` 成員的簽章或型別裡」(kit 實測 internal 預設引數參照 `private` 成員可以編譯)。
  - 版號依 kit session 的判斷為 MINOR 4.2.0。
