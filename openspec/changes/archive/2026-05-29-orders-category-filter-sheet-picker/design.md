## Context

訂單頁類別篩選目前在 iOS、iPadOS、macOS 三個平台都使用「`ScrollView(.horizontal)` 包一排 Capsule 膠囊」呈現，第一顆是「全部」，其後依 `availableCategories` 列出每個類別，選中的膠囊以 purple accent 反差呈現。`OrdersFeature` 的 state 已備好 `selectedCategory: String?` 與 `availableCategories` (computed merge of `categoryMaster` 與 orders 內出現過的 category)，action 為 `categoryFilterSelected(String?)`。

由於類別清單是使用者可新增的 (透過 `LookupManagementFeature`)，會隨使用時間成長；現有膠囊列在類別超過 7–10 個時，水平滑動距離過長、可發現性下降。初版方案曾考慮改成 SwiftUI `Menu`，但 `Menu` 展開後仍有滾動上限且無搜尋，在類別數量 20+ 時體驗仍不佳。本次改為「trigger button + sheet picker (with search)」，並重用既有的 `OptionPickerSheet` 元件（該元件在訂單編輯流程已用於選類別 / 付款方式 / 幣別，內建可搜尋列表、平台分流、空狀態與新增流程）。

`OptionPickerSheet` 既有設計沒有「清除選擇」的概念——picker 是「必選一個」的單選元件。Filter 場景多了一個「全部 (清除篩選)」的特殊選項對應 `selectedCategory = nil`，因此本次需要對 `OptionPickerSheet` 做向後相容的小幅擴充，新增 optional `clearOption` 參數。

狀態篩選 (`OrderStatusFilterBar`)、日期篩選與搜尋欄維持不變；payment method 與 order source 目前沒有篩選 UI，本次也不新增。

## Goals / Non-Goals

**Goals:**

- iOS、iPadOS、macOS 三平台的類別篩選一律改為「trigger button + sheet picker」，視覺與互動行為一致。
- Trigger button label 在未篩選時顯示「類別：全部」，已選中某類別 X 時顯示「類別：X」；末端固定一個 `chevron.down` 提示這是可開啟 sheet 的觸發點。
- 沿用既有 tag icon 放在 label 前緣；capsule fill 仍維持「已選時 purple、未選時 fillTertiary」的反饋。
- Trigger button 只在 `store.availableCategories` 非空時呈現；類別為空時整個篩選位置隱藏（與現況一致）。
- 點 trigger 後 present 既有 `OptionPickerSheet`，搜尋功能 (`searchable: true`) 預設啟用。
- Sheet 內第一列固定為「全部 (清除篩選)」（透過新的 `clearOption` 參數實現），點選後 `selectedCategory` 被清除為 `nil`。
- TCA 行為完全不變：仍透過 `store.send(.categoryFilterSelected(...))` 觸發，state、reducer、`selectedOrderID` 重算邏輯皆原樣。
- `OptionPickerSheet` 既有 call site（訂單編輯選類別 / 付款方式 / 幣別）不需修改、外觀與行為零變動。
- snapshot baseline 在類別存在時會因為篩選列從膠囊列改為單顆 trigger button 而需要 re-record。

**Non-Goals:**

- 不改動狀態膠囊 (`OrderStatusFilterBar`)、日期膠囊、搜尋欄。
- 不改動類別 master 的 CRUD (`LookupManagementFeature`)、cascade rename 與 `RootFeature` 攔截行為。
- 不為付款方式 / 訂單來源加篩選 UI。
- 不改 `OrdersFeature` 的 state shape、action set 或 reducer 行為。
- 不改 SwiftData schema / migration。
- 不引入「最近使用 / 常用類別」排序、群組或多選——sheet 內順序就是 `availableCategories` 既有合併規則。
- 不新建獨立 `CategoryFilterPickerSheet`——重用 `OptionPickerSheet` 並擴充 `clearOption`，避免兩套可搜尋 picker 邏輯各自演化。
- 不引入「依數量自適應 (少量膠囊、多量 sheet)」混合 pattern。

## Decisions

### 重用 `OptionPickerSheet` 並擴充 `clearOption`，而非新建獨立 picker 元件

選擇對既有元件做向後相容擴充：
- `OptionPickerSheet` 已具備搜尋、平台分流（iOS List、macOS BLCard）、空狀態、新增流程，與本次需求高度重疊；新建獨立元件會帶來重複的搜尋邏輯與平台分流維護成本。
- Filter 場景多出的「全部 (清除篩選)」用一個 optional 參數 `clearOption: ClearOption?` 表達；nested type `ClearOption { let title: String; let onClear: () -> Void }`。
- 不在 `options` array 內注入「全部」sentinel 字串（例如 `"__all__"`）：使用者可能真的建立一個叫「全部」的類別，sentinel 會撞名；用獨立參數避免此風險。
- 既有 call site 不傳 `clearOption`，picker 行為與外觀零變動。

不選擇：
- 「在 `OrdersView` 內把 `["全部"] + availableCategories` 作為 options 傳給既有 picker」：sentinel string 有撞名風險，且 picker 對 `selected: ""` 的處理會在每個 option row 都顯示「未選中」狀態，沒有專門 row 給 clear 使用，使用者不容易意識到第一列是「清除」。
- 「extend `OptionPickerSheet` 改成 `selected: String?`」：是 breaking change，會迫使既有 call site 全部跟著動，回歸風險高。

### `OptionPickerSheet` 內 `clearOption` row 的渲染與 checkmark 規則

- iOS / iPadOS（`listContent`）：在選項 Section 之上額外渲染一列「全部」row。Row 使用 `Button { clearOption.onClear(); dismiss() } label: { HStack { Text(clearOption.title); Spacer(); if selected.isEmpty { Image(systemName: "checkmark") } } }`。
- macOS（`optionsCard`）：在 `BLCard` 第一列為 clear row，row 結構與既有選項列對齊；下接 `Divider` 再列出 `filteredOptions`。
- Checkmark 規則：當 `selected` 為空字串時，clear row 顯示 checkmark；既有選項列維持 `option == selected` 比對。因為 `availableCategories` 不會包含空字串，既有選項列不會有人錯誤亮起 checkmark。
- 搜尋互動：clear row **不**參與 `filteredOptions` 過濾（永遠顯示在最上方）。當搜尋有結果時，clear row 與符合的選項共存；當搜尋無結果時，clear row 仍顯示，下方顯示既有空狀態 view。
- `allowsAdd` 與 `clearOption` 可同時存在（雖然本次 filter 場景傳 `allowsAdd: false`）；同時存在時排列順序為：新增按鈕 Section（如有） → clear row → 選項列。
- **Row 多行支援**：clear row 與既有選項列的 `Text` 一律套 `.multilineTextAlignment(.leading) + .fixedSize(horizontal: false, vertical: true)`，HStack 用 `alignment: .firstTextBaseline`。長類別名稱（例如 `aespa Lemonade QQ 音樂限定禮包`）會自然換行、row 高度隨內容增長、checkmark 與第一行 baseline 對齊。既有訂單編輯流程的 picker call site 同樣受益、無回歸（短字串渲染與舊版一致）。

### Trigger button 的 label format 與視覺

- Trigger button 為單顆 Capsule，**填滿可用水平寬度**——左右邊緣對齊上方搜尋欄、與其他篩選列同 inset。實作上，Button label 的 `HStack` 內 `Text` 套 `.frame(maxWidth: .infinity, alignment: .leading)` 吃掉中間水平空間，把 `chevron.down` 推到 capsule 內部右側 padding 邊。
- 結構：`HStack(alignment: .firstTextBaseline, spacing: 4) { tagIcon; Text("類別：\(currentLabel)").multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading); chevronDown }`，外層 `.padding(.vertical, *).padding(.horizontal, *)` + `Capsule().fill(...)`。三平台沿用各自既有 chip 的 padding 與 font 數值（iPhone `.subheadline`/`.caption` + 7/14、iPad `.footnote`/`.caption2` + 7/12、macOS `.footnote`/`.caption2` + 6/12）。
- `currentLabel`：`selectedCategory ?? "全部"`。
- **長類別名稱支援多行**：Text 用 `.multilineTextAlignment(.leading) + .fixedSize(horizontal: false, vertical: true)`，使類別名超過 capsule 單行寬度時自然換行；capsule 高度隨內容增長，**不**使用 `.lineLimit(1) + .truncationMode(.tail)` 截斷。HStack 用 `alignment: .firstTextBaseline` 讓 tag icon 與 chevron 對齊第一行 baseline，避免 icon 在多行文字中被擠到垂直中央。
- Capsule fill：已選類別時 purple 0.18 opacity、未選時 fillTertiary——維持「目前是否有套用類別篩選」的視覺反饋。
- Trigger 按鈕透過獨立 `@State var showsCategoryPicker = false` 控制 sheet 呈現，view 上加 `.sheet(isPresented: $showsCategoryPicker) { OptionPickerSheet(...) }`。

### 三平台共用 trigger helper 結構，但各自落在所屬 view 檔

不抽出 `Shared/DesignSystem/Components/` 內的新元件，原因與初版方案相同：
- Trigger helper 強耦合 `OrdersFeature` 的 store 與 `availableCategories` / `selectedCategory`，抽出去需要把 store 型別作為泛型參數，得不償失。
- 三平台 view 各自留 `categoryFilterTrigger(palette:)` helper 與 `@State var showsCategoryPicker`，內容互為對應（僅 padding / spacing 細節沿用各自既有的數值）。
- `OptionPickerSheet` 本身就是可重用元件，trigger 邏輯只是「組裝參數 + 控制 sheet 顯示」的薄層。

### macOS sheet 尺寸：沿用 `OptionPickerSheet` 既有 `400×480`，不對齊 `PaymentMethodEditorSheet` 的 `420×320`

雖然「sheet 樣式參考新增付款方式」是視覺方向的指引，但兩者尺寸需求不同：
- `PaymentMethodEditorSheet` 是固定欄位 form（name + Toggle + footer），內容高度可預測且小，`320` 高度足夠。
- `OptionPickerSheet` 是可搜尋列表，內容包含搜尋欄、變高列表、空狀態；既有 `400×480` 是為列表場景設計過的尺寸，已在訂單編輯流程驗證過合適。
- 沿用既有 picker 尺寸避免額外針對 filter 場景再開特例，也保持與訂單編輯流程選類別時的尺寸一致——使用者在兩個入口看到的 picker 大小相同，認知一致。
- 視覺方向的對齊（NavigationStack + 取消 toolbar + 同樣的 sheet 質感）由 `OptionPickerSheet` 既有 chrome 自動繼承，不需額外調整。

### snapshot baseline 處理策略

- snapshot 測試僅 iOS 393×852 baseline，會涵蓋訂單列表（含類別篩選列）的畫面。
- 本次必須 re-record baseline，並把新的 PNG 一併進 git。re-record 流程依 README 既有指引（`record: true` → 跑測試 → 改回 `record: false` → commit 新 baseline）。
- baseline 涵蓋兩種情境的訂單列表：類別非空且未選（trigger label「類別：全部」、capsule fill fillTertiary）、類別非空且已選（trigger label「類別：<x>」、capsule fill purple）。類別為空時 trigger 不呈現，原 baseline 行為不變、無需重錄該情境。
- snapshot 只涵蓋訂單列表（trigger button 的呈現），不涵蓋 sheet 內部畫面——sheet picker 已由 `OptionPickerSheet` 自己的 preview 與既有訂單編輯流程的 snapshot（如有）涵蓋。

## Implementation Contract

**Observable behavior（trigger button 與 sheet picker）**

- 當 `OrdersFeature.State.availableCategories` 為空時，類別篩選 UI **不**呈現（與現況一致）。
- 當 `availableCategories` 非空時，類別篩選位置出現一顆 Capsule 形狀的 trigger button，**填滿可用水平寬度**（左右邊緣對齊上方搜尋欄）：
  - 左側為 tag icon。
  - 中段顯示 `類別：<current>`，其中 `<current>` 在 `selectedCategory == nil` 時為「全部」、否則為 `selectedCategory!`。Text 套 `.frame(maxWidth: .infinity, alignment: .leading)` 以吃滿可用水平空間。
  - 右側為 `chevron.down`，被推到 capsule 內部右邊 padding。
  - Capsule fill 在 `selectedCategory != nil` 時為 purple 0.18 opacity，否則為 fillTertiary。
  - 類別名稱過長時 Text **自然換行**（多行支援，capsule 高度隨內容增長）；HStack 用 `alignment: .firstTextBaseline`，tag icon 與 chevron 對齊第一行 baseline。
- 點按 trigger 後 present `OptionPickerSheet`，參數為：
  - `title: "選擇商品類別"`
  - `allowsAdd: false`
  - `searchable: true`
  - `options: store.availableCategories`
  - `selected: store.selectedCategory ?? ""`
  - `clearOption: .init(title: "全部", onClear: { store.send(.categoryFilterSelected(nil)) })`
  - `onSelect: { store.send(.categoryFilterSelected($0)) }`
- Sheet 內顯示順序：
  - 最上方一列「全部」row（由新的 `clearOption` 行為產生）。
  - 其下依 `availableCategories` 順序列出每個類別。
- Sheet 內 checkmark 規則：
  - `selectedCategory == nil` 時，「全部」row 顯示 checkmark、其他列無 checkmark。
  - `selectedCategory == X` 時，類別 `X` 該列顯示 checkmark、其他列（含「全部」）無 checkmark。
- 點選任一列後，對應的 callback 被觸發、sheet 自動 dismiss、trigger button label 立即同步。
- 從 analytics 類別排行 deep-link 進來時：
  - Trigger button label 顯示「類別：<deep-linked category>」、capsule fill 為 purple。
  - 開啟 sheet 後該類別項目顯示 checkmark。
- 篩選合取行為（status × date × search × category）與既有 `filteredOrders(referenceDate:)` 結果完全相同。
- `selectedCategory` 的儲存、`selectedOrderID` 在類別變動後重算到首筆訂單等行為皆原樣。

**Observable behavior（`OptionPickerSheet` 既有 call site 回歸）**

- 訂單編輯流程選類別 / 付款方式 / 幣別三個既有 call site 不傳 `clearOption`，sheet 內畫面與行為與本次改動前完全相同——不顯示任何「全部」row、不影響搜尋過濾、不影響既有 `onAdd` / `onAddPaymentMethod` 流程。

**Interfaces**

- `OrdersFeature.Action.categoryFilterSelected(String?)`（未變動）
- `OrdersFeature.State.selectedCategory: String?`（未變動）
- `OrdersFeature.State.availableCategories: [String]`（未變動，computed）
- `OptionPickerSheet` 新增 `clearOption: ClearOption?` 參數（預設 `nil`，向後相容）
- `OptionPickerSheet.ClearOption`：nested type，欄位 `let title: String` 與 `let onClear: () -> Void`

**Failure / edge cases**

- 若 `availableCategories` 在執行期變空（使用者刪除最後一個類別 master 且訂單也無人填過），trigger button 隱藏；reducer 既有的「清除無效 `selectedCategory`」邏輯不變。
- 若 `selectedCategory` 指向已不存在於 `availableCategories` 的字串，reducer 行為仍會在資料載入後校正；UI 端不對此做額外處理。
- 搜尋輸入清空 sheet 內列表時：clear row 仍顯示，下方顯示既有 `ContentUnavailableView` 空狀態（與 picker 既有行為一致）。
- 使用者建立的類別字串為空字串：`availableCategories` 來源（`categoryMaster` / orders 中的 category）已會在 reducer 端 trim / 過濾，UI 端不需特別處理；即使萬一傳入空字串，picker 的 `option == selected` 比對會把它與 `selected: ""` 同步，但因為 trigger label「類別：」後面緊接空白，視覺異常足以讓使用者察覺，屬可接受的退化。

**Acceptance criteria**

1. 三平台訂單頁在類別非空情境下呈現一顆 trigger Capsule button，label 與 `selectedCategory` 同步。
2. 點 trigger 後出現 `OptionPickerSheet`，sheet 最上方為「全部」row、其後依 `availableCategories` 順序列出類別。
3. 點選「全部」row 觸發 `categoryFilterSelected(nil)`、sheet dismiss、trigger label 變回「類別：全部」、capsule fill 變回 fillTertiary。
4. 點選任一類別 row 觸發 `categoryFilterSelected(<category>)`、sheet dismiss、trigger label 變為「類別：<category>」、capsule fill 變為 purple。
5. Sheet 內 checkmark 規則完全符合 `Observable behavior` 描述（同時只有一列顯示 checkmark）。
6. 在 sheet 內搜尋類別字串可即時過濾選項列；搜尋無結果時「全部」row 仍顯示、下方為空狀態。
7. `OptionPickerSheet` 既有 call site（訂單編輯選類別 / 付款方式 / 幣別）回歸測試與手動驗證：sheet 行為與外觀零變動。
8. analytics deep-link「點 beauty 類別」後切到訂單頁，trigger label 顯示「類別：beauty」、開啟 sheet 後 beauty 項目顯示 checkmark。
9. 移除類別 master 的全部項目後重新進入訂單頁，trigger button 不呈現（與原行為一致）。
10. iOS snapshot baseline 重錄並通過（`record: false` 後跑 SnapshotTests iOS slice 全綠）。
11. iOS / iPadOS / macOS build 皆綠。

**In scope**

- `OptionPickerSheet.swift`：新增 `ClearOption` nested type 與 `clearOption` 參數，並在 iOS `listContent` 與 macOS `optionsCard` 內渲染 clear row 與 checkmark 規則。
- 三個訂單頁 view 檔的 trigger button helper 與 `.sheet` 連接 `OptionPickerSheet`。
- iOS snapshot baseline 的 re-record。

**Out of scope**

- 任何 `OrdersFeature` reducer / state / action 的改動。
- 狀態篩選、日期篩選、搜尋欄、payment method / order source 的 UI 改動。
- 新增獨立的 `CategoryFilterPickerSheet` 或將 `OptionPickerSheet` 拆分為兩個元件。
- SwiftData schema / migration / repository 改動。
- macOS / iPad 上的 keyboard shortcut 或 menu bar 整合。
- sheet 內部畫面的 snapshot baseline（已由 `OptionPickerSheet` 自己的 preview / 訂單編輯流程涵蓋）。

## Risks / Trade-offs

- [trigger button 比膠囊列多一個 tap 才能切換類別] → 換來「不受類別數量限制 + 可搜尋」的可擴展性，在已知會成長的場景中為正向交易；對少量類別使用者多一個 tap 是已接受成本。
- [`OptionPickerSheet` 既有 call site 因新增參數而被誤改] → 採用 optional 預設 `nil` 的擴充，既有 call site 不需動；CI build 與既有訂單編輯流程的回歸測試（手動 + snapshot 如有）會把回歸風險降到最低。
- [使用者真的建立一個叫「全部」的類別] → 因為「全部」用獨立 `clearOption` 參數而非 sentinel string，類別列表中可能會同時出現一列 clear「全部」row 與一列實際類別「全部」option。視覺上略混淆但行為正確（clear row 觸發 nil、option row 觸發「全部」）；屬可接受的低機率退化，使用者改名即解。
- [snapshot baseline 一定要重錄] → 已在 acceptance criteria 與 tasks 中列出；依 README record 流程處理。
- [類別名極長 trigger capsule 怎麼呈現] → 改採多行換行（`.multilineTextAlignment(.leading) + .fixedSize(horizontal: false, vertical: true)` + HStack `.firstTextBaseline`）：capsule 高度隨內容增長、tag icon 與 chevron 對齊第一行 baseline，使用者能看見完整類別名而非 ellipsis 截斷。代價是 capsule 在極長名稱下會顯著變高、佔篩選列垂直空間。視覺驗證已在實機 iPhone 15 Plus 確認。
- [Sheet picker 的記憶體與初始化成本高於 Menu] → 在訂單編輯流程已驗證可接受；本次只是多一個 sheet 入口，成本相當。
