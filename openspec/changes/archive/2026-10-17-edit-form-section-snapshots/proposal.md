## Summary

把訂單編輯與開團編輯兩張表單的整張 snapshot，改為逐區段 snapshot：不含系統 `DatePicker` 的區段照常做像素比對；含 `DatePicker` 的區段不做像素比對，改由單元測試守住它顯示的值、UI 測試守住日期列存在與 App 自己格式化的時間戳。程式碼在 worktree `/Users/leoho/Develop/BuyLedger-snapshot-sections` (分支 `features/edit-form-snapshot-sections`，base `82f6069`)。

## Motivation

- 完整單元回歸固定有 4 條 snapshot 失敗：`orderEditView_一般既有訂單_符合基準圖`、`orderEditView_合併訂單情境_符合基準圖`、`orderEditView_長訂單識別碼_顯示短識別碼`、`campaignEditView_編輯既有開團_符合基準圖`。2026-10-17 的三輪完整單元回歸 (`order-editor-close-and-seed-names` task 3.3 與 4.1) 都是這 4 條，暫換 HEAD 版程式碼也一樣，與程式改動無關。
- 成因是系統 compact `DatePicker` 的日期膠囊會隨真實時間在數字 (`2026/4/26`)、年月日 (`2026年4月26日`) 與年月日折成上下兩行之間切換，注入的時間控制不到；整張表單的截圖一定拍到日期膠囊，所以基準圖只在某些時段成立。
- 2026-10-08 曾裁決「兩種格式都算通過」並以替代圖 (`numeric`、`longform`、`longformwrap`) 加腳本比對，但替代圖只存在 `openspec/changes/archive/2026-10-10-order-edit-style-compliance/reference/check_snapshot_alternates.py`，測試本身仍判失敗，回歸結果每次都要人工判讀。
- 使用者 2026-10-10 裁決：編輯表單 snapshot 改逐區段、含系統 `DatePicker` 的區段不做像素比對 (改單元＋UI 守)、廢除替代圖機制；2026-10-17 指示在 worktree 執行。

## Proposed Solution

- **訂單編輯**：10 個區段中只有 `OrderEditBasicSection` 含 `DatePicker`。其餘 9 個區段 (狀態與幣別、收款金額、開團與收款、成本、手續費、商品、備註、照片、原始訂單) 以測試用的區段宿主各自拍一張；合併訂單另拍開團區段 (多個開團以「、」串接)，長編號訂單另拍原始訂單區段 (舊測試的截圖其實沒拍到 `displayID`)。
- **基本資料區段改由非像素測試守**：新增 `OrderEditDraftOperations.categoriesDisplayText` 的單元測試 (多類別以「、」串接、空陣列)；頁尾時間戳沿用既有 `OrderFormatters.fullTimestamp` 單元測試；日期選擇行為沿用既有 `OrderEditFeatureTests+Dates`；新增 UI 測試確認編輯既有訂單時訂購日期列存在、頁尾時間戳顯示草稿日期。
- **開團編輯**：資訊區段含開團、結單、提醒三個 `DatePicker`，不做像素比對；備註區段抽成獨立的 `CampaignEditNotesSection` (比照 `OrderEditNotesSection`) 後拍一張。新增 UI 測試確認開團與結單日期列存在、打開提醒後提醒日期列出現。
- 日期列與訂單頁尾時間戳加上 accessibility identifier 供 UI 測試定位。
- 刪除 4 張舊基準圖與 3 條整張表單測試；`ios-unit-tests.md` 已知雜訊清單移除不再存在的測試，並寫入「編輯表單 snapshot 逐區段、含系統 `DatePicker` 的區段不拍」的規則。
- 以 `SnapshotTests` 整批執行多輪確認不再有失敗。

## Non-Goals (optional)

- 不改兩張表單的外觀與互動；`CampaignEditView` 只把備註區段搬成獨立型別。
- 不處理已知雜訊清單中與 `DatePicker` 無關的 `ordersCompactView_多選模式_顯示勾選與工具列`。
- 不改其他畫面的 snapshot (如開團詳情、訂單詳情)；它們不含可編輯的 `DatePicker`。
- 不修改 archive 內的 `check_snapshot_alternates.py` 與替代圖 (歷史紀錄，不刪)。

## Alternatives Considered (optional)

- **重錄基準圖**：日期膠囊格式會再切換，重錄只讓某個時段變綠，且違反「不重錄來掩蓋」的規則。
- **保留替代圖機制、讓測試接受多種圖**：要改 snapshot 斷言接受多張參考圖，而格式還可能新增 (折行就是後來才出現的)；使用者已裁決廢除。
- **把 `DatePicker` 換成可注入的自製元件**：違反「系統已提供的能力不自己重造」，且改到正式畫面。
- **整張表單拍照時遮住 `DatePicker` 區域**：遮罩座標隨版面與字級變動，維護成本高，也不符合逐區段的裁決。

## Impact

- Affected specs：修改 `test-guard-effectiveness` (新增一條需求)
- Affected code (worktree 分支內)：
  - Modified:
    - apps/ios/BuyLedgerTests/SnapshotTests+OrderEdit.swift
    - apps/ios/BuyLedgerTests/SnapshotTests+CampaignDetail.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrderEditBasicSection.swift
    - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Orders.swift
    - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Campaigns.swift
    - apps/ios/BuyLedgerUITests/Screens/OrderEditScreen.swift
    - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift
    - .claude/rules/ios-unit-tests.md
    - .claude/rules/ios-ui-tests.md (`Form` 內 `Toggle` 的點擊規則，apply 時發現)
    - .claude/rules/ios-design-system.md (失效的參考測試改指 `paymentMethodEditorSheet_新增付款方式_顯示空白表單`)
    - apps/ios/BuyLedgerUITests/Screens/CampaignEditScreen.swift 的 `toggleReminder` 一併修正 (原本點擊不會切換開關)
  - New:
    - apps/ios/BuyLedger/Features/Campaigns/Components/CampaignEditNotesSection.swift
    - apps/ios/BuyLedgerTests/SnapshotTests+EditFormSections.swift (區段宿主與訂單編輯區段 snapshot；檔名依 task 定案)
    - apps/ios/BuyLedgerTests/OrderEditDraftOperationsTests.swift (類別串接的單元測試；若已有對應測試檔則併入)
    - apps/ios/BuyLedgerUITests/Tests/Orders/OrderEditDateRowTests.swift
    - apps/ios/BuyLedgerUITests/Tests/Campaigns/CampaignEditDateRowTests.swift
    - apps/ios/BuyLedgerTests/__Snapshots__/ 下的新區段基準圖 (預計訂單 11 張、開團 1 張，數量為規劃值)
  - Removed:
    - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEdit/orderEditView_一般既有訂單_符合基準圖.1.png
    - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEdit/orderEditView_合併訂單情境_符合基準圖.1.png
    - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderEdit/orderEditView_長訂單識別碼_顯示短識別碼.1.png
    - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+CampaignDetail/campaignEditView_編輯既有開團_符合基準圖.1.png
