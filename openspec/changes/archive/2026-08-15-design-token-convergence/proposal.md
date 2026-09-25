## Summary

讓顏色與字級只剩一個入口：刪掉零呼叫點的字級 token 軌道、把繞過色盤的原始色彩字面值全數收回、清掉從未讀取的外觀環境宣告，並新增原始碼掃描測試把這些不變式釘住，讓新的繞道無法再靜默長出來。

## Motivation

**⚠ 2026-08-01 修正：本節原「字級 token 軌道零呼叫點」的前提已被本計劃自己的第 21 案 (`accessibility-coverage-sweep`) 推翻。** 該案已把手寫字型收斂進 `BLTypographyStyle`／`blTextStyle(_:)`，並在 `apps/ios/CLAUDE.md` 立下「字級一律走 token」的規則。實測目前 `blTextStyle(` 呼叫點共 117 處、橫跨 39 個檔，字級 token 現為專案標準，**不再是零呼叫點的重造元件**。原提案「字級軌道直接刪除」(D1) 已撤除，字級 token 維持現狀，本次不動 `BLTypography.swift`／`BLTypographyModifier.swift`；下方 Proposed Solution 與 Impact 已同步更新，Motivation 保留此段作為決策沿革記錄。

**色彩入口其實已經成立，只是沒人守。** 實地掃描發現全庫系統取色介面呼叫**全部**落在色盤檔內，單一入口這條不變式本身已經達成。缺口是繞道：直接取系統強調色、系統綠、系統橘、系統紅與系統藍字面值 (含元件預覽區塊)，以及一支零呼叫點卻公開背書「手抄十六進位」的顏色建構子。精確計數見 design.md 的重新校準基準。

**次要文字繞過受測試把關的色盤。** 專案刻意不採用系統的次要標籤色，因為它在淺色外觀僅約 3.4:1，低於本專案為資訊性文字設下的 4.5:1 地板；色盤另以推導方式提供了達標的次要標籤色，並有對比測試把關。但全庫仍有數十處直接使用系統次要色 (`.secondary`)，等於這批文字完全在該測試的保護範圍之外。

**外觀環境宣告中僅一個從未被讀取者例外。** 各檔宣告外觀環境值卻整檔只出現這一次 (即宣告本身)，唯一真正的讀者是卡片陰影修飾子。色盤與語意色軌道全走系統動態色與資源目錄，外觀切換由系統驅動，view 不需自行宣告依賴。

**規範目前只有示範點，沒有機器強制力。** 上述每一類繞道都對應到已經寫明的規則，卻仍然存在並持續增加。掃描守門一旦落地，後續改動就無法再繞過既有入口，這是把示範式規範換成機器強制力的第一顆螺絲。

## Proposed Solution

**一、字級軌道維持現狀，不刪除、不擴充。** ⚠ 已撤除原「字級軌道直接刪除」決策：該決策的前提 (零呼叫點) 已被第 21 案反轉，字級 token 現為專案標準 (`apps/ios/CLAUDE.md` 已有「字級一律走 token」規則)，刪除會摧毀該案成果並讓呼叫點所在的檔案編不過。本案不動 `BLTypography.swift`／`BLTypographyModifier.swift`／`BLCard` 預覽字級。

**二、次要文字換入口，而不是逐處穿參數。** 多數繞道寫在私有的 `@ViewBuilder` helper 內、作用域拿不到色盤實例，逐一穿參數會製造大量無關差異。作法是在顏色擴充檔補一支靜態屬性代理到色盤的次要標籤色，呼叫點只把系統次要色換成它，形狀不變，並比照專案既有的按鈕樣式工廠慣例。表單與清單的 section footer 一併換，不留豁免。

**三、色彩字面值收回色盤。** 系統強調色、系統綠、系統橘、系統紅、系統藍等具名系統色字面值全部改走色盤 (含元件預覽區塊)；零呼叫點的十六進位建構子直接刪除。白、黑與透明不動，因為漸層白字、遮罩與透明背景不是語意色，這條例外要寫進規範與掃描器。

**四、狀態色點承認為獨立軌道。** 側邊欄的 8 個分組色點與狀態膠囊的語意色是兩套詞彙。語意色軌道只有 6 個值，8 個分組經映射後只剩 4 種顏色，其中兩個在側邊欄是相鄰兩列、同色會被讀成渲染 bug。因此新增一支專門承載分組色相的來源，附上與語意色軌道的對照說明，視覺零變更；真正要解決的是「這套映射沒有單一來源也沒有說明」的治理問題。

**五、掃描守門用測試內的原始碼掃描。** 不引入新工具鏈，比照專案既有讀取資源檔的測試 pattern，隨主 scheme 測試自然被執行，違例訊息直接引導到正解。需要例外時走具名的豁免標記並要求填寫理由，該理由本身也被測試檢查非空。

## Non-Goals

- **不刪除、不擴充字級 token。** 見上，D1 已撤除；字級 token 維持現狀。
- **不動非資訊性的第三層文字色。** 揭示指示箭頭等純圖形仍走系統色，不在本次收回範圍。
- **不動白、黑、透明三個字面值。** 它們不是語意色。
- **不引入外部靜態分析工具。** 掃描守門以專案內測試實作。
- **不改任何可及性識別碼。** 本次不動測試定位。

## Alternatives Considered

- **把字級軌道刪除。** 已否決 (2026-08-01 撤除)：該決策建立在「字級 token 零呼叫點」的前提上，但本計劃自己的第 21 案已把該前提反轉為「117 處呼叫、39 個檔、專案標準」，刪除會讓這些檔案編不過並回歸第 21 案已解決的問題。
- **擴充字級 token 並把手寫字型全部改過去。** 不在本案範圍：字級 token 的擴充/收斂已由第 21 案處理，本案不重複規劃。
- **Section footer 明文豁免、保留系統次要色。** 已否決：footer 承載的是規則說明這類真正的資訊性文字，適用 4.5:1 地板；且豁免會讓掃描守門必須帶白名單，而列舉式白名單正是本次要消滅的老毛病。
- **狀態色點全部改用語意色軌道，全 App 只留一套詞彙。** 已否決：映射後兩個相鄰狀態同色，需要另給區分手段才能採用；承認分軌並寫明理由，成本更低且視覺零變更。
- **用外部靜態分析工具寫規則。** 已否決：其規則表達力做不到「某個 API 只准出現在特定檔案」這種帶檔案條件的判斷，且要新增設定檔、建置階段與一支需維護版本的外部相依。
- **用獨立腳本掛 Makefile 或 git hook。** 已否決：在目前沒有 CI、也沒有 git hook 的現況下，等於又回到靠人記得跑。

## Impact

- Affected specs: `design-system-hygiene` (修改)、`design-system-color-contrast` (修改)、`color-system-foundation` (修改)、`interface-consistency` (修改)
- Affected code:
  - New:
    - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLStatusHue.swift
    - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
  - Modified:
    - apps/ios/BuyLedger/Shared/Extensions/Color+Extensions.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Cards/BLCard.swift
    - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
    - apps/ios/BuyLedger/Features/App/PersistenceFailureView.swift
    - apps/ios/BuyLedger/Features/App/AppLockView.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift
    - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
    - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
    - apps/ios/BuyLedger/Features/Orders/Components/PaymentMethodEditorSheet.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
    - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrderMergeCandidateSheet.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupNameEditorSheet.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
    - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
    - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
    - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
    - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
    - apps/ios/BuyLedger/Features/More/MoreView.swift
    - apps/ios/BuyLedger/Features/FX/FxView.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Tags/BLTagPill.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Progress/BLProgressBar.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Chips/BLFilterChip.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
    - apps/ios/BuyLedgerTests/ContrastComplianceTests.swift
    - apps/ios/CLAUDE.md
  - Removed:
    - (無；D1「字級軌道刪除」已撤除，`BLTypography.swift`／`BLTypographyModifier.swift` 不刪除，見 Motivation 2026-08-01 修正)
