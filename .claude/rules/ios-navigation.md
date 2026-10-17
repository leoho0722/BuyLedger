---
paths:
  - "apps/ios/BuyLedger/App/**"
  - "apps/ios/BuyLedger/Features/**"
  - "apps/ios/BuyLedger/Shared/DesignSystem/Components/**"
---

# iOS 導覽、呈現與輸入

## 根導覽與啟動

- **啟動時的服務初始化集中在 `AppLaunchConfigurator.configure()`**，`AppDelegate` 只在 `didFinishLaunching` 呼叫它；新增啟動設定加在這裡。
- **啟動載入由 Root 先送主檔目錄，完成後才送訂單**：`view(.task)` 送 `.more(.catalogLoadRequested)`、`.campaigns(.loadRequested)` 與 `.launch(.loadRequested)`，`.more(.delegate(.catalogLoadFinished))` 才送 `.orders(.rootRequest(.load))`。首頁、分析、客戶頁重試與訂單分頁的載入請求也都由 Root 先經主檔目錄，不以子層畫面事件觸發。
    - 清單出現或重試時先寫入 `dateContext`，再以 delegate 請容器載入 (訂單清單經 Root 先讀主檔目錄)；`OrdersLoadFeature`／`CampaignLoadFeature` 在載入中或已載入時略過，首次失敗後下一次請求會重讀。
    - 清單的 `.task` 只呼叫 `store.send(.view(.task))`，不等待 `finish()`：讀取結果由多個分頁共用，不能因切走清單而取消容器的載入 effect；只有畫面存在時才應執行的長效 effect 才隨畫面等待。
- **跨頁觸發新訂單由 Root 在總覽 `delegate(.newOrderTapped)` 的同一次更新內切到 `.orders` 並呼叫容器的 `presentNewOrder(id:now:calendar:)`**：從其他分頁直接設 sheet state 時 `OrdersView` 不在畫面階層，sheet 不會掛上。
    - 訂單分頁新增、編輯、合併確認與首頁新增都經容器的 `makeEditOptions(now:calendar:)` 帶入主檔、開團、幣別與行事曆；Root 不自行建立 `OrderEditFeature.State`，表單不在 `.task` 讀取選項。
- **Orders 的編輯、合併與 AI 摘要 sheet 綁定呈現子 Feature (`OrdersPresentationFeature`) 的同一個 `destination`，掛在 `OrdersView` 外層**：以 `@Bindable var presentation = store.scope(state: \.presentation, action: \.presentation)` 取得子 store，經 `$presentation.scope(state: \.$destination, action: \.destination)` 的各 case 呈現，iPhone／iPad 共用，不移到平台分流後的子 view。
- **不用 `.toolbar` 的 `.bottomBar`**：批次與選取操作放 `.primaryAction` 等頂部 placement，筆數由 `navigationTitle` 承載 (`OrderListFeature.State.navigationTitleKey`)。
    - compact 的底部 tab bar 會蓋住 `.bottomBar`；iPad 可拖曳視窗的下緣可能超出螢幕。
- **訂單多選工具列與可勾選列只有一份定義** (`Features/Orders/Components/` 的 `OrdersToolbarContent`／`OrderSelectableRow`)，compact 與 regular 共用，不各自維護等價實作。
- **每個目的地只有一條抵達路徑**：清單點擊與深連結寫入同一條路徑；「更多」分頁以 `MoreFeature.State.path` 的 `StackState<Path.State>` 驅動，列點擊與深連結只呼叫 `showSettings()` 這類 State 方法，在同一次狀態更新內先清空再推入。
    - 用堆疊狀態而非「呈現旗標加去重判斷」，讓不合法狀態無法表達。
    - **切離「更多」前先清空堆疊**：路徑非空時改 `selectedTab` 會讓 iPad 的 `NavigationSplitView` 觸發 assertion 崩潰 (iPhone 不會，容易漏測)。Root 的 `sidebarTabSelected` 先 `state.more.popToRoot()`；從「更多」堆疊交出跨分頁意圖的子畫面 (目前只有客戶頁) 由 `MoreFeature` 先清空 path 再送 delegate；iPhone `TabView` 走 `tabSelected` 並保留「更多」堆疊。新增會切離「更多」的推入點都走這兩條之一。
- **開團詳情以 `CampaignFeature.State.path` 的 `StackState<Path.State>` 推入，列表點擊與深連結都只呼叫 `CampaignFeature.State.showDetail(campaignID:)`**：同一次更新內先 `removeAll()` 再 `append`，找不到開團時不動。
    - production 移除堆疊內的單一元素用 `pop(from:)`，不用 `StackState.removeAll(where:)`：它走 `RangeReplaceableCollection` 預設實作，會重配所有元素的 id，畫面可能 pop 再 push；開團以 `popDetail(campaignID:)` 移除已刪除開團的詳情。
- **訂單 iPhone 詳情以詳情導覽子 Feature (`OrdersDetailNavigationFeature`) 的 `path` (`StackState<Path.State>`) 推入，`Path` 只含 `detail(OrderDetailFeature)`**：顯示詳情經 `detail.showDetail(orderID:)`，同一次更新內先清空再推入；刪除與合併後用 `path.popDetail(orderID:)`，內部以 `pop(from:)` 保留前方元素的識別值。
    - iPad 右欄以 scoped store 使用同一個 `OrderDetailFeature`；同一子 Feature 的 `regularDetail` 在清單的選取變更 delegate 與首次載入完成時由容器同步 (`detail.syncRegularDetail(selectedOrderID:)`、`detail.applyLoadedOrders(selectedOrderID:)`)，選取的訂單不變時沿用既有詳情，不因與選取無關的回應重建。
    - 客戶名稱與類別深連結由 Root 呼叫容器的 `applyFilterNavigation(searchText:category:now:calendar:)`，容器套用清單篩選、重選第一筆並同步右欄，Root 不直接改清單的篩選欄位。
- **側邊欄只列目的地，選取狀態由 `RootFeature.State.selectedTab` 衍生**：`RootSidebarLayout.SidebarSelection` 對應分頁列，不另設一套選取狀態；「訂單」列的進行中徽章由 `SidebarBadgeCounts.activeOrderCount` 計算。

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
    - 不綁 store、以 closure 溝通的可重用 sheet 元件 (`OptionPickerSheet`／`PaymentMethodEditorSheet`／`LookupNameEditorSheet`) 的本地 `@State` 屬元件內部狀態，不在此限。
- **任一時刻只呈現一層 modal**：同一畫面的多個 sheet 併進單一 `@Presents` destination 列舉 (參考 `LookupManagementFeature.Destination`)，不靠多個 `.sheet` 各自以布林避讓。
    - 同一個 `destination` 的表單送出後若要接續呈現寫入失敗或回溯確認 alert，等 `.sheet(item:onDismiss:)` 回報關閉後才把 alert 設進 `destination`；關閉期間到達的 alert 先暫存，再由關閉回呼呈現 (參考 `LookupManagementFeature.State.isFormSheetDismissing`、`pendingAlert` 與 `formSheetDismissed`)；開團的對應實作是 `CampaignPresentationQueue`，另涵蓋表單與其捨棄確認存在期間到達的提示 (只留最新一則)。sheet 關閉動畫中設入 alert 會讓 SwiftUI 丟棄呈現，但狀態仍停在 alert；alert 關閉後接續另一個 alert 不需套用這個延後流程。
    - 訂單由 `OrdersPresentationFeature` 以 `OrdersPresentationQueue` 保護 edit、merge、aiSummary 三種 sheet 的開啟與關閉期間，失敗通知只保留最新一則；`view(.formSheetDismissed)` 才取出通知。合併轉場以 `continuousClock` 延遲 500ms，確認表單等候選 sheet 關好才開，優先於暫存通知，通知等確認表單關好才顯示。
    - 已在 sheet 內要開子畫面或選擇器時走 push，不疊第二層 sheet；訂單編輯以 `OrderEditPickersFeature.State.PickerRoute` + `navigationDestination(for:)` 驅動 (不用 `navigationDestination(item:)`，它會造成 test target 連結失敗)。
    - `OptionPickerSheet`／`PaymentMethodEditorSheet` 以 `isEmbedded: true` 嵌入宿主堆疊，預設 `false` 為自帶 `NavigationStack` 的單層 sheet。
    - 開團的操作確認 (刪除、結團) 與寫入、提醒失敗提示只由容器的呈現子 Feature (`CampaignPresentationFeature`) 呈現，確認結果以 delegate 交容器寫入；詳情沒有 `destination`，只以 `delegate(.requested)` 請容器處理；表單自身的捨棄確認 (`CampaignEditFeature.discardConfirmation`) 保留在表單內。
    - 訂單呈現子 Feature 的 `Destination` 統一呈現 edit、merge、aiSummary 與 alert (刪除確認、寫入失敗、AI 摘要未啟用)，存檔、新增選項、刪除確認與 AI 設定以 delegate 交容器；清單與詳情只以 `delegate(.requested(OrderRequest))` 請容器處理。篩選 sheet 的捨棄確認留在清單，編輯表單的捨棄確認留在表單。
- **`NavigationStack` 外層的 `.alert` 在 iPad 的 `NavigationSplitView` 中無法顯示在推入的頁面之上 (`.sheet` 可以)**：容器統一呈現 alert 時，把 alert 綁定掛在目前最上層的畫面，堆疊為空時掛根內容、有推入時掛最上層目的地，另一處給 `.constant(nil)` (參考 `CampaignView.alertBinding(isDetail:)`)。
    - 同一個綁定同時掛兩處會破壞 iPhone：兩層各自呈現同一個 alert。
- **push 目的地不自帶 `NavigationStack`**：巢狀 stack 會弄壞推進與 pop 動畫；嵌入元件不自帶 stack、不設關閉鈕，標題掛在內容上，由宿主 Back 返回。
- **編輯類 sheet (訂單、開團、付款方式) 防未儲存變更遺失**：以單一草稿值型別對照開啟時的初始草稿判斷 dirty (closure 元件用初始值快照)，sheet 掛 `.interactiveDismissDisabled(<isDirty>)`，取消鍵於 dirty 時彈「捨棄變更／繼續編輯」確認。
    - 確認用 `AlertState`／`.alert`，不用 `.confirmationDialog`：取消鍵在 toolbar，iOS 26 起從 toolbar 觸發的 `.confirmationDialog` 會位置偏移。
    - 訂單照片非同步載入，不參與草稿相等比較 (載入完成會被誤判為變更)，改以 `OrderEditPhotosFeature.State.hasEditedPhotos` 旗標追蹤。
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
- **焦點狀態放 `Feature.State`**：view 的 `@FocusState` 只當鏡像，以 `.bind($store.focusedField, to: $focusedField)` 連結，讓自動聚焦與清除焦點能由 TestStore 涵蓋。
    - 焦點 enum case 依畫面視覺順序宣告 (參考 `OrderEditFeature.State.Field`)。
- **數字鍵盤工具列只放一個「完成」**，不加上一欄／下一欄箭頭。
    - 只在焦點位於數字欄時顯示 (參考 `OrderEditFeature.State.isNumericFieldFocused`)，整個畫面只有數字欄時才可無條件顯示；完成鍵以 store binding 把 `focusedField` 設為 `nil`。
