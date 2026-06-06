## 1. Schema 與資料模型

- [x] 1.1 [P] `OrderStatus` 新增 `merged` case (rawValue `"merged"`、title「已合併」，排在 `cancelled` 之後)，`realizedStatuses` allowlist 維持不變使「已合併」自動排除於收益統計 (對應 design「資料模型改為多選並新增「已合併」狀態」)。驗證：新增 unit test 斷言 `OrderStatus.merged` 的 rawValue/title 與「不屬於 realizedStatuses」；BuyLedgerTests 全綠。
- [x] 1.2 `LedgerOrder` 欄位改陣列：`category: String` → `categories: [String]`、`campaignName: String` → `campaignNames: [String]`、新增 `mergedSourceIDs: [String]` (預設空陣列)，落實 spec「An order can be assigned to multiple categories」與「An order can be assigned to multiple campaigns」(取代被移除的「An order can be assigned to a single campaign」)。`LedgerOrder+Samples` 改用陣列並補一筆多類別/多開團 + 非空 `mergedSourceIDs` 樣本；全專案呼叫點以編譯錯誤窮舉、先做語意等價的機械修正 (單值 ↔ 單元素陣列)。驗證：iOS Simulator、macOS、iPadOS 三平台 build 序列化通過 (`cmd1 && cmd2 && cmd3`)，BuyLedgerTests 編譯通過。
- [x] 1.3 依 `/swiftdata-schema-migration` skill 完成 design「SwiftData V11 custom migration」：凍結 V10 shadow、新增 `BuyLedgerSchemaV11` (categories/campaignNames/mergedSourceIDs)、append V10 → V11 `.custom` dump-and-restore stage，落實 spec「Type-changing migrations preserve values through a custom stage」的映射規則 (非空字串 → 單元素陣列、空字串 → 空陣列、mergedSourceIDs 一律空陣列)。驗證：`SchemaMigrationTests` 新增 V10 on-disk store 升版回歸案例，斷言映射表三種組合與其餘欄位完整保留。

## 2. 元件與編輯表單

- [x] 2.1 [P] `OptionPickerSheet` 新增多選模式，落實 spec「Optional multi-select mode」(對應 design「OptionPickerSheet 多選模式」)：`Set<String>` 選取、點列 toggle 不關閉 sheet、「完成」按鈕關閉、搜尋與新增選項流程與單選一致；單選 API 與行為完全不變。驗證：`#Preview` 補多選範例；既有單選呼叫點 build 通過且 `SnapshotTests` 既有 baseline 不變。
- [x] 2.2 `OrderEditFeature` 草稿改陣列並做單/多選分流：`draftCategories: [String]`、`draftCampaignNames: [String]`、`mergeSourceIDs: [LedgerOrder.ID]` (預設空)；落實 spec「Category multi-selection is offered only in merge contexts」與「The order editor selects from existing campaigns only」——合併情境 (合併草稿或 `original.mergedSourceIDs` 非空) 用多選 picker (類別保留新增入口、開團僅限既有選項)，一般訂單維持單選體驗並儲存單元素陣列；`canSave` 類別非空陣列；trigger row 以「、」串接顯示 (對應 design「編輯表單多選草稿與金額欄位鎖定」)。驗證：`OrderEditFeatureTests` 覆蓋單/多選分流、必填驗證與儲存陣列正規化 (trim/去重/去空)。
- [x] 2.3 金額與明細欄位鎖定，落實 spec「Amount and item fields of merge-related orders are locked」：`OrderEditFeature.State` 增 computed property `isAmountLocked` (合併確認草稿、合併產生訂單、狀態已合併三情境為 true)，`OrderEditView` 據此將收款金額/成本/手續費/商品明細四個 section 唯讀並顯示鎖定說明 footer；狀態 Picker 過濾 `merged` (僅當前狀態已是 merged 時顯示，作為誤合併回復路徑)。驗證：`OrderEditFeatureTests` 斷言三種情境的 `isAmountLocked` 與一般訂單為 false；snapshot 補合併訂單編輯表單 baseline。

## 3. 合併核心

- [x] 3.1 [P] 新建 `BuyLedger/BuyLedger/Core/Domain/OrderMerge.swift` (依 `/swift-file-template`)，落實 design「合併計算 OrderMerge 純函式」與 spec「Merged draft prefill rules」全部欄位規則：類別/開團保序聯集去重、訂購日期取注入時間、金額七欄位逐項加總、手續費三項以客戶實付加權平均 (clamp [0,1]、分母 0 取主訂單值、不得 NaN)、付款方式無卡優先 (對帳狀態與貨到付款隨付款方式來源)、商品明細串接、備註以 `----------` 獨立行分隔、照片主前副後串接。驗證：新建 `BuyLedgerTests/OrderMergeTests.swift` 逐規則斷言 (含加權平均表、備註三組合、聯集去重、零實付 edge case)。
- [x] 3.2 新建 `OrderMergeFeature` 兩步驟 reducer 與 `OrderMergeCandidateSheet`、`MergePhotoPickerSheet` 兩個 view (依 design「合併流程與 OrderMergeFeature」)：落實 spec「Merge candidate selection」(排除自身/已合併/已取消、限同幣別、限同客戶名稱、列顯客戶/日期/客戶實付、即時搜尋、空狀態) 與「Photo over-limit selection step」(合計 > 5 張先挑選至多 5 張、≤ 5 直接帶入)。驗證：TestStore 測試覆蓋候選過濾矩陣 (eligibility matrix)、搜尋、照片步驟觸發條件與 delegate 回傳。
- [x] 3.3 入口接線，落實 spec「Order merge entry points」：`OrdersView` 與 `OrdersCompactView` 的 row context menu 新增「合併訂單」、`OrderDetailView` 增 optional `onMerge` callback 由兩個 host 以 toolbar 動作接到同一個 `OrdersFeature` action；已合併/已取消訂單不顯示入口；合併 sheet 掛 `OrdersView` 最外層、與編輯 sheet 序列化呈現 (effect 延遲一拍)。驗證：`OrdersFeatureTests` 斷言入口 action 開啟候選 state 與 merged/cancelled 擋下；三平台 build 通過。
- [x] 3.4 持久化合併寫入 (對應 design「持久化合併寫入與 cascade rename」)：`OrderPersistence` / `OrderRepository` 新增 `mergeOrders(new:consumedIDs:)` 單次 save 完成「插入新單 (含 mergedSourceIDs) + 舊單轉 merged」；`OrdersFeature` 攔截合併草稿的 `saveTapped` 走此路徑，落實 spec「Saving a merged draft commits atomically」(失敗不留半套、走既有錯誤路徑) 與「Cancelling the merge leaves no changes」。驗證：`OrderPersistenceTests` 斷言原子性與來源 ID 寫入；`OrdersFeatureTests` 斷言儲存後 in-memory 狀態與取消零變更。

## 4. 篩選、統計與顯示

- [x] 4.1 篩選比對改 contains (對應 design「統計歸屬與篩選比對」)：`OrdersFeature.filteredOrders` 落實 spec「Category filter on the orders list」「Category filter combines with existing filters」「Filter orders by campaign status」(任一所屬開團符合即中)「Filter orders by a specific campaign」；「Deep link from analytics applies the category filter」與「Category filter is presented as a trigger button with a searchable picker sheet」的 containment 語意隨之成立 (UI 不變)。驗證：`OrdersFeatureTests` 覆蓋多類別/多開團訂單的篩選矩陣與組合篩選；`RootFeatureTests` deep link 案例維持綠燈。
- [x] 4.2 統計歸屬改「葉端訂單 (合併前收益)」：Insights 類別彙總落實 spec「Category revenue attributes pre-merge amounts from leaf orders」、每團獲利/Dashboard 開團卡片/`CampaignSummary` 落實 spec「Campaign analytics attribute pre-merge amounts from leaf orders」、整體不重複計算落實 spec「Analytics attribution after a merge uses pre-merge revenue」——葉端 = `mergedSourceIDs` 為空、狀態屬 realized ∪ merged；合併產生訂單不入組；彙總邏輯收在可測試 helper。驗證：`CampaignSummaryTests` 與新增的類別彙總 unit test 覆蓋歸屬矩陣 (含鏈式合併單一計算案例)。
- [x] 4.3 cascade rename 改陣列逐元素取代：`renameOrderCategory` / `renameOrderCampaign` 與 `RootFeature.rebuildOrder` 改陣列，落實 spec「Renaming a category cascades into order category lists」與「Renaming a campaign cascades to its orders」。驗證：`OrderPersistenceTests` 與 `RootFeatureTests` 斷言多元素陣列中僅目標元素被改名、持久化與 in-memory 同步。
- [x] 4.4 多值顯示：`OrderRowView` 第三行落實 spec「Row third line shows product category as a tag」(「、」串接單一 capsule、空陣列不渲染)；`OrderDetailView` 類別與開團欄同樣以「、」串接。驗證：unit test 斷言 join/缺席邏輯；受影響的 `SnapshotTests` baseline 重錄並於 PR 說明。

## 5. 整體驗收

- [x] 5.1 全套驗收：BuyLedgerTests 全綠 (xcodebuildmcp CLI 跑 test)；三平台 build 序列化通過；以 `xcodebuildmcp` device build-and-run 部署到使用者 iPhone 實機，依「合併入口 → 候選選擇 → 照片挑選 → 預填表單 (金額/明細唯讀) → 儲存 → 舊單已合併 → 統計不重複」流程供使用者手動驗收。

## 6. 實機驗收回饋修正 (2026-06-07)

- [x] 6.1 落實 spec「Merge-related orders stay fully editable」(對應 design「編輯表單多選草稿與金額欄位編輯性」)：移除 `OrderEditFeature.State.isAmountLocked` 與 `OrderEditView` 四個 section (收款金額/成本/手續費/商品明細) 的 `.disabled`、鎖定說明 footer、商品列 `deleteDisabled` 與「新增商品」隱藏條件——合併確認表單、合併產生的訂單、被合併舊訂單全部恢復與一般訂單相同的可編輯行為；狀態 Picker 過濾「已合併」與類別/開團多選 picker 維持不變。驗證：`OrderEditFeatureTests` 移除鎖定斷言並改斷言三種合併情境欄位可編輯 (binding 寫入金額成功)；`OrdersFeatureTests` 合併流程測試移除 `isAmountLocked` 斷言；snapshot 重錄合併情境編輯表單 baseline (無鎖定 footer、顯示「新增商品」)；BuyLedgerTests 全綠；三平台 build 通過；device build-and-run 部署實機供使用者驗收。
- [x] 6.2 訂單頁狀態篩選補「已合併」選項 (spec「Merged orders remain findable」的實作缺口)：`OrderStatusFilter.orderBrowsingCases` 加入 `.status(.merged)`，三平台膠囊狀態 filter (OrdersView / OrdersCompactView / OrdersMacView 共用此清單) 隨之出現「已合併」；「已取消」維持既有設計不列入。驗證：`OrderStatusTests.statusFilterBrowsingCasesIncludeMerged` 斷言清單包含 merged；SnapshotTests 視膠囊列變動重錄；BuyLedgerTests 全綠；device build-and-run 部署實機。
