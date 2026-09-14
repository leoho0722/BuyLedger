---
paths:
  - "apps/ios/BuyLedger/App/**"
  - "apps/ios/BuyLedger/Features/**"
  - "apps/ios/BuyLedger/Shared/DesignSystem/Components/**"
---

# iOS 導覽、呈現與輸入

## 根導覽與啟動

- **啟動時的服務初始化集中在 `AppLaunchConfigurator.configure()`**，`AppDelegate` 只在 `didFinishLaunching` 呼叫它；新增啟動設定加在這裡。
- **跨頁觸發新訂單用 `RootFeature.Action.startNewOrder`**：它同時切到 `.orders` 並設空白草稿；從其他分頁直接設 sheet state 時 `OrdersView` 不在畫面階層，sheet 不會掛上。
- **`OrdersView` 的 `.sheet(item: $store.scope(state: \.editOrder, action: \.editOrder))` 掛在 `OrdersView` 外層**，iPhone／iPad 共用，不移到平台分流後的子 view。
- **不用 `.toolbar` 的 `.bottomBar`**：批次與選取操作放 `.primaryAction` 等頂部 placement，筆數由 `navigationTitle` 承載 (`OrdersFeature.State.navigationTitleKey`)。
    - compact 的底部 tab bar 會蓋住 `.bottomBar`；iPad 可拖曳視窗的下緣可能超出螢幕。
- **訂單多選工具列與可勾選列只有一份定義** (`Features/Orders/Components/` 的 `OrdersToolbarContent`／`OrderSelectableRow`)，compact 與 regular 共用，不各自維護等價實作。
- **每個目的地只有一條抵達路徑**：清單點擊與深連結寫入同一條路徑；「更多」分頁以 `RootFeature.MoreRoute` 值導向堆疊驅動，深連結在同一次狀態更新內先清空再推入。
    - 用值導向堆疊而非「呈現旗標加去重判斷」，讓不合法狀態無法表達。
    - **從「更多」下的 pushed 頁深連結到其他根分頁，切分頁前先 `state.morePath.removeAll()`**：路徑非空時改 `selectedTab` 會讓 iPad 的 `NavigationSplitView` 觸發 assertion 崩潰 (iPhone 不會，容易漏測)。
- **選取狀態單一來源**：同一清單的不同項目類別併進同一個選取型別 (參考 `RootSidebarLayout.SidebarSelection`)，兩套選取機制並存會同時高亮兩列。

## App 鎖定

- **背景上鎖的觸發訊號是 `\.scenePhase` 的 `.background`／`.active`**：採場景生命週期的 App 不會呼叫 `AppDelegate` 的 `applicationWillResignActive`／`applicationDidBecomeActive` (且已 deprecated)，掛在那裡完全不生效。
    - `BuyLedgerApp.body` 的 `onChange(of: scenePhase)` 經 `AppScenePhaseCoordinator.handle(newPhase:send:)` 轉送 `AppLockFeature` 的 `appDidResignActive`／`appDidBecomeActive`；抽成獨立型別是為了能單元測試。
    - 任何「畫面或系統事件到動作」的接線都要有對應測試 (比照 `AppScenePhaseCoordinatorTests`)，不能只靠程式碼看起來合理。
    - 背景上鎖不保證多工切換器縮圖不含內容；需要這項保證時要另以獨立 `UIWindow` 遮蔽層處理。
- **啟用帳本保護前先通過一次驗證**：`AppLockFeature.enableToggled(true)` 先呼叫 `BiometricAuthClient`，成功才設 `isProtectionEnabled` 並持久化，失敗、取消或裝置不支援時開關維持關閉並顯示對話框；未驗證就開啟可能讓使用者無法進入 App，只能重裝並失去資料。
    - 設定頁 Toggle 用自訂 `Binding` (`get` 讀已生效的值、`set` 只送出意圖)，不用 `$store.xxx`，讓驗證失敗時開關自動彈回。

## 呈現

- **綁 store 的 View 不持有 presentation 狀態**：sheet／picker 開關、編輯草稿、焦點、導覽路徑一律放對應 `Feature.State`，以 `$store.xxx` 綁定，不留 `@State`。
    - 未採 `BindableAction` 的 Feature 先讓 `Action` conform 並在 reducer body 最前加 `BindingReducer()`；導覽堆疊用 `StackState`。
    - `.binding` 帶副作用時 (如 `SettingsFeature` 存檔)，純 UI 欄位用 `case .binding(\.showsXxx): return .none` 排除。
    - 不綁 store、以 closure 溝通的可重用 sheet 元件 (`OptionPickerSheet`／`PaymentMethodEditorSheet`／`LookupNameEditorSheet`) 的本地 `@State` 屬元件內部狀態，不在此限。
- **任一時刻只呈現一層 modal**：同一畫面的多個 sheet 併進單一 `@Presents` destination 列舉 (參考 `LookupManagementFeature.Destination`)，不靠多個 `.sheet` 各自以布林避讓。
    - 已在 sheet 內要開子畫面或選擇器時走 push，不疊第二層 sheet；訂單編輯以 `OrderEditFeature.State.PickerRoute` + `navigationDestination(for:)` 驅動 (不用 `navigationDestination(item:)`，它會造成 test target 連結失敗)。
    - `OptionPickerSheet`／`PaymentMethodEditorSheet` 以 `isEmbedded: true` 嵌入宿主堆疊，預設 `false` 為自帶 `NavigationStack` 的單層 sheet。
- **push 目的地不自帶 `NavigationStack`**：巢狀 stack 會弄壞推進與 pop 動畫；嵌入元件不自帶 stack、不設關閉鈕，標題掛在內容上，由宿主 Back 返回。
- **編輯類 sheet (訂單、開團、付款方式) 防未儲存變更遺失**：以單一草稿值型別對照開啟時的初始草稿判斷 dirty (closure 元件用初始值快照)，sheet 掛 `.interactiveDismissDisabled(<isDirty>)`，取消鍵於 dirty 時彈「捨棄變更／繼續編輯」確認。
    - 確認用 `AlertState`／`.alert`，不用 `.confirmationDialog`：取消鍵在 toolbar，iOS 26 起從 toolbar 觸發的 `.confirmationDialog` 會位置偏移。
    - 訂單照片非同步載入，不參與草稿相等比較 (載入完成會被誤判為變更)，改以 `hasEditedPhotos` 旗標追蹤。
- **開團訂購提醒用 Form 內 inline `DatePicker`**：`Toggle` 加條件顯示的 `DatePicker(displayedComponents: [.date, .hourAndMinute])`，時間戳隨表單草稿一起儲存；不另做 sheet、push 或自製對話框。
- **alert 不裝表單**：有輸入框或開關的流程用 sheet 內表單；alert 的 actions 只支援 `Button`／`TextField`，放 `Toggle` 會被靜默丟棄。
- **不用 `navigationBarBackButtonHidden(true)` 自繪返回鍵** (會停用邊緣滑動返回)，也不用 `.toolbarRole(.editor)` (inline 標題會變成 leading 對齊)。
- **不可逆的狀態轉換 (如結團) 比照刪除**：先以 `AlertState` 確認、文案點明後果與不可復原，確認後才寫入。
- **寫入先落盤、成功才改畫面狀態，不做樂觀更新加回滾**：狀態更新放在寫入成功的 action (`statusChangePersisted`／`batchStatusChangePersisted`／`orderSavePersisted`／`orderDeleted`)。
    - 訂單合併 (`mergeSourceIDs` 非空) 是保留的樂觀更新加快照回滾例外。
    - 一次性操作失敗與持續性載入失敗不共用狀態欄位：`OrdersFeature.errorMessage` 只給 `.task` 的載入失敗，寫入失敗經 `orderWriteFailed(String)` 呈現為 `writeFailureAlert`，隨使用者關閉而結束。共用欄位時唯一的清空點常被「已載入」旗標擋住，錯誤訊息會在後續操作成功後仍殘留。
- **表單儲存前的同步驗證由父層決定是否關閉**：子層 `saveTapped` 只回 `.none`，父層驗證通過才設 `state.xxx = nil`；拒絕時保留呈現，並把原因寫回子層 State 顯示在表單上 (如 `CampaignEditFeature.State.nameConflictMessage`)。

## 焦點與鍵盤

- **每個有輸入的畫面至少提供兩條收鍵盤路徑**：一般鍵盤的 return 鍵、數字鍵盤工具列 (`ToolbarItemGroup(placement: .keyboard)`)、`.scrollDismissesKeyboard(.interactively)`。
    - 不掛 window 級手勢加排除清單：黑名單追不上系統 view 型別，會誤觸貼上、選取等系統 action。
    - 「點背景收鍵盤」不可行，不要嘗試：`Form`／`List`／`ScrollView` 會吃掉空白處的觸控 (`Form` 加 `.scrollContentBackground(.hidden)` 亦然)。
    - `.scrollDismissesKeyboard(.interactively)` 對真實使用者有效，即使沒有 UI 測試能守它也要保留。
    - 收鍵盤一律把焦點設為 `nil`／`false`，不呼叫 UIKit 的 `endEditing`；`.searchable` 畫面由系統提供 Cancel 鈕與捲動收合。
- **焦點狀態放 `Feature.State`**：view 的 `@FocusState` 只當鏡像，以 `.bind($store.focusedField, to: $focusedField)` 連結，讓自動聚焦與清除焦點能由 TestStore 涵蓋。
    - 焦點 enum case 依畫面視覺順序宣告 (參考 `OrderEditFeature.State.Field`)。
- **數字鍵盤工具列只放一個「完成」**，不加上一欄／下一欄箭頭。
    - 只在焦點位於數字欄時顯示 (參考 `OrderEditView.isNumericFieldFocused`)，整個畫面只有數字欄時才可無條件顯示。
