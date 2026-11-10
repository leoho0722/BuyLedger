## Context

`BLAccessibilityID.Common` 的 `loading(_:)`、`loadFailure(_:)`、`loadFailureRetryButton(_:)` 是在 `91e074c` (2026-07-24，建立 UI Automation 測試) 與 `option`、`row`、`indexed` 一起加入的。當時兩條單元測試的名稱 (`loadFailureRetryButtonDerivesFromItsContainer`、`dashboardStateIdentifiersReuseTheCommonFeaturePrefix`) 顯示了用意：重試鍵的 identifier 由失敗容器的 identifier 組出，總覽沿用共用前綴。共用元件 `BLLoadFailureView` 本身不組 identifier，只接收呼叫端傳入的 `retryIdentifier`。這個理由沒寫進規則或 design：archive 裡 `palette-analytics-style-compliance` 寫到分析頁沿用這些 helper，`load-failure-reload-loop` 記錄分析頁當時是內聯呼叫 helper、沒有具名常數，兩處都沒寫理由 (主對話 2026-11-10 以 `git show 91e074c` 與 `git grep` 確認)。

目前 11 個載入狀態常數經 helper 組出，其餘 159 個 `static let` 直接寫字串 (計數方式見 proposal)。`.claude/rules/ios-ui-tests.md` 只規定 App 與測試兩端引用常數、不寫字面值，沒有規定常數定義處的值怎麼寫，所以呼叫端一致，只有定義處有兩種寫法。App 與測試沒有任何地方直接呼叫這三個 helper：除了常數定義，只有 `BLAccessibilityIDTests` 的 2 條測試引用 (主對話 2026-11-10 以 `git grep` 重新確認)。

`BuyLedgerAccessibilityIDs/` 共有 40 個 `static func` (2026-11-10 逐一讀過)：`option`、`row`、`indexed` 本身，要刪的 3 個載入 helper，`Common.selectedItem(_:)`，其餘 33 個都是 `option`／`row`／`indexed` 加上字面值前綴與最後一段參數。`selectedItem` 是唯一的例外，寫法是 `"common.navigation.\(feature.rawValue).selectedItem"`：

- 引用處：App 的 `CampaignView` (`.campaigns`)、`MoreView` (`.more`)；UI 測試的 `CampaignsScreen.selectedCampaignID()`、`CampaignListLoadFailureLoopTests`、`AdaptiveNavigationContinuityUITests.requireMoreSelection(in:)`。
- 寫死值的只有 `BLAccessibilityIDTests` 的 `selectedItem_指定功能範疇_組成符合慣例之ASCII識別碼` 的 3 個預期值；archive 只寫到函式名稱，沒有寫值。`Common.Feature.orders` 只在這條測試出現。

本 change 不改變 capability 層級的可觀察行為：11 個載入狀態值不變；`selectedItem` 的 3 個值改變，但 App 與 UI 測試經同一個函式取值，畫面與 UI 測試的定位結果相同。Apple `View.accessibilityIdentifier(_:)` 文件說明 identifier 供測試使用、不顯示給使用者。

## Goals / Non-Goals

**Goals:**

- 固定 identifier 的定義只剩一種寫法 (完整字串字面值)；需要組出的 identifier 只在字面值前綴之後接最後一段，失敗訊息印出的值都能用前綴搜到定義。
- 規則寫明這個形狀，避免再為某一類固定值加組字串的 helper，或在中段插入參數。

**Non-Goals:**

- 除 `selectedItem` 的 3 個值外，不改任何 identifier 的值與引用處。
- 不動 `option`、`row`、`indexed` 與其他 33 個已符合形狀的函式 (`Dashboard.kpiTile(_:)`、`Root.tab(_:)` 等)。
- 不把其他字串反過來改成 helper 組出。
- 不新增掃描 ID 檔的守門測試、不做型別化的載入狀態 identifier 組 (見「提案審查」的後續項目)。

## Decisions

### 往字串字面值收斂

固定 identifier 一律寫完整字串 (主對話建議，使用者 2026-11-09 同意另開 change 統一)。理由：多數 (159 個) 已是字串，改 11 個即可統一；值可直接搜尋。替代方案是把 `.root`、`.emptyState`、`retryButton` 也改成 helper，要改的常數多，換來的只是少打前綴，不採。

失去的保證很小：前綴本來就在各常數各自寫字面值，helper 只固定「容器後接 `.loadFailure`、重試鍵再接 `.retryButton`」的後綴形狀，App 與測試沒有任何程式依賴這個形狀 (兩端引用同一個常數)。改寫後這個形狀由 Implementation Contract 與審查維持。

### 函式只在字面值前綴之後接最後一段

規則採形狀準則：需要組出的 identifier 只能由 `option`、`row`、`indexed` 在字面值前綴之後接最後一段變動值。`Common.selectedItem(_:)` 一併改為 `option("common.navigation.selectedItem", key: feature.rawValue)`，3 個值改變 (見 Implementation Contract)。

理由：原擬的「依資料或列舉值變動的 identifier 才以函式組出」擋不住以列舉參數在中段組字串的 helper，`selectedItem` 就是這種形狀，失敗訊息印出的完整值在原始碼裡搜不到。改成形狀準則後，任何組出的值都能以字面值前綴搜到定義。

替代方案：把 `selectedItem` 列為規則的明確例外並維持現狀；或維持原擬措辭。兩者都留下一個搜不到定義的形狀，不採。

決策來源：架構審查 (opus-arch-reviewer) 提出，主對話推薦，使用者 2026-11-10 明確回覆採納。

### 值不變的守門

1.1 改寫 11 個常數時，helper 仍在，在 `BLAccessibilityIDTests` 加一條暫時的參數化測試：參數是 11 組「新常數、對應的舊 helper 呼叫」，逐組斷言相等。1.2 刪 helper 時連同這條測試一起刪除。

總覽的 3 條字面值測試 (`loading_總覽載入中_使用總覽前綴`、`loadFailure_總覽載入失敗_使用總覽前綴`、`loadFailureRetryButton_總覽重試按鈕_接在失敗區域後`) 在 1.2 一併刪除，也不為其餘 8 個值補永久的等值測試：常數改成字面值後，這類測試只是拿字面值比對同一個字面值，守不住任何東西。改寫是否正確由暫時測試在改寫當下證明。

決策來源：架構審查提出，主對話推薦，使用者 2026-11-10 明確回覆採納。

### 規則寫進 ios-ui-tests.md

在「定位與 identifier」第一條 (一律以 `accessibilityIdentifier` 定位) 的子 bullet「常數集中在 `BuyLedgerAccessibilityIDs/`」之後，補一個同層子 bullet，沿用該檔 4 空格縮排：

```markdown
    - 在 `BuyLedgerAccessibilityIDs/` 定義常數時，固定 identifier 寫完整字串字面值；需要組出的只能由 `option`、`row`、`indexed` 在字面值前綴之後接最後一段變動值，不在中段插入參數，也不在變動值之後再接固定片段，UI 測試失敗訊息印出的值才能以前綴搜到定義；UI 測試也以空字串呼叫這些函式取得 `BEGINSWITH` 前綴。
```

開頭寫明「定義常數時」，與相鄰子 bullet 的「兩端引用常數、不寫字面值」區分適用處。理由：這個慣例讀程式碼看不出原因 (搜尋需求，以及 UI 測試以空字串取前綴的依賴)，刪掉它時，之後的實作可能再為某一類固定值加 helper、在中段插入參數，或在變動值之後接固定片段。句尾「UI 測試也以空字串…」是 3.1 架構審查後補上的 (見「實作與審查」)。依根目錄 `CLAUDE.md`，規則只寫現行規則與理由，不寫本次經過。

### 驗證範圍

UI 只跑代表性回歸，不跑完整 UI 回歸 (主對話代選)。11 個常數的值與引用處都不變，編譯就能確認所有引用仍成立；`selectedItem` 的值雖然改變，App 與 UI 測試經同一個函式取值。UI 回歸只用來確認畫面上的元素仍以這些 identifier 被找到，所以挑會在斷言中真正等待這些元素的類別，兩台各跑一次：

- 載入失敗與重試：`DashboardLaunchLoadingTests` (經 `DashboardScreen` 的 `waitForLoadFailure`、`tapRetry`)、`LoadFailureReloadLoopTests` (直接引用總覽、分析頁、訂單的常數)、`OrderListLoadFailureTests`、`CampaignListLoadFailureLoopTests`、`CampaignFlowTests`。
- 經 `RootNavigationScreen.isForegroundDestinationReady(for:)`：這個就緒判斷把總覽、開團、分析頁的重試鍵列為就緒條件之一，`BuyLedgerUITests/Tests` 有 42 個檔案引用 `RootNavigationScreen` (2026-11-10 以 `git grep -l` 計數)，都可能間接讀到。資料正常時判斷由其他元素滿足、不會真的等到重試鍵，所以只挑 `InsightsLaunchLoadingTests` 代表這條路徑，不逐一列入。
- `selectedItem`：`CampaignFlowTests` (經 `CampaignsScreen.selectedCampaignID()`)、`CampaignListLoadFailureLoopTests`、`AdaptiveNavigationContinuityUITests` (開團與更多的選取標記)。

`AppLockTests` 不列入：它呼叫的 `tapRetry` 是 `AppLockScreen` 的方法，讀的是 `AppLock.retryButton`，不是這 11 個常數。單元測試跑完整 `BuyLedgerTests`。

建置與測試由主對話執行，同一時間只跑一組；實作者交回前只跑 `swiftc -parse`。

### 基準分支

`BLAccessibilityID+Insights.swift` 與 `+Orders.swift` 的載入狀態常數由 PR #6 新增；PR #6 已於 2026-11-09 合併 (`0510f34`)，本 change 從當時的 `main` 開新分支實作 (主對話代選)。

## Implementation Contract

改寫後每個常數的值必須等於下表的字串，與改寫前 helper 組出的值相同：

| 常數 | 改寫前 | 改寫後的字串 |
| --- | --- | --- |
| `Dashboard.loading` | `Common.loading("dashboard")` | `"dashboard.loading"` |
| `Dashboard.loadFailure` | `Common.loadFailure("dashboard")` | `"dashboard.loadFailure"` |
| `Dashboard.loadFailureRetryButton` | `Common.loadFailureRetryButton("dashboard")` | `"dashboard.loadFailure.retryButton"` |
| `Insights.loading` | `Common.loading("insights")` | `"insights.loading"` |
| `Insights.loadFailure` | `Common.loadFailure("insights")` | `"insights.loadFailure"` |
| `Insights.loadFailureRetryButton` | `Common.loadFailureRetryButton("insights")` | `"insights.loadFailure.retryButton"` |
| `Orders.listLoadFailure` | `Common.loadFailure("orders.list")` | `"orders.list.loadFailure"` |
| `Orders.listLoading` | `Common.loading("orders.list")` | `"orders.list.loading"` |
| `Orders.listLoadFailureRetryButton` | `Common.loadFailureRetryButton("orders.list")` | `"orders.list.loadFailure.retryButton"` |
| `Campaigns.listLoadFailure` | `Common.loadFailure("campaigns.list")` | `"campaigns.list.loadFailure"` |
| `Campaigns.listLoadFailureRetryButton` | `Common.loadFailureRetryButton("campaigns.list")` | `"campaigns.list.loadFailure.retryButton"` |

組字串規則依 `BLAccessibilityID.option(_:key:)` (`"\(prefix).\(key)"`)，`loadFailureRetryButton` 再接 `.retryButton`。

`Common.selectedItem(_:)` 改為 `option("common.navigation.selectedItem", key: feature.rawValue)`，值依下表改變：

| 參數 | 改寫前 | 改寫後 |
| --- | --- | --- |
| `.orders` | `"common.navigation.orders.selectedItem"` | `"common.navigation.selectedItem.orders"` |
| `.campaigns` | `"common.navigation.campaigns.selectedItem"` | `"common.navigation.selectedItem.campaigns"` |
| `.more` | `"common.navigation.more.selectedItem"` | `"common.navigation.selectedItem.more"` |

驗收：

- `apps/ios` 內搜尋 `Common.loading`、`Common.loadFailure` 為 0 筆；`BLAccessibilityID.Common` 只少這三個函式，`selectedItem(_:)` 的實作改為上式、doc comment 的格式說明改為 `"common.navigation.selectedItem.<feature>"`，其餘成員不變。
- 11 個常數的 doc comment 不變。
- 1.1 完成時，暫時測試的 11 組全部通過且實際執行數大於 0。
- 1.2 完成時，`BLAccessibilityIDTests` 比改動前少 5 個測試函式 (2 條 helper 測試與總覽 3 條)，暫時測試已刪除；`selectedItem_指定功能範疇_組成符合慣例之ASCII識別碼` 只改 3 個預期值並通過；其餘測試不改內容並通過。
- 完整 `BuyLedgerTests` 在 iPhone 17 (iOS 26.5) 0 失敗，snapshot 不重錄。
- 「驗證範圍」列出的 UI 類別在 iPhone 17 (iOS 26.5) 與 iPad Air 11-inch (M4) (iPadOS 27.0) 通過 (依版面宣告略過的既有案例照舊略過)。
- `.claude/rules/ios-ui-tests.md` 只多一個子 bullet，內容與「規則寫進 ios-ui-tests.md」的區塊相同。

範圍外：App 端 view 與 UI 測試的引用處不改；`BuyLedgerAccessibilityIDs/` 除上述 5 個檔案外不改。

## Risks / Trade-offs

- [改寫時打錯字串，值和改寫前不同] → 1.1 的暫時測試逐組比對新字面值與舊 helper 輸出，審查再逐列對照上表。兩端引用同一個常數，所以單一常數打錯不會讓定位失敗；但打錯後若與另一個常數同值 (例如重試鍵寫成容器的值)，查詢會同時找到兩個元素，present／absent 斷言就失效。Apple `XCUIElementQuery` 文件說明 subscript 與 `matching(_:identifier:)` 會比對 identifier、label、value 等識別屬性，`element` 要求唯一符合，`firstMatch` 不檢查是否有多個。
- [UI 只跑代表性類別，漏掉其他讀取者] → 其他讀取者經同一個常數或函式取值，編譯會檢查引用；`RootNavigationScreen` 的間接讀取者在資料正常時不依賴重試鍵。
- [`selectedItem` 的值改變] → 寫死舊值的只有 `BLAccessibilityIDTests` 的 3 個預期值，1.2 同步更新；App 與 UI 測試經同一個函式取值。

## Migration Plan

1.1 改寫 11 個常數並加暫時測試 (helper 仍在，建置通過)；1.2 刪 helper、暫時測試、2 條 helper 測試與總覽 3 條測試，並改寫 `selectedItem`。回復時還原這兩步即可，沒有資料或設定遷移。

## 提案審查 (2026-11-10)

審查者：Herdr 實作終端 t8 (claude-haiku-max-impl)、t9 (codex-luna-max-impl)、t16 (claude-sonnet-xhigh-impl)、t1n (codex-sol-xhigh-impl)，右側 Codex 審查終端 t17，接著 opus-arch-reviewer 做架構與長期維護審查；主對話同時審查。全程唯讀，審查前後 `git status --short` 與 change 檔雜湊一致。

共識：無高嚴重度問題；Implementation Contract 原有 11 列全部正確；helper 只有 2 條測試引用；`91e074c` 的來歷屬實；往字面值收斂的方向成立。

依審查修正 (主對話逐條對照程式碼後採納)：

- 驗證範圍原寫「依 grep 結果的全部讀取者」並列入 `AppLockTests`，與實際不符；改寫為上方的代表性回歸並寫明理由。
- 159 個 `static let` (原寫 158，漏算跨行宣告)。
- 規則寫明適用於常數定義處；「失去的保證」與打錯字串的風險改寫得不誇大也不輕描；`BLLoadFailureView` 只接收 `retryIdentifier`；歷史補上第二條測試名稱與 archive 的兩處紀錄；proposal 的「repo 搜不到」改為「原始碼裡搜不到定義」，「只測這兩個 helper」改寫為具名的測試；tasks 3.2 指向 UI 測試前置條件，並寫明建置與測試由主對話執行。

使用者 2026-11-10 明確回覆採納的三項：「函式只在字面值前綴之後接最後一段」(含改寫 `selectedItem`)、「值不變的守門」的暫時測試、刪除總覽 3 條字面值測試。

列為後續、不納入本 change (架構審查建議，主對話同意)：另開 change 加守門測試掃描 `BuyLedgerAccessibilityIDs/`，檢查字面值形狀、值不重複、只含 ASCII；型別化的載入狀態 identifier 組暫不做。值不重複是定位的實際風險，見 Risks 第一條。

## 實作與審查 (2026-11-10)

實作依 tasks 分工 (apply 時 `hc ls` 確認終端都在)：1.1、1.2 由 t16 (claude-sonnet-xhigh-impl)，2.1 與審查修正由 t8 (claude-haiku-max-impl)；實作者交回前只跑 `swiftc -parse`，建置與測試由主對話執行。

- 1.1：暫時測試在 iPhone 17 (iOS 26.5) 11 組都有執行並全過；把 `Dashboard.loadFailureRetryButton` 暫改為 `"dashboard.loadFailure"` (與容器同值) 時對應那組轉紅，還原後檔案雜湊與改前一致。
- 1.2：`BLAccessibilityIDTests` 由 13 條減為 8 條並全過；把 `selectedItem` 實作暫改回舊字串時該測試 3 組全紅，還原後雜湊一致。

審查者：t17 (codex，style 閘門與全面審查)、opus-arch-reviewer、opus-xhigh-reviewer，主對話同時審查，四方都未參與實作。審查前後 `git status --short` 與變更檔、change 檔雜湊一致。

- t17：7 個變更檔逐檔逐條做 style 閘門與正確性審查，高／中／低問題皆 0。
- opus-xhigh-reviewer：0 問題。11 個字面值與 3 個 `selectedItem` 新值對照 Implementation Contract 相符；3 個 helper 與 5 條測試的刪除範圍正確、無殘留；`apps/ios` 沒有依賴舊 helper 或舊 `selectedItem` 值之處；170 個 `static let` 值不重複；規則行與上方區塊逐字相同。
- 主對話：無問題。`BuyLedgerAccessibilityIDs/` 已沒有非字面值的 `static let`，`static func` 都經 `option`／`row`／`indexed`，`selectedItem` 的 5 處引用都經函式取值。
- opus-arch-reviewer：無高／中問題，2 項低：
  - 規則理由只寫搜尋需求，但「變動值在最後一段、後面不接固定片段」實際是 UI 測試依賴的契約：16 處 (7 個檔案；審查報告原寫 8 個，verify 時主對話以 `git grep -l` 重數更正) 以空字串呼叫 ID 函式取 `BEGINSWITH` 前綴 (例如 `Orders.row(orderID: "")`)，`OrdersScreen` 另以 `dropFirst(prefix.count)` 取回訂單編號。主對話以 `git grep` 查證屬實後推薦補上理由，使用者 2026-11-10 明確回覆採納；規則與上方區塊同步補一個子句，修正後由 t17 唯讀複核該行的 style 閘門與理由，0 問題，前後雜湊一致。
  - `option` 與固定字面值共用 `.` 分隔符號，目前 0 衝突 (所有組字串前綴都沒有字面值以「前綴＋分隔符號」開頭)；`Orders.categoryCell(_:)` 與兩個付款方式選項函式傳入使用者命名的資料卻用 `option`，屬既有寫法、不在本次範圍。本次不改，併入「提案審查」列的後續守門測試 change：檢查字面值不得以 `option`／`row`／`indexed` 的前綴加分隔符號開頭 (架構審查建議，主對話同意)。

## 回歸驗證 (2026-11-10)

依「驗證範圍」執行。審查修正只改規則文字，不影響建置與測試，回歸不因此重跑 (主對話判斷)。回歸前後 `git status --short` 一致。

- 完整 `BuyLedgerTests` 在 iPhone 17 (iOS 26.5)：共 2047 條，2044 過、3 條是既有標為已知問題的預期失敗、0 失敗，snapshot 未重錄。
- iPad Air 11-inch (M4) (iPadOS 27.0)：前置 `KeyboardDismissTests` 2 條通過。7 個類別 36 條首輪 31 過、4 條依版面宣告略過、1 條失敗：`AdaptiveNavigationContinuityUITests.testSearchKeepsOrClearsSelection_訂單清單並排_命中保留選取且排除後清空` 在搜尋欄點擊後的「等待 App 閒置」每次空等 60 秒，累計超過 10 分鐘執行上限，與本次的 identifier 無關；單獨重跑 97.7 秒通過，判定為環境雜訊，不改測試碼。彙整為 32 過、4 略過、0 失敗。
- iPhone 17 (iOS 26.5)：7 個類別 36 條首輪 20 過、7 略過、9 條以「轉向後 App 視窗寬仍未大於高」失敗 (`AdaptiveNavigationContinuityUITests` 7 條、`CampaignFlowTests` 2 條)。依 `.claude/rules/ios-ui-tests.md`「轉向測試」重開模擬器後重跑這 9 條：6 過、3 條轉向後依版面宣告略過 (需 regular 根導覽或無法展開為並排)。彙整為 26 過、10 略過、0 失敗。
- 兩台每個類別的實際執行數都大於 0：`DashboardLaunchLoadingTests` 2、`InsightsLaunchLoadingTests` 1、`LoadFailureReloadLoopTests` 3、`OrderListLoadFailureTests` 1、`CampaignListLoadFailureLoopTests` 1 條在兩台都通過；`CampaignFlowTests` iPad 9 過 2 略過、iPhone 10 過 1 略過；`AdaptiveNavigationContinuityUITests` iPad 15 過 2 略過、iPhone 8 過 9 略過。

## Open Questions

(none)
