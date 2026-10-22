# 7.1 第四輪紀錄 (2026-10-10)

第三輪修正 (副本 haikuF) 改到的 69 檔分 4 組唯讀重審，準則為第三輪準則加上 `gate71-round3.md` 的判定。各組完整報告在 session scratchpad `gate71/m01.txt`～`m04.txt`；`style_checks.py` 四組合計 69 檔，只有 `OrdersFeature.swift` 的 `LEN` (359 行例外) 與 `OrdersPresentationFeature.swift` 的 `WSIG` (enum case 維持一行) 兩筆不計失敗的代碼。

## 主對話判定：要修 (已修)

- **Bool 區域變數用事實名稱**：`OrdersContainerPlanTests` 三處 `let actual` 改 `isRequired`。
- **方法呼叫者在前**：`OrdersContainerPlanTests` 的 `makeRuleState()` 移到 `makeState(orders:)` 之前；`OrderFormatters` 依呼叫關係重排 (`revenueAndProfitText` → `signedTWD`／`minusTWD`／`plusTWD` → `twd`，`marginPercent` → `percent`)。
- **Given 能直設的不用 send、一個測試一組 When／Then**：
    - `OrdersFeatureTests+FailureTiming` 原本 Given 送 `dismiss` 再以 `formSheetDismissed` 為 When，改為 `presentation_三種表單關閉_標記關閉中並保留暫存通知(sheet:)` (When 為 `dismiss`)；關閉回呼取出通知由同檔 `formSheetDismissed_關閉中有暫存通知_呈現最新一則` (直設 Given) 涵蓋。
    - `CampaignFeatureTests+ReminderCancellation` 的 When 改為捨棄確認本身 (`presentation_修改提醒時間後取消並捨棄_不觸碰行事曆且保留連結`)，`dismiss` 的接收移到 Then，不再接 `formSheetDismissed`。
- **GWT 標記下一行直接接程式碼**：`CampaignFeatureTests+Presentation` 的 When 說明移到測試 doc 的 `- Note:`。
- **文件措辭**：`MergePhotoPickerSheet` 的 store 改 kit 樣板措辭；`RootLaunchOperations` 的 `try?` 註解改「失敗可忽略，因為 …」句型；`RootFeature.Action.View.task` 的 doc 改為實際行為 (請開團、訂單與啟動載入子層載入)。
- **右括號單獨一行**：`CampaignView` 的 `$store.scope(…).edit`／`.alert` 改為在 `.` 前斷行；`RootLaunchFeature` 的 `.start()` 與 `CampaignDetailDistributionSection` Preview 的 `.distribution` 移到右括號下一行。
- **固定點數尺寸用 `@ScaledMetric`**：`DashboardView` 與 `InsightsView` 載入骨架的卡片高度、`DashboardView` onboarding 底圓直徑。

## 不算違規

- UI 測試 Given 等待前置畫面出現 (`DashboardLaunchLoadingTests` 等待載入失敗)：「等待放 Then」只約束 TestStore 的 `finish`／`clock.advance`／`continuation`。
- 間距、內距與 `listRowInsets` 的點數不是尺寸；`navigationSplitViewColumnWidth` 的欄寬上下限比照第一輪 `.frame(maxWidth:)` 判定。
- 畫面以語意色調換算色盤顏色並組成 Design System 元件模型 (`OrderDetailCostView.donutSegments`)：資料處理已在 `OrderCostBreakdown`，色盤換算屬畫面接線。
- 計算屬性與回傳 View 的方法以名詞短語說明「這是什麼」：kit 的 doc 摘要允許「這是什麼」或「做什麼」。
- 註解以「—」引用畫面實際顯示的佔位值，不是當作標點的破折號。
- 輔助型別以 switch 分派子 Feature 的 Action 或 delegate (`OrderEditDraftOperations`、`OrdersContainerPlan+Writes`)、`OrderWritesFeature` 合併流程既有的 `.concatenate`：前者是 `apps/ios/CLAUDE.md` 的輔助型別寫法，後者行為依 722 設計不變。
- `…Operations`／`…Plan`／`…Queue` 後綴：`apps/ios/CLAUDE.md` 的輔助型別與「回傳計畫」寫法、導覽規則記載的 `CampaignPresentationQueue`。
- 多層 case pattern 依現有斷行；`DismissEffect { }`／`UUIDGenerator { }` 以 trailing closure 建構 TCA 內建的單一 closure 相依 (`apps/ios/CLAUDE.md` 的多行括號規則針對帶具名 closure 欄位的 Service、Client、Store)。
- 測試以狀態等同「通知已取出」的初始值直設 Given (`CampaignPresentationQueueTests`)；`LocalizationCatalogTests` 第一段為受測資料 (同第三輪判定)；`@Test(arguments:)` 使用標籤 tuple 未被禁止。

## 延後

- `.foregroundStyle(.primary)` 等直接使用的系統階層色：結案後的色盤 `ShapeStyle` 重構 (同第三輪)。

## 驗證

- 修正後 13 檔 `style_checks.py` `TOTAL {'WSTR': 1}` (既有單一字串字面值，不計失敗)。
- 受影響類別 (`OrdersContainerPlanTests`、`OrdersFeatureTests`、`CampaignFeatureTests`、`OrderFormattersTests`、`InsightsAttributionTests`、`RootFeatureTests`、`RootLaunchFeatureTests`、`SnapshotTests`、`OrdersPresentationFeatureTests`) total 317、passed 313，4 條失敗皆為登記的 `longformwrap` 編輯表單 snapshot，`check_snapshot_alternates.py` 判定與替代圖逐像素相同 (bundle `test_sim_2026-10-09T16-52-04-358Z_pid87750_9bd9b16d.xcresult`)。
- 變異：`OrdersPresentationQueue.isFormOpen` 只認 `.edit` 時，新參數化測試的 `.merge`、`.aiSummary` 兩例失敗、`.edit` 通過 (bundle `test_sim_2026-10-09T16-53-49-673Z_pid89333_01e4da23.xcresult`)；類別標籤略過空白、獲利正負號、通知只留最新三個變異皆被抓到 (bundle `test_sim_2026-10-09T16-29-56-741Z_pid57128_50a16700.xcresult`)。
