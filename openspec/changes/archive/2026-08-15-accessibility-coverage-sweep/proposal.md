## Why

專案在無障礙上的投入超出個人專案的常態：對比比值寫成可執行斷言、動態字級走版面重構而非壓縮字級、圖表元件有逐點朗讀與整體摘要。遺留的全部是「漏套」而非「不會做」，而且**規則本身早就寫對了**：

- 選取狀態的規則已明訂「須以標準特徵表達，勾號不得是唯一指示，且勾號須排除於朗讀」。實測全庫套了九處，漏了訂單清單的常規版與選項選擇器兩處；常規版連勾號的朗讀排除都沒有，而緊湊版有。
- 減少動態效果的規則已明訂「判斷須放在動畫宣告處，使日後新增的動畫沿用此模式而不必各自重新發現」。實測全專案三處動畫來源，兩處有判斷，照片檢視器的縮放動畫沒有。它正是規則所說的「日後新增的動畫」，而模式沒有被沿用。

也就是說，這不是規則缺漏，是規則沒有強制力。逐點補齊只會讓下一次新增又漏一次。

另外兩項是規則確實未涵蓋的：

**圖表缺少平台原生的圖表描述。** 元件有逐點標籤與整體摘要，但沒有使用平台提供的圖表描述機制，因此輔助技術無法以圖表的方式導覽（軸、資料序列、趨勢）。

**字級 token 從未上線。** 設計系統定義了字級 token 與其修飾子，但生產程式碼呼叫點是零，而手寫的字型指定有兩百零八處。此項屬於「跨檔案共用的呈現規則須有單一入口」的既有規則範圍，該規則已於共用助手收斂中一併涵蓋格式化與此類情形，因此本變更只執行收斂，不再新增條款。

## What Changes

- 補齊漏掉的兩處選取特徵與勾號朗讀排除。訂單清單的部分因共用元件已抽出，只需補一次。

  > 下游影響標記 (`orders-dual-layout-consolidation` QA 修正輪追加，2026-07-31)：本行原預期訂單清單部分 (`OrderSelectableRow.swift`) 仍需在本案補一次選取特徵與勾號朗讀排除。`orders-dual-layout-consolidation` 已將該元件收斂為 compact／regular 共用單一定義，收斂時一併採用 compact 既有行為 (勾選圖示排除於朗讀、`.isSelected` 特徵)，兩種尺寸皆已具備這兩項特徵。訂單清單部分因此已由該案提前完成，本案於此範圍只需處理選項選擇器 (`OptionPickerSheet.swift`) 與其餘項目。此標記僅記錄下游狀態，不更動本案的 tasks 或範圍。
- 補上照片檢視器縮放動畫的減少動態效果判斷，使三處動畫來源一致。
- 新增掃描式守門，偵測「表達選取但未加標準特徵」與「宣告動畫但未判斷系統偏好」兩類漏套，使既有規則從靠人記得變成機器強制。
- 為圖表補上平台原生的圖表描述，既有的逐點標籤與整體摘要維持不變。
- 把手寫的字型指定收斂為呼叫設計系統的字級 token，呈現結果不變。

## Non-Goals

- 不修改選取特徵與減少動態的規則本身。查證後確認兩者措辭已足夠涵蓋本次的漏套，缺的是強制力而非條款；再加一條指名這兩處的條款只會多兩個示範點。
- 不為字級收斂新增規格條款。該情形屬「跨檔案共用的呈現規則須有單一入口」的既有規則範圍，已於共用助手收斂中一併涵蓋。
- 不改變任何視覺呈現。字級 token 的值即為目前手寫的值。
- 不重新設計圖表的資料呈現，只補上平台原生的描述機制。
- 不處理對比相關的缺口，那些由對比守門的擴大與報價頁清算處理。
- 不抽取訂單清單的共用元件，那已由雙版面收斂完成。
- 不新增任何動畫。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `assistive-announcement-hygiene`: 選取特徵與裝飾排除兩條規則補上掃描式守門的要求，使漏套不能靜默通過。
- `motion-preference-adaptation`: 系統偏好判斷補上掃描式守門的要求。
- `chart-accessibility`: 新增平台原生圖表描述的要求。

## Impact

- Affected specs: `assistive-announcement-hygiene`（修改）、`motion-preference-adaptation`（修改）、`chart-accessibility`（修改）
- Affected code:
  - New:
    - apps/ios/BuyLedgerTests/AccessibilityConventionScanTests.swift
    - apps/ios/BuyLedgerTests/BLPhotoViewerTests.swift（QA 修正輪追加，2026-07-31：覆蓋抽出的 `BLPhotoViewer.zoomAnimation(reduceMotion:)`）
  - Modified:
    - apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift (下游影響標記：選取特徵與勾號朗讀排除已由 `orders-dual-layout-consolidation` 完成，詳見上方 What Changes 標記；本案若無其他理由不再需要改動此檔)
    - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
    - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift（QA 修正輪追加，2026-07-31：掃描式守門收窄豁免後新抓到的違規，補 `.isSelected` 特徵）
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTypography.swift
    - apps/ios/BuyLedger/Features/Settings/AppLanguage.swift（QA 修正輪追加，2026-07-31：新增 `init(locale:)`，供不持有 `AppLanguage` 狀態的呼叫端換算圖表無障礙描述的語言）
    - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift（QA 修正輪追加，2026-07-31：`BLSparkline` 呼叫點改傳已本地化的圖表描述字串）
    - apps/ios/BuyLedger/Features/Insights/InsightsView.swift（QA 修正輪追加，2026-07-31：`BLBarChart`／`BLDonutChart` 呼叫點改傳已本地化的圖表描述字串）
    - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift（QA 修正輪追加，2026-07-31：`BLDonutChart` 呼叫點改傳已本地化的圖表描述字串）
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings（QA 修正輪追加，2026-07-31：補 `第 %lld 筆` catalog entry）
  - Removed: （無）
- 字級收斂涉及各功能畫面的字型指定呼叫點，範圍以設計系統元件與功能畫面為主，逐檔進行。
- 不涉及 SwiftData schema 或資料形狀。
- 字級收斂以呈現不變為前提，因此原則上不需重錄視覺快照；若出現差異視為非預期並修正。
- 次序約束：本變更必須排在訂單雙版面收斂之後（使選取特徵只需補一次），並排在應用程式鎖定之前（使新增的畫面一併受本次的掃描守門約束）。
