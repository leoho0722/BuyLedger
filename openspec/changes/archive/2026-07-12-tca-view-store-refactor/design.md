## Context

BuyLedger 為 iOS/iPadOS 的 TCA + SwiftUI + SwiftData App。一次平行 TCA 稽核 (10 個 sub-agent) 確認 View 層無「直接繞過 reducer 竄改 domain state」的硬違規,但整理出三類待收斂項目:(1) 兩處商業規則與衍生計算漏在 View 的手刻 binding 內;(2) 多個帶 domain 意義的 @State 被鎖在 View,其中洞察區間與開團未付款篩選兩者在 iPad 切換分頁或 push/pop 重進時會被重置 (真實 bug);(3) 數處資料彙總 inline 在 View,牴觸平台「計算下放 reducer 或可測 helper」硬規則。本設計描述如何把這些狀態與計算收斂回 Store 與可測層,並補 TestStore 測試,行為除兩個持久化修正外保持等價。

## Goals / Non-Goals

**Goals:**

- 把 View 端的非負驗證與存檔日期補秒計算移入對應 reducer,使唯一把關點在 Store。
- 把帶 domain 意義的 @State (洞察區間、開團未付款篩選、Lookup 改名/編輯流程、訂單 compact 導覽路徑) 移入對應 feature state,達成可用 TestStore 驗證並修正兩個持久化 bug。
- 抽出 CustomersFeature 承載客戶彙總;把 Dashboard/Insights/側邊欄的彙總計算下放到可測層。
- 每個移入 Store 的項目補 TestStore 單元測試。

**Non-Goals:**

- 不變更 SwiftData schema (純 in-memory TCA state 重構)。
- 訂單篩選 sheet 的 pending 暫存維持 View-local staging,不收進 reducer。
- 不為目標毛利加上限;非負維持既有語意,只是把關點改到 reducer。
- 除兩個持久化 bug 修正外,不變更任何畫面的視覺或操作流程。

## Decisions

### 非負驗證下放 QuoteFeature 的 binding 處理

保留 QuoteFeature 的 BindingReducer,於其後的 Reduce 攔截 binding action,把七個數值欄 (itemPrice、domesticShipping、internationalShippingTwd、cardFeePercent、paymentFeePercent、platformFeePercent、targetMarginPercent) clamp 到不小於 0;clamp 為冪等,任何寫入路徑 (含測試直接 send binding) 都收斂到合法值。View 端移除 nonNegativeBinding helper,numberField 直接綁定 store。目標毛利不加上限。替代方案:改成每欄具名 action;不採,因七欄共用同一 clamp 規則、具名 action 徒增樣板。

### 存檔日期補秒改由 OrderEditFeature 的 dateComponentsChanged 承接

新增 OrderEditFeature 的 dateComponentsChanged(Date) action,由 reducer 以注入的 date 取得當下秒數,與傳入日期的年月日時分,用固定 gregorian/UTC 曆重組後寫入 draftDate;曆採確定性的顯式 gregorian (非環境相依的 current),符合注入原則。View 端的日期 binding setter 改為單純送出該 action,不再於 View 讀取注入時間做寫入前計算。行為與現況等價,唯計算搬進可測 reducer。

### 洞察分析區間收進 RootFeature 狀態

洞察頁無獨立 reducer、資料自 RootFeature 投影;將分析區間欄位加入 RootFeature 狀態 (預設近十二個月),新增 insightsRangeSelected action,InsightsView 改讀該狀態並以 action 更新。此舉修正 iPad 走側邊欄 switch 條件渲染時、切走再回會重建 View 導致區間被重置的 bug (iPhone 的 Tab ForEach 常駐不受影響,但統一由 state 擁有後兩平台一致)。

### 開團詳情未付款篩選收進 CampaignFeature 狀態

在 CampaignFeature 狀態新增未付款篩選旗標 (單一 Bool,與既有 statusFilter/grouping 同層級),新增 unpaidOnlyToggled action;CampaignDetailView 改綁該狀態。修正以 navigationDestination push 每次重建 View 導致篩選被重置的 bug。採單一 Bool 而非每開團字典,因詳情頁一次只顯示一個開團、且與既有列表層篩選的單值慣例一致。

### Lookup 改名與編輯流程改用 Presents Destination

在 LookupManagementFeature 狀態加入 Presents 的 Destination,含改名與編輯付款方式兩個 case;改名 case 帶原名與草稿,編輯 case 帶原名與快照後的三個布林旗標。使用者點改名/編輯時送 action,由 reducer 在該當下自 state 的主檔字典快照初值進 destination,取代 View 直接以 editTarget 索引 store 字典組裝表單初值。可儲存與否改為 destination 草稿 state 上的 computed property。新增 alert 與其草稿可一併收進 destination 的新增 case 以求一致,列為選配、不阻塞。

### 訂單 compact 導覽改用 OrdersFeature 的 StackState

訂單 compact 導覽路徑改用 OrdersFeature 狀態的 StackState,以最小的 detail 堆疊元素承載被推入的訂單詳情,使堆疊由 reducer 擁有、可被 TestStore 斷言。原本在 View 以 onChange 監看訂單集合、刪除或合併後修剪路徑的收斂邏輯,改由 reducer 在既有 domain 事件 (訂單載入/刪除/合併) 發生時同步修剪 StackState。NavigationStack 改綁 scoped 的 stack path。此為本次範圍最大的單項,替代方案 (維持純 ID 陣列進 state) 較輕但非 StackState,依使用者指定採 StackState。

### 新增 CustomersFeature 承載客戶彙總

新增 CustomersFeature,狀態持有來源訂單、以純函式聚合出每位客戶的消費總額、訂單筆數、最近訂單日與排序 (聚合函式接受 referenceDate、不內呼系統時間);RootFeature 組合此 feature 並同步訂單投影,CustomersView 改綁 CustomersFeature。原本 inline 在 CustomersView 的 aggregateCustomers 移入此 feature 並補單元測試。

### Dashboard 與 Insights 彙總計算下放 RootFeature 可測 helper

把 Dashboard 的營收成本獲利彙總、月度小計與 sparkline,以及 Insights 的走勢、上期比較、熱力圖、類別結構、開團獲利排名,從 View 抽成可測純函式或 RootFeature 狀態方法 (簽章接受 referenceDate/calendar、不內呼系統時間);側邊欄的進行中訂單徽章計數同樣下放。View 只讀取結果。既有已標非 private 供測試的函式併入統一可測家門。

## Implementation Contract

**可觀察行為**

- Quote:對七個數值欄輸入或貼上負值時,reducer 將其收斂為 0;目標毛利仍無上限。
- OrderEdit:透過日期選擇器改日期時,秒數沿用當下真實秒 (與現況相同),計算改於 reducer 完成。
- Insights:所選分析區間在 iPhone 與 iPad 上切換分頁、離開再回都保持不變。
- 開團詳情:「只看未付款」在離開詳情再重進後保持不變。
- Lookup:改名與編輯付款方式的操作流程與畫面對使用者不變;儲存鈕的可用與否由 feature state 推導。
- 訂單 compact:導覽堆疊存活於 store;刪除或合併訂單時,對應被推入的詳情如現況般被移除。
- Customers / Dashboard / Insights / 側邊欄:彙總數字與畫面不變,計算改由可測層產生。

**介面與資料形狀 (以名稱標示,不引用行號)**

- QuoteFeature:binding 後的 clamp;移除 View 的 nonNegativeBinding。
- OrderEditFeature:新增 dateComponentsChanged(Date)。
- RootFeature:新增洞察區間狀態欄位與 insightsRangeSelected action;新增 Dashboard/Insights 彙總的可測 helper;組合 CustomersFeature。
- CampaignFeature:新增未付款篩選旗標與 unpaidOnlyToggled action。
- LookupManagementFeature:新增 Presents Destination (改名、編輯付款方式),與進入編輯的 action。
- OrdersFeature:新增 StackState 導覽路徑與最小 detail 元素;reducer 在訂單載入/刪除/合併時修剪路徑。
- CustomersFeature:新檔,狀態持有訂單來源、聚合函式輸出客戶摘要集合。

**失敗模式**

- 無新增失敗模式;clamp 冪等;空資料維持既有空狀態呈現 (不繪假資料)。

**驗收標準**

- 每個移入 Store 的項目有對應 TestStore 測試:Quote 負值收斂、OrderEdit 日期補秒、Insights 區間更新、Campaign 未付款切換、Lookup 改名/編輯 destination 生命週期、Orders 刪除後路徑修剪、Customers 聚合輸出、Dashboard/Insights 彙總純函式。
- iOS 與 iPadOS 各 build 成功。
- 既有 snapshot baseline 不需重錄 (行為視覺等價);若因結構微調誤動,依 README 流程重錄。
- 手動:iPad 切換分頁後洞察區間保持;開團詳情重進後未付款篩選保持。

**範圍邊界**

- 範圍內:上述 feature 的 state/action/reducer 與對應 View 綁定調整、可測 helper 抽取、新 CustomersFeature、對應測試。
- 範圍外:SwiftData schema、OrderFilterSheet pending、目標毛利上限、任何視覺重設計。

## Risks / Trade-offs

- [StackState 遷移為最大單項,牽動 compact 導覽] → 先以最小 detail 元素落地、確保現有 push/pop 與刪除修剪行為不變,再補測試;此項獨立成 stage、build 綠燈才續。
- [reducer clamp 與 BindingReducer 執行順序] → clamp 置於 BindingReducer 之後、冪等;以負值輸入測試守門。
- [Dashboard/Insights 計算下放動到大檔] → 抽為純函式並保持簽章接受 referenceDate/calendar、行為等價;以既有 snapshot 加新單元測試雙重把關。
- [CustomersFeature 改動導覽接線] → 保持 CustomersView 視覺與列互動不變,僅換 store 來源。
- [Insights/Campaign 兩個持久化修正是行為變更] → 已於 proposal 標 BREAKING、於對應 spec delta 明列;屬修 bug 的預期變更。

## Migration Plan

實作分階段、每階段 iOS+iPadOS build 綠燈才進下一階段:1) 低風險下放 (Quote 非負、OrderEdit 日期補秒、側邊欄計數);2) @State 移入 (Insights 區間、Campaign 未付款、Lookup destination);3) 彙總下放大檔 (Dashboard/Insights 計算、CustomersFeature);4) StackState 導覽遷移 (最大);5) 補齊 TestStore 測試;6) iOS+iPadOS build 與 snapshot 驗證。無 schema 變更,回退為還原對應 commit。

## Open Questions

- StackState 的堆疊元素粒度 (完整 detail feature vs 最小元素) 於 apply 時定案,預設採最小元素以控制範圍。
