## Context

訂單詳情由 `OrderDetailView` (綁 `OrderDetailFeature` 的 store) 組出 `OrderDetailContentView`，再由六個區段 View 呈現：`OrderDetailSourceView`、`OrderDetailSummaryView`、`OrderDetailCardlessView`、`OrderDetailCostView`、`OrderDetailItemsView`、`OrderDetailNotesView`。`OrderDetailView.OrderDetailLayout` 有 `.compact` 與 `.wide` 兩個 case，`OrderDetailContentView` 與摘要、成本、商品、備註四個區段各自 `switch layout`。2026-10-21 查證的呼叫端：

| 呼叫端 | 傳入版面 |
|---|---|
| `OrderCompactDetailView` (iPhone 推入詳情) | 預設 `.compact` |
| `OrdersRegularDetailColumn.detail(order:store:)` (iPad 詳情欄) | `.wide` |
| `OrderDetailView` 的 `#Preview("訂單詳情 · 寬欄")` | `.wide` |
| `SnapshotTests+OrderDetail` 的 `orderDetailView_成本明細內容_符合基準圖` | 預設 `.compact` |

兩種排版的差異 (讀程式碼所得)：

| 區段 | 窄欄 (保留) | 寬欄 (刪除) |
|---|---|---|
| 財務摘要 | 一張卡：獲利與毛利率在上，總收款、總成本、手續費在下 | 三張並排的指標卡 (總收款、總成本、獲利帶毛利率)，標籤前有裝飾色點，不顯示手續費 |
| 成本拆解 | 區段標題＋卡片內圈狀圖與圖例列 | 卡片內大寫標題、每項一條成本拆解條、底部總成本列 |
| 成本與商品 | 上下排列 | 並排，輔助字級改上下 |
| 商品明細、備註 | 區段標題在卡片外 | 大寫標題在卡片內 |

兩種排版的 accessibility identifier 相同 (`Orders.detailRoot`、`Orders.detailSummaryTile(.revenue／.cost／.profit)`)，`OrderDetailTests.testDetailSummaryTilesHaveValues` 在 iPhone 與 iPad 都讀這三個值。規格目前沒有描述寬版的內容排列 (`adaptive-layout` 只規定清單與詳情並排、詳情欄導覽列承載客戶名稱與選單)。

## Goals / Non-Goals

**Goals:**

- iPad 詳情欄與 iPhone 推入詳情使用同一份內容排版，程式碼中不再有依版面分支的詳情內容。
- 兩處使用同一個詳情畫面型別 `OrderDetailView`，導覽列標題與工具列只宣告一次。
- iPhone 推入詳情的畫面不變：截圖可見區域由兩張既有截圖不重錄即通過守住，畫面外的區段以逐段程式碼對照確認。
- 刪除寬版專用的私有 View、函式與 `@ScaledMetric`，不留零呼叫點的成員；含只被成本拆解條讀取的 `OrderCostBreakdown.Component.fraction`。

**Non-Goals:**

- 不設計新的「依可用寬度調整」詳情排版：屬於 roadmap 第 5 至 7 項 (iPad／iPhone Duo 各頁版面)，那時再依實測決定詳情在寬欄要不要調整。
- 不調整 `OrderDetailContentView` 的可讀寬度上限 (`readableWidth`)、內距與區段順序。
- 不改 `OrderDetailFeature`、identifier 與本地化字串；不新增 UI 測試 (iPad 畫面實測改用 Xcode MCP，見「iPad 畫面實測改用 Xcode MCP」)。

## Decisions

### 保留現行窄欄排版作為唯一排版

唯一排版直接採用 iPhone 推入詳情現在的排版，不另外設計。理由：使用者的決定是「改成與 iPhone 相同」；窄欄排版已經處理輔助字級 (摘要的兩組數值改上下排列) 並由 iPhone 的截圖與 UI 測試守住；寬欄少了手續費，改用窄欄後 iPad 也會顯示。

替代方案：保留寬欄、刪除窄欄。否決，因為寬欄沒有手續費、成本與商品並排在 iPhone 寬度放不下，等於要重新設計。

### 先讓詳情欄改用共用排版，再移除寬版分支

分兩步：先把 `OrdersRegularDetailColumn` 改成 `OrderDetailView(store:)`，刪除寬版詳情欄截圖測試，並在 iPad 模擬器實測截圖確認排列 (使用者看到的變化全在這一步)；再刪除 `OrderDetailLayout` 與所有寬版分支 (純刪除，畫面不應再變)。每一步結束都能建置、測試全綠。第二步完成後兩張 iPhone 詳情截圖都不重錄即通過；iPad 詳情欄此時用的是同一份程式碼，因此同樣證明刪除沒有改到截圖涵蓋的區域。兩張截圖固定 393×852，只拍到成本圖例與商品卡片上半，商品列下半、備註與無卡明細在畫面外，這些區段以 iPad 實測捲動確認與逐段程式碼對照。

替代方案：一次改完。否決，因為無法區分「改用窄欄造成的畫面變化」與「刪除時誤改的畫面變化」。

### 刪除寬版專用成員並改名私有成員

刪除只服務寬版的私有成員，包含只被它們使用的屬性：

| 檔案 | 刪除 | 改名 |
|---|---|---|
| `OrderDetailView` | `layout` 屬性、`OrderDetailLayout` 列舉與其 Nested Types 區段 | 兩個 `#Preview` 改名為不分版面的名稱，第二個的 `.frame` 由 720×720 改為 704×768 (iPad 詳情欄寬度) |
| `OrderDetailContentView` | `layout` 參數、`dynamicTypeSize` 環境值 (只有寬版使用)、`wideBreakdownAndItems`、`wideDetailCards` | 無 |
| `OrderDetailSummaryView` | `layout`、`kpiThreeUp`、`kpiTiles`、`kpiTile(label:value:delta:deltaTint:tint:)`、`indicatorSize`、`labelSpacing` | 無 (`profitCard` 已是不分版面的名稱) |
| `OrderDetailCostView` | `layout`、`breakdownBarsCard`、`breakdownBarRow(_:)`、`rowSpacing` | `compactCostBreakdown` → `costBreakdown` |
| `OrderDetailItemsView` | `layout`、`wideItemsCard` | `compactItemList` → `itemList` |
| `OrderDetailNotesView` | `layout`、`wideNotesCard` | `compactNotes` → `notesSection` |
| `OrderCostBreakdown` | `Component.fraction`；手寫的 `Component.init(title:value:tone:total:)` 與其 doc comment (含只供算占比的 `totalValue`／`amount`)，刪除後改用合成的 memberwise `init(title:value:tone:)`；`components(for:)` 的 `total` 區域常數與七處 `total:` 引數 | `Component` 型別 doc 由「標題、金額、占比與語意色調」改為「標題、金額與語意色調」；`components(for:)` doc 拿掉「附上占總成本的比例」；`DonutSlice.value` 的「供圈狀圖計算占比」仍然成立，保留 |
| `OrderCostBreakdownTests` | `components_總成本為正_計算各項占比`、`components_總成本非正_占比夾限為一` 兩條占比測試；`makeDonutComponents()` 兩處建構的 `total:` 引數 | 無 |

保留 `OrderDetailCostView` 的 `indicatorRadius`、`indicatorSize` (圖例列使用)。各檔 doc comment 拿掉「窄欄／寬欄」的說法；各檔 body 只回傳單一私有 View，比照 `OrderDetailContentView.body` 的寫法。依 2026-10-09「改到即整檔對齊」裁決，本 change 改到的檔都要整檔符合 `/ios-dev-kit`：production 九個 (`OrderDetailView`、`OrderDetailContentView`、`OrderDetailSummaryView`、`OrderDetailCostView`、`OrderDetailItemsView`、`OrderDetailNotesView`、`OrdersRegularDetailColumn`、`OrdersCompactView`、`OrderCostBreakdown`)，測試三個 (`SnapshotTests+OrdersBaseline`、`ActionGroupingScanTests`、`OrderCostBreakdownTests`，依測試規範檢查)；刪除的 `OrderCompactDetailView.swift` 只驗證刪除與引用清除。

替代方案：保留 `layout` 參數但只剩一個 case。否決，留下沒有意義的參數就是使用者要避免的兩套維護入口。

### 刪除寬版詳情欄截圖測試

**Supersedes**: order-detail-single-layout / 寬版詳情欄截圖保留並重錄

刪除 `ordersRegularDetailColumn_寬版詳情欄選取含成本明細訂單_符合基準圖` 測試方法與其基準圖，不重錄 (使用者 2026-10-21 裁決)。理由：

- 改完後 iPad 詳情欄與 iPhone 推入詳情用同一份內容程式碼，差別只剩寬度；這份排版是直向堆疊、每區撐滿寬度，破版風險在窄寬度，393 pt 的 `ordersCompactView_推入含成本明細訂單_符合基準圖` 與 `orderDetailView_成本明細內容_符合基準圖` 已守住，704 pt 只多出數值拉開等觀感差異。
- 詳情欄自身的行為已有 UI 測試：導覽列標題與選單、無選取空狀態由 `OrderRegularColumnScopeTests` 守，iPad 上的摘要數值由 `OrderDetailTests.testDetailSummaryTilesHaveValues` 守。
- 留著它等於同一份內容有三張截圖，之後每次調整詳情內容都要三張一起重錄。
- 兩張 iPhone 截圖只涵蓋 393×852 的可見區域 (到成本圖例與商品卡片上半)；畫面外的商品列下半、備註與無卡明細不由截圖守，改以 iPad 實測捲動確認與程式碼對照，不把它們算成已由截圖驗過。
- roadmap 第 5 至 7 項重新設計依寬度調整的版面時，會針對新設計建立寬欄截圖。

刪除後 `SnapshotTests+OrdersBaseline.swift` 的 `makeOrdersBaselineOrder()` 仍由 `ordersCompactView_推入含成本明細訂單_符合基準圖` 使用，四個 import 也仍被其他測試使用 (2026-10-21 讀檔確認)，不連帶刪除。`.claude/rules/ios-unit-tests.md` 的「訂單三欄分欄拍」條目改為只拍清單欄，並寫明詳情欄不拍的原因。

被否決的方案：保留並重錄，守住共用排版在 iPad 詳情欄寬度的呈現 (本 change 原先的決定)。否決理由同上：它能多守住的只有寬欄的觀感，維護成本是每次調整詳情內容多重錄一張。

### iPad 畫面實測改用 Xcode MCP

**Supersedes**: order-detail-single-layout / 橫向以量完即刪的暫時 UI 測試確認

1.1 的直向與橫向、3.1 的最大輔助字級 iPad 畫面實測，都改用 Xcode 27.1 內建 MCP 的 device interaction (使用者 2026-10-21 選擇)，不寫暫時 UI 測試：

1. 依 `apps/ios/CLAUDE.md` 遞增 build number 後，以 `mobilebuildmcp simulator build-and-run --simulator-id 7F154D8D-8E3B-42F6-8150-36185A7B6B54` 安裝並啟動到 iPad Air 11-inch (M4) iOS 27.0，啟動參數以 `--json` 帶 `-BLUITest`、`-BLUITestSeed fullOrders` (3.1 另帶 `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL`)。建置一律走 `mobilebuildmcp`，不讓 Xcode 建置。
2. 以 `DeviceInteractionStartSession` (不綁 workspace) 開連線，交給載入 `device-interaction` skill 的子代理以 `DeviceInteractionSynthesize` 操作：帶 `activationBundleId` = `com.leoho.BuyLedger`，依結構檔座標點選 `BL-2604-018`，在直向擷取、捲到商品明細與備註各擷取，再送 `orientation landscapeLeft` 重複同樣擷取，最後送 `orientation portrait` 轉回。
3. 每張截圖記錄結構檔的 `Application UI orientation` 與第一個 Window frame，主對話自己打開截圖判讀，再 `DeviceInteractionEndSession` 關閉連線。

理由：

- 2026-10-21 實測 (iPad Air 11-inch iOS 27.0，系統「設定」App)：`orientation landscapeLeft` 讓 `Application UI orientation` 由 Portrait 變為 Landscape Right、Window 由 820×1180 變為 1180×820，回傳的截圖是完整的橫向畫面；`orientation portrait` 能轉回。
- 一份截圖就同時看到排列與方向，不必協調測試停留與同步截圖，也不必匯出附件 (`mobilebuildmcp` 沒有轉向與附件匯出指令，`apps/ios/CLAUDE.md` 的原生命令例外只允許 `xcresulttool` 讀摘要)。
- 使用者的 iPad 實機是 iPadOS 27，在 iOS 27 模擬器看畫面更接近實際使用。

代價與前提：

- Xcode 27.1 MCP 只接受 iOS 27 以上的模擬器，iOS 26.5 不在可選清單；畫面實測在 iOS 27.0，UI 測試仍在 iOS 26.5 (`apps/ios/CLAUDE.md` 規定 UI 測試只覆蓋 26.x)。詳情內容是一般 SwiftUI 直向堆疊，系統版本差異影響應小；兩邊不一致時以實測現象回報使用者。
- Xcode 要在執行中且已授權 (2026-10-21 已以 scratchpad 的空白專案完成授權，不開 BuyLedger 專案，避免 Xcode 刪除 `Package.resolved`)。
- 互動必須交給子代理；連線剛開可能回報 cannot be connected，關掉 session 重開即可；同名 session 短時間內不能重用；用完一定要 `DeviceInteractionEndSession`。
- Device Hub 開著不影響 Xcode MCP 轉向 (實測時開著)；但 XCUITest 的轉向測試仍要關閉 Device Hub (`ios-ui-tests.md`)，兩者不同時進行。

2.1 把「需要實測橫向畫面時以 Xcode MCP 轉向」連同上述前提寫進 `.claude/rules/ios-ui-tests.md` 的轉向測試段。

替代方案：

- 量完即刪的暫時 UI 測試 (本 change 第二輪後的做法)：附件取不出、橫向附件只拍到左半，改用元素 frame 斷言加同步截圖又要協調停留時機。
- 用 Device Hub 的 Orientation 選單轉向：違反 `ios-ui-tests.md` 的轉向規則。
- 以 `xcresulttool export attachments` 取出附件：超出 `apps/ios/CLAUDE.md` 允許的原生命令例外。

### 一併刪除成本項目的占比 fraction

`OrderCostBreakdown.Component.fraction` 在 production 只有寬版的 `breakdownBarRow(_:)` 讀取 (2026-10-21 全 repo grep：其餘只有 `OrderCostBreakdownTests` 的兩條斷言)，`Component.init` 的 `total` 參數也只用來算它；圈狀圖的 `donutSlices(for:locale:)` 以金額 (`value`) 計算，不讀 `fraction`。1.2 刪除成本拆解條後一併刪除 `fraction`、`total` 參數、`components(for:)` 的 `total` 區域常數與兩條占比測試，並改寫 `components(for:)` 的 doc comment (使用者 2026-10-21 選擇)。不刪的話，`fraction` 的註解「供進度條使用」會違反 `code-comment-currency` 規格 (移除了註解所說明的東西時，即使在其他未修改的檔案也要改寫或移除註解)。規格沒有任何條文要求成本占比 (2026-10-21 搜尋 `openspec/specs` 確認)。

替代方案：保留 `fraction`，只改寫註解。否決，留下零呼叫點的成員違反本 change 的目標。

### adaptive-layout 補上 Purpose 例外並修改 progress-indicator 範例

主對話依審查結果決定 (使用者未逐條看過)：`openspec/specs/adaptive-layout/spec.md` 的 Purpose 寫明「各版面內的畫面內容不在本規格範圍」，與本 change 新增的訂單詳情排列需求衝突；而既有的「The regular layout is used only when both size classes are regular」需求本來就規定了首頁 (KPI 與 hero 卡) 與分析頁 (類別排行與成本結構卡) 的排列。2.1 在 Purpose 補一句「例外：本規格也規定少數畫面在兩種版面的排列 (首頁 KPI 與 hero 卡、分析頁卡片、訂單詳情內容)」，其餘範圍與排除的相鄰規格不變。Purpose 不在 delta 內，直接修改主規格檔。`progress-indicator` 的「Bar-only progress keeps a single bar」情境把「order detail cost bar」列為範例，且 Example 表指向 `orderDetailView_成本明細內容_符合基準圖` (這張截圖本來就是圈狀圖、沒有成本條)；以 MODIFIED delta 移除這個範例與表格列。

替代方案：把新需求放到另一個規格。否決，沒有專門描述訂單詳情內容的規格，新開規格只為這一條需求不划算。

### 驗收以截圖、既有 UI 測試與 iPad 實測三者分工

| 規格情境 | 守門 |
|---|---|
| The regular detail column shows the pushed detail arrangement | Xcode MCP 在 iPad (iOS 27.0) 直向與橫向各截圖並捲到商品明細與備註 (逐張判讀：摘要卡含手續費、圈狀圖與圖例、商品明細標題在卡片外、備註標題在卡片外、沒有三張指標卡與成本拆解條；結構檔的 `Application UI orientation` 分別為 Portrait 與 Landscape)；可見區域的像素由兩張 iPhone 詳情截圖守 (同一份程式碼) |
| The same order reports the same summary values in both layouts | `OrderDetailTests.testDetailSummaryTilesHaveValues` 在 iPhone 17 與 iPad Air 11-inch 都通過 (同一組預期值) |
| The regular detail column stacks the summary at an accessibility text size | Xcode MCP 在 iPad (iOS 27.0) 以最大輔助字級啟動後截圖 |

不新增 UI 測試：排列是視覺結構，iPad 寬度以 Xcode MCP 實測確認一次，可見區域的像素由 iPhone 截圖守；數值由既有 UI 測試守；roadmap 第 2 項正要精簡 UI 測試，不在這裡新增只為一次性確認的測試。

### 標題與工具列收進 OrderDetailView 並刪除 OrderCompactDetailView

`OrderCompactDetailView` 與 `OrdersRegularDetailColumn.detail(order:store:)` 做的事完全相同：`OrderDetailView(store:)` 加客戶名稱 inline 標題 (`navigationTitle(Text(verbatim: order.customer.name))`、`.navigationBarTitleDisplayMode(.inline)`) 與 `.toolbar { OrderDetailToolbarContent(store:) }`。改由 `OrderDetailView` 在 `store.order` 有值的分支內自己宣告這三項，刪除 `OrderCompactDetailView`：

- `OrdersCompactView` 的 `.detail` 推入目的地改為 `OrderDetailView(store: detailStore)`，外掛的 `.alert(alertBinding(isDetail: true))` 不變。
- `OrdersRegularDetailColumn` 刪除私有 `detail(order:store:)`，body 只保留「regular 詳情 store 存在且有訂單時顯示 `OrderDetailView(store:)`，否則顯示 `emptyState`」。
- `ActionGroupingScanTests.migratedViewPaths` 移除 `Features/Orders/Components/OrderCompactDetailView.swift`：掃描以 `String(contentsOf:)` 讀清單中每個檔 (2026-10-21 讀 `ActionGroupingScanTests+Scanner.swift` 確認)，留著會讀檔失敗。
- `OrderDetailView` 的 doc comment 改為說明它是推入與詳情欄共用的詳情畫面 (含導覽列標題與工具列)；`body` 比照其他詳情檔只回傳私有 `content`，由 `content` 承載 `if let order = store.order`、`OrderDetailContentView` 與三個導覽修飾；兩個 `#Preview` 都包 `NavigationStack` 才看得到標題。

理由：SwiftUI 的慣例是目的地畫面自己宣告標題與工具列，`OrderDetailView` 本來就是推入目的地與詳情欄的內容；少一個型別，導覽列設定只有一份，符合這次「只有一版」的目標 (使用者 2026-10-21 選擇)。

替代方案：

- 維持兩處各自宣告：只有三行重複，但之後只改一處時另一處會靜默分歧，沒有測試會發現。
- 合併成一個包裝並改名：仍有包裝與內容兩個型別，且新名稱容易與 `OrderDetailView`、`OrderDetailContentView`、UI 測試的 `OrderDetailScreen` 混淆。

## Implementation Contract

**行為**：iPad 全螢幕 (regular 版面) 在訂單分頁選取一筆訂單後，詳情欄的內容排列與 iPhone 推入詳情相同：訂單標頭、來源、一張財務摘要卡 (獲利與毛利率、總收款、總成本、手續費)、有無卡調整時的無卡明細、總成本大於零時的成本拆解 (圈狀圖與圖例)、商品明細 (區段標題在卡片外)、有備註時的備註。詳情欄導覽列的客戶名稱標題、兩個選單與無選取空狀態不變。iPhone 推入詳情不變。

**介面**：`OrderCostBreakdown.Component` 不再有 `fraction` 與手寫 `init`，建構改用合成的 memberwise `init(title:value:tone:)`；`OrderDetailView` 只剩 `init(store:)` (合成的 memberwise init)，有訂單時自己宣告客戶名稱 inline 標題與 `OrderDetailToolbarContent`；`OrderCompactDetailView` 與 `OrderDetailView.OrderDetailLayout` 不存在；`OrderDetailContentView`、`OrderDetailSummaryView`、`OrderDetailCostView`、`OrderDetailItemsView`、`OrderDetailNotesView` 的建構參數不含 `layout`。`OrderDetailFeature`、`BLAccessibilityID` 與本地化 key 不變。

**失敗模式**：沒有新的錯誤路徑。`OrderDetailView` 在 `store.order` 為 `nil` 時不顯示內容的行為不變。

**驗收條件**：

- `grep -rn -E 'OrderDetailLayout|layout: \.(wide|compact)|kpiThreeUp|kpiTiles|func kpiTile\(|breakdownBar|wideItemsCard|wideNotesCard|wideBreakdownAndItems|wideDetailCards|compactCostBreakdown|compactItemList|compactNotes' apps/ios/BuyLedger apps/ios/BuyLedgerTests` 無結果 (2026-10-21 實測改動前只命中七個詳情相關檔；首頁的 `BLAccessibilityIDTests.kpiTileIdentifierUsesKPIKeyRawValue` 不會被 `func kpiTile\(` 比對到，`BLAccessibilityID+Dashboard.swift` 的 `static func kpiTile(_:)` 則是因為 `apps/ios/BuyLedgerAccessibilityIDs` 不在比對範圍)。
- `ordersCompactView_推入含成本明細訂單_符合基準圖` 與 `orderDetailView_成本明細內容_符合基準圖` 從頭到尾不重錄即通過；`ordersRegularDetailColumn_寬版詳情欄選取含成本明細訂單_符合基準圖` 測試方法與基準圖已刪除 (`grep -rn ordersRegularDetailColumn_ apps/ios` 無結果，且 `test ! -e 'apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/ordersRegularDetailColumn_寬版詳情欄選取含成本明細訂單_符合基準圖.1.png'` 成立；grep 只比對檔案內容，驗不到 png 是否刪除)。
- 寬版殘留與占比清除：`grep -n -E 'labelSpacing|rowSpacing|窄欄|寬欄' apps/ios/BuyLedger/Features/Orders/Components/OrderDetail*.swift` 無結果；`grep -c indicatorSize apps/ios/BuyLedger/Features/Orders/Components/OrderDetailSummaryView.swift` 與 `grep -c dynamicTypeSize apps/ios/BuyLedger/Features/Orders/Components/OrderDetailContentView.swift` 皆為 0；`grep -rn -E '\.fraction\b|fraction:' apps/ios/BuyLedger apps/ios/BuyLedgerTests` 無結果 (UI 測試的 `ValueParsing` 有同名參數，不在比對範圍)。這些 private 成員沒用到時編譯器不警告，只能靠 grep；`grep -n '占比' apps/ios/BuyLedger/Features/Orders/OrderCostBreakdown.swift` 只剩 `DonutSlice.value` 的一行 (`fraction` 的 grep 抓不到中文「占比」)。
- `grep -rn OrderCompactDetailView apps/ios` 無結果；iPhone 推入詳情與 iPad 詳情欄的導覽列標題、兩個選單照舊 (`OrderRegularColumnScopeTests`、`OrderDetailMenuTests` 綠)。
- 完整單元測試全綠；iPhone 17 (iOS 26.5，`1FB73457`) 與 iPad Air 11-inch (M4) (iOS 26.5，`E30658D5`) 的受影響 UI 類別全綠且執行數大於 0。
- 三個規格情境依上表各有守門紀錄。
- 「刪除寬版專用成員並改名私有成員」列出的九個 production 檔與三個測試檔通過專責 style agent 依 `/ios-dev-kit` 的逐檔逐條審查。

**範圍內**：六個詳情元件檔與 `OrdersRegularDetailColumn.swift`、`OrderCostBreakdown.swift` 與其測試的占比刪除、`OrdersCompactView.swift` 的推入目的地、刪除 `OrderCompactDetailView.swift` 並更新 `ActionGroupingScanTests` 的掃描清單、刪除詳情欄截圖測試方法與基準圖、`.claude/rules/ios-navigation.md` 的詳情條目與 `.claude/rules/ios-unit-tests.md` 的分欄截圖條目、`apps/ios/README.md` 的詳情欄說明、`adaptive-layout` 主規格的 Purpose、`.claude/rules/ios-ui-tests.md` 的 Xcode MCP 橫向實測條目與 `apps/ios/CLAUDE.md` 指向它的一條 (使用者 2026-10-22 決定)、build-and-run 前的 build number 遞增。

**範圍外**：見 Non-Goals；另外不動 `OrderDetailSourceView`、`OrderDetailCardlessView`、`OrderDetailToolbarContent` 與 `OrderDetailMenu`。實作中發現需要改範圍外的檔案時先停下回報。

## Risks / Trade-offs

- [iPad 詳情欄變成單欄長頁，橫向時需要更多捲動] → 使用者已接受以一版換取維護成本；詳情欄在寬欄的調整留給 roadmap 第 5 至 7 項，以可用寬度而非裝置判斷。
- [窄欄排版放在 704 pt 寬的詳情欄，圈狀圖與摘要卡橫向延展可能顯得空] → 第一步以 Xcode MCP 在直向與橫向截圖判讀；明顯失衡時回報使用者，不在本 change 內自行調整排版。
- [刪除詳情欄截圖後，沒有自動化測試守 iPad 詳情欄寬度的呈現] → 使用者接受；內容與 iPhone 同一份程式碼、破版風險在窄寬度，roadmap 第 5 至 7 項重新設計寬度版面時建立對應截圖。
- [刪除時誤改窄欄排版] → 第二步要求兩張 iPhone 詳情截圖不重錄即通過 (守可見區域)，畫面外的區段以逐段程式碼對照確認並記錄。
- [`orderDetailView_成本明細內容_符合基準圖` 直接拍 `OrderDetailView`、沒有包 `NavigationStack`，加上標題與工具列後預期不畫出任何東西，但未實測] → 收進標題與工具列的 task 實跑確認不重錄即通過；轉紅就停下回報，不重錄。
- [Xcode MCP 連不上模擬器 (cannot be connected) 或截圖不是 BuyLedger] → 先確認模擬器已開機、關掉 session 以新名稱重開；`activationBundleId` 帶 `com.leoho.BuyLedger`；仍不行時停下回報使用者，不改用 Device Hub 轉向或匯出附件。
- [畫面實測在 iOS 27.0，UI 測試在 iOS 26.5，兩邊行為可能不同] → 實測只判讀排列；與 26.5 的 UI 測試結果矛盾時回報使用者。
- [寬版的三張指標卡曾是色點 3:1 豁免的使用處之一] → 刪除後色彩規則不受影響 (豁免條件寫在 `ios-design-system.md`，不依附此元件)，`ContrastComplianceTests` 照跑。

## Open Questions

無。外層包裝是否合併已由使用者 2026-10-21 決定 (見「標題與工具列收進 OrderDetailView 並刪除 OrderCompactDetailView」)。
