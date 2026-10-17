## Context

- 訂單編輯 `OrderEditView` 由 10 個區段 struct 組成 (`formSections`)，只有 `OrderEditBasicSection` 含系統 compact `DatePicker` (訂購日期)。其餘 9 個：`OrderEditStatusSection`、`OrderEditPaymentSection`、`OrderEditCampaignSection`、`OrderEditCostSection`、`OrderEditFeesSection`、`OrderEditItemsSection`、`OrderEditNotesSection`、`OrderEditPhotosSection`、`OrderEditOriginalSection`；多數接收 `StoreOf<OrderEditFeature>` 與 `FocusState<OrderEditFeature.State.Field?>.Binding`，`OrderEditNotesSection` 接收 `Binding<String>`，`OrderEditOriginalSection` 只接收 `LedgerOrder?`，`OrderEditPhotosSection` 接收照片子 store。
- 開團編輯 `CampaignEditView` 的 `campaignInfoSection` (名稱、重名訊息、開團與結單 `DatePicker`、狀態、提醒開關與提醒 `DatePicker`) 與 `notesSection` 都是 private computed property。
- 現有 4 條整張表單 snapshot 以 `.frame(width: 393, height: 852)` 加 `.image(drawHierarchyInKeyWindow: true)` 拍攝 (工具列 prominent 按鈕離屏會變黑)；`SnapshotTests+OrderEdit` 另有兩條 `task_`／`photos_` 效果隔離測試與 `makeOrderEditSnapshotState(original:)`、`makeOrderEditCalendar()` 兩個 helper，本 change 保留 (兩者原本在 `private extension`，apply 時把 `makeOrderEditSnapshotState(original:)` 移到 internal extension 供區段測試共用，行事曆 helper 維持 private)。
- 守門現況：`OrderEditFeatureTests+Dates` 守日期選擇的草稿更新；`DateSectionFormattingTests` 守 `OrderFormatters.fullTimestamp`；`OrderEditDraftOperations.categoriesDisplayText` 沒有測試；UI 測試沒有任何日期列的檢查，日期列與訂單頁尾時間戳沒有 accessibility identifier。
- UI 測試模式下 `DependencyValues+BLUITestOverrides` 把 `calendar` 與 `timeZone` 設為 UTC、時間固定為 `configuration.referenceDate`，種子日期由同一個參考時間推導，頁尾時間戳是確定值。
- worktree 與主 checkout 共用 iPhone 17 (`DDAA3311-B464-4DD3-96B8-360B26AF1929`，iOS 26.5)：MobileBuildMCP 沒有建立模擬器的指令，主線目前沒有要跑的測試，兩條線的模擬器操作錯開進行。

## Goals / Non-Goals

**Goals:**

- `SnapshotTests` 整批執行不論當天什麼時間都不再出現編輯表單的失敗。
- 不含 `DatePicker` 的編輯表單區段仍有像素比對；含 `DatePicker` 的區段由單元與 UI 測試守住它顯示的值與日期列。
- 每個 snapshot 只比對一張核可的參考圖，不再需要替代圖或人工判讀。

**Non-Goals:**

- 不改兩張表單的外觀、互動與 Feature；不改其他畫面的 snapshot。
- 不刪 archive 內的替代圖與腳本 (歷史紀錄)。
- 不處理 `ordersCompactView_多選模式_顯示勾選與工具列` 等與 `DatePicker` 無關的已知雜訊。
- 不建立新的模擬器；若使用者要兩條線同時跑測試，由使用者在 Xcode 建立第二台 iOS 26.5 的 iPhone 17。

## Decisions

### 以測試用區段宿主逐區段拍攝

新增測試輔助型別 `SnapshotSectionView<Field: Hashable, Content: View>` (單獨一檔，放 `BuyLedgerTests/`)：持有 `@FocusState private var focusedField: Field?`，`body` 為 `Form { content($focusedField) }.formStyle(.grouped)`，讓需要焦點綁定的區段能在測試中建立。每個區段測試以 `.environment(\.locale, AppLanguage.traditionalChinese.locale)` 與 `.frame(width: 393, height: <區段高度>)` 包住宿主，`assertSnapshot(of:as: .image(drawHierarchyInKeyWindow: true))`；高度在 apply 時依實際渲染定為能容納整個區段且留白的值，並寫進各測試。apply 時實測離屏渲染 (`.image`) 畫不出開團區段系統分段控制的選取狀態 (「待收款」沒有白色選取塊)，會漏守收款狀態，所以全部區段都改在 key window 渲染，與舊的整張表單測試一致，並在各測試 doc 註明。

替代方案：直接把區段放進 `Form` 寫在每個測試內 (焦點綁定無法在 View 外建立，做不到)；把整張表單拍成長圖再裁切 (仍含 `DatePicker`，不符裁決)。

### 訂單編輯拍 9 個區段加兩個情境

- 一般既有訂單 (`LedgerOrder.sampleOrders[0]`，沿用 `makeOrderEditSnapshotState(original:)`)：9 個不含 `DatePicker` 的區段各一張。
- 合併訂單 (第一筆 `mergedSourceIDs` 非空的範例訂單)：開團區段一張，守多個開團以「、」串接。
- 長編號訂單 (`BL-DRAFT-00000000-0000-0000-0000-000000000000`)：原始訂單區段一張，守 `displayID` (`BL-DRAFT-000000`) 的顯示，並保留 `#expect(longIDOrder.displayID == "BL-DRAFT-000000")`。
- 測試名稱 `orderEdit<區段>Section_<情境>_<預期>`：一般既有訂單的 9 條預期段為 `符合基準圖` (如 `orderEditStatusSection_一般既有訂單_符合基準圖`)，合併與長編號兩條寫出各自守的結果 (`orderEditCampaignSection_合併訂單情境_以頓號串接開團`、`orderEditOriginalSection_長訂單識別碼_顯示短識別碼`)；各自獨立的測試方法 (參數化會讓多個案例共用基準圖檔名)。區段測試放新檔 `SnapshotTests+OrderEditSections.swift` (`SnapshotTests+OrderEdit.swift` 已 212 行，加入後超過 300 行)，基準圖目錄跟著檔名在 `__Snapshots__/SnapshotTests+OrderEditSections/`。

### 含 DatePicker 的區段改由單元與 UI 測試守

- 基本資料區段：新增 `OrderEditDraftOperationsTests` 守 `categoriesDisplayText` (多類別以「、」串接、單一類別原樣、空陣列為空字串)；頁尾時間戳沿用 `DateSectionFormattingTests`，日期選擇沿用 `OrderEditFeatureTests+Dates`。
- UI 測試 `OrderEditDateRowTests`：以 `minimalOrders` 種子開啟既有訂單 `UITEST-MIN-001` 的編輯表單，斷言訂購日期列 (`BLAccessibilityID.OrderEdit.orderDatePicker`) 存在，頁尾時間戳 (`BLAccessibilityID.OrderEdit.orderDateTimestamp`) 的文字等於以 UTC 格式化的種子日期；預期字面值由 UI 測試模式的參考時間 2026-04-30T00:00:00Z 與 UTC 行事曆推導後寫死 (不由 production 程式計算)，以 UI 測試的 `XCTAssertEqual` 通過確認與實際畫面相符。
- UI 測試 `CampaignEditDateRowTests`：開啟新增開團表單，斷言開團與結單日期列存在、提醒日期列不存在；打開提醒開關後提醒日期列出現。
- 只檢查存在與 App 自己格式化的文字，不讀取系統日期膠囊的格式 (會隨真實時間變化)。

### 開團備註區段抽成獨立型別

`notesSection` 搬成 `CampaignEditNotesSection` (放 `Features/Campaigns/Components/`，比照 `OrderEditNotesSection`)，接收 `Binding<String>` 與 `FocusState<CampaignEditFeature.State.Field?>.Binding`，`CampaignEditView` 改為呼叫它；資訊區段維持 private computed property (不做像素比對，不需要從測試建立)。快照測試 `campaignEditNotesSection_編輯既有開團_符合基準圖` 取代 `campaignEditView_編輯既有開團_符合基準圖`，放在 `SnapshotTests+CampaignDetail.swift`。

替代方案：開團編輯完全不拍 (備註區段沒有 `DatePicker`，依裁決仍應有像素比對)；把資訊區段也抽出 (不拍它就沒有需要，擴大改動)。

### 日期列與時間戳加 accessibility identifier

`OrderEditBasicSection` 的訂購日期 `DatePicker` 與頁尾時間戳 `Text`、`CampaignEditView` 的開團、結單、提醒三個 `DatePicker` 加上 identifier，常數放 `BLAccessibilityID.OrderEdit` 與 `BLAccessibilityID.CampaignEdit`。identifier 掛在本身就是無障礙元素的控制項上 (符合 `ios-ui-tests.md`)；不改朗讀內容。

### 刪除整張表單測試與舊基準圖並更新規則

刪除 `orderEditView_一般既有訂單_符合基準圖`、`orderEditView_合併訂單情境_符合基準圖`、`orderEditView_長訂單識別碼_顯示短識別碼`、`campaignEditView_編輯既有開團_符合基準圖` 與對應 4 張基準圖。`.claude/rules/ios-unit-tests.md` 的已知雜訊清單移除這 3 條 `orderEditView_*`，並在 Snapshot 測試節新增規則：編輯表單逐區段拍攝，含系統 `DatePicker` 的區段不拍，改由單元與 UI 測試守，snapshot 只比對一張參考圖。

## Implementation Contract

**行為**：

- `SnapshotTests` 整批執行時，編輯表單相關的 snapshot 都不含系統 `DatePicker`，在任何時段都以單一參考圖通過。
- 兩張表單在 App 中的外觀與互動不變；開團編輯的備註欄仍可多行輸入、焦點行為不變。

**介面與資料形狀**：

- `SnapshotSectionView<Field: Hashable, Content: View>(content: @escaping (FocusState<Field?>.Binding) -> Content)` (測試 target 內)。
- `CampaignEditNotesSection(notes: Binding<String>, focusedField: FocusState<CampaignEditFeature.State.Field?>.Binding)`。
- 新 identifier：`BLAccessibilityID.OrderEdit.orderDatePicker`、`.orderDateTimestamp`、`BLAccessibilityID.CampaignEdit.openDatePicker`、`.closeDatePicker`、`.reminderDatePicker` (字串值依既有 `orderEdit.*`／`campaignEdit.*` 命名)。
- Page Object：`OrderEditScreen` 與 `CampaignEditScreen` 新增取得上述元素的唯讀屬性。

**失敗模式**：

- 區段 snapshot 不符時照常失敗，不再有替代圖；UI 測試找不到元素一律 `failWithDiagnostics`。

**驗收**：

- 新增的單元與 UI 測試在 iPhone 17 通過；以變異證明有效：把 `categoriesDisplayText` 的分隔字元暫改時單元測試失敗、把訂購日期列的 identifier 暫時拿掉時訂單 UI 測試失敗、把提醒 `DatePicker` 的條件暫改為恆顯示時開團 UI 測試失敗，還原後 `cmp` 相同。
- 新區段基準圖錄製後逐張目視檢查 (完整區段、無截斷、不含任何系統日期膠囊)，因為比對的圖裡沒有 `DatePicker`，時段造成的格式切換在結構上影響不到；以 `-only-testing:BuyLedgerTests/SnapshotTests` 整批執行 3 輪全數通過。
- 完整單元回歸不再有這 4 條失敗；iPhone 17 UI 主回歸通過；iPad 執行兩個新 UI 測試類別通過。

**範圍**：

- 範圍內：上述測試、helper、identifier、`CampaignEditNotesSection` 抽出、4 張舊基準圖刪除與新基準圖、`ios-unit-tests.md` 規則。
- 範圍外：Non-Goals 所列；`OrderEditView` 本體、各訂單區段的畫面內容。

## Risks / Trade-offs

- [區段單獨放進 `Form` 的渲染可能與整張表單中略有差異 (如區段間距)] → 只守區段內容；區段順序與整體版面由 UI 測試的元素存在與既有 UI 主回歸涵蓋。
- [失去工具列 (取消、儲存玻璃按鈕) 與導覽標題的像素守門] → 工具列是系統元件，存在與可用狀態已由 `OrderEditDirtyTests`、`OrderCreateTests`、`CampaignEditScreen` 相關測試守住。
- [某些區段在離屏渲染出現黑塊或照片未載入] → 依 Decisions 改 `drawHierarchyInKeyWindow` 或沿用 `makeOrderEditSnapshotState` 的照片已載入設定。
- [與主 checkout 共用模擬器] → 測試錯開執行；主線 `order-editor-close-and-seed-names` 也改了 `OrderEditView`、`OrderCreateTests`、`OrderEditDirtyTests` 與 `OptionPickerScreen`，本 change 不改這些檔，合併時預期無衝突 (`project.pbxproj` build number 除外)。
