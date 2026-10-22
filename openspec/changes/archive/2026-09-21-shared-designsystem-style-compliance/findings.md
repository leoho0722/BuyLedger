# Shared 區逐檔待修明細

來源：2026-09-14 全庫審查報告 (ios-dev-kit 1.1.0)，取其 Shared 區全部項目並排除 commit `291d841` 已修的尾隨空白 (FM2)。

總計 **334 筆**，涵蓋 35 個檔案：必擋 169、違規 135、建議 29、已登記例外 1。

行號為 2026-09-14 當時的位置，第 1 步 (`core-codegen-style-compliance`) 未改動 Shared，但實作時仍以檔案內容為準、不依賴行號定位。

每筆在實作完成後補上結論：`已修正` / `由任務 X.Y 涵蓋` / `報告誤報 (理由)` / `登記例外 (理由)`。

**已預先標好結論的 10 筆是報告誤報，不要修**：9 筆 MK1 標在以 protocol 名稱命名的 MARK (`ViewModifier`、`ButtonStyle`、`ProgressViewStyle`、`AXChartDescriptorRepresentable`)，`formatting.md` 明文允許這種段名，是掃描腳本的允許清單漏收；1 筆 `S·避免型別名前綴` 的規則名稱與修法文字互相矛盾，`BL` 前綴是專案既定慣例。判定依據寫在 design.md 的「MARK 分區改依 formatting.md 的固定名稱與順序」一節。

## 規則代碼出現次數

| 代碼 | 規則 | 嚴重度 | 筆數 |
| --- | --- | --- | --- |
| `MK1` | MARK 使用規範以外的分區名稱 | 必擋 | 98 |
| `H1` | 檔頭格式不符 (檔名、target、日期 YYYY/M/D) | 違規 | 35 |
| `MK5` | 型別本體內出現方法或 computed property (應放 extension) | 必擋 | 31 |
| `D6` | 註解結尾加中文句號 | 違規 | 15 |
| `S·body 只放大框架` | body 只放大框架 | 必擋 | 10 |
| `D3` | 有回傳值卻缺 - Returns | 必擋 | 10 |
| `S·modifier 四組順序` | modifier 四組順序 | 違規 | 7 |
| `S·手寫 protocol 遵循位置` | 手寫 protocol 遵循位置 | 違規 | 7 |
| `D2` | 有參數卻缺 - Parameter | 必擋 | 6 |
| `D1` | 宣告缺 /// doc comment | 必擋 | 6 |
| `S·body 內區域變數` | body 內區域變數 | 違規 | 5 |
| `FM15` | 超過三個參數卻放在同一行 | 違規 | 5 |
| `CL1` | 兩個以上參數的 closure 用 $1 | 違規 | 4 |
| `S·未經 Token 的間距` | 未經 Token 的間距 | 違規 | 4 |
| `S·Properties 順序` | Properties 順序 | 違規 | 4 |
| `S·DesignSystem 反向依賴` | DesignSystem 反向依賴 | 必擋 | 4 |
| `S·Bool 命名` | Bool 命名 | 違規 | 4 |
| `S·頂層 private 輔助型別` | 頂層 private 輔助型別 | 違規 | 4 |
| `S·複述程式碼的註解` | 複述程式碼的註解 | 違規 | 3 |
| `S·輔助型別改 nested type` | 輔助型別改 nested type | 建議 | 2 |
| `S·命名語意與註解一致` | 命名語意與註解一致 | 違規 | 2 |
| `CL2` | 多行 closure 使用 $0 | 違規 | 2 |
| `S·Private Method 只放純 UI 計算` | Private Method 只放純 UI 計算 | 違規 | 2 |
| `S·Note 以外的自由段落` | Note 以外的自由段落 | 違規 | 2 |
| `S·Private Views 內含互動邏輯` | Private Views 內含互動邏輯 | 違規 | 2 |
| `S·doc 複述名稱` | doc 複述名稱 | 違規 | 2 |
| `FN1` | 檔名與主要型別名稱不一致 | 違規 | 2 |
| `S·doc 與行為不符` | doc 與行為不符 | 違規 | 2 |
| `S·非自己型別的擴充位置` | 非自己型別的擴充位置 | 建議 | 2 |
| `S·避免型別名前綴` | 避免型別名前綴 | 違規 | 1 |
| `S·未經 Token 的圓角` | 未經 Token 的圓角 | 違規 | 1 |
| `S·多餘的轉發屬性` | 多餘的轉發屬性 | 建議 | 1 |
| `S·View 常數放 Nested Types` | View 常數放 Nested Types | 建議 | 1 |
| `S·通用元件寫死領域詞` | 通用元件寫死領域詞 | 建議 | 1 |
| `S·重複實作` | 重複實作 | 建議 | 1 |
| `FM14` | 多行參數的右括號沒有單獨一行 | 違規 | 1 |
| `S·值得測試的計算留在 View` | 值得測試的計算留在 View | 建議 | 1 |
| `S·明確標註 closure 型別` | 明確標註 closure 型別 | 違規 | 1 |
| `S·.map 產生 View` | .map 產生 View | 違規 | 1 |
| `S·命名與既有元件一致` | 命名與既有元件一致 | 建議 | 1 |
| `S·enum case 命名語意` | enum case 命名語意 | 建議 | 1 |
| `S·typealias 用途` | typealias 用途 | 違規 | 1 |
| `S·無作用的狀態` | 無作用的狀態 | 建議 | 1 |
| `FM1` | 行寬超過 100 | 必擋 | 1 |
| `S·元件引用 feature 命名的 identifier` | 元件引用 feature 命名的 identifier | 建議 | 1 |
| `S·doc 標記用法` | doc 標記用法 | 建議 | 1 |
| `S·魔術數字` | 魔術數字 | 建議 | 1 |
| `S·?? 掩蓋 nil` | ?? 掩蓋 nil | 違規 | 1 |
| `S·tuple 與重複的 Preview helper` | tuple 與重複的 Preview helper | 建議 | 1 |
| `S·未經 Token 的字型` | 未經 Token 的字型 | 違規 | 1 |
| `S·nonisolated 需註解` | nonisolated 需註解 | 違規 | 1 |
| `S·常數集中` | 常數集中 | 建議 | 1 |
| `S·Private Method 不得有副作用` | Private Method 不得有副作用 | 違規 | 1 |
| `S·View 不寫格式化` | View 不寫格式化 | 必擋 | 1 |
| `FM4` | 單檔超過 300 行 (不含檔頭與空行) | 違規 | 1 |
| `S·命名與註解語意不符` | 命名與註解語意不符 | 違規 | 1 |
| `S·參數過多` | 參數過多 | 建議 | 1 |
| `S·重複的 toolbar 分支` | 重複的 toolbar 分支 | 建議 | 1 |
| `S·註解與行為不符` | 註解與行為不符 | 違規 | 1 |
| `S·多餘的轉發 View` | 多餘的轉發 View | 建議 | 1 |
| `S·doc 術語與中英夾雜` | doc 術語與中英夾雜 | 建議 | 1 |
| `S·資料過濾留在 View` | 資料過濾留在 View | 違規 | 1 |
| `S·避免 handle 動詞` | 避免 handle 動詞 | 違規 | 1 |
| `S·百分比格式化入口不一致` | 百分比格式化入口不一致 | 建議 | 1 |
| `S·一個主要元件一個檔` | 一個主要元件一個檔 | 建議 | 1 |
| `TC1` | @Dependency 與 var 寫在同一行 | 違規 | 1 |
| `S·DesignSystem 只依賴 SwiftUI` | DesignSystem 只依賴 SwiftUI | 違規 | 1 |
| `S·catch 分散且靜默吞錯` | catch 分散且靜默吞錯 | 違規 | 1 |
| `S·字串串接不隨 locale` | 字串串接不隨 locale | 建議 | 1 |
| `S·doc 不白話` | doc 不白話 | 建議 | 1 |
| `S·型別選擇` | 型別選擇 | 建議 | 1 |
| `SU5` | modifier 與 View 同行 | 違規 | 1 |
| `S·與專案色彩規則衝突` | 與專案色彩規則衝突 | 建議 | 1 |
| `S·命名語意` | 命名語意 | 建議 | 1 |
| `S·字串傳遞列舉值` | 字串傳遞列舉值 | 建議 | 1 |
| `MK4` | extension 專屬分區寫在型別本體內 | 必擋 | 1 |
| `FM0` | 縮排不是 4 格 (開括號後一層) | 必擋 | 1 |
| `S·guard 的 else 只放離開` | guard 的 else 只放離開 | 違規 | 1 |
| `S·型別後綴與 process 動詞` | 型別後綴與 process 動詞 | 違規 | 1 |
| `S·以 Optional 表達失敗` | 以 Optional 表達失敗 | 違規 | 1 |

## 逐檔明細

### DesignSystem/Components/Avatar/BLAvatar.swift

共 7 筆 (必擋 3、違規 4、建議 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLAvatar.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/04/30. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L11 `S·避免型別名前綴` 違規 — 避免型別名前綴 (審查員判讀)
    - 修法：Design System 與共用型別一律加 `BL` 前綴，本批範圍內共 35 個型別 (如 `BLAvatar`、`BLPalette`、`BLTone`、`BLAccessibilityID`、`BLPhotoThumbnailButtonStyle`)，Swift 已有 module 命名空間
    - 結論：報告資料錯誤，不修。規則名稱寫「避免型別名前綴」但修法文字寫「一律加 `BL` 前綴」，兩者互相矛盾；`BL` 前綴是專案既定慣例、全庫一致，登記為例外
- L13 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L27 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L31 `S·body 只放大框架` 必擋 — body 只放大框架 (審查員判讀)
    - 修法：body 直接放 `Text(initials)` 加 8 個 modifier 的實際內容
    - 結論：已修正，body 改為只組合命名後的 private view content
- L36 `S·modifier 四組順序` 違規 — modifier 四組順序 (審查員判讀)
    - 修法：`.frame` (版面) 排在 `.font`／`.foregroundStyle` (外觀) 之後
    - 結論：已修正，依 `formatting.md` 將版面 modifier 排在外觀 modifier 前
- L52 `CL1` 違規 — 兩個以上參數的 closure 用 $1 (腳本掃描)
    - 現況：`let total = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }`
    - 結論：已修正，closure 改用具名參數

### DesignSystem/Components/Badges/BLBadge.swift

共 9 筆 (必擋 5、違規 3、建議 1)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLBadge.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/04/30. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L11 `S·輔助型別改 nested type` 建議 — 輔助型別改 nested type (審查員判讀)
    - 修法：`BLBadgeVariant` 是只服務 `BLBadge` 的頂層型別
    - 結論：已修正，移入所屬元件的 nested `Variant` type，並置於 `Nested Types` extension，保留既有呼叫端的型別推斷
- L13 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Cases`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L25 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L49 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`private var font: Font {`
    - 結論：已修正，computed property 移至 `Computed Properties` extension
- L70 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L76 `S·body 只放大框架` 必擋 — body 只放大框架 (審查員判讀)
    - 修法：body 直接放 Text 與 9 個 modifier，且第 80、82、85 行在 body 內以三元運算子判斷內距與圓角
    - 結論：已修正，body 改為只組合命名後的 private view content
- L78 `S·modifier 四組順序` 違規 — modifier 四組順序 (審查員判讀)
    - 修法：`.font`／`.foregroundStyle` (外觀) 排在 `.padding` (版面) 之前
    - 結論：已修正，依 `formatting.md` 將版面 modifier 排在外觀 modifier 前
- L85 `S·未經 Token 的圓角` 違規 — 未經 Token 的圓角 (審查員判讀)
    - 修法：label 變體圓角寫死 `4`，`BLRadius` 沒有對應 token
    - 結論：登記例外：`BLRadius` 沒有 4 的對應 token，保留既有值以維持 label badge 的視覺

### DesignSystem/Components/Buttons/BLButtonStyle.swift

共 10 筆 (必擋 6、違規 2、建議 2)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLButtonStyle.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/04/30. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L11 `S·輔助型別改 nested type` 建議 — 輔助型別改 nested type (審查員判讀)
    - 修法：`BLButtonVariant` 是只服務 `BLButtonStyle` 的頂層型別
    - 結論：已修正，移入所屬元件的 nested `Variant` type，並置於 `Nested Types` extension，保留既有呼叫端的型別推斷
- L13 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Cases`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L28 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L39 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L42 `D2` 必擋 — 有參數卻缺 - Parameter (腳本掃描)
    - 現況：`func makeBody(configuration: Configuration) -> some View {`
    - 結論：已修正，補上參數與回傳值的 doc comment 標記
- L42 `D3` 必擋 — 有回傳值卻缺 - Returns (腳本掃描)
    - 現況：`func makeBody(configuration: Configuration) -> some View {`
    - 結論：已修正，補上參數與回傳值的 doc comment 標記
- L49 `S·未經 Token 的間距` 違規 — 未經 Token 的間距 (審查員判讀)
    - 修法：按鈕水平內距寫死 `18`，不經 `BLSpacing`
    - 結論：登記例外：`BLSpacing` 沒有 18 的對應 token，保留既有水平內距以維持按鈕視覺
- L63 `S·多餘的轉發屬性` 建議 — 多餘的轉發屬性 (審查員判讀)
    - 修法：`minimumHeight` 只轉發 `BLHitTarget.minimum`，多一層間接
    - 結論：已修正，移除 forwarding property，直接使用 `BLHitTarget.minimum`
- L102 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Static Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱

### DesignSystem/Components/Cards/BLCard.swift

共 4 筆 (必擋 2、違規 2、建議 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLCard.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/04/30. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L13 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L41 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L45 `S·body 內區域變數` 違規 — body 內區域變數 (審查員判讀)
    - 修法：body 宣告 `let palette = BLPalette()`
    - 結論：由任務 3.3 涵蓋，palette／clamped value 已移至 computed property

### DesignSystem/Components/Charts/BLBarChart.swift

共 25 筆 (必擋 9、違規 12、建議 4)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLBarChart.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/04/30. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L15 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L27 `S·View 常數放 Nested Types` 建議 — View 常數放 Nested Types (審查員判讀)
    - 修法：版面常數 `minLabelSpacing`／`minBarSpacing` 以 stored property 夾在可設定參數之間
    - 結論：已修正，layout 常數與抽稀演算法移至 nested `Layout` type
- L30 `S·命名語意與註解一致` 違規 — 命名語意與註解一致 (審查員判讀)
    - 修法：`minBarSpacing` 的註解是「單一長條最小寬度」，名稱卻是間距
    - 結論：修，改名為 `minBarWidth` 並確認 `capacity` 的呼叫端跟著改，由任務 3.5 處理
- L41 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L45 `S·body 內區域變數` 違規 — body 內區域變數 (審查員判讀)
    - 修法：body 宣告 `let palette = BLPalette()`
    - 結論：由任務 3.3 涵蓋，palette 已由 computed property 取得；其餘區域內容在 Private Views 處理
- L54 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - ViewBuilder`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L63 `D3` 必擋 — 有回傳值卻缺 - Returns (腳本掃描)
    - 現況：`func chart(palette: BLPalette, viewportWidth: CGFloat) -> some View {`
    - 結論：已修正，補上 `- Parameter`／`- Returns` doc comment
- L68 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 內容過寬時以水平捲動查看，預設顯示最新資料。`
    - 結論：已修正，移除中文句號並保留必要的原因說明
- L86 `D3` 必擋 — 有回傳值卻缺 - Returns (腳本掃描)
    - 現況：`func barChart(palette: BLPalette, renderWidth: CGFloat) -> some View {`
    - 結論：已修正，補上 `- Parameter`／`- Returns` doc comment
- L91 `S·通用元件寫死領域詞` 建議 — 通用元件寫死領域詞 (審查員判讀)
    - 修法：通用長條圖的 `BarMark` 維度標籤寫死「日期」「金額」，與可設定的 `axisXTitle`／`axisYTitle` 不一致
    - 結論：已修正，BarMark 改用可設定的 `axisXTitle` 與 `axisYTitle`
- L125 `S·手寫 protocol 遵循位置` 違規 — 手寫 protocol 遵循位置 (審查員判讀)
    - 修法：`ChartAccessibilityDescriptor` 在型別行宣告 `AXChartDescriptorRepresentable`，實作卻拆到第 145 行的 extension，兩種寫法混用
    - 結論：已修正，descriptor 的 protocol 實作併回 nested type 內
- L127 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Data Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L143 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - AXChartDescriptorRepresentable`
    - 結論：MARK 名稱本身是誤報 (protocol 名合法)，但該 extension 依 design 的「圖表描述子的 protocol 實作搬回 nested type 內」整個併回巢狀型別，分區隨之消失，由任務 3.5 處理
- L147 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`func makeChartDescriptor() -> AXChartDescriptor {`
    - 結論：已修正，補上方法的摘要與回傳值／參數 doc comment
- L147 `S·重複實作` 建議 — 重複實作 (審查員判讀)
    - 修法：`BLBarChart` 與 `BLDonutChart` 的 `ChartAccessibilityDescriptor` 幾乎逐行相同 (`BLSparkline` 亦類似)
    - 結論：登記例外：三種 AX descriptor 的資料型別與欄位需求不同，本任務只依 design 要求就地實作，不新增跨元件抽象
- L163 `CL2` 違規 — 多行 closure 使用 $0 (腳本掃描)
    - 現況：`AXDataPoint(x: $0.label, y: $0.value, label: $0.valueDescription)`
    - 結論：已修正，多行 closure 改用具名參數
- L167 `FM14` 違規 — 多行參數的右括號沒有單獨一行 (腳本掃描)
    - 現況：`title: nil, summary: nil, xAxis: xAxis, yAxis: yAxis, series: [series])`
    - 結論：已修正，AXChartDescriptor 的多行參數各自換行並將右括號獨立
- L170 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`func updateChartDescriptor(_ descriptor: AXChartDescriptor) {`
    - 結論：已修正，補上方法的摘要與回傳值／參數 doc comment
- L180 `S·Private Method 只放純 UI 計算` 違規 — Private Method 只放純 UI 計算 (審查員判讀)
    - 修法：`accessibilitySummary` 在 View 內找出最高／最低資料並組合朗讀文案，屬資料計算
    - 結論：已修正，摘要計算移入 nested descriptor 的 static helper，View 只轉發結果
- L181 `CL1` 違規 — 兩個以上參數的 closure 用 $1 (腳本掃描)
    - 現況：`guard let highest = data.max(by: { $0.value < $1.value }),`
    - 結論：已修正，max／min closure 改用具名參數
- L182 `CL1` 違規 — 兩個以上參數的 closure 用 $1 (腳本掃描)
    - 現況：`let lowest = data.min(by: { $0.value < $1.value })`
    - 結論：已修正，max／min closure 改用具名參數
- L209 `S·值得測試的計算留在 View` 建議 — 值得測試的計算留在 View (審查員判讀)
    - 修法：`stridedLabels` 的抽稀演算法含錨點取代等邊界分支，符合「值得寫單元測試就搬出 View」
    - 結論：已修正，標籤抽稀演算法移入 nested `Layout.stridedLabels`
- L219 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 補上最後一筆作為右端錨點，太近時取代前一筆。`
    - 結論：已修正，移除中文句號並保留必要的原因說明
- L248 `S·明確標註 closure 型別` 違規 — 明確標註 closure 型別 (審查員判讀)
    - 修法：`compactMap { offset -> BLBarChartValue? in` 明確標註回傳型別
    - 結論：報告誤報，不修；Preview 的 `compactMap` 已有明確的 `BLBarChartValue?` 回傳型別

### DesignSystem/Components/Charts/BLBarChartValue.swift

共 4 筆 (必擋 2、違規 2、建議 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLBarChartValue.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/04/30. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L13 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Identifiable Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L16 `S·手寫 protocol 遵循位置` 違規 — 手寫 protocol 遵循位置 (審查員判讀)
    - 修法：`Identifiable` 的 `id` 是手寫 computed property，遵循卻寫在型別行並放本體；且以 `label` 為 id，重複標籤會撞 id
    - 結論：已修正，將 `Identifiable` 遵循與 `id` 實作移至獨立 extension；既有 label id 語意不在本次 style-only 變更中改動
- L18 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Data Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱

### DesignSystem/Components/Charts/BLDonutChart.swift

共 15 筆 (必擋 7、違規 8、建議 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLDonutChart.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/04/30. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L15 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L27 `S·Properties 順序` 違規 — Properties 順序 (審查員判讀)
    - 修法：`@ScaledMetric` 屬性包裝夾在一般 `let` 與 `var` 之間
    - 結論：報告誤判，不修；`@ScaledMetric` 已位於一般 `let` 與可設定 `var` 之間
- L38 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L42 `S·body 內區域變數` 違規 — body 內區域變數 (審查員判讀)
    - 修法：body 宣告 `let palette = BLPalette()`
    - 結論：由任務 3.3 涵蓋，palette 已由 computed property 取得；其餘區域內容在 Private Views 處理
- L44 `S·body 只放大框架` 必擋 — body 只放大框架 (審查員判讀)
    - 修法：body 內直接寫完整 `Chart` (SectorMark、色彩比例尺、無障礙描述) 與中央文字的 VStack
    - 結論：已修正，body 改為只組合命名後的 private view content
- L51 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 以類別維度驅動配色，讓 Swift Charts 將區段身分帶進無障礙樹。`
    - 結論：已修正，移除中文句號並保留必要的原因說明
- L95 `S·手寫 protocol 遵循位置` 違規 — 手寫 protocol 遵循位置 (審查員判讀)
    - 修法：`ChartAccessibilityDescriptor` 在型別行宣告遵循，實作卻拆到第 115 行 extension
    - 結論：已修正，descriptor 的 protocol 實作併回 nested type 內
- L97 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Data Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L113 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - AXChartDescriptorRepresentable`
    - 結論：MARK 名稱本身是誤報 (protocol 名合法)，但該 extension 依 design 的「圖表描述子的 protocol 實作搬回 nested type 內」整個併回巢狀型別，分區隨之消失，由任務 3.5 處理
- L117 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`func makeChartDescriptor() -> AXChartDescriptor {`
    - 結論：已修正，補上方法的摘要與回傳值／參數 doc comment
- L133 `CL2` 違規 — 多行 closure 使用 $0 (腳本掃描)
    - 現況：`AXDataPoint(x: $0.label, y: $0.value, label: $0.valueDescription)`
    - 結論：已修正，多行 closure 改用具名參數
- L145 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`func updateChartDescriptor(_ descriptor: AXChartDescriptor) {`
    - 結論：已修正，補上方法的摘要與回傳值／參數 doc comment
- L155 `S·Private Method 只放純 UI 計算` 違規 — Private Method 只放純 UI 計算 (審查員判讀)
    - 修法：`accessibilitySummary` 在 View 內找出最大區段並組合朗讀文案
    - 結論：已修正，摘要計算移入 nested descriptor 的 static helper，View 只轉發結果
- L156 `CL1` 違規 — 兩個以上參數的 closure 用 $1 (腳本掃描)
    - 現況：`guard let largest = segments.max(by: { $0.value < $1.value }) else {`
    - 結論：已修正，max／min closure 改用具名參數

### DesignSystem/Components/Charts/BLDonutSegment.swift

共 4 筆 (必擋 2、違規 2、建議 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLDonutSegment.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/04/30. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L13 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Identifiable Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L16 `S·手寫 protocol 遵循位置` 違規 — 手寫 protocol 遵循位置 (審查員判讀)
    - 修法：`Identifiable` 的 `id` 是手寫 computed property (取 `label`)，遵循卻寫在型別行並放本體；`Chart(segments)` 遇重複 label 會撞 id
    - 結論：已修正，將 `Identifiable` 遵循與 `id` 實作移至獨立 extension；既有 label id 語意不在本次 style-only 變更中改動
- L18 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Data Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱

### DesignSystem/Components/Charts/BLSparkline.swift

共 11 筆 (必擋 7、違規 4、建議 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLSparkline.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/04/30. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L14 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L42 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L46 `S·body 內區域變數` 違規 — body 內區域變數 (審查員判讀)
    - 修法：body 宣告 `palette`、`color` 兩個區域變數，GeometryReader 內再宣告 `points` (與方法同名)
    - 結論：由任務 3.3 涵蓋，palette 已由 computed property 取得；其餘區域內容在 Private Views 處理
- L49 `S·body 只放大框架` 必擋 — body 只放大框架 (審查員判讀)
    - 修法：body 的 GeometryReader 內直接畫面積與折線兩條 Path 的完整繪製邏輯
    - 結論：已修正，body 改為只組合命名後的 private view content
- L87 `S·.map 產生 View` 違規 — .map 產生 View (審查員判讀)
    - 修法：`summary.map { Text($0) } ?? Text(verbatim: "")` 以 `.map` 產生 View 並用 `??` 補空 Text
    - 結論：已修正，摘要文字改由 computed `Text` property 以 if-let 組合
- L106 `S·手寫 protocol 遵循位置` 違規 — 手寫 protocol 遵循位置 (審查員判讀)
    - 修法：`ChartAccessibilityDescriptor` 在型別行宣告遵循，實作卻拆到第 130 行 extension
    - 結論：已修正，descriptor 的 protocol 實作併回 nested type 內
- L108 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Data Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L128 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - AXChartDescriptorRepresentable`
    - 結論：MARK 名稱本身是誤報 (protocol 名合法)，但該 extension 依 design 的「圖表描述子的 protocol 實作搬回 nested type 內」整個併回巢狀型別，分區隨之消失，由任務 3.5 處理
- L132 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`func makeChartDescriptor() -> AXChartDescriptor {`
    - 結論：已修正，補上方法的摘要與回傳值／參數 doc comment
- L162 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`func updateChartDescriptor(_ descriptor: AXChartDescriptor) {`
    - 結論：已修正，補上方法的摘要與回傳值／參數 doc comment

### DesignSystem/Components/Chips/BLFilterChip.swift

共 15 筆 (必擋 5、違規 8、建議 2)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLFilterChip.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/07/20. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L13 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L28 `S·命名與既有元件一致` 建議 — 命名與既有元件一致 (審查員判讀)
    - 修法：`icon`／`trailingIcon` 實為 SF Symbol 名稱，與 `BLTagPill` 的 `systemImage` 命名不一致
    - 結論：登記例外：`icon` 與 `trailingIcon` 已是既有公開呼叫端介面，本次不改動 out-of-allowlist 呼叫端
- L39 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L43 `S·body 內區域變數` 違規 — body 內區域變數 (審查員判讀)
    - 修法：body 宣告 `let palette = BLPalette()`
    - 結論：由任務 3.3 涵蓋，palette／clamped value 已移至 computed property
- L47 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 命中區放在標籤內部才會擴大可點區域；形狀用 capsule 而非外接矩形。`
    - 結論：已修正，移除中文句號並保留必要的原因說明
- L53 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 補上選取 trait，讓輔助技術讀取狀態。`
    - 結論：已修正，移除中文句號並保留必要的原因說明
- L53 `S·複述程式碼的註解` 違規 — 複述程式碼的註解 (審查員判讀)
    - 修法：`// 補上選取 trait，讓輔助技術讀取狀態。` 只是複述下一行 `.accessibilityAddTraits`
    - 結論：已修正，移除重複程式碼行為的註解
- L65 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Cases`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L74 `S·enum case 命名語意` 建議 — enum case 命名語意 (審查員判讀)
    - 修法：`Style` 說明為「語意配色」，`.inverted`／`.accent` 是語意名，`.purple` 卻是色相名
    - 結論：登記例外：`.purple` 已有 out-of-allowlist 呼叫端，改名會擴大本次範圍；保留既有 API 語意
- L80 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Cases`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L90 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - ViewBuilder`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L99 `S·未經 Token 的間距` 違規 — 未經 Token 的間距 (審查員判讀)
    - 修法：HStack spacing `4`、垂直內距 `7` (113 行)、水平內距 `12`／`14` (205、207 行) 寫死，其中 4 與 12 已有 `BLSpacing.extraSmall`／`BLSpacing.medium`
    - 結論：部分已修正：4 與 12 改用 `BLSpacing`；7 與 14 是 chip 的既有視覺尺寸，無對應 token，登記例外
- L112 `S·modifier 四組順序` 違規 — modifier 四組順序 (審查員判讀)
    - 修法：`.foregroundStyle` (外觀) 排在 `.padding` (版面) 之前
    - 結論：已修正，依 `formatting.md` 將版面 modifier 排在外觀 modifier 前
- L219 `FM15` 違規 — 超過三個參數卻放在同一行 (腳本掃描)
    - 現況：`BLFilterChip(title: "本月", isSelected: true, style: .accent, icon: "calendar") {}`
    - 結論：已修正，Preview 呼叫改為多行格式

### DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift

共 20 筆 (必擋 8、違規 9、建議 3)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  PaymentMethodEditorSheet.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/05/23. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L11 `S·Note 以外的自由段落` 違規 — Note 以外的自由段落 (審查員判讀)
    - 修法：型別摘要後緊接第二行自由段落「以付款方式分類旗標參數化表單…」，且「參數化」是術語
    - 結論：已修正，第二段改為 `- Note:`，明確說明表單只提供旗標參數，不引入領域型別
- L14 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Typealias`
    - 結論：已修正，原本的 Typealias 分區與 typealias 一併移入 `Nested Types`
- L20 `S·typealias 用途` 違規 — typealias 用途 (審查員判讀)
    - 修法：`SubmitAction` 只是替短 closure 簽章取別名，不屬組合 protocol 或縮短長泛型簽章；`OptionPickerSheet` 同一簽章又直接寫出
    - 結論：不修，`SubmitAction` 是跨 `PaymentMethodEditorSheet` 與 `OptionPickerSheet` 共用的 callback API typealias，用來維持兩個元件簽章一致
- L22 `S·DesignSystem 反向依賴` 必擋 — DesignSystem 反向依賴 (審查員判讀)
    - 修法：Design System 元件的公開介面依賴 `Core/Domain/PaymentMethodFlags` (專案規則只禁 Features，但 skill 規定 DesignSystem 不依賴 Core)
    - 結論：已修正，元件介面不再依賴 `PaymentMethodFlags`，Shared DesignSystem 不反向引用 Core
- L25 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正，改用 `Properties`、`Body`、`Private Views` 與 `Nested Types` 等規範分區
- L46 `S·Properties 順序` 違規 — Properties 順序 (審查員判讀)
    - 修法：`@Environment` 與 `@State`／`@FocusState` 排在一般 `let` (28～43 行) 之後
    - 結論：已修正，`@Environment`、`@State`、`@FocusState` 排在一般 stored properties 前
- L61 `S·Bool 命名` 違規 — Bool 命名 (審查員判讀)
    - 修法：`showsDiscardConfirmation` 不是 is／has／can／should 開頭的肯定斷言
    - 結論：已修正，改名為 `isDiscardConfirmationPresented`
- L64 `S·無作用的狀態` 建議 — 無作用的狀態 (審查員判讀)
    - 修法：`isNameFieldFocused` 只在第 145 行綁定，從未讀取或寫入，沒有實際作用
    - 結論：報告誤判，不修；`isNameFieldFocused` 由 `.focused($isNameFieldFocused)` 實際驅動鍵盤焦點
- L108 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正，改用 `Body`
- L118 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 提供半屏與全屏兩種高度。`
    - 結論：已修正，移除重述 `.presentationDetents` 的中文句號註解
- L118 `S·複述程式碼的註解` 違規 — 複述程式碼的註解 (審查員判讀)
    - 修法：`// 提供半屏與全屏兩種高度。` 複述 `.presentationDetents([.medium, .large])`
    - 結論：已修正，移除重述 `.presentationDetents` 行為的註解
- L135 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - ViewBuilder`
    - 結論：已修正，表單內容改放在 `Private Views`
- L148 `FM1` 必擋 — 行寬超過 100 (腳本掃描)
    - 現況：`103 字元`
    - 結論：已修正，accessibility identifier 呼叫改為多行格式
- L148 `S·元件引用 feature 命名的 identifier` 建議 — 元件引用 feature 命名的 identifier (審查員判讀)
    - 修法：Design System 元件的 identifier 取自 `BLAccessibilityID.LookupManagement` 這個以 feature 命名的 namespace (148、185、194、235 行)
    - 結論：登記例外：`BLAccessibilityID.LookupManagement` 是既有 UI test contract；改動 namespace 會牽涉 allowlist 外的測試與呼叫端，本輪保留
- L217 `S·Private Views 內含互動邏輯` 違規 — Private Views 內含互動邏輯 (審查員判讀)
    - 修法：確認鈕 action 內直接做 trim、空值驗證、組旗標、提交與關閉；取消鈕 (203 行) 也內嵌 dirty 分支；trim 邏輯在 237 行重複
    - 結論：已修正，取消與提交流程抽成 `cancelEditing()`、`submitDraft()`，Private View 只負責組合畫面
- L243 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Private Types`
    - 結論：已修正，`PaymentMethodEditorSnapshot` 改為 `PaymentMethodEditorSheet.Snapshot` nested type
- L246 `S·頂層 private 輔助型別` 違規 — 頂層 private 輔助型別 (審查員判讀)
    - 修法：`PaymentMethodEditorSnapshot` 是只給本檔用的頂層 `private struct`
    - 結論：已修正，nested type 放在 `Nested Types`
- L248 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Data Properties`
    - 結論：已修正，快照欄位放在 `Properties`
- L262 `S·doc 標記用法` 建議 — doc 標記用法 (審查員判讀)
    - 修法：computed property 的 doc 加上 `- Returns:` (262、275、284 行)，屬性不是函式
    - 結論：已修正，補上 `Snapshot` computed property 的 `- Returns:` 說明

### DesignSystem/Components/Images/BLPhotoThumbnail.swift

共 19 筆 (必擋 9、違規 8、建議 2)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLPhotoThumbnail.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/06/06. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L15 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L33 `S·魔術數字` 建議 — 魔術數字 (審查員判讀)
    - 修法：`deleteButtonInset` 以 `18 / 2 - 4` 推算，18 與 4 的意義不明
    - 結論：已修正，刪除圖示尺寸與邊距改由 nested `Layout` 命名
- L35 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L42 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 將尺寸與形狀放在標籤內，確保刪除按鈕有足夠命中區。`
    - 結論：已修正，移除中文句號並保留必要的原因說明
- L43 `S·body 只放大框架` 必擋 — body 只放大框架 (審查員判讀)
    - 修法：刪除鈕的 Button、圖示與 8 個 modifier 整段寫在 body
    - 結論：已修正，body 改為只組合命名後的 private view content
- L48 `S·modifier 四組順序` 違規 — modifier 四組順序 (審查員判讀)
    - 修法：`.frame` (版面) 排在 `.foregroundStyle`／`.blTextStyle` (外觀) 之後
    - 結論：已修正，版面 modifier 排在外觀與互動 modifier 前
- L52 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 以位移維持圖示原本的視覺位置。`
    - 結論：已修正，移除中文句號並保留必要的原因說明
- L59 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - ViewBuilder`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L71 `S·?? 掩蓋 nil` 違規 — ?? 掩蓋 nil (審查員判讀)
    - 修法：`accessibilityID ?? ""` 在未指定時仍掛空字串 identifier，掩蓋「不指定」的語意
    - 結論：已修正，只有提供 identifier 時才套用 accessibility identifier
- L106 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - ButtonStyle`
    - 結論：報告誤報，不修。`formatting.md` 明文以 protocol 名稱作 MARK 名稱，掃描腳本的允許清單未收 protocol 名
- L109 `S·頂層 private 輔助型別` 違規 — 頂層 private 輔助型別 (審查員判讀)
    - 修法：`BLPhotoThumbnailButtonStyle` 是只給本檔用的頂層 `private struct`
    - 結論：r9 先移入 `BLPhotoThumbnail` 的 nested type；r12 依使用者裁決再抽成 `BLPhotoThumbnailButtonStyle.swift`，不再保留巢狀型別
- L111 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L116 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L119 `D2` 必擋 — 有參數卻缺 - Parameter (腳本掃描)
    - 現況：`func makeBody(configuration: Configuration) -> some View {`
    - 結論：已修正，補上 `- Parameter`／`- Returns` doc comment
- L119 `D3` 必擋 — 有回傳值卻缺 - Returns (腳本掃描)
    - 現況：`func makeBody(configuration: Configuration) -> some View {`
    - 結論：已修正，補上 `- Parameter`／`- Returns` doc comment
- L151 `S·tuple 與重複的 Preview helper` 建議 — tuple 與重複的 Preview helper (審查員判讀)
    - 修法：Preview 的 `sampleJPEGData` 以 `(output, $0)` tuple 搭配 `.0`／`.1` 取值，且與 `BLPhotoViewer` 的 Preview helper 幾乎相同
    - 結論：部分已修正：移除 tuple 與 `.0`／`.1` 存取；兩個 Preview helper 保留為 Preview-only 實作，避免擴大 allowlist
- L156 `FM15` 違規 — 超過三個參數卻放在同一行 (腳本掃描)
    - 現況：`context.setFillColor(CGColor(red: red, green: green, blue: blue, alpha: 1))`
    - 結論：已修正，Core Graphics 多參數呼叫改為多行格式
- L157 `FM15` 違規 — 超過三個參數卻放在同一行 (腳本掃描)
    - 現況：`context.fill(CGRect(x: 0, y: 0, width: 240, height: 240))`
    - 結論：已修正，Core Graphics 多參數呼叫改為多行格式

### DesignSystem/Components/Images/BLPhotoViewer.swift

共 16 筆 (必擋 5、違規 10、建議 1)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLPhotoViewer.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/06/06. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L15 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L21 `S·Properties 順序` 違規 — Properties 順序 (審查員判讀)
    - 修法：一般 `let photos` 夾在 `@Environment` 與 `@State` 之間
    - 結論：已修正，`@Environment`、`@State` 與一般 `let` 依規範順序排列
- L49 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L62 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - ViewBuilder`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L81 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 只有倍率為 1 時允許換頁。`
    - 結論：已修正，移除中文句號並保留必要的原因說明
- L81 `S·複述程式碼的註解` 違規 — 複述程式碼的註解 (審查員判讀)
    - 修法：`// 只有倍率為 1 時允許換頁。` 複述 `.scrollDisabled(isZoomedIn)`
    - 結論：已修正，改為只保留非顯而易見的手勢行為說明
- L91 `D3` 必擋 — 有回傳值卻缺 - Returns (腳本掃描)
    - 現況：`func photoPage(data: Data) -> some View {`
    - 結論：已修正，補上 `- Parameter`／`- Returns` doc comment
- L103 `S·modifier 四組順序` 違規 — modifier 四組順序 (審查員判讀)
    - 修法：`.scaleEffect`／`.offset` 排在 `.accessibilityLabel`／`.accessibilityIdentifier` (行為) 之後
    - 結論：已修正，版面 modifier 排在外觀與互動 modifier 前
- L116 `S·未經 Token 的字型` 違規 — 未經 Token 的字型 (審查員判讀)
    - 修法：placeholder 圖示直接寫 `.font(.largeTitle)`，不經 `BLTypographyStyle`
    - 結論：已修正，placeholder 改用 `BLTypographyStyle.largeTitle.font`
- L130 `S·nonisolated 需註解` 違規 — nonisolated 需註解 (審查員判讀)
    - 修法：`nonisolated static func zoomAnimation` 沒有註解說明為何脫離 MainActor
    - 結論：已修正，補上不依賴 View 隔離狀態的理由
- L145 `S·常數集中` 建議 — 常數集中 (審查員判讀)
    - 修法：`zoomedInScale` 以 computed property 回傳常數 2，最大倍率 4 卻寫死在第 163 行
    - 結論：已修正，縮放倍率集中在 nested `Layout` type
- L192 `S·Private Method 不得有副作用` 違規 — Private Method 不得有副作用 (審查員判讀)
    - 修法：`toggleZoom`／`resetZoom`／`resetPan` 與兩個手勢的 closure (156～189 行) 直接改寫 `@State` 並含倍率夾限規則
    - 結論：登記例外：手勢 action 必須直接更新本 View 的 `@State`，這是 SwiftUI 互動狀態的必要副作用，不另引入 ViewModel
- L214 `S·View 不寫格式化` 必擋 — View 不寫格式化 (審查員判讀)
    - 修法：`counterText` 在 View 的 Private Method 以字串插值組出「目前/總數」顯示文字
    - 結論：登記例外：`counterText` 是只供 navigation title 使用的目前頁次／總頁數 UI 標籤，不是領域格式化 API
- L250 `FM15` 違規 — 超過三個參數卻放在同一行 (腳本掃描)
    - 現況：`context.setFillColor(CGColor(red: red, green: green, blue: blue, alpha: 1))`
    - 結論：已修正，Core Graphics 多參數呼叫改為多行格式
- L251 `FM15` 違規 — 超過三個參數卻放在同一行 (腳本掃描)
    - 現況：`context.fill(CGRect(x: 0, y: 0, width: 480, height: 320))`
    - 結論：已修正，Core Graphics 多參數呼叫改為多行格式

### DesignSystem/Components/Pickers/OptionPickerSheet.swift

共 25 筆 (必擋 7、違規 14、建議 4)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  OptionPickerSheet.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/05/23. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L1 `FM4` 違規 — 單檔超過 300 行 (不含檔頭與空行) (腳本掃描)
    - 現況：重拆後 `OptionPickerSheet.swift` 為 `419` 行有效行；純清單呈現抽出至 `OptionPickerList.swift`，為 `113` 行有效行
    - 結論：登記例外：依 `file-templates.md` 以 extension 分檔會迫使五個原 `private` wrapper property (`dismiss`、`draft`、`isAddAlertPresented`、`isAddPaymentMethodPresented`、`searchText`) 降為 internal，破壞 View 的狀態封裝。依使用者裁決改抽獨立 `OptionPickerList.swift`，保留主檔 private 封裝，接受 `OptionPickerSheet.swift` 超過 300 行；公開建構式、五個呼叫端與實作邏輯不變
- L13 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正，改用 `Properties`、`Body`、`Nested Types`、`Computed Properties` 與 `Private Method`
- L22 `S·Bool 命名` 違規 — Bool 命名 (審查員判讀)
    - 修法：`searchable` 是形容詞而非肯定斷言；`allowsAdd` (19 行)、`showsAddAlert` (78 行)、`showsAddPaymentMethodSheet` (81 行) 也不是 is／has／can／should 開頭
    - 結論：已修正，內部布林屬性改為 `canAdd`、`isSearchEnabled`、`isAddAlertPresented`、`isAddPaymentMethodPresented`，外部 label 保留既有 API
- L63 `S·DesignSystem 反向依賴` 必擋 — DesignSystem 反向依賴 (審查員判讀)
    - 修法：通用選項元件依賴 `Core/Domain/PaymentMethodFlags`，並為付款方式寫專屬分支 (`onAddPaymentMethod`、`PaymentMethodEditorSheet`)
    - 結論：已修正，元件不再直接依賴 `PaymentMethodFlags`；付款方式表單以通用 submit closure 注入
- L75 `S·Properties 順序` 違規 — Properties 順序 (審查員判讀)
    - 修法：`@Environment` 與 `@State` 排在 19 個一般 `let` 之後
    - 結論：已修正，wrapper properties 排在一般 stored properties 前
- L81 `S·命名與註解語意不符` 違規 — 命名與註解語意不符 (審查員判讀)
    - 修法：`showsAddPaymentMethodSheet` 與其註解說是 sheet，實際在第 268 行以 `navigationDestination` push；第 440 行註解「付款方式使用 sheet」同樣過時
    - 結論：已修正，付款方式狀態改以 `isAddPaymentMethodPresented` 命名，並同步說明實際是 navigation push
- L97 `S·doc 複述名稱` 違規 — doc 複述名稱 (審查員判讀)
    - 修法：init 參數說明複述名稱：`emptyTitle: 空狀態標題` (97)、`title: navigation 標題` (93)、`addAlertTitle: 新增 alert 標題` (99)、`addFieldPlaceholder: 新增 TextField placeholder` (100)、`options: 可選項目` (102)
    - 結論：已修正，init 文件改為描述導覽標題、空狀態、選項清單與各回呼用途
- L111 `S·參數過多` 建議 — 參數過多 (審查員判讀)
    - 修法：init 有 19 個參數，新增 alert 相關 4 個與空狀態 2 個總是成組出現
    - 結論：登記例外：這是既有通用元件的公開建構式，參數群組與多個呼叫端已固定；引入 options/config wrapper 會擴大 API 與呼叫端範圍，本輪保留
- L153 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正，改用 `Body`
- L174 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Data Properties`
    - 結論：已修正，資料狀態區段改用 `Properties`
- L186 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Data Properties`
    - 結論：已修正，資料狀態區段改用 `Properties`
- L196 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - ViewBuilder`
    - 結論：已修正，畫面產生器區段改用 `Private Views`
- L208 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 多選時立即套用，完成鍵結束選取。`
    - 結論：已修正，移除中文句號
- L219 `S·重複的 toolbar 分支` 建議 — 重複的 toolbar 分支 (審查員判讀)
    - 修法：取消鈕的 ToolbarItem 在 219 與 230 行各寫一次，只因巢在不同分支
    - 結論：已修正，抽出共用的 `cancelToolbarItem()`
- L249 `S·Private Views 內含互動邏輯` 違規 — Private Views 內含互動邏輯 (審查員判讀)
    - 修法：alert 的「新增」action 內直接做 trim、驗證、回呼、清草稿與關閉，trim 又在 258 行重複
    - 結論：已修正，新增流程抽成 `addDraft()`
- L278 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 新增後返回訂單表單。`
    - 結論：已修正，改為描述提交後返回目前選項頁，不再寫死訂單表單
- L278 `S·註解與行為不符` 違規 — 註解與行為不符 (審查員判讀)
    - 修法：通用元件的註解寫死「新增後返回訂單表單。」，實際只是 dismiss 目前頁面，呼叫端不一定是訂單表單
    - 結論：已修正，移除與實際行為不符的 push／返回說明
- L287 `S·多餘的轉發 View` 建議 — 多餘的轉發 View (審查員判讀)
    - 修法：`content` 只回傳 `listContent`，多一層無意義間接
    - 結論：已修正，移除只轉發 `listContent` 的 `content`
- L329 `S·doc 術語與中英夾雜` 建議 — doc 術語與中英夾雜 (審查員判讀)
    - 修法：doc 大量使用工程用語：`- Returns: clear row view` (329)、`選項列 view` (358)、`callback` (56、59)、`通用建構式` (91)
    - 結論：已修正，文件改用「回呼」「畫面」「選項列」等一致術語
- L380 `S·modifier 四組順序` 違規 — modifier 四組順序 (審查員判讀)
    - 修法：`.accessibilityIdentifier` (行為) 排在 `.buttonStyle` (外觀) 之前
    - 結論：已修正，`.buttonStyle(.plain)` 排在 `.accessibilityIdentifier` 前
- L391 `S·資料過濾留在 View` 違規 — 資料過濾留在 View (審查員判讀)
    - 修法：`filteredOptions` 在 View 內做三段搜尋比對 (顯示名、關鍵字、原值)，屬可測試的資料計算
    - 結論：登記例外：`filteredOptions` 只做通用 UI 搜尋的顯示名、關鍵字與原值比對，不含領域狀態；移出 View 需要新增 API 或擴大 allowlist，本輪保留
- L427 `S·避免 handle 動詞` 違規 — 避免 handle 動詞 (審查員判讀)
    - 修法：`handleOptionTap(_:)` 使用不說明做了什麼的 `handle`
    - 結論：已修正，`handleOptionTap` 改名為 `selectOption`
- L448 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - ViewModifier`
    - 結論：報告誤報，不修。`formatting.md` 明文以 protocol 名稱作 MARK 名稱，掃描腳本的允許清單未收 protocol 名
- L451 `S·頂層 private 輔助型別` 違規 — 頂層 private 輔助型別 (審查員判讀)
    - 修法：搜尋修飾器是只給本檔用的頂層 `private struct`，其 `enabled` (457 行) 也不符 Bool 命名
    - 結論：已修正，搜尋修飾器拆至同目錄的 `BLSearchableModifier.swift`，`enabled` 改為 `isEnabled`

### DesignSystem/Components/Progress/BLProgressView.swift

共 15 筆 (必擋 9、違規 4、建議 2)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLProgressView.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/04/30. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L13 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L27 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L31 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 先將數值限制在 0 到 1，避免超出進度範圍。`
    - 結論：已修正，移除中文句號並保留必要的原因說明
- L33 `S·body 只放大框架` 必擋 — body 只放大框架 (審查員判讀)
    - 修法：body 宣告區域變數 `clampedValue` 並在 ProgressView 標籤 closure 內直接放 Text
    - 結論：已修正，body 改為只組合命名後的 private view content
- L44 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - ViewBuilder`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L56 `S·百分比格式化入口不一致` 建議 — 百分比格式化入口不一致 (審查員判讀)
    - 修法：以 `.percent` 就地格式化 (skill 允許系統樣式)，但專案規則要求百分比走 `BLFormatters`，兩者精度也不同
    - 結論：依 design「七筆判讀級 findings 的逐筆處置」：修，改呼叫 `BLFormatters.percent(_:locale:)` 並傳 `fractionLength: 0`，顯示維持整數百分比逐字不變，由任務 3.4 處理
- L61 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - ProgressViewStyle`
    - 結論：報告誤報，不修。`formatting.md` 明文以 protocol 名稱作 MARK 名稱，掃描腳本的允許清單未收 protocol 名
- L64 `S·一個主要元件一個檔` 建議 — 一個主要元件一個檔 (審查員判讀)
    - 修法：`BLProgressViewStyle` 被呼叫端獨立搭配 `ProgressView` 使用，卻與 `BLProgressView` 同檔
    - 結論：依 design「七筆判讀級 findings 的逐筆處置」：修，`BLProgressViewStyle` 拆成獨立檔，由任務 3.4 處理
- L66 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L74 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L77 `D2` 必擋 — 有參數卻缺 - Parameter (腳本掃描)
    - 現況：`func makeBody(configuration: Configuration) -> some View {`
    - 結論：已修正，補上參數與回傳值的 doc comment 標記
- L77 `D3` 必擋 — 有回傳值卻缺 - Returns (腳本掃描)
    - 現況：`func makeBody(configuration: Configuration) -> some View {`
    - 結論：已修正，補上參數與回傳值的 doc comment 標記
- L80 `S·未經 Token 的間距` 違規 — 未經 Token 的間距 (審查員判讀)
    - 修法：`VStack(spacing: 5)` 與軌道高度 `6` (108 行) 寫死
    - 結論：依 design「七筆判讀級 findings 的逐筆處置」：不修，登記例外。`BLSpacing` 沒有 5 與 6 這兩級，為兩個一次性數值新增 token 會讓尺寸系統長出只用一次的階
- L81 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 只有呼叫端提供標題或目前值標籤時才顯示這一列。`
    - 結論：已修正，移除中文句號並保留必要的原因說明

### DesignSystem/Components/States/BLDelayedProgressView.swift

共 7 筆 (必擋 3、違規 4、建議 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLDelayedProgressView.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/07/21. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L14 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L20 `TC1` 違規 — @Dependency 與 var 寫在同一行 (腳本掃描)
    - 現況：`@Dependency(\.continuousClock) private var clock`
    - 結論：由任務 1.4 涵蓋，已移除 `@Dependency`，不再有同一行的 dependency 宣告
- L20 `S·DesignSystem 只依賴 SwiftUI` 違規 — DesignSystem 只依賴 SwiftUI (審查員判讀)
    - 修法：Design System 元件 `import ComposableArchitecture` 並以 `@Dependency(\.continuousClock)` 取時鐘
    - 結論：由任務 1.4 涵蓋，已移除 `ComposableArchitecture` 依賴並改用 Swift Concurrency
- L25 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L29 `S·body 只放大框架` 必擋 — body 只放大框架 (審查員判讀)
    - 修法：body 直接放 ProgressView，`.task` closure 內含 do／catch 與狀態寫入
    - 結論：已修正，body 改為只組合命名後的 private view content
- L39 `S·catch 分散且靜默吞錯` 違規 — catch 分散且靜默吞錯 (審查員判讀)
    - 修法：`catch is CancellationError { return }` 與通用 `catch { return }` 行為相同，第二個分支靜默吞掉所有錯誤
    - 結論：已修正，改用 `try?` 搭配 `Task.isCancelled` guard，取消是 `Task.sleep` 的唯一預期失敗

### DesignSystem/Components/States/BLLoadFailureView.swift

共 7 筆 (必擋 4、違規 3、建議 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLLoadFailureView.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/07/20. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L13 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L19 `S·Note 以外的自由段落` 違規 — Note 以外的自由段落 (審查員判讀)
    - 修法：`retryIdentifier` 的 doc 在摘要後另起一行自由段落說明 `nil`
    - 結論：已修正，改用 `Note` 標記 nil 行為
- L25 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L30 `S·body 只放大框架` 必擋 — body 只放大框架 (審查員判讀)
    - 修法：`ContentUnavailableView` 的 label 與 description closure 內直接放 `Label`、`Text` 內容
    - 結論：已修正，body 改為只組合命名後的 private view content
- L38 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 保留重試鍵的 identifier，避免被外層容器合併。`
    - 結論：已修正，移除中文句號並保留必要的原因說明
- L43 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - ViewBuilder`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱

### DesignSystem/Components/Status/BLStatusPill.swift

共 8 筆 (必擋 3、違規 5、建議 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLStatusPill.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/04/30. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L13 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L31 `S·Bool 命名` 違規 — Bool 命名 (審查員判讀)
    - 修法：`showsIndicator` 不是 is／has／can／should 開頭的肯定斷言，doc「指示是否顯示…」也有贅字
    - 結論：已修正，內部屬性改為肯定式 `isIndicatorVisible`；保留外部 `showsIndicator` label 以維持既有呼叫端
- L50 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L54 `S·body 只放大框架` 必擋 — body 只放大框架 (審查員判讀)
    - 修法：body 直接放狀態點 Circle 與 Text 的實際內容
    - 結論：已修正，body 改為只組合命名後的 private view content
- L54 `S·未經 Token 的間距` 違規 — 未經 Token 的間距 (審查員判讀)
    - 修法：`HStack(spacing: 4)` 寫死，已有 `BLSpacing.extraSmall`
    - 結論：已修正，改用 `BLSpacing.extraSmall`
- L56 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 裝飾色點不重複朗讀。`
    - 結論：已修正，移除中文句號並保留必要的原因說明
- L66 `S·modifier 四組順序` 違規 — modifier 四組順序 (審查員判讀)
    - 修法：`.foregroundStyle` (外觀) 排在 `.padding` (版面) 之前
    - 結論：已修正，依 `formatting.md` 將版面 modifier 排在外觀 modifier 前

### DesignSystem/Components/Tags/BLTagPill.swift

共 4 筆 (必擋 3、違規 1、建議 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLTagPill.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/05/26. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L13 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L32 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正，依 `formatting.md` 改用規範分區名稱
- L38 `S·body 只放大框架` 必擋 — body 只放大框架 (審查員判讀)
    - 修法：body 直接放前導 Image 與 4 個 modifier，以及 BLStatusPill 的版面修飾
    - 結論：已修正，body 改為只組合命名後的 private view content

### DesignSystem/Foundations/BLFormatters.swift

共 4 筆 (必擋 1、違規 2、建議 1)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLFormatters.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/07/30. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L11 `S·格式化用 FormatStyle` 違規 **[已登記例外]** — 格式化用 FormatStyle (審查員判讀)
    - 修法：金額與百分比格式化以無 case enum 的靜態函式實作，而非 `FormatStyle`；為 apps/ios/CLAUDE.md 已登記差異 6
    - 結論：依 design Non-Goals 不修：`apps/ios/CLAUDE.md` 已登記差異，金額與百分比走 `BLFormatters` 靜態函式而非 `FormatStyle`，本 change 不改變這個慣例
- L24 `S·DesignSystem 反向依賴` 必擋 — DesignSystem 反向依賴 (審查員判讀)
    - 修法：Design System 的 Foundations 依賴 `Core/Domain` 的 `CurrencyCode`
    - 結論：依任務 1.3 修正，`BLFormatters.twd(_:locale:)` 改用字面 ISO 代碼 `"TWD"`，不再依賴 `Core/Domain/CurrencyCode`
- L57 `S·字串串接不隨 locale` 建議 — 字串串接不隨 locale (審查員判讀)
    - 修法：`percent(scaled:)` 以 `+ "%"` 串接，百分比符號位置與間距不隨 locale 調整
    - 結論：依 design「七筆判讀級 findings 的逐筆處置」：修，改成 `(value / 100).formatted(.percent…)`，由任務 3.1.2 處理

### DesignSystem/Foundations/BLHeatmapDepth.swift

共 4 筆 (必擋 2、違規 1、建議 1)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLHeatmapDepth.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/07/20. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L13 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Cases`
    - 結論：已修正，enum case 保留在型別本體，移除不必要的 `Cases` MARK
- L31 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Display Properties`
    - 結論：已修正，computed properties 分區改為規範的 `Computed Properties`
- L40 `S·doc 不白話` 建議 — doc 不白話 (審查員判讀)
    - 修法：「經驗證達標的數字色」未說明驗證什麼、達什麼標
    - 結論：已修正，補充數字色與背景成對及對比驗證的語意

### DesignSystem/Foundations/BLMetrics.swift

共 7 筆 (必擋 4、違規 3、建議 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLMetrics.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/04/30. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L1 `FN1` 違規 — 檔名與主要型別名稱不一致 (腳本掃描)
    - 現況：`檔名 BLMetrics.swift 找不到型別 BLMetrics`
    - 結論：依 design Non-Goals 登記例外：`BLMetrics.swift` 是既有的 metrics token 聚合檔，集中 `BLRadius`、`BLSpacing`、`BLListMetrics` 與 `BLHitTarget`，沒有可單獨對應的主要型別；本 change 不拆檔或改名
- L13 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Static Properties`
    - 結論：已修正，static token 分區改為規範的 `Properties`
- L37 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Static Properties`
    - 結論：已修正，static token 分區改為規範的 `Properties`
- L39 `S·doc 複述名稱` 違規 — doc 複述名稱 (審查員判讀)
    - 修法：`BLSpacing` 的 doc 只複述名稱：「最小間距」(39)、「小間距」(42)、「中間距」(45)、「大間距」(48)、「特大間距」(51)
    - 結論：依 design Non-Goals 登記例外，不修；尺寸 token 的 doc 維持簡短名稱與既有用途語意，不因掃描器的複述名稱判讀擴大文件改寫
- L61 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Static Properties`
    - 結論：已修正，static token 分區改為規範的 `Properties`
- L73 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Static Properties`
    - 結論：已修正，static token 分區改為規範的 `Properties`

### DesignSystem/Foundations/BLPalette.swift

共 32 筆 (必擋 27、違規 3、建議 2)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLPalette.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/04/30. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L11 `S·型別選擇` 建議 — 型別選擇 (審查員判讀)
    - 修法：`BLPalette` 是無 stored property 的 struct，呼叫端到處 `BLPalette()` 並把 `palette` 當參數傳遞；多處 doc 稱其為「目前外觀對應的色盤」，實際不帶任何外觀狀態
    - 結論：依 design「七筆判讀級 findings 的逐筆處置」：不修，登記待專案處理。改成 enum namespace 要動 46 個呼叫點，多數在第 3 至 8 步的 Feature 檔
- L13 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Static Properties`
    - 結論：已修正，computed properties 分區改為規範的 `Computed Properties`
- L16 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`static var heroGradient: [Color] {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension
- L23 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Display Properties`
    - 結論：已修正，分區改為規範的 `Computed Properties`
- L26 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var background: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension
- L31 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var secondaryBackground: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension
- L36 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var tertiaryBackground: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension
- L41 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var plainBackground: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension
- L46 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var surface: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension
- L51 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var elevatedSurface: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension
- L56 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var label: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension
- L61 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var secondaryLabel: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension；色值例外另依 3.1.1 處理
- L62 `SU5` 違規 — modifier 與 View 同行 (腳本掃描)
    - 現況：`Color(uiColor: .label).opacity(0.6)`
    - 結論：依 design「次要文字色維持現況，改寫衝突的規則文字」不拆行或改色；此單一次要文字色由任務 3.1.1 登記為對比地板例外
- L62 `S·與專案色彩規則衝突` 建議 — 與專案色彩規則衝突 (審查員判讀)
    - 修法：`secondaryLabel` 以 `.opacity(0.6)` 降低不透明度，與專案「文字不透明度一律為 1」規則矛盾
    - 結論：依 design「次要文字色維持現況，改寫衝突的規則文字」：程式碼不修。`.opacity(0.6)` 是為了通過 4.5:1 對比地板而刻意選的 (規則文件載明系統 `secondaryLabel` 淺色未達標)，改的是規則文字，由任務 3.1.1 處理
- L66 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var tertiaryLabel: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension
- L71 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var separator: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension
- L76 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var opaqueSeparator: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension
- L81 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var fillPrimary: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension
- L86 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var fillSecondary: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension
- L91 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var fillTertiary: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension
- L96 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var fillQuaternary: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension
- L101 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var accent: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension
- L105 `S·命名語意與註解一致` 違規 — 命名語意與註解一致 (審查員判讀)
    - 修法：`green`／`red`／`orange`／`yellow`／`indigo` 以色相命名，doc 卻寫「成功狀態色」「錯誤或破壞性狀態色」等語意，與 `BLTone` 的語意軌混淆
    - 結論：依 design Non-Goals 不修：`BLPalette` 的語意命名屬 `color-system-foundation` 規格管轄，本 change 只改分區、取實例的位置與 `secondaryLabel` 一項色值
- L106 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var green: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension；語意命名依 design Non-Goals 保留
- L111 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var red: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension；語意命名依 design Non-Goals 保留
- L116 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var orange: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension；語意命名依 design Non-Goals 保留
- L121 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var yellow: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension；語意命名依 design Non-Goals 保留
- L126 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var purple: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension；語意命名依 design Non-Goals 保留
- L131 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var pink: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension；語意命名依 design Non-Goals 保留
- L136 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var teal: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension；語意命名依 design Non-Goals 保留
- L141 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var indigo: Color {`
    - 結論：由任務 3.1 涵蓋，computed property 已移至 `BLPalette` 的 extension；語意命名依 design Non-Goals 保留

### DesignSystem/Foundations/BLStatusHue.swift

共 3 筆 (必擋 1、違規 1、建議 1)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLStatusHue.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/08/01. | //`
    - 結論：已刪除，原檔頭不再屬現行程式碼，現行檔頭無需處理
- L21 `S·命名語意` 建議 — 命名語意 (審查員判讀)
    - 修法：型別叫 Hue、`- Returns: 色相`，實際回傳的是 `Color`
    - 結論：由任務 1.1 涵蓋，`BLStatusHue` 已刪除，呈現色彩改由 `OrderStatus.sidebarHue(in:)` 提供
- L22 `S·DesignSystem 反向依賴` 必擋 — DesignSystem 反向依賴 (審查員判讀)
    - 修法：Design System 的 Foundations 依賴 `Core/Domain` 的 `OrderStatus`，把訂單狀態對應寫進設計系統
    - 結論：由任務 1.1 涵蓋，刪除 `BLStatusHue` 並將狀態到色彩的對應移至 `OrderStatus+Presentation.swift`

### DesignSystem/Foundations/BLTone.swift

共 4 筆 (必擋 2、違規 1、建議 1)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLTone.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/04/30. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L13 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Cases`
    - 結論：已修正，enum case 保留在型別本體，移除不必要的 `Cases` MARK
- L34 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Display Properties`
    - 結論：已修正，computed properties 分區改為規範的 `Computed Properties`
- L84 `S·字串傳遞列舉值` 建議 — 字串傳遞列舉值 (審查員判讀)
    - 修法：`namedColor(role: String)` 以字串傳入 role，拼錯時具名色彩會靜默回退系統色
    - 結論：依 design「七筆判讀級 findings 的逐筆處置」：修，role 改成 private enum，由任務 3.1.2 處理

### DesignSystem/Foundations/BLTypography.swift

共 7 筆 (必擋 4、違規 3、建議 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLTypography.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/04/30. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L1 `FN1` 違規 — 檔名與主要型別名稱不一致 (腳本掃描)
    - 現況：`檔名 BLTypography.swift 找不到型別 BLTypography`
    - 結論：依 design Non-Goals 登記例外：`BLTypography.swift` 是既有的 typography token 檔，主要型別為 `BLTypographyStyle`；改檔名會擴大本 change 的檔案與專案同步範圍，本輪保留
- L13 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Cases`
    - 結論：已修正，enum case 保留在型別本體，移除不必要的 `Cases` MARK
- L48 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Identifiable Properties`
    - 結論：已修正，`Identifiable` 遵循改以 protocol 名稱作 MARK
- L51 `S·手寫 protocol 遵循位置` 違規 — 手寫 protocol 遵循位置 (審查員判讀)
    - 修法：`Identifiable` 的 `id` 是手寫 computed property，遵循卻寫在型別行並放本體；`rawValue` ("Large Title" 等) 只供 Preview 顯示，並非外部表示
    - 結論：已修正，`Identifiable` 遵循與 `id` 實作已移至獨立 extension，`rawValue` 的既有顯示語意不變
- L53 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Display Properties`
    - 結論：已修正，computed properties 分區改為規範的 `Computed Properties`
- L56 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var font: Font {`
    - 結論：已修正，`font` 移至 `Computed Properties` extension

### DesignSystem/Foundations/ViewModifiers/BLCardShadow.swift

共 10 筆 (必擋 6、違規 3、建議 1)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLCardShadow.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/05/31. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L10 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - ViewModifier`
    - 結論：報告誤報，不修。`formatting.md` 明文以 protocol 名稱作 MARK 名稱，掃描腳本的允許清單未收 protocol 名
- L13 `S·doc 與行為不符` 違規 — doc 與行為不符 (審查員判讀)
    - 修法：doc 說「在深色模式改以分隔線表達層級」，但 `body` 在深色模式只回傳原內容，分隔線其實在 `BLCard`
    - 結論：依 design Non-Goals 不修；`BLCardShadow` 在深色模式刻意不加陰影，卡片的分隔線由 `BLCard` 負責，doc 描述的是該卡片 modifier 組合的視覺責任
- L15 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正，stored properties 分區改為規範的 `Properties`
- L21 `S·Bool 命名` 違規 — Bool 命名 (審查員判讀)
    - 修法：`floating: Bool` 不是 is／has 開頭的肯定斷言 (`blCardShadow(floating:)` 同)
    - 結論：依 design Non-Goals 登記例外：`floating` 是既有 modifier 的公開參數與 Preview API；改成 `isFloating` 會改動既有呼叫端介面，本 change 不擴大該 API 變更
- L23 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正，protocol 實作分區改為規範的 `ViewModifier`
- L26 `D2` 必擋 — 有參數卻缺 - Parameter (腳本掃描)
    - 現況：`func body(content: Content) -> some View {`
    - 結論：已修正，補上 `content` 的 `- Parameter` doc comment
- L26 `D3` 必擋 — 有回傳值卻缺 - Returns (腳本掃描)
    - 現況：`func body(content: Content) -> some View {`
    - 結論：已修正，補上 `body` 的 `- Returns` doc comment
- L47 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Method`
    - 結論：已修正，`View` convenience extension 改以 `blCardShadow` 功能命名
- L49 `S·非自己型別的擴充位置` 建議 — 非自己型別的擴充位置 (審查員判讀)
    - 修法：`extension View` 放在元件檔 (本檔、`BLHeroCardBackground`、`BLTypographyModifier`、`BLButtonStyle` 104 行)，是 ios-design-system.md 記錄的專案慣例，但未列入 apps/ios/CLAUDE.md 既有差異清單
    - 結論：依 design Non-Goals 不修。`extension View` 的便利入口與其 modifier 同檔是 SwiftUI 慣例，維持一個關注點一檔

### DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift

共 8 筆 (必擋 7、違規 1、建議 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLHeroCardBackground.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/07/30. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L10 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - ViewModifier`
    - 結論：報告誤報，不修。`formatting.md` 明文以 protocol 名稱作 MARK 名稱，掃描腳本的允許清單未收 protocol 名
- L15 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Static Properties`
    - 結論：已修正，static computed property 分區改為規範的 `Computed Properties`
- L18 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`static var gradientColors: [Color] {`
    - 結論：已修正，`gradientColors` 移至 `Computed Properties` extension
- L22 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正，protocol 實作分區改為規範的 `ViewModifier`
- L25 `D2` 必擋 — 有參數卻缺 - Parameter (腳本掃描)
    - 現況：`func body(content: Content) -> some View {`
    - 結論：已修正，補上 `content` 的 `- Parameter` doc comment
- L25 `D3` 必擋 — 有回傳值卻缺 - Returns (腳本掃描)
    - 現況：`func body(content: Content) -> some View {`
    - 結論：已修正，補上 `body` 的 `- Returns` doc comment
- L38 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Method`
    - 結論：已修正，`View` convenience extension 改以 `blHeroCardBackground` 功能命名

### DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift

共 8 筆 (必擋 6、違規 2、建議 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  BLTypographyModifier.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/05/31. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L10 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - ViewModifier`
    - 結論：報告誤報，不修。`formatting.md` 明文以 protocol 名稱作 MARK 名稱，掃描腳本的允許清單未收 protocol 名
- L15 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正，stored properties 分區改為規範的 `Properties`
- L20 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正，protocol 實作分區改為規範的 `ViewModifier`
- L22 `S·doc 與行為不符` 違規 — doc 與行為不符 (審查員判讀)
    - 修法：doc 說「回傳套用字型與字距後的內容」，實作只套用字型
    - 結論：已修正，doc 改為只描述實際套用的字型
- L23 `D2` 必擋 — 有參數卻缺 - Parameter (腳本掃描)
    - 現況：`func body(content: Content) -> some View {`
    - 結論：已修正，補上 `content` 的 `- Parameter` doc comment
- L23 `D3` 必擋 — 有回傳值卻缺 - Returns (腳本掃描)
    - 現況：`func body(content: Content) -> some View {`
    - 結論：已修正，補上 `body` 的 `- Returns` doc comment
- L29 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Method`
    - 結論：已修正，`View` convenience extension 改以 `blTextStyle` 功能命名

### Extensions/Bundle+Extensions.swift

共 2 筆 (必擋 0、違規 2、建議 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  Bundle+Extensions.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/07/20. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L11 `S·頂層 private 輔助型別` 違規 — 頂層 private 輔助型別 (審查員判讀)
    - 修法：`BundleToken` 是只給本檔用的頂層 `private final class`
    - 結論：已修正，Bundle token 移入 `Bundle` extension 的 private nested `Token`

### Extensions/Color+Extensions.swift

共 1 筆 (必擋 0、違規 1、建議 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  Color+Extensions.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/04/30. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位

### Extensions/Decimal+Extensions.swift

共 2 筆 (必擋 1、違規 1、建議 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  Decimal+Extensions.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/05/01. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L15 `D3` 必擋 — 有回傳值卻缺 - Returns (腳本掃描)
    - 現況：`func roundedUpToInteger() -> Decimal {`
    - 結論：已修正，補上 `- Returns: 無條件進位後的整數 Decimal`

### Extensions/Image+Extensions.swift

共 1 筆 (必擋 0、違規 1、建議 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  Image+Extensions.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/06/06. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位

### Localization/AppLanguage.swift

共 12 筆 (必擋 8、違規 3、建議 1)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  AppLanguage.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/07/17. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L13 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Cases`
    - 結論：已修正，enum case 保留在型別本體，移除不必要的 `Cases` MARK
- L21 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Identifiable Properties`
    - 結論：已修正，`Identifiable` 遵循與 `id` 移至獨立 extension
- L24 `S·手寫 protocol 遵循位置` 違規 — 手寫 protocol 遵循位置 (審查員判讀)
    - 修法：`Identifiable` 的 `id` 是手寫 computed property，遵循卻寫在型別行並放本體
    - 結論：已修正，改在 `extension AppLanguage: Identifiable` 提供 `id`
- L40 `MK4` 必擋 — extension 專屬分區寫在型別本體內 (腳本掃描)
    - 現況：`// MARK: - Computed Properties`
    - 結論：已修正，computed properties 全部移到型別外的 `Computed Properties` extension
- L43 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var title: LocalizedStringResource {`
    - 結論：已修正，`title` 移至 extension
- L53 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var localeIdentifier: String {`
    - 結論：已修正，`localeIdentifier` 移至 extension
- L63 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var locale: Locale {`
    - 結論：已修正，`locale` 移至 extension
- L80 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Method`
    - 結論：依 `formatting.md` 改用 `rootNavigationTitle` 描述此 View extension；非自己型別 extension 的檔案位置依 design Non-Goals 保留
- L82 `S·非自己型別的擴充位置` 建議 — 非自己型別的擴充位置 (審查員判讀)
    - 修法：`extension View` 的 `rootNavigationTitle` 放在 `AppLanguage.swift`，不在 `Shared/Extensions/`
    - 結論：依 design Non-Goals 不修。`extension View` 的便利入口與其 modifier 同檔是 SwiftUI 慣例，維持一個關注點一檔
- L105 `FM0` 必擋 — 縮排不是 4 格 (開括號後一層) (腳本掃描)
    - 現況：`預期縮排 18，實際 12`
    - 結論：已修正，localized bundle fallback 的巢狀區塊縮排改為 4 格
- L105 `S·guard 的 else 只放離開` 違規 — guard 的 else 只放離開 (審查員判讀)
    - 修法：`guard` 的 `else` 內先呼叫 `assertionFailure` 再 return
    - 結論：已修正，`guard` 的 else 只做 assertionFailure 與 return，沒有混入其他流程

### Media/PhotoDataProcessor.swift

共 4 筆 (必擋 1、違規 3、建議 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/M/D) (腳本掃描)
    - 現況：`// | //  PhotoDataProcessor.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/06/06. | //`
    - 結論：已修正，檔頭日期格式為 `YYYY/M/D`，依使用者裁決不做月份與日期補位
- L13 `S·型別後綴與 process 動詞` 違規 — 型別後綴與 process 動詞 (審查員判讀)
    - 修法：`Processor` 不是規範定義的角色後綴，且 process 是應避免的動詞
    - 結論：登記例外：`PhotoDataProcessor` 與 `process` 是既有 allowlist 外 `PhotoClient`／測試 API；改名或改回傳模型會擴大範圍，本輪保留
- L15 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Static Properties`
    - 結論：已修正，`Static Properties` 改為 `Properties`
- L38 `S·以 Optional 表達失敗` 違規 — 以 Optional 表達失敗 (審查員判讀)
    - 修法：解碼、縮圖、編碼三種失敗原因都回傳 `nil`，呼叫端無法區分
    - 結論：登記例外：現有呼叫端與測試以 `Data?` 的 nil contract 表達解碼、縮圖與編碼失敗；改成 typed error 會改變 allowlist 外 API，本輪保留

## Review 第 8 輪補充結論（2026-09-20）

本輪重新發現的 21 筆排版問題是原始 334 筆明細之外的補充審查項目，因此保留上方 334 筆統計，並在此記錄實際處置。

### MK2：MARK 分區順序與重複分區

- `BLAvatar.swift`、`BLBadge.swift`、`BLButtonStyle.swift`、`BLBarChart.swift`、`BLDonutChart.swift`、`BLSparkline.swift`、`BLFilterChip.swift`、`BLPhotoThumbnail.swift`、`BLPhotoViewer.swift`、`OptionPickerSheet.swift`、`BLProgressView.swift`：已依 `Properties → Init → Body → Private Views → Nested Types → Computed Properties → Internal Method → protocol → Private Method → Preview` 移動既有 extension 區塊，未改動區塊內程式碼
- `BLButtonStyle.swift`：兩個 `Computed Properties` 標記已收斂為一個；`ButtonStyle where Self == BLButtonStyle` 工廠 extension 改置於 `ButtonStyle` protocol 區段並排在 `Private Method` 之前
- `BLPhotoThumbnail.swift` 與 `OptionPickerSheet.swift`：未標 MARK 但宣告 nested type 的 extension 也已移回 `Nested Types` 區段
- `BLMetrics.swift` 的四個 `Properties` 分別屬於 `BLRadius`、`BLSpacing`、`BLListMetrics`、`BLHitTarget` 四個獨立頂層 enum，屬合法例外，未修改
- 等價掃描結果：MARK 順序錯置 `Shared 0`；重複分區原始輸出僅剩 `BLMetrics.swift` 的合法例外，排除該例外後可處理項目為 `Shared 0`

### S·modifier 四組順序

- `BLBadge.swift`、`BLFilterChip.swift`、`OptionPickerSheet.swift`、`BLStatusPill.swift`、`BLHeroCardBackground.swift`：已將版面群組移到外觀群組之前，組內相對順序保留；`BLFilterChip.titleText` 的 `.fixedSize` 與 `.frame` 亦維持原本的先後順序
- `BLBadge.badgeContent`、`BLFilterChip.label`、`BLStatusPill.statusContent` 的 `.padding` 均在 `.foregroundStyle`／`.font` 與 `.background`／`.clipShape` 之前；`OptionPickerSheet.listClearRow` 與 `listOptionRow` 的 `.fixedSize` 均在外觀 modifier 之前；`BLHeroCardBackground` Preview 的外層 `.padding` 已移至 hero 背景 modifier 之前
- modifier 掃描結果：違反 `Shared 0`；`- Parameter` 缺漏 `0`；`- Returns` 缺漏 `0`

## Review 第 9 輪補充結論（2026-09-20）

本輪針對前幾輪機械掃描未涵蓋的巢狀型別位置、型別本體方法與註解破折號補正；不增加原始 334 筆統計。

### 巢狀型別位置

- `BLBadge.swift`：`BLBadge.Variant` 從型別本體移至 `Nested Types` extension
- `BLButtonStyle.swift`：`BLButtonStyle.Variant` 從型別本體移至 `Nested Types` extension
- `BLBarChart.swift`：`ChartAccessibilityDescriptor` 的段名邊界補正，與 `Layout` 同屬 `Nested Types`
- `BLPhotoThumbnail.swift`：r9 時 `ThumbnailButtonStyle` 的段名邊界補正，與 `Layout` 同屬 `Nested Types`；r12 已將按鈕樣式抽離，主檔只保留 `Layout`
- `OptionPickerSheet.swift`：`MultiSelection` 的段名邊界補正，明確落在 `Nested Types`；`BLSearchableModifier` 已在同目錄獨立檔保留 `ViewModifier` protocol extension
- `CurrencyPickerTests.swift`：`CurrencyPickerTests.Destination` 從 `Private Method` 移至 `Nested Types`

### 型別本體與註解

- `CurrencyDisplayName.swift`：`text(code:language:)` 與 `searchKeywords(code:locale:)` 移至 `Internal Method` extension，型別本體保持空宣告
- `BLPhotoViewer.swift`、`BLTagPill.swift`：兩筆註解破折號改為冒號；`BLFormatters.swift` 的 "—" 仍是產品空狀態佔位符，未改動

### r9 驗證

- `scan8.py`：Shared 的巢狀型別真違規 0；註解破折號真違規 0。原始輸出僅保留 `BLFormatters.swift` 對產品佔位符 "—" 的 3 筆預期誤報
- `scan9.py`：Shared 0（型別本體 computed property／method、`Private Views` 後綴、三元 View）
- `scan7.py`：Shared modifier 跨組順序違反 0
- Device Hub SnapshotTests：14 通過、0 失敗、0 跳過；未重錄 baseline。完整單元回歸：729 總數、728 通過、1 失敗，唯一失敗為已知 `SnapshotTests/orderEditViewBaseline()`；帶括號的方法層 selector 單獨重跑為 1 通過、0 失敗

## Review 第 12 輪修正紀錄（2026-09-20）

- `BLPhotoThumbnail.swift`：移除巢狀 `ThumbnailButtonStyle` 與 `BLPhotoThumbnail.ThumbnailButtonStyle: ButtonStyle` 遵循 extension；`Layout` 仍留在 `Nested Types`，呼叫端改用 `BLPhotoThumbnailButtonStyle()`。
- 新增 `BLPhotoThumbnailButtonStyle.swift`：依 `BLProgressViewStyle.swift` 的結構，型別本體只留 `reduceMotion`，`ButtonStyle` 遵循與 `makeBody` 放在 protocol MARK extension。
- `BLProgressView.swift`／`BLProgressViewStyle.swift`：由 `BLProgressBar.swift`／`BLProgressBarStyle.swift` 改名而來；所有 Swift 呼叫端與 `.claude/rules/ios-design-system.md` 同步改名。
- 文件中的檔頭日期規則與 35 筆 H1 結論已依使用者裁決統一描述為 `YYYY/M/D`，月份與日期不做補位。
- r12 驗證：SnapshotTests `totalTestCount` 14（14 通過）；完整單元回歸 `totalTestCount` 729（728 通過、1 個既有 `orderEditViewMergeContextBaseline()` snapshot mismatch），該方法單獨重跑 `totalTestCount` 1 且通過；iPhone 與 iPad UI 各 `totalTestCount` 64（各 64 通過）。未重錄 baseline。

## Review 第 13 輪補充結論（2026-09-21）

- `DesignSystemSourceScanTests` 已新增常駐的幣別查表單一入口守門：掃描完整 production root，複用既有掃描與豁免標記機制，allowlist 僅為 `Shared/Localization/CurrencyDisplayName.swift`；`OptionPickerSheet` Preview 亦改用 `CurrencyDisplayName.text(code:language:)`，不再自行呼叫 Foundation 查表。
- 幣別查表變異驗證已完成：注入 `localizedString(forCurrencyCode: "TWD")` 時，測試以 `totalTestCount` 1 失敗，並指出 `Features/Dashboard/DashboardView.swift:777`；還原後同一測試以 `totalTestCount` 1 通過。完整證據與 result bundle 路徑記於 `tasks.md` 的 6.2 與 Review 第 13 輪紀錄。
- `BLDelayedProgressView` 的靜默取消／失敗路徑已補上正體中文原因註解，`tasks.md` 的靜態驗證敘述同步為 `try?` 加 `Task.isCancelled`，不再誤述不存在的 `catch`。
- `design.md`、`proposal.md`、`tasks.md` 已同步 r12 改名的四個必要 Feature 呼叫端、實際 New／Removed／Modified 清單、8 筆既有行寬例外與 65 個變更項目；本輪沒有擴大 Non-Goals。
- r13 最終測試證據已寫入 `tasks.md` 6.2；四份 result bundle 均晚於最後一次 Swift 寫入，未重錄已知 `SnapshotTests/quoteViewBaseline()` baseline。

## Review 第 14 輪補充結論（2026-09-21）

- `LayerBoundaryTests.composableArchitectureImportViolations()` 已由整行相等比對改為模組名正規表示式，涵蓋前置 attribute、限定 import 與子符號三種 TCA import 寫法。三次變異驗證均以 `totalTestCount` 1 轉紅並指出正確的 `BLCard.swift:9`；還原後 clean selector 為 1/1 通過。
- 幣別單一入口兩個測試已從 `LayerBoundaryTests` 搬至 `DesignSystemSourceScanTests`，複用既有 `findViolations`、`swiftFiles`、`stripCommentsAndStrings` 與豁免標記機制；唯一 allowlist 檔案在逐行掃描前整支跳過。
- `PaymentMethodEditorSheet.Snapshot` 已恢復檔案私有封裝；搜尋修飾器已改名為 `BLSearchableModifier`，型別與檔名同步。
- r14 最終測試均在最後一次 Swift 寫入（`2026-09-21 10:01:02 +0800`）之後產生：SnapshotTests 14/14；完整單元回歸 730 條中 728 通過、兩筆既有 `orderEditViewMergeContextBaseline()` 與 `quoteViewBaseline()` snapshot mismatch 各聚焦重跑 1/1 通過；iPhone 完整 UI 64/64 通過；iPad 完整 UI 64/64 通過。結果包絕對路徑與 `totalTestCount` 已記於 `tasks.md` 6.2，未重錄 baseline。
