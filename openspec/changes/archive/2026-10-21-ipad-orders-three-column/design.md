## Context

regular 版面 (iPad 全螢幕) 由 `RootSidebarLayout` 以兩欄 `NavigationSplitView` (sidebar 加 detail) 呈現所有分頁。訂單分頁在 detail 欄放 `OrdersView`，它的 regular 分支 (`regularSplitContent`) 在單一 `NavigationStack` 內以 `HStack` 並排 `OrdersRegularListColumn` (清單) 與 `OrdersRegularDetailColumn` (詳情)，`.searchable(placement: .navigationBarDrawer(displayMode: .always))`、`rootNavigationTitle` 與 `OrdersToolbarContent` 都掛在這條橫跨兩欄的導覽列，所以搜尋欄與「⋯」「+」橫跨兩欄 (使用者截圖見 proposal)。

詳情欄頂部是自繪的 `titleBar` (客戶名稱、`OrderDetailMenu(kind: .status, layout: .wide)`、`OrderDetailMenu(kind: .more, layout: .wide)`，`.bar` 材質)，以 `safeAreaInset(edge: .top)` 疊在 `OrderDetailView(layout: .wide)` 上。iPhone 推入詳情 `OrderCompactDetailView` 已用系統導覽列：`navigationTitle(Text(verbatim: customer.name))`、`.inline`、兩個 `.primaryAction` 的 `OrderDetailMenu(layout: .compact)`。

對話框：`OrdersView.regularAlertBinding(isDetail:)` 在有選取詳情時把容器的 alert 綁定掛詳情欄、否則掛清單欄，另一處給 `.constant(nil)`。編輯、合併、AI 摘要 sheet 掛在 `OrdersView.body` 外層；清單篩選 sheet 與 iPad 類別選擇器、清單 `.task` 掛在 regular 分支外層。

三張截圖比對測試直接以 regular 尺寸分類渲染 `OrdersView` (1024×768)：`SnapshotTests+Orders` 的 `ordersView_寬版多選模式_顯示選取列`、`SnapshotTests+OrdersBaseline` 的 `ordersView_寬版選取含成本明細訂單_符合基準圖`、`SnapshotTests+OrderFilterEmptyStates` 的 `ordersView_寬版無付款方式與類別_符合基準圖`。

官方依據 (Apple docs MCP 與 codex-impl 查證)：
- 「Adding a search interface to your app」：三欄 `NavigationSplitView` 在 iPad 把搜尋欄放在中間欄頂端；要指定欄位就把 `.searchable` 掛在該欄的 view。
- `NavigationSplitView`：`init(sidebar:content:detail:)` 建立三欄；欄寬以 `navigationSplitViewColumnWidth(min:ideal:max:)` 指定；可在欄內嵌 `NavigationStack`；`columnVisibility` 以 `NavigationSplitViewVisibility` 控制。
- `NavigationSplitViewStyle.balanced`：「顯示前面幾欄時縮小詳情內容以讓出空間」(並排)；`.prominentDetail` 保持詳情大小 (前面幾欄覆蓋)；`.automatic` 依情境決定。
- WWDC22「SwiftUI on iPad: Organize your interface」(10058) 提到三欄在直向可能覆蓋詳情。

apply 中實測 (2026-10-20，iPad Air 11-inch (M4)，直向視窗 820×1180pt)：
- 三欄 `NavigationSplitView` 的 content 欄回報 compact 水平尺寸分類，`OrdersView` 依 `blLayoutClass` 在清單欄判成 compact，畫出 iPhone 版清單 (整合篩選鈕、日期分組)。
- 三欄在直向由系統收起側邊欄 (只剩「顯示側邊欄」鈕)，清單欄 320pt、詳情欄約 500pt；加 `.navigationSplitViewStyle(.balanced)` 後相同。
- 側邊欄收起時可及性樹沒有 `Root.sidebar`，UI 測試共用的 `AppNavigator.isSidebarLayout` 因此判斷不出版面。
- iPadOS 26 的內容會延伸到浮動側邊欄底下 (`Orders.listRoot` 左緣為 0)。

使用者 iPad 實機回報後的實測 (2026-10-20，iPad Air 11-inch (M4) 模擬器 iPadOS 26.5 與 27.0，以 `onGeometryChange` 暫時印出欄位 frame，量完即刪)：
- 清單欄搜尋：iPadOS 27 橫向輸入文字後清除，清單欄導覽列空出大標題的高度卻沒有畫出標題，搜尋欄被往下推；iPadOS 26 直向點搜尋欄即隱藏大標題。加 `.navigationBarTitleDisplayMode(.inline)` 後，27 直向與橫向的輸入、收鍵盤、清除都不再位移、標題保留；`searchPresentationToolbarBehavior(.avoidHidingContent)` 在 inline 下不需要。
- 欄寬：`regularListContent` 內、位於 `.searchable` 內層的 `navigationSplitViewColumnWidth` 完全沒有作用 (改成固定 200 仍是約 340pt)；移到 `.searchable` 外層或 `RootSidebarLayout` 的 `content:` 閉包就生效。
- 欄位 frame：兩版的清單欄與詳情欄 frame 都不含側邊欄。橫向 (視窗 1180pt) 26 側邊欄 250、清單 320、詳情 609.5；27 側邊欄 240、清單 340、詳情 599。直向 (820pt) 側邊欄收起，清單欄左緣為 0。
- 直向 content 欄有系統上限：要求 410pt 時，27 從一開始就要求會收斂到 340pt，從 320 動態改成 410 則系統把清單欄整個收起 (只剩詳情欄)；26 可給到 410。
- 直向側邊欄：加 `.navigationSplitViewStyle(.balanced)` 並把清單欄縮到 200pt，展開的側邊欄仍覆蓋在清單上。UIKit `preferredSplitBehavior` 文件：系統會盡量採用偏好的行為，空間不夠時改用其他介面。

限制 (`.claude/rules/ios-navigation.md`)：「更多」堆疊非空時切分頁會讓 iPad 的 `NavigationSplitView` 崩潰 (現有 `popToRoot` 防護)；alert 要掛在目前最上層的畫面；綁 store 的 View 不持有 presentation 狀態。

## Goals / Non-Goals

**Goals:**

- 訂單分頁的搜尋欄、導覽標題、筆數、「⋯」「+」與多選控制項只在清單欄寬度內 (spec `adaptive-layout` 新 requirement)。
- 詳情欄以系統導覽列承載客戶名稱與兩個選單，推入詳情與詳情欄共用一份工具列定義。
- 根層只宣告「哪些分頁是清單＋詳情」，訂單畫面的組成與呈現細節留在 `Features/Orders/`；不留只為繞過限制或走不到的程式。
- 版面判斷依視窗決定，不因畫面所在的 split view 欄位尺寸分類而改變。
- 其他分頁、compact 版面與所有 sheet／alert 的呈現語意維持不變。

**Non-Goals:**

- 不改清單欄篩選區、訂單列、詳情內容的排版與 TCA 狀態結構。
- 不改開團 (詳情維持推入)、總覽、分析、「更多」的版面。
- 不新增本地化字串；只新增 UI 測試定位所需的 accessibility identifier (清單見「UI 測試以欄位範圍比對守門」)。
- 不在本 change 改用 `TabView` 的 `.sidebarAdaptable` (見 Open Questions)。

## Decisions

### 根層以分欄型態宣告切換兩欄與三欄 NavigationSplitView

`RootSidebarLayout` 新增私有巢狀列舉，把 `RootTab` 對應成 regular 版面的分欄型態，例如 `SplitColumns.listDetail(ListDetailTab)` 與 `SplitColumns.single(SingleColumnTab)`：`ListDetailTab` 目前只有 `orders`，`SingleColumnTab` 是 `dashboard`、`campaigns`、`insights`、`more`。對應寫成一個窮舉 `RootTab` 的 switch，是「哪些分頁是清單＋詳情」的唯一宣告處。

`splitContent` 依這個列舉分流：
- `.listDetail`：`NavigationSplitView { sidebar } content: { ... } detail: { ... }`，訂單的 content 為 `OrdersView`、detail 為 `OrdersRegularDetailColumn`。
- `.single`：`NavigationSplitView { sidebar } detail: { ... }`，內層 switch 只窮舉 `SingleColumnTab`，取代現有 `destination(selectedTab:)` 中的非訂單分支。

所有 `.single` 分頁共用同一個分支，非訂單分頁之間切換時 split view 不重建 (與現況相同)；也不存在 `.orders` 走不到的分支。巢狀型別依 `/ios-dev-kit` 放在 Nested Types 區；`RootSidebarLayout.swift` 改完若超過 300 行，依 `apps/ios/CLAUDE.md` 先把分欄內容抽成獨立 View 型別，不拆 Preview。

以後其他分頁 (例如開團) 要改成清單＋詳情並排，只需在這個對應加入並補該分頁的兩欄畫面；規則寫入 `.claude/rules/ios-navigation.md`。

替代方案 (審查後不採用)：
- `if selectedTab == .orders` 分流並讓 `destination` 的 `.orders` 回傳空畫面：留下走不到的分支，且把「訂單是特例」寫死在判斷式。
- 每個分頁各寫一個 case：每次切分頁都重建 split view，比現況差。
- 永遠三欄、其他分頁放 content 欄：`NavigationSplitViewVisibility` 沒有「只隱藏 content 欄」的選項。
- 訂單頁內巢狀 `NavigationSplitView`、`HStack` 內各包一個 `NavigationStack`：見 proposal Alternatives。

取捨：在訂單與其他分頁之間切換時，SwiftUI 會換掉整個 split view (兩個分支型別不同)，側邊欄跟著重建；側邊欄選取由 `RootFeature.State.selectedTab` 衍生，不會遺失。

### 訂單清單欄承載搜尋、標題與工具列

`OrdersView` 的 regular 分支改名為 `regularListContent` (不再是兩欄)，只渲染清單欄：在 `OrdersView` 內對 `OrdersRegularListColumn` 實例掛 `.searchable(placement: .navigationBarDrawer(displayMode: .always))`、`rootNavigationTitle(listStore.navigationTitleKey, ...)` 與 inline 標題 (見「清單欄導覽標題固定 inline」)、`.toolbar { OrdersToolbarContent(...) }`、對話框 (見「對話框先試單一掛載點」)，以及原本掛在 regular 分支外層的 `.task` 與兩個清單 sheet。欄寬不在這裡設定，見「欄寬由 RootSidebarLayout 依側邊欄是否並排決定」。`OrdersRegularListColumn.swift` 本身不改；`ProjectionWriteBoundaryTests`、`ActionGroupingScanTests` 引用的路徑不變，由完整單元測試照常守門。

清單欄不包 `NavigationStack`：regular 訂單沒有推入目的地，split view 的欄本身就有導覽列，`.searchable` 掛在欄內 view 即符合官方說法 (codex-impl 另以 WWDC22「The SwiftUI cookbook for navigation」的三欄範例佐證)。若實測 content 欄沒有出現搜尋欄或工具列，改為在清單欄內包一層 `NavigationStack`，並記入本檔 Risks。

`listSnapshot()` 在 `regularListContent` 內仍只取一次，`OrdersRegularListColumn(orders: snapshot.orders)` 與 `OrdersToolbarContent(isAllFilteredSelected: snapshot.isAllSelected, filteredIDs: snapshot.ids, ...)` 寫法不變；`OrderListSnapshotSourceScanTests` 的宣告引數同步改成 `var regularListContent: some View`。

`OrdersView.body` 外層的編輯、合併、AI 摘要 sheet 位置不變，隨 `OrdersView` 落在 content 欄；從詳情欄選單觸發的編輯、合併會由清單欄的 sheet 呈現 (跨欄呈現，見 Risks)。

### 詳情欄改用系統導覽列並共用詳情工具列

新增 `OrderDetailToolbarContent: ToolbarContent` (放 `Features/Orders/Components/`)，內容是兩個 `.primaryAction` 的 `OrderDetailMenu(kind: .status)` 與 `OrderDetailMenu(kind: .more)`；`OrderCompactDetailView` 與 `OrdersRegularDetailColumn` 都改用它。兩處各自設 `navigationTitle(Text(verbatim: order.customer.name))` 與 `.navigationBarTitleDisplayMode(.inline)`。

`OrdersRegularDetailColumn` 刪除 `titleBar(order:store:)` 與 `safeAreaInset`，有選取訂單時顯示 `OrderDetailView(store:layout: .wide)` 加上述標題與工具列；沒有選取時只顯示既有 `emptyState` (`ContentUnavailableView`，補 identifier)，不掛詳情工具列。

`OrderDetailMenu` 移除 `layout` 參數與 `.wide` 外觀分支 (`.borderlessButton`、`.small`、文字 label)：兩處都在系統 toolbar，外觀以現行 compact 的圖示 label 為準 (主對話選擇：toolbar 的選單在 iOS 26 以玻璃按鈕呈現，「更新狀態」文字不再顯示，`accessibilityLabel` 保留「更新狀態」與「更多操作」)。`OrderDetailView.OrderDetailLayout` 仍供詳情內容排版使用，不刪。

替代方案：保留自繪標題列並隱藏詳情欄系統導覽列，使用者 2026-10-19 未採用。

### 對話框先試單一掛載點

`regularAlertBinding(isDetail:)` 的「有詳情掛詳情欄、否則掛清單欄」源自「`NavigationStack` 外層的 alert 蓋不過推入頁面」的限制 (規則的參考實作是開團詳情的推入)。訂單三欄沒有推入頁面，這個前提可能不存在。

做法：3.3 (原 3.1) 先只在清單欄 (`regularListContent`) 掛一個 alert，綁定容器呈現子 Feature 的 `destination.alert`，不依有無詳情切換；`OrdersRegularDetailColumn` 不掛 alert。
- iPad 實測：`OrderDetailMenuTests` 從詳情欄觸發刪除確認、取消後保留詳情的案例全綠，就刪除 `regularAlertBinding(isDetail:)` 與 `AlertBinding` typealias，不另開檔案。
- 對話框沒有出現：恢復「有詳情掛詳情欄、否則掛清單欄」的判斷，搬到新檔 `apps/ios/BuyLedger/Features/Orders/Store+OrdersRegularAlert.swift` (只放一個 `extension Store where State == OrdersFeature.State, Action == OrdersFeature.Action`，含 typealias)，清單欄與詳情欄各呼叫一次；不寫進 `OrdersFeature.swift` (該檔已在行數例外上限，且呈現用 Binding 不屬 reducer)。採用哪一種寫入本檔 Risks。

同一個綁定不可同時掛兩處 (規則：會重複呈現)。

### 直向依系統收合側邊欄

**Supersedes**: ipad-orders-three-column / 側邊欄並排先用不帶狀態的 balanced 樣式

使用者 2026-10-20 裁定：直向照系統的欄位呈現，不強制三欄全顯示。依據為上方 Context 的實測：iPad Air 11 直向時系統收起側邊欄，加 `.balanced` 也一樣；強制全顯示要在 `RootFeature` 保存欄位顯示狀態並自訂兩欄與三欄的對應規則，詳情欄只剩約 260pt。

- 三欄分支不加 `.navigationSplitViewStyle(...)`，也不綁 `columnVisibility`；橫向側邊欄、清單欄、詳情欄並排不重疊，直向清單欄與詳情欄並排，側邊欄由系統決定並排或收到「顯示側邊欄」鈕後。
- 較寬的 iPad (例如 13 吋直向 1032pt) 系統可能仍並排三欄，規格與測試都接受兩種情形。
- 已知取捨：在訂單分頁直向切到其他分頁要先叫出側邊欄；使用者在訂單分頁收起側邊欄後切到其他分頁，split view 重建、側邊欄恢復顯示。

替代方案：以 `RootFeature.State` 綁 `NavigationSplitViewVisibility` 固定 `.all`，使用者未採用。

UI 測試：`OrderRegularColumnScopeTests` 的方向方法在直向側邊欄收起時，以 `AppNavigator.revealSidebarIfCollapsed` 從左緣叫出，斷言選取訂單列左緣不變 (容許 1 點) 且側邊欄右緣蓋過訂單列左緣，守住「不設 style、不綁 `columnVisibility`」這個預設 (verify 2026-10-21 指出原本排除自動測試的理由不成立)。

使用者 2026-10-20 實機試用後要求直向展開側邊欄時改為推開清單；實測 `.balanced` 加上清單欄縮到 200pt 仍覆蓋 (見 Context)，使用者裁定維持系統覆蓋。取用 SwiftUI 底下的 `UISplitViewController` 強制並排依賴未公開的視圖結構，不採用。

### 清單欄導覽標題固定 inline

`regularListContent` 在 `rootNavigationTitle` 後加 `.navigationBarTitleDisplayMode(.inline)`。依據為 Context 的實測：清單欄的大標題在搜尋結束 (收鍵盤或清除文字) 後留出空白卻不顯示標題，把搜尋欄與詳情欄往下推；固定 inline 後導覽列高度不隨搜尋狀態改變。只作用於 regular 清單欄；iPhone 的 `OrdersCompactView` 不改 (使用者未回報，iPhone 搜尋有系統取消鈕)。

替代方案：`searchPresentationToolbarBehavior(.avoidHidingContent)` 只讓輸入時保留標題，清除後仍下移，不採用；改自繪標題列違反「系統元件優先」。

### 多選筆數顯示在清單欄頂部

inline 標題的副作用：iPadOS 26 直向清單欄 320pt，多選時導覽列只放得下全選、更改狀態、完成，「已選 N 筆」標題整個被擠掉 (原本的大標題顯示在導覽列下方)；橫向約 470pt 放得下。使用者 2026-10-20 在「清單頂部加一行筆數」「多選時改回大標題」「維持現狀」中選擇第一項。

- `OrdersRegularListColumn.listHeader` 在 `store.isSelecting` 時最上方加 `selectionSummary`：顯示 `store.navigationTitleKey` (與 iPhone 多選標題同一份文字：未選時「選擇訂單」、選取後「已選 N 筆」)，identifier `Orders.selectionSummary`。輔助字級時隨 `listHeader` 一起進入捲動區。
- regular 清單欄的導覽標題改為固定的 `orders.list.title` (主對話選擇：避免橫向時標題與頂部同時顯示筆數)；iPhone 的 `OrdersCompactView` 照舊以 `navigationTitleKey` 顯示多選標題。

測試 (先失敗)：`OrderRegularColumnScopeTests` 新增「多選勾選一筆後清單欄頂部顯示已選筆數」：進入多選、點選一筆後，`Orders.selectionSummary` 的文字含 `1`，且直向與橫向都在清單欄水平範圍內。多選列的 identifier 同時落在按鈕與內層摘要，點擊取 `firstMatch`。改動前 (拿掉 `selectionSummary`) 應因找不到元素失敗。清單欄多選截圖重錄。

測試 (先失敗)：新增 `OrderRegularSearchBarTests` (regular 限定)，直向與橫向各一次：記錄搜尋前搜尋欄上緣與詳情欄導覽列上緣，點搜尋欄、輸入仍符合選取訂單的文字、點鍵盤工具列收鍵盤、清除文字，收鍵盤後與清除後都斷言清單欄導覽列的「訂單」標題存在且可見、兩個上緣與搜尋前相差不超過 1 點。標題以 `Orders` 的導覽標題字面值 (鎖定語言) 在清單欄範圍內的導覽列中查找，或補 identifier，實作時擇一並寫在測試註解。改動前 (拿掉 inline) 應失敗。

### 欄寬由 RootSidebarLayout 依側邊欄是否並排決定

**Supersedes**: ipad-orders-three-column / 訂單清單欄承載搜尋、標題與工具列 (欄寬以 `.navigationSplitViewColumnWidth(min:ideal:max:)` 沿用三個 `@ScaledMetric` 的部分)

使用者 2026-10-20 要求清單與詳情各佔一半 (直向各半、橫向扣掉側邊欄後各半)，並在得知直向做不到後裁定直向維持系統行為。

做法 (`RootSidebarLayout`，宣告欄位的地方)：
- 以 `onGeometryChange` 記錄兩個視窗座標：清單欄 (`content:` 閉包的 `OrdersView`) 的 `frame(in: .global).minX`，與三欄 `NavigationSplitView` 的 `frame(in: .global).maxX`。
- `content:` 閉包對 `OrdersView` 設 `navigationSplitViewColumnWidth(目標寬)`：清單欄左緣大於 0 (側邊欄並排把它往右推) 時為 `(三欄右緣 − 清單欄左緣) / 2`，其餘 (側邊欄收起或覆蓋、尚未量到) 為 320。
- 目標寬只取決於視窗寬度與系統決定的側邊欄位置，不讀清單欄或詳情欄本身的寬度，沒有回饋迴圈。
- `OrdersView` 刪除三個 `@ScaledMetric` 欄寬與 `regularListContent` 內的欄寬設定 (主對話選擇：欄寬固定、不隨字級加寬，理由同「輔助字級時篩選區併入清單捲動區」的替代方案：加寬會擠壓詳情欄)。
- 欄寬設定掛在 `.searchable` 內層不會生效 (Context 實測)，寫入 `.claude/rules/ios-navigation.md`。

替代方案 (實測後不採用)：
- 量清單欄與詳情欄實寬、把兩者合計的一半回寫成欄寬 (回饋式)：27 直向會出現超過系統上限的目標寬，系統把清單欄收起後量不到清單欄，無法恢復。
- 直向也平分：27 直向的 content 欄上限 340pt，動態要求 410pt 會讓清單欄消失。
- 直向改成兩欄分欄、在內容區自己並排清單與詳情：轉向時整個版面重建 (捲動位置、搜尋狀態重置)，兩層導覽列要另外處理，使用者未採用。

測試 (先失敗)：新增 `OrderRegularColumnWidthTests` (regular 限定)。清單欄寬以 `2 × (Orders.listRoot 右緣 − 第一筆訂單列的水平中心)` 推算 (訂單卡片左右內距相同，iPadOS 26 的 `Orders.listRoot` 左緣延伸到側邊欄底下不可用)，詳情欄寬取 `Orders.detailRoot` 寬度：
- 橫向且側邊欄並排：兩欄寬相差不超過 2 點；清單欄左緣貼齊 `Root.sidebar` 右緣 (容許 2 點)、`Orders.detailRoot` 右緣貼齊視窗右緣 (容許 1 點)。
- 直向：清單欄寬 320 (容許 1 點)，清單欄左緣貼齊視窗左緣、詳情欄右緣貼齊視窗右緣；轉到橫向再轉回直向，`Orders.listRoot` 與 `Orders.detailRoot` 都仍存在且可互動。
改動前 (欄寬掛在 `.searchable` 內層) 橫向方法應失敗 (清單約 320、詳情約 610)。

### 版面判斷依視窗尺寸分類在根層決定

使用者 2026-10-20 裁定。`NavigationSplitView` 的 content 欄回報 compact 水平尺寸分類，現行 `blLayoutClass` 由每個畫面所在環境的尺寸分類推導，因此清單欄被判成 compact；既有規格寫明版面依「視窗」的尺寸分類決定，現行推導方式在 split view 欄內不成立。

做法 (全部放在 `Shared/DesignSystem/Foundations/BLLayoutClass.swift`)：
- `EnvironmentValues` 新增一個存放「根層已決定版面」的私有儲存 (例如 `@Entry` 的 optional 值)，`blLayoutClass` 改為可讀寫：有已決定值時回傳它，否則照現行由尺寸分類推導。
- `RootView` 讀自己環境的 `blLayoutClass` (根層即視窗的尺寸分類) 選擇根導覽宿主，並以 `.environment(\.blLayoutClass, layoutClass)` 把這個值交給整個子樹；視窗尺寸分類改變時 `RootView` 重新讀到新值並往下傳。
- `RootView` 與其他 production 程式仍不引用尺寸分類，原始碼掃描規則 (`DesignSystemSourceScanTests`) 不變。
- Preview 與截圖測試沒有經過 `RootView`，維持由注入的尺寸分類推導，既有截圖不受影響。
- 目前讀 `blLayoutClass` 的畫面只有 `RootView`、`OrdersView`、`DashboardSummarySection`、`InsightsView` (2026-10-20 搜尋)，都不在 sheet 內；總覽與分析在兩欄的 detail 欄，原本就判成 regular，行為不變。

測試 (先失敗)：`BLLayoutClassEnvironmentTests` 新增「已決定值覆寫欄位的 compact 尺寸分類」與「沒有已決定值時依尺寸分類推導」兩類案例，以 `EnvironmentValues` 直接設定或宿主畫面驗證；先加可讀寫介面但讀取時忽略已決定值，確認新案例失敗，再實作。整合後 iPad `OrderRegularClearFiltersTests`、`OrderPaymentMethodMenuTests` (清單欄需要 regular 篩選區) 轉綠。

替代方案：根層不經 `OrdersView` 的版面分流、直接放清單欄專用畫面並把編輯、合併、AI 摘要 sheet 搬到共用 modifier，使用者未採用。

### 輔助字級時篩選區併入清單捲動區

使用者 2026-10-20 裁定在本 change 修正。4.2 的最大輔助字級量測 (iPad Air 11) 發現：三欄的清單欄寬度固定 320pt，不隨字級加寬 (事後查明是當時的欄寬設定掛在 `.searchable` 內層而沒有生效，見「欄寬由 RootSidebarLayout 依側邊欄是否並排決定」；欄寬現在依設計固定，不隨字級加寬，本節做法不變)；清單欄導覽列 (大標題加搜尋欄) 在該字級高 267pt；`OrdersRegularListColumn` 的 `listHeader` (狀態膠囊、日期膠囊、付款方式 Menu、類別觸發鈕、清除篩選) 固定在 `ScrollView` 外，剩餘高度不足時被壓縮，`BLFilterChipLabel` 的文字以 `fixedSize(horizontal: false, vertical: true)` 撐出原本的高度，於是付款方式、類別與日期膠囊互相重疊。

做法：`OrdersRegularListColumn` 讀 `@Environment(\.dynamicTypeSize)`，`isAccessibilitySize` 時把 `listHeader` 放進 `ScrollView` 內、置於訂單內容之上，隨清單一起捲動，不再被壓縮；標準字級維持現行「篩選區固定在上方、只有訂單捲動」。`Orders.listRoot` 仍掛在 `ScrollView`。

測試 (先失敗)：`LaunchOptions` 新增系統字級設定，序列化為 `-UIPreferredContentSizeCategoryName <類別>` (UIKit 系統參數，不經 `BLUITestConfiguration`)；新增 `OrderRegularAccessibilitySizeTests` (regular 限定)，以最大輔助字級在直向與橫向驗證：狀態膠囊 (`Orders.statusChip("all")`)、日期膠囊、付款方式 Menu、類別觸發鈕、清除篩選鈕都位於 `Orders.listRoot` 的範圍內 (上緣 ≥ `Orders.listRoot` 上緣)，且依序相鄰兩個的上下不重疊 (前一個下緣 ≤ 後一個上緣，容許 1 點)；另以一條標準字級案例確認篩選區仍在 `Orders.listRoot` 上方。改動前「位於捲動範圍內」的斷言會失敗。另以清單欄分欄截圖 (`dynamicTypeSize` 設為 `.accessibility5`) 目視確認不重疊。

範圍：只改清單欄篩選區的位置；`BLFilterChipLabel` 與篩選元件本身不改。compact 版面的清單篩選不在範圍內。

替代方案：讓清單欄寬度隨字級變寬 (加寬會擠壓詳情欄，橫向平分時也會破壞兩欄各半)；或修改 `BLFilterChipLabel` 不再撐高 (只遮掉文字，仍不可讀)，都不採用。

### 寬版 snapshot 改為分欄拍攝

三張寬版截圖改為分欄拍，不渲染整個根層：
- `ordersView_寬版多選模式_顯示選取列` 與 `ordersView_寬版無付款方式與類別_符合基準圖`：拍清單欄，`OrdersView` 以 regular 尺寸分類渲染並在測試內包 `NavigationStack` (呈現搜尋欄、標題與工具列)，尺寸 320×768 (清單欄 ideal 寬度)。
- `ordersView_寬版選取含成本明細訂單_符合基準圖`：改拍詳情欄，`OrdersRegularDetailColumn` 在測試內包 `NavigationStack` (呈現客戶名稱標題與兩個選單)，尺寸 704×768 (1024 扣掉清單欄 320)。
- 測試名稱依 `<方法>_<情境>_<預期>` 調整 (例如第一段改 `ordersView` 清單欄、`ordersRegularDetailColumn` 詳情欄，情境寫明「寬版清單欄」「寬版詳情欄」)，刪除三張舊基準圖、重錄並逐張目視確認。
- 既有的 `LookupCatalog.withIsolatedStorage` 與 `TestDependencies.withFixedNow` 包裝保留；仍使用現有 `OrdersFeature()` reducer，與現況相同。

理由 (使用者 2026-10-20 同意)：渲染整個根層會把側邊欄 (logo、徽章、分頁列) 拍進三張訂單基準圖，側邊欄任何改動都要重錄，稀釋截圖的守門意義；也需要不執行效果的 store 與根狀態隔離才能避免載入觸發與共用資料外溢。分欄拍只在訂單畫面本身改變時才需重錄；三欄如何組合 (誰在哪一欄、不重疊) 由 `OrderRegularColumnScopeTests` 的位置比對守住。

### 驗收只跑會進訂單分頁的 UI 類別

使用者 2026-10-19 裁定：本 change 不跑 iPhone 與 iPad 的完整 UI 主回歸。

- iPad：程式改動落在 `RootSidebarLayout` 的清單＋詳情分支與訂單畫面；單欄分支的內容不變。會進到訂單分頁的是 `apps/ios/BuyLedgerUITests/Tests/Orders/` 底下全部類別，加上以下列指令在整個 UI 測試 target 找出的其他類別 (排除 Page Object 與 Support)：

  ```
  grep -rln "goToOrders\|OrdersScreen(\|BLAccessibilityID.Orders\." apps/ios/BuyLedgerUITests --include='*.swift' | grep -v "/Screens/\|/Support/\|/Tests/Orders/"
  ```

  2026-10-20 結果：`CustomersTests` (客戶跳訂單)、`LookupManagementTests` 與 `CurrencyPickerTests` (先進訂單再切到其他分頁)、`LaunchSmokeTests`、`OrientationLayoutTests`、`PhotoViewerPagingTests` (進訂單、選詳情、開編輯 sheet，放在 UI 測試目錄最外層)、`KeyboardDismissTests` (鍵盤前提檢查本來就會先跑)。
- iPhone：改動只有詳情工具列抽成共用定義 (畫面不變) 與多選相關控制項補 identifier，由 2.1、3.1 的 `OrderDetailTests`、`OrderDetailMenuTests`、`OrdersListTests` 與 iPhone 推入詳情 snapshot 守住。

替代方案：iPhone 與 iPad 都跑完整主回歸，涵蓋面只多出不經過訂單分頁的開團、分析、總覽與「更多」流程，使用者未採用。

剩餘風險：若有測試經由上述 grep 認不出的路徑進入訂單分頁 (例如從分析頁連結過去)，會漏跑；2026-10-20 搜尋沒有這類測試，4.2 執行前重跑同一個 grep 更新清單。

### UI 測試以欄位範圍比對守門

新增 `OrderRegularColumnScopeTests` (regular 版面限定，依規則於 Given 的 `launch` 後 `XCTSkipUnless(isRegularLayout(app), ...)`)，依 spec scenario 拆成多個測試方法，讓每組斷言的紅綠各自可見。水平範圍比對抽成 `apps/ios/BuyLedgerUITests/Support/HorizontalBounds.swift` 的共用 helper (讀 frame 前先經 `isHittableOnScreen` 排除無效 frame，容許 1 點誤差)，之後其他畫面守欄位歸屬也可重用。

各方法的斷言：
- 清單欄的水平範圍定義為「`Root.sidebar` 右緣到 `Orders.listRoot` 右緣」。2026-10-20 改動前實測 (iPad Air 11 直向)：iPadOS 26 的內容會延伸到浮動側邊欄底下，`Orders.listRoot` (ScrollView) 的左緣是 0，不代表可見的清單欄左緣；側邊欄 (CollectionView) 存在但不可互動，取 frame 只要求存在且有效。
- 清單欄控制項：可互動的搜尋欄 (`OrdersScreen` 以 `allElementsBoundByIndex.first(where: \.isHittableOnScreen)` 取得)、筆數、`Orders.addButton`、`Orders.batchMenuButton` 的左右緣都落在上述清單欄範圍內。直向、橫向各驗一次 (轉向比照 `OrientationLayoutTests`，teardown 轉回直向，不開 Device Hub)。
- 三欄不重疊：選取訂單列 (`Orders.row(orderID:)`，代表可見的清單內容) 右緣 ≤ `Orders.detailRoot` 左緣；側邊欄顯示時，`Root.sidebar` 右緣 ≤ 該訂單列左緣。橫向要求側邊欄顯示；直向接受側邊欄收起 (此時 `Root.sidebar` 不在可及性樹上)。
- 詳情導覽列：在 `app.navigationBars` 中取左緣 ≥ `Orders.listRoot` 右緣的導覽列，其 `identifier` 等於所選 seed 訂單的客戶名稱字面值 (資料值，不隨 App 語言變動；導覽列是 `.claude/rules/ios-ui-tests.md` 允許以 `app.navigationBars` 定位的受控例外)，且 `Orders.detailStatusMenuButton`、`Orders.detailMoreButton` 的 frame 落在這條導覽列範圍內。
- 多選：以新增的 `OrdersScreen.enterSelectionMode()` (點 `Orders.batchMenuButton` 後以 `tapMenuItem` 點「選取訂單」) 進入多選後，全選、批次狀態、完成三個控制項的左右緣落在清單欄範圍內，詳情導覽列斷言仍成立。
- 無選取：搜尋不存在的字串讓清單為空後，詳情空狀態存在，`Orders.detailStatusMenuButton` 與 `Orders.detailMoreButton` 都不存在，詳情欄導覽列的 `identifier` 不再是原客戶名稱。
- 側邊欄收起的處理放在共用的 `AppNavigator`：`isSidebarLayout` 在找不到側邊欄與分頁列時，若訂單清單欄與詳情欄 (`Orders.listRoot` 加上 `Orders.detailRoot` 或 `Orders.detailEmptyState`) 同時存在也判定為 regular (只有 regular 會同時顯示兩者)；`selectTab` 在 regular 而側邊欄收起時，先從視窗左緣往右滑叫出側邊欄 (與語言無關，不以「顯示側邊欄」文字定位系統按鈕)，等 `Root.sidebar` 出現再點分頁列。左緣滑動不可靠時停下回報，再決定是否以鎖定語言下的按鈕文字作為受控例外。
- 其他分頁：切到總覽後 `Orders.listRoot`、`Orders.detailRoot`、`Orders.detailEmptyState` 都不存在，`Dashboard.root` 左緣 ≤ `Root.sidebar` 右緣 (中間沒有其他欄)、右緣貼齊視窗右緣 (容許 1 點)；切回訂單後清單欄控制項斷言仍成立。

新增 identifier (常數放 `BLAccessibilityID+Orders.swift`)：多選入口「選取訂單」(`OrdersToolbarContent.selectionModeButton`)、全選／清除 (`selectionButton`)、批次狀態 (`batchStatusMenu`，掛在 `Menu` 本身)、完成 (`selectionDoneButton`)、筆數 (`orderCount` 的 `Text`)、詳情空狀態 (`OrdersRegularDetailColumn.emptyState` 的 `ContentUnavailableView`，先加 `.accessibilityElement(children: .contain)` 再掛 identifier)。

改動前先失敗的預期 (1.1 補完 identifier 後、未改版面前執行)：
- 應失敗，且失敗原因必須是位置越界或找不到詳情欄導覽列，不是找不到元素：搜尋欄、`addButton`、`batchMenuButton` 超出清單欄右緣；找不到左緣在清單欄右側的詳情導覽列；多選的批次狀態與完成超出清單欄右緣；其他分頁方法切回訂單後重做的清單欄控制項斷言 (codex-impl 2026-10-20 指出原列為應通過有誤，主對話採納)。
- 應通過：筆數與全選 (在左側)、三欄不重疊、無選取的空狀態與選單消失、其他分頁方法中切到總覽的那一段。
1.1 勾選時上述失敗測試預期仍為紅，到 3.1 才轉綠，期間不單獨提交。

### 導覽欄不套用輔助字級的單欄規則

既有 `dynamic-type-adaptation` 規格的「Layouts change structure at accessibility text sizes」要求多欄排列在輔助字級收成單欄，沒有寫明導覽欄是否適用；新 requirement 要求三欄並排。現況兩欄 `HStack` 在輔助字級也沒有收成單欄，所以 delta spec 補一句「導覽欄由系統 split view 管理，單欄規則作用於各欄內容」，把既有邊界寫清楚，不是新決定。

清單欄寬度不隨字級加寬 (見「欄寬由 RootSidebarLayout 依側邊欄是否並排決定」)；4.2 以量完即刪的暫時 UI 測試，用啟動參數 `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL` 開到最大輔助字級，記錄 iPad 直向與橫向的三欄寬度。詳情欄無法閱讀時回報使用者，不在本 change 自行處理。這個啟動參數是 UIKit 系統設定，不屬於專案 `-BLUITest` 測試掛鉤，因此只用於一次性量測，不進正式測試。

## Implementation Contract

**行為 (使用者可觀察)**：
- iPad 全螢幕訂單分頁的清單欄與詳情欄並排、不重疊；橫向時側邊欄也並排，直向時側邊欄由系統決定並排或收起 (iPad Air 11 直向收起，點「顯示側邊欄」叫出，叫出的側邊欄覆蓋在清單上)；搜尋欄、「訂單」標題 (多選時為已選筆數)、筆數、「⋯」「+」與多選控制項只在清單欄頂部。
- 側邊欄並排時清單欄與詳情欄各佔扣掉側邊欄後的一半；直向清單欄 320pt、詳情欄佔其餘；轉向後兩欄都仍顯示。
- 清單欄標題為 inline；收鍵盤或清除搜尋文字後標題仍在，搜尋欄與詳情欄不下移。
- 詳情欄頂部是系統導覽列，標題為選取訂單的客戶名稱，右側為狀態選單與更多操作選單 (圖示)；詳情內容頂部不再有自繪標題列。沒有選取訂單時只顯示「選擇訂單」空狀態。
- 切到總覽、開團、分析、更多時是兩欄；切回訂單恢復三欄。iPhone 與 iPad 窄視窗不變。
- 編輯、合併、AI 摘要、篩選 sheet、類別選擇器與刪除確認等對話框照常出現在最上層。

**介面**：
- `RootSidebarLayout`：私有分欄型態列舉與 `RootTab` 對應 (唯一宣告處)；`splitContent` 依它分流兩欄與三欄；移除 `destination(selectedTab:)` 中的訂單分支 (改由只窮舉單欄分頁的 switch 取代)。
- `OrdersView`：公開 init 不變；regular 分支改名 `regularListContent`，只產出清單欄。
- `OrdersRegularDetailColumn(store: StoreOf<OrdersFeature>)`：init 不變，自帶導覽標題與 `OrderDetailToolbarContent`；單一掛載點成功時不掛 alert。
- `OrderDetailToolbarContent(store: StoreOf<OrderDetailFeature>)`：新 `ToolbarContent`。
- `OrderDetailMenu(kind:store:)`：移除 `layout` 參數 (**BREAKING**，程式內部介面，兩個呼叫端同步改)。
- `OrdersScreen`：新增取得可互動搜尋欄與 `enterSelectionMode()`；`Support/HorizontalBounds.swift`：水平範圍比對 helper。
- `EnvironmentValues.blLayoutClass`：改為可讀寫，有根層已決定值時回傳它，否則由尺寸分類推導；`RootView` 把讀到的值交給子樹。
- `AppNavigator`：`isSidebarLayout` 能辨識側邊欄收起的 regular 版面，`selectTab` 在側邊欄收起時先叫出側邊欄。
- `RootSidebarLayout`：兩個 `@State` 視窗座標 (清單欄左緣、三欄右緣) 與計算目標欄寬的私有屬性；`OrdersView` 不再宣告欄寬。

**失敗模式**：
- 三欄分支或清單欄缺少 `.searchable`／`.toolbar`：`OrderRegularColumnScopeTests` 轉紅。
- 對話框沒出現：`OrderDetailMenuTests` (iPad 刪除確認) 轉紅，依「對話框先試單一掛載點」改回兩處判斷。
- 清單欄被判成 compact (畫出整合篩選鈕)：`OrderRegularClearFiltersTests`、`OrderPaymentMethodMenuTests` 在 iPad 轉紅。
- 橫向側邊欄沒有並排：`OrderRegularColumnScopeTests` 的三欄不重疊方法轉紅。
- 欄寬沒有生效或計算錯誤：`OrderRegularColumnWidthTests` 轉紅；直向超過系統上限而清單欄消失：同一類別的轉向方法轉紅。
- 搜尋結束後標題消失或下移：`OrderRegularSearchBarTests` 轉紅。

**驗收**：
- `OrderRegularColumnScopeTests` 在改動前依上列預期失敗與通過，改動後於 iPad 模擬器直向與橫向全綠。
- 單元測試全綠 (含改名後的 `OrderListSnapshotSourceScanTests`、分欄重錄並目視確認的三張截圖)。
- iPad 跑 `Tests/Orders/` 全部類別與會進訂單分頁的其他類別全綠 (含 `OrientationLayoutTests`、`OrderDetailMenuTests`、`OrderEditDirtyTests`、`OrderCreateTests` 的從總覽新增訂單、`CustomersTests` 的客戶深連結、`PhotoViewerPagingTests`)；iPhone 以 2.1、3.1 的受影響類別為準 (見「驗收只跑會進訂單分頁的 UI 類別」)。
- 最大輔助字級的三欄寬度量測結果記錄在 4.2。
- 專責 style 審查逐檔通過 (`/ios-dev-kit` 規範)。

**範圍**：
- 範圍內：上述 iOS 檔案 (含 `BLLayoutClass.swift`、`RootView.swift`、`AppNavigator.swift`)、對應測試與基準圖、apps/ios/README.md 與 `.claude/rules/ios-navigation.md`、`ios-ui-tests.md`、`ios-unit-tests.md`、`ios-design-system.md` 的描述同步。
- 範圍外：清單欄與詳情內容的排版、開團與其他分頁、schema、本地化字串、compact 版面、`TabView` 的 `.sidebarAdaptable` 改造。

## Risks / Trade-offs

- [直向在訂單分頁切到其他分頁要先叫出側邊欄，多一步操作] → 使用者已選照系統收起；側邊欄按鈕是系統提供，與郵件 App 相同。
- [根層把版面判斷交給子樹後，sheet 內若有畫面讀 `blLayoutClass` 會改拿到視窗的版面] → 目前讀取者都不在 sheet 內 (見「版面判斷依視窗尺寸分類在根層決定」)；之後新增讀取者時以視窗版面為準，寫入 `.claude/rules/ios-design-system.md`。
- [split view 型別切換時側邊欄重建，可能有閃爍；使用者收起的側邊欄在訂單與其他分頁間切換會恢復顯示] → 側邊欄項目少、不需捲動；`LookupManagementTests`、`CurrencyPickerTests` (先進訂單再切到其他分頁) 驗證切換流程，有明顯閃爍時回報使用者。
- [「更多」堆疊非空時切到訂單的崩潰防護是否仍有效] → 既有 `sidebarTabSelected` 先 `popToRoot`、客戶深連結先清 path 的流程不變；4.2 在 iPad 跑的 `CustomersTests` 客戶深連結測試驗證。
- [從總覽觸發新增訂單時 `OrdersView` 尚未在階層內] → Root 仍在同一次更新內切到 `.orders` 並設定 sheet state，`OrdersView` 落在 content 欄後掛上 sheet；以 `OrderCreateTests` 的從首頁新增在 iPad 驗證。
- [編輯、合併 sheet 由清單欄呈現、從詳情欄觸發 (跨欄呈現)，官方沒有針對這種情況的說明] → 3.3 (原 3.1) 的 iPad 驗收含 `OrderDetailMenuTests`、`OrderEditDirtyTests`、`OrderMergeTests`、`PhotoViewerPagingTests`。
- [分欄截圖在測試中包 `NavigationStack`，導覽列外觀與 split view 欄內可能有細微差異] → 截圖守各欄內容與列上項目，三欄組合由 UI 位置比對守住。
- [模擬器「視窗 App」模式抓不到可及性樹，無法自動驗證 iPad 視窗縮放 (regular → compact → regular)] → `RootView` 依版面替換根導覽宿主的邏輯本次不改，狀態保存在 TCA store；不加驗收，只記錄於此。
- [輔助字級時篩選區隨清單捲動，捲到下方後看不到目前的篩選條件] → 只在輔助字級改變；篩選條件仍在清單頂端，捲回即可看到；標準字級行為不變。
- [欄寬依量到的座標計算，第一次顯示訂單分頁時先以 320 排版、量到後才平分，橫向可能看到一次欄寬變化] → 座標存在 `RootSidebarLayout` 的 `@State`，之後切回訂單分頁直接沿用；有明顯跳動時回報使用者。
- [UI 測試只能在 iPadOS 26.x 模擬器執行，使用者實機是 iPadOS 27] → 27 的行為以模擬器手動實測 (Context)；裝到實機後由使用者確認。
- [台前調度或分割畫面等較窄的 regular 視窗若系統仍並排側邊欄，平分後的清單欄可能超過系統對 content 欄的上限] → 無法以模擬器自動驗證，由使用者在實機調整視窗寬度確認清單欄不會消失；清單欄被收起後量不到它的座標，目標寬度不會自己降回，所以發生時改為只在視窗寬度足夠時平分。
- [對話框改為單一掛載點後，從詳情欄觸發的刪除確認是否仍會出現] → 3.3 實測成立：iPad `OrderDetailMenuTests` 從詳情欄觸發刪除確認、取消後保留詳情全綠，已刪除 `regularAlertBinding(isDetail:)` 與 `AlertBinding`，未新增 `Store+OrdersRegularAlert.swift`。較窄但仍屬 regular 的視窗 (分割畫面、台前調度) 無法以模擬器自動驗證，由使用者在實機手動確認。
- [詳情選單改為圖示後少了「更新狀態」文字] → 使用者已選系統導覽列；`accessibilityLabel` 保留，VoiceOver 朗讀不變。

## Open Questions

- 長期是否改用 `TabView` 加 `.tabViewStyle(.sidebarAdaptable)` 作為 iPad 與 iPhone 共用的根導覽 (使用者 2026-10-20 同意記錄、另案評估，不在本 change 範圍)：
  - 依據：Apple 範例「Enhancing your app's content with tab navigation」(Destination Video) 採用此樣式，iPadOS 18 起分頁列可在 iPad 切換成側邊欄；專案最低版本 iOS 26 可用。
  - 可能好處：`RootTabLayout` 與 `RootSidebarLayout` 合併成一個宿主；每個分頁自己決定版面 (訂單分頁自己持有清單＋詳情的 split view)，根層不再有分欄型態宣告。
  - 待確認：iPad 預設會從固定側邊欄改成頂部浮動分頁列，與現行 `adaptive-layout` 規格「regular 版面使用側邊欄導覽、橫向並排側邊欄」不同，屬產品決定；側邊欄 logo 列、徽章、分組標題的對應 API；分頁內再放 split view 的實際行為 (官方文件未明確說明，需實測)；「更多」堆疊防崩潰規則與所有分頁的 UI 測試影響。
  - 與本 change 的關係：本 change 的訂單清單欄與詳情欄畫面、共用詳情工具列、欄位位置比對 helper 與 UI 測試都可沿用；屆時移除的主要是 `RootSidebarLayout` 的分欄型態宣告。
