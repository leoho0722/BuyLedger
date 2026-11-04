---
paths:
  - "apps/ios/BuyLedger/App/**"
  - "apps/ios/BuyLedger/Features/**"
  - "apps/ios/BuyLedger/Shared/DesignSystem/Components/**"
---

# iOS 導覽、呈現與輸入

## 根導覽與啟動

- **根導覽是 `RootNavigationLayout`**：原生 `TabView` + `.tabViewStyle(.sidebarAdaptable)`，五個同層目的地；iPad 初始為頂部分頁列，叫出後為側邊欄，品牌 header 只在側邊欄 (`tabViewSidebarHeader`)。
    - `RootView` 只阻斷持久層失敗、鎖定畫面並套用語系，正式路徑的版面不由它決定。
- **啟動時的服務初始化集中在 `AppLaunchConfigurator.configure()`**，`AppDelegate` 只在 `didFinishLaunching` 呼叫它；新增啟動設定加在這裡。
- **啟動載入由 Root 先送主檔目錄，完成後才送訂單**：`view(.task)` 送 `.more(.catalogLoadRequested)`、`.campaigns(.loadRequested)` 與 `.launch(.loadRequested)`，`.more(.delegate(.catalogLoadFinished))` 才送 `.orders(.rootRequest(.load))`。首頁、分析、客戶頁重試與訂單分頁的載入請求也都由 Root 先經主檔目錄，不以子層畫面事件觸發。
    - 清單出現或重試時先寫入 `dateContext`，再以 delegate 請容器載入 (訂單清單經 Root 先讀主檔目錄)；`OrdersLoadFeature`／`CampaignLoadFeature` 在載入中或已載入時略過，首次失敗後下一次請求會重讀。
    - 清單的 `.task` 只呼叫 `store.send(.view(.task))`，不等待 `finish()`：讀取結果由多個分頁共用，不能因切走清單而取消容器的載入 effect；只有畫面存在時才應執行的長效 effect 才隨畫面等待。
- **跨頁觸發新訂單由 Root 在總覽 `delegate(.newOrderTapped)` 的同一次更新內切到 `.orders` 並呼叫容器的 `presentNewOrder(id:now:calendar:)`**：從其他分頁直接設 sheet state 時 `OrdersView` 不在畫面階層，sheet 不會掛上。
    - 訂單分頁新增、編輯、合併確認與首頁新增都經容器的 `makeEditOptions(now:calendar:)` 帶入主檔、開團、幣別與行事曆；Root 不自行建立 `OrderEditFeature.State`，表單不在 `.task` 讀取選項。
- **Orders 的編輯、合併與 AI 摘要 sheet 綁定呈現子 Feature (`OrdersPresentationFeature`) 的同一個 `destination`，掛在 `OrdersView` 外層**：以 `@Bindable var presentation = store.scope(state: \.presentation, action: \.presentation)` 取得子 store，經 `$presentation.scope(state: \.$destination, action: \.destination)` 的各 case 呈現，iPhone／iPad 共用，不移到平台分流後的子 view。
- **不用 `.toolbar` 的 `.bottomBar`**：批次與選取操作放 `.primaryAction` 等頂部 placement；compact 的筆數由 `navigationTitle` 承載 (`OrderListFeature.State.navigationTitleKey`)，regular 清單欄由欄內頂部承載 (見下方 inline 標題條目)。
    - compact 的底部 tab bar 會蓋住 `.bottomBar`；iPad 可拖曳視窗的下緣可能超出螢幕。
- **訂單多選工具列與可勾選列只有一份定義** (`Features/Orders/Presentation/` 下 `Root/Views/` 的 `OrdersToolbarContent` 與 `OrderList/Views/` 的 `OrderSelectableRow`)，compact 與 regular 共用，不各自維護等價實作。
- **訂單詳情畫面只有一份定義** (`OrderDetailView`)：iPad 詳情欄與 iPhone 推入詳情都直接使用 `OrderDetailView(store:)`，內容排版不分版面，不為寬版另做分支。
    - 客戶名稱 inline 標題與工具列 (`OrderDetailToolbarContent`) 由 `OrderDetailView` 在有訂單時自己宣告，呼叫端不另外包裝：兩處各自包裝時可能只改到一處，現有測試不能保證兩處始終一致。`OrdersRegularDetailColumn` 只負責無選取或選取的訂單已不存在時的空狀態。
    - `OrderDetailMenu` 不分版面外觀；標題用系統導覽列，不自繪標題列。
- **`NavigationSplitView` 的欄位規則**：訂單 (`OrdersView`)、開團 (`CampaignView`)、更多 (`MoreView`) 各自持有清單欄與詳情欄的 split；以下規則適用於所有 split view 欄位。
    - **清單欄每個可選項目都是 `List(selection:)` 的直接列** (`NavigationLink(value:)`)，selection 的 getter 由功能的 `path` 投影、setter 送功能自己的 view action：多個連結包在同一列的卡片裡時選取不生效，直向覆蓋的側邊欄點選後也不會收起。列要有卡片外觀時用 `BLCardRowBackground`／`BLCardRowPosition` 逐列給背景。
    - 不綁 `columnVisibility`、不指定 split view style：側邊欄是否並排由系統決定 (窄的 iPad 直向會收起，由「顯示側邊欄」鈕或左緣滑動叫出，叫出後覆蓋在清單上)；`.balanced` 改變不了三欄直向的覆蓋。
    - **欄寬在宣告欄位的地方設定** (欄位閉包或欄位根 view)：掛在 `.searchable` 內層的 `navigationSplitViewColumnWidth` 不生效。直向的 content 欄有系統上限，動態要求超過上限時系統會收起清單欄，所以不以量到的欄寬回寫欄寬。
    - **含 `.searchable` 的並排清單欄用 inline 標題**：大標題在搜尋結束 (收鍵盤或清除文字) 後會留白不顯示標題並把搜尋欄下推。收合時的窄版清單維持大標題：搜尋中由系統收起標題，關閉搜尋後回到原位 (由 `OrdersListTests` 的三條 `testCloseSearch_…` 守門：直接關閉、收鍵盤後關閉、清除文字後關閉)。regular 訂單清單欄的標題固定為「訂單」，多選筆數一律放欄內頂部 (`OrdersRegularListColumn.selectionSummary`)：直向窄欄放不下 inline 標題與多選工具列，兩處都顯示又會重複。
- **每個目的地只有一條抵達路徑**：清單選取與深連結寫入同一條路徑；「更多」分頁以 `MoreFeature.State.path` 的 `StackState<Path.State>` 驅動，入口清單的選取由 `path` 投影 (`currentEntry`)，setter 送 `entrySelected(_:)`，深連結 (`showSettings()`) 與選取都經 `open(_:)`：同一工具不動 `path` (保留子狀態與元素識別值)，不同工具在同一次狀態更新內先清空再推入。
    - 工具的子階層由 `MoreView` 詳情欄的 `NavigationStack` 承載，以 `.id(pathID)` 讓換工具時重建、重選同一工具時保留；工具 View 本身不自帶 stack。
    - 用堆疊狀態而非「呈現旗標加去重判斷」，讓不合法狀態無法表達。
    - **切分頁不清空「更多」堆疊**：`RootFeature` 的 `tabSelected` 只更新 `selectedTab`，「更多」的 `path` 原樣保留，切回後回到原目的地；從「更多」堆疊交出跨分頁意圖的子畫面 (目前只有客戶頁) 也不先清空。
- **開團目前詳情只存在 `CampaignFeature.State.path` 的 `StackState<Path.State>`**：清單選取的 setter 送 `detailSelectionChanged(_:)`，有值呼叫 `showDetail(campaignID:)`、`nil` 呼叫 `clearDetail()`；深連結也只呼叫 `showDetail`。同一開團重開保留元素，其他開團在同一次更新內先 `removeAll()` 再 `append`，找不到開團時不動；載入完成 (`onChange(of: \.load.hasLoaded)`) 只移除已不存在開團的詳情，不自動選取。
    - production 移除堆疊內的單一元素用 `pop(from:)`，不用 `StackState.removeAll(where:)`：它走 `RangeReplaceableCollection` 預設實作，會重配所有元素的 id，畫面可能 pop 再 push；開團以 `popDetail(campaignID:)` 移除已刪除開團的詳情。
- **訂單目前目的地只有詳情導覽子 Feature (`OrdersDetailNavigationFeature`) 的 `path` (`StackState<Path.State>`)**：`Path` 只含 `.detail(OrderDetailFeature)`；窄版與寬版清單的選取 getter 都由 `OrdersFeature.State.selectedOrderID` 投影，setter 送 `detailSelectionChanged(_:)`，有值呼叫 `detail.showDetail(orderID:)`、`nil` 呼叫 `detail.clearDetail()`；收合推入與並排詳情欄都以 `scope` 使用同一個 `path` 元素，不另存第二份目前訂單；相同訂單重開保留元素，其餘訂單替換詳情路徑。
    - 刪除與合併後依 `path.popDetail(orderID:)` 移除，保留前方元素識別值。
    - 清單篩選條件改變時，容器以 `OrdersFeature.body` 的 `.onChange(of: \.list.filterConditions)` 檢查 `path` (父層不能攔截清單的 `.view` action)：符合結果就保留；被排除時回傳 `.run` 送 `filterConditionsChanged`，下一個 action 才清空。載入完成只移除已不存在訂單的詳情，不自動開啟首筆。
        - 不在同一次更新內清空：`.searchable` 的文字綁定可能在畫面更新中送出 action，SwiftUI 收到巢狀狀態變更的通知會同步重算詳情欄，讀到 TCA 尚未寫回的舊 `path`；寫回時根狀態識別不變、不再通知，詳情欄就停在已被排除的訂單。延後清空時，被排除的訂單會在詳情欄多留一個 run loop。
    - 客戶名稱與類別深連結由 Root 呼叫容器的 `applyFilterNavigation(searchText:category:now:calendar:)`，容器套用清單篩選並在同一次更新內檢查 `path` (Root 的 action 不經過容器的 `.onChange`)；不符合時清空詳情，不改選其他訂單。Root 不直接改清單的篩選欄位。
    - 回到前景與系統時間變更時，容器的 `refreshDateContext(now:calendar:)` 只清除因這次刷新才被日期篩選排除的詳情：刷新前已被排除的詳情 (改狀態到篩選外) 刻意保留，一律檢查會在每次回到前景時清掉它。`applyFilterNavigation` 不經此方法，要先套新篩選再檢查。
    - 存檔與合併完成不自動開啟詳情；合併讓目前詳情的訂單消失時清除該詳情。
- **根導覽的選取狀態只有 `RootFeature.State.selectedTab`**：`RootNavigationLayout` 以 `$store.selectedTab.sending(\.view.tabSelected)` 綁定原生 `TabView`，不另設選取狀態；「訂單」分頁的進行中徽章由 `SidebarBadgeCounts.activeOrderCount` 提供。

## App 鎖定

- **背景上鎖的觸發訊號是 `\.scenePhase` 的 `.background`／`.active`**：採場景生命週期的 App 不會呼叫 `AppDelegate` 的 `applicationWillResignActive`／`applicationDidBecomeActive` (且已 deprecated)，掛在那裡完全不生效。
    - `BuyLedgerApp.body` 的 `onChange(of: scenePhase, initial: true)` 經 `AppScenePhase(_:)` 轉成殼層列舉，送 `AppLockFeature` 的 `.view(.scenePhaseChanged)`；上鎖、解鎖與是否通知殼層一律由 reducer 決定，App 入口不做判斷。回到前景時 `AppLockFeature` 送 `delegate(.didBecomeActive)`，由 Root 更新開團、訂單清單、首頁與分析頁的日期脈絡。
    - 任何「畫面或系統事件到動作」的接線都要有對應測試 (`AppScenePhaseTests` 守場景階段對應，`AppLockFeatureTests` 守各階段的狀態變化)，不能只靠程式碼看起來合理。
    - **冷啟動解鎖靠 `initial: true`，這一行沒有 UI 測試守門**：拿掉後現有 `AppLockTests` 的冷啟動測試仍會通過 (啟動時 scenePhase 的後續變更也會觸發)，改動時要另外確認。
    - 背景上鎖不保證多工切換器縮圖不含內容；需要這項保證時要另以獨立 `UIWindow` 遮蔽層處理。
- **啟用帳本保護前先通過一次驗證**：`SettingsFeature` 收到 `view(.appLockToggled(true))` 先呼叫 `BiometricAuthService`，成功才設 `isBiometricUnlockEnabled`、寫入並送 `delegate(.preferencesChanged)`，失敗、取消或裝置不支援時開關維持關閉並顯示對話框；未驗證就開啟可能讓使用者無法進入 App，只能重裝並失去資料。
    - 設定頁 Toggle 用自訂 `Binding` (`get` 讀已生效的值、`set` 只送出意圖)，不用 `$store.xxx`，讓驗證失敗時開關自動彈回。
    - `AppLockFeature` 常駐於 Root，只管上鎖與解鎖；啟用驗證與失敗說明留在設定頁，因為 alert 要掛在推入的設定頁之上。

## 呈現

- **綁 store 的 View 不持有 presentation 狀態**：sheet／picker 開關、編輯草稿、焦點、導覽路徑一律放對應 `Feature.State`，以 `$store.xxx` 綁定，不留 `@State`。
    - 未採 `BindableAction` 的 Feature 先讓 `Action` conform 並在 reducer body 最前加 `BindingReducer()`；導覽堆疊用 `StackState`。
    - `.binding` 帶副作用時 (如 `SettingsFeature` 存檔)，純 UI 欄位用 `case .binding(\.showsXxx): return .none` 排除。
- **不綁 store 的可重用 sheet 元件** (`PaymentMethodEditorSheet`、`LookupNameEditorSheet`) 只以 `Binding` 與 closure 和呼叫端溝通：
    - 草稿與捨棄確認由呼叫端的 `Feature.State` 以 `Binding` 傳入，元件不持有。
    - 焦點的真值由呼叫端 Binding 持有，元件內只保留 `@FocusState` 鏡像 (見焦點與鍵盤)。
    - 取消與捨棄以 closure 交回呼叫端。
    - `OptionPickerSheet` 的本地 `@State` 只限搜尋與推入等互動狀態。
    - 嵌入式付款方式編輯器的草稿也在其元件內，每次推入重建。
- **任一時刻只呈現一層 modal**：同一畫面的多個 sheet 併進單一 `@Presents` destination 列舉 (參考 `LookupManagementFeature.Destination`)，不靠多個 `.sheet` 各自以布林避讓。
    - 同一個 `destination` 的表單送出後若要接續呈現寫入失敗通知或回溯確認 alert，等 `.sheet(item:onDismiss:)` 回報關閉後才呈現：
        - 通知設進獨立通知狀態，確認 alert 設進 `destination`。
        - 關閉期間到達的先暫存，再由關閉回呼呈現 (參考 `LookupManagementFeature.State.isFormSheetDismissing`、`pendingAlert`／`pendingNotice` 與 `formSheetDismissed`)。
        - 開團的對應實作是 `CampaignPresentationQueue`，另涵蓋表單與其捨棄確認存在期間到達的提示 (只留最新一則)。
        - sheet 關閉動畫中設入 alert 會讓 SwiftUI 丟棄呈現，但狀態仍停在 alert。
    - **確認 alert 之後接續的寫入失敗通知，用與 `destination` 分開的 `@Presents` 通知狀態與獨立 `.alert` 呈現** (參考 `LookupManagementFeature.State.notice`、`CampaignPresentationFeature.State.notice`)，這是單一 `destination` 的例外：
        - 確認框關閉動畫期間把同一個 `destination` 改設成新 alert，SwiftUI 不呈現也不回寫 nil，狀態卡住，之後的確認框也出不來。
        - 改成 `destination` 的另一個 case 配獨立 `.alert` 也不行：TCA case 綁定的 setter 寫 nil 時不分 case，確認框晚到的 nil 會把通知一起關掉。
        - 通知只在確認框關閉後出現，兩者不同時呈現。
    - 訂單由 `OrdersPresentationFeature` 以 `OrdersPresentationQueue` 保護 edit、merge、aiSummary 三種 sheet 的開啟與關閉期間，失敗通知只保留最新一則；`view(.formSheetDismissed)` 才取出通知。合併轉場以 `continuousClock` 延遲 500ms，確認表單等候選 sheet 關好才開，優先於暫存通知，通知等確認表單關好才顯示。
    - 已在 sheet 內要開子畫面或選擇器時走 push，不疊第二層 sheet；訂單編輯以 `OrderEditPickersFeature.State.PickerRoute` + `navigationDestination(for:)` 驅動 (不用 `navigationDestination(item:)`，它會造成 test target 連結失敗)。
    - `OptionPickerSheet`／`PaymentMethodEditorSheet` 以 `isEmbedded: true` 嵌入宿主堆疊，預設 `false` 為自帶 `NavigationStack` 的單層 sheet。
    - 開團的操作確認 (刪除、結團) 與寫入、提醒失敗提示只由容器的呈現子 Feature (`CampaignPresentationFeature`) 呈現，確認結果以 delegate 交容器寫入；詳情沒有 `destination`，只以 `delegate(.requested)` 請容器處理；表單自身的捨棄確認 (`CampaignEditFeature.discardConfirmation`) 保留在表單內。
    - 訂單呈現子 Feature 的 `Destination` 統一呈現 edit、merge、aiSummary 與 alert (刪除確認、寫入失敗、AI 摘要未啟用)，存檔、新增選項、刪除確認與 AI 設定以 delegate 交容器；清單與詳情只以 `delegate(.requested(OrderRequest))` 請容器處理。清單的篩選 sheet (iPhone) 與類別選擇器 (iPad) 是清單自己的 `destination` (`OrderListFeature+Destination`)，不經容器的呈現佇列，但 `.sheet` 同樣掛在 `OrdersView` 分欄層，不掛在並排或單欄分支內：分支切換時 sheet 要有宿主。捨棄確認各留在 `OrderFilterFeature`／`OrderCategoryPickerFeature`；編輯表單的捨棄確認留在表單。
- **容器直接設定 `destination` 呈現的 sheet，若 sheet 內會推入子畫面，內容畫面的 `.task` 不可 `await store.send(...).finish()`**：呈現子 Feature 的 `ifLet` 沒參與那次呈現，TCA 的 dismiss effect 延到第一個送進呈現 reducer 的 action 才啟動，等於掛在 `.task` 這次送出底下；推入子畫面時 `.task` 被取消，dismiss effect 跟著取消，之後 `@Dependency(\.dismiss)` 不再關閉 sheet (參考 `OrderEditView`)。
    - 需要隨畫面取消的長效 effect 改由 reducer 以 cancel id 管理，不靠 `.task` 等待完成。
- **`NavigationStack` 外層的 `.alert` 在 iPad 的 `NavigationSplitView` 中無法顯示在推入的頁面之上 (`.sheet` 可以)**：容器統一呈現 alert 時，把 alert 綁定掛在目前最上層的畫面，堆疊為空時掛根內容、有推入時掛最上層目的地，另一處給 `.constant(nil)` (參考 `CampaignView.alertBinding(isDetail:)`)。
    - 同一個綁定同時掛兩處會破壞 iPhone：兩層各自呈現同一個 alert。
    - 訂單 split 的清單欄 (`OrdersCompactView`／`OrdersRegularListContent`) 與詳情欄 (`OrdersView`) 共用 `OrdersView.alertBinding(store:isDetail:)`：`path` 有詳情時只有詳情欄拿到真綁定，否則只有清單欄拿到。
- **push 目的地不自帶 `NavigationStack`**：巢狀 stack 會弄壞推進與 pop 動畫；嵌入元件不自帶 stack、不設關閉鈕，標題掛在內容上，由宿主 Back 返回。
- **編輯類表單 (訂單、開團、主檔名稱、付款方式) 防未儲存變更遺失，取消與捨棄由表單的 reducer 處理**：
    - dirty 是 `Feature.State` 的計算屬性，sheet 掛 `.interactiveDismissDisabled(<isDirty>)` 擋下滑。
    - 取消鍵有變更時設定確認框狀態 (「捨棄變更／繼續編輯」)；沒有變更或確認捨棄時，由 reducer 以 `@Dependency(\.dismiss)` 關閉表單。
    - 原因：sheet 在版面變化時 (如 iPhone Duo 摺展) 可能被系統關閉後重新呈現，View 本地狀態與 View 的 `dismiss` 在重新呈現後不可靠；reducer 關閉會把 `destination` 設為 `nil`，子狀態一併移除。
    - closure 未提供的預覽、快照與嵌入選擇器沒有 feature，才由 View 的 `dismiss` 關閉。
    - 主檔表單的 dirty 比對沿用既有行為：名稱表單比對去除空白後的名稱，付款方式表單比對未修剪的名稱。
    - 確認用 `AlertState`／`.alert`，不用 `.confirmationDialog`：取消鍵在 toolbar，iOS 26 起從 toolbar 觸發的 `.confirmationDialog` 會位置偏移。
    - 訂單照片非同步載入，不參與草稿相等比較 (載入完成會被誤判為變更)，改以 `OrderEditPhotosFeature.State.hasEditedPhotos` 旗標追蹤。
- **主檔管理的表單與提示由 `MoreView` 分欄層的宿主 (`LookupManagementPresentations`) 呈現，只隨目前主檔工具存在**：`LookupManagementView` 本體不掛呈現修飾子。
    - 理由：詳情欄內的呈現在分欄收合或展開時會被系統重新呈現，確認框與表單狀態會失效；分欄層的宿主不受影響。
    - 宿主由 `MoreView` 在目前工具是主檔管理時掛載，傳入的是從 More 的 path 取得的主檔子 store，分欄的識別不因此改變。
- **開團訂購提醒用 Form 內 inline `DatePicker`**：`Toggle` 加條件顯示的 `DatePicker(displayedComponents: [.date, .hourAndMinute])`，時間戳隨表單草稿一起儲存；不另做 sheet、push 或自製對話框。
- **alert 不裝表單**：有輸入框或開關的流程用 sheet 內表單；alert 的 actions 只支援 `Button`／`TextField`，放 `Toggle` 會被靜默丟棄。
- **不用 `navigationBarBackButtonHidden(true)` 自繪返回鍵** (會停用邊緣滑動返回)，也不用 `.toolbarRole(.editor)` (inline 標題會變成 leading 對齊)。
- **不可逆的狀態轉換 (如結團) 比照刪除**：先以 `AlertState` 確認、文案點明後果與不可復原，確認後才寫入。
- **寫入先落盤、成功才改畫面狀態，不做樂觀更新加回滾**：訂單由 `OrderWritesFeature` 在 `statusResponse`／`batchStatusResponse`／`saveResponse`／`deleteResponse` 的成功回應內更新共用資料。
    - 訂單合併 (`mergeSourceIDs` 非空) 是保留的樂觀更新加快照回滾例外。
    - 一次性操作失敗與持續性載入失敗不共用狀態欄位：`OrdersLoadFeature.State.errorMessage` 只由載入流程更新，容器與清單以 `SharedReader` 讀取；寫入失敗經 `writes` 的 `delegate(.failed)` 交容器，容器送 `presentation(.noticeRequested(...))` 進入呈現佇列，最後呈現 `destination.alert`，隨使用者關閉而結束。共用欄位時唯一的清空點常被「已載入」旗標擋住，錯誤訊息會在後續操作成功後仍殘留。
    - 表單新增主檔選項經 Root 與 `MoreFeature` 轉給 `LookupCatalogFeature` 先落盤，成功後才更新 `lookupCatalog`；結果以 `.orders(.rootRequest(.optionAdditionCompleted(_:isStored:)))` 送回容器。請求與回應帶表單實例 id，只在目前表單 id 相符時加入並選取，不能改到關閉後重開的另一張表單。
- **表單先自行處理能由子層判斷的驗證**：驗證通過才送出 delegate；需要父層資料的驗證 (如 `CampaignEditFeature` 的名稱衝突) 才由父層決定是否關閉表單，拒絕時把原因寫回子層 State 顯示在表單上。

## 焦點與鍵盤

- **每個有輸入的畫面至少提供兩條收鍵盤路徑**：一般鍵盤的 return 鍵、數字鍵盤工具列 (`ToolbarItemGroup(placement: .keyboard)`)、`.scrollDismissesKeyboard(.interactively)`。
    - 不掛 window 級手勢加排除清單：黑名單追不上系統 view 型別，會誤觸貼上、選取等系統 action。
    - 「點背景收鍵盤」不可行，不要嘗試：`Form`／`List`／`ScrollView` 會吃掉空白處的觸控 (`Form` 加 `.scrollContentBackground(.hidden)` 亦然)。
    - `.scrollDismissesKeyboard(.interactively)` 對真實使用者有效，即使沒有 UI 測試能守它也要保留。
    - 收鍵盤一律把焦點設為 `nil`／`false`，不呼叫 UIKit 的 `endEditing`；`.searchable` 畫面由系統提供 Cancel 鈕與捲動收合。
- **焦點狀態放 `Feature.State`**，讓自動聚焦與清除焦點能由 TestStore 涵蓋。
    - view 的 `@FocusState` 只當鏡像，以 `.bind($store.focusedField, to: $focusedField)` 連結。
    - Design System 元件 (`PaymentMethodEditorSheet`) 不 import TCA，因此以同語意手寫焦點同步：
        - `onAppear` 依 Binding 還原焦點。
        - 雙向 `onChange` 以相等判斷避免回寫迴圈。
    - 焦點 enum case 依畫面視覺順序宣告 (參考 `OrderEditFeature.State.Field`)。
- **輸入會改變清單內容的 `TextField` 不放 `List` 的 section header**：內容變動時 header 會重建，輸入一個字就失焦、鍵盤收起；改放獨立 section 的普通列並給固定 `.id` (參考 `OrderCategoryFilterRows.SearchRow` 的類別搜尋)。
    - insetGrouped 會以儲存格圓角遮罩列的內容與背景，沒有公開 API 可關閉；列內灰底改用 `Capsule`，與儲存格輪廓一致。
- **數字鍵盤工具列只放一個「完成」**，不加上一欄／下一欄箭頭。
    - 只在焦點位於數字欄時顯示 (參考 `OrderEditFeature.State.isNumericFieldFocused`)，整個畫面只有數字欄時才可無條件顯示；完成鍵以 store binding 把 `focusedField` 設為 `nil`。
