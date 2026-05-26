## Context

訂單列表的單列摘要由 `OrderRowView` 繪製，並由 iOS (`OrdersCompactView`)、iPadOS (`OrdersView`)、macOS (`OrdersMacView`) 與 Dashboard 四處共用。原始版面為：第一行「客戶名稱 · 訂單後三碼」、第二行商品明細、第三行「狀態膠囊 + 訂購日期」，右欄為收款金額與利潤。

完整訂單單號已由訂單詳情頁顯示，且 `id` 已納入列表全文搜尋的 `searchableText`，因此列表第一行的後三碼為冗餘且掃視價值低的資訊。商品類別目前只在編輯表單出現，列表完全沒有露出。

本變更已先以可丟棄原型在實機 (iPhone) 上迭代確認版面，現以正式流程收尾。約束：`OrderRowView` 跨平台共用、Design System 元件需遵守 `Shared/DesignSystem/` 的 Foundations/Components 分層與「一元件一檔 + 各自 #Preview」慣例、snapshot 測試需用固定時間注入、列表 row 顯示資料一律來自 reducer/domain 不在 view 內計算。

## Goals / Non-Goals

**Goals:**

- 讓使用者在列表一眼掌握「誰、何時、什麼狀態、什麼類別」。
- 以對稱、一致的 8pt 垂直節奏呈現三行內容與分隔線。
- 將類別膠囊抽成可重用、不洩漏 Design System 內部色盤的元件。

**Non-Goals:**

- 不調整訂單詳情頁、不更動搜尋邏輯 (單號仍可被搜尋)。
- 不更動任何資料模型、persistence schema 或 migration。
- 不新增「依類別篩選」的列表 affordance (屬後續獨立提案)。
- 不重新設計右欄金額/利潤、avatar 與狀態膠囊本身的樣式。

## Decisions

### 移除後三碼，第一行改為「客戶名稱 · 訂購日期」並上移狀態膠囊

第一行去掉 `order.id.suffix(3)`，改以 `OrderFormatters.shortDate(order.date)` 顯示訂購日期，狀態膠囊 (`BLStatusPill`) 移到日期右側。理由：後三碼掃視價值最低且詳情頁/搜尋皆可取得；訂購日期是高頻關注維度，與客戶名稱以「·」配對 (who + when) 比原本 (who + 冗餘 id) 更自然。替代方案「客戶名稱 · 商品類別」被否決，因為與第二行商品明細語意重疊、且把不同軸 (who 與 what-kind) 用對等分隔點黏在一起。

### 商品類別以「膠囊外 tag 圖示 + neutral 灰底膠囊」呈現

新增第三行：前導 `tag` SF Symbol 置於膠囊外，右側以 neutral 灰底膠囊顯示類別文字。膠囊沿用狀態膠囊的外觀 (灰底 Capsule、`caption` 半粗體) 但不顯示狀態指示點。圖示與膠囊以 `HStack(alignment: .center)` 對齊垂直中心；膠囊文字以 `fixedSize` 維持單行、不提早換行。類別為空字串 (trim 後) 時整行不顯示。替代方案 (純文字無膠囊、圖示包進膠囊內、類別並排於狀態膠囊旁) 均經實機比較後否決。

### 將類別膠囊抽成 BLTagPill Design System 元件

原型期類別膠囊 inline 在 `OrderRowView` 且直接取用 `BLTheme.palette`，違反 feature view 不碰 Design System 內部色盤的慣例。正式版抽成 `BLTagPill` 元件，置於 `Shared/DesignSystem/Components/Tags/`，封裝「可選前導 SF Symbol (膠囊外) + neutral 灰底膠囊文字」。`OrderRowView` 改為只引用 `BLTagPill`，不再直接碰 palette。元件附自己的 `#Preview`。

### 單列垂直節奏統一為 8pt

`OrderRowView` 左欄 `VStack` 的子元件間距由 4pt 提升為 8pt (名稱↔明細↔類別一致)；單列垂直邊距總和調為 8pt，使類別膠囊上下間距、以及分隔線上下間距對稱。理由：原型在實機比較 4pt/8pt 後，8pt 為兼顧對稱與不擁擠的折衷 (行距由 24pt 收為 16pt)。

### 跨平台共用驗證與間距對齊

因 `OrderRowView` 與其 `VStack` 間距為四處共用，需確認 iPadOS (`OrdersView`)、macOS (`OrdersMacView`) 與 Dashboard 的列在新節奏下不破版；並檢查各平台 row 包裝層的垂直邊距，使其與 8pt 內部節奏搭配後同樣上下對稱。依專案規範，動到跨平台 view 後須序列化執行 macOS 與 iOS Simulator build 確認。

### 重錄 iOS snapshot baseline

單列版面改變，`BuyLedgerTests/__Snapshots__/` 既有 iOS 393×852 baseline 失效，需以 `TestDependencies.withFixedNow { ... }` 重錄並提交新 baseline。

## Implementation Contract

- **行為**：訂單列表每列呈現三行 — (1) 客戶名稱 · 訂購日期 + 狀態膠囊；(2) 商品明細 (各品名，可多行)；(3) 商品類別 tag 圖示 + neutral 灰底膠囊。後三碼不再出現於列表任何位置。類別為空字串時第三行完全不 render。三行間距與分隔線上下間距皆為 8pt。
- **介面**：新增 `BLTagPill(_ text: String, systemImage: String? = nil)` — 以 neutral tone 灰底 Capsule 呈現 `text`，`systemImage` 非 nil 時於膠囊左側 (膠囊外) 放置該 SF Symbol，圖示以 `HStack(alignment: .center)` 垂直置中、膠囊文字 `fixedSize` 單行。`OrderRowView` 以 `BLTagPill(order.category, systemImage: "tag")` 呈現，且僅在 `order.category` trim 後非空時加入版面。
- **失敗/空值模式**：`order.category` 為空或全空白 → 不顯示第三行 (沿用既有 trim 判斷)，不顯示空膠囊、不顯示孤立圖示。
- **驗收條件**：macOS 與 iOS Simulator build 皆通過；`OrderRowView` 不再直接引用 `BLTheme.palette`；iOS snapshot baseline 重錄並提交；實機或 Preview 目視確認三行版面、8pt 對稱間距、後三碼已移除、空類別不顯示第三行。
- **範圍邊界**：in scope — `OrderRowView` 版面、`BLTagPill` 新元件、`OrdersCompactView` 間距、iPad/Mac/Dashboard 共用列的目視與間距對齊、iOS snapshot baseline。out of scope — 訂單詳情頁、搜尋邏輯、資料模型/schema、右欄金額樣式、依類別篩選功能。

## Risks / Trade-offs

- [`OrderRowView` 為四處共用，改 `VStack` 間距會一併影響 iPad/Mac/Dashboard] → 在 tasks 內明確要求三平台 build 與目視驗證，必要時對齊各自包裝層邊距。
- [統一 8pt 使名稱↔明細也由 4pt 放寬到 8pt，列表整體略鬆] → 已於實機原型確認 8pt 為可接受折衷；若日後嫌鬆可改為僅對類別膠囊加 top padding，不影響本契約其餘部分。
- [snapshot baseline 若未重錄會導致測試失敗] → tasks 明列重錄步驟，且以固定時間注入確保跨機器一致。

## Migration Plan

無資料或 schema migration。屬純呈現層調整，可隨一般版本發布；如需回退，還原 `OrderRowView`、`OrdersCompactView` 與 `BLTagPill` 相關變更並還原 snapshot baseline 即可。

## Open Questions

- iPad (`OrdersView`) 與 macOS (`OrdersMacView`) 是否需要與 iPhone 完全相同的邊距值，或各自微調以符合平台慣例 — 於 apply 階段依各平台目視結果決定。
