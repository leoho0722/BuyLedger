---
paths:
  - "apps/ios/BuyLedger/Features/**"
  - "apps/ios/BuyLedger/Shared/**"
  - "apps/ios/BuyLedger/Core/{Domain,Networking}/**"
  - "apps/ios/BuyLedger/**/*.xcstrings"
  - "apps/ios/BuyLedgerTests/{LocalizationCatalogTests,AccessibilityConventionScanTests}.swift"
---

# iOS 無障礙與本地化

## Dynamic Type 與無障礙

- **無障礙字級改版面結構，不用縮放係數把字壓回去**：以 `dynamicTypeSize.isAccessibilitySize` 判斷 (不逐級列舉 case)，解除單行限制並降維 (多欄變單欄、橫排變堆疊)。
    - 不用 `minimumScaleFactor`／`lineLimit(1)` 抵銷使用者的字級設定。
- **固定點數的尺寸一律 `@ScaledMetric`** (圖示、格高、欄寬、圖表直徑)：它需要 view 實例，`static let` 尺寸常數要改成實例屬性。
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
    - Design System 元件不持有 `AppLanguage` 是既有慣例 (不是分層限制)；不持有語言狀態的 view (如 `OrderDetailView`) 由 `@Environment(\.locale)` 換算出 `language`，並與 `currencyDisplayText(for:)` 共用同一入口。
    - 這些字面值同樣要進 `Localizable.xcstrings`。

## 本地化

- **`Text(someString)` (型別 `String`) 走 verbatim、不會本地化**：固定詞經 `String` 變數傳進 `Text`／`Label`／`navigationTitle` 時包 `LocalizedStringKey(...)`，或把參數型別宣告為 `LocalizedStringKey` (參考 `DashboardView.kpiTile(delta:)`)。
    - 帶插值的文案用 `Text(LocalizedStringKey("\(count) …"))`；不用 `String(localized:locale:)`，它走系統語言 bundle、不吃 App 內語言切換。
    - 使用者資料 (主檔名稱、`customer.name`) 與格式化後的數字、日期維持 verbatim。
- **根分頁標題用 `rootNavigationTitle(_:language:)`**：`navigationTitle` 不會隨 `\.locale` 可靠地重新解析 String Catalog，改由 `AppLanguage.localized(_:)` 先解析。
    - Orders 的多選三態標題由 `OrdersFeature.State.navigationTitleKey` 衍生；`Tab(LocalizedStringKey)` 不需要此處理。
- **新增任何 UI 字串 (含 `AlertState`／`TextState`、`accessibilityLabel`) 都補 `Localizable.xcstrings` 的 `en`**，否則英文模式露出中文。
    - 手動補 catalog 用文字插入展開格式的 entry，不整檔 `json.dump` 重寫：`.xcstrings` 是 Xcode 自訂序列化，重寫會產生巨量 diff。
    - `LocalizationCatalogTests` 會掃描程式碼中的使用者可見字面值；型別呼叫自動涵蓋，但文字類 modifier (如 `.help`) 與 display property 是列舉清單，新增這兩類時同步補 `visiblePatterns`／`displayProperties`。
    - 直接作為型別呼叫引數的多行 `"""` 字面值掃描抓不到，要人工確認已進 catalog。
