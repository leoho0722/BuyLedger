## Context

第 4 步範圍是 `apps/ios/BuyLedger/Features/Lookups/` 的 6 個 production 檔 (`LookupCatalog`、`LookupKind`、`LookupManagementDestination`、`LookupManagementFeature`、`LookupManagementView`、`LookupNameEditorSheet`)，加上跟著改的 2 個單元測試檔 (`LookupManagementFeatureTests`、`LookupCatalogTests`)。2026-09-14 全庫審查在這 8 檔記錄 302 筆待修項 (實測值，由報告資料集依檔名篩出，已排除尾隨空白)，逐筆明細在本目錄的 `findings.md`。

前三步已把 Core、Shared／Design System 與六個小型 Feature 對齊並結案 (commit `30791e3`、`44e7799`、`93c402d`)；本步依賴的錯誤型別 (`PersistenceError`、`PaymentMethodPersistenceError`)、`PaymentMethodEditorSheet` 的三個具名 `Bool` 介面、`ActionGroupingScanTests` 與 `LedgerOrder.fixture(...)` 都已穩定。

**三種範圍要分清楚**：

- **審查基準**：上面 8 個檔案、302 筆，是 `findings.md` 逐筆要有結論的對象。
- **實作範圍**：proposal Impact 清單與本 design「範圍邊界」列出的全部檔案，也就是 allowlist。
- **檢查範圍分兩組** (以完工時 `git status --porcelain` 列出的 Swift 檔為準)：
    - **A 組，整檔合規**：`Features/Lookups/` 下全部 Swift 檔 (含改名與新增的)、`LookupManagementFeatureTests` 與拆出的 `LookupManagementFeatureTests+<Domain>.swift`、`LookupCatalogTests`，以及本步新增的全部 Swift 檔 (含 UI 測試與 page object)。驗收條件 1 至 3 對整個檔案檢查。
    - **B 組，只管改到的地方**：其餘連帶改動的既有檔 (`RootFeature`、`RootFeatureTests`、`ActionGroupingScanTests` 三檔、`LocalizationCatalogTests`、`BLUITestConfiguration`、`BLUITestDependencyOverrides`、`BLUITestConfigurationTests`、`LaunchOptions`、`BLAccessibilityID`)。驗收條件 1 至 3 只對本步新增或修改的行、宣告與測試檢查 (以 `git diff` 的 hunk 判定)；實測 `RootFeatureTests` 1,317 行、`BLUITestDependencyOverrides` 有多行超過 100 字元，整檔套用會把第 8、9 步提前拉進來。

**現況的結構問題** (已逐一讀過原始碼確認)：

- `LookupManagementFeature` 546 行 (2026-09-24 實測，不含檔頭與空行)，`body` 是單一 `Reduce { state, action in }` 閉包；Action 22 個 case 全部平放，`binding` 排在最後、`Alert` 夾在 case 中間；State 有四個 `@Presents` (`destination`、`deletionConfirmation`、`retroactiveConfirmation`、`writeFailureAlert`)；`BindableAction` 與 `BindingReducer()` 沒有任何 `$store.<欄位>` 綁定在用；為了 `LocalizedStringKey` 而 `import SwiftUI`。
- 四種主檔的讀寫在 `load(kind:)`、`addConfirmed`、`deleteRequested`、`renameRequested` 各寫一次 `switch kind`，共四段重複分派。
- `LookupManagementDestination.swift` 內四個子 reducer 的 `body` 都是 `Reduce { _, _ in .none }` 或只更新草稿，Action 只有平放的 `saveButtonTapped`，父層以 `.destination(.presented(.rename(.saveButtonTapped)))` 直接攔截並讀子層 State。
- `RootFeature` 攔截子層的 `renameRequested` (寫入前就改寫記憶體訂單) 與 `paymentMethodEditSucceeded`。
- **`PaymentMethodEditorSheet` 在呼叫 `onSubmit` 之後立即 `dismiss()`** (Shared 元件的既有行為)，所以付款方式更正的確認 alert 與失敗 alert 實際都在表單關閉後、於主檔管理頁呈現，不會疊在表單上。這決定了下面「付款方式更正流程抽成子 Feature」與「四個 @Presents 併成單一 Destination」兩項設計。

**限制與既有登記差異** (`apps/ios/CLAUDE.md`「ios-dev-kit 規範與既有差異」，本步沿用)：

- Reducer body 寫 `some Reducer<State, Action>`，不寫 `some ReducerOf<Self>`。
- Repository 是 struct-of-closures 並宣告 `testValue`；`@Shared(.lookupCatalog)` 用於主檔目錄的記憶體共享 (`.inMemory` key)。
- 檔頭日期一律不補零 `YYYY/M/D`；測試方法名稱維持單段 lowerCamel。
- SwiftUI View 超過 300 行優先抽獨立 View 型別，不以跨檔 extension 拆分。
- 第 3 步使用者裁決的九條風格硬規則 (大括號本體換行、`@Dependency` 同行、注入值用 `let`、不為單一呼叫點抽 method、closure 參數列與 `{` 同行、View 無 `Computed Properties` 分區、`body` 只組合用 `Reduce(core)`、一檔一型別) 已在 `apps/ios/CLAUDE.md`，本步一體適用。

## Goals / Non-Goals

**Goals:**

- 審查基準 8 檔與本步新增的檔案符合 `/ios-dev-kit` 的 `tca-architecture.md`、`formatting.md`、`coding-style.md` 與 `file-templates.md`，除了上面的既有登記差異與本 design 明列的例外。
- 每個 Swift 檔不超過 300 行 (不含檔頭與空行)，不以壓行達成。
- 套用第 3 步的 TCA 範本：Action 分組、父層只處理子層 `delegate`、`Reduce(core)`、同一次請求的結果合併成單一 `Result` case。
- 修掉三個缺陷：寫入先改畫面 (新增與改名)、寫入失敗訊息常駐、付款方式同名會崩潰；並以變異驗證確認 `LookupCatalogTests` 的合併旗標測試有效 (使用者裁決的第四項「修假測試」經查已在第 0 步修好，見「測試拆檔與寫法」)。
- 以 UI 測試實際驗證主檔新增、改名、刪除與寫入失敗的畫面行為，並以 snapshot 守住主檔管理畫面的外觀。

**Non-Goals:**

- **`RootFeature` 只改兩處主檔攔截** (改收 `delegate`)，`lookupManagements` 的手寫初始陣列、`morePath`、`cascadeRename` 的結構與其餘分區留給第 8 步。`LookupKind` 補上 `CaseIterable` 後雖可改用 `allCases` 產生該陣列，本步不動。
- **`OrdersFeature` 與 `OrderFilterSheet` 對 `@Shared(.lookupCatalog)` 的讀寫不動** (第 6 步)；`LookupCatalog` 既有 API (`names(for:)`、`add`、`remove`、`rename`) 的簽章不變，只新增方法。
- **`PaymentMethodEditorSheet` 送出後立即關閉的行為不改**：它是 Shared 元件，第 2 步已結案。
- **`LookupNameEditorSheet` 的 `canSubmit`／`trimmedName` 不抽成可測的靜態函式**：它是不綁 store 的可重用元件，按鈕停用屬 UI 判斷；送出後的名稱驗證由表單子 Feature 的 reducer 再做一次並有單元測試。
- **不改任何使用者可見字串與本地化 key** (新增、刪除、改名、付款方式編輯的失敗文案與「操作失敗」「知道了」都是既有 key)；不重錄任何既有 snapshot 基準圖；除本步新增的主檔管理 UI 測試外不改其他 UI 測試。
- **不改測試方法名稱的命名格式** (使用者 2026-09-21 裁決維持單段 lowerCamel)。
- **ios-dev-kit 2.0.0 的依賴規則另開 change** (Service 為 struct 裝 closure、每個 closure 宣告 typealias、`testValue` 全部 `unimplemented`、以 `DependencyValues` 屬性取用而非型別下標)：使用者 2026-09-25 裁決 整批改造 `Core/Dependencies/` 與所有呼叫端；本步沿用 `@Dependency(XxxRepository.self)`／`$0[XxxRepository.self]`。2.0.0 其餘規則 (巢狀型別成員就地寫、typed throws closure 只補 `throws(E)`、區內排序、TCA 測試 `$0` 例外) 本步照套，`Destination.State` 因巨集限制保留 extension (已記入 `apps/ios/CLAUDE.md`)。

## Decisions

### 主檔管理的拆分：付款方式更正子 Feature、讀寫輔助型別與三個表單子 Feature

使用者 2026-09-24 裁決採用「子 Feature ＋ 同域輔助型別」。拆分後 `Features/Lookups/` 的型別與職責：

| 型別 (檔案) | 職責 | 有自己的 View |
|---|---|---|
| `LookupManagementFeature` | 一種主檔的管理畫面：載入、開表單、確認刪除、呈現 alert、把結果交給根畫面 | `LookupManagementView` |
| `LookupManagementFeature.Destination` (`LookupManagementFeature+Destination.swift`) | 三種表單 (新增、改名、付款方式編輯) 與 alert 的呈現目的地，含 alert 的建構 | 無 |
| `LookupAddFormFeature` | 新增表單送出的名稱驗證，名稱型與付款方式共用，以 `hasClassification` 區分要呈現哪一種表單 | 表單由 `LookupNameEditorSheet`／`PaymentMethodEditorSheet` 呈現 |
| `LookupRenameFormFeature` | 改名表單送出的驗證 | 同上 |
| `PaymentMethodEditFormFeature` | 付款方式編輯表單送出的驗證 | 同上 |
| `PaymentMethodCorrectionFeature` | 付款方式更正：找出引用原付款方式的訂單、要求確認、一起寫入 (全部成功或全部不動) | 無，由父層轉送 |
| `PaymentMethodEditPlan` | 更正流程的固定快照 (從 `LookupManagementFeature` 巢狀型別搬出成頂層型別，欄位不變) | 無 |
| `LookupItemAddition`、`LookupItemRename` | 一次新增與一次改名的內容 (新增：名稱與旗標；改名：舊名與新名)，各自一檔，供寫入結果與 delegate 傳遞 | 無 |
| `LookupItemOperations` | 四種主檔的讀取、新增、刪除、改名分派與其 Effect | 無 |
| `LookupItemRow` (`Components/`) | 主檔清單列與付款方式分類徽章 | 本身是 View |
| `LookupItemList` (`Components/`) | 主檔清單、空狀態、載入失敗列與列操作 | 本身是 View (使用者 2026-09-24 裁決，見「LookupManagementView 與 LookupNameEditorSheet」) |

- **`PaymentMethodCorrectionFeature` 比照第 3 步的 `QuoteRateFeature`**：沒有自己的 View，所以不設 `view` 分組，Action 是一般內部 case，由父層的 `core` 轉送；父層轉送的不是子層 `.view`，不觸犯 `ActionGroupingScanTests` 規則二。父層以 `Scope(state: \.correction, action: \.correction)` 組合。
- **更正流程不能搬進編輯表單子 Feature**：表單送出後立即關閉，`ifLet` 會取消已關閉目的地的 Effect，更正流程會在找出引用原付款方式的訂單或一起寫入途中被中斷。依據是 TCA 1.26.2 的 `Sources/ComposableArchitecture/Reducer/Reducers/PresentationReducer.swift`：目的地身分改變 (含設為 `nil`) 且不是 ephemeral 狀態時，`dismissEffects = ._cancel(navigationID: presentedPath)` 取消該目的地啟動的全部 Effect (checkout 路徑同下一節)。所以表單子 Feature 只做驗證並交出結果，流程由常駐於父層 State 的 `PaymentMethodCorrectionFeature` 執行。
- **三個表單子 Feature 各自一檔、改為頂層型別**：原本巢狀在 `Destination` 內，四組 `State`／`Action`／`Body` 的 MARK 會以縮排 8 格重複出現，且同檔多型別會讓 `Private Method` 分區重複 (違反「一檔一型別」)。新增表單只有一個 `Destination` case `add(LookupAddFormFeature)`，`LookupAddFormFeature.State` 以 `let hasClassification: Bool` 記錄這次是否為付款方式，View 依它選擇 `PaymentMethodEditorSheet` 或 `LookupNameEditorSheet`；名稱型主檔送出時旗標為 `PaymentMethodFlags.none`。不讓兩個 `Destination` case 共用同一個 reducer 型別，避免 `@Reducer enum` 巨集產生的 case 路徑與 `Scope` 出現未查證的行為。
- **拆分後仍超過 300 行時停下回報**，附上實際行數與各分區行數，不壓行、不自行再拆出本表以外的型別。父層的行數尚未實測，Codex 第一輪依本設計粗估約 270 至 320 行，所以 `LookupItemAddition`／`LookupItemRename` 一開始就放頂層檔、alert 建構放 `+Destination.swift`，父層檔不再有 `Nested Types` 區。
- `apps/ios/CLAUDE.md` 的「大型 reducer 以同域輔助型別拆分，不拆成子 reducer」改寫如下 (task 7.1)，讓它與 `tca-architecture.md` 的拆分順序及 `QuoteRateFeature`、`PaymentMethodCorrectionFeature` 兩個實例一致：

  > **Feature 超過 300 行依 `tca-architecture.md` 的拆分順序**：`Destination` 移到 `<Name>+Destination.swift` → 可獨立的流程抽成子 Feature 以 `Scope` 組合 (沒有自己 View 的子 Feature 不設 `view` 分組，由父層轉送，如 `QuoteRateFeature`、`PaymentMethodCorrectionFeature`)。重複的計算或讀寫分派收進同域輔助型別：純計算放無 case 的 enum，只放 `static func`，以 `inout State` 與明確參數溝通 (如 `OrdersFilterOperations`)；需要依賴的讀寫分派放持有依賴值的 struct，由 reducer 以自己的 `@Dependency` 建立 (如 `LookupItemOperations`)。

  其下既有的四條子項 (輔助型別不宣告 `@Dependency`、主 switch 窮舉零預設分支、多段 `Reduce` 規則、草稿型別標 `@ObservableState`) 保留。

**替代方案**：只抽子 Feature (再抽「主檔讀寫」子 Feature)、只用同域輔助型別，使用者皆未採用 (見 proposal)。

### 主檔管理的 Action 分組

`LookupManagementFeature.Action` 依 `view` → `delegate` → 子層與目的地 → 內部回應 (字母序) 排列；`View` 與 `Delegate` 是 `@CasePathable` nested enum。`Action` 不再遵循 `Equatable` (`PersistenceError` 依第 1 步不遵循)，`RootFeature.Action` 在第 3 步已不遵循，不受影響。

| Feature | view | delegate | 子層與目的地 | 內部回應 |
|---|---|---|---|---|
| `LookupManagementFeature` | `task`、`addButtonTapped`、`deleteButtonTapped(name:)`、`editButtonTapped(name:)`、`renameButtonTapped(name:)` | `itemRenamed(LookupItemRename)`、`paymentMethodEdited(PaymentMethodEditPlan)` | `correction`、`destination` | `addResponse(Result<LookupItemAddition, PersistenceError>)`、`deleteResponse(Result<String, PersistenceError>)`、`itemsResponse(Result<LookupCatalog, PersistenceError>)`、`renameResponse(Result<LookupItemRename, PersistenceError>)` |
| `LookupAddFormFeature` | `saveButtonTapped(name: String, flags: PaymentMethodFlags)` | `saved(name: String, flags: PaymentMethodFlags)` | 無 | 無 |
| `LookupRenameFormFeature` | `saveButtonTapped(name: String)` | `saved(oldName: String, newName: String)` | 無 | 無 |
| `PaymentMethodEditFormFeature` | `saveButtonTapped(name: String, flags: PaymentMethodFlags)` | `saved(originalName: String, newName: String, flags: PaymentMethodFlags)` | 無 | 無 |
| `PaymentMethodCorrectionFeature` | 無 (沒有自己的 View) | `confirmationRequired(affectedOrderCount: Int)`、`edited(PaymentMethodEditPlan)`、`failed` | 無 | `cancelled`、`confirmed`、`editResponse(Result<PaymentMethodEditPlan, PaymentMethodPersistenceError>)`、`planResponse(Result<PaymentMethodEditPlan, PersistenceError>)`、`requested(originalName: String, newName: String, flags: PaymentMethodFlags)` |

- `LookupItemAddition` (`name`、`flags`) 與 `LookupItemRename` (`oldName`、`newName`) 是頂層型別各自一檔 (`domain/Model.swift` 樣板，只留用得到的 `Equatable`、`Sendable`)，欄位用 `let`。
- 原本的 `task`、`addButtonTapped`、`deleteButtonTapped(name:)`、`editButtonTapped(name:)`、`renameButtonTapped(name:)` 移進 `View`。`orderSourceItemsLoaded` 等四個載入 case 與 `loadFailed` 合併成 `itemsResponse`；`addConfirmed`、`deleteRequested`、`deleteSucceeded`、`renameRequested`、`editConfirmed`、`paymentMethodEditPrepared`、`paymentMethodEditSucceeded`、`paymentMethodEditFailed`、`binding` 刪除 (職責分別移到表單子 Feature、`PaymentMethodCorrectionFeature` 與 `*Response`)。
- `body` 為 `Scope(state: \.correction, action: \.correction) { PaymentMethodCorrectionFeature() }` → `Reduce(core)` → `.ifLet(\.$destination, action: \.destination)`；`core` 的 case 順序與 `Action` 宣告順序一致，case 之間空一行，`.delegate` 一律 `return .none`，超過十行的分支抽成動詞開頭、回傳 `Effect<Action>` 的 Private Method。
- 表單子 Feature 的 `core`：新增表單把名稱去掉頭尾空白，空字串回 `.none`，否則送 `.delegate(.saved(...))`；改名表單另要求與 `originalName` 不同；付款方式編輯表單只要求非空 (允許只改旗標)。三者 State 由父層建立時帶齊：`LookupRenameFormFeature.State` 與 `PaymentMethodEditFormFeature.State` 的 `originalName`、`flags` 用 `let` 且宣告處不給預設值 (既有硬規則)。
- `LookupManagementFeature.State` 的注入值 `kind` 已是 `let`；新增 `var hasLoadFailed = false` 取代 `errorMessage`、`var correction = PaymentMethodCorrectionFeature.State()`；衍生值 `id`、`items`、`hasClassification` (是否為付款方式主檔) 與 `func classification(for name: String) -> PaymentMethodFlags?` (非付款方式主檔回 `nil`) 放在 stored property 之後。刪除 `pendingPaymentMethodEdit` (移到子 Feature) 與三張旗標對應表。
- `addButtonTapped` 設 `destination = .add(LookupAddFormFeature.State(hasClassification: state.hasClassification))`，不在父層寫 `switch kind` (見 lookup-management spec「Adding a lookup kind is a compile-time obligation」)。

### 寫入成功才更新主檔目錄

使用者 2026-09-24 裁決納入。新增、改名、刪除一律先寫資料庫，寫入成功的回應才改 `@Shared(.lookupCatalog)`，失敗時目錄完全不動 (`.claude/rules/ios-navigation.md`「寫入先落盤、成功才改畫面狀態」)。

- 表單子 Feature 送出 `delegate(.saved)` 時，父層先把 `state.destination` 設為 `nil`，再回傳寫入 Effect。表單元件自己的 `dismiss()` 隨後觸發的關閉，因目的地已是 `nil` 而不會再送出 `.destination(.dismiss)`。
- `addResponse(.success(addition))` → `catalog.add(name:kind:flags:)`；`deleteResponse(.success(name))` → `catalog.remove(name:kind:)`；`renameResponse(.success(rename))` → `catalog.rename(from:to:kind:)` 並回傳 `.send(.delegate(.itemRenamed(rename)))`。
- **改名的訂單改寫改由 delegate 觸發**：`RootFeature` 改攔截 `.lookupManagements(.element(id: kind, action: .delegate(.itemRenamed(rename))))`，以既有的 `cascadeRename(kind:from:to:in:)` 改寫記憶體訂單。原本同一個 action 內「目錄與訂單一起更新」的保證因此變成「目錄更新後，由同一次寫入結果產生的 delegate 改寫訂單」，lookup-management spec 的「Lookup data has a single source shared by every consumer」已隨之修改。
- 刪除原本就是先寫後改，只把 `deleteRequested`／`deleteSucceeded` 改成單一 `deleteResponse`。

**替代方案**：保留樂觀更新並在失敗時回滾。否決理由是既有規則明文不做樂觀更新加回滾，且回滾期間其他畫面已可能選到未落盤的值。

### 寫入失敗改為一次性提示

使用者 2026-09-24 裁決納入。新增、刪除、改名、付款方式更正的失敗一律呈現為 `Destination.alert`，標題「操作失敗」、單一「知道了」按鈕，訊息沿用既有 key：

| 失敗的操作 | 訊息 |
|---|---|
| 新增 | 新增失敗，請稍後再試。 |
| 刪除 | 刪除失敗，請稍後再試。 |
| 改名 | 重新命名失敗，請稍後再試。 |
| 找出引用原付款方式的訂單或一起寫入失敗 | 付款方式編輯失敗，請稍後再試。 |

- `Destination` 內定義 `enum WriteFailure { add, delete, rename, paymentMethodEdit }`，alert 由 `Destination.State.writeFailure(_:)` 建構，各 case 對應上表的字面值 `TextState`，reducer 不再以 `String` 傳遞本地化 key。
- 清單上方的紅字只留給首次載入失敗：State 以 `hasLoadFailed` 表示，`itemsResponse(.failure)` 設為 `true`、`.success` 設回 `false`；View 在 `hasLoadFailed` 時顯示既有字串「主檔載入失敗，請稍後再試。」。付款方式更正成功**不**清除它 (使用者 2026-09-25 裁決)：HEAD 在更正成功時清掉共用的 `errorMessage`，是為了移除上一次寫入失敗的訊息；寫入失敗改成一次性 alert 後這個理由已不存在，清掉只會讓從未重新載入的清單看起來像已載入完整。
- 失敗提示關閉後即結束，之後其他操作成功不會再出現。

### 改名是單一交易

使用者 2026-09-25 裁決，取代 2026-09-24 的「補償寫入」。`/spectra-review` 發現補償在撞名時會掉資料：把「服飾」改成既有的「衣著」時，`NameLookupPersistence.rename` 會合併 (刪掉服飾、保留衣著)；若訂單改寫接著失敗，補償的反向改名「衣著 → 服飾」會刪掉**所有**「衣著」，包括原本就在的那筆。補償只能事後猜原狀，根本解法是讓主檔表與訂單表在同一次 save 內完成。

- `OrderPersistence` (長命 `@ModelActor`，訂單唯一的寫入者) 新增四個方法 `applyOrderSourceRename`／`applyCategoryRename`／`applyPaymentMethodRename`／`applyReconciliationStatusRename`，在自己的 actor 上執行，但**用這次交易專用的一次性 `ModelContext(modelContainer)`** (使用者 2026-09-25 裁決)：先改主檔記錄、再改引用舊名稱的訂單，只 `save()` 一次；失敗時直接丟棄這個 context。
    - 不用長命 `modelContext` 的原因 (實測)：save 失敗後 `rollback()` 無法還原刪除與插入，主檔的「刪舊名、插新名」會以未存檔變更留在長命 context，下一次任何訂單寫入時一併落盤，變成主檔已改、訂單未改。撞名案例沒有插入仍殘留，證實不是清理程式的問題。
    - 一次性 context 只更新既有訂單列、不插入訂單，且與其他訂單寫入在同一個 actor 上依序執行，不牴觸「訂單持久層只用單一長命 `OrderPersistence`」防的並發重複插入。
    - 成功後長命 context 可能仍快取改名前的訂單值，與付款方式編輯 (`applyEdit`) 已接受的風險相同；記憶體內訂單由 `RootFeature` 收到 `itemRenamed` 後改寫。
- 主檔記錄的改名規則只有一份：`NameLookupPersistence.rename` 的「刪舊名、新名不存在才插入」與 `PaymentMethodPersistence.rename` 的「撞名時合併旗標」抽成吃 `ModelContext` 的共用 helper，原本兩個方法與新的交易都呼叫它，行為不變。
- `OrderRepository` 以四個對應的交易 closure 取代原本只改訂單的四個改名 closure (呼叫端只有 `LookupItemOperations` 與 UI 測試替身)；`LookupItemOperations.renameItem` 改成一次呼叫，刪除補償、兩個分派方法與 `OSLog` 匯入。
- 撞名合併是既有功能，照舊保留：成功時新名稱只剩一筆、引用舊名的訂單改指新名；失敗時兩張表都不動。
- 付款方式的改名目前畫面走不到 (付款方式走「編輯」與 `applyEdit`)，仍依窮舉實作，確保新增主檔種類時的編譯期義務不變。
- `.claude/rules/ios-data-layer.md` 的「跨檔不變式」補一條：主檔改名是一次原子操作 (一次性 context、單次 save、失敗丟棄)；「訂單寫入」補一條 gotcha：長命 context 在 save 失敗後 `rollback()` 無法還原插入與刪除，需要失敗不留殘留的多表交易改用一次性 context。

### 表單關閉後才顯示後續 alert

使用者 2026-09-24 裁決。四個 `@Presents` 併成單一 `destination` 後，表單送出時 reducer 先把 `destination` 設為 `nil` 關閉 sheet，寫入失敗或回溯確認的 alert 若在 sheet 關閉動畫結束前就設進同一個 `destination`，SwiftUI 會丟掉這次呈現，`destination` 卻已是 `.alert`，畫面看不到提示。證據 (iPhone UI 測試)：`testAddWriteFailureShowsAlertAndLeavesListUnchanged` 與 `OrderDetailTests/testCashOnDeliveryCorrectionPersistsAfterRelaunch` 皆報「alert 未出現」；暫時在失敗回應前延遲 1 秒後前者轉綠；只移除表單元件送出後自行呼叫的 `dismiss()` 仍紅，所以成因是時序，不是元件自行關閉。

- 表單體驗不變 (送出即關閉)，兩個表單元件 (`LookupNameEditorSheet`、`PaymentMethodEditorSheet`) 不改。
- `State` 加 `isFormSheetDismissing: Bool` 與 `pendingAlert: Destination.State?`：三個表單的 `delegate(.saved)` 分支把 `destination` 設為 `nil` 時一併設 `isFormSheetDismissing = true`。
- 會在表單關閉期間到達的四個 alert 來源 (`addResponse(.failure)`、`renameResponse(.failure)`、`correction(.delegate(.confirmationRequired))`、`correction(.delegate(.failed))`) 改經同一個入口：`isFormSheetDismissing` 為真時存進 `pendingAlert`，否則直接設 `destination`。刪除失敗來自確認 alert、不經表單，維持直接設 `destination`。
- `View.Action` 加 `formSheetDismissed`；三個 `.sheet(item:onDismiss:)` 的 `onDismiss` 送出它。reducer 收到時設 `isFormSheetDismissing = false`，有 `pendingAlert` 就移到 `destination` 並清空。使用者取消表單時同樣觸發，此時沒有暫存 alert，不改變狀態以外的任何東西。
- 刪除失敗 (確認 alert 關閉後緊接失敗 alert) 是否有同樣問題未知，以新增的 UI 測試 `testDeleteWriteFailureShowsAlertAndLeavesListUnchanged` 判定；若它紅，停下回報，不自行擴充機制。

### iPad 側邊欄切分頁先清「更多」路徑

使用者 2026-09-24 裁決在本 change 修正 (既有缺陷，由本步新增的 UI 測試首次在 iPad 觸發)。iPad 在「更多」下的推入頁 (如商品類別管理) 點側邊欄其他分頁時，`RootFeature.tabSelected` 只改 `selectedTab`、不清 `morePath`，`NavigationSplitView` 在 `NavigationColumnState.boundPathChange` 觸發 assertion 閃退 (crash report `BuyLedger-2026-09-24-215534.ips`，`LookupManagementTests/testRenameCategoryUpdatesLookupAndOrderPicker` 在 iPad 重現)。側邊欄的智慧分組 (`smartGroupSelected`) 同樣切到訂單分頁、同樣沒清。`RootSidebarLayout`、`MoreView` 與 `tabSelected` 在本 change 前後皆未改動，所以不是本步造成的回歸。

- `RootFeature.Action` 新增 `sidebarTabSelected(RootTab)`：先 `morePath.removeAll()` 再設 `selectedTab`；`RootSidebarLayout` 的側邊欄選取改送它。
- `smartGroupSelected` 開頭同樣先 `morePath.removeAll()` (只有 iPad 側邊欄會送)。
- `tabSelected` 不變：iPhone 的 `TabView` 走這條，切回「更多」仍停在原本推入的頁面。
- 範圍外：`RootFeature` 其他結構 (`morePath` 改 `StackState` 等) 仍留給第 8 步。

### 四個 @Presents 併成單一 Destination

`tca-architecture.md` 規定一個畫面只有一個 `destination`。`deletionConfirmation`、`retroactiveConfirmation`、`writeFailureAlert` 併入 `Destination` 的 `alert` case：

```swift
@Reducer
enum Destination {
    case add(LookupAddFormFeature)
    @ReducerCaseIgnored
    case alert(AlertState<Alert>)
    case editPaymentMethod(PaymentMethodEditFormFeature)
    case rename(LookupRenameFormFeature)

    @CasePathable
    enum Action { /* add、alert、editPaymentMethod、rename 四個 case，各自對應上面的 case */ }

    @CasePathable
    enum Alert { /* confirmDelete(name: String)、confirmPaymentMethodEdit、cancelPaymentMethodEdit */ }

    enum WriteFailure { /* add、delete、rename、paymentMethodEdit */ }
}
```

- **TCA 1.25 起，目的地列舉持有 `AlertState` 這類非 Feature 狀態時，必須標 `@ReducerCaseIgnored` 並明寫 `Action` 列舉** (官方 `MigratingTo1.25` 文件)。專案鎖定 TCA 1.26.2 (revision `377da406`)，本機實際使用的 checkout 在 `~/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/DerivedData/BuyLedger-7e23f7e00e0e/SourcePackages/checkouts/swift-composable-architecture` (`git describe` 為 1.26.2)，其 `Examples/SyncUps/SyncUps/SyncUpDetail.swift` 就是這個寫法 (`@ReducerCaseIgnored case alert(AlertState<Alert>)`、明寫 `enum Action`、View 用 `$store.scope(\.$destination, action: \.destination).edit`)。
- `Alert`、`Action`、`WriteFailure` 寫在 `Destination` 本體內，屬 `formatting.md` 例外三「Nested Types 內的小型別就地實作」，與官方範例一致。
- 三種 alert 的建構是 `extension LookupManagementFeature.Destination.State` 的 `static func deleteConfirmation(name:)`、`retroactiveConfirmation(affectedOrderCount:)`、`writeFailure(_:)`，放 `// MARK: - Internal Method`；文案與按鈕逐字沿用現況。回溯確認的取消鍵改帶 `cancelPaymentMethodEdit` action (原本無 action、靠 `.dismiss` 判斷)，因為單一目的地的 `.dismiss` 分不出是哪一個 alert。
- `// MARK: - Equatable` 補 `extension LookupManagementFeature.Destination.State: Equatable {}`；`Destination.Action` 不再需要 `Equatable`。
- View 以 1.25 的列舉 scope 綁定：`.sheet(item: $store.scope(state: \.$destination, action: \.destination).add)`、`.rename`、`.editPaymentMethod` 三個 sheet，與 `.alert($store.scope(state: \.$destination, action: \.destination).alert)`。
- **行為不變的依據**：付款方式編輯表單送出即關閉 (見 Context)，所以三種 alert 出現時畫面上不會有表單；同一時刻只會有一個目的地，與現況使用者看到的一致。
- 父層收到 `correction(.delegate(.edited(plan)))` 時不再把 `destination` 設為 `nil` 或清除 `hasLoadFailed`：確認 alert 已由按鈕關閉，再設 `nil` 可能關掉使用者剛開的其他表單；更正成功也不代表首次載入失敗的清單已重新載入。

### 付款方式更正流程抽成子 Feature

`PaymentMethodCorrectionFeature` 承接現況 `editConfirmed` → `paymentMethodEditPrepared` → `retroactiveConfirmation` → `paymentMethodEditSucceeded`／`paymentMethodEditFailed` 的全部邏輯，規則逐條不變 (`.claude/rules/ios-data-layer.md`「付款方式編輯是一次原子操作」)。

- State：`@Shared(.lookupCatalog) var catalog: LookupCatalog` (讀取目前旗標)、`var pendingPlan: PaymentMethodEditPlan?`。
- Dependencies：`OrderRepository` 用來找出引用原付款方式的訂單，`PaymentMethodRepository` 用來一起寫入付款方式與訂單 (全部成功或全部不動)。
- `requested(originalName:newName:flags:)`：以 `catalog.paymentMethodFlags(named: originalName)` 取目前旗標，與送出旗標比較得出 `hasChangedFlags`，回傳找出引用原付款方式訂單的 Effect：`fetchOrders()` 後篩出 `paymentMethod == originalName` 的訂單，逐筆 `renamingPaymentMethod(to:)` 再 `applyingPaymentMethodFlags(_:)`，組成 `PaymentMethodEditPlan` 以 `planResponse` 送回。多行 closure 用具名參數，不用 `$0`。
- `planResponse(.success(plan))`：沒有受影響訂單或旗標未變時直接寫入；否則存入 `pendingPlan` 並送 `.delegate(.confirmationRequired(affectedOrderCount:))`。`.failure` 送 `.delegate(.failed)`。
- `confirmed`：取出並清空 `pendingPlan` 後寫入；沒有 `pendingPlan` 時 `.none`。`cancelled`：清空 `pendingPlan`，主檔與訂單都不動。
- `editResponse(.success(plan))` 送 `.delegate(.edited(plan))`；`.failure` 送 `.delegate(.failed)`。
- 父層：表單 `delegate(.saved(originalName:newName:flags:))` → 關閉目的地並送 `.correction(.requested(...))`；`correction(.delegate(.confirmationRequired(count)))` → `destination = .retroactiveConfirmation(affectedOrderCount: count)`；alert 的 `confirmPaymentMethodEdit`／`cancelPaymentMethodEdit` → 轉送 `.correction(.confirmed)`／`.correction(.cancelled)`；`correction(.delegate(.edited(plan)))` → 目錄移除舊名、以新名與新旗標加入，保留 `hasLoadFailed` 原值，回傳 `.send(.delegate(.paymentMethodEdited(plan)))`；`correction(.delegate(.failed))` → `destination = .writeFailure(.paymentMethodEdit)`。
- `RootFeature` 改攔截 `.lookupManagements(.element(id: .paymentMethod, action: .delegate(.paymentMethodEdited(plan))))`，照現況純轉送 `.orders(.paymentMethodFlagsApplied(plan.affectedOrders))`，不再正規化。
- 旗標由送出當下的目錄讀取，與現況 `editConfirmed` 讀 `paymentMethodFlagSnapshot` 的時點相同。

### 讀寫分派收進 LookupItemOperations

`LookupItemOperations` 是 `Sendable` struct，stored property 為五個 repository (`CategoryRepository`、`OrderRepository`、`OrderSourceRepository`、`PaymentMethodRepository`、`ReconciliationStatusRepository`，依名稱字母序)。它本身不宣告 `@Dependency`，由 `LookupManagementFeature` 在 Private Method 以自己 `Dependencies` 區的五個依賴建立。

- Internal Method 提供四個回傳 `Effect<LookupManagementFeature.Action>` 的方法：`load(kind:)`、`add(_ addition: LookupItemAddition, kind:)`、`delete(name:kind:)`、`rename(_ rename: LookupItemRename, kind:)`，各以單一 `do`／`catch` 把 `throws(PersistenceError)` 的結果包成對應的 `*Response`。
- Private Method 放每種主檔的實際分派，四種操作各一個窮舉 `switch kind`，這是全庫唯一依主檔種類選資料來源的地方：
    - 讀取回傳只填入該種類清單的 `LookupCatalog`；付款方式依名稱 `localizedStandardCompare` 排序 (原本在 reducer 內排序，移到這裡)。
    - 改名呼叫 `OrderRepository` 的單一交易改名 (見「改名是單一交易」)，一種主檔一個 closure，由一個窮舉 `switch kind` 分派；失敗直接拋出，父層照一般改名失敗處理。
- `itemsResponse(.success(fetched))` 以新增的 `LookupCatalog.replaceItems(of:from:)` 只換掉該種類清單，其他種類不動。

**替代方案**：無 case 的 enum 加 `static func`，五個 repository 逐一當參數傳。否決理由是每個方法都要五個參數，呼叫端與簽章都更長，且這些值在一次 reducer 呼叫內本來就是同一組。

### 付款方式旗標改為單一查詢

使用者 2026-09-24 裁決納入。`LookupCatalog` 新增 `func paymentMethodFlags(named name: String) -> PaymentMethodFlags`：取第一筆同名項目的 `currentFlags`，找不到回 `PaymentMethodFlags.none`。

- 刪除 `LookupManagementFeature.State` 的 `paymentMethodIsCardless`、`paymentMethodIsBankTransfer`、`paymentMethodIsCashOnDelivery` 三張 `Dictionary(uniqueKeysWithValues:)` 對應表與 private 的 `paymentMethodFlagSnapshot(for:)`。
- 父層 `classification(for:)`、開啟編輯表單時的旗標快照、`PaymentMethodCorrectionFeature` 的 `hasChangedFlags` 判斷都改用這一個方法。
- `LookupCatalogTests` 補「同名兩筆取第一筆」「找不到回無旗標」的參數化測試 (lookup-management spec 的新增 requirement)。

### LookupKind 與 LookupCatalog 的分區與命名

- `LookupKind`：依 `domain/Enum.swift` 樣板，本體只放 case (刪掉 `// MARK: - Cases`)，顯示字串移到 `// MARK: - Computed Properties` extension，`isReferenced(by:name:)` 與 `renamingReference(in:from:to:)` 放 `// MARK: - Internal Method` (原 `Order Cascade`)。遵循改為 `String, CaseIterable, Sendable` (raw value enum 已自動具備 `Equatable`、`Hashable`)。`addAlertTitle` → `addFormTitle`、`addAlertMessage` → `addFormMessage`、`addFieldPlaceholder` → `nameFieldPlaceholder` (它早已同時用在新增、改名、編輯三種表單)；`LookupKind` 這三個屬性的呼叫端只有 `LookupManagementView`。`OptionPickerSheet` 的同名參數標籤 (`addAlertTitle:` 等) 是 Shared 元件的介面，不在本步改名。
- **`LocalizationCatalogTests` 以屬性名稱辨識使用者可見文案**：其 `displayProperties` 清單列有 `addAlertTitle` 與 `renameSheetTitle`，改名後若不同步，`addFormTitle` 的字串就不再被檢查是否進了字串目錄，而且沒有任何測試會轉紅。所以 `displayProperties` 的 `addAlertTitle` 換成 `addFormTitle` (`visiblePatterns` 裡的 `addAlertTitle:` 參數標籤規則照舊，它比對的是 `OptionPickerSheet` 的呼叫端)；`LookupManagementView` 的改名表單標題維持 `renameSheetTitle` 這個名稱。以變異驗證確認：暫時讓 `addFormTitle` 回傳一個字串目錄沒有的字串，`LocalizationCatalogTests` 轉紅。四個 case 與空狀態屬性的 doc 改寫成說明用途，不複述名稱。
- `LookupCatalog`：`Data Properties` → `Properties`；doc 的「trim」「no-op」改白話；新增 `paymentMethodFlags(named:)` 與 `replaceItems(of:from:)` 放 `Internal Method`。`SharedKey` 的 `lookupCatalog` 擴充移到 `Features/Lookups/SharedKey+LookupCatalog.swift` (它引用 Feature 型別，不能放 `Shared/Extensions/`)，單一 extension 不加 MARK。`.inMemory` key 屬既有登記差異，不動。

### LookupManagementView 與 LookupNameEditorSheet

- `LookupManagementView` 依 View 樣板分區：Properties → Body → Private Views → Private Method → Preview (沒有 `Computed Properties`)。`body` 只放清單、`.task { await store.send(.view(.task)).finish() }`、`accessibilityIdentifier`、導覽標題、`toolbar { ToolbarItem(placement: .primaryAction) { addButton } }`、三個 `.sheet` (`add`／`rename`／`editPaymentMethod`) 與一個 `.alert`；modifier 依版面 → 外觀 → 行為 → 導航與呈現排列，只做跨組移動。
- 所有 `store.send` 與子層 store 的 `send` 都送 `.view(...)`；改名送出改為單一 `renameStore.send(.view(.saveButtonTapped(name:)))`，不再連送 `draftChanged` 與 `saveButtonTapped`。
- 清單列抽成 `Features/Lookups/Components/LookupItemRow.swift`：輸入 `name: String` 與 `classification: PaymentMethodFlags?` (`nil` 代表此主檔沒有分類)，只負責名稱與三種徽章；徽章的 modifier 依 `.padding(.horizontal)` → `.padding(.vertical)` → `.font` → `.foregroundStyle` → `.background` 排列，外觀不變。原 `listContent` 內的 `let palette = BLPalette()` 改為 Private Method 的 `palette` computed property。改名表單標題 (依主檔種類的四種字串) 由 Properties 區移到 Private Method。
- 改名表單標題的 Private Method 維持名稱 `renameSheetTitle` (見「LookupKind 與 LookupCatalog 的分區與命名」的 `LocalizationCatalogTests` 說明)。
- 付款方式清單的說明文字 footer 與空狀態照舊；`hasLoadFailed` 取代 `errorMessage` 的顯示條件。
- `#Preview` 至少四個：商品類別有資料、付款方式含徽章、空狀態、載入失敗。`LookupItemRow` 至少兩個 (一般主檔、付款方式三種徽章)。
- `LookupNameEditorSheet`：Properties 依 `@Environment` → `@State` 與 `@FocusState` (同組依名稱字母序) → `let` (依名稱字母序) 排列；`showsDiscardConfirmation` 改名 `isDiscardConfirmationPresented` (Bool 命名規則，與 `PaymentMethodEditorSheet` 一致)；`.alert` 的按鈕與訊息抽成 Private Views；doc 的「callback」「caller」「trim」「dismiss action」改白話。
- 兩檔各自不超過 300 行。
- **清單抽成 `Features/Lookups/Components/LookupItemList.swift`** (使用者 2026-09-24 裁決：抽出 `LookupItemRow` 後 `LookupManagementView` 仍有 343 行，依 `apps/ios/CLAUDE.md`「超過 300 行時優先抽成獨立 View 型別並傳入必要值與 closure」選此做法，不改表單 Feature 的 State、不登記行數例外)：
    - 收整個 `List`：載入失敗列、空狀態、`ForEach` 的 `LookupItemRow` 與其 `contextMenu`／`swipeActions`、section header 筆數與付款方式 footer；編輯或重新命名按鈕的分支與 `palette` 一併搬入，`LookupManagementView` 不再持有 `palette`。
    - 只收值與 closure，不綁 store：`items`、`kind`、`hasLoadFailed`、以名稱查分類的 closure，以及刪除、編輯付款方式、重新命名三個動作 closure；`LookupManagementView` 在 closure 內送對應的 `.view(...)` action。
    - accessibility identifier 逐一保留在原本的元素上 (`row`、`deleteButton`、`editButton`、`renameButton`、`loadFailureMessage`)；`root` 留在 `LookupManagementView`。四張主檔管理 snapshot 必須不重錄即通過。
    - `#Preview` 至少兩個：一般主檔有資料、付款方式含徽章與 footer。
- `#Preview` 不覆寫依賴 (`tca-architecture.md`「Preview 直接建 Store，不覆寫依賴」)：`InMemoryStorage` 的 `previewValue` 退回 `liveValue`，同一個 preview process 共用一份，所以每個 preview 都明寫自己的目錄內容 (空的也寫)，再設 `hasLoaded = true` 避免 `.task` 以空的 preview repository 覆蓋。

### reducer 不 import SwiftUI

`LookupManagementFeature`、`LookupManagementFeature+Destination.swift` 與本步新增的所有 Feature 只 `import ComposableArchitecture` 與 `Foundation`。

**已查證的依據** (swift-navigation 2.8.0，checkout 與 TCA 同目錄 `swift-navigation/Sources/SwiftNavigation/TextState.swift`)：`TextState` 有三個接字串的初始化：`init(_ key: LocalizedStringKey, …)` (只在 `canImport(SwiftUI)` 時存在)、`init(_ resource: LocalizedStringResource)` (iOS 16 起)、`@_disfavoredOverload init<S: StringProtocol>(_ content: S)` (原文照印)。以 `nm -u` 查現有編譯產物 (`Build/Intermediates.noindex/BuyLedger.build/Debug-iphonesimulator/BuyLedger.build/Objects-normal/arm64/<檔名>.o`) 得到：

| 檔案 | 是否 import SwiftUI | 綁定的 `TextState` 初始化 |
|---|---|---|
| `PersistenceFailureFeature` | 否 | 只有 `init(LocalizedStringResource)` |
| `CampaignEditFeature` | 否 | 只有 `init(LocalizedStringResource)` |
| `LookupManagementFeature` (現況) | 是 | `init(LocalizedStringResource)` 與 `init(LocalizedStringKey, …)` |
| `OrdersFeature` | 是 | `init(LocalizedStringResource)` 與 `init(LocalizedStringKey, …)` |

也就是說，**全 App 的 alert 字串字面值不論有沒有 import SwiftUI，都已經綁定 `LocalizedStringResource` 版本**；現況 `LookupManagementFeature` 會綁到 `LocalizedStringKey` 版本，只因為它把 `LocalizedStringKey` 型別的變數 (`message`) 傳給 `TextState`。本步把所有 alert 文案改成直接寫在 `TextState(...)` 內的字面值 (含回溯確認的 `"確認後將重算 \(count) 筆…"` 插值字面值，`LocalizedStringResource` 支援插值，插入整數時的 key 是既有的 `%lld` 版本)，因此不需要 import SwiftUI，且與全 App 其他 alert 走同一條本地化路徑。

- 不得再宣告 `LocalizedStringKey` 型別的中介變數；編譯失敗時停下回報，不以 `import SwiftUI` 繞過。
- 驗收：task 3.1 編譯後，以同一個 `nm -u … | swift demangle | grep 'TextState.init'` 查 `LookupManagementFeature+Destination.o`，只能出現 `init(LocalizedStringResource)`，指令與輸出記在 task 下方；`LocalizationCatalogTests` 維持綠燈 (文案 key 都在字串目錄)。
- **範圍外的觀察**：`LocalizedStringResource` 版本在 App 內語言切換下是否跟著切換，本步沒有驗證；它是全 App alert 的既有行為，不因本步改變。

### Action 分組守門涵蓋主檔與子層 store

`ActionGroupingScanTests` (第 3 步新增) 兩處調整：

- `migratedViewPaths` 加入 `Features/Lookups/LookupManagementView.swift`，`migratedComponentDirectories` 加入 `Features/Lookups/Components`。
- **`storeSendPattern` 目前是 `/store\s*\.\s*send\s*\(\s*/`，大小寫敏感，`renameStore.send(...)` 這類子層 store 的送出完全掃不到**。改為同時比對 `store` 與以 `Store` 結尾的駝峰識別字 (例如 `/\b(?:store|\w+Store)\s*\.\s*send\s*\(\s*/`)，自我測試表 (`ActionGroupingScanTests+Scenarios.swift`) 補三列：子層 store 送 `.view(` 通過、子層 store 送 `.draftChanged(` 違規、`restoreSend(` 之類不相干識別字不被誤判。改動後既有已遷移 View 若出現新違規，停下回報。
- 變異驗證兩次：在 `LookupManagementView` 暫時加一個子層 store 送非 `.view` action，規則一轉紅；在 `LookupManagementFeature` 暫時加一個 `case .destination(.presented(.rename(.view(...))))`，規則二轉紅。各確認 xcresult `totalTestCount` > 0 後還原。

### 改動前先錄主檔管理的 snapshot 與 UI 測試

主檔管理畫面目前沒有 snapshot，也沒有新增、改名、刪除的 UI 測試。依「行為驗收一律用 UI Automation 實測」的專案做法，在改動任何 production 行為前先補兩類守門：

**snapshot** (新檔 `BuyLedgerTests/SnapshotTests+Lookups.swift`，以 `extension SnapshotTests` 撰寫，沿用 `SnapshotTests.swift` 的 `#if canImport(SnapshotTesting) && os(iOS)` 包覆；CI 以 `-skip-testing:BuyLedgerTests/SnapshotTests` 排除的是整個 suite 型別，extension 一併排除)：

| 測試 | 內容 |
|---|---|
| `lookupManagementCategoryBaseline` | 商品類別，目錄依序為「服飾」「美妝」「精品」 |
| `lookupManagementPaymentMethodBaseline` | 付款方式，目錄依序為「信用卡」(無旗標)、「無卡分期」(無卡)、「銀行匯款」(銀行匯款)、「貨到付款」(貨到付款)，含 footer |
| `lookupManagementEmptyBaseline` | 商品類別，目錄為空 |
| `lookupManagementLoadFailureBaseline` | 商品類別，目錄為空，改動前 `errorMessage = "主檔載入失敗，請稍後再試。"`、改動後 `hasLoadFailed = true` |
| `lookupNameEditorSheetRenameBaseline` | 改名表單：`title` 「重新命名商品類別」、`message` 「改名後，引用此名稱的訂單也會一併更新。」、`namePlaceholder` 「類別名稱」、`submitTitle` 「儲存」、`initialName` 「服飾」 (都是現況改名流程傳入的既有字串) |

- 四張主檔管理頁以 `NavigationStack { LookupManagementView(store: …) }` 建構，讓導覽標題與新增鍵一起入圖 (比照該 View 既有 `#Preview`)；名稱表單本身自帶 `NavigationStack`，直接建構。
- 每條都以 `TestDependencies.withFixedNow` 包住畫面建構與 `assertSnapshot` (`.claude/rules/ios-unit-tests.md` 的 snapshot 規則)，寫法比照既有 `fxViewBaseline`。
- 基準圖目錄是 `BuyLedgerTests/__Snapshots__/SnapshotTests+Lookups/`：swift-snapshot-testing 1.19.2 以呼叫 `assertSnapshot` 的原始檔名 (`#filePath` 去掉副檔名) 當子目錄 (`Sources/SnapshotTesting/AssertSnapshot.swift` 的 `fileUrl.deletingPathExtension().lastPathComponent`，checkout 與 TCA 同目錄)，與 extension 所屬的 suite 型別無關。
- store 用 `Store(initialState: state) { EmptyReducer() }`，讓畫面出現時送的 `.task` 不改變狀態；目錄在新增的 `LookupCatalog.withIsolatedStorage` 內寫入 (`BuyLedgerTests/LookupCatalog+TestIsolation.swift`，以 `defaultInMemoryStorage = InMemoryStorage()` 隔離)，避免第 1 步踩過的 `@Shared` 跨測試污染。
- 外觀先鎖淺色；含 `.borderedProminent` 工具列按鈕的名稱表單用 `.image(drawHierarchyInKeyWindow: true)`，主檔管理頁若 `.image` 渲染出空白導覽列同樣改用它，選用方式記在 `tasks.md`。
- 載入失敗那張在 task 3.1 之後要把 State 建構從 `errorMessage = "…"` 改為 `hasLoadFailed = true`，這是唯一允許的測試碼改動，基準圖不得重錄。

**UI 測試** (新檔 `BuyLedgerUITests/Tests/More/LookupManagementTests.swift` 與 page object `BuyLedgerUITests/Screens/LookupManagementScreen.swift`)，iPhone 與 iPad 都要跑：

| 測試 | 驗證 | 改動前預期 |
|---|---|---|
| 新增類別 | `lookupsOnly` seed，從「更多」進商品類別，新增「手作小物」後清單出現該列 | 綠 |
| 改名類別 | `minimalOrders` seed，把被訂單引用的「服飾」改名為「衣著」，清單只剩新名稱；再開新訂單的類別選擇器，新名稱在、舊名稱不在 (新名稱以 `BLAccessibilityID.OptionPicker.optionRow(_:)` 的 `waitForExistence` 判定，舊名稱在選擇器根元素出現後以同一個 identifier 的 `exists == false` 判定；不用 `OptionPickerScreen.optionLabel(for:)`，它遇到不存在的選項會直接 `failWithDiagnostics`，也不改 `OptionPickerScreen`) | 綠 |
| 刪除類別 | `lookupsOnly` seed，刪除「生活雜貨」並確認後該列消失 | 綠 |
| 新增失敗 | `lookupsOnly` seed 加 `-BLUITestLookupWriteFailure`，新增「失敗類別」，出現「操作失敗」alert，關閉後清單不含該名稱、清單上方沒有紅字 | **紅** (現況顯示紅字、清單出現該名稱) |
| 首次載入失敗 | `lookupsOnly` seed 加既有 `LoadFailure.lookups` 啟動，清單上方顯示載入失敗訊息 | 綠 |

- 需要的 identifier 新增在 `BLAccessibilityID.LookupManagement`：`addButton`、`deleteButton(_:)`、`nameField`、`nameSubmitButton` (名稱表單的欄位與送出鈕)、`loadFailureMessage` (清單上方的載入失敗文字，讓「新增失敗」判斷紅字不存在、「首次載入失敗」判斷紅字存在，不以顯示文字定位)；兩端引用常數。identifier 只掛在按鈕、輸入欄與本身就是無障礙元素的 `Text` 上。
- 「首次載入失敗」使用既有 `LaunchOptions.LoadFailure.lookups`：它同時讓四種主檔讀取與幣別主檔的讀取、刷新失敗 (`BLUITestDependencyOverrides.applyLookupOverrides`)。這條測試只斷言主檔管理頁的 `loadFailureMessage` 出現，不檢查幣別相關畫面，幣別失敗的副作用不影響判定。
- UI 測試 harness 目前沒有「寫入失敗」選項。新增啟動參數 `-BLUITestLookupWriteFailure` (`BLUITestConfiguration.shouldFailLookupWrites`、`LaunchOptions.shouldFailLookupWrites`)，開啟時四種主檔 repository 的新增、刪除、改名都拋錯，讀取不受影響；`BLUITestConfigurationTests` 補解析測試。
- 需要一筆訂單引用改名的類別；已查證 `BLUITestSeedData.makeMinimalOrders` 有一筆 `categories: ["服飾"]` 的訂單，`minimalOrders` seed 可用。
- 「新增失敗」在改動前轉紅是預期的證據 (新測試先失敗、改動後轉綠)，失敗訊息記在 `tasks.md`。

### 測試拆檔與寫法

- `LookupManagementFeatureTests.swift` (1,030 行) 依職責拆成：主檔 `LookupManagementFeatureTests.swift` (載入、新增、刪除、寫入失敗)、`LookupManagementFeatureTests+Forms.swift` (表單開啟、驗證、改名、付款方式編輯轉送)，更正流程的測試搬到新的 `PaymentMethodCorrectionFeatureTests.swift`。任一檔仍超過 300 行時，依同一命名規則再拆 `LookupManagementFeatureTests+<Domain>.swift`，不需停下回報。
- 共用的 `withIsolatedCatalog` 改為 `LookupCatalog.withIsolatedStorage` (`LookupCatalog+TestIsolation.swift`)，泛型參數具名 `Output`；`.claude/rules/ios-unit-tests.md` 的參考同步改。
- `LookupManagementFeatureTests` 必須涵蓋父層把更正失敗轉成 alert：子 Feature 送出 `delegate(.failed)` (找出引用原付款方式的訂單失敗與一起寫入失敗各一條) 時，`destination` 變成 `.writeFailure(.paymentMethodEdit)`，關閉後回到 `nil` 且目錄不變。
- 測試寫法沿用第 3 步：每個 `@Test` 有 `///` 與 Given／When／Then 三段且標記底下有對應程式碼；`receive` 一律 case key path (現況 8 處以整個 action 值比對)；同一邏輯多組輸入用 `@Test(arguments:)`，四種主檔的載入與新增以 `LookupKind.allCases` 參數化；三個旗標以 `PaymentMethodFlags` 表示，不用三元素 tuple；`PaymentMethodEditTestBox` (`@unchecked Sendable`) 改 `LockIsolated`；`makePaymentOrder` 改用 `LedgerOrder.fixture(...)` 並覆寫付款相關欄位。
- `addConfirmedWritesThroughToTheSharedCatalog...` 宣稱驗證跨容器共享卻讀同一個 store，改成在同一個隔離範圍另宣告 `@Shared(.lookupCatalog)` 讀取比對。
- `LookupCatalogTests.renamingPaymentMethodMergesFlagsWhenEitherSideIsTrue`：審查報告 (2026-09-14) 記的「付款方式合併旗標測試沒走到合併分支」已在第 0 步 commit `4263e45` 修好 (現況先放入「匯款」與已存在的「銀行匯款」兩筆再改名)，task 0.1 抽驗時發現。本步不改寫它的內容 (只套用測試寫法規範)，以 task 1.2 的變異驗證確認它會在合併邏輯壞掉時轉紅。
- `RootFeatureTests` 只改直接送出主檔內部 action 的 10 條，逐條如下，改為經由子層 `view` 與 `delegate` 走完整流程：
    - `paymentMethodEditSuccessForwardsTheSameNormalizedOrdersToOrdersFeature`、`paymentMethodEditCancellationLeavesRootOrdersAndMasterUnchanged`、`paymentMethodEditPersistenceFailureLeavesOrdersAndMasterUnchanged`
    - `categoryRenameCascadesInsideMultiCategoryOrders`
    - `renamingOrderSourceSyncsManagementOrdersAndAvailableListInOneReducerCall`、`renamingCategorySyncsManagementOrdersAndAvailableListInOneReducerCall`、`renamingReconciliationStatusSyncsManagementOrdersAndAvailableListInOneReducerCall`、`renamingPaymentMethodSyncsManagementOrdersAndAvailableListInOneReducerCall`：斷言改成「寫入成功後目錄更新、收到 `itemRenamed` 後改寫訂單」，名稱依序改為 `renamingOrderSourceRewritesOrdersThroughDelegate`、`renamingCategoryRewritesOrdersThroughDelegate`、`renamingReconciliationStatusRewritesOrdersThroughDelegate`、`renamingPaymentMethodRewritesOrdersThroughDelegate`
    - `deletingCategoryRemovesItFromOrderEditorAvailableList`
    - `ordersChangeSyncsAllProjections` (以改名觸發投影同步)
  另**新增一條** `renamingCategoryWriteFailureLeavesOrdersUnchanged`：以 `$0[CategoryRepository.self].renameCategory` 拋 `PersistenceError.saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))` 注入失敗 (比照現有刪除失敗測試的寫法)，斷言目錄與記憶體訂單都維持「服飾」、沒有收到 `itemRenamed`、`destination` 為改名失敗 alert。所以本 task 是改寫 10 條、新增 1 條。
  完工時以 `grep -n "renameRequested\|paymentMethodEditSucceeded\|deleteRequested\|editConfirmed\|?\.retroactiveConfirmation\|\.retroactiveConfirmation(\.\|paymentMethodIs" apps/ios/BuyLedgerTests/RootFeatureTests.swift` 確認無輸出。`retroactiveConfirmation` 只比對舊的 state 欄位 (`?.retroactiveConfirmation`) 與舊 action (`.retroactiveConfirmation(.dismiss)`／`(.presented(...))`) 形狀；新的 `Destination.State.retroactiveConfirmation(affectedOrderCount:)` 建構呼叫是必要寫法，不列入。其餘測試不動，仍用既有 `makeIsolatedRootState`。
- 窮舉 `TestStore` 不關 exhaustivity；`TestSuiteIntegrityTests` 的 `.off` 總數不得增加。

### 判讀級 findings 的逐筆處置

`findings.md` 中需要判斷的項目逐筆定案如下 (已預填進 `findings.md`)，其餘判讀項目依其「修法」照做：

| 位置 | 項目 | 處置 |
|---|---|---|
| `LookupCatalog` 的 `.inMemory` key | `@Shared` 帶 persistence key | **登記例外**：既有登記差異 |
| `LookupKind` 遵循宣告 | 冗餘 `Equatable`、`Hashable`，缺 `CaseIterable` | **修** |
| `LookupKind.addAlert*` | 命名停在 alert 時代 | **修**：改 `addForm*`、`nameFieldPlaceholder` |
| `Destination` 子 reducer | 空殼、無 view／delegate | **修**：改為三個表單子 Feature |
| `LookupManagementFeature` 行數 | 超過 300 行 | **修**：依「主檔管理的拆分」 |
| `Dictionary(uniqueKeysWithValues:)` | 同名會 trap | **修**：使用者裁決 |
| 四個 `@Presents` | 一個畫面只能一個 | **修**：併入 `Destination.alert` |
| `RootFeature` 攔截非 delegate | 跨 Feature 意圖走 delegate | **修**：改收 `delegate` |
| 未使用的 `BindableAction` | 無作用 | **修**：移除 |
| 新增、改名先改目錄 | 寫入先落盤 | **修**：使用者裁決 |
| 寫入失敗共用載入錯誤 | 一次性失敗分開呈現 | **修**：使用者裁決 |
| `LookupNameEditorSheet` 的 `canSubmit` | 驗證邏輯可抽成可測函式 | **不修**：見 Non-Goals |
| 測試命名 (2 筆) | 未依「行為_情境_預期」 | **不修**：使用者 2026-09-21 裁決 |
| `LookupCatalogTests` 合併測試 | 沒走到合併分支 | **報告誤報**：第 0 步 commit `4263e45` 已修，task 1.2 以變異驗證確認有效 |
| 5 筆 `TC5` | `some Reducer<State, Action>` | **登記例外**：既有登記差異 |
| 8 筆 `H1` | 報告要求 `YYYY/MM/DD` | **不修**：日期規則已改為不補零，確認格式後標記 |

## Implementation Contract

**行為**：

- **改變 (使用者裁決)**：
    - 新增、改名在寫入成功前不出現在主檔清單與訂單編輯的選單；寫入失敗時清單維持原樣。改名成功後，記憶體內引用舊名稱的訂單由 `RootFeature` 在收到 `itemRenamed` delegate 時改寫。
    - 新增、刪除、改名、付款方式更正失敗時，畫面出現「操作失敗」alert，關閉即消失；清單上方不再出現這類紅字。
    - 付款方式資料有同名項目時畫面不再崩潰，徽章與編輯表單的預設旗標取第一筆。
- **不變**：所有畫面的版面、文字、本地化字串與既有 `BLAccessibilityID`；四種主檔的排序、去重與旗標合併規則；付款方式更正找出引用訂單的方式、確認文案與筆數、一起寫入 (全部成功或全部不動) 與取消後不動主檔；刪除的確認文案；首次載入失敗的紅字與重進畫面時重新載入；UserDefaults、SwiftData schema 與資料庫內容。

**對外介面變更**：

| 介面 | 改動前 | 改動後 |
|---|---|---|
| 主檔管理的 Action | 平放 22 個 case，遵循 `Equatable` | 見「主檔管理的 Action 分組」，不遵循 `Equatable` |
| 根畫面攔截的主檔事件 | `renameRequested(from:to:)`、`paymentMethodEditSucceeded(plan)` | `delegate(.itemRenamed(LookupItemRename))`、`delegate(.paymentMethodEdited(PaymentMethodEditPlan))` |
| 付款方式更正快照 | `LookupManagementFeature.PaymentMethodEditPlan` | 頂層 `PaymentMethodEditPlan`，欄位不變 |
| 主檔管理的呈現狀態 | 四個 `@Presents` | 單一 `@Presents var destination`，含 `@ReducerCaseIgnored` 的 `alert` |
| 載入錯誤 | `errorMessage: String?` | `hasLoadFailed: Bool` |
| 付款方式旗標讀取 | State 的三張對應表 | `LookupCatalog.paymentMethodFlags(named:)`、State 的 `classification(for:)` |
| `LookupKind` | `Equatable, Hashable`，`addAlertTitle`／`addAlertMessage`／`addFieldPlaceholder` | `CaseIterable`，`addFormTitle`／`addFormMessage`／`nameFieldPlaceholder` |
| 表單子 reducer | `LookupManagementFeature.Destination.RenameFeature` 等四個巢狀型別 | 頂層 `LookupAddFormFeature`、`LookupRenameFormFeature`、`PaymentMethodEditFormFeature` |
| UI 測試啟動參數 | 無寫入失敗選項 | 新增 `-BLUITestLookupWriteFailure` |

**失敗模式**：

- 首次載入失敗：清單上方顯示載入失敗訊息，再次進入畫面時重新載入 (與現況相同)。
- 新增、刪除、改名寫入失敗：目錄、記憶體訂單都不動，顯示對應訊息的一次性 alert。
- 改名寫入失敗：主檔表與訂單表在同一次 save 內整批回滾，目錄與記憶體訂單不動，顯示改名失敗 alert。
- 找出引用原付款方式的訂單或一起寫入失敗：主檔與訂單都不動，顯示付款方式編輯失敗 alert。

**驗收條件** (數字與 result bundle 路徑一律記在 `tasks.md` 對應 task 下方，只存在對話裡不算數)：

1. **機械檢查** (A 組整檔、B 組只查改到的行)：行寬不超過 100 (以 python3 按字元計算；只由單一字串字面值構成而超過的行逐行列在 `tasks.md` 並說明)、無尾隨空白與 tab、手寫檔第 5 行完整符合 `^//  Created by Leo Ho on \d{4}/\d{1,2}/\d{1,2}\.$`、每檔不含檔頭與空行不超過 300 行，四項各 0 筆。
   以上與下面第 2、3 項 (含 `- Parameter`／`- Returns`／`- Throws`／associated value 說明、以大括號判斷型別成員與 `@Test` 本體範圍) 都用審查端提供的 `/private/tmp/claude-501/-Users-leoho-Develop-BuyLedger/d4e52ef9-0db8-485b-b7ba-a3127d2503b5/scratchpad/step4-checks/lookups_checks.py` 檢查 (不給參數時取 `git status` 的全部 Swift 檔，A／B 組已內建；各代碼的判定規則寫在腳本開頭)。它已用第 3 步結案的 Fx、Quote、Settings、AISummary、Customers 檔校正過，這些檔除了登記過的單一字串超寬行 (`WSTR`，列出說明、不計入失敗) 外全數通過。腳本回報 `PASS` 才算三項通過，輸出全文記在 task 8.2 下方。
2. **分區檢查**：`// MARK:` 段名都在允許清單內；頂層分區順序正確、同一分區不重複 (排除巢狀型別內與 `Destination` 本體內的小型別)；**區塊內容相符** (`Properties` 不含 func 或 computed property；`Computed Properties` 不含 func；`Internal Method`／`Private Method` 不含 stored property，computed property 只允許出現在 View 與 TCA Feature 的 `Private Method`，因為這兩種型別沒有 `Computed Properties` 分區；`Nested Types` 最外層不含 let／var／func；`Body` 只含 `var body`；View 沒有 `Computed Properties` 分區)；modifier 跨組順序只以 `formatting.md` 表中明列的 modifier 判定。
3. **註解與測試**：A 組宣告缺 `///` 0 筆、B 組本步新增或改動的宣告缺 `///` 0 筆；每個 `@Test` 有 doc 與三段標記，When／Then 標記底下第一個非空行不是 `}` 或另一個標記。
4. **殘留名稱**：`grep -rn` 限本 change 的範圍 (`apps/ios/BuyLedger/Features/Lookups/`、`apps/ios/BuyLedger/Features/App/RootFeature.swift`，以及 `LookupManagementFeatureTests*.swift`、`PaymentMethodCorrectionFeatureTests.swift`、`LookupCatalogTests.swift`、`RootFeatureTests.swift`；`deletionConfirmation`、`writeFailureAlert`、`uniqueKeysWithValues` 等名稱在 Orders、Campaigns 也有各自的同名用法，不在本步範圍)，`paymentMethodIsCardless`、`paymentMethodIsBankTransfer`、`paymentMethodIsCashOnDelivery`、`uniqueKeysWithValues`、`renameRequested`、`paymentMethodEditSucceeded`、`LookupManagementDestination`、`deletionConfirmation`、`retroactiveConfirmation:`、`writeFailureAlert` 皆無輸出；`Features/Lookups/` 內 `import SwiftUI` 只出現在 View 檔，`addAlertTitle`、`addAlertMessage`、`addFieldPlaceholder` 在 `Features/Lookups/` 內無輸出 (`OptionPickerSheet` 的同名參數標籤不在此限)。
5. **守門轉紅**：`ActionGroupingScanTests` 兩條規則各做一次變異驗證 (見「Action 分組守門涵蓋主檔與子層 store」)，對應測試由綠轉紅、xcresult 可解析且執行數大於 0，驗證後還原；還原也算 Swift 寫入，之後的回歸必須晚於它。
6. **完整單元回歸**：以 `BuyLedger.xctestplan` 跑完整單元測試，先鎖模擬器淺色外觀；失敗清單是 task 0.2 基準的子集。頂層 `totalTestCount` 以測試方法計 (參數化測試不論幾組引數都算一條)，因為本步會把重複測試併成參數化、也會搬移與新增測試，所以不設固定門檻，改為兩項：(a) 與基準的差額逐項說明 (新增、刪除、併入參數化的方法名稱)；(b) 下列類別都有執行且 0 失敗：`LookupManagementFeatureTests` (含拆出的 extension 檔)、`PaymentMethodCorrectionFeatureTests`、`LookupCatalogTests`、`RootFeatureTests`、`ActionGroupingScanTests`、`LocalizationCatalogTests`、`BLUITestConfigurationTests`、`TestSuiteIntegrityTests`，以及 `SnapshotTests` 的五條主檔 snapshot。snapshot 失敗先依 `.claude/rules/ios-unit-tests.md` 判別是否為已知渲染雜訊，**不得重錄基準圖**；task 0.3 新增的五條主檔 snapshot 必須在單獨重跑時通過。
7. **UI 回歸**：iPhone 與 iPad 各跑一次 `BuyLedgerUITests` 主回歸，逐台與 task 0.2 基準比較：頂層 `totalTestCount` 等於基準加 7 (本步新增的 `LookupManagementTests`：0.4 的五條、5.2 的刪除失敗，以及 8.2 風格審查依「一個測試只允許一組 When／Then」把改名測試拆成兩條)、失敗清單是基準失敗清單的子集，且 `LookupManagementTests` 七條全綠 (含改動前轉紅的「新增失敗」)、`OrderDetailTests` 的付款方式回溯重算流程維持綠燈。
8. **findings 結論**：`findings.md` 302 筆全部有結論，`待填` 0 筆，預填項目未被改掉。
9. **spectra 檢查**：`spectra validate lookups-style-compliance` 通過。

**讀取測試結果**：測試數、通過數與失敗清單一律以 `xcrun xcresulttool get test-results summary --path <bundle>` 唯讀讀取 result bundle 的頂層 `totalTestCount` 與失敗清單 (不採用裝置層 `passedTests` 展開數)。XcodeBuildMCP 沒有讀取 xcresult 摘要的指令 (`xcodebuildmcp tools` 只有 `get-coverage-report`)，第 2、3 步也是這樣讀；`apps/ios/CLAUDE.md`「不退回原生 xcrun」的例外清單目前沒寫這一項，由 task 0.1 在第一次讀取結果 (task 0.2) 之前補上 (只讀結果，不執行 build 或 test)。

**測試環境** (基準與驗收必須用同一組)：iPhone 用 `iPhone 17` (iOS 26.5，UDID `DDAA3311-B464-4DD3-96B8-360B26AF1929`)，iPad 用 `iPad Air 11-inch (M4)` (iOS 26.5，UDID `6B65ED1C-3C2E-42BA-B1E7-08F606F175C5`)，一律以 `--simulator-id` 指定；`.xcodebuildmcp/config.yaml` 的 session 預設不是這兩台，不要依賴它。開工前以 `xcodebuildmcp simulator list` 確認兩個 UDID 仍存在，不存在就停下回報。iPad UI 回歸前依 `apps/ios/CLAUDE.md` 確認軟體鍵盤可顯示。UI 回歸用 `--scheme BuyLedgerUITests`。

**範圍邊界**：可改動的檔案為 proposal 的 Impact 清單、本 change 目錄的 `tasks.md` 與 `findings.md`，加上下列本 design 決定的連帶檔案：

- `apps/ios/BuyLedgerUITests/Tests/More/LookupManagementTests.swift` (新)
- `apps/ios/BuyLedgerUITests/Screens/LookupManagementScreen.swift` (新)
- `apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift` (只加寫入失敗旗標)
- `apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift` (只加 `LookupManagement` 的五個 identifier)
- `apps/ios/BuyLedger/App/Testing/BLUITestConfiguration.swift`、`apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift` (只加寫入失敗旗標與其替身)
- `apps/ios/BuyLedgerTests/BLUITestConfigurationTests.swift` (只加旗標解析測試)
- `apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift` (只把 `displayProperties` 的 `addAlertTitle` 換成 `addFormTitle`)
- `apps/ios/BuyLedgerTests/LookupManagementFeatureTests+<Domain>.swift` (依「測試拆檔與寫法」按需新增)

**遇到清單外必須改動的檔案就停下來回報，不要自行擴張範圍**。已確認不需要手改：`project.pbxproj` (`PBXFileSystemSynchronizedRootGroup` 按目錄同步，新增 `Components/` 與 `Tests/More/` 子目錄不必手改；唯一允許的 pbxproj 變更是每次 `build` 或 `build-and-run` 前依 `apps/ios/CLAUDE.md` 執行 `agvtool next-version` 造成的 `CURRENT_PROJECT_VERSION` 遞增，多次 build 各遞增一次都可接受)、兩份 xctestplan (不列舉測試類別)、`Localizable.xcstrings` (不新增或改動字串)。

## Risks / Trade-offs

- **[改名交易失敗後殘留未存檔變更]** → 交易用一次性 context，失敗即丟棄；以測試確認「改名失敗後再存一筆無關訂單，主檔表仍維持原狀」。
- **[長命 context 快取改名前的訂單值]** → 與 `applyEdit` 同一等級的已接受風險，記憶體訂單由 `RootFeature` 同步。
- **[寫入失敗 alert 取代使用者剛開的表單]** → 單一目的地同一時刻只能呈現一個，若使用者在寫入結果回來前又開了另一個表單，失敗 alert 會取代它。寫入通常在數十毫秒內完成，發生機率低；接受此取捨換取「不同時呈現兩層 modal」。
- **[`@ReducerCaseIgnored` 或列舉 scope 在 Swift 6 嚴格併發下編不過]** → 官方文件與範例都有此寫法，但專案搭配 `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated` 未實測。遇到編譯障礙停下回報，不退回多個 `@Presents`。
- **[父層在 300 行內放不下]** → 行數是依拆分後的職責估計，尚未實測。超過時停下回報，由使用者決定再拆或登記例外，不壓行。
- **[擴大 `storeSendPattern` 讓既有已遷移 View 轉紅]** → 第 3 步的 View 除了 allowlist 已登記的 `SettingsView` 送 `.appLock(...)` (第 8 步移除) 外都只用 `store.send(.view(...))`，Codex 第一輪也查過全 Features 的 `*Store.send(` 只命中 `LookupManagementView`。擴大後只有**未被 allowlist 涵蓋的新違規**才代表第 3 步有漏網的子層送出，此時停下回報。
- **[`SnapshotTests+Lookups` 的 `@Shared` 寫入污染其他測試]** → 一律在 `LookupCatalog.withIsolatedStorage` 內建立 state；`BuyLedger.xctestplan` 字母序執行，完整回歸出現新紅燈時先查是否為共享狀態外溢。
- **[snapshot 在完整回歸下偶發失敗]** → 依 `.claude/rules/ios-unit-tests.md` 的已知雜訊判別法單獨重跑 (方法層 `-only-testing` 帶 `()`、確認 `totalTestCount` ≥ 1)。
- **[`findings.md` 的預填結論被實作端照單改掉]** → 預填項目在檔頭列出並註明「不要改掉」；驗收條件 8 會檢查。
- **[實作端在沙箱內無法操作模擬器]** → 前兩步確認 Codex 的 XcodeBuildMCP MCP server 會被沙箱擋住，派工時要求走 `xcodebuildmcp` CLI，仍禁止退回原生 `xcodebuild`／`simctl`。

## Migration Plan

無資料遷移：SwiftData schema、UserDefaults key 與資料庫內容都不變。回滾即還原本 change 的 commit。
