## 1. 驗證與衍生計算下放 reducer

- [x] 1.1 [P] 完成「非負驗證下放 QuoteFeature 的 binding 處理」:QuoteFeature 於 BindingReducer 之後 clamp itemPrice、domesticShipping、internationalShippingTwd、cardFeePercent、paymentFeePercent、platformFeePercent、targetMarginPercent 至不小於 0 (目標毛利不設上限),QuoteView 移除 nonNegativeBinding 改直接綁 store。驗證:新增 QuoteFeatureTests 送出寫入負值的 binding action,斷言 state 收斂為 0;iOS build 綠。
- [x] 1.2 [P] 完成「存檔日期補秒改由 OrderEditFeature 的 dateComponentsChanged 承接」:新增 dateComponentsChanged(Date) action,reducer 以注入的 date 取當下秒數、與傳入日期年月日時分用固定 gregorian/UTC 曆重組後寫入 draftDate;OrderEditView 的日期 binding setter 只送該 action。驗證:OrderEditFeatureTests 注入固定 date 斷言 draftDate 的秒數與年月日時分正確;build 綠。

## 2. 帶 domain 意義的 @State 移入 feature state

- [x] 2.1 完成「洞察分析區間收進 RootFeature 狀態」,滿足 spec「Insights analysis range is owned by feature state and persists」:RootFeature 新增分析區間欄位 (預設近十二個月) 與 insightsRangeSelected action,InsightsView 改讀 state、以 action 更新。驗證:RootFeatureTests 送 insightsRangeSelected 斷言 state 變更;手動於 iPad 切換分頁再回、iPhone 切 tab 再回,區間保持不重置。
- [x] 2.2 [P] 完成「開團詳情未付款篩選收進 CampaignFeature 狀態」,滿足 spec「Campaign detail unpaid-only view filter persists across navigation」:CampaignFeature 新增未付款篩選 Bool 與 unpaidOnlyToggled action,CampaignDetailView 改綁 state。驗證:CampaignFeatureTests 送 unpaidOnlyToggled 斷言 state;手動 push 進詳情、返回列表、重進詳情,篩選保持啟用。
- [x] 2.3 [P] 完成「Lookup 改名與編輯流程改用 Presents Destination」:LookupManagementFeature 新增 Presents Destination (rename、editPaymentMethod 兩 case),reducer 在進入改名/編輯的當下自主檔字典快照初值,可儲存與否改為 destination 草稿 state 的 computed property,View 以 scope 呈現。驗證:LookupManagementFeatureTests 斷言 present → 改草稿 → canSave → confirm → 送出對應 effect 的完整生命週期;build 綠。

## 3. 彙總計算下放可測層與新 feature

- [x] 3.1 完成「新增 CustomersFeature 承載客戶彙總」,滿足 spec「Customers screen aggregates orders into per-customer summaries」:新 feature 以純聚合函式依 customer.name 分組、加總 revenue、取最近訂單日、依總消費由高到低排序輸出客戶摘要;RootFeature 組合並同步訂單投影,CustomersView 改綁 CustomersFeature。驗證:CustomersFeatureTests 以 spec 範例的三客戶輸入斷言排序與各欄數值;空訂單斷言空狀態;build 綠。
- [x] 3.2 完成「Dashboard 與 Insights 彙總計算下放 RootFeature 可測 helper」:Dashboard 的營收成本獲利彙總、月度小計與 sparkline,Insights 的走勢、上期比較、熱力圖、類別結構、開團獲利排名,以及側邊欄進行中訂單徽章計數,抽成接受 referenceDate/calendar 的純函式或 RootFeature 狀態方法,View 只讀取結果。驗證:新增彙總純函式單元測試 (固定 referenceDate) + 既有 insights/dashboard snapshot baseline 不變;build 綠。

## 4. 訂單 compact 導覽遷移

- [x] 4.1 完成「訂單 compact 導覽改用 OrdersFeature 的 StackState」:OrdersFeature 以 StackState 承載 compact 詳情堆疊 (最小 detail 元素),reducer 在訂單載入/刪除/合併事件同步修剪堆疊路徑,OrdersCompactView 的 NavigationStack 改綁 scoped stack path、移除 View 內 onChange 修剪。驗證:OrdersFeatureTests 斷言「push 詳情後刪除該訂單 → 對應堆疊元素被移除」;手動 compact push/pop 與刪除;iOS+iPadOS build 綠。

## 5. 整合驗收

- [x] 5.1 全測試套件綠燈:iOS 與 iPadOS 各 build 成功,BuyLedgerTests 全數通過 (含本次新增的各 FeatureTests)。驗證:xcodebuildmcp 於 iPhone 與 iPad 模擬器各跑一次 test,exit 0。
- [x] 5.2 手動與 snapshot 驗收:iPad 切分頁後洞察區間保持、開團詳情重進後未付款篩選保持兩個 bug 修正確認;snapshot baseline 未因行為等價的重構而變動 (若誤動依 README 流程重錄)。驗證:實機/模擬器手動走查 + snapshot test 綠。
