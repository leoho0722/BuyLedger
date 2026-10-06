## Problem

完整單元回歸與 `SnapshotTests` 整批執行時，帶標題的進度列 (`BLProgressView`) 偶爾整個標題沒畫出來，同一列右側的目前值與進度條照常顯示。受影響的 snapshot 會失敗，單獨重跑又轉綠，所以目前列在 `.claude/rules/ios-unit-tests.md` 的已知雜訊清單裡，每次回歸都要人工逐條重跑判定。清單中屬於這個徵狀 (內容型) 的有四條：

- `quoteView_非零試算輸入_顯示成本與建議售價` (試算頁成本拆解)
- `campaignListView_依日分組含今天與昨天_符合基準圖`、`campaignListView_依月分組_符合基準圖` (開團列的到貨與收款進度)
- `dashboardView_含進行中開團_顯示進行中的開團區段` (首頁進行中開團列的收款進度)

雜訊讓回歸結果需要人工判讀，也可能掩蓋真正的標題遺失；同一機制若在實機發生，使用者會看到沒有標題的進度列。這是 6e `iphone-landscape-compact-layout` 封存後，使用者裁決另開的 change，排在 ios-dev-kit 修正順序第 6 步 6a 之前。

## Root Cause

**已確認 (2026-10-06，task 2.1 至 2.3)：經 `configuration.label` 轉交給 `BLProgressViewStyle` 的標題，在 `SnapshotTests` 整批執行的離屏渲染中偶發沒有畫出；與本地化查表無關。**

- `BLProgressView` 以 `ProgressView(value:) { Text(LocalizedStringKey(title)) } currentValueLabel: { … }` 建立，由 `BLProgressViewStyle.makeBody` 以 `configuration.label` 畫標題、`configuration.currentValueLabel` 畫目前值。
- 修正前基準 (整批五輪)：`quoteView_非零試算輸入_顯示成本與建議售價` 與清單外的 `campaignListView_依年分組_符合基準圖` 都是 5／5 失敗，每次只少一個標題 (「刷卡手續費」、「到貨」)，五輪差異範圍逐像素相同，同列目前值與進度條不變。哪一條、哪一列消失會隨模擬器狀態改變 (同日稍早一次整批只有 `campaignListView_依月分組_符合基準圖` 失敗)，但同一狀態下是確定性的。
- 實驗 A (標題改 `Text(verbatim:)`，仍經 `configuration.label`)：兩條仍 5／5 失敗，排除本地化查表。
- 實驗 B (標題與目前值由 `BLProgressView` 自己排版，`ProgressView` 不帶標籤)：兩條 0／5；每個實驗後的不改程式對照輪失敗都回來，確認是變體讓失敗消失。
- 沿革：2026-07-20 (`5a36e30`) 為了讓輔助技術讀到帶當前值的進度語意，元件改成系統 `ProgressView` 加 `ProgressViewStyle`；`ios-design-system.md` 規定「系統已提供的能力不自己重造 (含進度)」，所以修法必須保留系統 `ProgressView` 的進度語意。

## Proposed Solution

- **先量測再動手**：以 `SnapshotTests` 類別整批執行五輪取得四條測試各自的失敗次數與失敗圖，作為修正前的基準。
- **先補守門**：新增 UI 測試守住進度列的朗讀 (開團列的無障礙標籤依序含「到貨、0/3、收款、$11,800」) 與英文模式的標題，讓修正不會悄悄拿掉當初改用系統 `ProgressView` 換來的進度語意與本地化。
- **以實驗確認根因 (已完成)**：判定為經 `configuration.label` 轉交的標題，採用 design 的修法 B'：標題與目前值由 `BLProgressView` 自己排版，系統 `ProgressView` 保留並提供無障礙的標題與目前值，可見文字不重複朗讀。
- **修正後驗收**：既有基準圖一律不重錄即通過；五輪整批執行四條測試都不再失敗；把四條從已知雜訊清單移除並改寫內容型雜訊的說明，修法若形成新慣例就寫進 `ios-design-system.md`。

## Non-Goals (optional)

- 像素型雜訊 (導覽列差值個位數，如 `orderEditView_一般既有訂單_符合基準圖`) 不在範圍。
- 不改進度列的外觀、`BLProgressView(title:value:tint:trailingText:)` 的呼叫形狀，以及八個呼叫端。
- 不處理已知雜訊清單中其他非進度列造成的項目。
- `SnapshotTests` 整批執行時 `orderEditView_長訂單識別碼_顯示短識別碼`、`orderEditView_合併訂單情境_符合基準圖` 出現的「Unimplemented: …Service.fetch…」依賴外溢失敗 (每輪觸發的 Service 不同，2026-10-06 量測中發現) 不在本 change 範圍，結案時回報使用者另行處理。

## Success Criteria

- 修正前的五輪整批執行量測與失敗圖記錄在 task 下方，根因由實驗結果判定並寫明證據。
- 修正後 `SnapshotTests` 整批執行五輪，所有含進度列的 snapshot 都沒有「只差進度列標題」的失敗 (至少涵蓋四條目標與 `campaignListView_依年分組_符合基準圖`)；完整單元回歸也沒有。
- 既有 snapshot 基準圖全部不重錄即通過，包含只用 `BLProgressViewStyle` 畫進度條的首頁 hero、分析頁類別排行與訂單詳情成本明細。
- 新增的朗讀與英文標題 UI 測試在修正前後都通過，且以變異驗證確認守得住 (拿掉標題時會失敗)。
- 四條測試從已知雜訊清單移除；iPhone 17 的 UI 主回歸全綠。iPad 因軟體鍵盤前提未成立，依使用者 2026-10-06 裁決略過主回歸，未驗證 (詳見 task 4.4)。

## Impact

- Affected specs：新增 `progress-indicator`
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressView.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressViewStyle.swift
    - .claude/rules/ios-unit-tests.md (已知雜訊清單與內容型說明)
    - .claude/rules/ios-design-system.md (修法若形成新慣例)
  - New:
    - apps/ios/BuyLedgerUITests/Tests/Campaigns/ 下的進度列朗讀與英文標題 UI 測試檔 (檔名依 task 命名)
  - Removed: 無
