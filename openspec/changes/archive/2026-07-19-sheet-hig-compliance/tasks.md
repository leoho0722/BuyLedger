## 1. F1：訂單編輯 sheet 未儲存變更關閉確認

- [x] 1.1 [P] 依「Dirty 判斷以各編輯 feature 的 draft fingerprint 計算」，於 `OrderEditFeature.State` 新增涵蓋全部草稿欄位 (客戶名稱／來源／類別／訂購日期／狀態／幣別／付款方式／對帳狀態／各收款與成本金額／手續費率／開團／收款狀態／商品明細／備註／照片) 的 draft fingerprint 與 `isDirty`；行為：改動任一草稿欄位後 `isDirty` 為 `true`、未改為 `false`。驗證：`OrderEditFeatureTests` 新增 `isDirty` 案例 (改欄位→真、還原→假) 綠燈
- [x] 1.2 依「捨棄變更以 confirmationDialog 確認、狀態放 reducer」與 spec「Confirm discarding unsaved changes when cancelling」，`OrderEditFeature` 的 `cancelTapped` 於 `isDirty` 為真時呈現含「捨棄變更」(destructive) 與「繼續編輯」的確認狀態、否則直接 dismiss，並新增 discard／keepEditing 對應 Action。驗證：`TestStore` 驗 dirty→呈現確認、discard→發出 dismiss、keepEditing→關對話框且草稿留存、未 dirty→直接 dismiss
- [x] 1.3 依「以 interactiveDismissDisabled 綁 dirty 阻擋靜默下滑關閉」與 spec「Guard edit sheets against silent data loss on dismissal」，`OrderEditView` 加 `.interactiveDismissDisabled(store.isDirty)` 並讓取消鍵接上確認對話框。行為：dirty 時下滑不關閉、取消鍵彈確認；未 dirty 時下滑與取消直接關閉。驗證：模擬器手動 assert 兩種情境 + iOS build 綠

## 2. F1：開團編輯 sheet 未儲存變更關閉確認

- [x] 2.1 [P] 依「Dirty 判斷以各編輯 feature 的 draft fingerprint 計算」，於 `CampaignEditFeature.State` 新增涵蓋 `draftName`／`draftNotes`／開團日期／結單日期／狀態／`wantsReminder`／提醒時間戳的 draft fingerprint 與 `isDirty`。行為：改動任一草稿欄位後 `isDirty` 為真。驗證：`CampaignEditFeatureTests` 新增 `isDirty` 案例綠燈
- [x] 2.2 依「捨棄變更以 confirmationDialog 確認、狀態放 reducer」與 spec「Confirm discarding unsaved changes when cancelling」，`CampaignEditFeature` 的 `cancelTapped` 依 `isDirty` 分流呈現捨棄確認、並新增 discard／keepEditing Action。驗證：`TestStore` 驗 dirty→確認、discard→dismiss、keepEditing→留存、未 dirty→直接 dismiss
- [x] 2.3 依「以 interactiveDismissDisabled 綁 dirty 阻擋靜默下滑關閉」與 spec「Guard edit sheets against silent data loss on dismissal」，`CampaignEditView` 加 `.interactiveDismissDisabled(store.isDirty)` 並讓取消鍵接確認對話框。驗證：模擬器手動 assert + iOS build 綠

## 3. F1：付款方式編輯 sheet 未儲存變更關閉確認

- [x] 3.1 [P] 依 spec「Guard edit sheets against silent data loss on dismissal」與「Confirm discarding unsaved changes when cancelling」，`PaymentMethodEditorSheet` 以本地 `@State` 記初始 `(name, isCardless, isBankTransfer, isCashOnDelivery)` 推導 `isDirty`，加 `.interactiveDismissDisabled(isDirty)` 與取消鍵的 `.confirmationDialog`(捨棄變更／繼續編輯)，不更動對外 `onSubmit` 簽章。驗證：Preview 手動 assert dirty→取消彈確認、乾淨→直接關；既有測試維持綠

## 4. F2：OptionPickerSheet 可嵌入化

- [x] 4.1 [P] 依「OptionPickerSheet 拆出可嵌入 (無自帶 NavigationStack) 模式」與 spec「Preserve top-level single-sheet picker presentation」，`OptionPickerSheet` 抽出內部 List／搜尋／新增內容子 view 並加呈現情境參數 (預設＝自帶 `NavigationStack` + Cancel、6 處主介面呼叫點免改)；嵌入模式不自帶 `NavigationStack`／不放 Cancel、保留標題與多選「完成」。驗證：設定／報價／匯率／訂單頁 6 處單層 sheet 外觀互動不變 (手動比對) + 雙平台 build 綠
- [x] 4.2 依「開團提醒選擇器與新增付款方式表單改用 push」與 spec「Add-new sub-editors avoid a third stacked sheet」，`OptionPickerSheet` 的「新增付款方式」由 `.sheet` 改為 push 到當下承載該 picker 的 `NavigationStack`。行為：訂單編輯付款方式選擇器點「新增付款方式」時新增表單以 push 出現、全程不超過一層 sheet + 導覽 push。驗證：模擬器手動 assert 無三層疊 sheet

## 5. F2：訂單編輯選擇器改 push 導覽

- [x] 5.1 依「訂單編輯的巢狀選擇器改用單一 route 的 push 導覽」，`OrderEditFeature.State` 以單一 optional picker route enum 取代 `showsOrderSourceSheet`／`showsCategorySheet`／`showsCampaignSheet`／`showsPaymentMethodSheet`／`showsReconciliationStatusSheet`／`showsCurrencySheet` 六個布林；picker tapped Action 設 route、選取 Action 清 route。驗證：`OrderEditFeatureTests` picker route 遷移案例 (tap→route 設定、select→route 清空) 綠燈
- [x] 5.2 依 spec「Present in-sheet pickers via push navigation」，`OrderEditView` 六個 `.sheet(isPresented:)` 改為單一 route 驅動的 `navigationDestination` 呈現嵌入式 `OptionPickerSheet`，採本 codebase 既有的 `StackState`／`navigationDestination(for:)` 模式避開 `navigationDestination(item:)` 的 test-target 連結踩雷。行為：點選擇器列以 push (帶 Back) 呈現、Back 回表單且選擇已套用、無疊 sheet。驗證：模擬器手動 assert + iOS/iPadOS build 綠 (若連結失敗依 memory 判別處置)

## 6. F2：開團提醒選擇器改 push 導覽

- [x] 6.1 依 spec「Present in-sheet pickers via push navigation」，`CampaignEditView` 的訂購提醒最終改為 Form 內 inline `DatePicker`（`Toggle($store.wantsReminder)` + 條件顯示的 inline 日期時間列，點擊跳系統原生月曆／時間浮層）——經 push、置中自製對話框兩版實機被否決後定案；提醒時間戳即表單草稿、無獨立呈現故不涉疊 sheet，並移除 `draftReminderTimestamp`／`isReminderPickerPresented` 與四個 popup action。驗證：`CampaignFeatureTests` binding 版測試綠 + 實機手動 assert

## 7. 驗證與收尾

- [x] 7.1 `OrderEditFeatureTests` 與 `CampaignEditFeatureTests` 補齊 `isDirty`、`cancelTapped` 分流、discard／keepEditing、picker route 遷移四類案例並全數綠燈。驗證：`test_sim` 對兩個測試檔案綠
- [x] 7.2 依平台鐵則將 build number +1 後序列化 build iOS 與 iPadOS 皆成功、既有 269+ 測試全綠；導覽結構調整若造成 snapshot 差異則重錄 baseline 並於變更說明記錄。驗證：雙平台 build 綠 + 全測試綠
- [x] 7.3 實機驗收：訂單編輯六種選擇器 + 開團提醒 + 新增付款方式皆以 push (帶 Back) 呈現且無疊 sheet；訂單／開團／付款方式三張編輯 sheet 在有未儲存變更時下滑不關、取消鍵彈「捨棄變更／繼續編輯」確認。驗證：實機逐項手動 assert 通過

## 8. 全面 HIG 合規再稽核補強

- [x] 8.1 依 spec「Present media viewers as full-screen modals」，訂單編輯的照片檢視器 `BLPhotoViewer` 由 `.sheet(item:)` 改為 `.fullScreenCover(item:)`（HIG media 全螢幕呈現、消除最後一處 sheet 疊 sheet）。驗證：全測試套件綠（snapshot 無變動）+ 實機手動 assert 照片以全螢幕開啟
- [x] 8.2 依 spec「Multi-step sheets use Back on subsequent steps」，合併流程 `OrderMergeCandidateSheet` 照片步驟改真 navigation push（`NavigationStack(path:)` + `navigationDestination(for: Step.self)`、`Step` 加 `Hashable`、候選為 root、照片為 push 目的地），取得原生 push／pop 動畫、系統原生 Back 返回並經 `stepPath` setter 送 `backToCandidatesTapped` 清照片暫存。驗證：`OrderMergeFeatureTests.backToCandidatesTappedReturnsToCandidateStepAndClearsPhotoState` 綠 + 實機 assert pop 動畫
- [x] 8.3 補齊 F1 捨棄確認 alert 的英文本地化：`捨棄變更`／`繼續編輯`／三句「…尚未儲存的變更…」補進 `Localizable.xcstrings` 的 `en`（原僅中文字面值、英文模式露中文）。驗證：`LocalizationCatalogTests` 全綠（含 catalog 完整性）+ 實機英文模式確認 alert 顯示英文
