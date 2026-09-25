## Context

`apps/ios/BuyLedger/Shared/` 共 35 個 Swift 檔 (DesignSystem 29、Extensions 4、Localization 1、Media 1)，是全 App 每個畫面都會經過的元件與格式化層。2026-09-14 全庫審查在此區記錄 334 筆待修項 (實測值，取自報告資料集的 Shared 區篩選，已排除 commit `291d841` 修掉的尾隨空白)，內含必擋 169、違規 135、建議 29 與 1 筆已登記例外，35 檔全部命中。

前一步 `core-codegen-style-compliance` 已把 Core 與 codegen 模板對齊規範並結案 (commit `30791e3`)，錯誤型別與生成型別的形狀已穩定，Shared 可以安全地在其上重構。

**現有守門的缺口**：`LayerBoundaryTests.coreAndSharedDoNotReferenceFeatureTypes` 只掃「Core 與 Shared 是否引用 Features 的型別」，方向是向上。本次要處理的是 Shared 認得 Core 領域型別 (`OrderStatus`、`CurrencyCode`、`PaymentMethodFlags`) 與 TCA (`@Dependency`)，這個方向目前零守門。

**限制**：

- 專案是單一 App target，分層靠慣例與掃描測試維持，編譯器不強制。
- `apps/ios/CLAUDE.md` 已載明「金額、百分比、日期格式化用 `BLFormatters` / `OrderFormatters` / `CampaignFormatters` 的靜態函式，不是 `FormatStyle`」，本次不改變這個慣例。
- `.claude/rules/ios-accessibility-localization.md` 已載明「Design System 元件不持有 `AppLanguage`」與「不持有語言狀態的 view 由 `@Environment(\.locale)` 換算出 `language`，並與 `currencyDisplayText(for:)` 共用同一入口」，本次的幣別文字入口要與這條相容。

## Goals / Non-Goals

**Goals:**

- Shared 底下 35 檔全部符合 `/ios-dev-kit` 的 `formatting.md`、`coding-style.md` 與 `file-templates.md`。
- Design System 不再認得 Core 的領域型別，也不再 import ComposableArchitecture。
- 幣別顯示名稱只有一個實作，production code 全部 13 處查表 (5 處畫面名稱 + 4 處 picker 列標題 + 4 處 picker 搜尋關鍵字) 共用它，四個幣別 picker 的顯示格式統一為語系規則。
- 新增可轉紅的分層守門，涵蓋 Shared 對 Core 領域型別的引用。
- 單元測試跟著本區一起改：涵蓋本區的測試檔採用規範的命名、Given / When / Then 與 doc comment。

**Non-Goals:**

- **不修 Feature 檔自身的違規**。本次改到的 9 個 Feature 檔 (`OrderStatus+Presentation`、`RootSidebarLayout`、`LookupManagementView`、`SettingsView`、`QuoteView`、`FxView`、`OrderEditView`、`OrderDetailView`、`CustomersView`) 只做「換用新入口與新簽章」必需的行，其餘違規留給第 3 至 8 步。allowlist 另列的 `OrdersView.swift` 是預留範圍，目前沒有已知待改處。
- **不動 `BLPalette` 的色彩值、語意命名與取色管道**。色彩取得管道由 `color-system-foundation` 規格管轄，本次只改分區與取得色盤實例的位置。
- **不重錄任何 snapshot 基準圖**。若重構後 snapshot 轉紅，代表畫面真的變了，要改回程式碼而不是改基準圖。
- **不改 `OptionPickerSheet` 與 `PaymentMethodEditorSheet` 的呈現、可選項目與可用動作**，只改 callback 的參數型別。
- **不把 `extension View` 的便利入口搬出 modifier 所在檔**。`blCardShadow()` / `blHeroCardBackground()` / `blTextStyle(_:)` / `rootNavigationTitle(_:language:)` 與其 modifier 同檔是 SwiftUI 慣例，維持一個關注點一檔。
- **不因檔名掃描器的單一主要型別假設拆分既有 token 檔**。`BLMetrics.swift` 聚合 `BLRadius`、`BLSpacing`、`BLListMetrics` 與 `BLHitTarget`，`BLTypography.swift` 聚合 `BLTypographyStyle`；本次只整理分區與型別本體邊界，不改動既有檔名或拆檔。尺寸 token 的 doc 維持簡短名稱與既有用途語意，不為掃描器的「複述名稱」判讀擴大文件改寫。
- **不改既有 `BLCardShadow` 的 public 參數命名與組合語意**。`floating` 是既有 modifier API；深色模式由 modifier 不加陰影、由 `BLCard` 的分隔線表達層級，是兩個元件協作的既有責任分配，本次不為單一 finding 擴大 API 或視覺行為變更。
- **不重構 `AppLanguage` 的語言判斷與 bundle 解析**。

## Decisions

### BLStatusHue 移入 Features/Orders 而非留在 Design System

`BLStatusHue` 的全部內容就是 `OrderStatus` 到色相的 `switch`，把它留在 Design System 卻改收自訂語意列舉，等於新增一層只有一個呼叫端的間接轉換。它移進既有的 `OrderStatus+Presentation.swift` (該檔已放 `OrderStatus.tone`)，Design System 少一個型別，領域到呈現的兩個對應收在同一處。

- 新形狀：`OrderStatus` 的 `func sidebarHue(in palette: BLPalette) -> Color`。
- `apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLStatusHue.swift` 刪除。
- `OrderStatus+Presentation.swift` 因為回傳 `Color` 要改 `import SwiftUI` (目前是 `import Foundation`)。

**替代方案**：留在 Design System 改收自訂語意列舉。否決理由是它只有一個產品呼叫端 (`RootSidebarLayout.SmartGroup.color(in:)`)，新增的語意列舉沒有第二個使用者，只是把同一個 `switch` 拆成兩個。

### 幣別顯示名稱的單一入口放 Shared/Localization 並收 ISO 代碼字串

新增 `apps/ios/BuyLedger/Shared/Localization/CurrencyDisplayName.swift`，型別為無 case 的 `enum CurrencyDisplayName`，提供兩個入口共用同一份 private 查表：

- `static func text(code: String, language: AppLanguage) -> String`：**畫面上顯示的幣別名稱**。正體中文回傳 `locale.localizedString(forCurrencyCode:)` 的結果、查不到或空字串時回退 ISO 代碼；英文直接回傳 ISO 代碼。
- `static func searchKeywords(code: String, locale: Locale) -> String`：**picker 的搜尋補充關鍵字**。一律回傳目前 locale 的本地化名稱，查不到時回傳空字串，**不套用上面的語言規則**。

收 `String` 而非 `CurrencyCode`，讓這個入口與 Core 完全無關；呼叫端傳 `currency.rawValue`。放在 `Shared/Localization/` 而非 `BLFormatters`，因為幣別名稱是本地化查表，不是數值格式化規則。

**現況是 13 處 production 查表，不是 5 處，而且格式三種都不一樣** (已逐處確認；另有第 14 處在 `OptionPickerSheet` 的 `#Preview` 內，這輪一併改為呼叫 `CurrencyDisplayName.text`，讓 Preview 與 production 用法一致)：

| 用途 | 目前輸出 | 出現處 |
|---|---|---|
| 畫面上的幣別名稱 | 中文回名稱、英文回 ISO 代碼 | `SettingsView`、`QuoteView`、`FxView`、`OrderEditView`、`OrderDetailView` 各自的 `currencyDisplayText`，共 5 處 |
| picker 列標題 | `"\(code) · \(name)"`，如「TWD · 新台幣」 | `SettingsView`、`FxView`、`QuoteView` 的 `displayName` closure，共 3 處 |
| picker 列標題 | `"\(code) (\(name))"`，如「TWD (新台幣)」 | `OrderEditView` 的 `displayName` closure，1 處 |
| picker 搜尋關鍵字 | 一律 locale 查表結果，查不到回空字串，不看 App 語言 | 上述四個畫面的 `searchKeywords` closure，共 4 處 |

**使用者 2026-09-19 裁決：picker 的顯示格式改成與畫面上其他地方一致的語系規則**，中文顯示「新台幣」、英文顯示「TWD」，不再顯示代碼加分隔符。四個 picker 的 `displayName` 一律改呼叫 `text(code:language:)`，`searchKeywords` 改呼叫 `searchKeywords(code:locale:)`。

`searchKeywords` 刻意不套語言規則：英文模式下顯示的是 ISO 代碼，若搜尋關鍵字也只回 ISO 代碼，英文使用者就搜不到 "Taiwan"，那是功能退化。維持現況的 locale 查表行為，代碼本身由 `OptionPickerSheet` 以原值比對，不需要另外補。

**替代方案一**：掛在 `AppLanguage` 上。否決理由是 `AppLanguage` 是語言偏好型別，讓它長出幣別呈現規則會把兩個關注點綁在一起。
**替代方案二**：新增第三個 `listLabel(code:locale:separator:)` 入口保留三種既有格式。否決理由是把現有的不一致固化進 Shared API，之後還要再開一輪才能統一。
**替代方案三**：只收斂 5 處畫面名稱、picker 的 8 處留給第 3 與第 6 步。否決理由是同一份規格要分兩次才收齊，中間那段時間規格是宣稱成立但實際不成立的狀態。

### 兩個 sheet 的付款方式旗標改收三個具名 Bool

`PaymentMethodEditorSheet` 的 `SubmitAction` 與 `initialFlags`、`OptionPickerSheet` 的 `onAddPaymentMethod` 都改用 `isCardless` / `isBankTransfer` / `isCashOnDelivery` 三個具名 `Bool`，由 `LookupManagementView` 與 `OptionPickerSheet` 的 Feature 端呼叫者負責組回 `PaymentMethodFlags`。

**`PaymentMethodFlags` 在 `PaymentMethodEditorSheet` 共 7 處**，全部都要改掉，`Shared/` 內才會歸零：`SubmitAction` 的參數、`initialFlags` 屬性、init 參數、提交時建構旗標、private 的 `PaymentMethodEditorSnapshot.flags` 欄位、`draftSnapshot` 與 `initialSnapshot` 的建構，以及 `#Preview` 的傳值。private snapshot 型別改成直接持有三個 `Bool`，`isDirty` 的比較語意不變。

**替代方案一**：在 Design System 定義同形狀的 `BLPaymentMethodOptions`。否決理由是同一個形狀在兩層各定義一次，且兩層都要維護。
**替代方案二**：把 `PaymentMethodEditorSheet` 搬到 `Features/Lookups/`。否決理由是會提前捲入第 4 步的 Lookups 檔案。

### BLDelayedProgressView 的延遲改用 Task.sleep 並移除 TCA 依賴

移除 `import ComposableArchitecture` 與 `@Dependency(\.continuousClock)`，`.task` 內改用 `try? await Task.sleep(for: delay)`，並以 `Task.isCancelled` 避免取消後更新狀態。沒有任何測試注入這個 clock (已確認 `BLDelayedProgressView` 在 `apps/ios/BuyLedgerTests/` 零出現)，移除不會讓既有測試失去控制點。

`catch is CancellationError { return }` 與 `catch { return }` 兩個分支合併為單一 `catch { return }` 並附「取消或逾時都不顯示轉圈，失敗可忽略」的理由註解，符合 `coding-style.md` 對靜默 catch 要有理由的要求。

### ViewModifier 與 Style 的 body 移進以 protocol 命名的 extension

`BLCardShadow`、`BLHeroCardBackground`、`BLTypographyModifier` 的 `func body(content:)`，`BLButtonStyle` 與獨立檔 `BLPhotoThumbnailButtonStyle` 的 `makeBody(configuration:)`，`BLProgressViewStyle` 的 `makeBody(configuration:)`，以及 `BLSearchableModifier` 的 ViewModifier，一律從型別本體移到 `// MARK: - ViewModifier` / `// MARK: - ButtonStyle` / `// MARK: - ProgressViewStyle` 的 extension，遵循宣告也跟著移到 extension 上。型別本體只留 stored properties 與 Init。

這是 2026-09-14 裁決 3，`formatting.md` 的「需要手寫實作的 protocol 在 extension 宣告遵循並放全部實作」也指向同一結果。SwiftUI `View` 的 `body` 是明文例外，留在型別本體的 `Body` 區。

### OptionPickerSheet 保留 private 狀態並抽獨立清單 View

`OptionPickerSheet` 不以跨檔 `extension` 拆分 View。本型別的五個 `@State`／`@Environment` (`dismiss`、`draft`、`isAddAlertPresented`、`isAddPaymentMethodPresented`、`searchText`) 維持 `private`，因此會碰到這些狀態的 `configuredContent`、`cancelToolbarItem`、`filteredOptions`、`addDraft`、`selectOption` 與 `triggerAdd` 全部留在主檔並置於對應的 private MARK 區塊。

清單列的純呈現與選取狀態判斷抽成同目錄的 `OptionPickerList`，只接收已過濾選項、選取資料、顯示轉換、清除設定、多選設定、選取 closure 與空狀態文字；主檔保留外層 `List`、新增入口、alert、導覽與搜尋 binding。這樣不改 `OptionPickerSheet` 的 init 參數列，也不讓 private 狀態為了跨檔存取而降成 internal。

依使用者 2026-09-20 裁決，主檔因此超過 300 行，登記 `FM4` 行數例外。理由是依 `file-templates.md` 以 View extension 跨檔分割會迫使五個 private wrapper property 降為 internal，破壞 View 狀態封裝；優先抽出獨立 `OptionPickerList` 後仍抽不動的主檔內容保留原處，接受單檔超標。

### MARK 分區改依 formatting.md 的固定名稱與順序

Shared 底下實測出現 11 種規範外的分區名，一律改為規範名或刪除 (下表另列 `Presentation Properties`，它在 allowlist 內的 `OrderStatus+Presentation.swift` 出現，不在 Shared)：

| 現況段名 | 改成 |
|---|---|
| `View Properties` | `Properties` |
| `View Body` | `Body` |
| `ViewBuilder` | `Private Views` |
| `Data Properties` | `Properties` |
| `Display Properties` | `Computed Properties` |
| `Identifiable Properties` | 併入 `Computed Properties` |
| `Static Properties` (型別本體) | `Properties` |
| `Static Properties` (extension 內) | `Computed Properties` 或 `Properties` 視是否 computed |
| `Private Types` | `Nested Types` |
| `Typealias` | 刪除該分區，`typealias` 併入 `Nested Types` |
| `Cases` | 刪除該分區 (樣板不為 enum case 立分區) |
| `Presentation Properties` | `Computed Properties` |
| `View Method` (對 `View` 的 extension) | 依該 extension 提供的功能命名 |

順序依 `formatting.md`：Properties → Init → (View 專屬) Body → Private Views → Nested Types → Computed Properties → Internal Method → protocol 名 → Private Method → Preview。

**以 protocol 名稱作 MARK 是合法的，`findings.md` 對此有誤報**。`formatting.md` 明文「Protocol 遵循各自獨立一個 extension，以 protocol 名稱作為 MARK 名稱」，但審查腳本的允許清單沒收 protocol 名，於是把下列段名全標成 `MK1` 必擋。**這些都不改**，實作時在 `findings.md` 逐筆標記「誤報，protocol 名稱依 formatting.md 合法」：

- `// MARK: - ViewModifier` (`BLCardShadow`、`BLHeroCardBackground`、`BLTypographyModifier`、`BLSearchableModifier`)
- `// MARK: - ButtonStyle` (`BLPhotoThumbnailButtonStyle.swift`)
- `// MARK: - ProgressViewStyle` (`BLProgressViewStyle.swift`)
- `// MARK: - AXChartDescriptorRepresentable` (`BLBarChart`、`BLDonutChart`、`BLSparkline`)。**MARK 名稱本身合法，但這三個 extension 依下一節要整個消失**，所以這三筆在 `findings.md` 標為「誤報，但該處另有 nested type 就地實作的問題，由圖表描述子那一節處理」。

**`enum` 的 case 之間要空行，`switch` 的 case 之間不空行**，兩者是不同規則，`formatting.md` 的空行規則表與其後的「避免」條目分別講這兩件事，不是自相矛盾。2026-09-14 裁決 2 講的是後者。`BLTone`、`BLHeatmapDepth`、`BLTypographyStyle`、`BLButtonVariant`、`BLBadgeVariant`、`BLFilterChip.Style`、`BLFilterChip.Size`、`AppLanguage` 的 enum case 維持目前的空行；這些型別內 `switch` 的 case 之間則不得空行。

**enum 的 case 留在型別本體是必然**，「型別本體只留 stored properties 與 Init」這句話不適用於 enum case (語言不允許 case 放 extension)。`Cases` 這個 MARK 分區要刪掉，case 本身不動。

**`BL` 前綴不改**。`findings.md` 有一筆把 `BLAvatar` 標成「避免型別名前綴」，但同一筆的修法文字寫的是「一律加 `BL` 前綴」，規則名與修法互相矛盾；`BL` 前綴是專案既定慣例、全庫一致，本次登記為例外不動。

### 圖表描述子的 protocol 實作搬回 nested type 內

`BLBarChart`、`BLDonutChart`、`BLSparkline` 各有一個 nested 的 `ChartAccessibilityDescriptor`，遵循宣告寫在型別行 (`struct ChartAccessibilityDescriptor: AXChartDescriptorRepresentable`)，但 `makeChartDescriptor()` 的實作拆在檔案層的 `private extension BLBarChart.ChartAccessibilityDescriptor` 裡。

`formatting.md` 的例外三明文「Nested Types 內的小型別遵循宣告在型別行並就地實作，**不再拆 extension**」，所以現況違反的是這一條，不是 MARK 名稱。三個 `// MARK: - AXChartDescriptorRepresentable` extension 整個併回 nested type 內部，該分區隨之消失；`makeChartDescriptor()` 目前缺 `///`，併回去時一併補上。

**替代方案**：把這三個 extension 登記為例外保留原狀。否決理由是 `formatting.md` 對 nested type 沒有留這個口子，而本計劃的既定方針是規範不遷就既有寫法。

### body 內不宣告區域變數，色盤改由 computed property 取得

Shared 內共 12 處 `BLPalette()` 實例化 (實測值)，**只有 7 處在 `body` 或 `makeBody` 內、需要本次處理**：`BLCard`、`BLFilterChip`、`BLBarChart`、`BLDonutChart`、`BLSparkline` 的 `body`，`BLButtonStyle` 與 `BLProgressViewStyle` 的 `makeBody`。這 7 處改成型別上的 private computed property (放 `Computed Properties` 或 `Private Method` 分區)，`body` 只留大框架。

其餘 5 處不動：`BLMetrics`、`BLPalette`、`BLProgressView`、`BLDonutChart` 各自 `#Preview` 內的 4 處 (Preview 不是 `body`)，以及 `Color+Extensions.swift` 的 `blSecondaryLabel`，它本來就是 static computed property、是設計系統對外的單一取色入口。

這同時解掉「body 只放大框架」與「body 內不宣告區域變數」兩條。`BLProgressView.body` 內的 `let clampedValue = min(max(value, 0), 1)` 同樣改成 computed property。

### 次要文字色維持現況，改寫衝突的規則文字

`BLPalette.secondaryLabel` 是 `Color(uiColor: .label).opacity(0.6)`，表面上與 `.claude/rules/ios-design-system.md`「層級用字重與字級表達，文字不透明度一律為 1」衝突。**但同一份規則文件另有一句更硬的約束**：「資訊性次要文字用 `Color.blSecondaryLabel`，不用系統 `.secondary`：系統 `secondaryLabel` 淺色對比低於本專案 4.5:1 的文字地板」。也就是說目前的寫法是為了通過 `ContrastComplianceTests.secondaryLabelTextMeetsTheTextFloor` 的 4.5 門檻而刻意選的，換成系統色會讓那條測試轉紅。

兩條規則衝突時以對比地板優先，所以**程式碼不動**，改的是規則文字：把「文字不透明度一律為 1」改寫成「不透明度不得用於呼叫端自訂降階；色盤內為達到對比地板而定義的單一次要文字色除外，理由是系統 `secondaryLabel` 在淺色下未達 4.5:1」。這不是放寬規則，是把既有的、有實測依據的例外寫明，避免下一個人重蹈這次的誤判。

**替代方案一**：改用系統 `Color(uiColor: .secondaryLabel)`。否決理由見上，規則文件已載明它不達標。
**替代方案二**：在 asset catalog 定義一組達 4.5:1 的次要文字色 (含 Any／Dark 與 High Contrast 變體)，比照 `BLTone` 的做法。否決理由是要新增色彩資源並重新驗證全 App 對比，範圍遠超過本步的排版與分層目標；這條列為後續可考慮的方向。

### 七筆判讀級 findings 的逐筆處置

`findings.md` 有 7 筆需要人判斷才能決定修或不修，逐筆定案如下，實作時照這裡寫的做並在 `findings.md` 填上對應結論：

| 位置 | 項目 | 處置 |
|---|---|---|
| `BLPalette.secondaryLabel` | `.opacity(0.6)` 與色彩規則衝突 | **程式碼不修，改規則文字**，見上一節 |
| `BLPalette` 型別本身 | 無 stored property 的 struct，46 處 `BLPalette()` | **不修**，登記待專案處理。改成 enum namespace 要動 46 個呼叫點，多數在第 3 至 8 步的 Feature 檔，與本步「呼叫端只做最小改動」衝突 |
| `BLFormatters.percent(scaled:)` | `+ "%"` 串接不隨 locale | **修**：改成 `(value / 100).formatted(.percent…)`，輸出字串維持一位小數，由 `BLFormattersTests` 既有的 `percent` 斷言確認逐字不變 |
| `BLTone.namedColor(role:)` | 以字串傳 role，拼錯會靜默回退系統色 | **修**：role 改成 `BLTone` 內的 private enum，四個呼叫點改傳 case |
| `BLProgressViewStyle` | 與 `BLProgressView` 同檔 | **修**：拆成 `Components/Progress/BLProgressViewStyle.swift` |
| `BLProgressView` 的 `spacing: 5`、軌道 `height: 6` | 未經 token 的間距 | **不修**，登記例外：`BLSpacing` 沒有 5 與 6 這兩級，為了兩個一次性數值新增 token 會讓尺寸系統長出只用一次的階，理由寫進 `findings.md` |
| `BLProgressView` 的百分比格式化 | 用 `.percent` 就地格式化、未走 `BLFormatters` | **修**：`BLFormatters.percent(_:locale:)` 新增 `fractionLength` 參數 (預設 1，維持既有呼叫端行為)，`BLProgressView` 改呼叫它並傳 0，locale 由 `@Environment(\.locale)` 取得。**顯示逐字不變** (仍是 `42%`)，`BLFormattersTests` 既有的 `percent` 斷言也不受影響 |

**兩個 API 改動的呼叫端範圍已確認**，都不會溢出 allowlist：

- `BLFormatters.percent(_:locale:)` 新增的 `fractionLength` **預設 1**，既有 7 處 production 呼叫端 (`InsightsStats` 1 處、`DashboardView` 4 處、`CampaignDetailView` 1 處、`OrderFormatters` 1 處) 與 `BLFormattersTests` 的 8 條斷言都不必改、輸出不變；只有 `BLProgressView` 傳 0。另一個多載 `percent(scaled:locale:)` 只有 `QuoteView` 1 處呼叫，它改的是內部串接方式、簽章不變，呼叫端同樣不動。
- `BLTone.namedColor(role:)` 的 4 個呼叫端全在 `BLTone.swift` 自己檔內，改 private enum 不影響其他檔。

### CurrencyDisplayName 的檔案樣板

`file-templates.md` 的樣板選擇表沒有「共用工具型別」這一類。`CurrencyDisplayName` 是無 case 的 `enum` 命名空間加 static 函式，形狀與 `assets/templates/domain/Enum.swift` 最接近，**以該樣板為起點**，刪掉樣板的 `case example` 與用不到的空分區，分區用 `Internal Method` 與 `Private Method`。這與 `BLFormatters`、`PhotoDataProcessor` 等既有共用工具型別的寫法一致，不另外登記例外。

### 新增 Shared 對 Core 領域型別的分層守門

`LayerBoundaryTests` 新增一條測試，掃描 `apps/ios/BuyLedger/Shared/DesignSystem/` 底下的 Swift 檔是否引用 `apps/ios/BuyLedger/Core/Domain/` 的頂層宣告名稱，重用該檔既有的 `topLevelDeclarationNames` 擷取、`stripCommentsAndStrings` 註解剝除與 `findViolations` 機制。

**但不能直接重用 `swiftFiles(under:)`**：它以 `excludedDirectoryName = "Generated"` 排除生成檔目錄，而本次要擋的三個型別裡，`OrderStatus` 與 `CurrencyCode` 的型別宣告**只存在於** `Core/Domain/Generated/OrderStatus.generated.swift` 與 `CurrencyCode.generated.swift` (手寫的同名檔只有 extension)。沿用現有排除規則的話，新測試收集到的領域型別名稱清單裡不會有這兩個符號，守門會在最重要的兩個型別上空跑。

做法：為領域型別名稱的收集另寫一個可包含 `Generated/` 的檔案列舉，或給 `swiftFiles` 加一個是否排除生成檔的參數；既有的 `coreAndSharedDoNotReferenceFeatureTypes` 維持原本的排除行為不變。新測試的名稱清單至少要涵蓋 `OrderStatus`、`CurrencyCode`、`PaymentMethodFlags` 三個符號，實作時以斷言或除錯輸出確認這三個名字真的在清單內，再談掃描結果。

掃描範圍限 `Shared/DesignSystem/`，不含 `Shared/Localization/`、`Shared/Extensions/` 與 `Shared/Media/`：`app-layer-boundaries` 允許 Shared 依賴 Core，本次收緊的是 Design System 這一子層。

同時新增一條測試確認 `Shared/DesignSystem/` 不出現 `import ComposableArchitecture`。

`DesignSystemSourceScanTests` 新增幣別顯示名稱的單一入口掃描，直接複用該檔既有的 `findViolations`、`swiftFiles`、`stripCommentsAndStrings` 與豁免標記機制，掃描完整 production root，allowlist 僅為 `Shared/Localization/CurrencyDisplayName.swift`。

### 呼叫端只做最小改動

本次改到的 Feature 檔僅限於因簽章或入口改變而必須跟著改的行：

- `Features/Orders/Components/OrderStatus+Presentation.swift`：加入 `sidebarHue(in:)`、改 import。
- `Features/App/RootSidebarLayout.swift`：`SmartGroup.color(in:)` 改呼叫 `status.sidebarHue(in:)`。
- `Features/Lookups/LookupManagementView.swift`：兩處 `PaymentMethodEditorSheet` 呼叫改傳三個 Bool 並組回 `PaymentMethodFlags`。
- `Features/Settings/SettingsView.swift`、`Features/Quote/QuoteView.swift`、`Features/FX/FxView.swift`、`Features/Orders/OrderEditView.swift`、`Features/Orders/Components/OrderDetailView.swift`：刪除各自的 `currencyDisplayText`，改呼叫 `CurrencyDisplayName.text(code:language:)`。
- `Features/Settings/SettingsView.swift`、`Features/FX/FxView.swift`、`Features/Quote/QuoteView.swift`、`Features/Orders/OrderEditView.swift` 的幣別 picker：`displayName` 改呼叫 `CurrencyDisplayName.text(code:language:)`、`searchKeywords` 改呼叫 `CurrencyDisplayName.searchKeywords(code:locale:)`，共 8 處。
- `Features/Customers/CustomersView.swift`：`customerRow` 的 `BLAvatar(size: 36)` 與分隔線的 `BLSpacing.large + 36 + BLSpacing.small` 改由單一定義推導。**維持目前的 36pt 視覺**，在 `CustomersView` 宣告一個 `@ScaledMetric` 實例屬性 (基準值 36)，頭像與內縮都從它取值；不改用 `BLListMetrics.avatarSize` (那是 40，會改變頭像大小)，也不用 static 常數 —— `.claude/rules/ios-accessibility-localization.md` 明文「固定點數的尺寸一律 `@ScaledMetric`，`static let` 尺寸常數要改成實例屬性」。
- 使用 `OptionPickerSheet` 的 `onAddPaymentMethod` 的呼叫端：改傳三個 Bool 的 closure。實測 13 個 `OptionPickerSheet` 建構點中只有 `OrderEditView.pickerDestination` 一處傳這個參數，其餘不受影響；allowlist 列出的 `OrdersView.swift` 是預留的安全範圍，不是已知待改檔。

這些檔自身的 MARK 段名、body 邊界、doc comment 等違規不在本次範圍。

## Implementation Contract

**行為**：只有一項可觀察行為改變，其餘完全不變。

- **改變 (使用者知情裁決)**：四個幣別 picker 的列標題從「代碼加分隔符加名稱」改為與畫面其他地方一致的語系規則，中文顯示「新台幣」、英文顯示「TWD」。改前 `SettingsView`、`FxView`、`QuoteView` 顯示「TWD · 新台幣」、`OrderEditView` 顯示「TWD (新台幣)」，改後四者相同。已確認 `apps/ios/BuyLedgerUITests/` 與 `apps/ios/BuyLedgerTests/` 沒有任何測試以這些字串定位或斷言。
- **跟著改變**：幣別選項列的無障礙朗讀文字。`OptionPickerSheet.listOptionRow` 的 `Button` 沒有自訂 `accessibilityLabel`，標籤由 `Text(displayText(for:))` 產生，所以朗讀內容一律等於列上看到的文字。這是預期結果：看到什麼就讀到什麼。
- **搜尋行為要精確描述，不是「完全不變」**。`OptionPickerSheet.filteredOptions` 依序比對顯示文字、`searchKeywords`、選項原值三者。改動後：以 ISO 代碼搜尋仍由選項原值命中、以幣別名稱搜尋仍由 `searchKeywords` 命中，**這兩種實際使用情境的結果集合不變**；但以舊列標題的組合字串搜尋 (例如 `·`、`TWD ·`、`(新台幣)`) 改動後不再命中，因為那段文字已不存在。驗收以前兩種情境為準。
- **不變**：畫面版面、可選項目、可用動作、以代碼或名稱搜尋的結果、畫面上其他位置的幣別文字、進度列右側的百分比文字 (見下方七筆處置表，改走 `BLFormatters` 但精度維持 0 位)、狀態色點顏色、轉圈延遲時間、照片降採樣結果。

**對外介面變更**：

| 介面 | 改動前 | 改動後 |
|---|---|---|
| `BLStatusHue.color(for:in:)` | `static func color(for status: OrderStatus, in palette: BLPalette) -> Color` | 刪除；改為 `OrderStatus.sidebarHue(in palette: BLPalette) -> Color` |
| `PaymentMethodEditorSheet.SubmitAction` | `(_ name: String, _ flags: PaymentMethodFlags) -> Void` | `(_ name: String, _ isCardless: Bool, _ isBankTransfer: Bool, _ isCashOnDelivery: Bool) -> Void` |
| `PaymentMethodEditorSheet.init` 的 `initialFlags` | `PaymentMethodFlags = .none` | 三個 `Bool = false` 參數 |
| `OptionPickerSheet.onAddPaymentMethod` | `((String, PaymentMethodFlags) -> Void)?` | `((String, Bool, Bool, Bool) -> Void)?` |
| 畫面上的幣別名稱 | 5 個 View 各自的 `currencyDisplayText` | `CurrencyDisplayName.text(code: String, language: AppLanguage) -> String` |
| 幣別 picker 列標題 | 3 個 View 用 `"代碼 · 名稱"`、`OrderEditView` 用 `"代碼 (名稱)"` | 同上的 `text(code:language:)`，四者統一 |
| 幣別 picker 搜尋關鍵字 | 4 個 View 各自的 `searchKeywords` closure 內查表 | `CurrencyDisplayName.searchKeywords(code: String, locale: Locale) -> String`，行為與現況相同 |
| `PaymentMethodEditorSnapshot` (private) | `let flags: PaymentMethodFlags` | 三個 `Bool` 欄位 |
| `BLFormatters.twd(_:locale:)` | 內部讀 `CurrencyCode.twd.code` | 內部用字面 ISO 代碼，簽章不變 |

**失敗模式**：

- `CurrencyDisplayName.text` 對未知代碼不拋錯、不回傳空字串，回退傳入的 ISO 代碼原值。
- `BLDelayedProgressView` 的 sleep 被取消時不顯示轉圈、不記錄診斷，這是刻意靜默並在程式碼中以註解說明理由。

**驗收條件**：

1. **機械檢查**：本次變更的每個 Swift 檔，行寬不超過 100 (以 python3 按字元計算，不用 `awk length`，因為 macOS awk 按位元組算會把中文註解誤判)、無尾隨空白與 tab、手寫檔第 5 行為 `//  Created by Leo Ho on YYYY/M/D.` 格式。三項各自輸出 0 筆。
2. **分區檢查**：本次變更的每個 Swift 檔，`grep` 出的 `// MARK:` 段名全部落在 `formatting.md` 允許的清單內 (protocol 名稱屬於允許清單)，逐檔記錄段名與順序。
3. **分層守門轉紅**：兩條 `LayerBoundaryTests` 測試各做一次變異驗證 (暫時在 `Shared/DesignSystem/` 內引用一個 `Core/Domain/` 型別、暫時加入三種帶前置 attribute 或子符號的 `ComposableArchitecture` import 變體)，每次都要看到對應測試由綠轉紅且 xcresult 可解析、執行數大於 0；驗證後還原。領域型別掃描的變異要用 `OrderStatus` 或 `CurrencyCode` 這兩個宣告在 `Generated/` 的型別，TCA 變異要涵蓋 `@preconcurrency import`、`@_spi(Internals) import` 與 `import struct ...`。
4. **單一入口生效**：production Swift 內 `grep -rn "currencyDisplayText"` 無輸出，`grep -rn "localizedString(forCurrencyCode"` 只剩 `CurrencyDisplayName.swift` 自身；`DesignSystemSourceScanTests` 以 production root 守門，`CurrencyDisplayNameTests` 涵蓋兩個入口各自在正體中文、英文與未知代碼下的輸出，共六種組合。
   - **`grep` 範圍限 production Swift 與現行規則文件** (`apps/ios/**/*.swift`、`apps/ios/CLAUDE.md`、`.claude/rules/`)。`openspec/specs/**` 的 `<!-- @trace -->` 區塊是歸檔工具自動產生的歷史紀錄，root `CLAUDE.md` 明文不可信也不可手改，不納入任何符號歸零的判定。
5. **完整回歸**：以 `BuyLedger.xctestplan` 跑完整單元測試，結果不得比開工前 baseline 更差 (測試數不減少、通過數不減少、失敗清單是 baseline 的子集)；跑之前先鎖模擬器淺色外觀。回歸的 xcresult 時間必須晚於最後一次改檔。
   - **baseline 與各次回歸的數字一律記在 `tasks.md` 的對應 task 行下方**，內容為測試總數、通過數、失敗清單與 result bundle 的絕對路徑；後續 task 引用「0.2 baseline」時指的就是那裡的紀錄。結論寫在別處或只存在對話裡都不算數。
6. **UI 回歸**：iPhone 與 iPad 各跑一次 `BuyLedgerUITests` 主回歸，因為本次動到 `OptionPickerSheet` 與 `PaymentMethodEditorSheet` 的簽章與 `RootSidebarLayout` 的色點。
7. **spectra 檢查**：`spectra validate shared-designsystem-style-compliance` 通過。

**範圍邊界**：

可改動的檔案為以下清單。**遇到清單外必須改動的檔案就停下來回報，不要自行擴張範圍** (第 1 步的經驗是 allowlist 一定會估得太窄，四次邊界詢問四次都問對了)：

- `apps/ios/BuyLedger/Shared/` 底下全部 Swift 檔。完工後檔數為 35 - 1 (`BLStatusHue.swift` 刪除) + 5 (`CurrencyDisplayName.swift`、`BLPhotoThumbnailButtonStyle.swift`、`BLProgressViewStyle.swift`、`BLSearchableModifier.swift`、`OptionPickerList.swift`) = 39 檔
- `apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift`
- `apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift`
- `apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift`
- `apps/ios/BuyLedger/Features/Settings/SettingsView.swift`
- `apps/ios/BuyLedger/Features/Quote/QuoteView.swift`
- `apps/ios/BuyLedger/Features/FX/FxView.swift`
- `apps/ios/BuyLedger/Features/Orders/OrderEditView.swift`
- `apps/ios/BuyLedger/Features/Orders/OrdersView.swift`
- `apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift`
- `apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift` (r12 進度列型別更名的必要連帶)
- `apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift` (r12 進度列型別更名的必要連帶)
- `apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift` (r12 進度列型別更名的必要連帶)
- `apps/ios/BuyLedger/Features/Insights/InsightsView.swift` (r12 進度列型別更名的必要連帶)
- `apps/ios/BuyLedger/Features/Customers/CustomersView.swift` (只改 `customerRow` 的頭像尺寸與分隔線內縮這兩處)
- `apps/ios/BuyLedgerTests/LayerBoundaryTests.swift`
- `apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift`
- `apps/ios/BuyLedgerTests/ContrastComplianceTests.swift`
- `apps/ios/BuyLedgerTests/BLFormattersTests.swift`
- `apps/ios/BuyLedgerTests/BLPhotoViewerTests.swift`
- `apps/ios/BuyLedgerTests/PhotoDataProcessorTests.swift`
- `apps/ios/BuyLedgerTests/CurrencyDisplayNameTests.swift` (新增)
- `apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift` (補搜尋操作與列標籤讀取)
- `apps/ios/BuyLedgerUITests/Tests/Tools/CurrencyPickerTests.swift` (新增)
- `apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift` (只補 `openCurrencyPicker()`，`CurrencyPickerTests` 要涵蓋訂單編輯的幣別入口時需要)
- `apps/ios/CLAUDE.md`、`.claude/rules/ios-design-system.md`、`.claude/rules/ios-accessibility-localization.md`、`.claude/rules/ios-unit-tests.md`、`.claude/rules/ios-ui-tests.md`
- 本 change 目錄下的 `tasks.md` 與 `findings.md`

## Risks / Trade-offs

- **[`BLDelayedProgressView` 改用 `Task.sleep` 後，snapshot 測試的載入態畫面可能改變]** → 目前沒有測試注入該 clock，但 snapshot 若原本靠 `ImmediateClock` 讓轉圈立刻出現，改後轉圈不會出現。開工前的 baseline 回歸已記錄哪些 snapshot 通過；若有 snapshot 因此轉紅，要當作真實行為改變處理並回報，不重錄基準圖。
- **[13 處 `OptionPickerSheet` 呼叫端中只有部分傳 `onAddPaymentMethod`]** → 簽章改動會讓沒傳這個參數的呼叫端不受影響，但要逐一確認，不能只改看得到的那幾處。
- **[刪除 `BLStatusHue` 會讓 `ContrastComplianceTests.statusHueValuesStayMutuallyDistinguishable` 編不過]** → 該測試改呼叫 `status.sidebarHue(in:)`，斷言內容與參數化來源不變，色相互異的守門力不減。
- **[98 筆 MARK 改名是大範圍純文字改動，容易夾帶非預期的程式碼移動]** → 每個檔案的分區改動與程式碼搬移分開檢視，改完逐檔比對段名清單與順序。
- **[`OrderStatus+Presentation.swift` 改 `import SwiftUI` 後，Features/Orders 的其他檔可能出現重複 import]** → 改完檢查該檔 import 排序與是否有被涵蓋的重複 import。
- **[picker 列標題是本次唯一的可見行為變更，可能撞到 snapshot]** → 已確認沒有測試以幣別顯示字串定位或斷言，但涵蓋這四個畫面的 snapshot 若因此轉紅，是預期中的變更而非缺陷，要逐張確認差異只在幣別列的文字，並回報給使用者決定是否重錄；不得未經確認就重錄。
- **[`searchKeywords` 若跟著套語言規則會讓英文搜尋退化]** → 它一律回傳 locale 查表結果、不看 App 語言，這是刻意與 `text(code:language:)` 不同；實作時不要「順手統一」兩者的語言處理。
- **[新增的幣別 picker UI 測試要跑兩種語言，但測試計畫只有一個中文設定]** → 已查證不需要改 `BuyLedgerUITests.xctestplan`：它不列舉測試類別 (只有 `skippedTests: ["LaunchPerformanceTests"]`)，且鎖定的 `zh-Hant`／`TW` 是系統語系；App 內語言另由啟動參數 `-BLUITestLanguage` 覆寫，`LaunchOptions` 已有 `english` 選項。搜尋框是 `.searchable`，用 `app.searchFields` 結構定位即可，不必新增 `BLAccessibilityID` 項目。因此 allowlist 不含 `xctestplan` 與 `BLAccessibilityID.swift`，實作時若發現非改不可，停下來回報。
- **[幣別選項列的無障礙朗讀文字會跟著列標題改變]** → 這是預期行為 (朗讀內容等於看到的文字)，但既有 UI 測試只用選項原值 (ISO 代碼) 的 identifier 定位、不驗證列標籤，所以不會自動抓到。實作時以 `xcodebuildmcp ui-automation` 的 `snapshot-ui` 在中文與英文各取一次幣別 picker 的可及性樹，確認列標籤符合語系規則，截圖與樹的輸出留存。
- **[snapshot 測試在完整回歸下偶發失敗，是這個套件的系統性雜訊]** → 2026-09-19 至 20 實測到**五條**：`quoteViewBaseline`、`orderEditViewLongIdentifierBaseline`、`ordersCompactViewMultiSelectBaseline`、`orderEditViewMergeContextBaseline`、`orderEditViewBaseline`；第 1 步也記錄過其中兩條。雜訊分兩型：
  - **內容型**（`quoteViewBaseline`）：整個文字標籤沒渲染出來，缺的標籤組合每次不同。
  - **像素型**（`orderEditViewBaseline`）：肉眼完全相同，2026-09-20 實測差異只落在 y 12–143 的導覽列區域、佔 0.41% 像素、**最大單通道差值 2**，是工具列按鈕的次像素渲染差異。**四次完整回歸有三次各紅一條、且每次紅的都不是同一條，另一次全綠**，單獨重跑一律通過。
  - **判別法**：單獨重跑該條（方法層 `-only-testing` 必須帶 `()`，並確認 `totalTestCount` ≥ 1），或重跑一次完整回歸；轉綠即為渲染雜訊，**不重錄基準圖、不放寬斷言**。
  - **只有單獨重跑仍穩定失敗才是真回歸**，那時先查 `.claude/rules/ios-unit-tests.md` 的 `@Shared` 跨測試污染一節。
  - task 5.1 要把這條連同四條測試名寫進 `.claude/rules/ios-unit-tests.md` 的 Snapshot 測試一節。
- **[`findings.md` 有已知誤報，照單全改會破壞合規結果]** → 誤報清單寫在「MARK 分區改依 formatting.md 的固定名稱與順序」一節 (protocol 名段名 4 類、`BL` 前綴 1 筆)；實作時逐筆標記為誤報而不是修掉，task 6.4 的結論檢查會看到這些標記。
- **[新增與刪除 Swift 檔是否要改 `project.pbxproj`]** → 已確認 `apps/ios/BuyLedger.xcodeproj/project.pbxproj` 使用 `PBXFileSystemSynchronizedRootGroup` (6 處)，App 與 Tests target 都按目錄同步，新增 `CurrencyDisplayName.swift`、`CurrencyDisplayNameTests.swift` 與刪除 `BLStatusHue.swift` 都不需要手改 pbxproj。
