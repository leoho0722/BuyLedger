## Context

App 有兩套版面：compact 版面 (根導覽底部分頁列 `RootTabLayout`、訂單 `OrdersCompactView` 單欄 + push 詳情、首頁與分析頁單欄) 與 regular 版面 (根導覽側邊欄 `RootSidebarLayout`、訂單「清單 + 詳情」兩欄、首頁 hero 與 KPI 並排、分析頁卡片並排)。目前四個畫面各自以 `@Environment(\.horizontalSizeClass)` 判斷：

| 畫面 | 判斷位置 | 現行條件 |
|---|---|---|
| 根導覽 | `RootView` 的 `layout` | 水平 compact → 分頁列，否則側邊欄 |
| 訂單 | `OrdersView` 的 `platformContent` | 水平 compact → `OrdersCompactView`，否則兩欄 |
| 首頁 | `DashboardView` 的 `useWideHero` | 水平不是 compact → 寬版 hero |
| 分析頁 | `InsightsView` 的 `useWideLayout` | 水平不是 compact → 卡片並排 |

大尺寸 iPhone 橫向時水平是 regular、垂直是 compact，四處都誤判成 iPad。條件從 MVP (`efffab8`) 起沒變，iPhone 支援橫向也是建專案時的設定 (2026-10-04 `git log -G` 查證)。全庫 production 程式只有這四處讀尺寸分類 (2026-10-04 grep 實測)；測試端只有 `SnapshotTests.ordersView_寬版多選模式_顯示選取列` 以 `.environment(\.horizontalSizeClass, .regular)` 模擬 iPad，垂直方向沿用 snapshot host (iPhone 直向，regular)。

模擬器 CLI (`mobilebuildmcp`) 沒有轉向指令；UI 測試可用 `XCUIDevice.shared.orientation` 轉向，`BLUITestCase.setUpWithError` 每條測試開始時已重設為直向。`AppNavigator.isSidebarLayout` 以 `BLAccessibilityID.Root.sidebar` 與分頁列判斷目前版面。

## Goals / Non-Goals

**Goals:**

- iPhone 任何機型橫向都維持 compact 版面，只把內容橫向延伸；四個畫面一致 (使用者 2026-10-04 選擇首頁與分析頁也一起改)。
- iPad 全螢幕直向與橫向維持 regular 版面；iPad 窄視窗維持 compact 版面。
- 版面判斷只有一個入口，並以來源掃描守住。
- 規格寫明「iPhone Compact」「iPadOS」等平台措辭對應的是版面而不是裝置。
- 本 change 改到的六個既有檔整份對齊 ios-dev-kit 的風格與結構，畫面與行為不變 (使用者 2026-10-04 裁決)。

**Non-Goals:**

- 不調整 compact 版面在橫向時的細部排版 (間距、欄寬、分頁列)；只驗證內容正常延伸、沒有截斷或重疊。
- 不重寫其他規格的平台措辭：`order-filter-sheet` 由 6d 改寫，`order-category-filter` 的 iPad 觸發鈕段落由 6b 處理訂單列表時一併檢視；本 change 只以 `adaptive-layout` 的對應規則消除歧義。
- `apps/ios/CLAUDE.md` 已登記的過渡例外不在本 change：`OrdersView`、`DashboardView`、`InsightsView` 宣告 `@Dependency` 取現在時間 (第 6、7 步照開團 `dateContext` 做法遷移)、畫面內的統計與格式化計算移進 reducer 或 State (6b、第 7 步)。整檔對齊只處理風格與結構，不改這些既有寫法，也不新增 `@Dependency` 宣告。
- 不以裝置類型 (`UIDevice.userInterfaceIdiom`) 或畫面寬度門檻判斷 (理由見 Decisions)。

## Decisions

### 版面判斷規則：水平與垂直都是 regular 才用 regular 版面

`BLLayoutClass(horizontal:vertical:)` 只在兩個尺寸分類都是 `.regular` 時回傳 `.regular`，其餘 (含 `nil`) 回傳 `.compact`。iPhone 不論機型，橫向時垂直都是 compact；iPad 全螢幕兩個方向都是 regular；iPad 分割畫面變窄時水平是 compact。規則完全由系統尺寸分類推導，iPad 多工視窗自然落在正確版面。

替代方案：
- 依裝置類型 (`UIDevice.userInterfaceIdiom == .phone` 一律 compact)：iPad 窄視窗會被判成 regular 而塞進兩欄，與現況相反；也多一個系統 API 讀取點。
- 依畫面寬度門檻 (GeometryReader)：門檻是任意數字，會隨字級與機型漂移，且 Apple 以尺寸分類作為版面切換的官方訊號。

### 版面判斷收成設計系統的 BLLayoutClass 單一入口

新增 `Shared/DesignSystem/Foundations/BLLayoutClass.swift`：`enum BLLayoutClass` (`compact`、`regular`，遵循 `Equatable`、`Sendable`) 加 `init(horizontal: UserInterfaceSizeClass?, vertical: UserInterfaceSizeClass?)`；同檔以 `extension EnvironmentValues` 提供唯讀的 `blLayoutClass`，由 environment 中的兩個尺寸分類推導 (依 `.claude/rules/ios-design-system.md`「與特定元件耦合的 extension 留在元件檔」)。四個畫面改為宣告 `@Environment(\.blLayoutClass) private var layoutClass`，條件改比對 `layoutClass`；`DashboardView.useWideHero`、`InsightsView.useWideLayout` 改為 `layoutClass == .regular`。實作後的落點 (3.2 拆檔與 5.1 Bool 命名後，2026-10-06 verify 依程式碼校正)：首頁的版面判斷隨 hero 與 KPI 移到 `DashboardSummarySection.shouldUseWideHero`，`DashboardView` 本身不再讀版面；分析頁為 `InsightsView.shouldUseWideLayout`。

放設計系統的理由：它只依賴 SwiftUI，符合 `LayerBoundaryTests` 對 Design System 的限制 (不引用 Core/Domain、不 import TCA)，且屬於「單一來源」類規則 (比照 `@Environment(\.colorScheme)` 只准用在 `BLCardShadow`)。

`Environment.init(_:)` 接受唯讀 `KeyPath<EnvironmentValues, Value>`，API 形狀支援 computed 屬性；但同一個視窗的尺寸分類改變時讀值會不會跟著更新，官方文件沒有明文承諾，所以**以執行期實證為準**：task 1.2 新增 `BLLayoutClassEnvironmentTests`，以 `traitOverrides` 依序切換「regular／regular → regular／compact → regular／regular」與「regular／regular → compact／regular → regular／regular」，斷言探測 View 觀察到的值依序為 regular、compact、regular。觀察與等待的條件：
    - 測試型別標 `@MainActor` (專案預設隔離是 `nonisolated`，UIKit 型別要明確上主執行緒)。
    - 全程使用同一個 `UIWindow`、同一個 `UIHostingController` 與同一個根 View，不在切換之間重建，避免重建掩蓋「既有 View 不更新」的問題。視窗以單元測試 host 已連線的 `UIWindowScene` 建立 (單元測試是 app-hosted，`BuyLedgerApp` 仍宣告 `WindowGroup`)；測試剛開始時 scene 可能尚未連線，先有限次等待，仍取不到就停下回報。視窗要設定 frame 並 `isHidden = false`，讓 hosting view 進入視窗階層，`onAppear` 才會觸發。
    - 探測 View 以 `onAppear` 記錄初始值、以 `onChange(of:)` 記錄後續值，交給測試持有的紀錄器；測試先等到初始 regular 被觀察，再逐次切換。
    - 紀錄器是以 `AsyncStream.makeStream` 建立的 continuation-backed `AsyncStream` (預設無上限緩衝)，在視窗顯示前建立，探測 View 的回報只呼叫 `continuation.yield`，早到的觀察值不會遺失。不使用裸 `CheckedContinuation` 當等待器 (取消時不會自動恢復，逾時後可能卡住)。
    - 每次設定 `traitOverrides` 後呼叫 `updateTraitsIfNeeded()` 與 `window.layoutIfNeeded()`，再等待下一個值：在 `withThrowingTaskGroup` 中加入兩個子任務，一個接收 `Sendable` 的 stream、在子任務內自行建立 iterator 並取一個值 (不捕獲外層可變 iterator；同一時間只有一個 consumer)，另一個以可取消的 `ContinuousClock.sleep` 計時並回傳逾時；以 `group.next()` 取第一個結果，`defer { group.cancelAll() }` 取消落敗者。計時子任務被取消時的 `CancellationError` 以 `try?` 吞掉。
    - 逾時或 stream 提早結束時以 `Issue.record` 記錄失敗並結束這次測試，不再使用已終止的 stream。UIKit 操作與視窗清理留在 `@MainActor` 的測試本體 (含 `defer`)，不放進 `onTermination`。
    - Swift Testing 的 `confirmation` 只在 closure 結束時檢查次數、不會等待事件也沒有逾時，不能當等待器；不以 `Task.yield` 輪詢 (`ios-unit-tests.md`)。
    - 結束時 (含失敗) 隱藏視窗並解除 `rootViewController`，不留在 host App 內。Apple docs MCP 與 Context7 的查證只作輔助紀錄。實證不成立或無法穩定重現時停下回報使用者，不自行改用其他寫法。

替代方案：每個畫面各自宣告兩個尺寸分類再呼叫 `BLLayoutClass(horizontal:vertical:)`，規則雖集中，但畫面仍直接讀尺寸分類，來源掃描無法區分合法與違規的讀取。

### 以來源掃描規則十一守住單一入口

`DesignSystemSourceScanTests` 既有規則一至十 (規則八是豁免標記必須有理由、九是幣別入口、十是語言入口)，新規則編為**規則十一**，測試以語意命名 (三段式正體中文)。

- **禁止的是引用，不只是讀取**：樣式 `\b(?:horizontal|vertical)SizeClass\b`，套在既有剝除註解與字串後的每一行；涵蓋 `@Environment(\.horizontalSizeClass)`、`.environment(\.verticalSizeClass, …)` (Preview 注入也算) 與 `EnvironmentValues` extension 內的裸成員。
- **排除用完整相對路徑**：比照規則九、十以 `excludingRelativePaths: ["Shared/DesignSystem/Foundations/BLLayoutClass.swift"]` 排除，不用只看檔名的 `excludingFilesNamed` (同名檔放在其他目錄會繞過)。
- **不接受行級豁免**：既有 `findViolations` 會略過帶 `design-system-scan-exempt:` 的行；規則十一以參數關閉這個略過 (其他規則行為不變)，帶理由的豁免標記也一樣失敗。
- **正式掃描與 fixture 共用同一個入口** (2026-10-06 review 補修)：規則十一的樣式、排除路徑與「不接受豁免」設定集中在 `DesignSystemSourceScanTests+Scanner.swift` 的規則十一入口，比照既有的 `currencyLookupViolations()`、`languageDerivationViolations()`；入口提供掃描 production 目錄與分類記憶體內原始碼兩種形式，兩者讀同一份豁免設定，正式測試與 fixture 測試都只經入口呼叫，不各自傳 `honoringExemptions`。這樣把入口的豁免設定改成接受豁免時，fixture 的豁免列會轉紅，正式規則不會在沒有任何測試失敗的情況下被放寬。
- **修正共用剝除器的四個缺陷** (`stripCommentsAndStrings`，所有規則共用)：
    - **以 Unicode 碼位辨識分隔符號**：現行以 `Array(line)` 逐個 `Character` (extended grapheme cluster) 比對，`"` 若緊接組合用符號 (例如字串內容是單獨的 U+0301) 會與它合成一個 `Character`，剝除器認不出字串開頭，把結尾當成開頭而剝掉其後的引用。改為逐個 `unicodeScalars` 比對 ASCII 分隔符號 (`"`、`\`、`/`、`*`)，未剝除的內容原樣保留。
    - **字串結尾判斷**：現行只看「前一個字元是不是反斜線」判斷 `"` 是否被跳脫，沒有計算連續反斜線的奇偶；`"\\"` (內容是一個反斜線的字串) 結尾的 `"` 會被當成跳脫，同一行後面的程式碼全被當成字串剝掉。改法只動單行字串狀態：以 `isEscaped` 旗標取代 `previousInString`，遇到 `\` 且尚未跳脫時設為 true，下一個字元無條件消耗並清除旗標；只有未跳脫的 `"` 結束字串；開頭引號重設旗標。與舊行為的差異只在偶數個反斜線後的 `"`。
    - **區塊註解黏合 token**：現行把區塊註解整段刪除、不留邊界，`horizontalSizeClass/* note */as Any` (合法 Swift，註解等同空白) 剝除後變成 `horizontalSizeClassas Any`，`\b` 樣式就比對不到。改為每段區塊註解剝除後留一個空格 (跨行時在註解結束那一行補)。字串字面值在合法 Swift 中兩側不會同時緊貼識別字，剝除後不需補空白。
    - **多行字串的跳脫**：現行 `.tripleQuotedString` 遇到任何 `"""` 就結束字串，沒有辨識跳脫；合法的 `\"""` (內容是三個引號) 會讓字串提前結束、真正的結尾又重新進入字串狀態，之後的程式碼被當成字串剝掉。比照單行字串，在多行字串狀態也以 `isEscaped` 旗標處理反斜線，只有未跳脫的 `"""` 結束字串。
    - **修正前後比對**：以暫時的測試或腳本，對 production 全部 Swift 檔在修正前後各跑一次剝除，逐行比對輸出，預期完全相同 (2026-10-04 grep：production 沒有 `"\\"` 字面值、沒有任何 `/*` 區塊註解、沒有 `\"""`)；另記下每條既有規則的違規數，修正前後必須都不變。有任何差異就停下回報。比對用的暫時程式做完即移除。
- **掃描保證的範圍以正面列舉定義**：規則十一只保證抓到「剝除器有建模的詞法形式」之外的一般程式碼中的引用。剝除器建模的詞法形式只有：`//` 行註解、非巢狀的 `/* … */` 區塊註解、單行 `"…"` 與多行 `"""…"""` 一般字串 (含反斜線跳脫，逐個 Unicode 碼位處理)。**其他任何未建模的詞法形式都不在保證範圍**，會讓剝除器狀態錯置，不只寫在其中的引用，同一行甚至之後幾行的程式碼也可能被漏判或誤判；記在規則十一的文件註解、spec 與 `ios-design-system.md`。已知的例子 (2026-10-04 grep 實測 production 皆 0 處)：
    - **字串內插**：剝除器把內插運算式連同字串一起剝掉，`"\(horizontalSizeClass)"` 這類引用會**漏判**。
    - **原始字串與擴充分隔符號 (`#"…"#`、`#"""…"""#`)**：剝除器不認得分隔符號，原始字串裡的反斜線是一般字元，卻會被當成跳脫；例如 `let pair = (#"\"#, horizontalSizeClass)` 的結尾引號被當成跳脫，字串外的引用也被剝掉而**漏判**，其他情況也可能**誤判**。
    - **正規表示式字面值 (`/…/`、`#/…/#`)**：剝除器不認得 regex literal，`let pair = (/"/, horizontalSizeClass)` 中合法的引號會被當成字串開頭而**漏判**。
    - **巢狀區塊註解**：剝除器遇到第一個 `*/` 就結束註解，`/* 外層 /* 內層 */ horizontalSizeClass */` 中合法註解內的文字會被當成程式碼而**誤判**，反過來也可能讓之後的程式碼被當成註解而漏判。
- **樣式與剝除的正反例**：新增記憶體內 fixture 測試，對同一個樣式與剝除流程驗證會失敗的 `@Environment(\.horizontalSizeClass)`、`.environment(\.verticalSizeClass, .regular)`、`EnvironmentValues` extension 內的 `horizontalSizeClass == .regular`、帶豁免標記的讀取 (水平與垂直各一列，垂直列於 2026-10-06 補上)、`let pair = ("\\", horizontalSizeClass)` (反斜線字串之後的引用)、`horizontalSizeClass/* note */as Any` (區塊註解緊貼的引用)、內容含 `\"""` 的多行字串之後的引用、內容是單獨組合用符號 (U+0301) 的字串之後的引用，以及會通過的註解 (含 `/* horizontalSizeClass */`)、純字串字面值 (含 `"\\"`)、只在多行字串內容中出現的 `horizontalSizeClass` 與 `@Environment(\.blLayoutClass)`。
- **變異驗證**：暫時在 `DashboardView` 加回 `@Environment(\.horizontalSizeClass)`、再改為帶有效豁免理由的同一行，兩次規則十一都失敗並指出該行，且實際掃描檔數大於 0；還原後通過。

### 測試：純規則單元測試、snapshot 與轉向 UI 測試

- `BLLayoutClassTests`：以 Swift Testing 參數化列出水平、垂直各為 `.compact`／`.regular`／`nil` 的九種組合，只有 regular + regular 得到 `.regular`。
- `SnapshotTests.ordersView_寬版多選模式_顯示選取列` 補上 `.environment(\.verticalSizeClass, .regular)`，讓寬版前提不再依賴 snapshot host；既有基準圖必須逐位元相同，不重錄。
- 新增 snapshot (放在拆檔後的訂單 snapshot 測試檔)：訂單頁在水平 `.regular`、垂直 `.compact`、尺寸 956 × 440 (iPhone 17 Pro Max 橫向的點數；依 Pro Max 規格 440 × 956 pt 的估計值，task 1.1 以 UI 測試讀取橫向視窗尺寸實測確認，不符就改用實測值) 時呈現單欄訂單清單與整合篩選鈕；錄製新基準圖前先鎖淺色外觀。第一次執行會錄製並回報失敗，人工確認圖中是 compact 版面後再跑一次通過才算數，未經確認的圖不得當基準。
- 首頁與分析頁的 snapshot (2026-10-06 verify 補修)：
    - 既有 `dashboardView_一般儀表板資料_符合基準圖`、`dashboardView_含進行中開團_顯示進行中的開團區段`、`insightsView_一般洞察資料_符合基準圖` 明確注入水平 `.compact`、垂直 `.regular`，讓窄版前提不依賴 snapshot host；基準圖必須逐位元相同，不重錄。
    - 新增四張：首頁與分析頁各一張寬版 (水平與垂直都 `.regular`、寬 1024，起始高度 768) 與大尺寸 iPhone 橫向 (水平 `.regular`、垂直 `.compact`、寬 956，起始高度 440)。寬版要看得到 hero 與 KPI 並排、類別排行與成本結構並排；橫向要看得到 KPI 在 hero 下方、兩張卡片上下堆疊。
    - 證明排列的卡片在起始高度內露不出來時只加高 (寬度與尺寸分類不變)，實際高度與理由記在 task 下方；高度不影響版面判斷，寬度才決定內容延伸。
    - 首頁兩張新圖的 State 與 `dashboardView_一般儀表板資料_符合基準圖` 相同 (不帶開團)，避開 `BLProgressViewStyle` 標題漏畫的已知雜訊。
    - 錄製流程同訂單新 snapshot：第一次執行錄製並回報失敗，人工確認排列後再跑一次通過。
- 新增 `BLLayoutClassEnvironmentTests`：同一個視窗切換尺寸分類時讀值會更新的實證 (見「版面判斷收成設計系統的 BLLayoutClass 單一入口」)。
- 新增 UI 測試 `OrientationLayoutTests`：
    - 以 `LaunchOptions(seed: .campaignsWithOrders)` 啟動 (預設的 `.default` 是空資料庫，首頁只會顯示 onboarding、分析頁是空狀態，截圖看不出卡片排列)。
    - 轉向前先以 `addTeardownBlock` 註冊轉回直向 (`BLUITestCase` 設了 `continueAfterFailure = false`，寫在方法尾端的還原在失敗時不會執行)，再設 `XCUIDevice.shared.orientation = .landscapeLeft`。
    - **轉向完成條件**：等到 App 視窗 (`app.windows.firstMatch`) 寬大於高，才斷言與截圖；setter 模擬的是實體方向，轉向沒生效時測試會在直向取得 compact 版面而誤判通過。
    - 以 `UIDevice.current.userInterfaceIdiom` 分辨裝置 (UI 測試 runner 跑在同一台模擬器上，測試檔需 `import UIKit`)，不用 `AppNavigator.isSidebarLayout` 分辨，因為那是受測結果。
    - iPhone：先對 `app.tabBars.firstMatch` 做 `waitForExistence` 並斷言存在，再斷言 `AppNavigator.isSidebarLayout == false`；切到訂單分頁後斷言 `BLAccessibilityID.Orders.filterButton` 存在。iPad：斷言側邊欄存在且 `filterButton` 不存在。
    - 截圖附件：首頁等到 KPI 卡 (`BLAccessibilityID.Dashboard.kpiTile(_:)`，可沿用 `DashboardScreen.kpiValue(_:)`) 出現後截圖；分析頁捲到類別排行與成本結構卡片露出後截圖；訂單頁截一張。附件保留在 result bundle 供使用者檢視，並記錄橫向視窗尺寸。
    - 定位一律用 identifier，找不到元素以 `failWithDiagnostics` 回報 (`.claude/rules/ios-ui-tests.md`)。
- 驗收裝置：iPhone 17 Pro Max (橫向水平為 regular 的機型，真正重現原問題)、平常回歸用的 iPhone 17 與 iPad。開工前以 `mobilebuildmcp simulator list` 取得 iPhone 17 Pro Max 的 UDID 並記錄。

### 文件同步

- `apps/ios/README.md`「App 進入點與平台導覽」的版面表與 `OrdersView` 分流說明改寫成「regular 版面 (水平與垂直尺寸分類都是 regular)／compact 版面 (其餘，含 iPhone 橫向)」。
- `.claude/rules/ios-design-system.md`：
    - 「單一來源」加一條：版面判斷只經 `BLLayoutClass`／`blLayoutClass`，production 程式在入口檔以外不引用尺寸分類 (由規則十一守住，不接受豁免標記；字串內插、原始字串與巢狀區塊註解超出掃描保證，見規則十一的文件註解)。
    - 「`DesignSystemSourceScanTests` 以掃描守門上述色彩入口」改寫為涵蓋色彩、幣別、語言與版面入口，並註明豁免標記不適用版面規則。
    - frontmatter `paths` 補上拆出的 `apps/ios/BuyLedgerTests/DesignSystemSourceScanTests+*.swift`，讓單獨修改拆出檔時仍會載入此規則檔。
- `.claude/rules/ios-unit-tests.md`「Snapshot 測試」中「baseline 目前只有 iOS 393×852」改寫為實際存在的尺寸 (含 1024×768 寬版與本次新增的橫向尺寸)。
- `apps/ios/CLAUDE.md`「依賴配置的過渡例外」與「現在時間」過渡例外清單逐條確認：拆檔後宣告 `@Dependency` 的仍是 `OrdersView`、`DashboardView`、`InsightsView` 本身 (抽出的 View 不宣告)，清單不需改；若實作結果不同就同步改寫。

### 六個既有檔整檔對齊 ios-dev-kit 的風格與結構

取代原本 Non-Goals 的「既有檔只審改動行」(使用者 2026-10-04 裁決)。範圍是 `RootView`、`OrdersView`、`DashboardView`、`InsightsView`、`DesignSystemSourceScanTests`、`SnapshotTests` 六個檔，以及本 change 新增或拆出的所有檔：排版、MARK 分區、文件註解、命名、測試三段式命名與 Given／When／Then，以及每檔不含檔頭與空行不超過 300 行。`LocalizationCatalogTests+SourceGuards.swift` 只補路徑清單，整檔檢查目前已是 0 筆 (2026-10-04 實測)，改動後維持 0 筆。

**基準**：以 `reference/style_checks.py` (複製自第 5 步，`B_GROUP` 清空、`SnapshotTests.swift` 移出 `EXISTING_OVER_LIMIT`) 整檔實測共 227 筆，逐筆明細在 `findings.md`。腳本只涵蓋機械規則；`body` 只放大框架、命名語意等由 style agent 逐檔逐條審查。

**拆檔方式** (行數為 2026-10-04 實測；拆法為估計，每個拆檔 task 先在 task 下方記下切分方案與各檔預估行數再動手)：

| 檔案 | 行數 | 拆法 |
|---|---|---|
| `DashboardView` | 694 | 依區段抽成獨立 View 型別 (進行中開團區段、hero 與 KPI、近期訂單等)，`DashboardView` 只留 `body` 組裝與載入狀態切換；估計至少拆成 3 個檔 |
| `InsightsView` | 538 | 依卡片抽成獨立 View 型別 (趨勢、每團毛利、類別、成本結構、熱力圖等)；估計至少拆成 2 個檔 |
| `OrdersView` | 434 | regular 版的清單欄 (清單、標題列、篩選鈕) 與詳情欄 (標題列、狀態與更多選單) 各抽成獨立 View 型別，`OrdersView` 留版面分流與 sheet 掛載 |
| `DesignSystemSourceScanTests` | 467 | 測試本體與比對樣式、掃描輔助各分到 `DesignSystemSourceScanTests+<用途>.swift` extension 檔 (測試檔不是 View，extension 分檔可行)。跨檔使用的輔助方法與型別必須由 `private` 改為 internal (只在測試 target 內可見)，這是跨檔拆分的必要結果；只被同檔使用的維持 `private` |
| `SnapshotTests` | 475 | 依畫面區域拆成 `SnapshotTests+<區域>.swift`，比照既有 `SnapshotTests+Campaigns.swift` |

- View 依 `apps/ios/CLAUDE.md` 不以跨檔 extension 作為第一選擇：抽出的 View 型別接收所需的值、closure 或同一個 Feature 的 store，不把 `private` 的 `@State`／`@Environment` 降為 `internal`。抽出的 View 不宣告 `@Dependency`；需要現在時間的格式化留在原畫面或以參數傳入。
- 抽不到 300 行以下時停下回報使用者，不自行在 `findings.md` 登記行數例外。
- **規則三依賴樣式物件的同一性**：`lineViolates` 以 `pattern === namedHueTokenPattern` 決定是否套用「值位置」判斷，所以各樣式必須維持只建立一次的 stored `static let`；整理 `try!` 等風格項目時不得改成每次建立新物件的 computed property。拆檔時補一組規則三的正反 fixture (值位置的裸色相名會失敗、非值位置不會)，守住這個語意。
- **拆檔與風格整理分兩步**：`DashboardView` 與 `DesignSystemSourceScanTests` 先完成拆檔並驗證畫面或掃描結果不變，再整理其餘風格項目，各自是一個 task，中途中斷也能從檢查點續做。
- **snapshot 基準圖跟著搬**：swift-snapshot-testing 以測試所在檔名決定基準圖目錄 (`__Snapshots__/<檔名>/`)，測試搬到新檔後以 `git mv` 把對應基準圖搬到新目錄，不重錄；搬完舊目錄不得留下孤兒圖，也不得出現新錄製。
- **導覽標題掃描的涵蓋範圍** (3.1、3.2、3.4 都適用)：`LocalizationCatalogTests+SourceGuards` 的根畫面掃描以寫死的路徑清單讀檔；拆檔若把設定根畫面標題 (`rootNavigationTitle`) 的程式碼移到新檔，就把新檔加入清單，確保禁止寫法仍會被抓到。
- 所有搬移只改結構，畫面不變：既有 snapshot 不重錄即通過是主要證據，相關 UI 測試類別再補一次實測。

## Implementation Contract

**行為**：
- iPhone (含 Pro Max 等大尺寸機型) 轉成橫向後：根導覽仍是底部分頁列、沒有側邊欄；訂單分頁是單欄清單，篩選以整合篩選鈕 (`BLAccessibilityID.Orders.filterButton`) 呈現，點列 push 詳情；首頁的 KPI 格維持在 hero 卡下方，分析頁的類別排行與成本結構卡片維持上下堆疊，只是寬度延伸。
- iPad 全螢幕直向與橫向：側邊欄、訂單兩欄、首頁寬版 hero、分析頁並排卡片，皆與現況相同。
- iPad 窄視窗 (水平 compact)：與現況相同的 compact 版面。
- environment 沒有提供尺寸分類 (`nil`) 時一律 compact 版面；任何回報垂直 compact 的視窗 (例如寬而矮的視窗) 也用 compact 版面。
- 同一個視窗的尺寸分類改變時，版面跟著切換。

**介面**：
- `enum BLLayoutClass: Equatable, Sendable { case compact; case regular }`
- `BLLayoutClass.init(horizontal: UserInterfaceSizeClass?, vertical: UserInterfaceSizeClass?)`
- `EnvironmentValues.blLayoutClass: BLLayoutClass` (唯讀，由 environment 的兩個尺寸分類推導)
- `RootView`、`OrdersView`、`InsightsView`、`DashboardSummarySection` 以 `@Environment(\.blLayoutClass)` 取得版面，不宣告 `horizontalSizeClass`／`verticalSizeClass`；判斷名稱為 `DashboardSummarySection.shouldUseWideHero` 與 `InsightsView.shouldUseWideLayout`，`DashboardView` 本身不讀版面 (2026-10-06 依實作校正)。
- `BLLayoutClass` 只遵循 `Equatable`、`Sendable`，不遵循 `CaseIterable` (沒有使用者；`BLLayoutClassTests` 的組合表自行列舉)。
- 規則十一的入口：`DesignSystemSourceScanTests+Scanner.swift` 提供掃描 production 目錄與分類記憶體內原始碼兩種形式，固定 `sizeClassReferencePattern`、排除 `Shared/DesignSystem/Foundations/BLLayoutClass.swift` 並不接受豁免標記；方法名稱由實作決定，測試名稱的第一段跟著改成被呼叫的方法。

**失敗模式**：規則十一在入口檔以外、掃描保證範圍內 (只使用剝除器建模的詞法形式的一般程式碼) 出現尺寸分類引用時失敗 (豁免標記無效)，訊息含檔案與行號；`OrientationLayoutTests` 在 iPhone 橫向出現側邊欄或缺整合篩選鈕時失敗，失敗時附上截圖。

**驗收**：
- `BLLayoutClassTests` 九種組合全綠；`BLLayoutClassEnvironmentTests` 兩組切換序列全綠。
- 規則十一與其正反 fixture 綠燈，且變異驗證 (加回直接讀取、帶豁免理由的直接讀取) 都確實轉紅；剝除器修正前後，production 全部檔案的剝除輸出逐行相同、每條既有規則的違規數不變；新 fixture 在修正前的剝除器上確實失敗 (證明 fixture 守得住修正)，修正後通過。
- `BLLayoutClassEnvironmentTests` 依觀察與等待條件執行，連跑三次結果相同。
- 首頁含進行中開團的 snapshot (拆檔前錄於未改程式) 拆檔後不重錄即通過，UI Automation 實測點選進行中開團進入詳情。
- 既有寬版訂單 snapshot 在補上垂直尺寸分類後基準圖不變；新 snapshot 基準圖經人工確認為 compact 版面。
- 首頁與分析頁三張既有 snapshot 注入尺寸分類後不重錄即通過；四張新 snapshot 經人工確認排列 (寬版並排、橫向堆疊) 後重跑通過。
- 規則十一的正式測試與 fixture 都只經入口呼叫；把入口的豁免設定暫時改成接受豁免時，fixture 的兩列豁免案例都轉紅；在 production 檔暫時加入帶有效豁免理由的垂直尺寸分類讀取時，正式規則十一失敗並指出該行；還原後全綠。
- `OrientationLayoutTests` 在 iPhone 17 Pro Max、iPhone 17、iPad 三台模擬器皆綠，Pro Max 的橫向截圖顯示分頁列與單欄訂單。
- 完整單元測試、iPhone 與 iPad UI 主回歸全綠 (UI 主回歸在 iPad 執行前確認軟體鍵盤可顯示)。單元測試的失敗只有同時符合「列在 `ios-unit-tests.md` 已知雜訊清單」與「方法層單獨重跑轉綠」才可判為雜訊；其餘一律是真失敗，即使開工前的基準就已失敗也一樣，停下回報。
- 以明確的檔案清單 (六個既有檔、所有新檔與拆出的檔，不靠腳本無參數時的 git 狀態) 重跑 `reference/style_checks.py`，核對輸出的檔數等於清單數且 `TOTAL` 為空 (腳本明列不計失敗的代碼除外；腳本印出 `FAIL` 時不會設失敗退出碼，不能只看退出碼)，每檔不含檔頭與空行不超過 300 行；style agent 逐檔逐條審查 0 違規。
- 拆檔前後既有 snapshot 全數不重錄即通過，搬移的基準圖沒有孤兒或新錄製；`LocalizationCatalogTests` 根畫面掃描清單涵蓋設定根畫面標題的所有檔。

**範圍**：
- 範圍內：`BLLayoutClass` 與 environment 讀取、四個畫面改用、規則十一 (含修正共用剝除器的碼位比對、單行與多行字串反斜線判斷、區塊註解邊界)、上述測試、六個既有檔整檔對齊風格與結構 (含拆檔)、README、`ios-design-system.md` 與 `ios-unit-tests.md` 同步、新規格 `adaptive-layout`。
- 範圍內 (2026-10-06 verify／review 補修)：首頁與分析頁 snapshot 的尺寸分類注入與四張新圖、規則十一共用入口與垂直豁免 fixture、移除 `BLLayoutClass` 的 `CaseIterable`。
- 範圍外：Non-Goals 列出的橫向細部排版、其他規格措辭改寫、已登記的過渡例外 (畫面的 `@Dependency`／現在時間、畫面內計算移進 reducer)；`BLProgressViewStyle` 標題漏畫的根治 (本 change 封存後另開 change)；`DashboardOngoingCampaignsSection` 的 `Row`／`rows` 移進 State (第 7 步)；iPad 直向的版面斷言與 `XCUIScreen` 全螢幕截圖 (verify 與 review 提出，使用者未選)。

## Risks / Trade-offs

- [首頁與分析頁在大尺寸 iPhone 橫向不再並排卡片，寬螢幕的資訊密度變低] → 使用者 2026-10-04 明確選擇四處一致；截圖附件供使用者確認觀感。
- [computed `EnvironmentValues` 屬性在尺寸分類變動時沒有更新] → 以 `BLLayoutClassEnvironmentTests` 在同一個視窗切換尺寸分類實證；不成立就停下回報。
- [UI 測試把模擬器留在橫向，影響後續測試的座標互動] → 轉向前以 `addTeardownBlock` 註冊轉回直向，失敗也會執行；`BLUITestCase.setUpWithError` 每條測試開始時也會重設直向。
- [`XCUIDevice` 設定方向後 App 還沒完成轉向，測試在直向取得 compact 版面而誤判通過] → 斷言前等到 App 視窗寬大於高。
- [規則十一沿用的剝除器不是完整的 Swift 詞法分析器，未建模的寫法可能影響之後的程式碼] → 修正碼位比對、單行與多行一般字串的反斜線判斷與區塊註解邊界；掃描保證以剝除器建模的詞法形式正面列舉，其餘一律為已知限制，明列在 spec 與規則文件註解中，已知例子在 production 目前 0 處。
- [iPhone 17 這類標準尺寸機型橫向本來就是 compact，`OrientationLayoutTests` 在平常回歸裝置上無法重現原問題] → 驗收時必跑 iPhone 17 Pro Max；規則本身由 `BLLayoutClassTests` 與新 snapshot 在任何裝置上守住。
- [iPad 窄視窗與全螢幕切換時版面仍會在兩套之間切換] → 與現況相同，不在本 change 範圍。
- [`OrdersView` 整檔對齊後，6b 拆訂單容器時會再重寫一次] → 使用者 2026-10-04 知情選擇照做；6b 以本次拆出的清單欄與詳情欄為起點。
- [拆檔把測試搬到新檔後，snapshot 找不到舊基準圖而錄製新圖並回報失敗；若未審圖就重跑，新圖會被誤當成基準] → 搬測試時同步 `git mv` 基準圖；驗收時確認 `__Snapshots__` 沒有新增未預期的圖、執行結果沒有錄製訊息。
- [首頁「進行中開團」區段沒有 snapshot 也沒有 UI 測試涵蓋，拆檔弄壞顯示或點選接線也不會被發現] → 3.2 拆檔前先在未改的程式上錄一張含進行中開團的首頁 snapshot，拆完不重錄即須通過；另以 UI Automation 實際點選一筆，確認進入開團詳情。
- [拆檔把畫面程式碼移到 `LocalizationCatalogTests` 根畫面清單以外的檔，禁止寫法不再被掃描] → 拆檔 task 同步更新清單，並以暫時加入禁止寫法的變異確認新檔被掃到。
- [抽出的 View 改變了排版或修飾子套用順序] → 既有 snapshot 不重錄即通過才算完成；有差異就修正抽法，不重錄。
