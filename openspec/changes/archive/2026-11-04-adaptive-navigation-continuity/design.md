## Context

需求來源為本次 Spectra discuss 對話，使用者逐項採納根導覽、點選後才開啟詳情、分頁狀態保留、統一總覽／分析、彈性欄寬及閱讀寬度，最後明確指定「比例不寫死」。本提案由 Codex 整理；以下產品決策屬使用者，狀態表示與遷移順序屬 Codex 的技術設計。

提案前已讀取的基線證據 (現行實作進度見 verification.md)：
- `RootView.layout` 依 `blLayoutClass` 替換 `RootTabLayout`／`RootSidebarLayout`；後者另外掌管訂單的 content／detail 欄與全域座標欄寬計算。
- `OrdersDetailNavigationFeature.State` 同時持有 `path` 與 `regularDetail`；初始化、`OrdersFeature.applyLoadedOrders`、`OrderListFeature.selectFirstFilteredOrder` 會選第一筆。`OrdersFilterOperations` 的搜尋與篩選更新會重選。
- `RootFeature.core` 的 `sidebarTabSelected` 先清空更多路徑；`MoreFeature.core` 收到客戶跨頁意圖也先清空 path。`RootFeatureSidebarTests` 明確要求清空，必須更新成新的保留契約。
- `CampaignFeature.State.showDetail` 已以 path 表示詳情，`CampaignView` 目前只有 NavigationStack；`MoreView` 的入口清單通往客戶、匯率、報價、各主檔與設定。
- `DashboardSummarySection` 寬版並排摘要與 KPI；`DashboardKPITiles.columnTiles` 省略成本，`gridTiles` 則包含成本；`InsightsView.breakdownGrid` 有左右並排分支。
- `BLLayoutClass` 採雙向 regular 的全域分類且由根覆寫子欄環境；`DesignSystemSourceScanner.sizeClassViolations` 禁止其他檔案讀取 size class；`LayerBoundaryTests` 的根 store 白名單列出目前的根宿主。
- `OrderRegularColumnWidthTests` 斷言平分／固定欄寬；`OrientationLayoutTests` 與 `AppNavigator` 將根側邊欄等同 regular。這些測試不能原封不動沿用。
- `order-category-filter`、`order-filter-sheet` 主規格仍要求提交／清除篩選後選第一筆，`ui-test-support-layer` 仍將根 tabs/sidebar 對應全域 compact/regular；本提案同步三份 delta，避免新舊規格互斥。

Duo 前次實測報告記錄 Closed 466×678 pt、Open／Partial 951×669 pt，屬當次方向的量測，不是規格斷點；臨時證據可能已清除，apply 必須重現。App 最低支援版本維持 iOS 26；Duo 新 API 依實際 SDK 可用性設 availability 分支，不提高 deployment target。

## Goals / Non-Goals

**Goals:**
- In scope：五個分頁的根導覽；訂單、開團、更多的清單／詳情導覽；總覽與分析的統一排列；上述頁面及其既有表單、工具的閱讀寬度、安全區、焦點與操作連續性。
- 同一次場景存活期間保留所選分頁、目前目的地、搜尋篩選、批次選取、草稿與詳情內的狀態；修正 Duo 雙向詳情不同步、膠囊越界及 iPad 更多切頁崩潰。
- 系統自適應優先；每個分頁在自己的容器判斷內容是否放得下，保留原生返回、工具列與單層模態行為。
- 修訂與新行為衝突的規格、守門測試、UI helper 與文件，讓新契約有真正失敗的驗證。

**Non-Goals:**
- Out of scope：跨 App 重啟或跨場景狀態還原、新增多視窗功能、資料 schema／財務公式／網路服務變更、發版、commit／push。
- 不引入 ArrangementView，不做 hinge angle 驅動的姿勢特例，不新增裝置型號斷點表；不強制 Duo 展開後變根側邊欄。
- 不改名 RootFeature 為 AppFeature，不做全庫 rules 縮減、測試命名或單次 helper 內聯；這些仍屬既有 roadmap 後續。
- 不新增分頁自訂排序／隱藏功能、不變更主要目的地、篩選欄位或統計計算。不同工具間主動切換是否保留每個工具的歷史不擴充為多份快取；只保留目前選取工具跨根分頁與尺寸變化的狀態。

## Decisions

### 先切換根導覽並隔離舊功能入口

**Supersedes**: adaptive-navigation-continuity / 系統自適應根導覽與分頁容器（2026-10-25 初版，最後才切換預設根的安排）。

新增 `RootNavigationLayout`，只持有根 store、selectedTab 與各功能 scope。TabView 使用 sidebarAdaptable，iPad 初始偏好 tab bar；使用者切換側邊欄後，App 不因旋轉或分頁切換強制改回。五個目的地、既有側邊欄訂單徽章、分組與品牌入口以原生 API 保留，無對應能力時在原型報告列明差異，不自畫第二套根導覽。

實測取捨 (main 決策，iPad26.5／Xcode27.1 SDK27.1)：build412 的 TabSection 把五個 Tab 子項折為頂部「工作區／工具」兩個群組；build413 改為五個同層原生 Tab，AX／截圖確認五個 Root.tab.* 與徽章4，原生 More／sidebar XCTest probe2項通過。依前述原生能力差異條款，sidebar 採品牌 header 下平列五個目的地，不重造分組或複製 Tab。這是已量測的組合差異，不主張官方證明所有其他組合皆不可能。完整偏好與 N5 仍以1.5 gate為準。

最終由訂單、開團、更多各自持有 NavigationSplitView，根層只組合功能入口；總覽與分析保持各自 NavigationStack。Duo 沿用系統直向／橫向控制列與 overflow，不強制搬移清單欄控制項至詳情側邊列。

遷移採「先切根、再逐功能換入口、最後刪舊檔」：task 1.1 完成真實 TCA 原型，1.3 將新根設為預設。此時尚未分欄的開團與更多沿用既有完整 NavigationStack；訂單以 `OrdersLegacyNavigationView` 包裝既有 OrdersView，僅在這個暫時入口提供 compact 相容環境，以保留 OrdersView 的 sheet／alert 與 OrdersCompactView 的完整清單→詳情堆疊。這是所有裝置共用的過渡入口，不以硬體分流，也不把舊環境注入整個 TabView 或已遷移功能。

RootTabLayout／RootSidebarLayout 暫留可編譯檔案，但 1.3 起不再是執行入口，也不作為自動失敗回退。新的功能 split 絕不放進舊 RootSidebarLayout 的 content／detail。2.3 將新 OrdersView 掛到同一新根並移除訂單暫時入口；2.4／2.5 分別原地遷移開團／更多；3.1 只做舊檔、未使用 action 與環境橋接的清理，不再承擔首次啟用新根。

1.3–1.5 視為同一前置根遷移批。1.3 交付原生宿主、狀態保留與 Store 守門；1.4 與 1.5 在其已驗 primitive 上分別完成正式 helper 與 N1/N5 UI，兩者檔案不重疊可並行。1.3 同批撤除 RootFeature.sidebarTabSelected 與 MoreFeature.customerSelected 的清空繞行並遷移其測試；在 iPad 以實際 reducer／delegate 鏈驗證 More→設定→Orders→More，以及 More→客戶清單→點客戶→Orders→切根樣式→More。兩個流程都保留來源 path、輸入／清單狀態且無 assertion failure，且 1.4／1.5 全數通過才接受本批並允許 2.x 功能遷移；不是把 N5 延至最終回歸。若失敗就維持任務未完成並修正新容器組合，不能以清空 path、改用 ArrangementView、降低驗收或提高最低系統版本當作完成。原型不等於正式功能已通過全部驗收。

### 單一目的地與系統導覽的轉接契約

**Supersedes**: adaptive-navigation-continuity / 同一目的地狀態跨尺寸與分頁保留（2026-10-25 初版，未明列系統 selection／Back 與 StackState 的轉接驗收）。

技術設計沿用 TCA 的 path 作為每個功能唯一的目前目的地承載；根目的地 path 為空或只含目前詳情／工具，目的地內原有子導覽留給該功能。split detail 與 collapsed navigation scope 同一個元素及 action，相同 ID 的重複開啟保留元素識別與子狀態，不同 ID 的明確導航以單次 reducer 更新替換根目的地，不堆疊兄弟頁。

NavigationSplitView 不直接接受 StackState；必須建立功能自己的 View 轉接層，把原生清單選取／value-based NavigationLink、收合呈現與該 path 連接。選取 binding 的 getter 由目前 path 元素投影；setter 送出該功能的選取或返回意圖，由 reducer 操作 path，不能另存一份可獨立寫入的 entity ID。columnVisibility／preferredCompactColumn 等 View 呈現狀態允許局部持有，但不是領域選取來源。

| 原生或功能事件 | 唯一目的地狀態與畫面結果 |
| --- | --- |
| 清單點選新 ID | 驗證 ID 存在後替換 path 元素，清單高亮與詳情都由該元素投影 |
| 點選／深連結目前 ID | 重用現有元素，不丟失詳情內篩選與草稿 |
| 尺寸、姿勢或根 bar 改變 | 不寫入不同 ID，也不因欄位隱藏自動清空 path |
| 收合狀態使用原生 Back／邊緣返回至功能根清單 | 轉成同一功能的返回操作，清空目前根目的地；再次展開顯示提示 |
| 所選實體失效 | 經功能操作清除 path，顯示提示／清單，不改選鄰項 |

不把同一個根 detail 一面作為 split 的 detail、一面又推入 detail 欄內的第二個根堆疊。嵌套 NavigationStack 只服務目的地原有子階層，由宿主提供；push 目的地仍不自帶另一個 stack，不自畫 Back。

1.1 的原型必須使用實際 TCA Store／StackState 與 OrderDetailFeature 的狀態／action，不接受只有靜態畫面或兩份 mock selection 的容器演示。記錄原生 selection binding、path action、系統欄位回寫的事件順序與元素 identity，完成並排選取→同 ID 重開→不同 ID 替換→收合→原生返回→展開的 UI 操作與 reducer 斷言；另測只改尺寸時不得誤 pop。若原生回寫無法分辨返回與呈現轉場，先修正並驗證轉接模式，再使用到正式功能；不能以任意延遲忽略 nil 回寫或把第二份 ID 當作解法。Apple 的系統收合能力是容器行為依據，不是本 App 的 TCA 轉接已驗證之證明。

- Orders：2.1 先改既有搜尋／篩選與載入的選取語意，當批維持既有表示的同步與相同 ID 子狀態；2.2 再移除可獨立寫入的 regularDetail 與 selectedOrderID，收斂到 path 投影。所有舊 views 與跨功能測試同批遷移；不得新增第三份狀態或把舊存儲留至最終驗收。
- Campaigns：沿用 showDetail 入口，並排與單頁讀同一詳情元素，保留未收款過濾等詳情內狀態。
- More：Entry 區分 LookupKind；目前工具由 path 衍生，同一工具不重新初始化，明確選另一入口替換根目的地。客戶清單發送跨頁 delegate 後保留，訂單沿用 showOrders(customer:) 將客戶名稱放入 searchText。
- Root：切換分頁只更新 selectedTab，深連結經功能唯一入口，與點擊結果一致。
- sheet、alert 與草稿狀態放在功能容器，跨排列變化沿用原實例；焦點以欄位識別保留，續輸入仍寫回原欄位。尊重使用者主動收起鍵盤的動作。

### 明確選取與篩選失效規則

初次載入、重試與純刷新都不自動選第一筆；Orders、Campaigns、More 未選取時，展開顯示本地化提示，收合顯示清單。明確點擊／深連結是開啟來源。

訂單搜尋、狀態、日期、類別、付款篩選及清除篩選後，以同一過濾結果檢查目前 orderID：仍在結果中保留目的地及子狀態；不在則清除，不改選首筆。背景資料刷新不能將仍存在的目的地換成另一筆。刪除／合併讓目前 ID 不再存在時關閉該詳情，不展示舊資料；新增儲存本身不自動選第一筆，保留現有明確導航請求的意圖；使用者 2026-10-29 決定新增訂單存檔與合併完成都不開啟詳情 (兩者沒有明確導航請求)，合併讓目前詳情的訂單消失時清除該詳情。開團刪除也清除不存在的目的地；本次不改開團既有篩選語意為訂單的新規則。現況沒有獨立的訂單開團／客戶篩選欄位；客戶跨頁是設定搜尋文字，套用相同搜尋結果的選取規則，不新增 campaign/customer predicate。

### 統一總覽分析排列與彈性閱讀寬度

總覽順序固定為日期、本月摘要、營業額／成本／毛利率／進行中訂單 KPI、進行中開團、近期訂單。四張與二乘二是使用者明定的內容／排列，不是量測值；輔助字級 KPI 單欄。分析保持期間、走勢、類別、成本、開團毛利 (有資料才出現)、熱力圖的垂直順序。載入、失敗與空狀態沿用原行為，骨架需匹配最終排列。

新增不依賴 TCA／領域型別的 `BLReadableContentLayout`，由內容類型選擇閱讀寬度偏好；總覽、分析、訂單／開團詳情、匯率、報價、客戶、主檔、設定與新增／編輯表單逐一採用。窄容器扣除正常設計邊距後填滿，寬容器到上限後在自身安全內容區內置中；圖表可比文字／輸入更寬。上限是可驗證的設計參數，不能用裝置名稱切分。

不把整個 NavigationSplitView 或根 TabView 包進閱讀限寬；只限制欄內內容，不讓分欄丟失可用空間。一般留白與系統 inset 分開，SwiftUI 已處理的安全區不能再扣一次。連續捲動內容不因半摺整頁搬到另一半；只對必要互動元素採局部避讓。

### 彈性欄寬與局部環境判斷

訂單接近各半、開團約 1:2、更多入口約 300 pt 是使用者採納的初始偏好，屬未量測設計估計，不是硬門檻或固定驗收數字。以欄內長文字、工具列可操作性、輔助字級、半摺與視窗縮放量測確認或否定；失敗就放寬偏好或收合，不能縮小文字來維持比例。

各分頁優先交由 NavigationSplitView 與目前環境適配；水平尺寸分類用於橫向需求，垂直尺寸分類只處理高度需求。移除根注入的全域 blLayoutClass 與「只有雙 regular 才寬版」限制，允許 View／ViewModifier 讀取自己的環境。共用閱讀規則集中，但不再將全 App 鎖成同一個 compact／regular 狀態。缺少環境時使用可返回的單頁保守呈現，不推測裝置。

既有「iPhone compact／iPad regular」篩選規格改解釋為訂單清單自己的簡化／展開控制區：簡化區用整合篩選入口，足夠空間的控制區保留獨立類別等入口，既有功能不能消失。這個選擇不由根分頁列或側邊欄是否出現決定。

### 系統工具列與非對稱安全區

前景控制項尊重所在容器每一側的 safe area；不能假設側邊列永遠在右側，也不能用前次實測 84 pt 寫死 padding。`OrdersCompactListView.chipStrip` 可橫向捲動，但顯示與觸控範圍不得侵入系統列。一般尺寸、輔助字級與改變保留區時都驗證。

標題與工具列掛在所屬清單／詳情欄。並排時訂單搜尋維持 inline 標題，不因結束搜尋留下空白；收合的窄版清單維持大標題，搜尋中由系統收起標題，收鍵盤或清除文字時仍在搜尋中，關閉搜尋後回到原位 (4.24 實測)；多選筆數在所屬清單可見，不重複顯示。保留原生 Back、手勢與 Done；提供圖示及名稱、使用語意 placement 與群組，常用操作保有可達路徑。適合的工具列更多動作在支援系統整合原生 overflow，狀態選單仍是具名狀態操作；不變更「更多」分頁。新 API 使用前依 Context7 與 Xcode DocumentationSearch 確認 availability，iOS 26 保留等價可達操作。

### 分層驗證與守門遷移

狀態測試驗證同一目的地與子狀態的保留，UI 驗證畫面、觸控、返回與工具列，snapshot 只驗證排列。不能用 reducer 綠燈或截圖存在取代互動驗收。

撤銷 size class 僅允許單檔的舊政策及其專屬斷言；保留掃描器的其他規則和詞法覆蓋。用跨功能測試驗證局部環境不被根覆寫，並保留檢查裝置型號／全域螢幕布局捷徑的針對性檢查。根 store 白名單在遷移中精確列出新舊宿主，最後收斂為 RootView 與 RootNavigationLayout；不刪整個分層守門。

測試隨契約變更的批次遷移，不留到完整回歸才補編譯。1.3 更新 RootFeatureSidebarTests 與 RootFeatureOrderFiltersTests 的 path 保留斷言；2.1 更新首載／篩選／刪除不首選的 feature 與 Root 測試；2.2 更新 Orders 測試、RootFeatureDetailNavigationTests、RootFeatureOrderFiltersTests、RootFeatureSharedOrdersTests、RootFeatureLoadRequestsTests 及 CampaignIntegrationTests 的舊欄位存取。實作前以 rg 盤點所有 regularDetail、selectedOrderID、selectFirstFilteredOrder 的讀寫／斷言，記錄逐檔擁有者與遷移批次；此清單是已確認入口，不是封閉白名單。2.4 等到 2.2 完成再改 CampaignIntegrationTests，避免平行競寫。

1.4 的正式 UI 導航 helper 分別辨識根目的地入口與所屬功能的單頁／分欄，不能由 app.tabBars 存在就推論所有內容 compact。iPad 浮動列實測無法由 app.tabBars 類型查到，改用已驗語意 IDs；Root.sidebar 現為 header mode marker，不代表整個欄位框線。1.5 root／orders smoke 分檔，後續2.3／2.5同批遷移各自受 split 改變的 scope／Back 斷言。1.4 另依使用者決定納入鍵盤前置 helper：輸入 helper 以目標欄位本身的鍵盤焦點判斷聚焦並先把游標移到尾端，捲動 helper 新增「完整落在容器垂直可見區」的輕拖 (位置簽章不變即停)，訂單表單的實付金額改用它，AppNavigator 新增 rootLayout 供 regular 專屬案例宣告範圍。PlatformScope 改依訂單前景判斷後，訂單篩選與 regular 欄位測試的既有呼叫端在同批先切到訂單分頁再判斷，不延到 3.2，維持每批對應測試通過。Adaptive Split 原型在遷移期間只於 DEBUG 編譯，3.1 隨舊宿主一併移除。欄寬斷言改驗證前景元素位於可見可操作區、清單與詳情不互蓋且功能完整，移除 320 pt／精確對半的硬斷言。

### 測試裝置與 iPadOS 27 適應

使用者 2026-10-27 決定：除 Duo 外，單元與 UI 測試改在實體機執行。iPhone 12 (iOS 26.7.2) 涵蓋 App 最低支援版本 iOS 26；iPad 只用 iPad Air 5 (iPadOS 27.2)，測試依實際畫面適應 iOS 27，不另以 iOS 26 iPad 驗收。Duo 仍用 iOS 27.1 模擬器以 UI Automation 取證。App deployment target 維持 iOS 26。

Supersedes：原「iPad UI 驗收在 iOS 26.5 模擬器、斷開硬體鍵盤並關閉 Device Hub」與 task 4.2「不以新系統代替最低版本驗收」中 iPad 的部分，由本段取代；iPhone 的最低版本驗收不變，改由 iPhone 12 實機執行。

單元測試的例外 (使用者 2026-10-28 決定)：讀 repo 原始碼或資源檔的守門測試 (實機無法存取主機檔案系統) 與 snapshot 測試 (基準錄自 iOS 26.5 模擬器淺色模式) 在 iPhone 17 iOS 26.5 模擬器執行，跑前鎖淺色外觀；其餘單元測試仍在 iPhone 12。守門測試執行時讀原始碼，執行期間不派工改檔。

已實測的 iPadOS 27 差異 (iPad Air 5，2026-10-27，證據見驗收記錄)：

- 直向時根側邊欄是覆蓋內容的 overlay，在 overlay 點選目的地後系統收起側邊欄、回到分頁列；以 Xcode DocumentationSearch 對照 sidebarAdaptable、defaultAdaptableTabBarPlacement、TabViewCustomization，未找到直向固定側邊欄的 API。N1／N5 的側邊欄偏好保留改在橫向 (側邊欄固定在旁) 驗證；直向驗 overlay 收起後目的地、訂單徽章與功能狀態正確。
- 數字鍵盤是貼在欄位旁的浮動小型面板，沒有 App 鍵盤工具列的完成鍵；在欄位點兩下換成完整軟體鍵盤後才有完成鍵 (使用者手動確認)。KeyboardDismissTests 依實際鍵盤幾何判斷浮動面板，走「點兩下換完整鍵盤再按完成鍵」的使用者路徑，不 skip。
- 點靠右對齊的金額欄位時游標落在原值之前，直接輸入會接在原值前 (輸入 123 得到 1230)。共用輸入 helper 在刪除前先把游標移到尾端。此行為對真人輸入的影響不在本 change 範圍；使用者決定另開 change 修正所有輸入框 (數字欄位聚焦時全選、文字欄位聚焦時游標移到尾端)。
- 主檔清單以 destructive 角色的滑動刪除鈕刪除、寫入失敗後，iPadOS 27 不再顯示該列 (資料與筆數未變)；使用者 2026-10-29 原決定另開 change 修正，2026-10-30 改為併入本 change，見「主檔滑動刪除不交由系統移除列」。

實機前置：開啟開發者設定的 UI 自動化、未接任何鍵盤、裝置解鎖；KeyboardDismissTests 兩條通過才開始 iPad 回歸；轉向案例在成功與失敗路徑都還原直向並等方向確立。只存在 regular 版面的案例以 AppNavigator 的 rootLayout 依實際畫面宣告範圍 (側邊欄或頂部分頁列為 regular，底部分頁列為 compact)，不判斷裝置類型，也不因元素缺席而 skip。

範圍內：測試裝置、UI 測試 helper 與前置規則的調整。規則文件 (apps/ios/CLAUDE.md、README 與 ios-design-system／ios-navigation／ios-ui-tests) 於 1.4 依本 design 寫成最終契約，2.x 與 3.1 才成立的部分 (各功能自管分欄、舊根宿主與 BLLayoutClass 刪除、根 store 白名單收斂) 以「遷移中」子項標出，3.1 只刪子項並更新 README 目錄結構，避免文件在遷移期間與程式碼矛盾。範圍外：產品端為 iPadOS 27 浮動數字面板或金額欄游標新增的行為。

### 主檔滑動刪除不交由系統移除列

4.2 實機回歸時 iPad Air 5 (iPadOS 27.2) 的 `LookupManagementTests.testDeleteItem_確認刪除商品類別_清單移除該名稱` App 閃退 (10/28 同測試通過，本 change 把主檔管理移進「更多」分欄後出現)。主對話在 iPadOS 27.0 iPad Air 11 模擬器重現，執行期記錄為 `NSInternalInconsistencyException`：清單更新前已只剩 3 列，資料再刪 1 筆，數量不符。成因是 `LookupItemList` 的滑動刪除鈕 `Button(role: .destructive)` 被點下時系統先移除列；確認刪除成功後資料再刪一次就閃退，寫入失敗時列則不會回來，兩者同一根因。

決策：滑動刪除鈕改用一般 `Button` 並以 `.tint(.blRed)` 維持紅色，保留標籤與 identifier；破壞性語意由既有的確認對話框承擔。內容選單 (長按) 的刪除鈕維持 destructive 角色，4.5 一併實測。若改角色後 iPadOS 27 仍移除列，改採替代方案 (刪除失敗後強制清單依資料重建) 並在 verification 記錄實測結果；移除滑動刪除違反 `lookup-management`「iOS swipe-to-delete is retained」，不採用。

Supersedes：parked change `lookup-swipe-delete-row-retention` 的修正 (其 design「滑動刪除鈕改為一般按鈕加紅色著色」與 tasks 1.1、1.2) 由本段與 task 4.5 取代，決策來源為使用者 2026-10-30。該 change 保持 parked，是否刪除由使用者決定。

範圍內：`LookupItemList` 滑動刪除鈕的角色與著色、`LookupManagementTests` 刪除相關案例。範圍外：確認與寫入流程、改名與編輯的滑動動作、其他清單。

### 主檔刪除寫入失敗提示不因確認框關閉而遺失

4.2 第 3 次實機回歸 iPad Air 5 (iPadOS 27.2) 的 `LookupManagementTests.testRequestDeletion_長按選單刪除寫入失敗_項目保留且筆數不變` 失敗：確認刪除後「操作失敗」提示未出現，列與筆數正確保留。同測試在第 2 次與重跑 5 次皆通過。主對話 2026-10-31 在 iPadOS 27.0 iPad Air 11 (M4) 模擬器以 ui-automation 重現：滑動與長按選單兩條路徑都會間歇發生，發生後再點刪除鈕連確認框都不出現，要離開畫面才恢復。

成因推測 (主對話，未驗證)：`LookupManagementFeature` 收到 `.deleteResponse(.failure)` 時直接把 `destination` 設為 `.writeFailure(.delete)`。確認框與失敗提示共用同一個 `.alert` 修飾符；注入的寫入失敗幾乎立即回來，SwiftUI 尚未處理確認框關閉造成的 nil 時 `destination` 已再度非 nil，SwiftUI 視為一直在呈現而沒有呈現新提示，狀態卡在非 nil，之後的刪除請求只改狀態、不觸發呈現。`Destination.State` 不可識別，TCA 呈現綁定的身分比對不能區分前後兩個提示。開團 `CampaignPresentationQueue` 與訂單 `OrdersPresentationQueue` 的註解記載同一系統行為 (sheet 關閉動畫期間設進目的地的 alert 會被丟棄，狀態仍宣稱正在顯示)，但兩者只保護 sheet 關閉，確認框接寫入失敗通知同樣直接設定目的地。

實驗結果 (主對話，2026-10-31，iPadOS 27.0 iPad Air 11 (M4) 模擬器)：
- 暫時診斷 (`[BLDIAG-4.6]` 輸出) 顯示：成功時確認框關閉後 SwiftUI 對綁定回寫 nil 兩次，失敗回應在第二次之後才到；遺失時失敗回應落在兩次回寫之間，之後綁定不再回寫、提示不呈現，`destination` 卡在提示狀態，之後設定確認框也不觸發呈現。成因確認。
- 實驗修法：失敗提示改用獨立的 `@Presents` 呈現狀態與另一個 `.alert` 修飾符。滑動與長按選單各 10 次共 20 次，失敗提示 20 次皆出現，其中 18 次的失敗回應落在原本會遺失的時間窗內，且之後都能再開確認框。實驗碼已還原，正式修正另行實作。
- 開團以 `-BLUITestCampaignWriteFailure` 實測：詳情「更多 > 刪除開團」確認後第 2 次即遺失「操作失敗」，之後再按刪除不出現確認框，同一缺陷。訂單沒有寫入失敗的注入旗標，未實測。iPhone 17 iOS 26.5 模擬器點分頁列無法切換畫面，iOS 26 未實測；iPhone 12 實機 iOS 26.7.2 歷次回歸的主檔刪除失敗案例皆通過。

決策 (主對話)：實作前先以實驗確認成因 (記錄 `destination` 的變化與 SwiftUI 回寫關閉的先後)，再依成因修正。修正後失敗提示在確認框關閉後一定呈現，關閉提示後可以再次開啟刪除確認框；列與筆數的行為維持「主檔滑動刪除不交由系統移除列」。採用實驗驗證的做法：寫入失敗通知與確認框、表單分開，使用獨立的 `@Presents` 呈現狀態與各自的 `.alert` 修飾符；表單關閉中到達的通知沿用既有暫存機制，關閉後放進獨立通知狀態。主檔管理的新增、刪除、改名、付款方式更正四種寫入失敗通知一律改走獨立狀態；開團 `CampaignPresentationFeature` 的 `noticeRequested` 通知改走獨立狀態，`CampaignPresentationQueue` 的暫存規則不變。不採用固定秒數延遲，因為時序依裝置與系統版本而異，無法證明一定足夠。使用者 2026-10-31 決定「先實測，有重現才併入」：主檔管理與開團已重現而併入；訂單的確認刪除接寫入失敗通知機制相同但無法實測，記為未驗證風險，不在本 change 修改。

範圍內：主檔管理寫入失敗通知與開團通知的呈現狀態，及其 reducer、View、單元與 UI 測試。範圍外：寫入服務、確認框文字、訂單通知 (未驗證風險)、其他功能的提示。

### regular 訂單搜尋排除目前訂單時詳情欄必須清空

4.2 第 3 次實機回歸 iPad Air 5 的 `OrderRegularColumnScopeTests.testRegularColumns_搜尋無符合訂單_詳情只顯示空狀態` 失敗：輸入 `ZZZ-NO-SUCH-ORDER` 後清單已顯示 0 筆與「沒有符合條件的訂單」，詳情欄 10 秒內仍顯示 `UITEST-MRG-001`，錄影逐格未見詳情清空。同測試第 2 次與重跑 5 次皆通過 (實機 7 次失敗 1 次)；模擬器以注音輸入未重現。

現況：`OrdersFeature` 以 `.onChange(of: \.list.filterConditions)` 呼叫 `reconcileDetailPathWithFilteredOrders()`，排除目前訂單時清除詳情，reducer 單元測試已涵蓋。詳情欄只在 `path` 末端有可顯示訂單時呈現；重新推入詳情只會經由 `OrdersRegularListContent.selection` 的 setter 送出 `detailSelectionChanged`。成因尚未確定，可能是清除未觸發，也可能是清除後清單選取又送回舊識別碼。

決策 (主對話)：先在實機加暫時診斷 (只在 DEBUG 記錄 `searchTextChanged`、清除與 `detailSelectionChanged` 的先後與值) 重現並找出成因，記錄於驗收紀錄後再修正，診斷碼在任務完成前移除。修正須符合「Order filtering preserves only a matching destination」：搜尋排除目前訂單時詳情欄清空並維持空選取，不由清單選取回寫恢復。若實機重複 20 次仍無法重現，記錄已排除的成因與嘗試，回報使用者決定，不憑推測修改產品碼。

範圍內：訂單 regular 版面的搜尋、清單選取綁定與詳情清除。範圍外：compact 版面、其他篩選類型的呈現差異 (除非診斷顯示同一成因)、開團與更多的選取。

成因 (主對話以 iPad Air 5 實機診斷確認，2026-10-31)：清除確有執行，清單選取也沒有回寫。失敗時的軌跡 顯示，第一個字 `Z` 觸發的 `.onChange` 執行中，`OrdersView` 與 `OrdersRegularDetailColumn` 的 `body` 被同步重算並讀到舊 `path`，reducer 隨後才清空，之後兩個畫面再也沒有重算。TCA 1.26.2 的 `RootCore._send` 在狀態副本上執行 reducer、結束才寫回；巢狀 `@ObservableState` 的變更通知在執行中送出，寫回時根狀態 `_$id` 不變，`Store` 不再通知。`.searchable` 的文字綁定有時在畫面更新中送出 action，SwiftUI 收到通知後同步重算，讀到尚未寫回的狀態。

修法 (主對話決定，codex-impl 實作)：篩選條件改變且目前詳情被排除時，`.onChange` 回傳 `.run` 送 `filterConditionsChanged`，下一個 action 才清空 `path`，讓清空的通知發生在畫面更新之外。詳情仍命中或沒有詳情時不送 action；Root 的 `applyFilterNavigation` 不經 `.onChange`，維持同步清空。代價是被排除的訂單在詳情欄多留一個 run loop。修正後含診斷版本在 iPad Air 5 重複 20 次全過 (修正前同診斷版第 1 至 2 次即失敗)，移除診斷後全類別與目標測試重複 10 次全過。

交叉審查當時記錄為未處理：`refreshDateContext` 只更新日期脈絡、不檢查 `path`，跨日、跨月或回到前景時「本月」等日期篩選若排除目前詳情，詳情不會清空。使用者 2026-11-03 決定併入本 change，由 4.19 處理 (見「verify 後修正」)。

### Duo 摺展時主檔表單草稿必須保留

4.3 的 Duo iOS 27.1 模擬器驗證 (2026-11-01) 發現：Closed 把「服飾」改成「服飾Duo」且欄位聚焦，切到 Open 後重新命名表單仍只有一份，但值回到「服飾」、焦點消失；Open 打成「服飾Duo」再摺回 Closed 也一樣 (2/2 重現)。同一輪的新增訂單與開團編輯草稿、焦點都保留。

現況：`LookupNameEditorSheet` 的 `draftName` 與捨棄確認開關都是 sheet 內的 `@State`；`PaymentMethodEditorSheet` (Shared/DesignSystem) 的名稱與三個分類旗標草稿也是 `@State`。`LookupRenameFormFeature`、`LookupAddFormFeature`、`PaymentMethodEditFormFeature` 的 State 只有原始名稱、旗標或 `hasClassification`。訂單與開團編輯的欄位直接綁定 store (`$store.draft.customerName`、`$store.draftName`)。

成因推測 (主對話讀碼，未以診斷確認)：呈現表單的 `destination` 摺展後仍存在，所以 sheet 重新呈現，但表單 View 被重建，`@State` 回到 `initialName`、焦點跟著消失。主檔管理位在「更多」分欄的詳情欄，收合與並排切換時該欄內容可能整個重建；訂單新增與開團編輯的呈現位置不同，或草稿不靠 View 狀態，所以不受影響。

決策 (使用者 2026-11-01 併入本 change；修正方向由主對話提出)：主檔改名、主檔新增與付款方式編輯三種表單的草稿 (名稱與付款方式分類旗標) 改由對應的 TCA 表單 State 持有，View 綁定 store；dirty 判斷與捨棄確認的呈現狀態一併移入 State，摺展後確認框仍保留。`PaymentMethodEditorSheet` 屬 DesignSystem，不依賴 TCA：改為由呼叫端傳入草稿綁定，主檔管理綁定 feature State；`OptionPickerSheet` 的呼叫端維持原行為與原狀態來源。實作先以暫時診斷 (只在 DEBUG) 確認摺展時表單 View 是否重建，再決定焦點保留方式：草稿移入 State 後焦點仍消失時，焦點欄位也由 State 持有並以 `bind` 同步，不以重新彈出鍵盤代替使用者主動收起的鍵盤。

診斷 (主對話，2026-11-02，`BLDIAG-4.8`)：摺展時 `LookupManagementView` 沒有重建，表單 sheet 卻被系統關掉再重新呈現兩次，草稿移入 State 後草稿與焦點都已保留。但捨棄確認開著時摺展，第一個重新呈現的 sheet 實例把確認框綁定寫回 false，畫面上留下屬於舊呈現的確認框；按「捨棄變更」或「繼續編輯」都不會呼叫任何按鈕動作 (日誌沒有任何輸出)，確認框關閉後表單與草稿仍在。訂單 (`OrdersView`) 與開團 (`CampaignView`) 的表單 sheet 掛在 `NavigationSplitView` 那一層，摺展時不受影響；主檔表單由詳情欄內的 `LookupManagementView` 呈現，詳情欄收合或展開時被重新呈現。

決策補充 (使用者 2026-11-02)：主檔管理的表單 sheet 與提示 (確認框、寫入失敗通知) 改由 `MoreView` 的分欄層呈現，與訂單、開團一致，`LookupManagementView` 不再自行呈現；呈現狀態仍在 `LookupManagementFeature` 的 `destination` 與通知狀態，切換工具或沒有主檔工具時不呈現，且不改變 `NavigationSplitView` 的識別。草稿、焦點與捨棄確認維持由表單 feature State 持有，取消與捨棄由 reducer 關閉。

範圍內：主檔改名、新增、付款方式編輯表單的草稿、dirty、捨棄確認與焦點；主檔管理表單與提示的呈現位置 (`MoreView`、`LookupManagementView`)；對應 reducer、View、`PaymentMethodEditorSheet` 介面與其呼叫端。範圍外：寫入服務與驗證規則、`OptionPickerSheet` 在訂單表單中的草稿保留 (同一元件但未實測，記為未驗證風險)、其他工具頁的呈現位置。

### Duo 摺疊後訂單詳情選單間歇消失

4.3 的 Duo 驗證 (2026-11-01)：訂單詳情 Mika `BL-2604-017`，Open 點「隱藏側邊欄」→ Partial (仍收起、017) → Closed 後詳情 017 正確，但 `orders.detail.statusMenuButton` 與 `orders.detail.moreButton` 消失，右側只剩空白膠囊。同序列再跑兩次未重現 (其中一次 Partial 步驟未截圖確認)；直接 Open → Closed 正常。任務 1.1 曾記錄同一現象 (Closed 空白膠囊、兩個選單 identifier 缺失)，當時改用候選 2 後 Duo 驗證通過，本次在收起側邊欄的序列再現。

現況：`OrderDetailView` 以 `.toolbar` 放入 `OrderDetailToolbarContent`，內含兩個 `.primaryAction` 的 `ToolbarItem` (狀態選單、更多選單)。成因未確定，可能與收合時詳情欄的工具列重新掛載、側邊欄可見度變化或摺展中途的 View 更新有關。

決策 (使用者 2026-11-01 併入本 change，先追查成因；驗收方式由主對話提出)：先在 Duo 重複「Open 收起側邊欄 → Partial → Closed」與直接 Open → Closed 的對照序列至少 20 次估計重現率，加只在 DEBUG 編譯的暫時診斷 (詳情 View 與工具列內容的出現／消失、側邊欄可見度、path 與 store 識別) 找出成因並寫入驗證紀錄，再依成因修正。若 20 次仍無法重現，記錄已排除的成因與嘗試並回報使用者決定，不憑推測修改產品碼。姿勢切換只能在 Device Hub 以 computer use 操作，需要使用者在電腦前核准授權。

範圍內：訂單詳情工具列在摺展與側邊欄切換時的呈現，及其 reducer、View 與 UI 驗證。範圍外：開團與更多的工具列 (除非診斷顯示同一成因)、iPad 與一般 iPhone 的工具列行為改動。

### 4.4 量測發現的版面缺陷

2026-11-02 在 iPad Air 11 iOS 27.0 模擬器量測 (證據與數值見 verification「任務4.4：iPad 閱讀寬度與欄寬量測」)：

- 閱讀上限在 `ScrollView` 頁面成立：文字 640、表單 680、圖表 840 在寬區限寬並置中於可見區，窄區填滿，輔助字級隨字級放大且不截斷。這三個值由候選值轉為已量測確認的設計參數。
- 欄寬 (使用者 2026-11-02 決定)：訂單與開團清單欄維持系統預設 (實測 320 pt)，「訂單接近各半、開團約 1:2」的初始偏好由量測否定；「更多」入口欄實測 300 pt，與偏好相符。輔助字級時清單欄擁擠以欄內換行接受。
- 使用者決定併入本 change 修正的三個缺陷：
  - 分欄清單選取列文字對比不足 (4.10)：訂單、開團的列以自訂 `listRowBackground` 畫卡片，系統選取仍把主要文字改成高對比前景，造成白字疊白卡或淺底；「更多」入口欄偶見黑底深色字。修正先查證系統選取對前景樣式的影響並重現，選取仍由系統 `List(selection:)` 呈現並保留 `.isSelected`。
  - `blReadableScrollContent` 在 `List`／`Form` 遇不對稱水平安全區時不置中也不限寬 (4.11)：量到的寬度已扣安全區，但 `List`／`Form` 的 `contentMargins` 從容器原點起算、不疊加安全區，詳情欄延伸到左側欄底下時內容偏左並滑入左欄。`ScrollView` 會疊加安全區，不受影響。修正後兩類容器的內容都在安全區內置中，原「量測扣安全區會扣兩次」的結論只對 `ScrollView` 成立。
  - 報價輸入列在輔助字級標籤被擠成一字寬並裁切 (4.12)：橫排的「標籤 + 固定寬輸入框 + 單位」在輔助字級改為堆疊，標準字級不變。
- 使用者 2026-11-02 再決定併入的兩個輔助字級缺陷 (Duo AX5 量測)：
  - 訂單詳情標頭在窄寬度輔助字級不換行，「日期・幣別」與下方卡片進入右側系統列與工具列底下 (4.13)：標頭改為可換行或堆疊，詳情內容維持在安全內容區內，標準字級不變。
  - 總覽 hero 目標進度在窄寬度輔助字級把金額斷在數字中間 (4.14)：輔助字級時進度條與文字上下堆疊，標準字級不變。
  - 訂單編輯商品列在輔助字級把「數量」「單價」標籤擠成一字寬 (4.15，主對話量測後使用者決定併入)：輔助字級時 Stepper 與單價列上下堆疊，標準字級不變。
  - 分析頁在窄寬度輔助字級：走勢長條圖 x 軸標籤重疊、類別排行金額在數字中間斷行 (4.16，使用者決定併入)：軸標依放大後的寬度抽樣，排行列改為可換行排列，標準字級不變。
  - 訂單詳情成本拆解圖例與商品明細的金額在窄寬度輔助字級斷在數字中間 (4.17，修正版重量後使用者決定併入)：輔助字級時名稱與金額改為上下兩列，金額取得整列寬度、不被卡片裁切，標準字級不變 (4.16 類別排行同樣改為上下排列，使用者 2026-11-02 依 codex-impl 審查決定)。
  - 以上各項的排列切換都不得以條件分支建立不同的 View (切換字級時保留結構識別)。
- 不處理 (使用者決定)：根側邊欄標頭「BuyLedger」在 AX5 斷字；英文時約 320 pt 的分欄訂單清單欄標題「Orders」在 Duo 縮放寬度被截成「…」或「Orde…」(Duo 的清單欄多一顆系統分欄切換鈕，iPad 與 Duo Open 完整，中文不截斷)，記為已知限制。
- 修正版的連續縮放 (Duo「Enter Resize Mode」416、740、1280 寬) 在收合與分欄間即時切換，目前訂單詳情與選取不遺失；4.11 修正後 `List`／`Form` 工具頁的閱讀上限也在 iPad 量測成立 (`ReadableWidthUITests`)。模擬器沒有 Duo 左右並排與 iPad 連續縮放的可用入口 (iPad 的 Resize Mode 為灰色，視窗 App 模式會讓 UI Automation 失效)，這兩項以固定寬度量測加 Duo 縮放涵蓋，記為未驗證情境。
- 範圍內：上述三處 View、共用捲動閱讀寬度修飾與其測試、規則文件閱讀寬度條目。範圍外：清單欄寬比例、根側邊欄標頭、其他工具頁輸入列 (4.12 只盤點並回報；訂單編輯商品列量測後併入為 4.15)。範圍內另含 4.13 訂單詳情標頭與成本圓餅圖 (`BLDonutChart`)、4.14 總覽 hero 進度列、4.15 訂單編輯商品列、4.16 分析頁走勢圖軸標與類別排行與 4.17 訂單詳情成本圖例與商品明細金額。

## 2026-10-26 審查後修訂

來源：使用者要求依前輪 codex-impl、gemini-impl 審查修訂，再交同兩方複審。產品決策維持原討論結果；遷移順序與工作分配由 Codex 主對話決定。當時尚未實作原型或應用程式。

| 前輪已核實的問題 | 處理方式 |
| --- | --- |
| 新功能 split 可能被尚未替換的舊根 split 包住 | 新根在 1.3 成為預設；未遷移訂單先用 `OrdersLegacyNavigationView` 保留原有完整單頁導覽與表單，2.3 原子替換為新 split；舊 `RootSidebarLayout` 不再是執行入口 |
| 刪舊選取欄位時跨功能測試沒有明確擁有者 | 1.3 改 More path 保留測試；2.1 先改首載、搜尋、篩選、失效行為及其斷言；2.2 收斂型別並同步遷移 Orders、Root 與 `CampaignIntegrationTests`；2.4、2.5 等 2.2 交還測試所有權 |
| 規格承諾了不存在的獨立開團、客戶篩選 | 移除獨立 campaign、customer predicate；客戶跨頁明確寫成沿用 `showOrders(customer:)` 設定 `searchText`，再按搜尋結果判斷選取有效性 |
| 靜態容器原型不足以證明 TCA path 與原生返回的轉接 | 1.1 明列實際 TCA `Store`、`StackState`、`OrderDetailFeature` 的 UI 與 reducer 驗證；新增事件對照表、同 ID 元素保留、原生 Back 後清空、resize 不誤 pop；1.3 另以正式 More reducer 與 delegate 鏈驗兩條返回流程 |

前輪 Gemini 的「`NavigationSplitView` 一概無法原生返回」未獲證實，未採為既定事實；這輪要求實測具體轉接，不改用自製返回鍵。Toolbar availability、精確 root-host 白名單仍按原有契約；補上 iPad 鍵盤與 XCUITest 轉向的既有環境檢核引用。

任務沿革：當時沒有已完成任務。初版 1.3 的非預設宿主安排由新版 1.3 的預設切換取代；初版 2.1 分拆為新版 2.1 的行為切片與 2.2 的狀態收斂。初版 2.2–2.6 順移為 2.3–2.7；初版 3.1 的首次切根與撤除清空繞行移入新版 1.3，3.1 保留舊碼清理。依賴及所有權隨之更新，未把取消的舊安排勾為完成。

這輪修改 proposal、design、tasks 與 navigation-path-integrity delta，其餘 capability delta 維持。修訂後共 16 項待辦。靜態分析沒有 Critical 與 Warning，保留既有分層規則的 6 項補例 Suggestion；`spectra validate` 通過。這些結果只證明提案格式與靜態一致性，正式原型及裝置互動當時仍待執行。

## verify 後修正

`/spectra-verify` 2026-11-03 指出的落差，主對話讀碼與截圖確認後，使用者決定處理方式：

- 開團選取列高亮 (4.18)：開團列沒有畫選取狀態，觸控操作下選取卡與未選取卡同為白底；訂單列已有淺藍底。比照訂單列呈現，選取來源仍是 `CampaignFeature.State.path` 投影。
- 日期脈絡刷新排除目前詳情 (4.19)：Root 的前景與時間變更路徑在刷新後檢查目前詳情。`applyFilterNavigation` 內部也會刷新日期脈絡，須維持先套新篩選再檢查，避免以舊條件清掉詳情。這條路徑由場景階段與時間變更事件觸發，不經 `.searchable` 綁定，因此不沿用 4.7 的延後清空，在同一次更新內清除。只有這次刷新才造成排除時清空：刷新前已被排除的詳情 (既有行為：改狀態到篩選外時保留詳情) 維持原樣，否則每次回到前景都會清掉它 (主對話讀碼發現，既有測試 `writes_詳情改成篩選外狀態_保留path並更新內容` 鎖定此行為)。
- 情境測試 (4.20)：補齊沒有測試也沒有實測的 6 條情境。批次操作的真實視窗拖曳在模擬器無法執行，以守門掃描與 UI 量測涵蓋。
- 範圍內：上述開團列、訂單日期脈絡、情境測試與對應規則文件。範圍外：開團詳情工具列的 4.9 繞過做法、`candidateMaximumWidth` 改名與其他 verify 建議項目；數字欄游標停在預設值 0 之前留給 parked change `input-focus-selection`。
- 未驗證情境 (使用者決定不補或工具限制)：iPad 可縮放視窗、Duo 左右 Split View、批次操作的真實視窗拖曳、多選筆數在收合與並排間的切換 (使用者決定不驗；兩種版面各自有 UI 測試)、最終程式碼的實機完整 UI 回歸 (使用者決定回歸只在模擬器跑；iPhone 12 實機單元測試與 `QuoteTests` 除外)。
- 已知限制 (主對話裁定，`codex exec` 審查指出)：清單的 `view(.task)`／`retryTapped` 會自行更新日期脈絡且不檢查詳情，若它比 Root 的前景與時間變更事件先拿到新日期，之後 Root 刷新會把該詳情視為早已排除而保留。需要日期跨界發生在兩個事件之間的極短時間內且清單剛好重新出現，後果是詳情多留到使用者下次操作篩選；不為此改動清單載入流程。使用者 2026-11-03 決定維持程式不改，在 spec 加例外 (4.26)。

### verify 第二輪修正

4.21 後的 `/spectra-verify`、`/spectra-review` 指出的項目，主對話核對程式碼與回歸結果後，使用者決定處理方式：

- 清除篩選鈕 (4.22)：最大輔助字級時訂單清單標頭放進 `List` 列，`clearFiltersButton` 沒有指定按鈕樣式，點列內空白處可能送出 `clearFiltersTapped` (審查者讀碼判斷，修正前先以 UI 測試確認)。改 `.borderless`，與同區已指定樣式的按鈕一致且保留強調色。
- 清單篩選 sheet 宿主 (4.23)：依「sheet、alert 與草稿狀態放在功能容器」，篩選 sheet 與類別選擇器移到 `OrdersView` 的分欄層，比照編輯表單。呈現狀態仍在 `OrderListFeature` 的 `destination`。
- 窄版標題 (4.24)：`OrdersCompactView` 的大標題與當時「訂單搜尋維持 inline 標題」的文字不符。主對話在 iPhone 17 iOS 26.5 模擬器實測未重現留白或下推，依任務約定不改程式，把 inline 規則範圍縮小到並排清單欄，並補窄版 UI 測試。
- 驗證缺口 (4.25)：Root 回到前景與時間變更清空詳情的串接、清單自行刷新日期的例外、訂單與開團選取列的 `isSelected`、篩選 sheet 清除鈕停用。
- 全裝置略過的 UI 測試 (4.26)：`testSelectionSurvivesLayoutChange` 與 `CampaignFlowTests.testBackTapped` 在 iPhone 17 iOS 26.5、iPad Air 11 iOS 27.0 模擬器都依版面略過。測試碼保留，對應情境標為人工情境，不改用未指定的模擬器。
- 範圍內：上述訂單清單欄、sheet 宿主、窄版標題、測試與文件。範圍外 (列為後續)：主檔取消表單時的暫存通知、`List` 列數不固定的效能量測、未使用的 `blReadableContent`、只供預覽的舊初始化簽章、開團詳情工具列在 Duo 收合 10 次的確認、其他過時規則與紀錄。
- 未驗證情境 (使用者 2026-11-04 接受 Duo 相關情境維持未驗證)：Duo Open 開著類別選擇器摺到 Closed 的實際行為 (Device Hub 操作權限目前不可用)；`The same order survives both directions of a resize`、`Split collapse preserves a native return path`、`Explicit back differs from automatic collapse` 的開團部分、`Unfolding preserves the root destination`、`Partial folding preserves continuous reading` 在最終程式碼上未驗證。

## Implementation Contract

**介面與狀態：** `RootFeature.State.selectedTab` 仍是根選取來源；Orders／Campaigns／More 的目前目的地各有唯一可 scope 的 TCA path 元素，列表點擊、深連結、返回及資料失效皆經功能自己的方法。不得以同步兩個獨立 detail state 代替單一來源。既有 Service、model、識別碼語意及商業計算不變。

**失敗行為：** 未選取顯示選擇提示；ID 已刪除清除目的地；載入失敗保留現有失敗／重試 UI，不用假資料補畫面。仍有崩潰、越界或狀態遺失就不勾選驗收 task。環境故障記錄工具、OS、重現與未驗證情境，不以 skip 掩蓋產品失敗。

**驗收矩陣：**

| 編號 | 動作與觀察 |
| --- | --- |
| N1 | iPad 新啟動顯示五個原生分頁；切換側邊欄再選分頁，目的地與訂單徽章正確；根樣式變化不重建功能狀態 |
| N2 | Duo Closed 點 Mika `BL-2604-017` → Open／Partial 仍是同筆；改點 Joyce `BL-2604-015` → Closed 仍是 Joyce；選擇來源與 ID 同時由 AX 確認 |
| N3 | 首次進入訂單／開團／更多均未選取；展開顯示提示；點選後收合看同頁；Back 回清單後再展開仍無選取 |
| N4 | Mika 搜尋／篩選仍命中則保留；排除則空選取；清除篩選不自動重選；明確深連結不重複建立詳情 |
| N5 | 更多→設定→訂單→更多保留設定且無崩潰；更多→客戶→訂單→更多保留客戶頁；開團的未收款篩選跨分頁保留 |
| N6 | 新增訂單輸入 `DuoDraft`，保持欄位聚焦後摺展，再輸入附加文字仍寫回同欄，草稿與捨棄確認保留；開團編輯、報價輸入與主檔編輯同樣驗證，不造成重複 sheet |
| L1 | 總覽跨尺寸都能讀到四張 KPI 含成本；分析卡片依同一順序；大字級不截斷；比較相同 seed 的數值一致 |
| L2 | Duo 系統列在任一側時，捲動進度膠囊、點選篩選、操作新增／詳情選單都可達，不進入系統保留區。Duo 模擬器只出現右側與上方兩種位置，使用者 2026-11-01 決定左側目前不會發生、先不驗證 |
| L3 | 訂單／開團／更多在並排、收合、根側邊欄展開與半摺間切換，比例可變但狀態保留；分欄範圍正確，不以原始視窗寬減固定值驗收 |
| L4 | 總覽／分析、詳情、工具與表單在窄／寬視窗及大字級下，閱讀區上限存在且文字、圖表標籤、輸入與主要操作可讀可達；連續捲動區不因半摺跳到另一區 |

iPad UI 驗收依「測試裝置與 iPadOS 27 適應」的實機前置：開啟 UI 自動化、未接鍵盤，並先確認 KeyboardDismissTests 兩條通過，排除已知環境雜訊。Duo 模擬器仍依 apps/ios/CLAUDE.md 斷開硬體鍵盤並在 XCUITest 轉向前關閉 Device Hub。

每個矩陣案例記錄 OS／SDK、裝置或模擬器識別、尺寸／尺寸分類、方向、姿勢、字級、語言、通過與失敗步驟。Duo 驗證 Closed／Open／Partial、所有可用方向與左右側 Split View；iPad 驗證直橫向、全螢幕與可縮放視窗；一般 iPhone 驗證直橫向。以標準與最大輔助字級、中英語系測試改動頁面，VoiceOver／Reduce Motion 驗證選取、返回、欄位與非必要轉場。

**量測決策：** 不預填未量測的內容最大寬度或收合點。task 1.1 產出原型與診斷基準，task 1.2 記錄閱讀寬度的候選值及反例，後續 L3／L4 以截圖、AX frame、可讀文字與實際操作確認或否定，通過值記入 design 的驗證記錄後才定稿。這是有明確測量目標的實作任務，不能把空白數字當成已通過設計。

**分批遷移：** 1.1 原型與 1.2 局部 layout 支援完成後，1.3 啟用新根和完整的舊功能入口，1.4／1.5 於同一前置批通過 helper 與完整 N1/N5；再逐功能遷移並隨批更新測試，3.1 移除已不再掛載的舊宿主及環境橋接。每批維持可建置與對應測試通過；主對話依序建置／測試，不讓 agent 並行執行建置。失敗時回到仍可執行的上一批，不清除使用者工作樹或實機資料。

**歸檔說明：** 本提案只建立既有 capability 的 delta，不直接修改主規格。歸檔時將 `adaptive-layout` 的 Purpose 同步為：「涵蓋系統自適應根導覽、各功能依自身可用區域調整清單／詳情呈現，以及跨尺寸一致的內容排列與閱讀寬度；不以全 App 的單一寬窄分類決定所有畫面。篩選操作與狀態連續性分別由篩選與導覽規格規範。」不順帶清理其他主規格的歷史目的段落。

**官方依據：**
- https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo
- https://developer.apple.com/videos/play/tech-talks/111461/
- https://developer.apple.com/videos/play/tech-talks/111462/
- https://developer.apple.com/videos/play/tech-talks/111463/
- https://developer.apple.com/documentation/swiftui/view/defaultadaptabletabbarplacement(_:)
- https://developer.apple.com/documentation/uikit/uiview/readablecontentguide
- https://developer.apple.com/documentation/swiftui/navigationsplitview
- https://developer.apple.com/documentation/swiftui/environmentvalues/dismiss
- 官方 app-resizability skill 的 safe-area-task 與 idiom-task：局部環境、各邊 inset 獨立且即時、系統容器優先。

## Risks / Trade-offs

- 初版遷移順序可能讓舊根再次包住功能 split → 1.3 先切換根並以完整單頁橋接未遷移訂單，禁止將新 split 掛回舊根；3.1 僅清理零使用檔案。
- TabView 內嵌 split view 的工具列／搜尋／收合細節未由本次討論實測 → 原型是遷移前依賴，不把官方 API 支援當成本 App 已通過。
- 系統回寫 path 或重建 View 造成合成 pop、焦點遺失 → 同一 store 與元素識別，測試區分使用者 Back 與尺寸變化。
- 固定比例或固定限寬壓縮內容 → 所有偏好可退讓，使用長標籤、大字級與半摺反例校準。
- 多功能同時改 Shared、Root、identifier、String Catalog 或 UI helper → 熱點由前置／整合任務單獨管理；並行組僅處理不重疊的 feature 子樹，派工前後比對 git status。
- 大範圍 UI 修改使既有 snapshot／helper 假綠 → 更新行為斷言並證明舊錯誤會失敗，禁止僅重錄 snapshot 宣稱完整驗收。
- iOS 27 功能與 iOS 26 差異 → 保持原生舊版回退與同等可達功能；iOS 26 回歸在 iPhone 12，iPad 回歸在 iPadOS 27.2 的 iPad Air 5，Duo 行為另做 iOS 27.1 UI Automation 證據。
- iPad 不再驗 iOS 26 (使用者接受) → iPad 專屬的 iOS 26 行為差異不會被回歸發現；共用程式路徑由 iPhone 12 的 iOS 26 回歸涵蓋，iPad 版面與互動以 iPadOS 27 為準。
- 單元測試 snapshot 基準錄自 iOS 26.5 iPhone 模擬器 → snapshot 仍在 iPhone 17 iOS 26.5 模擬器以淺色外觀執行，不在 iPhone 12 跑；差異先回報使用者裁決是否重錄，不自行重錄。
