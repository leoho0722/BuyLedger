## 1. View body 平台分流骨架

- [x] 1.1 依設計「macOS 卡片版面與 iOS/iPadOS List 以 `#if os(macOS)` 分流」，把 `LookupManagementView` body 重構為 root + `@ViewBuilder content`（`#if os(macOS)` → 新 macContent；`#else` → 現有 List 原樣保留）。行為：交付 spec「Platform-adaptive lookup management presentation」——macOS 走卡片、iOS/iPadOS 走 List。驗證：序列化執行 `xcodebuildmcp --log-level error macos build` 與 `simulator build`（iPhone 17）皆 BUILD SUCCEEDED。
- [x] 1.2 依設計「共用 toolbar / alert / sheet / task modifier 提取到平台分支之外」，把 `.navigationTitle`、toolbar `+` primaryAction、重新命名 `.alert`、新增類別/來源 `.alert`、付款方式 `.sheet`、`.task` 掛在 `content` 之外的 root 共用，`@State`（draft / renameTarget / renameDraft / showsAddCategoryAlert / showsAddPaymentMethodSheet）不變。行為：交付 spec「Lookup item management operations are preserved across platforms」——兩平台新增/重新命名/刪除觸發與 `LookupManagementFeature` 業務邏輯一致。驗證：iPhone 與 macOS 各跑一次新增/重新命名/刪除，項目清單與寫入結果與變更前相同。

## 2. macOS 卡片內容

- [x] 2.1 依設計「macOS header、無卡 footnote 與徽章對齊 `CustomersView` 樣式」，實作 macContent：`ScrollView` + `palette.background` + 計數 header（大寫次級標籤 +「N 項」）+ 單一 `BLCard(padding: 0)` 列表（列間 `Divider` 帶 leading inset）。行為：交付 spec「Lookup item count and empty state」的計數顯示，且視覺與 `CustomersView` 一致。驗證：macOS run，訂單來源/商品類別/付款方式三頁皆顯示卡片版面與計數 header。
- [x] 2.2 在 macOS 卡片列實作付款方式「無卡」Capsule 徽章與卡片下方 `.footnote` 次級色說明文字。行為：交付 spec「Payment method cardless indicator」。驗證：macOS run 付款方式頁，標記為 isCardless 的項目顯示「無卡」徽章，且畫面顯示無卡說明 footnote。
- [x] 2.3 macOS 空狀態以 `ContentUnavailableView`（`kind.emptyTitle` / `kind.emptyDescription`）置中於 `palette.background`。行為：交付 spec「Lookup item count and empty state」的空狀態。驗證：macOS run 在無資料時三頁顯示對應空標題與描述並置中。
- [x] 2.4 依設計「macOS 卡片列沿用 `.contextMenu` 觸發重新命名與刪除」，macOS 每一列保留現有 `.contextMenu`（重新命名/刪除），不引入新互動。行為：交付 spec「Lookup item management operations are preserved across platforms」中 macOS 右鍵操作與現況相同。驗證：macOS run 右鍵任一列出現「重新命名/刪除」且皆可運作。

## 3. iOS/iPadOS 回歸驗證

- [x] 3.1 確認 `#else` 分支沿用原 List（section header「目前已建立 N 項」、`.swipeActions`、`.contextMenu`、付款方式 List footer）未被更動。行為：交付 spec「Platform-adaptive lookup management presentation」中 iOS/iPadOS 維持 List，以及「Lookup item management operations are preserved across platforms」的 iOS 滑動刪除。驗證：iPhone 17 run 三頁與變更前一致，列可左滑刪除/重新命名。

## 4. 整合驗證

- [x] 4.1 交付 design「Implementation Contract」的驗收標準：序列化執行 macOS build 與 iOS Simulator build 皆成功，並確認既有 iOS snapshot 測試（若涵蓋本頁）維持通過、不需重建 baseline。驗證：`xcodebuildmcp --log-level error macos build` 與 `simulator build` 皆 BUILD SUCCEEDED；相關 snapshot 測試綠燈。
