## 1. Design System：BLTagPill 元件

- [x] 1.1 [P] 新增 `BuyLedger/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift`：定義 `BLTagPill(_ text: String, systemImage: String? = nil)`，以 neutral tone 灰底 `Capsule` 呈現 `text`，`systemImage` 非 nil 時於膠囊左側 (膠囊外) 放置該 SF Symbol，圖示與膠囊以 `HStack(alignment: .center)` 垂直置中、膠囊文字 `fixedSize` 維持單行。行為：提供可重用的類別標籤元件，呼叫端不需碰 `BLTheme.palette`。驗證：附 `#Preview` 展示「有 icon」與「無 icon」兩種樣態，iOS Simulator build 通過。實作設計決策：將類別膠囊抽成 BLTagPill Design System 元件。

## 2. OrderRowView E 版型

- [x] 2.1 `OrderRowView` 第一行改為「客戶名稱 · `OrderFormatters.shortDate(order.date)`」，將 `BLStatusPill` 移到日期右側，並移除 `order.id.suffix(3)`。行為：列表第一行呈現 who + when + 狀態，後三碼不再出現於列表。驗證：實機/Preview 目視第一行為「名稱 · 日期 + 狀態膠囊」，列表任何位置皆無後三碼。實作需求 (spec)：Row first line shows customer and order date；設計決策 (design)：移除後三碼，第一行改為「客戶名稱 · 訂購日期」並上移狀態膠囊。
- [x] 2.2 `OrderRowView` 第三行改用 `BLTagPill(order.category, systemImage: "tag")`，僅在 `order.category` 經 `trimmingCharacters(in: .whitespacesAndNewlines)` 後非空時加入版面；移除原型期 inline 的 `BLTheme.palette` 取用與 `@Environment(\.colorScheme)`。行為：類別以膠囊外 tag 圖示 + neutral 灰底膠囊呈現，空類別不顯示第三行，且 view 不再直接引用 palette。驗證：以非空、空字串、純空白三種 category 目視 (後兩者不顯示第三行)；grep 確認 `OrderRowView.swift` 不再出現 `BLTheme.palette`。實作需求 (spec)：Row third line shows product category as a tag；設計決策 (design)：商品類別以「膠囊外 tag 圖示 + neutral 灰底膠囊」呈現。
- [x] 2.3 `OrderRowView` 左欄 `VStack(alignment: .leading)` 間距設為 `BLSpacing.small`。行為：名稱↔商品明細↔類別三段垂直間距統一為 8pt。驗證：實機目視三段間距相等。實作需求 (spec)：Row uses symmetric vertical spacing；設計決策 (design)：單列垂直節奏統一為 8pt。
- [x] 2.4 確認 `OrderRowView` 第二行 `order.itemSummary` 在 E 版型重構後仍逐項列出各商品名稱、行為不變 (regression)。行為：第二行持續顯示商品明細。驗證：實機/Preview 目視第二行為各品名清單。實作需求 (spec)：Row second line shows item details。

## 3. iOS 間距與分隔線對稱

- [x] 3.1 [P] 調整 `OrdersCompactView` 的 row 包裝層垂直邊距，使 row 邊距與 `OrderRowView` 自身 `BLSpacing.extraSmall` 合計為 8pt。行為：類別膠囊上下間距對稱，分隔線與相鄰兩列內容等距 (皆 8pt)。驗證：實機目視膠囊上方、下方到分隔線、以及分隔線到下一列內容皆為 8pt。實作需求 (spec)：Row uses symmetric vertical spacing；設計決策 (design)：單列垂直節奏統一為 8pt。

## 4. 跨平台共用驗證與間距對齊

- [x] 4.1 確認 iPadOS `OrdersView`、macOS `OrdersMacView` 與 Dashboard 共用的列在新版面與 8pt 節奏下不破版，必要時對齊各自 row 包裝層垂直邊距達成相同對稱。行為：三處列呈現一致、版面不破。驗證：iPad 與 macOS 目視確認。設計決策 (design)：跨平台共用驗證與間距對齊。
- [x] 4.2 依專案規範序列化執行 (`cmd1 && cmd2`) macOS 與 iOS Simulator build，確認 file system synchronized groups 正確拾取新增的 `BLTagPill.swift` 且三平台皆編譯通過。行為：新檔被專案拾取、三平台 build 綠。驗證：build 成功且無遺漏檔案警告。

## 5. 測試

- [x] 5.1 以 `TestDependencies.withFixedNow { ... }` 重錄 `BuyLedger/BuyLedgerTests/__Snapshots__/` 的 iOS 393×852 baseline 並提交。行為：snapshot baseline 反映新版單列摘要。驗證：snapshot 測試 (`SnapshotTests`) 對新 baseline 通過。設計決策 (design)：重錄 iOS snapshot baseline。
