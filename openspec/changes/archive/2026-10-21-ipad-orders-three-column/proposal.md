## Summary

iPad 全螢幕 (regular 版面) 的訂單分頁改成根層三欄導覽：側邊欄、訂單清單欄、訂單詳情欄各有自己的導覽列，搜尋欄、筆數、「⋯」與「+」只出現在清單欄，詳情欄改以系統導覽列顯示客戶名稱與狀態、更多操作選單。

## Motivation

使用者 2026-10-18 在 iPad 上回報：訂單頁的搜尋欄 (「搜尋客戶、單號或商品」) 與右上工具列橫跨清單欄和詳情欄 (截圖：~/.claude/uploads/a808483d-fa56-467e-8bf3-13a4782409c4/d1ad2bc6-image.jpg)，搜尋只作用在清單，卻佔滿兩欄寬度，看起來像也在搜尋詳情。

成因：`OrdersView` 的 regular 版面在單一 `NavigationStack` 內用 `HStack` 並排 `OrdersRegularListColumn` 與 `OrdersRegularDetailColumn`，`.searchable(placement: .navigationBarDrawer)`、導覽標題與 `.toolbar` 都掛在這條橫跨兩欄的導覽列上。這個結構在 HEAD `5f91965` 之前就存在，不是 `order-filter-sheet-redesign` 造成。

使用者 2026-10-20 在 iPad 實機 (iPadOS 27) 試用本 change 後再回報兩項並提出一項要求：點搜尋欄後收鍵盤或清除搜尋文字，清單欄的搜尋欄與詳情欄跟著下移、「訂單」標題消失；直向展開側邊欄時側邊欄蓋在清單上，不像橫向那樣並排；清單與詳情要各佔一半 (直向各半，橫向扣掉側邊欄後各半)。

Apple 文件「Adding a search interface to your app」寫明：三欄 `NavigationSplitView` 會把搜尋欄放在 iPad 中間欄頂端，要指定欄位就把 `.searchable` 掛在該欄的 view；目前的自排兩欄拿不到這個行為。

## Proposed Solution

結構由使用者 2026-10-19 裁定 (兩個方案中選「根層改三欄」，另一案是在 `HStack` 內各包一個 `NavigationStack`)；三方審查 (claude-impl、codex-impl、gemini-impl) 後，使用者 2026-10-20 同意以長期維護為優先的四處調整 (見 design)：

- `RootSidebarLayout` 以私有列舉宣告每個分頁在 regular 版面的分欄型態 (「清單＋詳情」或「單欄內容」)：訂單分頁用 `NavigationSplitView(sidebar:content:detail:)`，其他分頁維持現行兩欄，且非訂單分頁之間切換不重建 split view。
- 訂單清單欄自己的導覽列承載導覽標題、搜尋欄、筆數、「⋯」與「+」，多選模式的全選、批次狀態與完成鈕也在這一欄；多選時的已選筆數顯示在清單欄頂部 (搜尋欄下方)，導覽標題固定為「訂單」。
- 詳情欄改用系統導覽列 (使用者 2026-10-19 裁定)：客戶名稱為 inline 導覽標題，狀態選單與更多操作選單放 toolbar，刪除自繪的標題列 (`titleBar`)。推入詳情 (iPhone) 與詳情欄共用同一份詳情工具列定義，`OrderDetailMenu` 不再區分窄欄工具列與寬欄標題列兩種外觀。
- 編輯、合併、AI 摘要 sheet 與清單篩選 sheet 的呈現語意不變；對話框先試只在清單欄掛一處，iPad 實測通過就移除「依有無詳情切換掛載點」的判斷。
- 直向照系統的欄位呈現 (使用者 2026-10-20 裁定，依 iPad Air 11 實測)：清單欄與詳情欄並排，側邊欄由系統決定並排或收到「顯示側邊欄」鈕後；橫向三欄並排。
- 版面判斷改依視窗 (使用者 2026-10-20 裁定)：`RootView` 依視窗尺寸分類決定一次並交給子樹，split view 的 content 欄 (回報 compact 尺寸分類) 不再被判成 compact；Preview 與截圖測試維持現行推導。
- iPad 寬版截圖比對改為清單欄、詳情欄分開拍，三欄組合由 UI 測試的位置比對守住。
- 輔助字級時清單欄篩選區併入清單捲動區 (使用者 2026-10-20 裁定)：最大輔助字級下清單欄寬度不隨字級加寬、篩選區被壓縮而重疊，改為隨清單一起捲動；標準字級不變。
- 清單欄導覽標題固定 inline (實機回報後修正)：清除搜尋文字或收鍵盤後標題保留，搜尋欄與詳情欄不再下移。直向清單欄 320pt 放不下 inline 標題與多選工具列，多選筆數改顯示在清單欄頂部 (使用者 2026-10-20 選擇)。
- 欄寬 (使用者 2026-10-20 要求並裁定)：側邊欄並排時清單欄與詳情欄平分扣掉側邊欄後的寬度；直向 (側邊欄收起或覆蓋) 清單欄維持 320pt、詳情欄佔其餘，展開的側邊欄照系統覆蓋在清單上。直向各半與直向側邊欄推開經實測系統做不到，使用者裁定維持系統行為。欄寬改由宣告欄位的 `RootSidebarLayout` 設定 (原本掛在 `.searchable` 內層的欄寬從未生效)。
- compact 版面 (iPhone 任何方向、iPad 窄視窗) 不變。

## Non-Goals

- 不改開團、總覽、分析與「更多」分頁的版面；開團詳情維持推入。
- 不改訂單清單欄的篩選區、訂單列與詳情內容的排版 (只換詳情頂部的標題與選單承載方式)。
- 不改 TCA 狀態結構與導覽路徑 (iPhone 詳情堆疊、iPad 右欄同步 `regularDetail` 照舊)。
- 不在本 change 改用 `TabView` 的 `.sidebarAdaptable` 樣式；這是長期方向，記錄在 design 的 Open Questions，另案評估。

## Alternatives Considered

- 在 `HStack` 內清單欄與詳情欄各包一個 `NavigationStack`：改動只在 `OrdersView`，但「split view 詳情欄內並排兩個 stack」官方沒有記載，兩欄導覽列高度不一致、側邊欄收合鈕落在哪一欄不確定。使用者未採用。
- 訂單頁內再包一層 `NavigationSplitView`：巢狀 split view 會與根層 split 互搶寬度 (apps/ios/README.md 已記錄不用此做法)。
- 改用自繪搜尋欄放進清單欄頂部：失去系統搜尋的取消鈕、捲動收合與鍵盤行為，違反既有「系統元件優先」規格。
- 根層改用 `TabView` 加 `.sidebarAdaptable`，讓訂單分頁自己持有清單＋詳情的 split view：根層不再有分頁特例，但 iPad 預設會從固定側邊欄改成頂部浮動分頁列 (產品決定)，且影響所有分頁與大量 UI 測試；列為長期方向，不在本 change。

## Impact

- Affected specs: `adaptive-layout` (修改「The regular layout is used only when both size classes are regular」的 iPad 情境；新增訂單三欄與搜尋、工具列歸屬，以及版面判斷依視窗兩條 requirement；不新增 capability)。
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersRegularDetailColumn.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailMenu.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrderCompactDetailView.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift (多選入口、多選控制項與筆數補 identifier)
    - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID+Orders.swift
    - apps/ios/BuyLedgerTests/OrderListSnapshotSourceScanTests.swift
    - apps/ios/BuyLedgerTests/SnapshotTests+Orders.swift
    - apps/ios/BuyLedgerTests/SnapshotTests+OrdersBaseline.swift
    - apps/ios/BuyLedgerTests/SnapshotTests+OrderFilterEmptyStates.swift
    - apps/ios/BuyLedgerUITests/Screens/OrdersScreen.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersRegularListColumn.swift (輔助字級時篩選區併入捲動區)
    - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift (系統字級啟動參數)
    - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLLayoutClass.swift
    - apps/ios/BuyLedger/Features/App/RootView.swift
    - apps/ios/BuyLedgerTests/BLLayoutClassEnvironmentTests.swift
    - apps/ios/BuyLedgerUITests/Support/AppNavigator.swift
    - apps/ios/BuyLedgerUITests/Screens/RootNavigationScreen.swift (側邊欄收起時改等目的地根容器)
    - .claude/rules/ios-design-system.md
    - .claude/rules/ios-accessibility-localization.md
    - apps/ios/BuyLedgerUITests/Tests/Smoke/OrientationLayoutTests.swift (轉向 helper 改用共用版本)
    - apps/ios/README.md
    - apps/ios/CLAUDE.md (UIKit 系統參數只加在 `LaunchOptions`，5.1 補)
    - .claude/rules/ios-navigation.md
    - .claude/rules/ios-ui-tests.md
    - .claude/rules/ios-unit-tests.md
  - New:
    - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailToolbarContent.swift
    - apps/ios/BuyLedgerUITests/Tests/Orders/OrderRegularColumnScopeTests.swift
    - apps/ios/BuyLedgerUITests/Tests/Orders/OrderRegularColumnScopeTests+Assertions.swift (style 閘門要求拆出的斷言 helper)
    - apps/ios/BuyLedgerUITests/Tests/Orders/OrderRegularAccessibilitySizeTests.swift
    - apps/ios/BuyLedgerUITests/Tests/Orders/OrderRegularSearchBarTests.swift (搜尋結束後標題與位置)
    - apps/ios/BuyLedgerUITests/Tests/Orders/OrderRegularColumnWidthTests.swift (橫向各半、直向 320、轉向後清單欄仍在)
    - 清單欄最大輔助字級截圖的基準圖 (apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/)
    - apps/ios/BuyLedgerUITests/Support/HorizontalBounds.swift (欄位水平範圍比對 helper)
    - apps/ios/BuyLedgerUITests/Support/Orientation.swift (自 OrientationLayoutTests 搬出的轉向 helper)
    - 分欄拍攝的寬版截圖新基準圖 (檔名依改寫後的測試名稱，位於 apps/ios/BuyLedgerTests/__Snapshots__/ 對應目錄)
    - 只有在單一掛載點實測失敗時才新增：apps/ios/BuyLedger/Features/Orders/Store+OrdersRegularAlert.swift
  - Removed:
    - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+Orders/ordersView_寬版多選模式_顯示選取列.1.png
    - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/ordersView_寬版選取含成本明細訂單_符合基準圖.1.png
    - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrderFilterEmptyStates/ordersView_寬版無付款方式與類別_符合基準圖.1.png
- 不動資料庫 schema、`shared/data-model/schema/` 與本地化字串。
