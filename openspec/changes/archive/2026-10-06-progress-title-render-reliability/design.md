## Context

`BLProgressView` (`Shared/DesignSystem/Components/Progress/BLProgressView.swift`) 以系統 `ProgressView(value:label:currentValueLabel:)` 建立，標題是 `Text(LocalizedStringKey(title))`，目前值是 `Text(trailingText)` 或格式化百分比的 `Text(String)`；外觀由 `BLProgressViewStyle` (`ProgressViewStyle`) 的 `makeBody` 決定：

- 有標題或目前值時，上方一列以 `configuration.label` 與 `configuration.currentValueLabel` 排版，下方是 6pt 高的進度條；兩者都沒有時只畫進度條。
- 八個呼叫端透過 `BLProgressView` 帶標題 (`CampaignRow`、`CampaignDetailSettlementSection`、`DashboardOngoingCampaignsSection`、`InsightsCampaignProfitCard`、`QuoteBreakdownCard`)。
- 三個呼叫端直接寫 `ProgressView(value:)` 加 `BLProgressViewStyle`，只畫進度條 (`DashboardHeroCard` 的月目標、`InsightsCategoryCard`、`OrderDetailView` 的成本明細)。

2026-10-06 實測：

- `campaignListView_依月分組_符合基準圖` 在 `SnapshotTests` 整批執行失敗時，與基準圖的差異範圍只有「到貨」標題，同列的「2/2」與進度條逐像素相同。
- 最近四次包含整個 `SnapshotTests` 類別的執行，這條四次都失敗、單獨重跑都通過。
- 以 `mobilebuildmcp ui-automation snapshot-ui` 讀取 `campaignsWithOrders` 種子資料的開團分頁：「四月韓國團」列的無障礙標籤是「四月韓國團、開團中、3 筆 · $16,780、到貨、0/3、收款、$11,800」。每個進度列依序貢獻標題與目前值，目前沒有任何測試守住這段朗讀。

沿革：2026-07-20 (`5a36e30`) 把元件從自繪兩段文字改成系統 `ProgressView`，目的是讓輔助技術讀到帶當前值的進度語意；`ios-design-system.md` 因此規定「系統已提供的能力不自己重造 (含進度)」。

## Goals / Non-Goals

**Goals:**

- 以可重現的量測確認標題漏畫的根因，修正後四條內容型雜訊在整批執行下不再出現，並從已知雜訊清單移除。
- 修正不改變任何既有畫面 (基準圖不重錄)、不拿掉系統 `ProgressView` 的進度語意、不破壞英文模式的標題。

**Non-Goals:**

- 像素型雜訊 (導覽列差值個位數) 與清單中其他非進度列的項目。
- 進度列外觀調整、`BLProgressView(title:value:tint:trailingText:)` 呼叫形狀與呼叫端改寫。
- 第 6 步其他 change (6a 起) 的範圍。

## Decisions

### 以整批執行的失敗次數作為量測，五輪為一組

單獨執行無法重現，所以修正前、各實驗與修正後都以同一種量測比較：在 iPhone 17 (`DDAA3311-B464-4DD3-96B8-360B26AF1929`，鎖淺色) 以 `-only-testing:BuyLedgerTests/SnapshotTests` 整批執行五輪，記錄四條目標測試各自的失敗次數 (以及任何差異只有進度列標題消失的其他 snapshot 失敗)、每輪的 `totalTestCount` 與 result bundle 路徑，並保存失敗圖 (執行結束後、下一次安裝前，從模擬器 App 容器 `tmp/SnapshotTests+<區域>/` 複製出來)。

- 五輪是估計值：依目前「四次都失敗」的觀察，五輪足以分辨「仍會失敗」與「不再失敗」。若修正前基準五輪中四條合計失敗少於 3 次，改為每組十輪並記錄理由，之後各組一律用同樣輪數。
- 量測期間不得有其他程式改動；每輪前不重錄、不刪除任何基準圖。

替代方案：寫一個在單一測試內反覆渲染的重現測試。單獨執行時不重現，觸發條件與整批執行時同一個 process 先前渲染過的畫面有關，沒有證據能在單一測試內重建，所以不作為主要量測；實作時若意外找到可穩定重現的單一測試，可以補充，但不取代整批量測。

### 兩個受控實驗與判定規則

兩個暫時變體各自只改 `BLProgressView` 一處，其餘程式不動；每個變體先以方法層單獨執行四條目標測試，確認畫面逐像素等於既有基準圖 (前提不成立就修正變體，不得重錄)，再跑一組整批量測，量完立即還原並以 `cmp` 確認還原：

- **實驗 A (不查本地化表)**：標題改為 `Text(verbatim: title)`，仍經 `configuration.label`。正體中文的本地化 key 就是顯示文字，正體中文 snapshot 畫面不變；英文 snapshot (`campaignListView_英文月分組_符合基準圖`) 會改顯示中文標題而失敗，判讀時排除 (2026-10-06 執行時才發現，原描述漏了這條)。
- **實驗 B (標題不經 configuration.label)**：`BLProgressView` 自己以與 `BLProgressViewStyle.makeBody` 相同的結構排版 (外層 `VStack(alignment: .leading, spacing: 5)`、`HStack` 內標題、`Spacer`、目前值，字型與顏色相同)，標題仍是 `Text(LocalizedStringKey(title))`，下方的 `ProgressView(value:)` 不帶標籤、只套 `BLProgressViewStyle`。

判定規則 (以修正前基準該組失敗合計至少 3 次為前提)：

| 實驗 A | 實驗 B | 判定的根因 | 採用的修法 |
| --- | --- | --- | --- |
| 0 次 | 仍失敗 | 標題的本地化查表 | 修法 A' |
| 仍失敗 | 0 次 | 經 `configuration.label` 轉交的標題 | 修法 B' |
| 0 次 | 0 次 | 兩者的組合 (查表的標題經 `configuration.label` 轉交) | 修法 A' (改動較小，保留現有結構) |
| 仍失敗 | 仍失敗 | 不在這兩個假設內 | 停下回報使用者，不自行嘗試其他修法 |

「0 次」指該組每一輪四條都通過；次數下降但不為 0 視為「仍失敗」。

**判定結果 (2026-10-06，task 2.1 至 2.3)**：

| 量測組 (各五輪，同一模擬器狀態) | `quoteView_非零試算輸入_顯示成本與建議售價` | `campaignListView_依年分組_符合基準圖` | 其他三條目標 |
| --- | --- | --- | --- |
| 修正前基準 | 5／5 | 5／5 | 0／5 |
| 實驗 A | 5／5 | 5／5 | 0／5 |
| 實驗 B | 0／5 | 0／5 | 0／5 |

- 兩條失敗都只少一個標題，各組差異範圍逐像素相同；每個實驗後不改程式的對照輪失敗都回來。
- `campaignListView_依年分組_符合基準圖` 不在原四條目標內，但徵狀相同；哪一條、哪一列消失會隨模擬器狀態改變 (同日稍早一次整批只有依月分組失敗)，同一狀態下是確定性的。因此目標擴大為「所有含 `BLProgressView` 的 snapshot，任何只差進度列標題的失敗都算」。
- 依判定表第二列：根因是經 `configuration.label` 轉交的標題，採用修法 B'。

### 修法 A'：標題先解析成字串再交給 configuration.label

**不採用** (2026-10-06 判定：實驗 A 沒有消除漏畫)，保留記錄。

`BLProgressView` 讀 `@Environment(\.locale)`，以 `AppLanguage(locale:)` 換算 App 語言，再以 `localized(_:)` 先把 `title` 解析成字串，再以 `Text(verbatim:)` 交給 `ProgressView` 的 label。這與根分頁標題 `rootNavigationTitle(_:language:)` 的既有做法一致 (`navigationTitle` 不會隨 `\.locale` 可靠地重新解析 String Catalog)。設計系統元件不持有 `AppLanguage` 狀態，只由 `\.locale` 換算，符合 `ios-accessibility-localization.md` 的慣例。結構與進度語意不變。

### 修法 B'：標題與目前值由 BLProgressView 自己排版，進度語意留在系統 ProgressView

**採用** (2026-10-06 判定，依據見「兩個受控實驗與判定規則」的判定結果)。

`BLProgressView` 以實驗 B 的結構排版，系統 `ProgressView(value:)` 保留在元件內 (只套 `BLProgressViewStyle` 畫進度條)。無障礙寫法 (2026-10-06 實測後改定，取代原先「可見文字隱藏、`ProgressView` 加 `.accessibilityLabel`／`.accessibilityValue`」)：可見的標題與目前值**不**隱藏，整個元件以 `.accessibilityElement(children: .combine)` 合併成一個無障礙元素。

實測 (iPhone 17，`CampaignProgressAccessibilityTests` 與 `mobilebuildmcp ui-automation snapshot-ui --verbose`)：

| 寫法 | 開團列合併朗讀 | 開團詳情結算區單獨聚焦 |
| --- | --- | --- |
| 修正前 (style 畫 `configuration.label`) | `…、到貨、0/3、收款、$11,800` | 元素標籤「收款進度、70%」，值 70% |
| 原定寫法 (文字隱藏＋`.accessibilityLabel`／`.accessibilityValue`) | `…、到貨、收款` (缺目前值，UI 測試失敗) | 未量 |
| 文字隱藏＋`ProgressView` 帶標籤但 style 不畫 | 進度列完全沒有貢獻 (UI 測試失敗) | 未量 |
| **採用：文字不隱藏＋整個元件 `.combine`** | `…、到貨、0/3、收款、$11,800` (中英文 UI 測試通過) | 元素標籤「收款進度、70%」，值 70%，與修正前相同 |

父層合併朗讀讀的是實際畫出的文字子元素，所以修正前的朗讀內容其實來自 style 畫出的標籤；採用的寫法讓同一段文字由元件自己畫出，系統 `ProgressView` 仍在同一個元素內提供進度值。`BLProgressViewStyle` 只負責進度條：有標籤時的上方一列改由 `BLProgressView` 承擔，`makeBody` 的標籤列條件分支隨之移除，三個只畫進度條的呼叫端畫面不變。

- 「系統已提供的能力不自己重造」：進度語意仍來自系統 `ProgressView`，只有文字排版移出 style，不算重造。
- 朗讀順序與內容以下方的 UI 測試守住；單獨聚焦的朗讀以上表的實測為準。

### 先補朗讀與英文標題的 UI 測試

新增 `BuyLedgerUITests/Tests/Campaigns/CampaignProgressAccessibilityTests.swift`，以 `LaunchOptions(seed: .campaignsWithOrders)` 啟動，切到開團分頁後，以 `BLAccessibilityID.Campaigns.row(campaignID: "CMP-SAMPLE-KR-APR")` 取得「四月韓國團」列 (透過 `CampaignsScreen`)：

- 正體中文：斷言列的 `label` 含 `到貨、0/3、收款、$11,800`。
- 英文 (`language: .english`)：先以 `ui-automation snapshot-ui` 讀取實際標籤，把實測的英文片段 (含 `Arrived` 與 `Payment` 及其目前值) 寫成獨立字面值斷言。

這是 Regression 守門 (目前已成立)：以變異確認守得住，拿掉 `BLProgressView` 的標題時兩條都失敗。修正前後都必須通過。

### 文件同步

- `.claude/rules/ios-unit-tests.md`：四條測試從已知雜訊清單移除；內容型徵狀的說明依實際根因改寫，若清單中已沒有內容型項目，就刪掉內容型的說明，只保留像素型。
- `.claude/rules/ios-design-system.md`：修法 A' 時補「設計系統元件內交給系統元件標籤的本地化標題，先以 `AppLanguage(locale:).localized(_:)` 解析成字串」；修法 B' 時把「系統已提供的能力不自己重造」補一句：進度語意必須留在系統 `ProgressView`，文字可以由元件自己排版。

**Supersedes**: progress-title-render-reliability / 原驗收「iPhone 17 與 iPad 的 UI 主回歸全綠」。使用者 2026-10-06 裁決略過 iPad 主回歸：重啟後硬體鍵盤恢復連線，`KeyboardDismissTests` 未通過，軟體鍵盤前提未成立；iPad 主回歸未執行、未驗證。task 4.4 保留原計畫與實際結果作為歷史紀錄，封存驗收以 iPhone 17 主回歸為準。

## Implementation Contract

**行為**：

- 帶標題的進度列在任何渲染 (含整批 snapshot 執行) 都畫出標題、目前值與進度條；只帶數值的進度條仍只畫一條進度條。
- 開團列的無障礙標籤依序含每個進度列的標題與目前值 (正體中文為 `到貨、0/3、收款、$11,800`)，英文模式的標題是英文。

**介面**：

- `BLProgressView(title:value:tint:trailingText:)` 與 `BLProgressViewStyle(tint:track:)` 的呼叫形狀不變，十一個呼叫端不改。
- 新 UI 測試檔 `CampaignProgressAccessibilityTests` 兩條測試 (正體中文、英文)。

**失敗模式**：

- 修正前基準不足以判定 (五輪合計少於 3 次)：改用十輪。
- 兩個實驗都不能歸零：停下回報，附上三組量測。
- 變體或修正讓任何既有基準圖改變：修正寫法，不重錄。
- 朗讀或英文標題測試失敗：停下回報。

**驗收**：

- 修正前基準、兩個實驗與修正後各一組整批量測，數字、bundle 路徑與失敗圖記在 task 下方；根因判定依上表寫明。
- 修正後一組整批量測中，所有含 `BLProgressView` 的 snapshot 都沒有只差進度列標題的失敗 (至少涵蓋四條目標與 `campaignListView_依年分組_符合基準圖`)。
- 完整單元回歸中這四條都不失敗。
- 既有基準圖全部不重錄即通過，`git status` 中 `__Snapshots__` 沒有任何變動。
- `CampaignProgressAccessibilityTests` 在修正前後都通過，變異驗證有效。
- iPhone 17 的 UI 主回歸全綠；style 閘門 0 違規。iPad 因軟體鍵盤前提未成立，依使用者 2026-10-06 裁決略過主回歸，未驗證 (詳見 task 4.4)。

**範圍**：

- 範圍內：`BLProgressView`、`BLProgressViewStyle`、新 UI 測試、`ios-unit-tests.md` 與 `ios-design-system.md` 同步。
- 範圍外：Non-Goals 列出的項目；判定表以外的修法 (需使用者另行決定)。

## Risks / Trade-offs

- [整批執行的失敗與測試順序、模擬器狀態有關，五輪可能不足以分辨] → 修正前基準不足時改十輪；量測都在同一台、鎖淺色的模擬器上連續進行，模擬器狀態異常時先重開機並記錄。
- [實驗 B 或修法 B' 的排版與原本 style 有細微差異，造成所有進度列 snapshot 失敗] → 每個變體先以方法層單獨執行確認逐像素相同，才進行量測。
- [修法 B' 改變 VoiceOver 的朗讀] → 先補朗讀測試；原定的 `.accessibilityLabel`／`.accessibilityValue` 寫法實測讓合併朗讀缺目前值，經使用者 2026-10-06 裁決改為「文字不隱藏＋整個元件合併」，合併與單獨聚焦的朗讀都實測與修正前相同。
- [修法 A' 讓標題不再隨 `\.locale` 自動更新] → 由 `\.locale` 換算語言並以英文模式 UI 測試守住。
