## Summary

iPad 訂單分頁的詳情欄改用與 iPhone 推入詳情相同的內容排版，移除 `OrderDetailView.OrderDetailLayout` 與各區段的寬版分支，訂單詳情內容只維護一版。

## Motivation

訂單詳情目前有兩套內容排版：iPhone 推入詳情用窄欄 (財務摘要卡、圈狀成本圖與圖例、帶標題的商品與備註卡)，iPad 詳情欄用寬欄 (三張財務指標卡並排、成本拆解條、大寫標題的卡片並排)。分流散在 `OrderDetailContentView`、`OrderDetailSummaryView`、`OrderDetailCostView`、`OrderDetailItemsView`、`OrderDetailNotesView` 五個檔，每次調整詳情內容都要改兩份並各自驗證。使用者 2026-10-21 決定兩者共用同一版，減少寬窄兩套排版的維護成本；詳情工具列已在 `ipad-orders-three-column` 收成 `OrderDetailToolbarContent` 一份，這次把內容排版也收成一份。

這也是後續 iPad／iPhone Duo 各頁版面規劃的前置：各頁版面的原則是同一版畫面依可用寬度調整，不依裝置分版。

## Proposed Solution

- `OrderDetailView` 移除 `layout` 屬性與 `OrderDetailLayout` 列舉，`OrderDetailContentView` 與四個區段 View 移除 `layout` 參數與 `switch`，只保留現行窄欄排版。
- 刪除只有寬版使用的私有 View 與成員：`OrderDetailContentView` 的 `wideBreakdownAndItems`／`wideDetailCards`、`OrderDetailSummaryView` 的 `kpiThreeUp`／`kpiTiles`／`kpiTile(...)` 與只供它們使用的 `@ScaledMetric`、`OrderDetailCostView` 的 `breakdownBarsCard`／`breakdownBarRow(_:)` 與 `rowSpacing`、`OrderDetailItemsView` 的 `wideItemsCard`、`OrderDetailNotesView` 的 `wideNotesCard`；名稱帶 `compact` 的私有成員改為不分版面的名稱，doc comment 拿掉窄欄／寬欄的說法。
- `OrdersRegularDetailColumn` 改以 `OrderDetailView(store:)` 呈現，導覽列標題、詳情工具列與無選取空狀態不變。
- 詳情的導覽列標題 (客戶名稱、inline) 與 `OrderDetailToolbarContent` 改由 `OrderDetailView` 自己宣告，刪除只做這件事的 `OrderCompactDetailView`；iPhone 推入目的地與 iPad 詳情欄都直接使用 `OrderDetailView(store:)`，iPad 詳情欄只保留無選取時顯示空狀態的判斷 (使用者 2026-10-21 選擇)。
- 刪除寬版詳情欄截圖測試 `ordersRegularDetailColumn_寬版詳情欄選取含成本明細訂單_符合基準圖` 與其基準圖 (使用者 2026-10-21 裁決)：改完後 iPad 與 iPhone 用同一份內容程式碼，iPhone 的兩張詳情截圖不重錄即通過，守住截圖可見區域沒有改壞，畫面外的區段以 iPad 實測捲動確認與逐段程式碼對照；iPad 詳情欄的排列以模擬器實測確認一次。
- `OrderCostBreakdown.Component.fraction` (成本占比) 只被要刪除的成本拆解條使用，一併刪除，連同只用來計算它的建構參數 `total` (使用者 2026-10-21 選擇)；圈狀圖以金額計算，不受影響。
- `adaptive-layout` 規格新增「訂單詳情內容在兩種版面使用同一種排列」的需求，並在 Purpose 補上例外 (原文寫明各版面內的畫面內容不在範圍，但既有需求已規定首頁與分析頁的排列，這次再加上訂單詳情)；`progress-indicator` 規格移除已不存在的「訂單詳情成本條」範例；`.claude/rules/ios-navigation.md` 的詳情工具列條目補上內容排版也只有一份，`.claude/rules/ios-unit-tests.md` 的訂單三欄分欄截圖條目改為只拍清單欄。

## Non-Goals (optional)

範圍外的事項與否決的做法記在 design.md 的 Goals／Non-Goals。

## Alternatives Considered (optional)

- **保留寬版、只在無障礙字級或窄寬度時退回窄版**：仍是兩套排版，不符合使用者「只寫一版」的決定。
- **改寫成依可用寬度自動切換的新排版**：屬於後續「iPad／iPhone Duo 各頁版面」討論的範圍，在那之前先收斂成現行窄欄一版，避免同時改動排版與版面判斷。

## Impact

- Affected specs: `adaptive-layout` (新增需求：訂單詳情內容在 compact 與 regular 版面使用同一種排列；Purpose 補上例外)、`progress-indicator` (修改需求：bar-only 範例移除訂單詳情成本條)
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailContentView.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailSummaryView.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailCostView.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailItemsView.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailNotesView.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersRegularDetailColumn.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
    - apps/ios/BuyLedger/Features/Orders/OrderCostBreakdown.swift (刪除 `Component.fraction` 與 `total` 參數)
    - apps/ios/BuyLedgerTests/OrderCostBreakdownTests.swift (刪除兩條占比測試、更新建構引數)
    - apps/ios/BuyLedgerTests/ActionGroupingScanTests.swift (掃描清單移除 `OrderCompactDetailView.swift`)
    - apps/ios/BuyLedgerTests/SnapshotTests+OrdersBaseline.swift (刪除 `ordersRegularDetailColumn_寬版詳情欄選取含成本明細訂單_符合基準圖` 測試方法)
    - apps/ios/BuyLedger.xcodeproj/project.pbxproj (build-and-run 前遞增 build number)
    - .claude/rules/ios-navigation.md
    - .claude/rules/ios-unit-tests.md
    - .claude/rules/ios-ui-tests.md (補上以 Xcode MCP 實測橫向畫面的做法)
    - apps/ios/CLAUDE.md (建置與開發指令補一條指向上述 Xcode MCP 條目，使用者 2026-10-22 決定)
    - apps/ios/README.md (詳情欄說明，2.1 視現況同步)
    - openspec/specs/adaptive-layout/spec.md (Purpose 段落)
  - New: 無
  - Removed:
    - apps/ios/BuyLedger/Features/Orders/Components/OrderCompactDetailView.swift
    - apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests+OrdersBaseline/ordersRegularDetailColumn_寬版詳情欄選取含成本明細訂單_符合基準圖.1.png
