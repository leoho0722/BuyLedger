## 0. 開工前基準

- [x] 0.1 確認逐檔待修明細與現況相符：change 目錄的 `findings.md` 已載入 `apps/ios/BuyLedger/Shared/` 全部 35 檔的 334 筆項目，逐檔打開原始碼抽驗每個檔案至少兩筆 (`Color+Extensions.swift` 與 `Image+Extensions.swift` 各只有 1 筆，該檔全驗)，確認該違規現在仍然成立，不成立或屬 design 已列的誤報就地標記原因。驗證：35 個檔案各有抽驗記錄，且不成立與誤報的項目逐筆寫明原因

  抽驗記錄（2026-09-19）：35 檔全部以原始碼核對；以下列出每檔至少兩筆 finding（單筆檔全驗）。`H1` 均確認第 5 行仍為舊日期檔頭；預填的誤報／例外結論不改動。
  - `DesignSystem/Components/Avatar/BLAvatar.swift`：`H1 L1` 成立；`S·避免型別名前綴 L11` 為報告誤報，`BLAvatar` 仍是既定前綴
  - `DesignSystem/Components/Badges/BLBadge.swift`：`H1 L1` 成立；`S·輔助型別改 nested type L11` 的 `BLBadgeVariant` 仍為頂層型別
  - `DesignSystem/Components/Buttons/BLButtonStyle.swift`：`H1 L1` 成立；`S·輔助型別改 nested type L11` 的 `BLButtonVariant` 仍為頂層型別
  - `DesignSystem/Components/Cards/BLCard.swift`：`H1 L1` 成立；`MK1 L13` 仍為 `View Properties`
  - `DesignSystem/Components/Charts/BLBarChart.swift`：`H1 L1` 成立；`MK1 L15` 仍為 `View Properties`
  - `DesignSystem/Components/Charts/BLBarChartValue.swift`：`H1 L1` 成立；`MK1 L13` 仍為 `Identifiable Properties`
  - `DesignSystem/Components/Charts/BLDonutChart.swift`：`H1 L1` 成立；`MK1 L15` 仍為 `View Properties`
  - `DesignSystem/Components/Charts/BLDonutSegment.swift`：`H1 L1` 成立；`MK1 L13` 仍為 `Identifiable Properties`
  - `DesignSystem/Components/Charts/BLSparkline.swift`：`H1 L1` 成立；`MK1 L14` 仍為 `View Properties`
  - `DesignSystem/Components/Chips/BLFilterChip.swift`：`H1 L1` 成立；`MK1 L13` 仍為 `View Properties`
  - `DesignSystem/Components/Forms/PaymentMethodEditorSheet.swift`：`H1 L1` 成立；`S·Note 以外的自由段落 L11` 仍存在
  - `DesignSystem/Components/Images/BLPhotoThumbnail.swift`：`H1 L1` 成立；`MK1 L15` 仍為 `View Properties`
  - `DesignSystem/Components/Images/BLPhotoViewer.swift`：`H1 L1` 成立；`MK1 L15` 仍為 `View Properties`
  - `DesignSystem/Components/Pickers/OptionPickerSheet.swift`：`H1 L1` 成立；`FM4 L1` 成立，檔案仍超過 300 行
  - `DesignSystem/Components/Progress/BLProgressView.swift`：`H1 L1` 成立；`MK1 L13` 仍為 `View Properties`
  - `DesignSystem/Components/States/BLDelayedProgressView.swift`：`H1 L1` 成立；`MK1 L14` 仍為 `View Properties`
  - `DesignSystem/Components/States/BLLoadFailureView.swift`：`H1 L1` 成立；`MK1 L13` 仍為 `View Properties`
  - `DesignSystem/Components/Status/BLStatusPill.swift`：`H1 L1` 成立；`MK1 L13` 仍為 `View Properties`
  - `DesignSystem/Components/Tags/BLTagPill.swift`：`H1 L1` 成立；`MK1 L13` 仍為 `View Properties`
  - `DesignSystem/Foundations/BLFormatters.swift`：`H1 L1` 成立；`S·格式化用 FormatStyle L11` 為 design 已登記例外
  - `DesignSystem/Foundations/BLHeatmapDepth.swift`：`H1 L1` 成立；`MK1 L13` 仍為 `Cases`
  - `DesignSystem/Foundations/BLMetrics.swift`：`H1 L1` 成立；`FN1 L1` 成立，檔名 `BLMetrics` 與主要型別 `BLRadius` 不一致
  - `DesignSystem/Foundations/BLPalette.swift`：`H1 L1` 成立；`S·型別選擇 L11` 為 design 登記的無 stored property 例外
  - `DesignSystem/Foundations/BLStatusHue.swift`：`H1 L1` 成立；`S·命名語意 L21` 的 `BLStatusHue.color(for:in:)` 仍存在，待 task 1.1 移除
  - `DesignSystem/Foundations/BLTone.swift`：`H1 L1` 成立；`MK1 L13` 仍為 `Cases`
  - `DesignSystem/Foundations/BLTypography.swift`：`H1 L1` 成立；`FN1 L1` 成立，檔名 `BLTypography` 與主要型別 `BLTypographyStyle` 不一致
  - `DesignSystem/Foundations/ViewModifiers/BLCardShadow.swift`：`H1 L1` 成立；`MK1 L10` 的 protocol 名 `ViewModifier` 為合法誤報
  - `DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift`：`H1 L1` 成立；`MK1 L10` 的 protocol 名 `ViewModifier` 為合法誤報
  - `DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift`：`H1 L1` 成立；`MK1 L10` 的 protocol 名 `ViewModifier` 為合法誤報
  - `Extensions/Bundle+Extensions.swift`：`H1 L1` 成立；`S·頂層 private 輔助型別 L11` 的 `BundleToken` 仍為頂層型別
  - `Extensions/Color+Extensions.swift`：`H1 L1` 成立；該檔只有此 1 筆 finding，已全檔核對 `Color.blSecondaryLabel`
  - `Extensions/Decimal+Extensions.swift`：`H1 L1` 成立；`D3 L15` 的 `roundedUpToInteger()` 仍缺 `- Returns`
  - `Extensions/Image+Extensions.swift`：`H1 L1` 成立；該檔只有此 1 筆 finding，已全檔核對 `Image.init?(photoData:)`
  - `Localization/AppLanguage.swift`：`H1 L1` 成立；`MK1 L13` 仍為 `Cases`
  - `Media/PhotoDataProcessor.swift`：`H1 L1` 成立；`S·型別後綴與 process 動詞 L13` 的 `PhotoDataProcessor` 仍存在
- [x] 0.2 取得改動前的完整單元測試基準：先鎖模擬器淺色外觀，再以 `BuyLedger.xctestplan` 跑一次完整回歸，**把測試總數、通過數、失敗清單與 result bundle 絕對路徑寫在本檔這一行下方**。驗證：記錄的數字來自 xcresult 本身而非終端摘要，且 `tasks.md` 內確實留有該筆紀錄供 6.1 與 6.2 比較 [after: 0.1]
  - 2026-09-19，Device Hub `test_sim`（project `/Users/leoho/Develop/BuyLedger/apps/ios/BuyLedger.xcodeproj`、scheme `BuyLedger`、iPhone 17 `DDAA3311-B464-4DD3-96B8-360B26AF1929`）；結果由該次 xcresult 解析：`totalTestCount` 720、通過 720、失敗 0、跳過 0 (該 xcresult 裝置層另有 `passedTests` 870，那是 test case runs 的展開數、不是測試數，比較 baseline 時一律以頂層 `totalTestCount` 為準)。
  - 失敗清單：無。
  - Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-19T14-11-10-863Z_pid32283_94fed0f8.xcresult`
- [x] 0.3 取得改動前的 UI 測試基準：iPhone 與 iPad 各跑一次 `BuyLedgerUITests` 主回歸，**結果與 result bundle 絕對路徑同樣寫在本檔這一行下方**。驗證：兩份 xcresult 皆可解析且執行數大於 0 [after: 0.2]
  - 2026-09-19，Device Hub `test_sim`，scheme `BuyLedgerUITests`，參數 `-only-testing:BuyLedgerUITests`、`-skip-testing:BuyLedgerUITests/LaunchPerformanceTests`；兩台裝置 appearance 維持既有淺色設定。兩次 Device Hub wrapper 均在 300 秒逾時，但底層 xcodebuild session 均完成並寫入 `.xcodebuildmcp-completed` marker，非重新執行。
  - iPhone 17 `DDAA3311-B464-4DD3-96B8-360B26AF1929`：xcresult `TestCaseRuns` 解析為總數 56、通過 56、失敗 0、跳過 0；失敗清單：無。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-19T14-15-34-981Z_pid32283_b8738b93.xcresult`
  - iPad Air 11-inch (M4) `6B65ED1C-3C2E-42BA-B1E7-08F606F175C5`：xcresult `TestCaseRuns` 解析為總數 56、通過 56、失敗 0、跳過 0；失敗清單：無。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-19T14-45-53-247Z_pid32283_bcf932f4.xcresult`

## 1. 切斷 Design System 對 Core 與 TCA 的依賴

- [x] 1.1 側邊欄狀態色點的色相由訂單狀態自己提供：依「BLStatusHue 移入 Features/Orders 而非留在 Design System」，在 `OrderStatus+Presentation.swift` 新增 `sidebarHue(in:)` 並刪除 `BLStatusHue.swift`，`RootSidebarLayout.SmartGroup.color(in:)` 與 `ContrastComplianceTests.statusHueValuesStayMutuallyDistinguishable` 改呼叫它。驗證：`ContrastComplianceTests` 全類別通過，且 `grep -rn "BLStatusHue"` 在 `apps/ios/**/*.swift` 回傳 0 筆 (`.claude/rules/ios-design-system.md` 由任務 5.1 處理；`openspec/specs/**` 的 `@trace` 是歸檔工具產生的歷史紀錄，不可手改也不納入判定) [after: 0.3]
  - 靜態驗證：`rg -n 'BLStatusHue' apps/ios --glob '*.swift'` 無輸出；`sidebarHue(in:)` 的定義與兩個呼叫端均存在。
  - Device Hub `test_sim`（scheme `BuyLedger`，`-only-testing:BuyLedgerTests/ContrastComplianceTests` 等受影響 unit/snapshot targets）：110 passed、0 failed、0 skipped；其中 `ContrastComplianceTests` 全類別與 `statusHueValuesStayMutuallyDistinguishable` 均在 selected list 且通過。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-19T15-15-49-086Z_pid32283_04ce1b74.xcresult`
- [x] 1.2 付款方式 sheet 以基本型別回報結果：依「兩個 sheet 的付款方式旗標改收三個具名 Bool」，`PaymentMethodEditorSheet` 的 7 個 `PaymentMethodFlags` 使用點 (`SubmitAction` 參數、`initialFlags` 屬性、init 參數、提交時建構、private `PaymentMethodEditorSnapshot.flags`、`draftSnapshot` 與 `initialSnapshot` 建構、`#Preview` 傳值) 與 `OptionPickerSheet.onAddPaymentMethod` 全部改收三個具名 `Bool`，`LookupManagementView` 與其他傳入該 callback 的呼叫端負責組回 `PaymentMethodFlags`；未儲存變更的判定語意不變。驗證：專案編譯通過、`apps/ios/BuyLedger/Shared/` 內 `grep -rn "PaymentMethodFlags"` 回傳 0 筆，且 `OrderEditDirtyTests` 與付款方式相關 UI 測試結果與 0.3 基準一致 [after: 0.3]
  - 靜態驗證：`rg -n 'PaymentMethodFlags' apps/ios/BuyLedger/Shared` 無輸出；三個具名 Bool 由 `PaymentMethodEditorSheet`／`OptionPickerSheet` 傳出，`LookupManagementView` 與 `OrderEditView` 才重建 `PaymentMethodFlags`。
  - Device Hub `test_sim`（scheme `BuyLedger`）：`LookupManagementFeatureTests`、`OrderEditFeatureTests` 等受影響 unit targets 合計 110 passed、0 failed、0 skipped；UI `test_sim`（scheme `BuyLedgerUITests`，`OrderEditDirtyTests` + `OrderDetailTests`）為 6 passed、0 failed、0 skipped。UI result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-19T15-17-33-131Z_pid32283_1a8333fe.xcresult`
- [x] 1.3 新台幣格式化不再讀領域型別：`BLFormatters.twd(_:locale:)` 內部改用字面 ISO 代碼，對外簽章與輸出字串不變。驗證：`BLFormattersTests` 既有的六條 `twd` 測試全部維持通過，輸出字串一字不差 [after: 0.3]
  - 靜態驗證：`rg -n 'CurrencyCode\.twd\.code|currency\(code:' apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift` 僅輸出 `.currency(code: "TWD")`。
  - Device Hub `test_sim`（scheme `BuyLedger`）selected list 包含六條 `BLFormattersTests` 的 `twd` 測試，結果合計 110 passed、0 failed、0 skipped；六條既有輸出斷言均通過。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-19T15-15-49-086Z_pid32283_04ce1b74.xcresult`
- [x] 1.4 延遲轉圈不再依賴架構框架：依「BLDelayedProgressView 的延遲改用 Task.sleep 並移除 TCA 依賴」，移除 `import ComposableArchitecture` 與 `@Dependency(\.continuousClock)`，延遲改走 `Task.sleep(for:)`，取消時靜默返回並在程式碼註明理由。驗證：`apps/ios/BuyLedger/Shared/` 內 `grep -rn "ComposableArchitecture"` 回傳 0 筆，且使用它的兩個畫面 (`DashboardView`、`InsightsView`) 的 snapshot 測試結果與 0.2 基準一致 [after: 0.3]
  - 靜態驗證：`rg -n 'ComposableArchitecture' apps/ios/BuyLedger/Shared` 無輸出；`BLDelayedProgressView.swift` 僅保留 `import SwiftUI`、`Task.sleep(for:)` 與 `Task.isCancelled` 檢查，`try?` 旁有取消或失敗時不顯示轉圈的理由註解，沒有 `catch`。
  - Device Hub `test_sim`（scheme `BuyLedger`）selected list 包含 `SnapshotTests/dashboardViewBaseline` 與 `SnapshotTests/insightsViewBaseline`，結果合計 110 passed、0 failed、0 skipped，未重錄 snapshot。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-19T15-15-49-086Z_pid32283_04ce1b74.xcresult`

## 2. 幣別顯示名稱收斂為單一入口

- [x] 2.1 幣別顯示名稱有唯一實作：依「幣別顯示名稱的單一入口放 Shared/Localization 並收 ISO 代碼字串」與規格 Dimensions shared across files derive from a single source，依「CurrencyDisplayName 的檔案樣板」從 `assets/templates/domain/Enum.swift` 起手，新增 `CurrencyDisplayName` 的 `text(code:language:)` 與 `searchKeywords(code:locale:)` 兩個入口共用一份查表。`text` 在正體中文回傳系統本地化名稱、查不到或空字串時回退 ISO 代碼，英文直接回傳 ISO 代碼；`searchKeywords` 一律回傳目前 locale 的本地化名稱、查不到回空字串，不套語言規則。驗證：新增 `CurrencyDisplayNameTests` 涵蓋兩個入口各自在正體中文、英文與未知代碼下的輸出 (共六種組合) 並全部通過 [after: 0.3]
  - 靜態驗證：`CurrencyDisplayName` 位於 `Shared/Localization`，production 端的 13 處查表／顯示呼叫均改走兩個入口；`OptionPickerSheet` Preview 也改走 `CurrencyDisplayName.text`，直接查表只保留唯一入口自身。
  - Device Hub `test_sim`（scheme `BuyLedger`、`-only-testing:BuyLedgerTests/CurrencyDisplayNameTests`）：6 passed、0 failed、0 skipped。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-19T16-07-30-814Z_pid32283_0149bb44.xcresult`
  - Round 3 follow-up（2026-09-20）：六個測試案例補上實質的 Given / When / Then；`CurrencyDisplayName.text` 的 `- Returns` 明確寫出正體中文本地化名稱、未知／空字串回退 ISO 代碼，以及英文一律回傳 ISO 代碼。未改變行為
- [x] 2.2 十三處幣別查表共用同一個入口、四個 picker 顯示格式統一：依「呼叫端只做最小改動」，`SettingsView`、`QuoteView`、`FxView`、`OrderEditView`、`OrderDetailView` 刪除各自的 `currencyDisplayText` (5 處)；`SettingsView`、`FxView`、`QuoteView`、`OrderEditView` 幣別 picker 的 `displayName` 改呼叫 `text(code:language:)`、`searchKeywords` 改呼叫 `searchKeywords(code:locale:)` (8 處)，語言一律經 `AppLanguage(locale:)` 取得。完成後四個 picker 的列標題一致 (中文顯示「新台幣」、英文顯示「TWD」)，不再有 `"代碼 · 名稱"` 與 `"代碼 (名稱)"` 兩種格式，這是使用者裁決的可見行為變更；以 ISO 代碼或幣別名稱搜尋的結果不變，以舊組合字串 (`·`、`TWD ·`、`(新台幣)`) 搜尋則刻意不再命中。驗證：`apps/ios/**/*.swift` 內 `grep -rn "currencyDisplayText"` 無輸出，`grep -rn "localizedString(forCurrencyCode"` 只剩 `CurrencyDisplayName.swift` 自身；新增 `CurrencyPickerTests` 並為 `OptionPickerScreen` 補上搜尋操作 (搜尋框是 `.searchable`，用 `app.searchFields` 定位，不新增 identifier) 與列標籤讀取，斷言中文模式列標籤為「新台幣」、英文模式為 `TWD` (英文情境用啟動參數 `-BLUITestLanguage` 切換，`LaunchOptions` 已有 `english` 選項，不改測試計畫)，且以 ISO 代碼 `TWD` 與幣別名稱 (中文「新台」、英文 `Taiwan`) 搜尋時該列都仍在結果內；涵蓋這五個畫面的 snapshot 若轉紅，逐張確認差異只在幣別列文字後回報使用者，不得自行重錄 [after: 2.1] [after: 1.2]
  - 靜態驗證：`currencyDisplayText` 已無 production 使用；`localizedString(forCurrencyCode:)` 僅剩 `CurrencyDisplayName` 自身；`OptionPickerScreen` 使用 `app.searchFields`，未新增 accessibility identifier。
  - Device Hub `test_sim`（scheme `BuyLedger`、`-only-testing:BuyLedgerUITests/CurrencyPickerTests`）：8 passed、0 failed、0 skipped；Settings 兩案例各有一筆 `Invalid frame dimension` runtime warning，無 failure，未重錄 snapshot。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-19T16-34-40-009Z_pid32283_9596680f.xcresult`

- [x] 2.3 客戶列的分隔線內縮由單一定義推導：依「呼叫端只做最小改動」與規格 Dimensions shared across files derive from a single source，`CustomersView` 宣告一個基準值 36 的 `@ScaledMetric` 實例屬性，`customerRow` 的頭像尺寸與分隔線內縮都從它取值，維持目前 36pt 的視覺。驗證：`CustomersView.swift` 內 `grep -n "size: 36\|+ 36 +"` 回傳 0 筆 (第 311 行的 `maximum: 360` 是格線寬度、不在此列)，且 `CustomersTests` 與涵蓋客戶列的 UI 測試結果與 0.3 基準一致 [after: 2.2]
  - 靜態驗證：`CustomersView.swift` 的 `size: 36` 與 `+ 36 +` 均無輸出；`customerAvatarSize` 這個 `@ScaledMetric` 同時供頭像與 Divider leading inset 使用。
  - Device Hub `test_sim`（scheme `BuyLedger`、`-only-testing:BuyLedgerUITests/CustomersTests`）：4 passed、0 failed、0 skipped。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-19T16-39-41-659Z_pid32283_da284197.xcresult`

## 3. 分區、body 邊界與註解對齊規範

- [x] 3.1 Foundations 九檔的分區名與順序符合規範：依「MARK 分區改依 formatting.md 的固定名稱與順序」，`BLPalette`、`BLTone`、`BLTypography`、`BLMetrics`、`BLHeatmapDepth`、`BLFormatters` 與三個 ViewModifier 檔的段名全部改為規範允許的名稱，型別本體只留 stored properties 與 Init。驗證：這九檔 `grep "// MARK:"` 的段名逐一對照 `formatting.md` 允許清單，清單外段名 0 筆 [after: 1.3]
  - 靜態驗證（2026-09-20）：九檔的 MARK 依 `formatting.md` 順序；`Static Properties`、`Display Properties`、`Identifiable Properties`、`Cases` 與 `View Method` 均已移除，清單外段名 0 筆
- [x] 3.1.1 次要文字色的規則衝突以改寫規則文字收斂：依「次要文字色維持現況，改寫衝突的規則文字」，`BLPalette.secondaryLabel` 的程式碼不動，改寫 `.claude/rules/ios-design-system.md`「文字不透明度一律為 1」那條，寫明色盤內為達對比地板的單一次要文字色是例外及其實測理由。驗證：`ContrastComplianceTests` 與 `DesignSystemSourceScanTests` 維持通過 (本任務不改程式碼，兩者結果應與 0.2 基準完全相同)，且規則文件內不再有兩句互相矛盾的表述 [after: 3.1]
  - 靜態驗證（2026-09-20）：`BLPalette.secondaryLabel` 的 `.opacity(0.6)` 未改；規則文字已改為只禁止呼叫端自訂降階，並明載此單一次要文字色是因淺色 `secondaryLabel` 未達 4.5:1 而保留的例外
- [x] 3.1.2 Foundations 四筆判讀級項目照定案處理：依「七筆判讀級 findings 的逐筆處置」，`BLFormatters.percent(scaled:)` 改用 `(value / 100).formatted(.percent…)` 不再字串串接 `%`、`BLFormatters.percent(_:locale:)` 新增預設為 1 的 `fractionLength` 參數 (只改 formatter 本身，進度列的呼叫端由任務 3.4 處理)、`BLTone.namedColor(role:)` 的 role 改成 private enum、`BLPalette` 的型別選擇登記為待專案處理並寫明理由。驗證：`BLFormattersTests` 既有 `percent` 斷言輸出逐字不變、`BLTone` 四個呼叫點改傳 case 且色彩 snapshot 與 0.2 基準一致、`findings.md` 對應四筆填上結論 [after: 3.1.1]
  - 靜態驗證（2026-09-20）：`percent(scaled:)` 不再串接 `%`；`percent(_:locale:fractionLength:)` 預設 1；`BLTone` 四處改傳 `Role` case；`findings.md` 的 `BLFormatters` 反向依賴、scaled 百分比、`BLPalette` 型別選擇與 `BLTone` role 均有結論
- [x] 3.2 ViewModifier 與 Style 的實作放在 protocol extension：依「ViewModifier 與 Style 的 body 移進以 protocol 命名的 extension」，`BLCardShadow`、`BLHeroCardBackground`、`BLTypographyModifier`、`BLButtonStyle`、`BLPhotoThumbnailButtonStyle`、`BLProgressViewStyle` 與 `OptionPickerSheet` 檔內的 ViewModifier，遵循宣告與實作一併移到 extension，型別本體只留 stored properties。驗證：這些型別的宣告行不再帶 protocol 名稱，對應 extension 存在且 MARK 名為 protocol 名；相關 snapshot 測試結果與 0.2 基準一致 [after: 3.1] [after: 1.2]
  - 靜態驗證（2026-09-20）：七個 protocol conformance 均移到對應 MARK extension，型別宣告行不再帶 `ViewModifier`、`ButtonStyle` 或 `ProgressViewStyle`；首次 snapshot 編譯發現 private conformance extension 的 Swift 限制，移除 extension 的 `private` 後修正
- [x] 3.3 色盤與衍生值不在 body 內取得：依「body 內不宣告區域變數，色盤改由 computed property 取得」，把位於 `body` 或 `makeBody` 的 7 處 `let palette = BLPalette()` (`BLCard`、`BLFilterChip`、`BLBarChart`、`BLDonutChart`、`BLSparkline` 的 `body`，`BLButtonStyle` 與 `BLProgressViewStyle` 的 `makeBody`) 與 `BLProgressView.body` 的夾值計算改為型別上的 private computed property；`#Preview` 內的 4 處與 `Color.blSecondaryLabel` 不動。驗證：這 8 處各自的 `body` 或 `makeBody` 不再出現該筆 `let` 宣告 (`BLSparkline.body` 的 `let color = tint ?? palette.green` 由任務 3.5 隨該檔一併處理，本任務不驗它；`BLProgressView.body` 的 `clampedValue` 由本任務移出，3.4 不重複處理)，且相關 snapshot 測試結果與 0.2 基準一致 [after: 3.2]
  - 靜態驗證（2026-09-20）：7 個 body / makeBody 的 palette 宣告與 `BLProgressView.body` 的 `clampedValue` 均已移至 private computed property；四個 Preview 內的 `BLPalette()` 保留。機械檢查 20 個本輪 Swift 檔：檔頭、行寬、尾隨空白與 tab 均為 0 筆
  - Device Hub `test_sim`（scheme `BuyLedger`、`-only-testing:BuyLedgerTests/SnapshotTests`）：14 個案例實際執行，13 passed、1 failed、0 skipped；唯一失敗為已知 `quoteViewBaseline` 成本拆解渲染雜訊，未重錄基準圖。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-19T17-25-46-100Z_pid32283_e4f67725.xcresult`
  - Device Hub 單獨重跑 `BuyLedgerTests/SnapshotTests/quoteViewBaseline()`：xcresult `totalTestCount` 1、通過 1、失敗 0、跳過 0，確認為渲染雜訊。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-19T18-06-57-445Z_pid32283_21fb06b4.xcresult`
- [x] 3.4 小型元件十二檔的分區、註解與排版符合規範，進度列三項判讀項照定案處理：`BLAvatar`、`BLBadge`、`BLButtonStyle`、`BLCard`、`BLTagPill`、`BLStatusPill`、`BLFilterChip`、`BLLoadFailureView`、`BLDelayedProgressView`、`BLBarChartValue`、`BLDonutSegment`、`BLProgressView` (含其 15 筆 findings，但 `clampedValue` 的移出屬任務 3.3) 依 `findings.md` 逐項修正段名、缺漏的 doc comment 與 `- Parameter` / `- Returns`；依「七筆判讀級 findings 的逐筆處置」把 `BLProgressViewStyle` 拆成 `Components/Progress/BLProgressViewStyle.swift`、`BLProgressView` 的百分比改走 `BLFormatters.percent(_:locale:)` 並傳 `fractionLength: 0`、`spacing: 5` 與軌道 `height: 6` 登記為例外並寫明理由；`BLProgressView.body` 的 `clampedValue` 由任務 3.3 移出 body，本任務不重複處理。驗證：這十二檔在 `findings.md` 的項目全部標記處理結果 (含 design 已列的誤報標記)，進度列右側百分比顯示逐字不變 (仍為整數百分比)，且機械檢查 (行寬、尾隨空白、檔頭) 各 0 筆 [after: 3.3] [after: 1.4] [after: 3.1.2]
  - 靜態驗證（2026-09-20）：3.4 的十二檔與新增 `BLProgressViewStyle.swift` 均已完成；本批 26 個 3.4–3.6 目標 Swift 檔的行寬、尾隨空白、tab 與 closing brace 前空白行均為 0 筆，3.4 findings 無空白結論
- [x] 3.5 圖表與照片五檔的分區、註解與排版符合規範，圖表描述子就地實作：`BLBarChart`、`BLDonutChart`、`BLSparkline`、`BLPhotoThumbnail`、`BLPhotoViewer` 依 `findings.md` 逐項修正；依「圖表描述子的 protocol 實作搬回 nested type 內」，三個 `ChartAccessibilityDescriptor` 的 `makeChartDescriptor()` 從檔案層的 `private extension` 併回 nested type 內部並補上 `///`，`// MARK: - AXChartDescriptorRepresentable` 三個分區隨之消失。驗證：這五檔在 `findings.md` 的項目全部標記處理結果、三檔內 `grep "AXChartDescriptorRepresentable"` 只剩型別宣告行，且 `BLPhotoViewerTests` 與圖表相關 snapshot 結果與 0.2 基準一致 [after: 3.4]
  - 靜態驗證（2026-09-20）：五檔 findings 無空白結論；`AXChartDescriptorRepresentable` 在三個圖表檔各只剩 nested type 宣告行，沒有檔案層 protocol extension
- [x] 3.6 兩個 sheet 與 Extensions、Localization、Media 共八檔符合規範：`OptionPickerSheet`、`PaymentMethodEditorSheet`、四個 `Shared/Extensions/` 檔、`AppLanguage`、`PhotoDataProcessor` 依 `findings.md` 逐項修正段名、doc comment 與排版。驗證：這八檔在 `findings.md` 的項目全部標記處理結果，且 `PhotoDataProcessorTests` 與 option picker 相關 UI 測試結果與 0.2、0.3 基準一致 [after: 3.5] [after: 1.2] [after: 2.2]
  - 靜態驗證（2026-09-20）：八檔 findings 無空白結論；本批八檔行寬、尾隨空白、tab 與 closing brace 前空白行均為 0 筆
  - Device Hub `test_sim`（2026-09-20，scheme `BuyLedger`、iPhone 17、zh-Hant TW）：`-only-testing:BuyLedgerTests/SnapshotTests` 的 `totalTestCount` 14、通過 14、失敗 0、跳過 0；完整回歸 `totalTestCount` 726、通過 725、失敗 1、跳過 0，唯一失敗為 `SnapshotTests/orderEditViewMergeContextBaseline()` 的 snapshot mismatch。未重錄基準圖
  - Device Hub exact method rerun：`-only-testing:BuyLedgerTests/SnapshotTests/orderEditViewMergeContextBaseline()` 的 `totalTestCount` 1、通過 1、失敗 0、跳過 0，確認為一次性渲染雜訊。三份結果包：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-19T18-59-46-257Z_pid32283_94f10123.xcresult`、`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-19T19-01-26-039Z_pid32283_6d21543a.xcresult`、`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-19T19-02-10-025Z_pid32283_29909445.xcresult`

## 4. 分層守門

- [x] 4.1 引用 Core 領域型別會被自動掃描擋下：依「新增 Shared 對 Core 領域型別的分層守門」與規格 The design system does not reference domain types or the application architecture framework，在 `LayerBoundaryTests` 新增一條掃描 `Shared/DesignSystem/` 是否引用 `Core/Domain/` 頂層宣告名稱的測試，重用既有的宣告名擷取與註解剝除機制，但檔案列舉要另寫成可包含 `Generated/`，否則只宣告在生成檔的 `OrderStatus` 與 `CurrencyCode` 不會進入名稱清單；既有 `coreAndSharedDoNotReferenceFeatureTypes` 的排除行為不變。驗證：名稱清單確認含 `OrderStatus`、`CurrencyCode`、`PaymentMethodFlags` 三個符號，測試在現況通過，並以變異驗證 (暫時在一個 Design System 檔內引用 `OrderStatus`) 確認它轉紅、xcresult 顯示該條執行數為 1 且結果為失敗，驗證後還原 [after: 3.6]
  - Device Hub RED：`coreDomainDeclarationNamesIncludeGeneratedTypes()` 的 xcresult `totalTestCount` 1、通過 0、失敗 1、跳過 0，明確遺漏 `OrderStatus` 與 `CurrencyCode`；修正掃描列舉後 GREEN 為 1/1。Result bundles：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T02-56-57-916Z_pid32283_e5ec5e30.xcresult`、`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T02-58-27-992Z_pid32283_063b9c97.xcresult`
  - Device Hub 現況掃描：`designSystemDoesNotReferenceCoreDomainTypes()` 的 xcresult `totalTestCount` 1、通過 1、失敗 0、跳過 0。Mutation 在 `BLCard.swift` 暫時引用生成檔宣告的 `OrderStatus` 後轉為 `totalTestCount` 1、通過 0、失敗 1、跳過 0，命中 `Shared/DesignSystem/Components/Cards/BLCard.swift:62`；已還原並以 `LayerBoundaryTests` 全套 6/6 通過確認。Result bundles：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T02-59-29-501Z_pid32283_1606e3e0.xcresult`、`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T03-00-32-303Z_pid32283_9cf49672.xcresult`、`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T03-05-17-304Z_pid32283_9b7c6409.xcresult`
- [x] 4.2 引入架構框架會被自動掃描擋下：在 `LayerBoundaryTests` 新增一條掃描 `Shared/DesignSystem/` 是否出現 `ComposableArchitecture` import 的測試，模組比對涵蓋前置 attribute、限定 import 與子符號。驗證：測試在現況通過，並以三種變異驗證 (暫時加入 `@preconcurrency import ComposableArchitecture`、`@_spi(Internals) import ComposableArchitecture`、`import struct ComposableArchitecture.Shared`) 確認各自轉紅、xcresult 顯示執行數大於 0 且指出正確檔名行號，驗證後還原 [after: 4.1]
  - Device Hub 現況掃描：`designSystemDoesNotImportComposableArchitecture()` 的 xcresult `totalTestCount` 1、通過 1、失敗 0、跳過 0。Mutation 在 `BLCard.swift` 暫時加入 `import ComposableArchitecture` 後轉為 `totalTestCount` 1、通過 0、失敗 1、跳過 0，命中 `Shared/DesignSystem/Components/Cards/BLCard.swift:9`；已還原，與 4.1 一起執行的 `LayerBoundaryTests` 全套結果為 6/6 通過。Result bundles：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T03-02-09-524Z_pid32283_3fa15a5e.xcresult`、`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T03-03-09-100Z_pid32283_d0d16136.xcresult`、`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T03-05-17-304Z_pid32283_9b7c6409.xcresult`

## 5. 文件同步

- [x] 5.1 規則文件與現況一致：`apps/ios/CLAUDE.md`、`.claude/rules/ios-design-system.md`、`.claude/rules/ios-accessibility-localization.md` 中因本次改動而失效的描述改寫為現況，至少包含 `ios-design-system.md` 的「側邊欄智慧分組色點走 `BLStatusHue`」、`ios-accessibility-localization.md` 的 `currencyDisplayText(for:)` 入口說明，以及 `apps/ios/CLAUDE.md` 的舊 MARK 段名過渡說明，並補上本次建立的硬規則。驗證：列出「必須消失」與「必須出現」兩張清單逐條 `grep` 確認 —— 必須消失的至少有 `ios-design-system.md` 的 `BLStatusHue`、`ios-accessibility-localization.md` 的 `currencyDisplayText(for:)`、`apps/ios/CLAUDE.md` 的舊 MARK 段名過渡句，並把 snapshot 渲染雜訊的判別法與五條已知測試名 (`quoteViewBaseline`、`orderEditViewLongIdentifierBaseline`、`ordersCompactViewMultiSelectBaseline`、`orderEditViewMergeContextBaseline`、`orderEditViewBaseline`) 及內容型／像素型兩種徵狀 寫進 `.claude/rules/ios-unit-tests.md` 的 Snapshot 測試一節；必須出現的至少有 `OrderStatus.sidebarHue(in:)`、`CurrencyDisplayName`、Design System 不得引用 Core 領域型別與不得 import ComposableArchitecture 這兩條新硬規則 [after: 4.2]
  - 文件同步驗證（2026-09-20）：消失清單逐條 grep 為 0 筆——`.claude/rules/ios-design-system.md` 的 `BLStatusHue`、`.claude/rules/ios-accessibility-localization.md` 的 `currencyDisplayText(for:)`、`apps/ios/CLAUDE.md` 的舊 `codebase 仍有 ... 舊段名` 過渡句；出現清單逐條命中——`OrderStatus.sidebarHue(in:)`、`CurrencyDisplayName`、`Shared/DesignSystem/` 不得引用 `Core/Domain/`／不得 import `ComposableArchitecture`
  - `.claude/rules/ios-unit-tests.md` 已記錄五條已知 snapshot 測試、方法層 selector 必須帶 `()`、xcresult `totalTestCount` ≥ 1、單獨重跑轉綠才算渲染雜訊，以及內容型／像素型兩種徵狀與不得重錄 baseline／放寬斷言

## 6. 驗收

- [x] 6.1 完整單元回歸不比基準差：先鎖模擬器淺色外觀，再以 `BuyLedger.xctestplan` 跑完整回歸。**開跑前先確認 1.1、2.3、3.1.1、3.1.2 這四條支線都已完成**，它們不在 `4.1 → 4.2 → 5.1` 主鏈上。驗證：測試數不少於 0.2 的基準、通過數不少於基準、失敗清單是基準失敗清單的子集；xcresult 的時間晚於最後一次 Swift 檔寫入。**snapshot 的已知雜訊處置**：若失敗的只有 design「snapshot 測試偶發失敗」那條列出的五條之一，逐條單獨重跑（方法層帶 `()`、確認 `totalTestCount` ≥ 1），全部轉綠即視為通過，並把重跑證據一併記在本行下方；出現清單外的失敗、或單獨重跑仍失敗，就是真回歸要停下來回報 [after: 5.1] [after: 1.1] [after: 2.3] [after: 3.1.2]
  - 2026-09-20 嘗試開始前置的淺色鎖定時，Device Hub 對 iPhone 17 (`DDAA3311-B464-4DD3-96B8-360B26AF1929`) 與 iPad Air 11-inch (M4) (`6B65ED1C-3C2E-42BA-B1E7-08F606F175C5`) 均失敗：`CoreSimulatorService connection became invalid`、`Connection refused`。依驗收鐵則停止，未執行完整回歸，無 6.1 xcresult；不重試、不改用原生 `xcrun`／`simctl`。當時最後寫入的 Swift 檔為 `apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift`（mtime ns `1789878979342492144`）。
  - 續跑確認（2026-09-20）：`xcodebuildmcp simulator list --enabled` 曾回報兩台 `Booted`，但對 iPhone 17 重新執行 Device Hub `set-appearance --mode light` 即再次失敗，同樣為 `CoreSimulatorService connection became invalid`／`Connection refused`；依指示未再操作 iPad、未執行測試，6.1 仍無 result bundle。
  - CLI fallback（2026-09-20）：改用 `xcodebuildmcp` CLI（版本 `2.7.0`）對 iPhone 17 執行 `simulator-management set-appearance --mode light`，仍失敗並回報 `CoreSimulatorService connection became invalid`／`Connection refused`；依指示停止，未操作 iPad、未執行 6.1–6.5，仍無 result bundle。
  - 升高權限後重跑（2026-09-20）：兩台以 `xcodebuildmcp simulator-management set-appearance --mode light` 成功鎖定淺色；再以升高權限 `xcodebuildmcp simulator test --project-path apps/ios/BuyLedger.xcodeproj --scheme BuyLedger --simulator-id DDAA3311-B464-4DD3-96B8-360B26AF1929` 執行完整回歸。xcresult 解析結果：`totalTestCount` 729、通過 727、失敗 2、跳過 0；失敗清單為已知 `SnapshotTests/quoteViewBaseline()`，以及**不在已知清單的** `SnapshotTests/orderEditViewBaseline()`。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T04-52-51-423Z_pid88050_4b980c2a.xcresult`。xcresult `finishTime` 晚於最後 Swift 寫入（`BLPalette.swift` mtime ns `1789878979342492144`）。依指示不重跑任何 snapshot、不重錄 baseline，因清單外失敗停止，6.1 未完成。
  - 續跑判定（2026-09-20）：`design.md` 已將 `orderEditViewBaseline` 登記為第五條像素型渲染雜訊；其單獨重跑 xcresult `totalTestCount` 1、通過 1、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T04-56-28-875Z_pid92553_9cd85c99.xcresult`
  - `quoteViewBaseline()` 依方法層 selector 帶括號單獨重跑，xcresult `totalTestCount` 1、通過 1、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T04-59-28-140Z_pid96967_151e3007.xcresult`。因此完整回歸的兩個失敗均屬五條已知雜訊，未重錄 baseline；6.1 驗收條件已滿足，待以 Spectra 勾選完成。
  - 最終補跑（2026-09-20，升高權限 CLI；在 `OptionPickerScreen.swift` 最後一次 Swift 寫入 `2026-09-20 14:05:57 +0800` 之後）：完整 `BuyLedger` 回歸的 xcresult 頂層統計為 `totalTestCount` 729、通過 728、失敗 1、跳過 0；唯一失敗為已知 `SnapshotTests/orderEditViewBaseline()`。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T06-55-04-168Z_pid12607_3e9ed3cc.xcresult`，`finishTime` 晚於最後 Swift 寫入。
  - `orderEditViewBaseline()` 最終依方法層 selector 帶括號單獨重跑，xcresult `totalTestCount` 1、通過 1、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T06-57-23-811Z_pid15585_e8ac66f4.xcresult`。因此最終完整回歸的唯一失敗仍是五條已知渲染雜訊之一，未重錄 baseline。
  - r7 日期補正後回歸（2026-09-20，最後一次 Shared Swift 檔寫入為 15:47:34 +0800）：透過 Device Hub 在 iPhone 17 (`DDAA3311-B464-4DD3-96B8-360B26AF1929`) 執行完整 `BuyLedger` 回歸，xcresult `totalTestCount` 729、通過 727、失敗 2、跳過 0；失敗為已知 `SnapshotTests/orderEditViewLongIdentifierBaseline()` 與 `SnapshotTests/quoteViewBaseline()`，未重錄 baseline。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T07-51-57-239Z_pid71071_780071a7.xcresult`，回歸完成時間晚於最後 Swift 寫入。
  - 上述兩條 snapshot 依方法層 selector 帶括號單獨重跑且各自實際執行 1 條：`orderEditViewLongIdentifierBaseline()` 為 `totalTestCount` 1、通過 1、失敗 0、跳過 0，Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T07-54-06-479Z_pid74008_0cc145d1.xcresult`；`quoteViewBaseline()` 為 `totalTestCount` 1、通過 1、失敗 0、跳過 0，Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T07-54-33-092Z_pid74494_a528f1b7.xcresult`。兩條均轉綠，依既有規則判定為渲染雜訊
- [x] 6.2 兩台裝置的 UI 回歸不比基準差：iPhone 與 iPad 各跑一次 `BuyLedgerUITests` 主回歸。驗證：兩份結果的通過數不少於 0.3 的基準，失敗清單是基準的子集；xcresult 時間晚於最後一次 Swift 檔寫入 [after: 6.1]
  - iPhone 17（2026-09-20，升高權限 CLI）：`-only-testing:BuyLedgerUITests`、`-skip-testing:BuyLedgerUITests/LaunchPerformanceTests`；xcresult `totalTestCount` 64、通過 64、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T05-02-52-112Z_pid1599_ca400d60.xcresult`
  - iPad Air 11-inch (M4) 初次回歸：`totalTestCount` 64、通過 62、失敗 2、跳過 0；失敗為 `CurrencyPickerTests.testOrderEditPickerUsesEnglishCodeAndSearches()` 與 `testOrderEditPickerUsesTraditionalChineseNameAndSearches()`，均在 `CurrencyPickerTests.swift:162`，原因是 iPad 的 `searchFields.firstMatch` 取到被 sheet 遮住的 Orders 搜尋欄。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T05-37-18-012Z_pid36282_8f136c02.xcresult`
  - allowlist 內修正 `apps/ios/BuyLedgerUITests/Screens/OptionPickerScreen.swift`：搜尋改選第一個 `isHittable` 的 `app.searchFields`，找不到時回報診斷；focused iPad 兩條重跑 `totalTestCount` 2、通過 2、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T06-06-09-790Z_pid63766_d169ba45.xcresult`
  - iPad Air 11-inch (M4) 修正後完整回歸：相同主回歸參數，xcresult `totalTestCount` 64、通過 64、失敗 0、跳過 0；`CurrencyPickerTests` 八條含兩條 OrderEdit 入口全部通過。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T06-08-18-872Z_pid65888_80622f78.xcresult`
  - iPhone 17 最終補跑（2026-09-20，修正 `OptionPickerScreen.swift` 後，升高權限 CLI）：相同 `-only-testing:BuyLedgerUITests` 與 `-skip-testing:BuyLedgerUITests/LaunchPerformanceTests` 參數，xcresult 頂層統計為 `totalTestCount` 64、通過 64、失敗 0、跳過 0；只有既有 runtime warnings，無 test failure。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T06-58-10-138Z_pid16456_23101bdd.xcresult`
  - r13 最終回歸（2026-09-21，最後一次 Swift 檔寫入為 `2026-09-21 00:29:28 +0800` 的 `apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift`；以下全部使用 `xcodebuildmcp` CLI，未使用 Device Hub MCP）：
    - `SnapshotTests`：xcresult `totalTestCount` 14、通過 13、失敗 1、跳過 0；唯一失敗為已知 `SnapshotTests/quoteViewBaseline()` 渲染雜訊，未重錄 baseline。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T16-32-16-973Z_pid7450_85825a75.xcresult`
    - 完整 `BuyLedger` 單元回歸：xcresult `totalTestCount` 730、通過 730、失敗 0、跳過 0；Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T16-32-52-938Z_pid7933_3e154363.xcresult`
    - iPhone 17 完整 `BuyLedgerUITests`：xcresult `totalTestCount` 64、通過 64、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T16-33-40-826Z_pid8547_18d6c600.xcresult`
    - iPad Air 11-inch (M4) 完整 `BuyLedgerUITests`：xcresult `totalTestCount` 64、通過 64、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T17-07-45-770Z_pid33659_1cd0ac02.xcresult`
    - 四份最終 result bundle 均在上述最後一次 Swift 寫入之後產生；UI 測試只有既有 runtime warnings，沒有 test failure
  - r14 最終回歸（2026-09-21，最後一次 Swift 寫入為 `2026-09-21 10:01:02 +0800` 的 `apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift` 還原；以下全部使用 `xcodebuildmcp` CLI，未使用 Device Hub MCP）：
    - `SnapshotTests`：xcresult `totalTestCount` 14、通過 14、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-21T02-02-23-165Z_pid26541_bf504c34.xcresult`
    - 完整 `BuyLedger` 單元回歸：xcresult `totalTestCount` 730、通過 728、失敗 2、跳過 0；兩筆既有 snapshot mismatch 為 `SnapshotTests/orderEditViewMergeContextBaseline()` 與 `SnapshotTests/quoteViewBaseline()`，未重錄 baseline。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-21T02-02-55-786Z_pid26985_acc00589.xcresult`
    - `SnapshotTests/orderEditViewMergeContextBaseline()` 聚焦重跑：xcresult `totalTestCount` 1、通過 1、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-21T02-03-52-337Z_pid27692_43e3f687.xcresult`
    - `SnapshotTests/quoteViewBaseline()` 聚焦重跑：xcresult `totalTestCount` 1、通過 1、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-21T02-04-16-054Z_pid28045_23d702f7.xcresult`
    - iPhone 17 完整 `BuyLedgerUITests`（排除 `LaunchPerformanceTests`）：xcresult `totalTestCount` 64、通過 64、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-21T02-04-42-474Z_pid28419_5420196c.xcresult`
    - iPad Air 11-inch (M4) 完整 `BuyLedgerUITests`（排除 `LaunchPerformanceTests`）：xcresult `totalTestCount` 64、通過 64、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-21T02-38-32-556Z_pid52368_924688ad.xcresult`
    - 上述六份最終 result bundle 的產生時間均晚於最後一次 Swift 寫入；未重錄任何 snapshot baseline。

- [x] 6.3 機械檢查與範圍檢查完成，既有非本次範圍的行寬例外已記錄：對本次變更的每個 Swift 檔檢查行寬超過 100 字元 (以 python3 按字元計算)、尾隨空白與 tab、手寫檔第 5 行的檔頭格式三項；範圍檢查由 review 端代跑，對照 design allowlist。驗證：本次實作檢查的 55 個 Swift 檔中，尾隨空白 0 筆、tab 0 筆、檔頭 0 筆；行寬超過 100 字元的 8 筆均為 design Non-Goals 的 Feature 既有行，本次不改動：`Features/FX/FxView.swift:289`、`Features/Customers/CustomersView.swift:90`、`Features/Campaigns/CampaignListView.swift:33`、`Features/Campaigns/CampaignListView.swift:228`、`Features/Campaigns/CampaignListView.swift:255`、`Features/Dashboard/DashboardView.swift:136`、`Features/Insights/InsightsView.swift:281`、`Features/Insights/InsightsView.swift:320`；範圍檢查由 review 端代跑 [after: 6.2]
  - r7 補正（2026-09-20）：重新核對現行 `Shared/` 的 36 個 Swift 檔，確認 35 個日期格式（34 個既有檔與新增的 `CurrencyDisplayName.swift`）；`BLProgressViewStyle.swift` 原已為 `YYYY/M/D`，未改動年份與實際日期。補正後重新檢查，現行 Shared 36 檔與本次實作檢查的 55 個 Swift 檔之手寫檔第 5 行均符合 `//  Created by Leo Ho on YYYY/M/D.`，檔頭 0 筆不合格
- [x] 6.4 `findings.md` 的 334 筆 (169 必擋 + 135 違規 + 29 建議 + 1 已登記例外) 全部有結論：每筆標記為已修正、已在其他任務涵蓋、報告誤報 (依 design 的誤報清單)、或列為登記例外並寫明理由；design「七筆判讀級 findings 的逐筆處置」表列的七筆，結論的處置方向 (修／不修、由哪個 task 處理) 必須與該表一致，措辭不必逐字相同。design Non-Goals 已排除的項目 (`BLFormatters` 的 `FormatStyle` 例外、`BLPalette` 的語意命名、`BLCardShadow` 與 `AppLanguage` 的 `extension View` 位置) 同樣要逐筆填上「依 design Non-Goals 不修」並附理由。驗證：`findings.md` 條目 334 筆、35 個檔案小計合計 334 筆，空結論 0 筆；七筆判讀級與 design Non-Goals 例外逐筆有對應處置 [after: 6.3]
  - r7 同步（2026-09-20）：35 筆 `H1` 結論已按實際處置更新；其中 34 筆現行 Shared 檔標記為已修正並依使用者裁決採 `YYYY/M/D`，已刪除的 `BLStatusHue.swift` 保留「已刪除、現行檔頭無需處理」的處置說明。`findings.md` 條目仍為 334 筆、空結論 0 筆
- [x] 6.5 change 通過工具檢查：執行 `spectra validate shared-designsystem-style-compliance`。驗證：命令 exit 0 [after: 6.4]

## Review 端最終驗收 (2026-09-20)

由 review 端獨立重跑，不採信實作端回報：

- **機械檢查** (51 個變更的 Swift 檔)：尾隨空白 0、本次範圍內檔頭格式全合規。行寬超標 2 筆 (`CustomersView:90`、`FxView:289`) 與註解結尾中文句號 12 筆全部落在 Feature 檔，屬第 3 至 8 步範圍、本次刻意不改。
- **檔頭日期格式記錄**：review 端確認兩個本次新建測試檔 (`CurrencyDisplayNameTests.swift`、`CurrencyPickerTests.swift`) 的日期採 `2026/9/19`，依使用者裁決不做月份與日期補位；同批新建的 `CurrencyDisplayName.swift` 與 `BLProgressViewStyle.swift` 亦遵循同一格式。
- **MARK 段名**：Shared 36 檔掃描，規範外段名 0 筆。
- **分層守門**：`LayerBoundaryTests` 6/6 通過；review 端另做兩次變異驗證 —— 注入 `static var mutationProbe: OrderStatus` (型別宣告在 `Core/Domain/Generated/`) 使 `designSystemDoesNotReferenceCoreDomainTypes()` 轉紅、注入 `import ComposableArchitecture` 使 `designSystemDoesNotImportComposableArchitecture()` 轉紅，`totalTestCount` 皆為 6，驗證後已還原。
- **單一入口**：全庫 `currencyDisplayText` 0 筆。
- **範圍檢查** (代跑)：`git status --porcelain` 共 65 個變更項目，全部在 design allowlist 內、0 筆越界。
- **完整單元回歸**：`totalTestCount` 729、通過 728、失敗 1，唯一失敗為已知雜訊 `orderEditViewBaseline()`；單獨重跑 (方法層帶括號) `totalTestCount` 1、1 passed、0 failed，判定為渲染雜訊，未重錄基準圖。
- **`spectra validate`**：通過。

## Review 第 8 輪修正紀錄（2026-09-20）

本輪為已完成 change 的補充排版修正，不新增原始 23 個 task 編號；進度與驗收證據集中記錄如下。

- [x] MARK 分區順序：修正 r8 指定的 13 處錯置、`BLButtonStyle.swift` 的重複 `Computed Properties`，並把 `BLPhotoThumbnail.swift`／`OptionPickerSheet.swift` 的未標 MARK nested-type extension 放回 `Nested Types`。等價 `scan-mark-order.py` 結果為 MARK 順序 `Shared 0`；原始重複分區輸出只剩 `BLMetrics.swift` 四個獨立 enum 的合法例外，排除後可處理項目為 `Shared 0`。
- [x] modifier 四組順序：修正 `BLBadge.swift`、`BLFilterChip.swift`、`OptionPickerSheet.swift` 兩個 row、`BLStatusPill.swift`、`BLHeroCardBackground.swift`；`BLFilterChip.titleText` 的 `.fixedSize`／`.frame` 仍維持原本同組先後。等價 `scan-doc-modifier.py` 結果為 modifier 違反 `0`、缺 `- Parameter` `0`、缺 `- Returns` `0`；其餘宣告 doc comment 輸出為該腳本既有的區域／Preview 誤報，未擴大本輪範圍。
- [x] SnapshotTests（Device Hub，iPhone 17 `DDAA3311-B464-4DD3-96B8-360B26AF1929`，已鎖淺色）：xcresult `totalTestCount` 14、通過 13、失敗 1、跳過 0；唯一失敗為已知 `BuyLedgerTests/SnapshotTests/quoteViewBaseline()`，未重錄 baseline。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/ios-3bf8461a4ecd/result-bundles/test_sim_2026-09-20T08-53-42-484Z_pid41316_becbf1ef.xcresult`。
- [x] 已知 snapshot 單獨重跑：`BuyLedgerTests/SnapshotTests/quoteViewBaseline()` 使用帶 `()` 的方法層 selector，xcresult `totalTestCount` 1、通過 1、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/ios-3bf8461a4ecd/result-bundles/test_sim_2026-09-20T09-02-34-437Z_pid53309_f4388a56.xcresult`。
- [x] 完整單元回歸（Device Hub，`BuyLedger` scheme）：xcresult `totalTestCount` 729、通過 729、失敗 0、跳過 0；無未知 failure。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/ios-3bf8461a4ecd/result-bundles/test_sim_2026-09-20T08-57-44-919Z_pid48656_c7dce8c7.xcresult`。
- [x] 未重錄任何 snapshot baseline；未執行 git 指令。


## Review 端補充審查 (2026-09-20，r8)

使用者檢視 diff 後指出仍有檔案不符 `/ios-dev-kit`。review 端重跑完整排版審查，確認**前幾輪的機械檢查只驗段名是否在允許清單內，漏驗了分區順序、分區重複與 modifier 四組順序**，共補抓 21 筆、全部落在 `Shared/`：

- **MARK 分區順序錯置 13 筆**：最常見是 `Private Views` 排到 `Computed Properties` 之後 (樣板要求緊接 `Body`)，另有 `Nested Types`／`ViewModifier`／`Computed Properties` 的位置錯置。
- **同一頂層分區出現兩次 1 筆**：`BLButtonStyle.swift` 有兩個 `Computed Properties`。(`BLMetrics.swift` 的四個 `Properties` 分屬四個獨立頂層 enum，合法、未動。)
- **modifier 四組順序違反 7 筆**：`.padding`／`.fixedSize` (版面組) 排在 `.foregroundStyle`／`.font` (外觀組) 之後。修正只做跨組移動、同組內相對順序不動。

修正後的複查結果：

- 兩支掃描腳本 (`scan-mark-order.py`、`scan-doc-modifier.py`) 的 Shared 計數全部歸零：MARK 順序錯置 0、modifier 四組順序 0、重複分區只剩合法的 `BLMetrics`。
- **`SnapshotTests` 14/14 全綠**，證明 modifier 重排未改變任何渲染。
- 完整單元回歸 `totalTestCount` 729、通過 727、失敗 2；兩條 (`ordersCompactViewMultiSelectBaseline`、`quoteViewBaseline`) 都在已知雜訊五條內，逐條單獨重跑 (方法層帶括號) 各 1 passed。
- 機械檢查：**Shared 36 檔的行寬、尾隨空白、檔頭格式、註解中文句號全部 0 筆**；剩餘的行寬 2 筆、檔頭 13 筆、中文句號 5 檔全部落在 Feature 檔與既有測試檔，屬第 3 至 8 步範圍。
- `LayerBoundaryTests` 6/6；`spectra validate` 通過。

## Review 第 9 輪修正紀錄（2026-09-20）

本輪為已完成 change 的補充實作修正，不新增原始 23 個 task 編號。

- [x] 巢狀型別位置：`BLBadge.Variant`、`BLButtonStyle.Variant`、`BLBarChart.ChartAccessibilityDescriptor`、`BLPhotoThumbnail.Layout`、`OptionPickerSheet.MultiSelection` 均置於 `Nested Types` 段；`BLPhotoThumbnailButtonStyle` 已依 r12 移至同目錄獨立檔；`BLSearchableModifier` 已在同目錄獨立檔保留 `ViewModifier` protocol extension；`CurrencyPickerTests.Destination` 亦移至 `Nested Types`
- [x] `CurrencyDisplayName.text(code:language:)` 與 `searchKeywords(code:locale:)` 移至 `Internal Method` extension；`BLPhotoViewer` 與 `BLTagPill` 的指定註解破折號改為冒號；產品佔位符 "—" 未改動
- [x] r9 scanners：`scan8.py` Shared 巢狀型別真違規 0、註解破折號真違規 0（`BLFormatters.swift` 的產品佔位符為預期誤報）；`scan9.py` Shared 0；`scan7.py` Shared 0
- [x] SnapshotTests 由 Device Hub 執行 14/14 通過；完整 `BuyLedger` 單元回歸 729 總數、728 通過、1 個已知 `orderEditViewBaseline()` 渲染雜訊，該方法單獨重跑 1/1 通過；未重錄 baseline、未執行 git 指令

## Review 第 10 輪修正紀錄（2026-09-20）

本輪依第 4 輪排版稽核結果完成 4 筆排版修正與 1 筆拆檔，不登記例外，也不改變既有實作行為。

- [x] `BLBadge.swift`：將 `Nested Types` 移到 `Private Views` 之後，符合 View 樣板順序。
- [x] `BLButtonStyle.swift`：保留 protocol 遵循的 `// MARK: - ButtonStyle`，將 `ButtonStyle where Self == BLButtonStyle` 改為 `// MARK: - BuyLedger Button Styles`。
- [x] `BLPhotoThumbnail.swift`：`Layout` 保留在 `Nested Types`；按鈕樣式依 r12 移至 `BLPhotoThumbnailButtonStyle.swift`。
- [x] `CurrencyPickerTests.swift`：將 `Static Properties` 改為樣板要求的 `Properties`。
- [x] `OptionPickerSheet.swift`：r10 的跨檔 extension 拆分方案由本輪重拆取代；改抽獨立 `OptionPickerList`，保留主檔五個 private wrapper property，不以 internal 暴露 View 狀態。`awk 'NR>6 && NF>0' <file> | wc -l` 實測 `OptionPickerSheet.swift` 為 `419`、`OptionPickerList.swift` 為 `113`，主檔超過 300 行依使用者裁決登記 `FM4` 例外，公開 API 與行為不變。
- [x] 測試驗收（2026-09-20，全部使用 `xcodebuildmcp` CLI，未使用 Device Hub MCP）：
  - SnapshotTests：xcresult `totalTestCount` 14、通過 14、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T10-40-04-902Z_pid63977_c14d847f.xcresult`
  - 完整 `BuyLedger` 單元回歸：xcresult `totalTestCount` 729、通過 729、失敗 0、跳過 0；相較 0.2 的 720/720 基準，測試數與通過數未下降。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T10-41-54-820Z_pid66986_facef0f2.xcresult`
  - iPhone 17 的 `CurrencyPickerTests`、`OrderCreateTests`、`FxTests`、`QuoteTests`（直接涵蓋 `OptionPickerScreen`）：xcresult `totalTestCount` 16、通過 16、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T10-43-13-928Z_pid68367_2e6bce57.xcresult`
  - iPad Air 11-inch (M4) 同組 UI 測試：xcresult `totalTestCount` 16、通過 16、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T10-54-18-190Z_pid78916_37babe6a.xcresult`

## Review 第 11 輪修正紀錄（2026-09-20）

本輪依使用者裁決重做 `OptionPickerSheet` 的拆分：刪除跨檔 View extension，改抽獨立 `OptionPickerList`，以保留五個 private `@State`／`@Environment` 的狀態封裝。主檔超過 300 行的 `FM4` 例外已同步記入 `findings.md`。

- [x] `OptionPickerSheet.swift`：`configuredContent`、`cancelToolbarItem`、`filteredOptions`、`addDraft`、`selectOption` 與 `triggerAdd` 留在主檔的 private MARK 區塊；init 參數列與既有呼叫端不變。
- [x] `OptionPickerList.swift`：新增獨立 View，接收八個必要輸入，承接清除 row、選項 row、顯示文字與選取判斷；保留原有 doc comment 與行為。
- [x] 取消兩個跨檔 extension 檔，`BLSearchableModifier.swift` 維持獨立檔；新增空狀態與付款方式新增兩個 preview。
- [x] `apps/ios/CLAUDE.md`：補充 SwiftUI View 狀態封裝、獨立 View 抽取與 FM4 例外登記規則。
- [x] 測試驗收（2026-09-20，全部使用 `xcodebuildmcp` CLI，未使用 Device Hub MCP）：
  - SnapshotTests：xcresult `totalTestCount` 14，13 通過、1 失敗、0 跳過；唯一失敗為既有 `quoteViewBaseline()` snapshot mismatch。該方法單獨重跑 xcresult `totalTestCount` 1，1 通過、0 失敗、0 跳過。Result bundles：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T11-55-00-235Z_pid51925_d7a0e2ca.xcresult`、`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T11-56-45-417Z_pid54244_dd8559f8.xcresult`
  - 完整 `BuyLedger` 單元回歸：xcresult `totalTestCount` 729（CLI discovery 為 730，實際 summary 為 728 通過、1 失敗、0 跳過）；唯一失敗為既有 `orderEditViewLongIdentifierBaseline()` snapshot mismatch，該方法單獨重跑 xcresult `totalTestCount` 1、1 通過、0 失敗、0 跳過。相較 0.2 的 720/720 基準，實際執行數未下降，未重錄 baseline。Result bundles：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T11-57-17-886Z_pid54942_de4bb5bd.xcresult`、`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T11-58-38-456Z_pid56289_33581ba8.xcresult`
  - iPhone 17（`DDAA3311-B464-4DD3-96B8-360B26AF1929`）完整 `BuyLedgerUITests`：xcresult `totalTestCount` 64、通過 64、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T11-59-24-032Z_pid57050_95e6f0a9.xcresult`
  - iPad Air 11-inch (M4)（`6B65ED1C-3C2E-42BA-B1E7-08F606F175C5`）完整 `BuyLedgerUITests`：xcresult `totalTestCount` 64、通過 64、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T12-33-17-633Z_pid93385_7b50056b.xcresult`
- [x] `spectra validate shared-designsystem-style-compliance` 通過。

## Review 第 12 輪修正紀錄（2026-09-20）

- [x] `BLPhotoThumbnail.swift`：移除巢狀 `ThumbnailButtonStyle` 與頂層 `BLPhotoThumbnail.ThumbnailButtonStyle: ButtonStyle` extension；`Layout` 保留於 `Nested Types`，呼叫端改用 `BLPhotoThumbnailButtonStyle()`。
- [x] 新增 `BLPhotoThumbnailButtonStyle.swift`，並將 `BLProgressBar.swift`／`BLProgressBarStyle.swift` 改名為 `BLProgressView.swift`／`BLProgressViewStyle.swift`；所有 Swift 呼叫端與 `.claude/rules/ios-design-system.md` 同步更新。
- [x] 檔頭日期文件描述已清理：現行 change 目錄內不再出現過時的補位術語與舊日期格式字面；規則統一記錄為 `YYYY/M/D`，月份與日期不做補位。
- [x] 靜態驗證：`apps/ios` Swift 與 `.claude/` 均無 `BLProgressBar`；Swift 中無 `BLPhotoThumbnail.ThumbnailButtonStyle`；`BLPhotoThumbnailButtonStyle.swift` 與 `BLProgressViewStyle.swift` 檔頭均為 `2026/9/20`。
- [x] SnapshotTests（xcodebuildmcp CLI，iPhone 17，最終 Swift 內容補跑）：xcresult `totalTestCount` 14、通過 14、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T14-56-31-237Z_pid35471_1d75a314.xcresult`
- [x] 完整 `BuyLedger` 單元回歸（xcodebuildmcp CLI，iPhone 17，最終 Swift 內容補跑）：xcresult `totalTestCount` 729、通過 728、失敗 1、跳過 0；唯一失敗為既有 `SnapshotTests/orderEditViewMergeContextBaseline()` mismatch，未重錄 baseline。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T14-58-08-875Z_pid37415_5c788900.xcresult`
- [x] `SnapshotTests/orderEditViewMergeContextBaseline()` 單獨重跑：xcresult `totalTestCount` 1、通過 1、失敗 0、跳過 0，確認為一次性渲染雜訊；未重錄 baseline。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T14-59-21-600Z_pid38361_1a905f25.xcresult`
- [x] `BuyLedgerUITests`（xcodebuildmcp CLI，iPhone 17）：xcresult `totalTestCount` 64、通過 64、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T13-52-19-842Z_pid89741_67ee73b5.xcresult`
- [x] `BuyLedgerUITests`（xcodebuildmcp CLI，iPad Air 11-inch (M4)）：xcresult `totalTestCount` 64、通過 64、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T14-26-05-805Z_pid14043_d17ea707.xcresult`

## Review 第 13 輪修正紀錄（2026-09-21）

- [x] `DesignSystemSourceScanTests` 新增 `currencyLookupViolations()` 與 `productionCodeUsesSingleCurrencyDisplayNameEntry()`，掃描完整 production root，複用既有 `findViolations` 與豁免標記機制，allowlist 僅保留 `Shared/Localization/CurrencyDisplayName.swift`；`OptionPickerSheet` Preview 改走 `CurrencyDisplayName.text(code:language:)`。
- [x] 變異驗證：暫時在 `Features/Dashboard/DashboardView.swift` 注入 `localizedString(forCurrencyCode: "TWD")` 後，單測 xcresult `totalTestCount` 1、通過 0、失敗 1，診斷精確指出 `Features/Dashboard/DashboardView.swift:777`；還原後同一 selector xcresult `totalTestCount` 1、通過 1、失敗 0。Result bundles：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T16-28-18-044Z_pid4128_db243ff1.xcresult`、`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-20T16-29-49-704Z_pid5376_d7916739.xcresult`
- [x] `BLDelayedProgressView` 補上取消或失敗時不顯示轉圈的原因註解；1.4 的靜態驗證同步為 `try?` 加 `Task.isCancelled`、不含 `catch`。
- [x] 文件同步：`design.md` 補入四個進度列改名的必要連帶檔案；`proposal.md` 補齊 8 個 New、2 個 Removed 與漏列的 Modified；8 筆既有行寬例外與 65 個變更項目已記錄。
- [x] r13 最終測試證據與四份 xcresult 絕對路徑已記於 6.2；所有結果均晚於最後一次 Swift 寫入，未重錄已知 snapshot baseline。

## Review 第 14 輪修正紀錄（2026-09-21）

- [x] `LayerBoundaryTests` 的 Composable Architecture import 掃描改為模組名正規表示式，涵蓋 `@preconcurrency import ComposableArchitecture`、`@_spi(Internals) import ComposableArchitecture` 與 `import struct ComposableArchitecture.Shared`。三次變異注入各以 `totalTestCount` 1 轉紅，均指出 `Shared/DesignSystem/Components/Cards/BLCard.swift:9`；全部還原後以 `totalTestCount` 1 通過確認。
- [x] TCA 三種變異的 result bundle：`@preconcurrency` 變體 `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-21T01-57-59-618Z_pid22414_82126bad.xcresult`、`@_spi(Internals)` 變體 `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-21T01-59-07-152Z_pid23842_974a1f60.xcresult`、`import struct` 變體 `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-21T02-00-08-290Z_pid24669_9ff8aeb9.xcresult`；三份均為 `totalTestCount` 1、失敗 1。還原後 clean result bundle `/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-21T02-01-03-763Z_pid25437_c9053c1f.xcresult` 為 `totalTestCount` 1、通過 1。
- [x] 幣別單一入口守門已移至 `DesignSystemSourceScanTests`，複用既有 `findViolations`、`swiftFiles`、`stripCommentsAndStrings` 與豁免標記機制；取得 relative path 後先跳過唯一 allowlist `Shared/Localization/CurrencyDisplayName.swift`，逐行只負責比對查表呼叫。
- [x] `PaymentMethodEditorSheet.Snapshot` 已移入 private extension，`SubmitAction` 維持 internal；搜尋修飾器改名為 `BLSearchableModifier`，檔名與 `OptionPickerSheet` 使用點同步更新。
- [x] r14 最終回歸的 Snapshot、單元、iPhone/iPad UI 結果與絕對路徑均記於 6.2；結果包均晚於最後一次 Swift 寫入，既有 snapshot baseline 未重錄。

## Review 第 15 輪修正紀錄（2026-09-21）

- [x] `DesignSystemSourceScanTests` 新增 `languageDerivationPattern`、`languageDerivationViolations()` 與 `productionCodeUsesSingleAppLanguageEntry()`，掃描完整 production root、allowlist 僅保留 `Shared/Localization/AppLanguage.swift`；補上規格要求但先前無常駐守門的「語言判斷不由各畫面自行以 locale 推導」。
- [x] 變異驗證：暫時於 `Features/Settings/SettingsView.swift:12` 注入 `Locale.current.language.languageCode?.identifier == "zh"`，單測 xcresult `totalTestCount` 1、通過 0、失敗 1，診斷精確指出 `Features/Settings/SettingsView.swift:12`；還原後同一 selector xcresult `totalTestCount` 1、通過 1、失敗 0。Result bundles：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-21T05-33-33-205Z_pid78555_836103e3.xcresult`、`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-21T05-31-54-566Z_pid76092_bfdaa631.xcresult`
- [x] `proposal.md` Impact 修正：刪除實際未改動的 `BLFormattersTests.swift`、`BLPhotoViewerTests.swift`、`PhotoDataProcessorTests.swift` 三列，補上 r12 進度列更名連帶的 `CampaignDetailView.swift`、`CampaignListView.swift`、`DashboardView.swift`、`InsightsView.swift` 四列，與 `design.md` 的可改動清單對齊。
- [x] `design.md` 判讀級處置表修正：原本被「兩個 API 改動的呼叫端範圍已確認」段落截成兩半、後五列無法以表格渲染；該段落移至表格結束之後，七列連成單一表格。
- [x] 測試檔 MARK 分區名依 `design.md` 對照表統一（Goals 第 5 條「涵蓋本區的測試檔採用規範的命名」）：`Data Properties` → `Properties`（`LayerBoundaryTests` 1 處、`DesignSystemSourceScanTests` 2 處、`OptionPickerScreen` 與 `OrderEditScreen` 各 1 處）；型別本體 `Static Properties` → `Properties`（`ContrastComplianceTests`）；`LayerBoundaryTests` 的 `Static Properties` extension 全為 `static var` computed，改為 `Computed Properties`；`DesignSystemSourceScanTests` 的同名 extension 為 stored 與 computed 混合，依分區順序拆為 `Properties`（10 個 `static let`）與 `Computed Properties`（2 個 `static var`）兩個 extension；刪除 `Cases` 分區 3 處（enum case 本身不動）。
- [x] r15 最終測試證據（xcodebuildmcp CLI，全部晚於最後一次 Swift 寫入）：
  - 完整 `BuyLedger` 單元回歸（iPhone 17 `DDAA3311-B464-4DD3-96B8-360B26AF1929`）：xcresult `totalTestCount` 731、通過 730、失敗 1、跳過 0；相較 r14 的 730 增加 1 條，即新增的 `productionCodeUsesSingleAppLanguageEntry()`。唯一失敗為既有 `SnapshotTests/orderEditViewBaseline()` mismatch，屬已登記的渲染雜訊，未重錄 baseline。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-21T05-34-48-068Z_pid79833_352a1bd3.xcresult`
  - `SnapshotTests/orderEditViewBaseline()` 單獨重跑：xcresult `totalTestCount` 1、通過 1、失敗 0、跳過 0，確認為一次性渲染雜訊。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-21T05-36-14-565Z_pid81091_57929075.xcresult`
  - iPhone 17 完整 `BuyLedgerUITests`：xcresult `totalTestCount` 64、通過 64、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-21T05-36-41-147Z_pid81574_c5`
  - iPad Air 11-inch (M4) `6B65ED1C-3C2E-42BA-B1E7-08F606F175C5` 完整 `BuyLedgerUITests`：xcresult `totalTestCount` 64、通過 64、失敗 0、跳過 0。Result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-21T06-10-34-651Z_pid6217_1bad9583.xcresult`
