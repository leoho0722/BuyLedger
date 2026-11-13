## Context

`BuyLedgerAccessibilityIDs/` 同時編入 App 與 UI 測試 target，`BLAccessibilityID` 依區域分成 8 個檔案。`load-state-identifier-literals` (2026-11-10) 把定義寫法收斂成兩種：固定 identifier 寫完整字串字面值；需要組出的只能由 `BLAccessibilityID.swift` 的 `option` (`"\(prefix).\(key)"`)、`row` (`"\(prefix):\(key)"`)、`indexed` (`"\(prefix).index.\(index)"`) 在字面值前綴之後接最後一段。規則寫在 `.claude/rules/ios-ui-tests.md`「定位與 identifier」，目前只靠審查維持。

主對話 2026-11-13 以暫時腳本 (不進 repo) 量測現況，提案審查的四位審查者各自重算，結果相同：

- 178 個 `static let`，全部是單一字串字面值 (其中 `LookupManagement.paymentMethodCashOnDeliveryToggle` 的值寫在下一行)。
- 37 個 `static func`：3 個組字串函式，加上 34 個本體恰為一次 `option`／`row`／`indexed` 呼叫的包裝函式。前綴全是字面值，第二個引數是參數或成員路徑；其中 5 個巢狀型別自己宣告了同名的 `static func row(...)`。
- 沒有 `var`，巢狀列舉的 case 都沒有明確 raw value；組字串函式本體之外沒有其他字串字面值。
- 固定值的段數：2 段 98 個、3 段 75 個、4 段 4 個、1 段 1 個 (`BackButton`)；組出前綴：2 段 13 個、3 段 19 個、4 段 2 個。除 `BackButton` 外全是 ASCII lowerCamelCase 片段，第一段也都與所屬巢狀型別名稱一致 (`AISummary` 對應 `aiSummary`)。
- 固定值之間、前綴之間 (不分函式) 0 重複；以「前綴加分隔符號」比較，0 個固定值或前綴落在另一個前綴之下。
- UI 測試 7 個檔案共 16 處以空字串呼叫 ID 函式，取得前綴做 `BEGINSWITH` 查詢 (例如 `Orders.row(orderID: "")`；`OrdersScreen` 另以 `dropFirst(prefix.count)` 取回訂單編號)。
- App 與 UI 測試 target 在 `BuyLedgerAccessibilityIDs/` 之外沒有擴充 `BLAccessibilityID` (2026-11-13 以 `git grep` 查得 0 處)。

系統指定、App 無法改名的 identifier 有兩種放法並存 (fable-arch-reviewer 指出，主對話以 `git grep` 核對)：

- `BLAccessibilityID.Common.backButton` (`BackButton`) 在共用命名空間，App target 0 處引用，UI 測試 7 個檔案各 1 處引用。
- UI 測試另有 3 處直接寫系統字面值：`XCUIApplication+TextInput.swift` 的 `popoverDismissRegionIdentifier` (`PopoverDismissRegion`)、`AppNavigator.rootSidebarToggle()` (`ToggleSideBar` 與 `ToggleSidebar` 兩種大小寫都接受)、`OrderRegularColumnScopeTests.sidebarColumnFrame` (`ToggleSidebar`)。

載入失敗重試鍵的值：總覽、分析、訂單清單、開團清單都是 `<容器>.loadFailure.retryButton`，只有 `Customers.listLoadFailureRetryButton` 是 `customers.list.loadFailureRetryButton`。這個值只定義在 `BLAccessibilityID+More.swift`，App (`CustomersView`) 與 UI 測試 (`RootNavigationScreen`、`CustomersLoadStateTests`) 都經常數引用。匯率與報價頁的 `fx.retryButton`、`quote.retryButton` 放在狀態橫幅內、與另一段失敗訊息並列，不是載入失敗容器的子元素，不屬同一種寫法。

現有檢查只有 `BLAccessibilityIDTests` 的 `staticIdentifiers_靜態識別碼_皆為ASCII字元`，手列 8 個常數。規格 `ui-test-element-identity` 的命名格式寫 `feature.screen.element` 加可選第四段，與 98 個 2 段的現況不符；「固定 feature 字彙」沒有定義在任何地方。

`BuyLedgerTests/Guards/` 已有多組原始碼掃描守門，共用工具在 `Guards/Scanning/`：`SwiftSourceFiles` (列檔與相對路徑)、`DependencyConventionLexing.blankedCommentsAndStrings(in:)` (把註解、字串與正規表示式的內容連同分隔符號換成空白，保留換行與字元位置；處理巢狀區塊註解、raw string、多行字串與巢狀插值)、`String.literalMatches` (不處理巢狀區塊註解與 `"""`／`#"`)。`.claude/rules/ios-unit-tests.md` 規定共用掃描型別放 `Guards/Scanning/`、各守門自己的掃描型別依職責命名。

## Goals / Non-Goals

**Goals:**

- 掃描 `BuyLedgerAccessibilityIDs/` 的原始碼，之後新增的 identifier 不必改測試就受檢；命名空間內只接受封閉清單內的寫法，看不懂的寫法讓測試轉紅。
- 檢查定義形式、宣告位置、形狀 (段數與第一段)、只含 ASCII、值不重複、查詢前綴不重疊與空掃描，違規訊息指出檔案、行號、宣告與值。
- 每條規則都有合成原始碼證明會失敗。
- 共用命名空間只放 App 指定的 identifier；系統指定的集中到 UI 測試端一處。
- 客戶頁載入失敗重試鍵與其他四個載入失敗重試鍵寫法一致。
- 規格的命名格式、常數單一來源與守門一致。

**Non-Goals:**

- 除 `Customers.listLoadFailureRetryButton` 外，不改任何 App 指定 identifier 的值；系統 identifier 只搬移宣告位置、值不變。
- 不檢查執行期才決定的 key：`row` 的業務鍵依規格保留原文 (可能非 ASCII)，`option` 收到的 `String` 參數來自 App 端的列舉或資料。
- 不新增「App 與 UI 測試不得內聯 identifier 字面值」的掃描：App 端 `accessibilityIdentifier("` 0 處 (2026-11-13 `git grep`)，UI 測試的系統字面值本次收進 `SystemAccessibilityID`；內聯掃描另屬一條規則，記為後續。例外：verify 後使用者 2026-11-13 選擇先加窄規則，系統 identifier 的值只能寫在 `SystemAccessibilityID.swift` (受檢值由掃描該檔取得)，App 指定 identifier 的內聯掃描仍留給後續。
- 不掃描單元測試 target：它的擴充不會編入 App 或 UI 測試，UI 測試查不到。
- 不檢查 `element` 段是否描述語意角色、是否編碼暫態：無法機械判定，維持審查。
- 不引入 SwiftSyntax 等新套件，也不改 `Guards/Scanning/` 的共用工具。
- 不修改規格中 `Identifiers for dynamic collections` 的示例表 (`orderEdit.photo.thumbnail.index.2` 與實際的 `orderEdit.photoThumbnail.index.<n>` 不同，但兩者都符合新格式，示例只示意三種集合的結尾)。
- 不改匯率與報價頁的 `fx.retryButton`、`quote.retryButton` (見 Context)。

## Decisions

### 以原始碼掃描取得受檢 identifier

守門讀 `TestPaths.iosRoot` 下 `BuyLedgerAccessibilityIDs/` 的全部 `.swift`，由掃描結果決定受檢對象。規格 `test-guard-effectiveness` 要求證明「沒有某類缺陷」的守門以掃描取得對象；Swift 也無法在執行期列舉型別的 `static let`。

替代方案：手列清單 (現有 ASCII 測試的寫法，新增的常數不受檢)；SwiftSyntax 解析 (要為測試 target 直接連結新套件，屬技術選型，且其他守門都以文字掃描實作)。兩者不採。重新評估 SwiftSyntax 的條件 (5.1 依 t1p 建議改為可判定，主對話採納)：(a) 擴充接受清單需要改宣告切分或開啟新宣告的關鍵字 (例如接受屬性標記、`#if`)，不只是新增一種比對；(b) 另一個守門需要記號與宣告切分這一層；(c) 正式原始碼出現宣告切分造成的誤判。屆時評估的事實：swift-syntax 已是 TCA 巨集的傳遞相依 (在 `Package.resolved`)，連進 `BuyLedgerTests` 仍要為模擬器建置 (耗時未量測)；本 change 的合成案例可直接當改寫的回歸套件。是否引入由使用者決定。

### 宣告層級封閉的定義形式

命名空間內每個宣告都必須是下表「接受」的寫法之一，其餘宣告與其他位置的字串字面值一律判為定義形式違規。從宣告出發而不是從字面值出發，沒有字面值的寫法 (別名屬性、包裝其他包裝函式、自行串接) 也會被擋下 (t1n 與 fable-arch-reviewer 指出原設計會漏判，主對話採納)。

| 寫法 | 結果 |
| --- | --- |
| `static let <名稱> = "<字面值>"`，可帶 `: String` 型別標註，等號後可換行，字面值後可接行尾 `//` 或 `/* */` 註解 | 接受，固定值 |
| 巢狀型別內 `static func <名稱>(<參數>) -> String { <組字串函式>("<前綴>", key: <運算式>) }` (或 `index:`)，參數與本體之間恰為 `-> String`，組字串函式可帶 `BLAccessibilityID.` 限定，呼叫可跨行 (`(` 後換行、每個引數一行)；第二個引數是識別字或成員路徑，不含字串字面值 | 接受，組出前綴 |
| 直接宣告在 `extension BLAccessibilityID` 內的 `static func option`／`row`／`indexed`，每個名稱跨檔只宣告一次，參數與本體之間恰為 `-> String`，本體恰為一個單行字串模板、插值內沒有字串字面值 | 接受，組字串函式本身 |
| 巢狀 `enum`，遵循清單只能是 `String`、`Sendable`，只含不指定 raw value 的 `case` | 接受 |
| 字面值含插值 (組字串函式的模板除外)、raw string、多行字串 | 拒絕 |
| `static let` 右側不是單一字面值 (串接、引用其他常數、呼叫) | 拒絕 |
| `var` (含 computed property)、`subscript` | 拒絕 |
| `static func` 本體不是恰好一次組字串呼叫 (包裝其他包裝函式、自行串接、多個敘述) | 拒絕 |
| 組字串呼叫的前綴不是單一字面值 | 拒絕 |
| 組字串函式本體多出其他敘述或字面值 | 拒絕 |
| `case` 指定明確 raw value | 拒絕 |
| 巢狀 `enum` 遵循 `String`、`Sendable` 以外的協定或型別 (範圍外的協定擴充可藉此注入成員) | 拒絕 |
| 任何深度的巢狀型別名稱為 `BLAccessibilityID` (會遮蔽限定呼叫) | 拒絕 |
| 包裝函式以未限定的 `option(`／`row(`／`indexed(` 呼叫，而同一個所屬型別 (跨檔、含更深的巢狀型別) 宣告了同名函式，或函式自己的參數區出現同名識別字 (保守判定，不分析解析結果) | 拒絕 |
| 組字串函式同名重載 (每一處都點名)、多行模板、插值內含字面值 | 拒絕 |
| 函式帶 `async`／`throws`，或回傳型別不是 `String` | 拒絕 |
| 以屬性標記 (`@…`) 或存取修飾詞開頭的宣告、`#if` 包住的宣告、同一行以分號串接的宣告、明寫 `return` 的本體 | 拒絕 |

函式宣告 `func option(`／`func row(`／`func indexed(` 不算呼叫：5 個巢狀型別自己宣告了 `static func row(...)` (主對話與 t16 指出)。定義形式違規的宣告不進入其他規則的檢查清單，所以一處違規只回報一條定義形式違規 (t16 建議，主對話代選)。

新寫法真的需要時 (例如列舉明確 raw value)，先修改規格 `ui-test-element-identity` 的接受清單，再擴充掃描規則與案例後使用 (5.1 依 t1p 建議補上規格，主對話採納)。這是刻意的嚴格度 (主對話代選)：看不懂的寫法讓測試轉紅，比靜默略過安全。

### 以遮罩後的結構切分宣告

以 `DependencyConventionLexing.blankedCommentsAndStrings(in:)` 取得保留位置的結構視圖：在視圖上切分宣告、配對大括號與括號、找出 `static let`／`static func`／`var`／`case`／組字串呼叫；字面值的起訖與內容回到原文同一位置讀取 (視圖中被遮成空白、原文以 `"` 或 `#"` 開頭的區段是字串，以 `//`、`/*` 開頭的是註解)。這個工具處理巢狀區塊註解、raw string 與多行字串，能免去行號對齊兩種工具的需要 (t16 建議、t1n 指出 `literalMatches` 不支援巢狀區塊註解，主對話代選)。

替代方案：`String.literalMatches` 加 `SwiftSourceStripping.stripCommentsAndStrings` (原設計)。前者不處理巢狀區塊註解、`"""` 與 `#"`；後者逐行處理且會刪字元，兩者只能以行號對齊。不採。

### 所屬型別取直接位於 BLAccessibilityID 之下的巢狀型別

宣告所屬的型別是「直接位於 `BLAccessibilityID` 之下、包含這個宣告的巢狀型別」：寫在 `extension BLAccessibilityID {` 內直接宣告的 `enum <名稱>` 裡 (含更深的巢狀型別)，或寫在 `extension BLAccessibilityID.<名稱> {` 裡 (`BLAccessibilityID+Orders.swift` 已 365 行，最可能以此拆檔；fable-arch-reviewer 指出，主對話代選支援)。不在任何巢狀型別內的固定值或組出前綴判為第一段違規。

型別名稱轉 lowerCamelCase 的規則：第一個字母轉小寫；名稱開頭有多個連續大寫字母、後面接小寫字母時，除最後一個外都轉小寫 (最後一個是下一個字的開頭)；開頭連續大寫字母後面沒有小寫字母時全部轉小寫。

| 型別名稱 | 第一段 |
| --- | --- |
| `Orders` | `orders` |
| `OptionPicker` | `optionPicker` |
| `AISummary` | `aiSummary` |
| `Fx` | `fx` |

決策來源：使用者 2026-11-13 明確回覆採納「第一段等於所屬巢狀型別名稱」(主對話推薦)。

### 形狀規則採 2 至 4 段並修改規格

固定值與組出前綴都必須以 `.` 分隔、2 至 4 段、每段第一個字元是小寫字母、其餘是字母或數字。形狀只看段落結構，字母與數字以 Unicode 類別判斷，字元集交給「只含 ASCII」檢查，兩條規則互不重疊。前綴的段數不含之後組上的 key 或 `index.<n>`。`:` 只會由 `row` 在執行期組出，固定值與前綴都不得含 `:`。

規格 `ui-test-element-identity` 的 `Identifier naming scheme` 同步改為 2 至 4 段 (screen 段在單一畫面的功能可省略)，feature 段改為所屬巢狀型別。決策來源：使用者 2026-11-13 明確回覆採納 (主對話推薦)。替代方案：依原規格限 3 至 4 段 (98 個值要改名並同步引用處，遠超出守門範圍)、不限段數 (5 段以上的固定值失去約束)，不採。

### 系統 identifier 收到 UI 測試端

**Supersedes**: accessibility-identifier-scan-guard / 例外表放在守門測試內

新增 `BuyLedgerUITests/Support/SystemAccessibilityID.swift`，以無 case 的 enum `SystemAccessibilityID` 宣告 4 個系統 identifier：

| 常數 | 值 | 取代 |
| --- | --- | --- |
| `backButton` | `BackButton` | `BLAccessibilityID.Common.backButton` |
| `popoverDismissRegion` | `PopoverDismissRegion` | `XCUIApplication+TextInput.swift` 的 private `popoverDismissRegionIdentifier` |
| `sidebarToggleButton` | `ToggleSidebar` | `AppNavigator.rootSidebarToggle()` 與 `OrderRegularColumnScopeTests.sidebarColumnFrame` 的字面值 |
| `sidebarToggleButtonAlternate` | `ToggleSideBar` | `AppNavigator.rootSidebarToggle()` 的字面值 |

刪除 `BLAccessibilityID.Common.backButton`，UI 測試 7 個引用處改引用 `SystemAccessibilityID.backButton`；`rootSidebarToggle()` 仍接受兩種大小寫、順序不變，`sidebarColumnFrame` 仍只比對 `ToggleSidebar`，查詢行為都不變。共用命名空間因此只剩 App 指定的 identifier，守門不需要例外表，`BackButton` 依一般規則會被判違規。

決策來源：fable-arch-reviewer 提出並傾向此案，主對話推薦，使用者 2026-11-13 明確回覆採納。

替代方案：維持例外表 (只收 `BackButton`)，另外 3 處留待 UI 測試規範修正再處理。到時若改為收到 UI 測試端，例外表、例外失效規則、規格中的例外段落都要再拆，不採。

### 客戶頁重試鍵與其他載入失敗重試鍵一致

`Customers.listLoadFailureRetryButton` 的值改為 `customers.list.loadFailure.retryButton`。App 與 UI 測試都經常數引用，只改定義這一行；它是 `customers.list.loadFailure` 容器內的重試鍵，與其他四個重試鍵同為「容器後接 `.retryButton`」。決策來源：使用者 2026-11-13 提出。

### 範圍外的擴充判違規

守門另外掃描 App target (`BuyLedger/`) 與 UI 測試 target (`BuyLedgerUITests/`) 的 `.swift`：任何 `extension BLAccessibilityID` (含 `extension BLAccessibilityID.<名稱>`) 或名為 `BLAccessibilityID` 的 `enum`／`struct`／`class`／`actor`／`protocol`／`typealias` 宣告出現在 `BuyLedgerAccessibilityIDs/` 之外，判為宣告位置違規。否則在範圍外新增的 identifier 不會進入這組守門 (t9 指出，主對話代選以掃描關閉而非只寫規則)。反引號包住的名稱 (`` extension `BLAccessibilityID` ``)、`typealias` 右側任一處出現 `BLAccessibilityID` (含 `(BLAccessibilityID)`、`Same<BLAccessibilityID>`)、`extension` 到第一個 `{` 之間任一處出現 `BLAccessibilityID` (含 `where Self == BLAccessibilityID.Orders`) 一併判違規 (5.1 三輪 t17 指出，主對話採納)。`typealias` 的右側到括號外的換行、下一個開啟宣告的關鍵字或大括號為止，換行處的前一個或後一個記號是 `.` 時視為同一個名稱的接續。停止線 (t1p 第三輪提出；使用者 2026-11-13 第三輪後選擇的收尾方式含寫入停止線，第四輪後再選擇把 spec 收窄到同一範圍)：宣告位置規則只保證本段列出的寫法，其他轉名途徑不由守門偵測、留給審查，記為已知限制 (見 Risks)，不再逐一追加 (「不偵測」而非「允許」，第五輪 t1p 指出、主對話代選)；要防的是在功能目錄直接擴充命名空間這類無意的寫法。兩個範圍外目錄各自要讀到檔案，目錄失效時測試轉紅 (5.1 t17 指出、主對話以變異實測：目錄改成不存在的名稱時 15 個測試全過)。

### 查詢前綴取代原始前綴比較

每個組出前綴 P 的查詢前綴 Q(P) 是 P 接上其組字串函式插在變動段之前的分隔符號 (現值：`option` 為 `.`、`row` 為 `:`、`indexed` 為 `.index.`)，也就是 UI 測試以空 key 呼叫函式得到的值。規則：

- 任何固定值不得以任何 Q(P) 開頭。
- 對任兩個不同的組出前綴 P1、P2，Q(P1) 不得以 Q(P2) 開頭 (有序對，含相等)。
- 所有組出前綴之間 (不分函式) 不得相同。
- 固定值與某個組出前綴完全相同不判違規：前綴查詢以 Q(P) 進行，不會誤中該固定值 (t8 建議寫明)。

原設計只比「Q 是否以 P 加 P 的分隔符號開頭」，`option("x.y.index")` 與 `indexed("x.y")` 的查詢前綴同為 `x.y.index.`，卻判通過 (t16、t1n 與 fable-arch-reviewer 指出，主對話採納)。決策來源：「前綴之間也檢查」為使用者 2026-11-13 明確回覆採納 (主對話推薦)；改用查詢前綴比較為主對話採納審查建議。

### 掃描器只處理文字

`AccessibilityIdentifierScanner` 與拆出的解析、規則型別都只 import Foundation，輸入是三樣東西：命名空間目錄的「相對路徑與原文」陣列、範圍外目錄的「相對路徑與原文」陣列、三個組字串函式的分隔符號。讀檔、決定根目錄、向 production 取分隔符號都放在 `AccessibilityIdentifierScanTests` (fable-arch-reviewer 建議，比照 `Guards/` 既有 `*Scanner.swift` 只 import Foundation)。

合成案例傳入字面值分隔符號 (`.`、`:`、`.index.`)，不從 production 取得，`row` 改分隔符號時合成案例的預期不會跟著漂移。正式掃描測試以 `@testable import BuyLedger` 呼叫 `BLAccessibilityID.option("", key: "")`、`row("", key: "")`、`indexed("", index: 0)` 去掉結尾 `0` 取得分隔符號，與 UI 測試以空字串取前綴同源；另一條測試釘住三個分隔符號依序為 `.`、`:`、`.index.`，讓函式格式變更成為有意識的決定。

### 以合成原始碼證明每條規則會失敗

每筆違規案例宣告預期的規則集合，斷言回報的規則集合與之相等；每條規則至少有一筆只破壞該規則的案例，證明它能單獨失敗。合規案例斷言沒有違規。合成案例放 `AccessibilityIdentifierScanCases.swift`，比照 `ActionGroupingScenarios.swift` 的拆法。空掃描另有三筆：空輸入、有檔案但沒有固定值、有固定值但沒有組出前綴 (t16 與 t9 指出原設計缺這三筆)。

### 刪除手列的 ASCII 測試

`BLAccessibilityIDTests` 的 `staticIdentifiers_靜態識別碼_皆為ASCII字元` 由掃描式守門取代，在新守門通過後刪除。其餘 7 個測試函式 (組字串函式、`tab`、`kpiTile`、`selectedItem`、分頁鍵) 驗證函式輸出，不受影響。決策來源：使用者 2026-11-13 明確回覆採納 (主對話推薦)。

### 驗證範圍

- 每個 task 跑改到的測試類別；勾最後一個 task 前在 iPhone 17 (iOS 26.5) 跑完整 `BuyLedgerTests`。
- 主對話在正式原始碼上做變異檢查，確認守門讀的是真實檔案 (見 Implementation Contract)。
- 系統 identifier 只搬位置、客戶頁重試鍵只改值，引用處都經常數，編譯即可確認引用成立；UI 只跑代表性回歸 (主對話代選)，挑在斷言或 helper 中真正查詢這些 identifier 的類別，兩台各跑一次：
  - `KeyboardDismissTests` (數字鍵盤等待會查 Popover 關閉區域；iPad 本來就要先跑)。
  - `MoreNavigationSmokeTests`、`NavigationScenarioUITests` (直接以 `backButton` 查詢)。
  - `LaunchSmokeTests` (經 `AppNavigator.rootSidebarToggle()`)、`OrderRegularColumnScopeTests` (`sidebarColumnFrame`)。
  - `CustomersLoadStateTests`、`CustomersTests` (客戶頁重試鍵與 `RootNavigationScreen` 的「更多」就緒判斷)。
- 建置與測試由主對話執行，同一時間只跑一組；實作者交回前只跑 `swiftc -parse`。

### 分支

apply 前從 `main` 開新分支 `features/accessibility-identifier-scan-guard` (主對話代選)。

## Implementation Contract

**檔案與型別** (型別內部結構可由實作者調整，測試名稱、檔案位置、規則與違規訊息內容依此)：

- `BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierScanner.swift`：`AccessibilityIdentifierScanner`，只 import Foundation，提供：
  - 由命名空間的「相對路徑與原文」陣列產生定義清單 (固定值：所屬型別、常數名稱、值、路徑、行號；組出前綴：所屬型別、包裝函式名稱、組字串函式種類、值、路徑、行號) 與定義形式違規。
  - 由範圍外的「相對路徑與原文」陣列產生宣告位置違規。
  - 由定義清單與分隔符號產生形狀、第一段、只含 ASCII、值重複、前綴重疊、空掃描違規。
  - 違規描述：每筆一行，格式為 `<相對路徑>:<行號> <型別>.<名稱> "<值>" <規則說明>`，行號 1 起算，規則說明用正體中文 (例如「與 BLAccessibilityID+Orders.swift:16 同值」「落在查詢前綴 orders.list.row: 之下」)；多筆依相對路徑再依行號排序，輸出可重現。組出前綴的 `<名稱>` 是包裝函式名稱 (例如 `Orders.statusChip`)。
- 同目錄拆出的獨立型別，都只 import Foundation (5.1 使用者 2026-11-13 選擇現在拆，依 t1p 與 t9 的建議)：記號、空隙分類與宣告切分 (`AccessibilityIdentifierSourceModel`)、一個宣告的記號視圖 (`AccessibilityIdentifierDeclaration`)、命名空間宣告解析與定義形式違規 (`AccessibilityIdentifierDeclarationParser`)、範圍外宣告位置檢查 (`AccessibilityIdentifierLocationChecker`)、定義清單的規則檢查 (`AccessibilityIdentifierRules`)。`AccessibilityIdentifierScanner` 只留進入點 (`scan`、`describe`) 與對外型別 (`Rule`、`SourceFile`、`Separators`、`ScanResult` 與其定義清單、`Violation`)。
- `BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierScanCases.swift`：合成原始碼案例。
- `BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierScanTests.swift`：讀檔、根目錄、分隔符號與下列測試。
- `BuyLedgerUITests/Support/SystemAccessibilityID.swift`：見「系統 identifier 收到 UI 測試端」。

**規則** (違規種類)：

| 規則 | 違規條件 |
| --- | --- |
| 定義形式 | 宣告或字面值不在「宣告層級封閉的定義形式」的接受清單 |
| 宣告位置 | App 或 UI 測試 target 在 `BuyLedgerAccessibilityIDs/` 之外擴充或宣告 `BLAccessibilityID` |
| 系統 identifier 字面值 | `SystemAccessibilityID.swift` 以外的 App 或 UI 測試檔，出現與該檔宣告值完全相同的字串字面值 (verify 後新增) |
| 形狀 | 固定值或前綴不是 2 至 4 段、每段以小寫字母開頭且只含字母或數字 (Unicode 類別) |
| 第一段 | 第一段不等於所屬型別的 lowerCamelCase，或沒有所屬型別 |
| 只含 ASCII | 固定值或前綴含非 ASCII 字元 |
| 值重複 | 兩個固定值相同，或兩個組出前綴相同 (不分函式)；違規描述列出兩處 |
| 前綴重疊 | 固定值以某個查詢前綴開頭，或某個查詢前綴以另一個查詢前綴開頭 |
| 空掃描 | 命名空間沒有檔案、沒有固定值或沒有組出前綴；範圍外目錄沒有檔案；系統 identifier 檔不存在或沒有宣告值 |

**測試** (Swift Testing，名稱依 `<方法>_<情境>_<預期>`、後兩段正體中文，doc comment 以「驗證」開頭，Given／When／Then)：

- 正式原始碼，每條規則一個測試，斷言違規為空並在訊息附違規描述：定義形式、宣告位置、形狀與第一段 (可合為一條)、只含 ASCII、值重複、前綴重疊、空掃描。
- 分隔符號：取得的三個分隔符號依序為 `.`、`:`、`.index.`。
- 合成違規案例 (參數化)：每筆宣告預期的規則集合，斷言回報的規則集合與之相等；每條規則至少一筆只破壞該規則的案例。至少涵蓋：
  - spec 各示例表中判為 fails 的列 (同時違反兩條的列，例如含 `:` 又落在 `row` 查詢前綴之下，或 `index.0` 以數字開頭又落在 `indexed` 查詢前綴之下，預期集合寫兩條)。
  - 不同函式傳入相同前綴。
  - `option("x.y.index")` 與 `indexed("x.y")` 查詢前綴相同。
  - 範圍外檔案的 `extension BLAccessibilityID` 與 `extension BLAccessibilityID.Orders`。
  - 不在任何巢狀型別內的 `static let`。
  - 空掃描三筆：空輸入、有檔案但沒有固定值、有固定值但沒有組出前綴。
- 合成合規案例 (參數化)：spec 示例表中判為 passes 的列、doc comment 與巢狀區塊註解內含引號、大括號與 identifier 字樣、`extension BLAccessibilityID.Orders` 拆檔、巢狀型別宣告同名的 `static func row(orderID:)`、只含 case 的巢狀列舉；斷言沒有違規。

**驗收**：

- 新守門的全部測試在 iPhone 17 (iOS 26.5) 通過，實際執行數大於 0；正式原始碼的違規為 0，主對話把掃到的檔案數、固定值數、組出前綴數記進本檔「實作與驗證」(預期 8 檔、177 個固定值 (刪除 `backButton` 後)、34 個組出前綴，不同時先查原因)。
- 變異檢查 (主對話執行，每次只做一項，確認後還原並比對檔案雜湊)：
  - 把 `Orders.listEmptyState` 的值暫改為 `orders.list.root` → 只有值重複測試失敗，訊息列出兩處。
  - 在 `Orders` 暫加 `static let probe = "orders.list.row:probe"` → 形狀與前綴重疊測試失敗。
  - 把 `Dashboard.loading` 暫改為 `"dashboard.\("loading")"` → 只有定義形式測試失敗。
  - 在 `Dashboard` 暫加 `static func recentOrderAlias(orderID: String) -> String { recentOrderRow(orderID: orderID) }` → 只有定義形式測試失敗。
  - 在 `apps/ios/BuyLedger/App/BuyLedgerApp.swift` 檔尾暫加 `extension BLAccessibilityID {}` → 只有宣告位置測試失敗。
- 系統 identifier：`apps/ios` 內 `Common.backButton` 0 處；`BackButton`、`PopoverDismissRegion`、`ToggleSidebar`、`ToggleSideBar` 的字串字面值只出現在 `SystemAccessibilityID.swift`。
- 客戶頁重試鍵：`apps/ios` 內字串 `customers.list.loadFailureRetryButton` 0 處。
- 刪除手列測試後，`BLAccessibilityIDTests` 的測試函式由 8 個減為 7 個 (以 `git diff` 確認)，xcresult 的案例數由 18 減為 10，全部通過。
- 「驗證範圍」列出的 UI 類別在 iPhone 17 (iOS 26.5) 與 iPad Air 11-inch (M4) (iPadOS 27.0) 通過 (依版面宣告略過的既有案例照舊略過)，每個類別至少在一台的實際執行數大於 0。
- 勾最後一個 task 前，完整 `BuyLedgerTests` 在 iPhone 17 (iOS 26.5) 0 失敗 (既有標為已知問題的預期失敗照舊)，snapshot 不重錄。
- `.claude/rules/ios-ui-tests.md` 只有「文件同步」列出的兩處變更；`apps/ios/README.md` 只改 `Guards/` 那一行。

**文件同步**：

`.claude/rules/ios-ui-tests.md`「定位與 identifier」中，「在 `BuyLedgerAccessibilityIDs/` 定義常數時…」子 bullet 之後，補一個同層子 bullet (4 空格縮排)：

```markdown
    - 固定值與前綴用 2 至 4 段 lowerCamelCase，第一段是所屬巢狀型別名稱 (如 `AISummary` → `aiSummary`)；定義形式、宣告位置、形狀、只含 ASCII、值不重複、不落在其他前綴之下都由 `AccessibilityIdentifierScanTests` 掃描守門，掃描不認得的新寫法先修改 spec `ui-test-element-identity` 的接受清單，並擴充掃描規則與案例再用。系統指定、App 無法改名的 identifier 不進 `BuyLedgerAccessibilityIDs/`，集中在 UI 測試 `Support/SystemAccessibilityID.swift`，其他檔不寫這些值的字面值 (同一組掃描守門)。
```

同檔「系統返回鍵帶語言無關的 identifier `BackButton` (`Common.backButton`)」改為 `(SystemAccessibilityID.backButton)`。

理由：第一段規則、封閉寫法與系統 identifier 的位置讀 ID 檔看不出來；刪掉這條時，之後的實作可能把系統 identifier 加回共用命名空間，或為了讓新寫法通過而放寬掃描。

`apps/ios/README.md` 專案結構中 `Guards/` 那一行的多檔守門清單，依字母順序把 `AccessibilityIdentifier` 放在最前 (`ActionGrouping` 之前)。

**範圍外**：`BuyLedgerAccessibilityIDs/` 只改 `BLAccessibilityID+Common.swift` (刪 `backButton`) 與 `BLAccessibilityID+More.swift` (改一個值)；App target 不改；UI 測試只改「系統 identifier 收到 UI 測試端」列出的引用處；`Guards/Scanning/` 的共用工具只呼叫、不改 (需要改時停下回報，由主對話判斷)。

## Risks / Trade-offs

- [文字掃描認不得罕見語法 (巨集、屬性包裝器)] → 不在接受清單內，一律判為定義形式違規，測試轉紅，不會靜默略過。
- [封閉清單擋下合理的新寫法 (例如列舉明確 raw value)] → 依「宣告層級封閉的定義形式」先擴充掃描規則；規則檔寫明掃描不認得時先擴充。
- [遮罩後結構與原文位置對不上，字面值讀錯] → 遮罩工具保留字元位置與換行；合規案例含巢狀區塊註解、doc comment 內的引號與大括號。
- [掃描器重做了一部分編譯器已知的資訊，是手寫的封閉文法辨識器：1.1 完成時 1577 行 (程式碼約 1009、doc comment 383、空行 176；記號模型約 455、宣告文法約 436、規則約 229 行)，遠超出依 `ActionGroupingScanner` 類推的 300 行估計，差距來自要正面辨識每種接受的宣告、其餘全拒 (t1p 量測)] → 5.1 拆成進入點、記號模型、宣告視圖、宣告解析、範圍外位置檢查與規則六個型別 (5.1 四輪修正後六檔共 2005 行；verify 後加系統字面值檢查，七檔共 2211 行，程式碼約 1440 行)；只認 ID 檔實際使用的幾種寫法，寫法改變時守門轉紅提示更新；SwiftSyntax 的重新評估條件見「以原始碼掃描取得受檢 identifier」。
- [第一段規則讓跨功能共用元件必須宣告在對應型別] → 現況已全部符合；共用元件放 `Common` (`common.*`) 或自己的型別 (如 `OptionPicker`)。
- [4 段上限沒有餘裕：現有 4 個固定值與 2 個前綴已是 4 段] → 更深的結構以 camelCase 併段；真的需要 5 段時先修改規格。
- [系統 identifier 搬移後，有人在 UI 測試再內聯系統字面值] → 規則檔寫明集中位置；內聯掃描記為後續。
- [宣告位置規則只認「範圍外的擴充判違規」列出的寫法 (extension 標頭、typealias 右側、同名型別宣告)，其他轉名途徑不會轉紅] → 停止線，使用者 2026-11-13 決定並同步收窄 spec；新增擴充命名空間的方式若在正式原始碼出現，再擴充規則與案例。
- [範圍外以隱含遵循 (`Sendable`、`Equatable`) 的協定擴充宣告 `static func option(_:key:)` 等同名函式，可遮蔽命名空間內未限定的組字串呼叫 (5.1 第二輪 t17 推演，未實測)] → 文字掃描無法從名稱判定，範圍外也已有同名但不同標籤的函式 (`BLUITestConfiguration.option(for:in:)`)，記為已知限制 (使用者 2026-11-13 決定)；帶 `where … BLAccessibilityID` 的形式由宣告位置規則擋下。
- [代表性 UI 回歸漏掉其他引用者] → 其他引用者經同一個常數取值，編譯檢查引用；值都不變 (客戶頁重試鍵除外，其讀取者都已列入回歸)。

## Migration Plan

1. 系統 identifier 搬到 UI 測試端 (2.1) 與客戶頁重試鍵改值 (2.2)，與守門掃描器 (1.1) 平行。
2. 正式原始碼掃描 (1.2) 在 1.1、2.1 完成後加入：`BackButton` 移走前正式掃描必然失敗。
3. 正式掃描 0 違規通過後刪手列的 ASCII 測試 (3.1)；文件 (4.1) 與程式碼平行。

回復時刪除 `Guards/AccessibilityIdentifier/` 與 `SystemAccessibilityID.swift`，還原 `BLAccessibilityID+Common.swift`、`+More.swift`、`BLAccessibilityIDTests` 與 UI 測試引用處、規則檔、README 即可，沒有資料或設定遷移。

## 提案審查 (2026-11-13)

審查者：Herdr 實作終端 t8 (claude-haiku-max-impl)、t9 (codex-luna-max-impl)、t16 (claude-sonnet-xhigh-impl)、t1n (codex-sol-xhigh-impl)，以及 fable-arch-reviewer 子代理做架構與長期維護審查；主對話同時審查。全程唯讀，審查前後 `git status --short` 與 change 檔雜湊一致。

共識：現況量測全部屬實；方向成立 (文字掃描、規則與解析分兩段、看不懂的寫法轉紅、先加守門再刪手列測試、不引入 SwiftSyntax)。

依審查修正 (主對話逐條對照程式碼後採納)：

- 中：呼叫偵測排除函式宣告 (主對話、t16)；宣告層級封閉的定義形式 (t1n、fable-arch-reviewer)；列出接受與拒絕的寫法並接受跨行呼叫、型別標註、行尾註解 (fable-arch-reviewer、t8、t16、t1n、主對話)；查詢前綴取代原始前綴比較 (t16、t1n、fable-arch-reviewer)；組字串函式只豁免單一模板 (t9)；範圍外擴充判違規 (t9)；空掃描與不同函式同前綴的合成案例 (t16、t9)；規格的縮寫轉換措辭與 design 一致 (t8)；形狀情境不再含 ASCII 字樣 (t16)。
- 低：改用保留位置的遮罩工具 (t16、t1n)；掃描器只處理文字、production 接線留在測試檔 (fable-arch-reviewer)；規格不寫實作手段 (fable-arch-reviewer)；定義形式違規不進其他規則 (t16)；行號 1 起算與排序 (t16)；測試數口徑 (t16)；規則句措辭 (t16、t9)；示例表標明固定值 (t9)；固定值與前綴相等不判違規寫明理由 (t8)；README 放在最前 (t8)；支援 `extension BLAccessibilityID.<名稱>` 拆檔 (fable-arch-reviewer)；tasks 寫明終端是查詢當下的結果 (t8)。

使用者 2026-11-13 決定的兩項：系統 identifier 收到 UI 測試端 (fable-arch-reviewer 提出，主對話推薦)、客戶頁重試鍵與其他四個一致 (使用者提出)。

不採納或列為後續：

- 型別歸屬只能做到行粒度 (fable-arch-reviewer)：改用保留位置的遮罩工具後不再受限。
- 大括號配對下沉到 `Guards/Scanning/` (fable-arch-reviewer 觀察)：維持私有，等下一個需要「宣告所屬型別」的守門再評估。
- App 與 UI 測試的 identifier 內聯掃描 (fable-arch-reviewer 觀察)：另屬一條規則，記為後續 change。
- t16 同時是提案審查者與 1.1、1.2 的實作者 (t16 備註)：不違反規範，實作審查另由未參與實作的終端進行。

## 實作與驗證

分支 `features/accessibility-identifier-scan-guard` 由 `main` (`4d03f60`) 切出。2026-11-13 `hc ls` 查得 tasks 指派的終端都在線，依原分工派工。

- 2.1 (t1n)、2.2 與 4.1 (t8)：主對話以 `git diff` 與 `git grep` 核對 (新子 bullet 與本檔區塊逐字相同；`Common.backButton`、舊重試鍵字串 0 處；四個系統字面值只在 `SystemAccessibilityID.swift`)，iPhone 17 (iOS 26.5) 建置 `BuyLedger` 與 `BuyLedgerUITests` (build-for-testing) 通過。2.2 的值變更經常數引用，不另寫斷言 (改動處即可看見，不跨引用處)，由 1.2 的正式掃描與 5.2 的 UI 回歸守。
- 1.1 (t16) 分兩階段交付：
  - RED：掃描器先只有公開型別與回傳空結果的本體，`AccessibilityIdentifierScanTests` 7 個測試函式中 4 個失敗 (違規案例的規則集合、合規案例掃到的值、跨檔描述、各規則描述開頭)，3 個只看案例資料的測試通過，與 t16 交回時的預測相同。
  - GREEN：實作後第一次編譯失敗 (22 處私有巢狀型別出現在非 private 方法簽名)，t16 把 11 個巢狀型別改為預設存取層級後，7 個測試全部通過。
  - 案例：違規 101 筆、合規 11 筆；每條規則至少一筆只破壞該規則的案例由測試機械檢查，主對話以 `grep` 核對 spec 各示例表的值都在案例內。
  - t16 在案例未涵蓋處的選擇 (主對話核對與本檔一致後採用)：同一行以分號串接兩個宣告、`#if` 包住宣告、屬性標記與存取修飾詞開頭的宣告判定義形式違規；檔案最外層的 `import` 接受；合規案例另斷言掃到的固定值與前綴清單 (主對話代選的補強)。
  - 掃描器實際 1577 行，遠超出 Risks 依 `ActionGroupingScanner` 類推的 300 行估計 (t16 說明約 750 行是私有巢狀型別與逐一寫齊的 doc comment)；交 5.1 的架構審查評估。
- 1.2 (t16)：正式原始碼掃描 7 個規則測試與分隔符號測試一次編譯通過，`AccessibilityIdentifierScanTests` 15 個測試全過 (iPhone 17，iOS 26.5)。主對話把空掃描測試暫改為必定失敗讀出訊息：掃到 8 檔、177 個固定值、34 個組出前綴，與預期相同；還原後雜湊與改前一致。
- 1.2 變異檢查 (主對話執行，每項只改一處，跑完整個 `AccessibilityIdentifierScanTests`，還原後雜湊與改前一致)：

| 變異 | 失敗的測試 (15 個中) | 訊息 |
| --- | --- | --- |
| `Orders.listEmptyState` 改為 `orders.list.root` | 只有值重複 | `BLAccessibilityID+Orders.swift:19 Orders.listEmptyState "orders.list.root" 與 BLAccessibilityID+Orders.swift:16 同值` |
| `Orders` 加 `static let probe = "orders.list.row:probe"` | 形狀與第一段、前綴重疊 | `:18 Orders.probe` 形狀不符；落在查詢前綴 `orders.list.row:` 之下 |
| `Dashboard.loading` 改為 `"dashboard.\("loading")"` | 只有定義形式 | `BLAccessibilityID+Dashboard.swift:19 Dashboard.loading "" 宣告不在接受的定義形式內` |
| `Dashboard` 加包裝 `recentOrderRow` 的 `recentOrderAlias` | 只有定義形式 | `BLAccessibilityID+Dashboard.swift:70 Dashboard.recentOrderAlias` 宣告不在接受的定義形式內 |
| `BuyLedgerApp.swift` 檔尾加 `extension BLAccessibilityID {}` | 只有宣告位置 | `BuyLedger/App/BuyLedgerApp.swift:73 BLAccessibilityID.extension` 在命名空間目錄之外宣告 |

- 3.1 (t8)：`git diff` 只有刪除該測試的 24 行，測試函式 8 → 7。`BLAccessibilityIDTests` 在 iPhone 17 (iOS 26.5) 7 個全過。xcresult 摘要與 `mobilebuildmcp` 的 JSON 輸出都只給函式層級的數字 (7)，讀不到參數層級的案例數；主對話改以原始碼計數 `@Test(arguments:)` 的案例：改前 18、改後 10，與 contract 一致。

## 實作與審查 (5.1)

審查者：t9 (codex-luna-max-impl) style 閘門、t17 (leader & reviewer) 正確性、t1p (leader & reviewer) 架構；三者都未參與實作。主對話同時審查。每輪審查前後 `git status --short` 與變更檔雜湊一致。t17 與 t1p 的角色規則禁止建立檔案，回報經 `hc send` 直接傳來。

**第一輪**

- t9：新檔的存取層級過寬、巢狀 closure 單行、helper 順序；UI 測試 `XCUIApplication+NavigationBackInteraction` 分區順序、`MoreNavigationSmokeTests` 未成對的 When。採納。
- t9 不採 (主對話裁定)：行寬 117 行註解與 105 行程式碼 (t9 以 UTF-8 位元組計，以字元計註解 0 行超過 100，超過 100 的程式碼行全是不可斷的字串內容)；`pollUntil` 改 private (另有 6 處跨檔使用)；UI 測試 Given／When 內的等待與 `tapAfterWaiting` (使用者「等待留在 Then」的裁決列的是 `store.finish()`、`clock.advance`、`continuation`，例外清單照字面不類推)；UI 測試命名 (已符合 kit `test<方法>_<情境>_<預期>`)；名稱中的技術詞沿用既有慣例。
- t17：spec 示例表與接受、拒絕表逐列推演一致；另有 6 項會靜默接受或空洞通過的情境。主對話實測其中兩項成立：範圍外目錄改成不存在的名稱時 15 個測試全過；巢狀型別以同名 `option` 或巢狀 `enum BLAccessibilityID` 遮蔽組字串呼叫，獨立 swiftc 小程式編譯通過、執行期值變成 `orders.list.picked:all` 與 `hijacked`。6 項全部採納 (F1–F6)；巢狀列舉遵循清單收緊為 `String`、`Sendable` 並改 spec，由使用者 2026-11-13 決定。主對話讀程式另發現 `typealias X = BLAccessibilityID` 再 `extension X` 可繞過宣告位置檢查，與 t17 同一項。
- t1p：規模 (1577 行，程式碼約 1009 行) 與重新評估條件不可判定 (A1)、新增規則時手列清單會靜默漏 (A2)、封閉清單的指引與未釘住的寫法 (A3)、側邊欄切換鍵的觀測條件 (A4)，採納；拆檔 (B2) 由使用者 2026-11-13 選擇本 change 內做；附註「範圍外先以 `contains` 過濾」無耗時證據不採。
- 修正 (t16 掃描器、t1n 案例與測試、t8 UI 測試三檔)：
  - 拆檔為純重構，主對話以量完即刪的暫時探針逐筆比對：原有 112 筆案例結果完全相同。
  - t1n 新增 21 筆案例，16 筆 RED (修正前回報 0 違規)，5 筆 (自行回傳模板的巢狀 `BLAccessibilityID`、raw string 模板、屬性標記、`private`、明寫 `return`) 由既有行為擋下，屬釘住既有行為。修正後 15 個測試全過。
  - F1 第一版以 `#require` 檢查範圍外檔案數，變異時只有 1 個測試失敗：`ExpectationFailedError` 只在第一個觸發快取初始化的測試記錄，其他測試重丟同一個錯誤不再記錄。改為丟自有錯誤 `ProductionScanError` 並以 `mapError` 包住所有錯誤後，同一變異讓 8 個正式掃描測試全部失敗。
  - 拆檔與修正後重跑 1.2 的 5 項變異，結果與修正前相同。

**第二輪**

- t9：5 筆，主對話全部駁回：`Composer`、`Separators`、`Definition` 只帶一兩個小方法，未達 kit「大到需要分區才讀得懂」的門檻；`ScanCases` helper 順序依第一次被呼叫的位置排 (`file` 第 121 行先於 `orders` 第 444 行) 符合 kit；Parser 的 4 個巢狀型別改 `private` 會在 `private extension` 方法簽名處編譯失敗 (1.1 已實測)，kit 又禁用 `fileprivate`。
- t1p：拆檔邊界清楚，無須改程式行為；design 的型別數與行數對齊實作 (R1)、補後續清單 (R2)、兩輪解析的不變式註解 (R3)、spec 遮蔽條件改為可機械判定的語法條件 (R4)，採納。
- t17：5 筆低。範圍外 `typealias` 右側與 `extension` 標頭不在開頭的 `BLAccessibilityID`、參數名遮蔽、跨檔重載點名錯檔、新案例沒釘住被點名的宣告，採納 (G1–G6)；範圍外以隱含遵循的協定擴充遮蔽記為已知限制 (見 Risks)。收尾方式由使用者 2026-11-13 決定：修完再開第三輪審查。

**第三輪**

- t9：2 處註解句尾中文句號、2 處 doc comment 以自由段落補充 (kit 規定用 `- Note:`)，採納。
- t17：`typealias ProbeIDs = BuyLedger` 下一行接 `.BLAccessibilityID` 漏判，主對話以獨立 swiftc 小程式實測可編譯並注入成員，採納 (H1)；`associatedtype` 預設值經型別見證擴充實測編譯失敗 (`must be declared as an extension of 'BLAccessibilityID.Orders'`)，不處理。
- t1p：程式無須再改；名稱表後續、最終行數、`typealias` 右側結束條件的文字，採納；建議寫明宣告位置規則的停止線。
- 收尾方式由使用者 2026-11-13 選擇：全修 (含停止線) 後再開第四輪。
- 修正：t1n 補「點在下一行開頭」案例 (RED：修正前回報 0 違規)；t16 實作 H1 時另把「點在上一行結尾」也視為接續，t1n 補案例釘住；主對話以變異確認只保留其中一個條件時，各有一筆接續案例失敗。修正後 16 個測試全過，重跑範圍外宣告與目錄失效的變異結果不變。

**第四輪**

- t9：無違規。
- t17：design 只寫了「下一個記號是 `.`」，與實作、案例不一致，採納；角括號內函式型別 `->` 讓深度提早歸零的寫法 (`Pair<(Int) -> Int,` 換行接 `BLAccessibilityID>`)，主對話實測編譯失敗，不處理。
- t1p：接續條件寫齊、停止線的例子 (原舉的關聯型別實測編譯失敗) 刪除、補第三四輪紀錄、Risks 加宣告位置規則的已知限制，採納；停止線只寫在 design、歸檔後 spec 仍無範圍限制，使用者 2026-11-13 決定收窄 spec。
- 收尾方式由使用者 2026-11-13 選擇：改完文件再開第五輪 (只審文件改動)。

**第五輪 (只審文件)**

- t9：無。
- t17：spec 的同名型別宣告要列出實際認得的六種宣告 (`associatedtype` 與泛型參數同名不會遮蔽命名空間，歸入不偵測範圍)；Scenario 的 WHEN 只舉兩種寫法，改成與條款同結構。採納。
- t1p：spec 沒寫 `typealias` 右側的換行界線 (主對話實測 `typealias ProbeIDs = Same` 換行接 `<BLAccessibilityID>` 可編譯，但經泛型別名擴充已實測編譯失敗，無法注入)；「out of scope」要寫明是不偵測、留給審查，不是允許。採納。
- 使用者 2026-11-13 決定結束審查，進 5.2 回歸。五輪中程式改動在第四輪後即停止；每輪修正都先補案例確認 RED，再改掃描器並重跑變異。

**後續 (不在本 change 處理，各附觸發條件)**

- fail-closed 不變式分散在各比對函式 (t1p 第一輪 B1)：`isImport`、`matchCase`、`matchFixed`、`matchWrapper` 各自檢查空隙，`isTemplate` 另用 `isSingleLineTemplate`。第一次新增接受的寫法時，先改成比對函式回報認領的字面值空隙、由 `analyzeMember` 統一核對。
- 遮罩工具只輸出空白、不輸出區段種類 (t1p B3)：`AccessibilityIdentifierSourceModel` 已有三組在原文重讀字面值與註解的程式。下一次有守門要在遮罩位置讀回字面值或註解時，讓 `Guards/Scanning/` 的遮罩工具另外輸出區段清單，並一併收窄記號模型的座標換算 (字元位置、絕對記號索引、宣告內相對位置)、`startKeywords` 的用途 (宣告切分、違規名稱、範圍外 `isDeclarationBoundary`)，以及 `AccessibilityIdentifierLocationChecker` 直接讀原文判斷換行的寫法。
- 兩輪解析的名稱表 (t1p 第二、三輪)：名稱表已分成兩份：兩輪都收集 `declaredFunctions`，第一輪的結果成為第二輪唯讀判斷用的 `knownFunctions`。下次修改 `scan`、`analyzeTopLevel`、`parseEnum` 或 `parseMembers` 時，把 `knownFunctions` 改成建立時傳入，並在 `scan` 結尾比對兩表、不同時回報違規；名稱表的鍵 (`String?`，`nil` 為根層) 改成具名列舉，參數名遮蔽 (`matchWrapper` 內) 與函式遮蔽 (`isShadowed`) 併到同一處。
- identifier 內聯掃描 (t1p B4)：`SystemAccessibilityID` 的重複值與 UI 測試再內聯系統字面值目前只靠驗收時的 `git grep`。做內聯掃描的 change 先把分散在四個掃描器檔的根型別名稱收成一個常數，並排在 roadmap 的 UI 測試規範修正之後 (UI 測試仍有以顯示文字定位的字面值，機械上無法與 identifier 區分)。
- `AccessibilityIdentifierScanCases.swift` 的拆分 (t1p B5)：下次擴充接受清單或大量增刪定義形式案例時，依 kit `file-templates.md` 拆成獨立的案例型別。
- 可選整理 (t1p 第二、三輪，不改行為)：`ContainerShape` 改回傳 tuple (`FunctionShape` 已有四個欄位，效益小)；`Definition` 的種類與 `fixed`／`prefixes` 兩個清單並存，規則端以索引配對查詢前綴；`AccessibilityIdentifierDeclarationParser.scan` 借用 `ScanResult` 回傳未排序的中間結果。

## 回歸驗證 (5.2)

- 單元測試：iPhone 17 (iOS 26.5，淺色外觀) 完整 `BuyLedgerTests` 2073 個，2070 通過、0 失敗、0 略過、3 個既有標為已知問題的預期失敗；snapshot 未重錄。
- UI 測試 (`BuyLedgerUITests` scheme)：
  - iPad Air 11-inch (M4) (iPadOS 27.0)：先單獨跑 `KeyboardDismissTests` 2 個全過 (鍵盤前提成立)；其餘 6 個類別 27 個，22 通過、0 失敗、4 個依版面略過、1 個既有預期失敗。6 個類別的方法數合計 27，每個類別依版面最多略過部分案例，iPad 上每類實際執行數都大於 0。
  - iPhone 17 (iOS 26.5)：7 個類別 29 個，13 通過、0 失敗、15 個依版面略過 (`OrderRegularColumnScopeTests` 12 個為寬版限定)、1 個既有預期失敗。
- 文件同步鐵則 (對照 `git status --short` 逐列)：有影響，已同步。
  - 新的守門、系統 identifier 位置與封閉清單的擴充方式：`.claude/rules/ios-ui-tests.md`「定位與 identifier」。
  - 新的 gotcha：`.claude/rules/ios-unit-tests.md` 補兩條 (共用快取的掃描結果不用 `#require`；參數化測試失敗時 xcresult 摘要只列一筆)。
  - 目錄結構：`apps/ios/README.md` 的 `Guards/` 多檔守門清單補上 `AccessibilityIdentifier`；root `README.md` 無影響。
  - 讓既有描述失效：規則檔的 `Common.backButton` 已改為 `SystemAccessibilityID.backButton`；`git grep` 確認 change 與 archive 之外沒有 `Common.backButton`、`customers.list.loadFailureRetryButton`、已刪測試名稱與 `popoverDismissRegionIdentifier` 的殘留。
  - 技術棧、外部服務、環境設定：無變動。

## verify／review 後的修正 (2026-11-13)

`/spectra-verify` (Critical 0、Warning 2、Suggestion 4) 與 `/spectra-review` (Critical 0、Warning 1) 的發現，使用者 2026-11-13 選擇全部處理。

- review W1：第二輪新增的「違規規則均有正式測試涵蓋」以手寫的 8 條規則做子集斷言，恆成立、永遠不會失敗。改為 `scan_正式原始碼_沒有任何違規`，斷言正式掃描的全部違規為空；之後每項變異都會多紅這一個測試。
- verify W1：「範圍外目錄讀不到檔」原本只靠測試檔裡的檢查與主對話的變異證明。改由掃描器以 `outsideRoots` 參數回報 `.emptyScan`，有合成案例證明；測試檔的檔案數檢查與 `ProductionScanError.emptyDirectory` 刪除，讀檔與 `outsideRoots` 共用同一個目錄清單常數。
- verify W2：新增窄規則 `.systemIdentifierLiteral` (`AccessibilityIdentifierSystemLiteralChecker`)：受檢值由掃描 `SystemAccessibilityID.swift` 取得，其他 App 與 UI 測試檔出現完全相同的字串字面值即違規；系統檔不存在或沒有值時判空掃描。spec 補上失敗條件與示例。寫成 raw string (`#"BackButton"#`) 或含跳脫的字面值不會被抓到，屬停止線之外的刻意繞法；App 指定 identifier 的內聯掃描仍是後續。
- verify S1–S4：補上用 spec 示例表原值的案例與 `class`／`actor`／`protocol`／同名 `typealias` 的宣告位置案例 (由既有行為滿足，釘住既有行為)；proposal 補列 `.claude/rules/ios-unit-tests.md`；spec 補全大寫型別名的轉換 (`AI` 轉 `ai`)。
- 驗證 (iPhone 17，iOS 26.5)：
  - RED：以暫時探針確認 V1、V2 的 5 筆違規案例與 V2 的點名描述在實作前都回報 0 違規；S1、S2 新案例由既有行為滿足。
  - GREEN：`AccessibilityIdentifierScanTests` 17 個測試全過；完整 `BuyLedgerTests` 2074 個，2071 通過、0 失敗、3 個既有預期失敗。
  - 變異 (每項只改一處，還原後雜湊一致)：1.2 的 5 項各讓對應規則的測試與「沒有任何違規」失敗 (m2 為形狀、前綴重疊加整體共 3 個)；範圍外目錄改名讓空掃描與整體失敗；兩個 `typealias` 接續條件各拿掉一個時對應案例失敗；`SettingsScreen` 的 `SystemAccessibilityID.backButton` 暫改回字面值 `"BackButton"` 讓系統字面值測試與整體失敗。
  - UI 測試不受影響：本輪只改 `BuyLedgerTests` 的守門檔，正式 identifier 與 UI 測試檔都沒有變更 (變異暫改的 `SettingsScreen` 已還原)。

## Open Questions

(none)
