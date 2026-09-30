## 1. 掃描守門先建立

- [x] 1.1 讓「表達選取但未加標準特徵」不能靜默通過：新增掃描式守門，偵測推導出選取布林值並渲染條件式勾號、卻未加標準特徵的呼叫點；守門本身掃描整個 App target，不侷限於現存的漏套位置。對應 spec requirement「Selection state is expressed through the standard trait」的掃描情境。

  > 下游影響標記 (`orders-dual-layout-consolidation` QA 修正輪追加，2026-07-31)：本任務原預期守門會指名訂單清單常規版與選項選擇器兩處。訂單清單的選取特徵與勾號朗讀排除已由 `orders-dual-layout-consolidation` 收斂 `OrderSelectableRow.swift` 為 compact／regular 共用單一定義時一併完成 (該元件已具備 `.accessibilityAddTraits(.isSelected)` 與勾號 `.accessibilityHidden(true)`)，守門實際只會指名選項選擇器 (`OptionPickerSheet.swift`) 一個元件內的呼叫點。

  驗證：守門在補齊之前即紅，並指名選項選擇器（apps/ios/BuyLedgerTests/AccessibilityConventionScanTests.swift）。
- [x] 1.2 讓「宣告動畫但未判斷系統偏好」不能靜默通過：同一份守門加入動畫宣告的掃描。對應 spec requirement「Animations honor the reduce motion preference」的掃描情境。驗證：守門在補齊之前即紅，並指名照片檢視器的縮放動畫。

  > QA 修正輪修正記錄 (2026-07-31)：QA 以變異測試證明原掃描判斷的是變數命名而非結構特徵：把選取列的布林值改名、或補一個不隨狀態變化的固定 `.accessibilityLabel(` 皆可讓真違規靜默通過；植入的三個案例 (拔掉 `OrderFilterSheet.swift` 既有選取列的特徵、新增 `isChosen` 命名的等價違規列、`OptionPickerSheet.optionRow` 拔特徵改掛固定 label) 全數放行。已重寫兩份掃描：
  >
  > - **選取特徵掃描改以結構判定**：候選鎖定「單元內同時具備 `.buttonStyle(.plain)` (本專案選取列既有慣例) 與結構上條件式渲染的勾號 (內嵌三元運算式或 `if` 區塊)」，不再依賴變數／條件命名或勾號前後三行是否含 `select` 字樣；同時移除「每單元只取第一個勾號」的限制，並整條移除 `.accessibilityLabel(` 豁免 (QA 指出其等價性不成立：動作描述無法取代選取列表在 rotor 中應有的標準選取語意)。因移除該豁免，`MergePhotoPickerSheet.photoCell` (原僅有隨狀態變化的 `.accessibilityLabel(`，無 `.isSelected` 特徵) 被新掃描抓到，已補上 `.accessibilityAddTraits(isSelected ? .isSelected : [])`。
  > - **動畫掃描補上同檔宣告解析**：若 `.animation(...)` 引用同檔內一個屬性／函式，且該宣告本身的內容判斷了 `reduceMotion`，視為已判斷；修掉 QA 指出的假陽性 (把判斷抽成計算屬性後，呼叫端 3 行視窗內不再有字面 `reduceMotion` 會被誤報)。並新增「掃到檔案數 > 0」的下限斷言，避免 `productionRoot` 解析錯誤時兩份掃描對空集合靜默恆綠。
  >
  > 兩份掃描與其已知邊界 (選取特徵只認 `.buttonStyle(.plain)` 慣例；動畫只認 `.animation(`，不含 `withAnimation`／`.transition`／`.symbolEffect`) 已同步收窄進 `apps/ios/CLAUDE.md` 與本 change 的兩份 spec delta，不再用絕對句宣稱涵蓋所有寫法。

## 2. 補齊選取狀態

- [x] 2.1 讓所有表達選取的列以標準特徵呈現，且其勾號不被單獨朗讀：補齊選項選擇器。訂單清單常規版已由 `orders-dual-layout-consolidation` 提前完成 (詳見 1.1 下游影響標記)，本案於此範圍不需再改動 `OrderSelectableRow.swift`。對應 spec requirement「Selection state is expressed through the standard trait」與「Decorative indicators are excluded from announcements」。驗證：1.1 守門轉綠；以輔助技術確認選項選擇器的選項列被朗讀為已選取且勾號不產生額外朗讀，並複核訂單清單常規版沿用既有實作、屬性不變（apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift；複核對象 apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift）。
- [x] 2.2 確認兩種尺寸的訂單清單呈現一致：補齊後兩者由同一份實作提供，屬性必然相同。驗證：iPhone 與 iPad 各以輔助技術檢視一次，屬性相同。

## 3. 補齊減少動態效果

- [x] 3.1 讓照片檢視器的縮放動畫在系統偏好開啟時不播放動畫，使三處動畫來源一致。對應 spec requirement「Animations honor the reduce motion preference」的縮放情境。驗證：1.2 守門轉綠；開啟系統偏好後縮放直接到達目標倍率而無過渡（apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift）。

  > QA 修正輪修正記錄 (2026-07-31)：QA 指出此行為原本唯一的守門是會被命名繞過、又會誤報的掃描式守門，可單元測試卻沒做。已把判斷抽成 `static func BLPhotoViewer.zoomAnimation(reduceMotion: Bool) -> Animation?`，並新增 `BLPhotoViewerTests` 覆蓋兩分支 (`reduceMotion = true` 回傳 `nil`、`false` 回傳非 `nil`)；曾將回傳寫反做變異驗證，確認測試會轉紅後才復原。

## 4. 圖表的原生描述

- [x] 4.1 讓輔助技術能以圖表方式導覽三個圖表元件：補上平台原生的圖表描述，涵蓋軸、資料序列與依繪製順序排列的數值，既有的逐點標籤與整體摘要維持不變。對應 spec requirement「Charts expose a native chart description for structured navigation」。驗證：以輔助技術確認三個元件皆可進入圖表導覽；全庫查無既有的圖表逐點朗讀單元測試可對照，改以逐檔 diff 確認三個元件既有的逐點 `.accessibilityLabel`／`.accessibilityValue` 與整體摘要 (`accessibilitySummary`) 程式碼未被本次改動觸及，本次異動僅新增 `.accessibilityChartDescriptor(_:)` 呼叫與其專用描述型別（apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift、apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift、apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift）。

  > QA 修正輪修正記錄 (2026-07-31)：本任務原記錄的驗證條件「既有的逐點朗讀測試維持綠燈」指向不存在的測試——全庫查無任何圖表逐點朗讀單元測試，該條件因此無法被證偽。已改寫為可驗證的條件：以 diff 確認逐點 label 與整體摘要程式碼未被本次改動觸及。

  > Style 修正輪修正記錄 (2026-07-31)：本任務落地時在 `Localizable.xcstrings` 補入 `數值`／`項目`／`順序`／`類別`／`長條圖`／`圈狀圖`／`走勢圖` 共 7 個翻譯條目。初次審視誤判為與「執行期不會查表」的已知落差矛盾而嘗試移除，但移除後 `LocalizationCatalogTests.catalogContainsCompleteTraditionalChineseAndEnglishValues()` 轉紅——該既有守門測試以結構性掃描比對 `title`／`name` 等參數標籤，只要字面值形似使用者可見文字就要求 catalog 收錄英文翻譯，不判斷是否會在執行期被查表。已恢復 7 個條目 (與 HEAD 前狀態一致)，並改為澄清 `apps/ios/CLAUDE.md` 對應段落：entry 存在是滿足 catalog 完整性守門與提供翻譯對照文件，與「執行期不會查表」並不矛盾。既有的 `占比` 條目 (HEAD 既有、非本案新增) 全程未變動。

  > QA 修正輪修正記錄 (2026-07-31)：上一則記錄把「`AXChartDescriptor` 系列型別吃 `String` 不吃 catalog」寫成不可解的落差，QA 指出專案已有 `AppLanguage.localized(_:) -> String` (`AppLanguage.swift`) 可解此題，只是先前未接上。已接上，但需顧及分層：`AppLanguage` 是 Features 層型別，Design System 元件在 Shared 層，Shared 依賴 Features 會違反分層。做法是**由呼叫端傳入已本地化字串**：`BLBarChart`／`BLDonutChart`／`BLSparkline` 新增 `axisXTitle`／`axisYTitle`／`seriesName` (`BLSparkline` 另有 `pointOrdinalDescription`) 建構參數，預設值維持正體中文字面值 (未傳入時行為不變，涵蓋 Preview)；`DashboardView`／`InsightsView` 已持有 `store.settings.language: AppLanguage`，直接呼叫 `AppLanguage.localized(_:)` 傳入；`OrderDetailView` 不持有該狀態，改由新增的 `chartLanguage: AppLanguage` 計算屬性從既有 `@Environment(\.locale)` 換算 (`AppLanguage` 同步新增 `init(locale:)`，與同檔既有的 `currencyDisplayText(for:)` 語系比對邏輯一致，不重寫第二份)。`BLSparkline.swift` 原本連 catalog key 都沒有的 `"第 \(n) 筆"` 一併補上 `第 %lld 筆` entry (以文字插入方式加入 `Localizable.xcstrings`，未動既有 7 個 entry)。至此三個呼叫點已改為執行期實際查表，`apps/ios/CLAUDE.md` 對應段落已同步改寫，不再是「已知落差」的措辭。

## 5. 字級 token 收斂

- [x] 5.1 讓設計系統元件的字型指定改為呼叫既有的字級 token，呈現結果不變。驗證：收斂後的元件不再持有手寫字型指定；視覺比對確認呈現相同（apps/ios/BuyLedger/Shared/DesignSystem）。
- [x] 5.2 讓各功能畫面的字型指定改為呼叫字級 token，逐檔進行，呈現結果不變。驗證：手寫字型指定的數量顯著下降並記錄前後數字；視覺比對確認各畫面呈現相同（apps/ios/BuyLedger/Features）。
- [x] 5.3 確認 token 的定義涵蓋實際用到的所有字級，未涵蓋者補進 token 而非留在呼叫端手寫。驗證：收斂後剩餘的手寫字型指定各有記錄的理由（apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTypography.swift）。

  > Style 修正輪修正記錄 (2026-07-31)：本任務原記錄的手寫 `.font(` 剩餘數與判準不夠精確，已重新實測並補上明確判準。
  >
  > **是否新增 case 的判準**已寫入 `apps/ios/CLAUDE.md`「字級一律走 `BLTypography`」一節：字重差異代表獨立視覺語意層級 (如 `title3Bold`) 才補 case；純粹強調用途的字重組合即使呼叫端數量達兩位數仍留在呼叫端。實測最高頻三組：`subhead.font.weight(.semibold)` 32 處、`caption.font.weight(.semibold)` 23 處、`footnote.font.weight(.semibold)` 15 處，皆屬此類、不新增 case。
  >
  > **剩餘手寫 `.font(` 呼叫點**實測本案範圍內 9 處 (不含 `persistence-failure-safe-recovery`／`orders-dual-layout-consolidation` 等他案未追蹤新檔的 3 處：`PersistenceFailureView.swift:27`、`OrderSelectableRow.swift:42`、`BLHeroCardBackground.swift:63`)：
  > - `MergePhotoPickerSheet.swift:75`、`BLAvatar.swift:35`、`BLPhotoViewer.swift:130` 三處各有行內理由註解 (前兩者為既有；`BLPhotoViewer.swift:130` 於本輪修正 A 項字重漂移後補上，說明維持無 bold 常規字重、token 的 `.largeTitle` case 內建 bold 會改變 placeholder 圖示粗細)。
  > - `InsightsView.swift:220`、`FxView.swift:236`／`258`、`QuoteView.swift:340`、`DashboardView.swift:267`／`390` 六處為 `@ScaledMetric` 驅動的比例縮放尺寸 (hero 數字／圖示)，屬 `apps/ios/CLAUDE.md` 既有總體豁免涵蓋範圍，不逐一加註解。

## 6. 驗收

- [x] 6.1 執行整體驗收：主 scheme 全套單元測試綠燈、UI 主回歸在 iPhone 與 iPad 各一次綠燈。驗證：測試通過數不低於改動前。
- [x] 6.2 確認呈現未變：字級收斂以呈現不變為前提，若快照出現差異視為非預期並修正，而非直接重錄接受。驗證：快照比對結果逐項確認。
