## 1. 資料模型與型別 (Domain)

- [x] 1.1 [P] 新增 CampaignStatus (ongoing/closed) 與 Campaign domain struct，達成 "Campaign entity with two-state lifecycle"；依設計「Campaign 採用獨立有狀態實體，不擴充為第五種 LookupKind」與「CampaignStatus 兩態加 settledDate 結團標記」。驗證：CampaignFeatureTests 建團後 status 為 ongoing 且 settledDate 為 nil。
- [x] 1.2 [P] 新增 PaymentReceiptStatus (pending/received) enum，達成 "Every order carries a payment receipt status"；依設計「訂單新增 paymentReceiptStatus 收款狀態欄位」。驗證：新建訂單預設 pending，由 OrdersFeature 套用編輯草稿測試覆蓋。
- [x] 1.3 於 LedgerOrder 新增 campaignName 與 paymentReceiptStatus 並補齊所有 memberwise 重建點 (RootFeature 重建、OrdersFeature 狀態變更與套用編輯草稿)，達成 "An order can be assigned to a single campaign"；依設計「訂單以 campaignName 字串歸團並沿用 cascade rename」。驗證：專案編譯通過 (immutable struct 全參數必填) 且 OrdersFeature 既有測試維持綠燈。

## 2. 持久化與 Schema V8

- [x] 2.1 新增 CampaignRecord (@Model) 與 toDomain/apply，名稱重複由 actor 檢查、不使用唯一性約束 (CloudKit 相容)。驗證：CampaignPersistenceTests upsert 後 fetch 回讀欄位一致。
- [x] 2.2 於 OrderRecord 新增 campaignName 與收款狀態 rawValue 欄位 (帶 default) 並補 init/apply/toDomain 互轉。驗證：既有 OrderPersistenceTests 維持綠燈且新欄位往返一致。
- [x] 2.3 達成「Schema V8 lightweight 遷移與凍結 V7 OrderRecord 影子型別」：新增 BuyLedgerSchemaV8 (含 CampaignRecord)、把 V7 OrderRecord 凍結為影子 @Model、MigrationPlan append lightweight stage、PersistenceContainer 的 Schema 指向 V8。驗證：以 V7 既有資料升級後舊訂單仍在 (模擬器先裝舊版再裝新版 build-and-run 比對)。

## 3. Repository 層

- [x] 3.1 [P] 新增 CampaignRepository (fetch/save/remove/rename) 與 CampaignPersistence (@ModelActor)，liveValue 走 PersistenceContainer.shared 並以 type-based @Dependency 注入。驗證：CampaignPersistenceTests 覆蓋 upsert/fetch/rename/delete。
- [x] 3.2 [P] OrderRepository 與 OrderPersistence 新增 renameOrderCampaign 改寫所有歸屬訂單，達成 "Renaming a campaign cascades to its orders"。驗證：OrderPersistenceTests rename 後所有相符訂單 campaignName 皆更新。

## 4. CampaignFeature 與彙總

- [x] 4.1 新增 CampaignSummary 純函式 (分貨依客戶名 trim 分組、收款面 應收/已收/未收、損益面重用 OrderSummary、到貨比例排除已取消)，達成 "Settlement summary aggregates member orders" 與 "Distribution groups member orders by customer"；依設計「分貨清單與結算全部 derive 自歸屬訂單 (CampaignSummary)」。驗證：CampaignSummaryTests 覆蓋分組、加總、已收款判定與除零。
- [x] 4.2 新增 CampaignFeature (載入 + 截單日自動轉 + 狀態切換 + 結團 + CRUD)，reducer body 用顯式 some Reducer<State, Action>、時間取自 @Dependency(\.date)，達成 "Automatic transition from ongoing to closed at the close date" 與 "Settling records a date without changing status"；依設計「截單日到自動由開團中轉已收單，採前景掃描並走依賴注入日期」。驗證：CampaignFeatureTests 以固定注入日期驗證過期團轉 closed、結團設 settledDate 且 status 不變。
- [x] 4.3 新增 CampaignEditFeature (name/openDate/closeDate/status/notes) sheet 子 reducer，承接 CampaignFeature 新增與編輯。驗證：CampaignFeatureTests 新增與編輯流程綠燈。

## 5. Orders 整合

- [x] 5.1 達成「CampaignFeature 與資料流：OrdersFeature 持有完整 Campaign 副本」：OrdersFeature 於 task 載入完整 [Campaign] 副本，供選團與依狀態篩選時解析訂單所屬團。驗證：OrdersFeature 測試 campaignsLoaded 後副本正確。
- [x] 5.2 OrdersFeature 的 filteredOrders 併入 selectedCampaign 與 selectedCampaignStatus 兩維度並與既有篩選合成，達成 "Filter orders by campaign status" 與 "Filter orders by a specific campaign"；依設計「訂單列表雙維度開團篩選」。驗證：OrdersFeature 測試覆蓋狀態篩選、團名篩選與其他篩選合成。
- [x] 5.3 OrderEditFeature 與 OrderEditView 加開團選擇器 (僅選既有團) 與收款狀態欄位 (所有訂單顯示)，達成 "The order editor selects from existing campaigns only"、"Receipt status is editable for all orders" 與 "Receipt status is the source of truth for received amounts"。驗證：OrdersFeature applyEditDraft 測試寫入 campaignName 與 paymentReceiptStatus，iOS build-and-run 檢視編輯欄位。

## 6. RootFeature 與導覽

- [x] 6.1 RootTab 新增 campaigns case 並於 RootFeature Scope CampaignFeature，使開團於專屬分頁管理，達成 "Campaign management lives in a dedicated tab"。驗證：RootFeatureTests 切換分頁，iOS build-and-run 見開團分頁。
- [x] 6.2 RootFeature 攔截開團改名與狀態變更 cascade 到訂單表與 OrdersFeature 兩處副本，並新增 campaignSelected 導覽到開團詳情，達成 "Selecting a campaign navigates to its detail"；依設計「Dashboard 與 Insights 開團整合與 campaignSelected 跨頁導覽」。驗證：RootFeatureTests 改名後訂單與副本同步、campaignSelected 切分頁並選團。
- [x] 6.3 三平台分頁：RootTabLayout (iPhone) 與 RootSidebarLayout (iPad/macOS) 加開團 destination 與 sidebar 導覽列。驗證：iOS、iPadOS、macOS 三平台序列 build 通過且皆見開團入口。

## 7. 開團 UI

- [x] 7.1 CampaignListView 顯示每團狀態 pill、筆數、總額、已收款與到貨進度，無團顯示空狀態，達成 "Campaign list shows progress derived from member orders"。驗證：iOS build-and-run 檢視列表與空狀態。
- [x] 7.2 CampaignDetailView 顯示 meta、結團結算 (收款面 + 損益面)、客戶分貨清單 (可展開品項、未付款標記、只看未收款) 與逐筆訂單 (切換收款狀態) 與結團按鈕。驗證：iOS build-and-run 檢視詳情，結算數字對照 CampaignSummaryTests。

## 8. Dashboard 與 Insights 整合

- [x] 8.1 [P] Dashboard 新增「進行中的開團」卡 (列開團中團 + 進度條 + 金額，無進行中團則隱藏)，點擊觸發 campaignSelected，達成 "Dashboard shows an ongoing campaigns card"。驗證：iOS build-and-run，無進行中團時卡片不顯示。
- [x] 8.2 [P] Insights 於 InsightsStats 加開團分組並以 BLBarChart 顯示每團毛利排行 (排除無訂單團)，點擊觸發 campaignSelected，達成 "Insights shows a per-campaign profit ranking"。驗證：iOS build-and-run，排行順序對照 profit 加總。

## 9. 測試與驗證

- [x] 9.1 [P] 補 CampaignSummaryTests (分組/加總/已收款/收款面/損益面/到貨比例排除取消/散單不納入/除零)。驗證：test target 綠燈。
- [x] 9.2 [P] 補 CampaignFeatureTests (載入與自動轉、狀態切換、結團、新增與刪除，固定注入 date 與遞增 uuid)。驗證：test target 綠燈。
- [x] 9.3 [P] 補 CampaignPersistenceTests (in-memory upsert/fetch/rename/delete)。驗證：test target 綠燈。
- [x] 9.4 [P] 補 RootFeature 與 OrdersFeature 測試 (開團改名 cascade、campaignSelected、雙維度篩選)。驗證：test target 綠燈。
- [x] 9.5 手動驗證 V7 到 V8 lightweight 遷移不丟資料，並執行 iOS、iPadOS、macOS 三平台序列 build。驗證：三平台序列 build 全綠且舊訂單保留。

## 10. 開團列表增強 (實作期間追加)

- [x] 10.1 開團列表依開團日期分頂層區段，並提供日／月／年分組切換 (月→日、年→月巢狀子標題，年另於列上顯示開團日期)，達成 "Campaign list groups campaigns by open date with selectable granularity"。驗證：iOS 實機 build-and-run 切換各分組檢視。
- [x] 10.2 開團列表工具列加狀態篩選 (全部／開團中／已收單) 與分組折疊子選單；篩選與分組合成、無結果顯示空狀態，達成 "Campaign list filters by status"。驗證：iOS 實機 build-and-run 篩選各狀態。
