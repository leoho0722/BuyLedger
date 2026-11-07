---
paths:
  - "apps/ios/BuyLedger/Shared/DesignSystem/**"
  - "apps/ios/BuyLedger/Core/Extensions/**"
  - "apps/ios/BuyLedger/Core/Formatters/**"
  - "apps/ios/BuyLedger/Features/**/*{View,Sheet,Layout,Row,Content,Column,Card,Section,Tile,Tiles,List,Banner,Menu,Field,Destination}.swift"
  - "apps/ios/BuyLedger/Features/**/Components/**"
  - "apps/ios/BuyLedger/Resources/Assets.xcassets/**"
  - "apps/ios/BuyLedgerTests/Guards/DesignSystemSourceScan/*.swift"
  - "apps/ios/BuyLedgerTests/Shared/DesignSystem/ContrastComplianceTests.swift"
---

# iOS Design System 與視覺

## 結構

- **Design System 放 `Shared/DesignSystem/`**：`Foundations/` 放 token、modifier 與語意模型，`Components/` 放可視元件並依類別分子資料夾。
- **一個主要元件一個檔，檔名對應型別名** (`BLBarChart.swift`)，不建立涵括多個元件的大檔 (`BLCharts.swift`)。
    - 只服務單一元件的小型 enum 或 extension 可同檔；開始跨元件重用或變大時拆出。
- **每個可視元件都有自己的 `#Preview`**：binding 用 `.constant(...)`，資料用小型 sample data。
- **調整結構或元件後 iPhone 與 iPad 各 build 一次**，確認 file system synchronized groups 拾取了新增、搬移、刪除的檔案。
- **可重用的 `ViewModifier` 各自一檔，放 `Shared/DesignSystem/Foundations/ViewModifiers/`**。
- **零呼叫點的元件直接刪除**：留在 Design System 目錄等同背書為標準作法。
- **元件上移到 `Shared/DesignSystem/` 須同時滿足三條件**：不綁 store、以 closure 與呼叫端溝通、不依賴任何 Feature 型別；任一不滿足就留在 feature 底下，即使被多個 feature 呼叫。
    - 帶領域詞彙不構成上移理由 (`PaymentMethodEditorSheet` 以布林旗標參數化才得以上移)；每個新元件都逐條核對三條件。
- **與特定元件耦合的 extension 留在元件檔**：`blCardShadow()`／`blTextStyle()` 與其 `ViewModifier` 同檔，`ButtonStyle where Self == BLButtonStyle` 的工廠留在 `BLButtonStyle.swift`。
    - 可獨立重用的通用 extension 才抽出，依 kit 放 `Core/Extensions/`，一型一檔 `<型別>+Extensions.swift`。

## 單一來源

- **必須對齊的尺寸由單一來源推導，不各自寫死** (`BLListMetrics.dividerInset` 由 `avatarSize` 推導)：各自寫死會在一方改動時默默錯開。
- **金額與百分比格式化依 kit 寫成自訂 `FormatStyle` (放 `Core/Formatters/`)，畫面以 `Text(_:format:)`／`formatted(_:)` 套用，不各自重寫等價設定**；要用 `<Feature>Formatters` 靜態函式時先與使用者個案討論。
    - 現有靜態函式遷移前維持：`OrderFormatters`／`CampaignFormatters` 只保留 feature 專屬方法，TWD 金額與比例百分比一律委派 `BLFormatters`。
    - 兩個 `shortDate` 同名但格式不同 (`OrderFormatters` 用 `.month(.defaultDigits).day(.defaultDigits)`、`CampaignFormatters` 用 `.month(.abbreviated).day()`)，遷移時也不可合併。
- **字級一律走 `BLTypographyStyle` token**：View 用 `.blTextStyle(_:)`，需要 `Font` 值才用 `BLTypographyStyle.<case>.font`，不手寫 `.font(.footnote)` 等字面值。
    - token 沒內建的字重用 `BLTypographyStyle.<case>.font.weight(_:)` 組合。
    - 只有代表獨立具名層級的字重才新增 case (如 `title3Bold`)；純強調用的組合 (`subheadline` 搭 `.semibold` 等) 不論出現幾次都留在呼叫端。
    - `.bold()` 與 `.weight(.bold)` 的 snapshot 光柵化結果不同，收斂時沿用原寫法，兩者不可互換。
    - 隨元件尺寸等比縮放的字級 (`BLAvatar` 縮寫、`@ScaledMetric` 驅動的數字) 維持 `.font(.system(size:))`。
- **版面不以全 App 尺寸分類政策判定**：各功能依自身可用區域與環境調整 (閱讀寬度見下方)，不建立全域的 compact／regular 分類；根導覽的分頁列與側邊欄由原生 `TabView` 決定。
    - `DesignSystemSourceScanner` 的尺寸分類器 (規則十一) 不掃 production，只由詞法案例測試 (`sizeClassViolations_規格範例表各列_分類結果符合預期`) 使用；詞法保證只涵蓋剝除器建模的形式：`//` 行註解、非巢狀的 `/* … */` 區塊註解、單行與多行一般字串。字串內插、原始字串與擴充分隔符號 (`#"…"#`)、正規表示式字面值、巢狀區塊註解在保證範圍外，遇到這些形式時人工複核。
    - split view 的欄位可能回報與視窗不同的尺寸分類 (例如 content 欄的水平分類為 compact)，不以欄位的尺寸分類推導版面。
- **閱讀寬度依容器選修飾**：`ScrollView`／`List`／`Form` 這類捲動容器用 `blReadableScrollContent(_:)` (以 `contentMargins` 限寬)，非捲動的內容區塊用 `blReadableContent(_:)`；不包整個 `NavigationSplitView` 或導覽列。
    - 閱讀寬度修飾跨越上限時只能更新可選邊距，不得切換 view 結構；避免重建容器與其內部焦點、`@State` 或捲動位置。
    - `ScrollView` 的置中邊距計算：
        - `size.width` 已扣水平安全區。
        - `.scrollContent` 邊距再加在安全區之後；計算置中邊距時不再扣 `safeAreaInsets`。
    - `List`／`Form` 的安全區處理：
        - 必須直接對 `List`／`Form` 值呼叫專用 overload；若先接上其他修飾並把值轉成一般 `View`，會改選一般 overload。
        - `.scrollContent` 的左右閱讀邊距分別設定 `.leading` 與 `.trailing`，各自納入對應的幾何安全區；純函式測試邊距計算，實際列位置以 live UI 幾何量測確認。
        - 渲染測試 host 以 `additionalSafeAreaInsets` 注入安全區時，`List`／`Form` 會自行避開；真實裝置與分欄內容不會，因此不以渲染測試驗證 `List`／`Form` 的安全區置中。
    - `.scrollContent` 邊距與列本身的 `listRowInsets` 各自控制不同層級；設定閱讀上限時保留列內距，並把列限制在安全區內。
    - 例外：內容本身已用 `GeometryReader` 給明確寬度的捲動畫面 (訂單詳情 `OrderDetailContentView`) 只把上限換成 `BLReadableContentType` 的對應值，不再疊加 `blReadableScrollContent`：兩套限寬各自量測容易分歧，拿掉明確寬度又會改變內部圖表收到的尺寸。
- **清單列要呈現共用卡片外觀時用 `BLCardRowBackground`／`BLCardRowPosition` 逐列給背景** (`listRowBackground`＋`cardRowInsets`)，不把多列包進一張 `BLCard`：分欄清單的每個選取項目必須是直接列。分組標題列另設 `.environment(\.defaultMinListRowHeight, 0)` 的清單才不會被最小列高撐高。

## 色彩

- **系統色與語意色經 `Color+Semantic.swift` 的色盤成員取用，系統取色介面 (`Color(uiColor: .systemXxx)`) 只出現在該檔**：系統色是隨外觀、增強對比與 vibrancy 調整的動態色，不手抄十六進位值。
    - 成員宣告在 `extension ShapeStyle where Self == Color`：有型別脈絡 (`ShapeStyle` 泛型參數、`Color` 參數或回傳值、`[Color]` 字面值) 時寫前置點 `.blX`，沒有型別脈絡時 (如 `let color = Color.blAccent`) 才寫 `Color.blX`。
    - 從原始分量建構色彩 (十六進位、RGB、色彩空間) 只允許 `Color+Semantic.swift` 與 `BLAvatar` (演算法漸層)。
    - 具名系統色 (強調色、綠、橘、紅、藍等) 不得直接取代色盤色，只有白、黑、透明例外。
- **資訊性次要文字用 `.blSecondaryLabel`，不用系統 `.secondary`**：系統 `secondaryLabel` 淺色對比低於本專案 4.5:1 的文字地板；section footer 也不豁免。
- **不設全域 tint，`AccentColor` 資源維持空值**：全域 tint 會把整個 App 強制上色；自訂元件的強調色取 `.blAccent`。
- **色彩不做亮暗分支，view 不為取色宣告 `@Environment(\.colorScheme)`**：唯一例外是 `BLCardShadow.swift` (深色需要不同陰影不透明度)。
- **語意色依「疊在什麼底色上」選 `BLTone` 四軌**：
    - `BLTone` 的軌道都是讀 asset catalog 具名資源的計算屬性，不收色盤參數 (外觀與 Increase Contrast 由系統依 trait 解析)。
    - 文字疊在卡片、列背景或 `background` 淡底用 `onSurface`。
    - 本身是圖形 (狀態點、進度填色、實心徽章底) 用 `indicator`；文字疊在 `indicator` 實心底上用 `onIndicator`。
    - 色值定義在 asset catalog 的 `BLTone<Tone><Role>` (Any／Dark 各含 High Contrast 變體)，不在程式碼計算：程式碼表達不了 Increase Contrast。
    - 具名色彩資源缺失時 SwiftUI 會靜默回退系統預設色：新增 Color Set 與引用它的程式碼同批合入，並逐一目視確認顏色。
    - 旁有文字標籤的圖形 (如膠囊色點) 屬裝飾，豁免 3:1 並標 `.accessibilityHidden(true)`；3:1 只約束單獨承載意義的圖形。
- **訂單狀態色由 `OrderStatus.tone` 統一映射到 `BLTone`**：依狀態的語意選色，畫面再依背景取對應色彩軌道。
    - 呼叫端不內嵌狀態到顏色的映射；新增訂單狀態時窮舉 switch 會逼出色調指派。
- **資料型別帶語意色調與方向，不持有 `Color`，由畫面換算色彩**：如 `InsightsCostSegment.tone`、走勢方向 `BLTrend` (`init(delta:)` 依差值正負判定)；綠、紅、三級文字色等換算留在畫面的 Private Method。
- **`Shared/DesignSystem/` 不得引用 `Core/Domain/` 的領域型別，也不得 import `ComposableArchitecture`**：領域值由呼叫端轉成 primitive 或 Design System 自有型別，架構框架的依賴容器只留在 Feature 層。
    - `LayerBoundaryTests` 掃描 `Shared/DesignSystem/` 與包含 `Generated/` 的 `Core/Domain/` 宣告清單，並以 mutation test 驗證兩條分層規則會轉紅；TCA import 比對必須涵蓋前置 attribute、限定 import 與子符號。
- **幣別顯示名稱只能由 `CurrencyDisplayName` 提供**：`DesignSystemSourceScanTests` 掃描完整 production root，allowlist 僅為 `Shared/Localization/CurrencyDisplayName.swift`，避免任何 Feature 或其他 Shared 模組重新建立 Foundation 查表。
- **語言判斷只能由 `AppLanguage(locale:)` 提供**：`DesignSystemSourceScanTests` 同樣掃描完整 production root，allowlist 僅為 `Shared/Localization/AppLanguage.swift`；畫面不得自行以 `languageCode?.identifier` 比對 locale，否則兩個畫面的語言判斷不一致時沒有任何測試會偵測到。
- **彩底 hero 卡一律用 `.blHeroCardBackground()`**，不以系統色自組漸層，也不在其他地方讀取 `BLHeroGradientStart`／`End` 資源 (由 `BLHeroCardBackground.gradientColors` 直接讀這兩個 asset)。
    - hero 卡文字固定 `.foregroundStyle(.white)` 是刻意例外 (疊在受測漸層上取得最高對比)。
    - `BLHeroGradientStart`／`End` 沒有 High Contrast 變體，新增依賴此漸層的畫面時留意。
- **層級用字重與字級表達，呼叫端不得用不透明度自訂降階**：色盤內為達到本專案 4.5:1 文字對比地板而定義的單一次要文字色是例外；實測顯示系統 `secondaryLabel` 在淺色外觀下未達該門檻，因此 `.blSecondaryLabel` 保留 `.opacity(0.6)`。
- **不以實色模仿系統 bar、不以半透明色模仿玻璃材質**：需要 bar 底用 `.background(.bar)` 並讓捲動內容延伸到下方。
- **`DesignSystemSourceScanTests` 以掃描守門色彩、幣別名稱、語言判斷，以及元件縮放參數的傳值 (規則十二，見 `ios-accessibility-localization.md`)**：色彩、幣別與語言規則需要例外時，在違規那一行加 `// design-system-scan-exempt: <理由>` (理由不可空)；規則十二不接受豁免標記，帶理由的標記也一樣失敗。
    - 色相名稱清單 `namedHueTokenPattern` 是封閉集合，SwiftUI 新增具名系統色時要同步補進它的兩個交替。
- **對比門檻由 `ContrastComplianceTests` 把關** (helper 為 `ColorContrast`)。

## 系統元件與互動

- **系統已提供的能力不自己重造** (搜尋、分段選擇、進度、列按壓回饋)：自製版會失去 Cancel 鈕、聽寫、進度語意、列 highlight 等目視檢查看不出的行為。
    - 自訂外觀走樣式擴充點：`ProgressViewStyle` (`BLProgressViewStyle`)、`ButtonStyle` (`BLButtonStyle`)。
    - 進度一律 `ProgressView` + `BLProgressViewStyle`，不用 `GeometryReader` 疊形狀模擬；彩底上以 `track` 參數指定軌道色。
    - 帶標題的進度列由 `BLProgressView` 自行排版標題與目前值，系統 `ProgressView(value:)` 只套 `BLProgressViewStyle` 畫進度條：進度語意留在系統元件；不在 `ProgressViewStyle` 內以 `configuration.label`／`currentValueLabel` 畫文字，整批 snapshot 的離屏渲染會偶發漏畫那段文字。
    - 整個 `BLProgressView` 以 `.accessibilityElement(children: .combine)` 合併，可見文字不隱藏：父層合併朗讀讀的是實際畫出的文字；隱藏文字再給 `ProgressView` 加 `.accessibilityLabel`／`.accessibilityValue`，合併朗讀會缺目前值 (由 `CampaignProgressAccessibilityTests` 守住)。
    - 系統搜尋欄一律透過 `.blSearchable(text:prompt:)` 套用，它內含 `.searchable(placement: .navigationBarDrawer(displayMode: .always))` 並處理聚焦游標；設定頁值選擇列用 `NavigationLink` + `LabeledContent` + `OptionPickerSheet(isEmbedded: true)`。
- **文字與數字輸入欄一律用 `BLTextField`／`BLNumberField`，不直接宣告 `TextField(`**：聚焦時的游標與清空由元件集中處理，數字欄聚焦即清空草稿，文字欄游標放在既有文字尾端，各畫面自行實作會漏掉其中一項。
    - 允許直接宣告的只有兩個元件本身、`OptionPickerAddSection` (alert 內的輸入欄，alert 只接受原生控制項) 與 Preview 示範；`.searchable` 不經這兩個元件，由 `.blSearchable` 處理，列表內一般輸入欄形式的搜尋 (類別搜尋) 仍用 `BLTextField`。
    - `searchable`、`searchFocused`、`searchSelection` 只出現在 `BLSearchableModifier`：呼叫端另掛焦點或選取會繞過它的游標追蹤，由 `InputFieldConventionScanTests` 守門。
    - `InputFieldConventionScanTests` 掃描正式原始碼守門，違規會列出檔案與行號。
- **含工具列 `.borderedProminent` 按鈕的畫面，snapshot 測試改用 `.image(drawHierarchyInKeyWindow: true)`**：離屏渲染會整張變黑，實際執行正常 (參考 `paymentMethodEditorSheet_新增付款方式_顯示空白表單`)。
- **破壞性用 `Button(role: .destructive)` 表達**，`BLButtonStyle` 不提供破壞性變體。
    - 例外：`swipeActions` 內只開啟確認對話框的刪除鈕用一般 `Button` 加 `.tint(.blRed)` (參考 `LookupItemList`)：iPadOS 27 點下 destructive 角色的滑動鈕會先移除列，確認刪除後資料再刪一次，清單列數不符而閃退；破壞性語意由確認對話框承擔。
- **自繪背景的 `ButtonStyle` 自己讀 `@Environment(\.isEnabled)`**，否則停用態看起來與可用時相同。
- **可點擊元素用 `Button`，不用 `onTapGesture`**：手勢沒有按壓態，也不支援 switch control 與外接鍵盤。
- **`ScrollView` 內容不常駐掛 `simultaneousGesture(DragGesture())`**：會搶走捲動的 pan，onChanged 內判斷不做事也擋不住；條件性手勢用 `.simultaneousGesture(_:isEnabled:)`。
- **命中區的 frame 與 `contentShape` 加在 `Button` 標籤內部**，加在外層只增加版面間距。
    - 尺寸取 `BLHitTarget.minimum`；形狀用元件自身形狀 (膠囊用 `.contentShape(.capsule)`)，避免相鄰命中區在圓角處重疊。
    - 需要維持貼齊角落的外觀時用 `.offset(...)` 推回原位；命中區撐高造成的版面位移是必然代價，元件視覺尺寸不變。
- **`Label` 在 `Form`／`List` row 內且後接 `Spacer` 時加 `.labelStyle(.titleAndIcon)`**，否則 icon 與文字被撐到兩端。
- **iPad 有硬體鍵盤焦點時，split list 的選取列會套用系統強調樣式，未指定前景色的文字會轉成單色**：
    - 自訂 `.listRowBackground` 繪製卡片的選取列，主要文字指定色盤前景色 `.blLabel` (參考 `OrdersRegularListColumn.navigableRow`、`CampaignRow.titleLine`)。
    - 使用系統預設選取外觀的列 (`MoreView.entryRow`) 不指定前景色。
    - 離屏 snapshot 與 XCUITest 沒有鍵盤焦點，無法重現此狀態；修改這類列時啟用模擬器硬體鍵盤，以 UI Automation 確認。
- **`List` 列設定 (`listRowInsets`／`listRowSeparator`／`listRowBackground`) 必須是列 View 最外層的修飾**：外面再包 `.onGeometryChange` 等修飾會讓列設定失效 (列內距回到預設、分隔線重現)，`formatting.md` 的 modifier 四組順序不適用於列設定 (參考 `OrderCategoryGrid.gridRow`)。
