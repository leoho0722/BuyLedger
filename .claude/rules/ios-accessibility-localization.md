---
paths:
  - "apps/ios/BuyLedger/Features/**"
  - "apps/ios/BuyLedger/Shared/**"
  - "apps/ios/BuyLedger/Core/{Domain,Networking}/**"
  - "apps/ios/BuyLedger/**/*.xcstrings"
  - "apps/ios/BuyLedgerTests/Guards/LocalizationCatalog/*.swift"
  - "apps/ios/BuyLedgerTests/Guards/Scanning/*+SourceLiteralScan.swift"
  - "apps/ios/BuyLedgerTests/Guards/AccessibilityConventionScanTests.swift"
---

# iOS 無障礙與本地化

## Dynamic Type 與無障礙

- **無障礙字級改版面結構，不用縮放係數把字壓回去**：以 `dynamicTypeSize.isAccessibilitySize` 判斷 (不逐級列舉 case)，解除單行限制並降維 (多欄變單欄、橫排變堆疊)。
    - 不用 `minimumScaleFactor`／`lineLimit(1)` 抵銷使用者的字級設定。
    - `NavigationSplitView` 的欄寬由版面分配決定 (如訂單三欄平分)，不套 `@ScaledMetric`，是下一條的例外：隨字級加寬會擠壓相鄰欄。欄寬因此不隨字級變大，欄內固定在捲動區外的區塊 (如 iPad 訂單清單欄的篩選區) 在輔助字級會被壓縮而重疊，要在 `isAccessibilitySize` 時併入捲動區 (參考 `OrdersRegularListColumn`)。
- **固定點數的尺寸一律 `@ScaledMetric`** (圖示、格高、欄寬、圖表直徑)：它需要 view 實例，`static let` 尺寸常數要改成實例屬性。
    - 元件參數本身已是 `@ScaledMetric` 時 (`BLSparkline.height`、`BLBarChart.height`)，呼叫端傳基準點數，不再包一層 `@ScaledMetric`：合成 `init` 會把傳入值當成基準再縮放一次，尺寸被乘上兩次縮放倍率。
    - 由 `DesignSystemSourceScanTests` 的規則十二守門，只辨識以單一識別字傳入的引數；傳入運算式或成員存取時人工確認。
- **驗證特定字級用啟動參數，不改系統設定**：`--launch-args '-UIPreferredContentSizeCategoryName' --launch-args 'UICTContentSizeCategoryAccessibilityXXXL'`。
    - 常數名拼錯會靜默無效，套用後先截圖確認字級真的變了。
- **複合列 (訂單列、開團列、KPI 格) 加 `.accessibilityElement(children: .combine)` 合併為單一朗讀單位**，合併前把純裝飾元素標 `.accessibilityHidden(true)`。
    - 可重用元件以參數表達是否裝飾 (`BLAvatar.isDecorative`)，不在呼叫端外層硬蓋。
- **格狀資料每格的 label 帶列與欄座標**；空值格排除於無障礙樹，整張圖另給一句摘要。
- **可選取的列於選取時加 `.accessibilityAddTraits(.isSelected)`**，條件式勾號本身標 `.accessibilityHidden(true)`。
    - `AccessibilityConventionScanTests` 以「`.buttonStyle(.plain)` 加條件式勾號」的程式碼形狀守門；改用其他 button style 或非 `Button` 呈現選取時掃描涵蓋不到，要人工複核。
    - 加上 `.accessibilityLabel(...)` 不能取代選取特徵：動作描述無法提供 rotor 需要的標準選取語意。
- **新增動畫先判斷減少動態效果**：`accessibilityReduceMotion` 為真時傳 `nil` 給 `.animation(_:value:)`。
    - 判斷放在動畫來源 (元件內，或可測的 `static func`，如 `BLPhotoViewer.zoomAnimation(reduceMotion:)`)，不散在呼叫端。
    - 掃描守門只涵蓋 `.animation(`；新增 `withAnimation`／`.transition`／`.symbolEffect` 時要人工確認。
- **圖表元件呼叫 `.accessibilityChartDescriptor(_:)` 提供原生圖表導覽**，新增圖表元件比照。
    - `AXChartDescriptor` 的標題與序列名是 `String`，不隨 App 內語言切換翻譯；`BLBarChart`／`BLDonutChart`／`BLSparkline` 因此開放為建構參數，由呼叫端以 `AppLanguage.localized(_:)` 傳入已本地化字串。
    - Design System 元件不持有 `AppLanguage` 是既有慣例 (不是分層限制)；不持有語言狀態的 view (如 `OrderDetailContentView`) 由 `@Environment(\.locale)` 換算出 `language`，並與 `CurrencyDisplayName.text(code:language:)` 共用同一入口；picker 搜尋補充文字走 `CurrencyDisplayName.searchKeywords(code:locale:)`。
    - 這些字面值同樣要進 `Localizable.xcstrings`。

## 本地化

- **String Catalog 英文結構化 Key 規範**：
  Key 統一規範為 `<domain>.<component>.<elementType>.<descriptor>` 四段點記號格式 (如 `orders.list.title`、`common.action.cancel`)。各段全小寫開頭，複合單詞一律採用 `lowerCamelCase`；`descriptor` 優先使用精簡單詞 (如 `save`、`cancel`、`delete`、`pending`)，同元件內需要消除歧義時才使用複合駝峰詞 (如 `saveAndContinue`、`pendingPayment`)。
- **嚴禁字串拼接 (Prohibition of String Concatenation)**：
  使用者可見文案與複合訊息嚴禁在 View 內以 `+` 拼接 `Text` (例如 `Text("篩選") + Text(": ") + summary` 即屬違規)；複合訊息必須在 String Catalog 定義單一帶參數的格式化字串。
- **多參數位置標記 (Positional Parameter Specifiers)**：
  含兩個 (含) 以上參數之格式字串，強制使用 `%1$lld`、`%2$@` 位置標記，避免不同語言詞序調換造成型別混淆。
- **單複數宣告走 String Catalog Substitutions**：
  英文單複數差異交由 `.xcstrings` 的 `plural` 屬性定義，禁止在業務邏輯中以 `if count == 1` 條件分支切換文案。
- **`Text(someString)` (型別 `String`) 走 verbatim、不會本地化**：固定詞經 `String` 變數傳進 `Text`／`Label`／`navigationTitle` 時包 `LocalizedStringKey(...)`，或把參數型別宣告為 `LocalizedStringKey` (參考 `DashboardKPITile` 的 `delta` 參數)。
  - 帶插值的文案用 `Text(LocalizedStringKey("\(count) …"))`；不用 `String(localized:locale:)`，它走系統語言 bundle、不吃 App 內語言切換。
  - 使用者資料 (主檔名稱、`customer.name`) 與格式化後的數字、日期維持 verbatim。
- **根分頁標題用 `rootNavigationTitle(_:language:)`**：`navigationTitle` 不會隨 `\.locale` 可靠地重新解析 String Catalog，改由 `AppLanguage.localized(_:)` 先解析。
  - Orders 的多選三態標題由 `OrderListFeature.State.navigationTitleKey` 衍生；`Tab(LocalizedStringKey)` 不需要此處理。
- **新增任何 UI 字串 (含 `AlertState`／`TextState`、`accessibilityLabel`) 都補 `Localizable.xcstrings` 的 `en`**，否則英文模式露出中文。
  - 手動補 catalog 用文字插入展開格式的 entry，不整檔 `json.dump` 重寫：`.xcstrings` 是 Xcode 自訂序列化，重寫會產生巨量 diff。
  - `LocalizationCatalogTests` 會掃描程式碼中的使用者可見字面值；型別呼叫自動涵蓋，但文字類 modifier (如 `.help`) 與 display property 是列舉清單，新增這兩類時同步補 `LocalizationCatalogLiteralScan.swift` `visibleLiteralStarts` 內的 `visiblePatterns`，以及 `String+SourceLiteralScan.swift` `isDisplayScopeDeclaration` 內的 `displayProperties`。
  - 直接作為型別呼叫引數的多行 `"""` 字面值掃描抓不到，要人工確認已進 catalog。
  - 回傳 `LocalizedStringKey`／`LocalizedStringResource` 的函式與屬性，本體內的字面值 (含插值) 都會被當成目錄 key 檢查：組出 verbatim 文字 (金額、百分比、`MoM` 等) 的格式化函式回傳 `String`，由呼叫端包 `LocalizedStringKey` (參考 `DashboardFormatters.percentDelta`)。
