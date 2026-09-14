---
paths:
  - "apps/ios/BuyLedger/Shared/DesignSystem/**"
  - "apps/ios/BuyLedger/Shared/Extensions/**"
  - "apps/ios/BuyLedger/Features/**/*{View,Sheet,Layout,Row,Content}.swift"
  - "apps/ios/BuyLedger/Features/**/Components/**"
  - "apps/ios/BuyLedger/Resources/Assets.xcassets/**"
  - "apps/ios/BuyLedgerTests/{DesignSystemSourceScanTests,ContrastComplianceTests}.swift"
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
    - 可獨立重用的通用 extension 才進 `Shared/Extensions/`，一型一檔 `<型別>+Extensions.swift`。

## 單一來源

- **必須對齊的尺寸由單一來源推導，不各自寫死** (`BLListMetrics.dividerInset` 由 `avatarSize` 推導)：各自寫死會在一方改動時默默錯開。
- **金額與百分比格式化走 `BLFormatters`**，畫面不另寫等價的 `.formatted(.currency(...))`／`.formatted(.percent(...))`。
    - `OrderFormatters`／`CampaignFormatters` 只保留 feature 專屬方法，TWD 金額與比例百分比一律委派 `BLFormatters`。
    - 兩個 `shortDate` 同名但格式不同 (`OrderFormatters` 用 `.month(.defaultDigits).day(.defaultDigits)`、`CampaignFormatters` 用 `.month(.abbreviated).day()`)，不可合併。
- **字級一律走 `BLTypographyStyle` token**：View 用 `.blTextStyle(_:)`，需要 `Font` 值才用 `BLTypographyStyle.<case>.font`，不手寫 `.font(.footnote)` 等字面值。
    - token 沒內建的字重用 `BLTypographyStyle.<case>.font.weight(_:)` 組合。
    - 只有代表獨立具名層級的字重才新增 case (如 `title3Bold`)；純強調用的組合 (`subheadline` 搭 `.semibold` 等) 不論出現幾次都留在呼叫端。
    - `.bold()` 與 `.weight(.bold)` 的 snapshot 光柵化結果不同，收斂時沿用原寫法，兩者不可互換。
    - 隨元件尺寸等比縮放的字級 (`BLAvatar` 縮寫、`@ScaledMetric` 驅動的數字) 維持 `.font(.system(size:))`。

## 色彩

- **系統色與語意色經 `BLPalette` 取用，系統取色介面 (`Color(uiColor: .systemXxx)`) 只出現在 `BLPalette.swift`**：系統色是隨外觀、增強對比與 vibrancy 調整的動態色，不手抄十六進位值。
    - 從原始分量建構色彩 (十六進位、RGB、色彩空間) 只允許 `BLPalette.swift` 與 `BLAvatar` (演算法漸層)。
    - 具名系統色 (強調色、綠、橘、紅、藍等) 不得直接取代色盤色，只有白、黑、透明例外。
- **資訊性次要文字用 `Color.blSecondaryLabel`，不用系統 `.secondary`**：系統 `secondaryLabel` 淺色對比低於本專案 4.5:1 的文字地板；section footer 也不豁免。
    - 呼叫端寫 `Color.blSecondaryLabel` 完整形式：它掛在 `Color` 上，`foregroundStyle(_:)` 的前置點縮寫解析不到。不為了支援前置點改成 `extension ShapeStyle where Self == Color` (已決定不做，避免擴大改動面)。
- **不設全域 tint，`AccentColor` 資源維持空值**：全域 tint 會把整個 App 強制上色；自訂元件的強調色取 `BLPalette.accent`。
- **色彩不做亮暗分支，view 不為取色宣告 `@Environment(\.colorScheme)`**：唯一例外是 `BLCardShadow.swift` (深色需要不同陰影不透明度)。
- **語意色依「疊在什麼底色上」選 `BLTone` 四軌**：
    - `BLTone` 的軌道都是讀 asset catalog 具名資源的計算屬性，不收色盤參數 (外觀與 Increase Contrast 由系統依 trait 解析)。
    - 文字疊在卡片、列背景或 `background` 淡底用 `onSurface`。
    - 本身是圖形 (狀態點、進度填色、實心徽章底) 用 `indicator`；文字疊在 `indicator` 實心底上用 `onIndicator`。
    - 色值定義在 asset catalog 的 `BLTone<Tone><Role>` (Any／Dark 各含 High Contrast 變體)，不在程式碼計算：程式碼表達不了 Increase Contrast。
    - 具名色彩資源缺失時 SwiftUI 會靜默回退系統預設色：新增 Color Set 與引用它的程式碼同批合入，並逐一目視確認顏色。
    - 旁有文字標籤的圖形 (如膠囊色點) 屬裝飾，豁免 3:1 並標 `.accessibilityHidden(true)`；3:1 只約束單獨承載意義的圖形。
- **訂單狀態色分兩軌、各有唯一來源**：帶文字標籤的狀態介面走 `BLTone`；側邊欄智慧分組色點走 `BLStatusHue` (八個分組經 `BLTone` 只剩四色，相鄰列會撞色)。
    - 呼叫端不內嵌狀態到顏色的映射；新增訂單狀態時兩邊的窮舉 switch 會逼出色彩指派。
- **彩底 hero 卡一律用 `.blHeroCardBackground()`**，不以系統色自組漸層，也不直接呼叫 `BLPalette.heroGradient`。
    - hero 卡文字固定 `.foregroundStyle(.white)` 是刻意例外 (疊在受測漸層上取得最高對比)。
    - `BLHeroGradientStart`／`End` 沒有 High Contrast 變體，新增依賴此漸層的畫面時留意。
- **層級用字重與字級表達，文字不透明度一律為 1**：降低不透明度會直接損害對比。
- **不以實色模仿系統 bar、不以半透明色模仿玻璃材質**：需要 bar 底用 `.background(.bar)` 並讓捲動內容延伸到下方。
- **`DesignSystemSourceScanTests` 以掃描守門上述色彩入口**：需要例外時在違規那一行加 `// design-system-scan-exempt: <理由>` (理由不可空)。
    - 色相名稱清單 `namedHueTokenPattern` 是封閉集合，SwiftUI 新增具名系統色時要同步補進它的兩個交替。
- **對比門檻由 `ContrastComplianceTests` 把關** (helper 為 `ColorContrast`)。

## 系統元件與互動

- **系統已提供的能力不自己重造** (搜尋、分段選擇、進度、列按壓回饋)：自製版會失去 Cancel 鈕、聽寫、進度語意、列 highlight 等目視檢查看不出的行為。
    - 自訂外觀走樣式擴充點：`ProgressViewStyle` (`BLProgressBarStyle`)、`ButtonStyle` (`BLButtonStyle`)。
    - 進度一律 `ProgressView` + `BLProgressBarStyle`，不用 `GeometryReader` 疊形狀模擬；彩底上以 `track` 參數指定軌道色。
    - 訂單搜尋用 `.searchable(placement: .navigationBarDrawer(displayMode: .always))`；設定頁值選擇列用 `NavigationLink` + `LabeledContent` + `OptionPickerSheet(isEmbedded: true)`。
- **含工具列 `.borderedProminent` 按鈕的畫面，snapshot 測試改用 `.image(drawHierarchyInKeyWindow: true)`**：離屏渲染會整張變黑，實際執行正常 (參考訂單編輯的 baseline 測試)。
- **破壞性用 `Button(role: .destructive)` 表達**，`BLButtonStyle` 不提供破壞性變體。
- **自繪背景的 `ButtonStyle` 自己讀 `@Environment(\.isEnabled)`**，否則停用態看起來與可用時相同。
- **可點擊元素用 `Button`，不用 `onTapGesture`**：手勢沒有按壓態，也不支援 switch control 與外接鍵盤。
- **`ScrollView` 內容不常駐掛 `simultaneousGesture(DragGesture())`**：會搶走捲動的 pan，onChanged 內判斷不做事也擋不住；條件性手勢用 `.simultaneousGesture(_:isEnabled:)`。
- **命中區的 frame 與 `contentShape` 加在 `Button` 標籤內部**，加在外層只增加版面間距。
    - 尺寸取 `BLHitTarget.minimum`；形狀用元件自身形狀 (膠囊用 `.contentShape(.capsule)`)，避免相鄰命中區在圓角處重疊。
    - 需要維持貼齊角落的外觀時用 `.offset(...)` 推回原位；命中區撐高造成的版面位移是必然代價，元件視覺尺寸不變。
- **`Label` 在 `Form`／`List` row 內且後接 `Spacer` 時加 `.labelStyle(.titleAndIcon)`**，否則 icon 與文字被撐到兩端。
