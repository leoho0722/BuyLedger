## Problem

大尺寸 iPhone (例如 Pro Max 機型) 轉成橫向後，App 從底部分頁列切成 iPad 佈局：左側出現側邊欄，訂單分頁變成「清單 + 詳情」兩欄、上方常駐搜尋列，首頁與分析頁的卡片也改成並排。橫向的螢幕高度本來就小，訂單清單只剩一條窄欄可以捲動，實際可用的瀏覽空間比直向還少。使用者期待轉向後維持 iPhone 佈局，只把內容橫向延伸。

這是 ios-dev-kit 修正順序第 6 步拆出的 6e，排在第 6 步其他四個 change 之前；範圍與修法由使用者 2026-10-04 討論定案。

## Root Cause

四個畫面各自以水平尺寸分類 (`horizontalSizeClass`) 是否為 compact 決定佈局：根導覽 (`RootView` 的 `layout`)、訂單 (`OrdersView` 的 `platformContent`)、首頁 (`DashboardView` 的 `useWideHero`)、分析頁 (`InsightsView` 的 `useWideLayout`)。大尺寸 iPhone 橫向時系統回報的水平尺寸分類是 regular、垂直是 compact，於是四處都判斷成 iPad。

這個判斷從 MVP (`efffab8`) 起就沒有變過，iPhone 支援橫向也是建專案時就有的設定 (2026-10-04 以 `git log -G` 查證)，所以不是某一版改壞，而是規則本身沒有考慮垂直方向。四處各自讀尺寸分類，也讓規則無法一次修正、日後容易再出現不一致。

## Proposed Solution

- 新增設計系統的版面判斷入口 `BLLayoutClass`：只有水平與垂直尺寸分類**都是 regular** 時回傳 regular 版面，其餘組合 (含尺寸分類未知) 一律 compact 版面，並提供 SwiftUI environment 讀取方式。
- 四個畫面改讀這個入口，不再直接讀尺寸分類。iPhone 不論機型，橫向時垂直尺寸分類都是 compact，所以一律維持 iPhone 佈局；iPad 全螢幕時兩個方向都是 regular，維持側邊欄；iPad 分割畫面變窄時本來就是 compact 版面，行為不變。
- 以來源掃描守住單一入口：production 程式在入口檔以外引用尺寸分類 (讀取、寫入 environment 或成員存取) 就讓測試失敗，豁免標記對這條無效。
- 新規格 `adaptive-layout` 定義兩種版面的選擇規則，並說明其他規格裡「iPhone Compact」「iPadOS」等平台措辭對應到哪一種版面，消除大尺寸 iPhone 橫向與 iPad 窄視窗的歧義。
- **本 change 改到的六個既有檔整份對齊 ios-dev-kit 的風格與結構** (使用者 2026-10-04 裁決)：`RootView`、`OrdersView`、`DashboardView`、`InsightsView`、`DesignSystemSourceScanTests`、`SnapshotTests`，含排版、MARK、文件註解、測試命名與 Given／When／Then，超過 300 行的拆檔 (View 優先抽成獨立 View 型別)。整檔基準 227 筆機械違規 (實測，明細見 `findings.md`)，其中五個檔超過 300 行。`apps/ios/CLAUDE.md` 已登記的過渡例外 (畫面宣告 `@Dependency` 取現在時間、畫面內計算移進 reducer) 維持 6b 與第 7 步處理；`OrdersView` 雖會在 6b 重拆，仍照做。

## Non-Goals (optional)

見 `design.md` 的 Goals / Non-Goals。

## Success Criteria

- 在 iPhone 17 Pro Max 模擬器把 App 轉成橫向：根導覽維持底部分頁列、沒有側邊欄；訂單分頁是單欄清單並出現 iPhone 的整合篩選鈕；以 UI 測試驗證並保留截圖。
- 在 iPad 模擬器直向與橫向：根導覽仍是側邊欄、訂單仍是「清單 + 詳情」兩欄。
- 單元測試涵蓋 `BLLayoutClass` 全部九種尺寸分類組合 (水平、垂直各為 compact、regular、未提供)，只有「regular + regular」得到 regular 版面；另以同一個視窗切換尺寸分類，證明畫面讀到的版面會跟著更新。
- 來源掃描在入口檔以外出現 `horizontalSizeClass`／`verticalSizeClass` 引用時失敗，帶豁免標記也一樣 (以暫時加回直接讀取、加回帶豁免理由的直接讀取兩種變異驗證確實會失敗)。
- 共用的原始碼剝除器改以 Unicode 碼位辨識分隔符號，並修正單行與多行字串的反斜線判斷、區塊註解剝除後的邊界；修正前後 production 全部檔案的剝除輸出逐行相同，新 fixture 在修正前失敗、修正後通過。掃描保證以剝除器建模的詞法形式正面列舉，其餘詞法形式 (含正規表示式字面值) 列為已知限制。
- 訂單寬版 snapshot 明確指定兩個方向的尺寸分類；新增「水平 regular、垂直 compact」的 snapshot，畫面是 iPhone 單欄訂單清單。
- 首頁與分析頁既有 snapshot 明確指定窄版的尺寸分類且基準圖不變；新增首頁與分析頁的寬版 (並排) 與大尺寸 iPhone 橫向 (堆疊) snapshot 各一張。規則十一的正式掃描與記憶體內範例共用同一個入口，放寬豁免設定時範例測試會失敗 (2026-10-06 verify／review 補修)。
- 六個既有檔與拆出的新檔重跑 `reference/style_checks.py` 為 0 筆，且 style agent 逐檔審查 0 違規；每個檔不含檔頭與空行不超過 300 行。
- 拆檔前後畫面不變：既有 snapshot 一律不重錄即通過 (搬到新測試檔的 snapshot 只搬基準圖目錄)；`LocalizationCatalogTests` 的根畫面導覽標題掃描仍涵蓋移出的程式碼。
- 完整單元測試與 iPhone、iPad 兩台 UI 主回歸全綠。

## Impact

- Affected specs：新增 `adaptive-layout`
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Features/App/RootView.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
    - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
    - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
    - apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift
    - apps/ios/BuyLedgerTests/SnapshotTests.swift (拆檔)
    - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/ 的基準圖隨拆檔搬到新測試檔對應的目錄
    - apps/ios/README.md
    - .claude/rules/ios-design-system.md
    - .claude/rules/ios-unit-tests.md
    - .claude/rules/ios-ui-tests.md (轉向測試的模擬器 gotcha)
    - .claude/rules/ios-accessibility-localization.md (`delta` 參數的引用改指 `DashboardKPITile`)
    - apps/ios/CLAUDE.md (Device Hub、iPad 多工與 `Calendar.current` 過渡例外)
  - New:
    - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLLayoutClass.swift
    - apps/ios/BuyLedgerTests/BLLayoutClassTests.swift
    - apps/ios/BuyLedgerTests/BLLayoutClassEnvironmentTests.swift
    - apps/ios/BuyLedgerUITests/Tests/Smoke/OrientationLayoutTests.swift
    - 新增兩張 snapshot 基準圖 (目錄依所在測試檔)：「大尺寸 iPhone 橫向訂單」(task 2.1) 與「含進行中開團的首頁」(task 3.2，拆檔前錄於未改程式)
    - 新增四張 snapshot 基準圖 (task 6.1)：首頁與分析頁各一張寬版與大尺寸 iPhone 橫向，放在 `__Snapshots__/SnapshotTests+Dashboard/` 與 `__Snapshots__/SnapshotTests+Insights/`
    - openspec/changes/iphone-landscape-compact-layout/findings.md 與 reference/style_checks.py (整檔基準與檢查腳本)
    - `OrdersView`、`DashboardView`、`InsightsView` 拆出的獨立 View 型別檔，以及 `DesignSystemSourceScanTests`、`SnapshotTests` 拆出的 extension 檔；檔名在各拆檔 task 依內容命名
  - Removed: 無
