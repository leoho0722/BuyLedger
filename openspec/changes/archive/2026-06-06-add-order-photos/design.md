## Context

- `OrderEditFeature` / `OrderEditView` 表單目前僅有文字、數值與 picker 欄位；訂單沒有任何影像附件能力，全 App 也尚無 PhotosUI 或影像處理程式碼。
- `LedgerOrder` 是 immutable struct (memberwise init 重建)；`OrderRecord` 採 `@Model class`，複合值 (customer / items) 以嵌入式 Codable transformable 儲存，刻意避免 relationship 以保留 CloudKit 相容性。
- Schema 鏈為 V7 (floor) → V8 → V9 (target)，全部 lightweight stage；CloudKit 目前 disabled。
- 專案硬規則：Swift 6 strict concurrency (`SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated`)、環境相依一律 @Dependency 注入、UI 寧可空狀態不顯示假資料。

## Goals / Non-Goals

**Goals:**

- 新增/編輯訂單表單可用系統原生 PhotosPicker 加入訂單照片，上限 5 張，可逐張刪除。
- 照片以 `Data` 形式隨 `OrderRecord` 持久化到 SwiftData，App 重啟後重開編輯表單仍可見。
- 既有 V9 (含更早 floor 以上) store 透過 lightweight migration 無痛升級，舊訂單照片為空陣列、其餘欄位不受影響。
- 點擊縮圖可全螢幕檢視該張照片，並在檢視器內左右滑動切換同訂單照片 (iOS / iPadOS 用 fullScreenCover、macOS 用 sheet)。
- 三平台 (iOS / iPadOS / macOS) 皆可編譯；以 iPhone 15 Plus 實機驗證。

**Non-Goals:**

- 訂單詳情頁 (OrderDetailView)、訂單列表與其他頁面的照片顯示——本次照片僅在編輯表單內可見與管理。
- 相機即時拍攝 (camera capture)、檢視器內的縮放手勢 (pinch zoom)。
- 照片重新排序、macOS 拖放匯入。
- CloudKit 同步策略 (sync 目前 disabled，啟用前另案評估)。
- 上限張數的使用者自訂 (固定 5 張)。

## Decisions

### 照片以 [Data] 欄位嵌入 OrderRecord，不建關聯表也不用 base64

照片在領域層為 `LedgerOrder.photos: [Data]`，持久層為 `OrderRecord.photos: [Data]` (帶 default 空陣列)。理由：與 `customer` / `items` 既有的嵌入式 Codable transformable 模式一致，不引入全專案第一個 relationship，維持 OrderRecord 註解明示的 CloudKit 相容設計。

考慮過的替代方案：

- **base64 string**：體積膨脹約 33%，且字串無型別意義，僅在無 binary 支援的儲存層才有必要——SwiftData 原生支援 `Data`，否決。
- **獨立 OrderPhotoRecord + relationship**：需要 sortIndex 維持順序、cascade delete rule、影子型別凍結複雜化，且違反現有「避免 relationship」設計，否決。
- **`@Attribute(.externalStorage)`**：Apple 文件記載的行為僅及單一 `Data` attribute；`[Data]` 是 transformable 複合值，externalStorage 對其行為未定義，不採用。改以「匯入時降採樣壓縮」控制 row 大小。

### 匯入管線：PhotosPicker 經 PhotoClient 與 PhotoDataProcessor 處理

- UI 用 PhotosPicker (PhotosUI，iOS 16+ / macOS 13+) 多選模式，`matching: .images`，`maxSelectionCount` 設為剩餘容量。
- 新增 `PhotoClient` dependency client (type-based `@Dependency(PhotoClient.self)` 注入)：`importPhotos: @Sendable ([PhotosPickerItem]) async -> [Data]`。liveValue 對每個 item 呼叫 `loadTransferable(type: Data.self)`，成功者交 `PhotoDataProcessor` 正規化；單一 item 失敗 (如 iCloud 離線) 靜默略過、不阻斷其他照片。reducer 測試注入 fake client，迴避 PhotosPickerItem 難以在測試中載入真實資料的問題。
- `PhotoDataProcessor` (Shared/Media/)：以 ImageIO (`CGImageSourceCreateThumbnailAtIndex` + `CGImageDestination`) 將影像降採樣至最長邊 1600 px、以 JPEG quality 0.75 重編碼；純函式、跨平台、無 UIKit/AppKit 分流。無法解碼時回傳 nil，該張略過。每張處理後預期數百 KB，5 張上限約 2 MB/筆訂單。

### 上限 5 張由 LedgerOrder.maxPhotoCount 常數定義、reducer 最終守門

領域常數 `LedgerOrder.maxPhotoCount = 5` 作為唯一來源：UI 的 `maxSelectionCount` 與計數標籤 (n/5) 引用它；reducer 在 `.photosImported` 時以 `prefix` 截斷，無論 picker 回傳幾張都不超過上限。UI 限制是體驗、reducer 截斷是不變量，測試以 reducer 行為為準。

### Schema V9 凍結為影子、新增 V10 lightweight stage

依 CLAUDE.md 標準四步流程：(1) 把目前 top-level `OrderRecord` 的屬性集合凍結成 `BuyLedgerSchemaV9` 內嵌影子 `@Model` (含 `isCashOnDelivery`、不含 `photos`)；(2) 新增 `BuyLedgerSchemaV10`，`models` 引用 top-level 定義；(3) `BuyLedgerMigrationPlan.schemas` 與 `stages` append V10 與 `.lightweight(fromVersion: V9, toVersion: V10)`；(4) `PersistenceContainer.make` 的 `Schema(versionedSchema:)` 改指 V10。新欄位 `photos: [Data] = []` 帶 default 走 lightweight。

### 編輯表單新增訂單照片 section 與 BLPhotoThumbnail 元件

- `OrderEditView` 在 notesSection 之後新增 photosSection (Section「訂單照片」)：橫向 ScrollView 的縮圖列 + PhotosPicker 觸發按鈕 + 計數標籤；已滿 5 張時隱藏加入按鈕。三平台共用同一 section，不做平台分流。
- 新增 Design System 元件 `BLPhotoThumbnail` (Components/Images/，獨立一檔)：輸入 `Data` 與刪除 callback，解碼為平台影像 (`#if canImport(UIKit)` 分流 UIImage/NSImage)，固定尺寸圓角縮圖 + 右上角刪除鈕；解碼失敗顯示 placeholder 圖示 (空狀態原則)。附 `#Preview`。

### 全螢幕照片檢視器 BLPhotoViewer：點縮圖開啟、左右滑動切換

- `BLPhotoThumbnail` 增加 `onTap` callback，僅掛在縮圖內容區——右上角刪除鈕本身是 `Button`，命中優先於 tap gesture，點刪除不會誤開檢視器。
- 新元件 `BLPhotoViewer` (Components/Images/ 獨立一檔)：輸入 `photos: [Data]`、`initialIndex` 與 `onDismiss`；以橫向 ScrollView + `scrollTargetBehavior(.paging)` + `scrollPosition` 實作左右滑動換頁——此組 API 在 iOS 17+ 與 macOS 14+ 皆可用，避免 `PageTabViewStyle` 不支援 macOS 的平台分流。黑底、影像 `scaledToFit`、頂部關閉鈕與計數標籤 (n/total)；單張解碼失敗顯示 placeholder 圖示。附 `#Preview`。
- 呈現方式：`OrderEditView` 以 view-local `@State` 持有被點擊的照片 index (比照既有 `showsOrderSourceSheet` 等 view-local sheet toggle 模式)。檢視為純呈現、不影響任何草稿資料，故不進 reducer。
- 呈現容器 (實機比較三種形式後定案)：三平台一律 `.sheet(item:)`；檢視器以 NavigationStack 包裹，navigation title 置中顯示計數 (x/n)、右上 toolbar 按鈕為 ✕ 關閉，iOS 上保留 sheet 的下滑關閉手勢。落選方案 (iOS fullScreenCover、popup 暗背景疊層卡片) 已移除。
- 版面細節 (實機調校定案)：照片顯示區嚴格位於 navigation bar 之下，四邊各留 `BLSpacing.small` (10pt) 間距；照片四角以 `.mask` 套 `BLRadius.small` (10pt) 圓角 (不用 clipShape——直接套在 image-backed layer 上的 clipShape 在 snapshot 光柵化路徑不生效)。背景不另外鋪色，沿用 sheet 的系統背景隨深淺色模式自適應。NavigationStack 會把貼齊 safe area 上緣的 ScrollView 自動延伸到 bar 底下，靠上述 padding 阻斷。

### TCA 狀態與 action 形狀

- State 新增：`draftPhotos: [Data]` (init 自 `original?.photos ?? []`)、`photoPickerSelection: [PhotosPickerItem] = []`。
- Action 新增：`.photosImported([Data])` (append 後 cap、清空 picker selection)、`.deletePhotoTapped(Int)` (依 index 移除)。`.binding(\.photoPickerSelection)` 非空時觸發 effect 呼叫 PhotoClient。
- `LedgerOrder` 新增欄位後，所有 memberwise init 呼叫點同步補 `photos:` 參數：`OrdersFeature.applyEditDraft` (新增帶 `draftPhotos`、更新帶 `draftPhotos`)、`OrdersFeature` 內收款狀態等兩處整筆重建 (帶原 `order.photos`)、`RootFeature.rebuildOrder` (帶原 `order.photos`)、`LedgerOrder+Samples` (帶空陣列，避免 repo 塞入二進位樣本)。

## Implementation Contract

**可觀察行為：**

- 編輯表單顯示「訂單照片」section；點「加入照片」開啟系統相簿 picker，可一次多選；確認後縮圖出現在表單中。
- 照片總數達 5 張時無法再加入；每張縮圖的刪除鈕移除該張。
- 儲存訂單後 kill App 重啟，再次編輯同一筆訂單，照片仍完整呈現；刪除訂單時照片隨 record 一併刪除。
- 主檔 cascade rename (訂單來源／類別／付款方式／對帳狀態／開團) 重建訂單時照片不遺失。
- 既有訂單升級到新版後照片為空、其餘欄位值不變。
- 點擊任一縮圖 (非刪除鈕) → 全螢幕開啟該張照片；檢視器內左右滑動依儲存順序切換上一張／下一張，至第一張／最後一張即停止；關閉鈕返回編輯表單且草稿內容不變。

**介面／資料形狀：**

- `LedgerOrder.photos: [Data]`、`LedgerOrder.maxPhotoCount: Int` (static，值 5)。
- `OrderRecord.photos: [Data] = []`，`init(order:)` / `apply(_:)` / `toDomain()` 三處 mapping 同步。
- `BuyLedgerSchemaV10` (Schema.Version(10, 0, 0))、`.lightweight(fromVersion: BuyLedgerSchemaV9.self, toVersion: BuyLedgerSchemaV10.self)`。
- `PhotoClient.importPhotos: @Sendable ([PhotosPickerItem]) async -> [Data]`。
- `PhotoDataProcessor.downscaledJPEGData(from:maxPixelSize:compressionQuality:) -> Data?`，預設最長邊 1600、quality 0.75。
- `BLPhotoThumbnail(imageData:onTap:onDelete:)`。
- `BLPhotoViewer(photos:initialIndex:onDismiss:)`，左右滑動以橫向 paging ScrollView 實作。

**失敗模式：**

- 單張照片 loadTransferable 失敗或無法解碼 → 該張靜默略過，其餘照片正常加入；不顯示錯誤 alert (與「寧可空狀態不顯示假資料」一致，使用者可由縮圖數量察覺)。
- 已持久化的照片 Data 無法解碼 → 縮圖顯示 placeholder 圖示，不崩潰。
- Migration 失敗 → 沿用既有 `makeForApp()` 開發期 fallback (砍檔重建)，由 on-disk 回歸測試把關不讓此情況發生。

**驗收條件：**

- 單元測試：OrderEditFeatureTests (匯入 append 與 cap 至 5、刪除指定 index、picker selection 匯入後清空)；OrderPersistenceTests (photos 經 upsert / fetch round-trip 不變)；SchemaMigrationTests (V9 on-disk store 以 V10 plan 重開：訂單數與欄位值不變、photos 為空)。
- 三平台 build 序列化通過 (iOS Simulator、iPadOS Simulator、macOS)。
- 實機手動驗證 (iPhone 15 Plus)：加 5 張 → 無法加第 6 張 → 刪 1 張 → 儲存 → 重啟 → 重開編輯表單照片仍在；點縮圖全螢幕開啟該張 → 左右滑動切換 → 關閉返回表單。
- Snapshot：orderEditViewBaseline 因新 section 變動，重新 record 後 commit 新 baseline。

**範圍邊界：**

- In scope：編輯表單照片管理、持久化、V10 migration、全螢幕檢視器 (含左右滑動)、上述測試。
- Out of scope：詳情頁/列表照片顯示、相機、檢視器縮放手勢、排序、CloudKit、照片相關 UI 以外的任何表單改動。

## Risks / Trade-offs

- [照片 inline 儲存使 DB row 變大、`fetchAll` 全量載入時記憶體上升] → 匯入時降採樣 (1600 px / JPEG 0.75) 控制單張數百 KB、上限 5 張；個人帳本資料量級可接受。若未來照片量成長，再另案評估獨立 record 或 lazy 載入。
- [lightweight migration 對新增 transformable `[Data]` 欄位的相容性屬推定 (既有欄位皆為純量或既存 transformable)] → SchemaMigrationTests 補 V9 → V10 on-disk 回歸測試，build 階段即驗證。
- [HEIC 轉 JPEG 重編碼喪失原始畫質與 metadata] → 用途為對帳憑證而非相片典藏，可接受；換取體積與跨平台解碼穩定性。
- [PhotosPickerItem 無法在單元測試中載入真實資料] → 以 PhotoClient 依賴反轉，reducer 流程全可測；liveValue 的 loadTransferable 路徑由實機手動驗證涵蓋。
- [Snapshot baseline 變動] → 屬預期變更，依 README record / commit 流程重建。

## Migration Plan

- 部署：V10 隨 App 更新生效；停在 V7~V9 的 store 依既有 stage 鏈逐段 lightweight 遷移，已在 V10 的 store 開啟時 delta 為 0。
- 回退：schema 升版為單向 (forward-only)；目前為 pre-release 階段，若需回退以 `makeForApp()` 開發期 fallback 重建空 store，不影響正式使用者。

## Open Questions

(無——儲存形式、上限、壓縮參數與範圍邊界皆已定案。)
