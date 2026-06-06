## 1. 領域模型與持久化欄位

- [x] 1.1 `LedgerOrder` 新增 `photos: [Data]` 欄位與 `static let maxPhotoCount = 5` 常數，落實 design「照片以 [Data] 欄位嵌入 OrderRecord，不建關聯表也不用 base64」與「上限 5 張由 LedgerOrder.maxPhotoCount 常數定義、reducer 最終守門」的領域形狀 (BuyLedger/BuyLedger/Core/Domain/LedgerOrder.swift)。驗證：1.2 與 1.3 完成後全專案編譯通過 (memberwise init 簽章變更會在所有呼叫點強制顯式處理)。
- [x] 1.2 所有 `LedgerOrder` memberwise init 呼叫點補上 `photos:` 參數，確保 cascade rename 重建與既有流程不遺失照片 (spec: Photos persist with the order — Master-data rename keeps photos)：`RootFeature.rebuildOrder` 與 OrdersFeature 內兩處整筆重建帶原 `order.photos`；`LedgerOrder+Samples` 帶空陣列。驗證：既有 OrdersFeatureTests 與 RootFeature 相關測試全數維持綠燈。
- [x] 1.3 先在 OrderPersistenceTests 新增「photos 經 upsert / fetchAll round-trip 後 byte 級不變」的測試 (TDD)，再於 `OrderRecord` 新增 `photos: [Data] = []` 並同步 `init(order:)` / `apply(_:)` / `toDomain()` 三處 mapping，使訂單照片隨 record 儲存與刪除 (spec: Photos persist with the order)。驗證：該新測試由紅轉綠。

## 2. Schema V10 migration

- [x] 2.1 依 design「Schema V9 凍結為影子、新增 V10 lightweight stage」：把 V9 時代的 `OrderRecord` 屬性集合 (含 `isCashOnDelivery`、不含 `photos`) 凍結為 `BuyLedgerSchemaV9` 內嵌影子 `@Model`，保住 V9 attribute 指紋 (BuyLedger/BuyLedger/Core/Persistence/BuyLedgerSchema.swift，比照 V8 影子寫法)。驗證：2.3 的 on-disk 回歸測試以 V9 影子建立舊 store 成功。
- [x] 2.2 新增 `BuyLedgerSchemaV10` (models 引用 top-level 定義)、在 `BuyLedgerMigrationPlan` 的 schemas 與 stages append V10 與 lightweight stage，並把 `PersistenceContainer.make` 的 Schema(versionedSchema:) 改指 V10，使舊 store 升級後照片為空陣列、其餘欄位不變 (spec: Existing stores migrate with empty photo lists)。驗證：2.3 測試通過。
- [x] 2.3 SchemaMigrationTests 新增 V9 → V10 on-disk 回歸測試：以 V9 schema 寫入 3 筆訂單到磁碟 store，改以 V10 migration plan 重開，斷言 3 筆訂單與其欄位值完整、每筆 `photos` 為空陣列 (spec: Existing stores migrate with empty photo lists)。驗證：xcodebuildmcp 跑 BuyLedgerTests 該測試綠燈。

## 3. 照片匯入管線

- [x] 3.1 [P] 先新增 PhotoDataProcessorTests (TDD：給定長邊超過 1600 px 的影像 data 應輸出最長邊不超過 1600 的 JPEG；給定無法解碼的 data 應回傳 nil)，再實作 `PhotoDataProcessor.downscaledJPEGData(from:maxPixelSize:compressionQuality:)`，以 ImageIO 降採樣與 JPEG 重編碼 (spec: Imported photos are normalized before storage；新檔 BuyLedger/BuyLedger/Shared/Media/PhotoDataProcessor.swift 與 BuyLedger/BuyLedgerTests/PhotoDataProcessorTests.swift)。驗證：新測試由紅轉綠。
- [x] 3.2 實作 `PhotoClient` dependency client (importPhotos 對每個 PhotosPickerItem 呼叫 loadTransferable 取 Data、交 PhotoDataProcessor 正規化、失敗項目靜默略過)，完成 design「匯入管線：PhotosPicker 經 PhotoClient 與 PhotoDataProcessor 處理」(新檔 BuyLedger/BuyLedger/Core/Dependencies/PhotoClient.swift)。驗證：三平台編譯通過；liveValue 載入路徑由 6.4 實機驗收涵蓋。

## 4. OrderEditFeature 狀態與 reducer

- [x] 4.1 先在 OrderEditFeatureTests 以 TestStore 新增測試 (TDD)：匯入 append 與 cap 截斷 (0+5→5、3+4→5 只收前 2、5+1→5 不變)、匯入後 photoPickerSelection 清空、刪除中間照片保序 ([A,B,C] 刪 B 得 [A,C])；再依 design「TCA 狀態與 action 形狀」實作 State (`draftPhotos` 自 original 帶入、`photoPickerSelection`)、Action (`.photosImported` / `.deletePhotoTapped`) 與 binding 觸發的匯入 effect，reducer 以 `LedgerOrder.maxPhotoCount` 守門 (spec: Attach photos to an order via the native photo picker；Delete an attached photo)。驗證：新測試由紅轉綠。
- [x] 4.2 `OrdersFeature.applyEditDraft` 在新增與更新兩分支帶入 `draftPhotos`，使儲存後的 `LedgerOrder` 含照片 (spec: Photos persist with the order)。驗證：OrdersFeatureTests 新增「儲存草稿後訂單 photos 等於 draftPhotos」案例綠燈。

## 5. UI：編輯表單與 Design System 元件

- [x] 5.1 [P] 新增 `BLPhotoThumbnail` 元件 (輸入 imageData 與 onDelete callback；固定尺寸圓角縮圖 + 右上刪除鈕；解碼失敗顯示 placeholder 圖示；附 #Preview)，落實 design「編輯表單新增訂單照片 section 與 BLPhotoThumbnail 元件」(新檔 BuyLedger/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift)。驗證：#Preview 正常渲染、macOS 與 iOS Simulator build 確認 file system synchronized groups 拾取新檔。
- [x] 5.2 `OrderEditView` 於 notesSection 後新增「訂單照片」photosSection：PhotosPicker 多選 (`matching: .images`、maxSelectionCount 為剩餘容量)、縮圖橫列與計數標籤 (n/5)、滿 5 張隱藏加入按鈕 (spec: Attach photos to an order via the native photo picker — Add control unavailable when full)。驗證：6.1 snapshot 與 6.4 實機手動驗收。

## 6. 測試、建置與驗收

- [x] 6.1 重新 record 並 commit `orderEditViewBaseline` snapshot baseline (新 section 造成的預期變動)，依 README record / commit 流程操作。驗證：SnapshotTests 全綠且 diff 僅含照片 section。
- [x] 6.2 三平台 build 序列化執行 (iOS Simulator、iPadOS Simulator、macOS，以 && 串接避免 build.db 鎖)。驗證：三個 build 皆 BUILD SUCCEEDED。
- [x] 6.3 以 xcodebuildmcp 跑 BuyLedgerTests 全套單元測試。驗證：全數綠燈，無既有測試回歸。
- [x] 6.4 build-and-run 至實機 iPhone 15 Plus 手動驗收：新增訂單加入 5 張照片 → 無法加第 6 張 → 刪除 1 張 → 儲存 → 強制結束 App 重啟 → 重開該訂單編輯表單照片完整呈現 (spec: Photos persist with the order；Attach photos to an order via the native photo picker)。驗證：上述每一步行為與 spec 一致並截圖回報。

## 7. 全螢幕照片檢視 (需求變更追加)

- [x] 7.1 [P] 依 design「全螢幕照片檢視器 BLPhotoViewer：點縮圖開啟、左右滑動切換」：`BLPhotoThumbnail` 增加 `onTap` callback (僅掛縮圖內容區，刪除鈕 Button 命中優先不誤觸)；新增 `BLPhotoViewer` 元件 (輸入 photos / initialIndex / onDismiss；橫向 paging ScrollView 左右滑動、黑底 scaledToFit、計數標籤 n/total、關閉鈕、解碼失敗 placeholder、附 #Preview) (spec: View attached photos full screen；新檔 BuyLedger/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift)。驗證：三平台 build 通過、#Preview 正常渲染。
- [x] 7.2 `OrderEditView` photosSection 接上檢視器：以 view-local @State 持有被點擊照片 index，iOS / iPadOS 用 fullScreenCover、macOS 用 sheet 呈現 `BLPhotoViewer`；點縮圖開啟該張、左右滑動依儲存順序切換 (至首尾即停)、關閉返回表單且草稿不變 (spec: View attached photos full screen)。驗證：三平台 build + 7.3 實機驗收。
- [x] 7.3 重新 build-and-run 至實機 iPhone 15 Plus，驗收完整流程 (含 6.4 原步驟與檢視器)：加 5 張 → 無法加第 6 張 → 點縮圖全螢幕開啟該張 → 左右滑動切換 → 關閉 → 刪 1 張 → 儲存 → 重啟 → 照片還原 (spec: View attached photos full screen；Photos persist with the order)。驗證：使用者於實機確認每一步行為與 spec 一致。
- [x] 7.4 新增檢視器呈現方案二 (popup 疊層) 並以 compile-time 常數 `photoViewerStyle` 切換：`OrderEditView` 以 `.overlay` 呈現半透明暗背景 (點擊即關閉) + 圓角卡片內嵌 `BLPhotoViewer`，scale + opacity transition；方案一 (cover) 程式碼保留、由常數切回。預設方案二供實機比較 (spec: View attached photos full screen — popup overlay)。驗證：三平台 build、單元測試全綠、部署 iPhone 15 Plus 由使用者比較兩方案後擇一。
