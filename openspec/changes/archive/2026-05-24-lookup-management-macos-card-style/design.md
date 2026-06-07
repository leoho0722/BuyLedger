## Context

訂單來源、商品類別、付款方式三頁共用 `LookupManagementView`，目前 body 是一段不分平台的系統 `List`（`Section` + 列 + `.swipeActions` + `.contextMenu` + section header「目前已建立 N 項」+ 付款方式 footer）。在 macOS 上，這與同樣從「更多」進入的 `CustomersView`（`ScrollView` + `palette.background` + `BLCard`）以及 `MoreView` 的 macOS 卡片版面不一致。`MoreView` 已示範 `#if os(macOS)` 分流 phone List 與 macOS 卡片的既有慣例。

約束：

- Swift 6 strict concurrency、TCA、SwiftData（見 CLAUDE.md）。
- `.swipeActions` 僅在 `List` 內生效；macOS 現況的刪除／重新命名實際走 `.contextMenu`（右鍵）。
- Design System 元件：`BLCard(padding:radius:)`（surface 底、separator 描邊、陰影）、`BLSpacing`、`BLTheme.palette(for:)`、`palette.background/surface/separator/secondaryLabel/tertiaryLabel`。
- 環境相依：顏色透過 `@Environment(\.colorScheme)` 取 palette，與 `CustomersView` 一致。

## Goals / Non-Goals

**Goals:**

- macOS 上三個主檔管理頁的視覺與 `CustomersView` 一致（ScrollView + palette 背景 + BLCard 列表）。
- iOS / iPadOS 的外觀與操作（List + 滑動刪除 + 右鍵）完全不變。
- 三平台的新增／重新命名／刪除操作邏輯與 `LookupManagementFeature` 業務邏輯與現況完全相同。

**Non-Goals:**

- 不改 iOS / iPadOS 的版面或互動。
- 不改 `LookupManagementFeature`、`LookupKind`、`CustomersView`、`BLCard`、repository 或資料層。
- 不在 macOS 引入現況沒有的互動（例如尾端 `⋯` menu、in-card 按鈕）；macOS 沿用 `.contextMenu`。
- 不新增或重建 snapshot baseline（snapshot 測試僅 iOS，且 iOS 不變）。

## Decisions

### macOS 卡片版面與 iOS/iPadOS List 以 `#if os(macOS)` 分流

把 `LookupManagementView` 的內容區拆成 `@ViewBuilder` 的 `content`：`#if os(macOS)` 走新的卡片版面（`macContent`），`#else` 原封不動沿用現有 `List`（`listContent`）。沿用 `MoreView` 既有的平台分流慣例。

- 替代方案：用 `horizontalSizeClass` 在 iPad 也切卡片——否決，使用者明確要求 iPad 維持 List + swipe，且 iPad 不是 `os(macOS)`，自然落入 List 分支。

### 共用 toolbar / alert / sheet / task modifier 提取到平台分支之外

`.navigationTitle`、toolbar `+`（primaryAction）、重新命名 `.alert`、新增類別／來源 `.alert`、新增付款方式 `.sheet`、`.task` 一律掛在 `content` 之外的單一 root，由兩個分支共用，確保新增／重新命名／刪除的觸發與業務邏輯兩平台完全一致。`@State`（`draft`、`renameTarget`、`renameDraft`、`showsAddCategoryAlert`、`showsAddPaymentMethodSheet`）維持不變。

- 替代方案：兩個分支各自掛一份 modifier——否決，會造成重複與兩平台漂移風險。

### macOS 卡片列沿用 `.contextMenu` 觸發重新命名與刪除

macOS 卡片每一列保留與現況相同的 `.contextMenu`（重新命名／刪除），不引入新互動。因 `.swipeActions` 在 macOS 本就不生效，移除它對 macOS 零影響；iOS/iPadOS 分支仍保有 `.swipeActions`。

### macOS header、無卡 footnote 與徽章對齊 `CustomersView` 樣式

macOS 卡片上方以 `CustomersView.customerList` 的 header 樣式呈現計數（大寫次級標籤 +「N 項」）；列包在單一 `BLCard(padding: 0)`，列間用帶 leading inset 的 `Divider`；付款方式列右側保留現有「無卡」Capsule 徽章，無卡說明改為卡片下方 `.footnote` 次級色 `Text`；空狀態沿用 `ContentUnavailableView`（`kind.emptyTitle/emptyDescription`）包在 `.frame(maxWidth/maxHeight: .infinity)` + palette 背景中。

## Implementation Contract

**範圍**：僅修改 `apps/apple/BuyLedger/Features/Lookups/LookupManagementView.swift` 的呈現層。

**可觀察行為：**

- 在 macOS，訂單來源／商品類別／付款方式三頁皆以 `ScrollView` + `palette.background` 呈現，內容為單一 `BLCard` 列表（列間分隔線），與 `CustomersView` 視覺一致；頂部顯示計數 header；付款方式頁列右側顯示「無卡」徽章、卡片下方顯示無卡說明 footnote；右鍵任一列可「重新命名／刪除」；導覽列右上「+」可新增；無資料時顯示置中 `ContentUnavailableView`。
- 在 iOS / iPadOS，三頁維持現有 `List`：section header「目前已建立 N 項」、付款方式 List footer、列可左滑刪除／重新命名、亦可長按 `.contextMenu`，與本次變更前逐一相同。
- 三平台的新增（toolbar `+` → alert/sheet）、重新命名、刪除、付款方式 `isCardless` 標示，行為與 `LookupManagementFeature` 寫入結果與現況完全相同。

**介面 / 資料形狀：** 不改 `LookupManagementFeature` 的 State 與 Action、不改 `LookupKind`、不改 `BLCard`。view body 重構為 root + 平台分支 `content`；共用 modifier 掛在 root。

**失敗模式：** 不新增；新增／重新命名的空字串與重複名稱驗證（`disabled` 條件與 trimming）沿用現況。

**驗收標準：**

- macOS build 與 iOS Simulator build 皆成功（依 CLAUDE.md 序列化執行，加 `--log-level error`）。
- macOS：三頁皆為卡片版面、計數 header、付款方式無卡徽章＋footnote、右鍵可重新命名／刪除、toolbar「+」可新增、空狀態置中。
- iPhone：三頁與變更前一致（List + 滑動刪除）。
- 既有 iOS snapshot 測試（若涵蓋）維持通過、不需重建 baseline。

**範圍邊界：** 不動 `LookupManagementFeature`、`LookupKind`、`CustomersView`、`BLCard`、repository、iOS/iPadOS 版面、snapshot baseline。

## Risks / Trade-offs

- [macOS 與 iPhone 版面分歧造成日後維護兩套呈現] → 共用 modifier 已集中於 root，分支只負責內容；以 `#if os(macOS)` 清楚標示，沿用 `MoreView` 既有慣例。
- [iPhone 上 `CustomersView` 是卡片、本頁仍是 List 的局部不一致] → 使用者明確取捨：iOS 原生滑動刪除優先於跨頁視覺統一。
- [Design System 檔案結構變更需 build 驗證 file system synchronized groups] → 本次不新增／搬移檔案，僅改單一現有檔，風險低；仍以 macOS + iOS build 雙重驗證。

## Migration Plan

無資料或結構遷移。純呈現層重構；rollback 即還原單一檔案。

## Open Questions

無。平台範圍、互動方式、header/footer/徽章處理已於 `/spectra-discuss` 收斂確認。
