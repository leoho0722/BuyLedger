## Why

訂單目前只能以文字記錄 (商品項目、備註)，使用者無法保存訂單相關的視覺憑證 (商品照片、對話截圖、收據)。代購情境中照片是對帳與售後溝通的重要依據，需要讓訂單可以附帶照片並隨訂單持久化保存。

## What Changes

- 「新增/編輯訂單頁」(OrderEditView) 新增「訂單照片」section：以系統原生 PhotosPicker (PhotosUI) 多選照片，上限 5 張，已滿 5 張時不可再加選。
- 已加入的照片以縮圖呈現，每張縮圖可單獨刪除。
- 點擊縮圖 (非刪除鈕) 放大檢視該張照片：三平台統一以 sheet 呈現，title 置中顯示計數 (x/n)、右上 toolbar ✕ 關閉；檢視器內可左右滑動切換同訂單的其他照片，照片帶小圓角、四邊留固定間距。(曾試做 fullScreenCover 與 popup 疊層兩種替代呈現，經實機比較後擇定 sheet。)
- 照片經統一縮圖處理 (降採樣 + JPEG 重新編碼) 後以 `Data` 形式存入 SwiftData，隨訂單儲存、更新與刪除同生命週期。
- 領域模型 `LedgerOrder` 新增 `photos: [Data]` 欄位；持久化模型 `OrderRecord` 新增對應屬性並更新雙向 mapping。
- SwiftData schema 由 V9 升版至 V10 (lightweight migration，新欄位帶 default 空陣列)；V9 的 `OrderRecord` 依慣例凍結為影子型別。
- 既有訂單 (V9 store) 升級後照片為空陣列，原有欄位資料不受影響。

## Capabilities

### New Capabilities

- `order-photo-attachments`: 訂單照片附件——在編輯表單中加選 (上限 5 張)、刪除與持久化訂單照片的完整行為。

### Modified Capabilities

(none — 既有的 schema migration 規格以 floor/target 抽象描述需求，新增 V10 屬於既有需求內的實作演進，不變更 spec 層級行為)

## Impact

- Affected specs: 新增 `order-photo-attachments`
- Affected code:
  - New:
    - BuyLedger/BuyLedger/Core/Dependencies/PhotoClient.swift (PhotosPickerItem 載入與縮圖處理的 dependency client)
    - BuyLedger/BuyLedger/Shared/Media/PhotoDataProcessor.swift (ImageIO 降採樣 + JPEG 重新編碼 helper)
    - BuyLedger/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift (可刪除、可點擊開啟檢視的照片縮圖元件)
    - BuyLedger/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift (全螢幕照片檢視器，支援左右滑動切換)
    - BuyLedger/BuyLedgerTests/PhotoDataProcessorTests.swift (降採樣與 JPEG 重編碼的單元測試)
  - Modified:
    - BuyLedger/BuyLedger/Core/Domain/LedgerOrder.swift
    - BuyLedger/BuyLedger/Core/Domain/LedgerOrder+Samples.swift
    - BuyLedger/BuyLedger/Core/Persistence/OrderRecord.swift
    - BuyLedger/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
    - BuyLedger/BuyLedger/Core/Persistence/PersistenceContainer.swift
    - BuyLedger/BuyLedger/Features/Orders/OrderEditFeature.swift
    - BuyLedger/BuyLedger/Features/Orders/OrderEditView.swift
    - BuyLedger/BuyLedger/Features/Orders/OrdersFeature.swift
    - BuyLedger/BuyLedger/Features/App/RootFeature.swift
    - BuyLedger/BuyLedgerTests/OrderEditFeatureTests.swift
    - BuyLedger/BuyLedgerTests/OrderPersistenceTests.swift
    - BuyLedger/BuyLedgerTests/SchemaMigrationTests.swift
    - BuyLedger/BuyLedgerTests/SnapshotTests.swift
  - Removed: (none)
