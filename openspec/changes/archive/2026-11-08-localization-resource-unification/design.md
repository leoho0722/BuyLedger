## Context

本 change 接在 `string-catalog-warning-cleanup` 之後：那個 change 把第三類 32 筆元件參數改成 `LocalizedStringResource`，第一類 32 筆 (帶參數格式字串)、第二類 21 筆 (State／回傳值) 暫標 manual。本 change 從那個 change archive 後的狀態開始。

2026-11-08 apply 期間由四個實作者唯讀盤點 (主對話派工，盤點前後檔案雜湊一致)，發現更早就以 `String` 攜帶 key 的寫法：catalog 167 筆 manual 中有 105 筆早於 `string-catalog-warning-cleanup`，扣除已被抽取的 24 筆，約 81 筆分散在原計畫沒列到的約 40 個檔。使用者 2026-11-08 決定併入本 change，本 design 的「既有以 String 攜帶的列舉與元件」以下各節為擴充後新增。

`AppLanguage` (`apps/ios/BuyLedger/Shared/Localization/AppLanguage.swift`) 目前的解析寫法 (2026-11-07 實測，正式程式碼呼叫處)：`localized(_: String.LocalizationValue)` 25 處 (含 `Mirror` 反射的 `extractKeyAndArgs`)、`localizedString(forKey:_:)`／`(forKey:arguments:)` 12 處、`static format(_:_:locale:)` 34 處、`rootNavigationTitle(_:language:)` 7 處；語言選擇靠 `localizedBundle` 找對應的 `.lproj`。`string-catalog-warning-cleanup` 另會新增 2 處 `AppLanguage.format` (報價與手續費的百分比提示)。

已知事實：

- `Text(LocalizedStringResource)` 跟隨畫面環境的 `\.locale`：2026-11-07 在系統語言 zh-Hant-TW 的模擬器以 App 英文模式實測，開團詳情的收款狀態讀到 `Received`。
- `String(localized: resource)` 依 `resource.locale` 選語言：Apple 文件明載「To perform localization in a different locale, change this value before passing it to a String … initializer」；2026-11-08 任務 1.1 在系統語言 zh-Hant 的 iPhone 17 (iOS 26.5) 與 iPad Air 11-inch (M4) (iPadOS 27.0) 模擬器實測成立，拿掉 `locale` 設定時 6 筆英文案例全部失敗。
- 整數參數兩條路徑都依 locale 加千分位：1.1 實測 `common.general.label.pointLd` 帶 1234，`resolve` 與 `localizedString(forKey:arguments:)` 都輸出 `第 1,234 筆`／`Point 1,234`；單複數與四個位置參數的輸出也逐字相同。
- 以明確 key＋defaultValue 建構時，編譯器抽出原 key，`.stringsdata` 的 `value` 為插值形成的格式 (例如 `fx.rates.message.apiErrorCode` 為 `%@`)；Xcode IDE 同步不改寫 catalog 的來源語言值：任務 1.2 移除 `orders.lookup.label.itemsCreated` 的 manual 後在 Xcode IDE 建置 Debug，`.stringsdata` 抽出該 key (`value` 為 `%lld`)，catalog 雜湊不變、建置 0 筆警告，英文 `4 Items Created` 與正體中文 `目前已建立 4 項` 與修改前相同 (2026-11-08 實測)。
- 命令列建置不會同步 catalog，只有 Xcode IDE 建置會。
- `LocalizedStringResource` 在 SDK 宣告 `Equatable`、`Codable`、`Sendable`，不是 `Hashable`；`QuoteRateFeature.State.errorMessage` 已是 State 內的先例，測試以字面值設定預期值。

## Goals / Non-Goals

**Goals:**

- 正式程式碼不再以 `String` 攜帶 catalog key；所有本地化文字以 `LocalizedStringResource` 表示，參數型別由插值決定。
- `AppLanguage` 只剩一個把 resource 轉成 `String` 的入口，移除 `Mirror` 反射與 `CVarArg` 路徑。
- catalog 的 manual 只留給編譯器抽不到的 key，其餘交由 Xcode 追蹤使用。
- 畫面文案、單複數、位置參數與 App 內語言切換的行為與修改前相同。
- 同時顯示 key 與使用者資料的共用元件分成兩種輸入，使用者資料一律原樣顯示 (目前會被當成 key 查表)。

**Non-Goals:**

- 不改 key 名稱與翻譯文案。
- 不重新設計 Design System 圖表元件的介面，對外參數只做「不以 `String` 攜帶 key」所需的型別調整。
- 不使用 Xcode 為 manual 條目產生的符號 (使用者決策)。
- 不改 `navigationTitle` 的既有處理：根分頁標題仍先解析成 `String` 再交給 `navigationTitle`。
- 不新增 catalog key；以字面值建構、編譯器抽得到的 `LocalizedStringKey` 參數與回傳值不改型別 (見「LocalizedStringKey 的界線」)。

## Decisions

### 單一解析入口 AppLanguage.resolve

新增 `func resolve(_ resource: LocalizedStringResource) -> String` 與 `static func resolve(_ resource: LocalizedStringResource, locale: Locale) -> String` (後者以 `AppLanguage(locale:)` 判斷語言，供讀取 `@Environment(\.locale)` 的畫面使用)。實作為複製 resource、設定 `locale` 為所選語言後呼叫 `String(localized:)`。

- 名稱與既有 `localized(_:)` 不同 (主對話代選)：兩者都接受字串字面值，遷移期間同名會讓字面值呼叫產生歧義。
- 使用時機：畫面一般文字直接 `Text(resource)`；只有必須是 `String` 的地方 (`AXChartDescriptor`、圖表元件的字串參數、根分頁標題、`Text(verbatim:)` 的組合) 呼叫 `resolve`。
- `rootNavigationTitle(_:language:)` 的參數改為 `LocalizedStringResource`，內部經 `resolve` 解析；其他呼叫端都是字面值，不需修改。
- 不再以 `localizedBundle` 尋找 `.lproj`；若 iOS 試做顯示 `resource.locale` 無法選到正確語言，停止並回報使用者，不自行改走其他路徑。

### 帶參數字串用明確 key＋defaultValue

第一類改寫為 `LocalizedStringResource("<key>", defaultValue: "\(arg1)\(arg2)")` (使用者決策)。

- 插值順序決定參數序號，必須與 catalog 值中的位置標記 (`%1$lld`、`%2$@`) 一致。
- 數量以 `Int` 插值 (維持單複數變化)；金額、百分比、日期先以 `FormatStyle` 依 locale 格式化成 `String` 再插值。
- 與 `String(format:)` 的差異 (整數千分位、單複數選擇、位置參數) 由 1.1 的測試固定；有差異時停止並回報。
- 替代方案「產生的符號」：參數由 catalog 決定、寫錯編譯失敗，但條目必須維持 manual (見 proposal Alternatives)。

### 第二類 State 與回傳值改為 LocalizedStringResource

以 `String` 攜帶 key 的 State、`@Shared`、列舉關聯值與回傳值改為 `LocalizedStringResource`，以字面值建構：

- 載入失敗鏈：`OrdersLoadFeature`／`CampaignLoadFeature` 的 `@Shared var errorMessage`、`OrderListFeature`／`CampaignListFeature` 的 `@SharedReader`、`OrdersLoadState.failed`、`OrdersListQuery.loadState`、`DashboardFeature`／`InsightsFeature`／`CampaignListFeature` 的 `failed` 關聯值、`BLLoadFailureView(message:)`、`CampaignListView.loadFailure(message:)`。
- 寫入失敗：`OrderWriteOperations.Failure.message`。
- 標題與訊息：`OrderEditFeature.State.navigationTitleKey`、`CampaignEditFeature.State.navigationTitleKey`、`CampaignEditFeature.State.nameConflictMessage`、`OrderListFeature.State.navigationTitleKey` (含多選筆數)、`OrdersToolbarContent` 的全選／清除按鈕。
- `DashboardFormatters` 的走勢描述：三個分支各自建構 resource，不以 `String` 變數暫存 key。
- `OrderFormatters` 的類別與付款方式篩選摘要：目前先解析成 `String` 再包回 `LocalizedStringKey`，改為回傳 resource。

測試：TestStore 的預期值沿用字面值 (與 `QuoteRateFeature` 先例相同，字面值建構的 resource 相等)；帶參數的 resource 以 `.key` 斷言 key 身分，再以 `AppLanguage.resolve` 斷言兩種語言的文字。預覽傳入的中文示範文字 (例如 `DashboardView` 預覽的 `.failed("訂單載入失敗，請稍後再試")`) 改用既有 key。

### LookupKind 屬性改為 LocalizedStringResource

`LookupKind` 的 9 個 key 屬性 (`title`、`entryTitle`、`entrySubtitle`、`addButtonTitle`、`emptyTitle`、`emptyDescription`、`addFormTitle`、`addFormMessage`、`nameFieldPlaceholder`) 改回傳 resource，移除 `string-catalog-warning-cleanup` 在 `LookupManagementPresentations` 加的邊界轉換；`systemImage` 維持 `String`。

### Design System 元件內部改用單一入口

`BLBarChart`、`BLDonutChart` 的無障礙摘要改用 resource 並經 `AppLanguage.resolve(_:locale:)` 解析；`BLSparkline` 的預設描述 closure 不再寫死 `AppLanguage.traditionalChinese`，改依環境 locale 解析；`BLFormatters` 的今天／昨天改經 `resolve`。這部分呼叫端不需修改，對外參數的調整見下段。

2.6 實作時為符合「不以 `String` 攜帶 key」做了三處對外參數調整，主對話 2026-11-08 接受 (字面值呼叫端不需修改)：`BLDonutChart.centerTitle` 改 `LocalizedStringResource`；`BLSparkline.summary` 改 `LocalizedStringResource?`、點位描述 closure 改可選 (未提供時依環境 locale 解析)；三個圖表的 `axisXTitle`、`axisYTitle`、`seriesName` 原本以 key 字串當預設值，改為 `String? = nil`，`nil` 時元件依環境 locale 解析原本的 key。4.4 依「同組屬性依字母序」把 `BLBarChart` 的 `data` 移到 `axisYTitle` 之後，memberwise init 的參數順序跟著改變，呼叫端 (`InsightsTrendCard`、`SnapshotSharedTests`、元件預覽) 已同步改寫；4.6 再刪除呼叫端重複傳入的預設軸標題、序列名稱與點序描述，預設文字只留在元件一處。

### 既有以 String 攜帶的列舉與元件

盤點結果 (2026-11-08，`inventory-*` 四份報告由主對話合併)：

- 列舉的 `title` 回傳 key 字面值：`OrderStatus`、`OrderStatusFilter`、`OrderDatePeriod`、`PaymentReceiptStatus`、`CampaignStatus`、`CampaignGrouping`、`RootTab`、`InsightsDateRange` (`title`、`trendCardTitle`)、`CustomerTier`。改為 `LocalizedStringResource` (字面值建構)，呼叫端 `Text(LocalizedStringKey(x.title))` 改為 `Text(x.title)`、`Tab(x.title, systemImage:value:)`。型別一改，`LocalizedStringKey(...)` 包裝的呼叫端全部無法編譯，所以每個列舉與它的全部呼叫端在同一個任務內完成。
- 只收 key 的元件參數：`BLFilterChip`／`BLFilterChipLabel` 的 `title` (`LocalizedStringKey`，呼叫端以變數建構)、`BLNumberField` 的標題 (配合 `QuoteInputsCard` 的標籤)、`LookupNameEditorSheet` 的 `title`／`submitTitle` 改為 `LocalizedStringResource`。字面值呼叫端不需修改。
- 其他以 `String` 攜帶：`QuoteInputsCard` 的標籤與單位、`QuoteBreakdownCard.BreakdownItem.label`、`OrderCostBreakdown.DonutSlice.label`、`InsightsFormatters.CostSlice.label`、`OrderEditFeature` 的導覽標題與訂購日期 helper、`OrderMergeFeature.candidateFilterNotice`、`MoreView` 的入口標題、`OrdersListQuery.filterSummary` 內的 `String.LocalizationValue`、`OptionPickerSheet` 預覽的 `String.LocalizationValue`。
- 已符合或只是資料路徑、不需修改的檔 (只剩 catalog 的 manual 殘留，交 3.2)：`AISummaryFeature`／`AISummaryView`、`SettingsView`、`OrderFilterSheet`、`OrderCategoryFilterRows`、`OrderCategoryPickerSheet`、`CampaignDetailSettlementSection`、`CampaignDistributionRow`、`InsightsStats`、`FxView`、`PaymentMethodEditorSheet`、`OptionPickerAddSection`、`OptionPickerList`、`LookupManagementFeature+Destination`、`OrderEditPickerDestination`、`OrderEditCostSection`。

### 混用元件分成 resource 與 verbatim 兩種輸入

`BLStatusPill` (`title: String` 內部包 `LocalizedStringKey`) 同時接收狀態標題 (key)、`BLTagPill` 傳入的商品類別 (使用者資料) 與 `OrderCategoryGrid` 的已選數量；`BLProgressView` 同時接收字面 key、`InsightsCampaignProfitCard` 的「名次. 開團名稱」(使用者資料) 與 `QuoteBreakdownCard` 的 key。使用者資料目前會被當成 key 查表，名稱等於某個 key 時顯示成翻譯 (主對話代選以下做法)：

- `BLStatusPill` 提供 `init(_ title: LocalizedStringResource, …)` 與 `init(verbatim title: String, …)`；`BLProgressView` 原本就以 `title:` 標籤建構，為相容既有呼叫端改為 `init(title: LocalizedStringResource, …)` 與 `init(verbatimTitle: String, …)` (4.4 審查提出，主對話代選保留)。內部都以 private enum 分流成 `Text(resource)` 或 `Text(verbatim:)`。不用單一 Configuration struct 搬欄位：兩種來源互斥，呼叫端本來就知道是哪一種。
- 依擴充、遷移、收縮三段進行，每段結束都能建置：1.3 新增兩個 init 並暫留既有 `String` init；各批遷移自己的呼叫端；3.1 移除 `String` init。
  - 過渡期的多載解析 (2026-11-08 以 `swiftc -swift-version 6` 實測)：`String` 與 `LocalizedStringResource` 兩個無標籤 init 並存時，字串字面值選 `String` init，`LocalizedStringResource` 變數選 resource init；移除 `String` init 後字面值改選 resource init。所以過渡期字面值呼叫端仍走舊路徑 (抽不到)，3.1 移除後才被抽取，殘留的 `String` 變數呼叫端會編譯失敗。
- `BLTagPill` 只傳使用者資料，改呼叫 `verbatim:`；`OrderCategoryGrid` 的已選數量改為明確 key＋defaultValue 的 resource；`InsightsCampaignProfitCard` 改呼叫 `verbatim:`。
- `BLBadge` 沒有正式呼叫點，依 `.claude/rules/ios-design-system.md`「零呼叫點的元件直接刪除」刪除 (主對話代選)，不遷移。
- 元件預覽的中文示範字串改為 `verbatim:` 或 App 程式碼也在用的 key，不新增 key。

### LocalizedStringKey 的界線

以字面值建構的 `LocalizedStringKey` 參數或回傳值 (例如 `OrderEditSelectionRow.title`、`AppLockFormatters` 的回傳值) 編譯器抽得到，不在範圍；`LocalizedStringKey(非字面值)` 等同以 `String` 攜帶 key，一律改掉，由 3.1 的掃描守門擋下 (主對話代選)。只有需要接收已遷移 resource 的元件 (`BLFilterChip`／`BLFilterChipLabel`、`BLNumberField`) 才改型別。

### 混用值的介面

主對話代選，理由是 key 與 verbatim 文字在型別上分開，呼叫端不必再猜：

- `CustomerTier.title` 改為巢狀 enum `DisplayTitle` (`.localized(LocalizedStringResource)`、`.verbatim(String)`)：new／regular 是 key，VIP 是 `.verbatim("VIP")`，catalog 沒有 `VIP` 條目也不新增；客戶列與排名卡保留既有 VIP 樣式分支。
- `QuoteInputsCard` 的單位改為卡片內 enum `Unit` (`.localized`、`.verbatim`)：`quote.calculator.label.twdItem` 是 key，來源幣別代碼與 `%` 是 verbatim；標籤一律 `LocalizedStringResource`。
- `InsightsFormatters.trendDelta` 改回傳 `String?`：有比較值時是格式化百分比 (verbatim)，沒有時回傳 `nil`，由畫面顯示字面值 `insights.chart.label.comparison`。`DashboardKPITile.delta` 的內容全是格式化結果，型別改 `String` 並以 verbatim 呈現；`DashboardKPITiles` 的進行中開團數改用明確 key＋defaultValue。
- `OrdersListQuery.filterSummary` 維持回傳 `String` (key 解析後與使用者選的類別、付款方式名稱以分隔符組合，組合數不固定)，內部改經 `AppLanguage.resolve`；篩選鈕標題改為 `LocalizedStringResource("orders.filter.label.filterSummary", defaultValue: "\(summaryText)")`，使用者資料以參數帶入、不被查表。
- 已解析的日期分段標題 (`OrderDateSection.title`) 在 `OrdersCompactListView`、`OrderMergeCandidateSheet` 改為 `Text(verbatim:)`，不改 `OrderDateSection` 的型別。
- 由 `.key` 衍生、不顯示的 `String` 識別值可以保留 (既有 `OrderCostBreakdown.Component.id` 先例)；`QuoteBreakdownCard.BreakdownItem.id` 改為 `label.key`。

### 系統對話框的理由文字維持系統語言

Face ID／Touch ID 解鎖理由 (`settings.preference.label.authenticateUnlockApp`，`AppLockFeature` 解鎖與 `SettingsFeature` 開啟 App 鎖定時傳給 `BiometricAuthService.authenticate`) 原本以 `String(localized:)` 依系統語言解析，與系統對話框的標題、取消鍵同語言。2026-11-08 apply 期間發現，使用者決定維持系統語言：兩個 reducer 以注入的 `@Dependency(\.locale)` 經 `AppLanguage.resolve(_:locale:)` 解析，不新增 App 語言狀態。差異：系統語言不是中英文時，`AppLanguage(locale:)` 視為英文，原本則退回 catalog 的來源語言 (正體中文)。

### 依功能分批遷移

先擴充 (1.x：新增 `resolve`、試做、共用元件新增 resource 與 verbatim init)，再依功能分批遷移 (2.x)，最後收尾 (3.x：移除舊 API 與過渡 init、清理 manual)。每批只改自己的檔案，結束時建置與該批測試通過。catalog 在 2.x 期間不動：已轉為字面值引用的 key 仍標 manual，Xcode 不會改動 manual 條目，留到 3.2 統一清理，避免多個批次同改 catalog。

### 收尾清理 manual 與掃描守門

- 移除 `localized(_: String.LocalizationValue)`、`extractKeyAndArgs`、`localizedString(forKey:arguments:)`、`localizedString(forKey:_:)`、`static format(_:_:locale:)`，以及不再使用的 `localizedBundle`；移除 `BLStatusPill`、`BLProgressView` 的過渡 `String` init。
- 新增掃描守門 (`LocalizationCatalogSourceGuardsTests`)：`String(localized:` 與 `localizedString(forKey:` 只能出現在 `AppLanguage.swift`；正式程式碼不得出現 `AppLanguage.format`、`extractKeyAndArgs`、`String.LocalizationValue`；`LocalizedStringKey(` 後面必須是字串字面值。
- 清理 manual (使用者決策)：以 Debug 與 Release 的 `.stringsdata` (排除 `GeneratedStringSymbols_*` 來源) 求兩種建置都被抽取的 key，這些 key 一律移除 manual；剩下的 manual 逐筆列出抽不到的理由寫入本 design (預期為 `SettingsView` `#if DEBUG` 內的 8 個：`orders.general.label.model` 與 7 個 `settings.preference.*`)。
- 3.2 結果 (2026-11-08，3.1 完成後以 `mobilebuildmcp` 建置 Debug 與 Release)：手寫程式碼抽出 Debug 476 個、Release 468 個 key，全在 catalog 內；原 166 筆 manual 中 157 筆兩種建置都抽得到，移除 manual；`common.general.message.afterConfirmationLd` 沒有手寫程式碼引用 (文字與使用中的 `orders.lookup.message.confirmRecalculateNotice` 相同)，依「A key with no reference in hand-written source code SHALL be removed」刪除 (主對話代選，比照 `string-catalog-warning-cleanup` 刪除未引用條目的先例)。3.2 完成時 catalog 的 `git diff` 只有 `extractionState` 行與被刪除的條目；之後 4.4 的 S15 又把 8 個多參數 key 的值改用位置標記，最終 diff 另含這 16 個值的修改。
- 保留的 8 筆 manual，理由都是只在 `SettingsView` 的 `#if DEBUG` 區塊引用、Release 建置抽不到：`orders.general.label.model` (AI 模型列)、`settings.preference.label.selectAiModel`、`settings.preference.label.customModel`、`settings.preference.label.customAiModel`、`settings.preference.label.modelsAvailable`、`settings.preference.message.enterModelName`、`settings.preference.message.modelNameFor`、`settings.preference.message.enterCustomModel` (AI 模型選擇器)。
- 主 spec「String Catalog extraction state matches source references」原本把「以 `String` 經 `AppLanguage` 解析、存在 State 或由函式回傳」列為 manual 路徑，並以 `orders.general.message.orderSavedTry` 為 manual 範例；本 change 移除這些路徑後改為 MODIFIED，範例改成「由函式回傳的 resource 被抽取」與「只在 `#if DEBUG` 的 key 維持 manual」。

### 驗收方式

- 抽取差集：Debug 與 Release 的 `.stringsdata` (排除生成符號來源) 抽出的 key 全在 catalog 內，catalog 內無 `extractionState` 的 key 兩種建置都抽得到，manual 的 key 兩種建置至少一種抽不到。
- IDE 建置：記錄 catalog 的 SHA-256，Xcode IDE 建置 Debug 後不變、Issue Navigator 對 `Localizable.xcstrings` 0 筆警告、`Package.resolved` 未被刪除。
- 測試：完整單元回歸跑 iPhone 17 iOS 26.5 模擬器 (淺色)。本 change 牽動約 190 條 UI 測試 (2026-11-07 盤點全部 242 條，依各批改到的功能估算)，完整 UI 回歸只在審查修正後跑一次 (iPhone 17 (iOS 26.5) 與 iPad Air 11-inch (M4) (iPadOS 27.0) 模擬器，使用者同意)；英文與正體中文、不重開 App 的雙向切換以 `ui-automation` 實測；擴充範圍另需實測根分頁列與側邊欄標籤 (`Tab(LocalizedStringResource)` 是否即時切換沒有文件保證)、狀態膠囊、篩選鈕、客戶分級與報價輸入單位，以及名稱等於 key 的使用者資料原樣顯示。

### 實測與審查紀錄

- 4.3 (2026-11-08，iPhone 17 iOS 26.5，系統語言 zh-Hant)：以 `ui-automation` 確認根分頁列標籤、「更多」入口、主檔管理四頁、客戶分級與筆數、匯率連線與換算、報價欄位與單位 (`TWD/item` 翻譯、`%` 原樣)、訂單狀態膠囊與篩選鈕、多選標題、開團狀態與進度列、分析區間、總覽件數，在 zh-Hant → en → zh-Hant 不重開的切換下即時更新，`Tab(LocalizedStringResource, …)` 的標籤也即時切換；開團載入失敗訊息隨語言切換。寫入失敗通知 (表單關閉後呈現)、新增訂單標題、開團重名訊息、照片區段張數與上限以量完即刪的暫時 XCUITest 在英文模式確認；名稱等於 key 的使用者資料由 1.3 的 `BLTagPill` snapshot 與 `string-catalog-warning-cleanup` 的開團名稱 snapshot 佐證 (`ui-automation` 輸入受 Mac 輸入法影響)。
- 4.3 發現既有缺陷 (不在本 change 範圍)：訂單載入持續失敗時，切換分頁會讓總覽 `.task` (掛在依 `screenState` 切換分支的 `Group` 上) 每次換分支都重送 refresh，Root 再請訂單重新載入，形成無限重新載入，訂單清單停在載入中。以 HEAD 建置重做同樣步驟症狀相同。因此「訂單清單載入失敗訊息隨語言切換」改以開團載入失敗驗證，spec 情境的前提也改為開團清單 (verify W1，使用者 2026-11-08 決定)；訂單清單待修正該缺陷的 change 完成後再驗。使用者 2026-11-08 決定另開 change 修正。
- 4.4 審查 (右側 Codex 唯讀審查＋主對話同步審查，前後檔案雜湊一致)：沒有行為錯誤；W1 掃描守門可被字串串接與空白繞過 → 修；W2 圖表摘要測試未呼叫正式函式 → 補測試；W3 匯率時間戳只驗前綴 → 時間依系統時區格式化是既有缺口，改為斷言插入的時間不為空並記錄；風格 S01 至 S14 依「改到的檔整檔對齊」全修；S15 catalog 8 個多參數 key 改用位置標記 (顯示文字不變)。取捨由主對話代選。
- 4.1 (2026-11-08)：差集結果與 3.2 完成時相同 (Debug 抽出 476 個、Release 468 個 key，全在 catalog 內；catalog 476 筆中 468 筆無標記、8 筆 manual、0 筆 stale；沒有無標記的 key 在任一建置抽不到)；catalog SHA-256 `30cbdc68ae56025c2cd2c5e23350fd467a843b61a5a392c9b6582e6a75b06d58` 在 Xcode IDE 建置 Debug 後不變，Issue Navigator 對 `Localizable.xcstrings` 0 筆警告，`Package.resolved` 仍在。4.2 完整單元回歸 2028 條通過。
- 4.5 (2026-11-08，4.4 修正後；S15 的位置標記讓 catalog SHA-256 變為 `1bf78b5023e893c787cecf1b7039a6906752f779d7f5fa435b604e6387f13829`)：差集數字與 4.1 相同；IDE 建置 Debug 後雜湊不變、0 筆警告、`Package.resolved` 仍在；完整單元回歸 2036 條通過；完整 UI 回歸 (排除效能測試) iPhone 17 191 條通過、49 條略過 (都是只在 regular 版面成立的案例)，iPad Air 先單獨跑 `KeyboardDismissTests` 2 條通過，再全跑 215 條通過、25 條略過 (都是只在 compact 版面成立的案例)，0 失敗；UI 回歸前後 140 個改動檔雜湊一致。差集腳本只在驗收時使用、不進 repo，判定條件見「驗收方式」。
- verify／review (2026-11-08)：verify 沒有 Critical，W1 spec 情境前提改為開團清單 (見上)、W2 補本節 4.1 與 4.5 的紀錄、W3 改寫圖表元件參數的範圍描述、S1 守門加擋 `LocalizedStringKey.init(非字面值)`、S2 `deadKeys` 加入 `common.general.message.afterConfirmationLd`、S3 三處 defaultValue 改純插值、S4 proposal Impact 對齊實際改動；review 沒有 Critical 或 Warning，3 個 Suggestion (圖表呼叫端重複預設、客戶分級的重複 switch、`OrderEditFeature` 未使用的 `locale` 參數) 全修。修正範圍由使用者 2026-11-08 決定，修法由主對話代選，列為 4.6。
- 4.6 審查 (`t17` 唯讀審查＋主對話同步審查，前後檔案雜湊一致)：沒有 Critical；`CustomerTopCard` 子 view 宣告順序、`LocalizationSourceScanner` 存取層級、本節介面描述的 `BLProgressView` 標籤三項修正 (主對話代選)。W1：掃描器不分辨字串與區塊註解，`"LocalizedStringKey.init(title)"` 這類文字會被判成呼叫；正式程式碼 0 處，原本的 `LocalizedStringKey(` 寫法有同樣限制，誤判方向是測試失敗而非漏判，使用者 2026-11-08 決定不修並記錄。W2：`InsightsCostStructureCard` 圖例在輔助字級未改上下排列、色點未以 `@ScaledMetric` 縮放，HEAD 已存在，`string-catalog-warning-cleanup` 時已同意延後 (會改動輔助字級 snapshot)，使用者 2026-11-08 決定維持延後。
- 4.6 驗證 (2026-11-08)：建置通過；受影響的 18 類單元與 snapshot 測試 0 失敗、snapshot 未重錄；拿掉 `.init` 判斷後 3 個新違規樣本轉紅、合法樣本仍通過；完整單元回歸 2037 條通過 (審查修正前後各跑一次)；受影響的 11 類 UI 測試 iPhone 17 48 條通過、5 條略過，iPad Air 先單獨跑 `KeyboardDismissTests` 2 條通過，再跑 40 條通過、11 條略過，另 2 條 `OrderEditInputFocusUITests` 因單條超過 10 分鐘逾時，單獨重跑後一條通過、一條依設計略過 (iPad 數字 Popover，與 4.5 相同)；審查修正後兩台再跑 `CustomersTests` 各 3 條通過；Xcode IDE 建置 Debug 後 catalog SHA-256 仍為 `1bf78b5023e893c787cecf1b7039a6906752f779d7f5fa435b604e6387f13829`、`Localizable.xcstrings` 0 筆警告、`Package.resolved` 仍在。

### 平行分工

實作者依 2026-11-07 `hc ls` 由主對話代選，開工時依當下查詢結果重新確認：`codex-luna-max-impl` (原名 `codex-impl`) 負責 `AppLanguage` 熱點檔 (1.1、2.3、3.1)、訂單清單與狀態、訂單編輯批次；`claude-sonnet-xhigh-impl` 負責載入失敗鏈、寫入失敗與開團 (含開團與收款狀態列舉)；`claude-haiku-max-impl` 負責總覽／分析／圖表與 catalog 清理；`codex-sol-xhigh-impl` 負責共用元件的過渡 init (1.3) 與客戶／匯率／報價／主檔 (2.7)。2026-11-08 使用者要求新增的 `codex-sol-xhigh-impl` 也派工，1.3 與 2.7 的分配由主對話代選。審查 (含逐檔逐條的 style 閘門) 依根目錄 `CLAUDE.md`，由開工時 `hc ls` 查到的審查用終端 (例如右側 Codex) 與主對話同步進行，沒有審查用終端時改派未參與實作的 agent：使用者 2026-11-07 決定，因 `claude-haiku-max-impl` 本身就是 `haiku-max-implementer`，參與實作後不能再當 style 閘門。

## Implementation Contract

**行為**

- 兩種 App 語言下，所有畫面文字、無障礙描述、導覽標題、單複數與位置參數的輸出與修改前相同；系統語言與 App 語言不同時，輸出依 App 語言。
- 不重開 App 切換語言時，已開啟畫面 (含 sheet、錯誤訊息、根分頁標題) 即時更新。
- 使用者資料 (開團名稱、客戶名稱、主檔名稱、商品類別) 即使等於某個 key 仍原樣顯示，經共用元件呈現時也一樣。

**介面**

- `AppLanguage.resolve(_:)`、`AppLanguage.resolve(_:locale:)` 是唯一把 resource 轉成 `String` 的入口；`rootNavigationTitle(_:language:)` 接 `LocalizedStringResource`。
- 第二類列出的 State、共享值、關聯值與回傳值型別由 `String` 改為 `LocalizedStringResource`；`LookupKind` 的 9 個屬性與「既有以 String 攜帶的列舉與元件」列出的列舉 `title` 同。
- `BLStatusPill` 提供 `init(_ title: LocalizedStringResource, …)` 與 `init(verbatim:…)`，`BLProgressView` 提供 `title: LocalizedStringResource` 與 `verbatimTitle:` 兩個 init (標籤取捨見「混用元件分成 resource 與 verbatim 兩種輸入」)；`BLFilterChip`／`BLFilterChipLabel`、`BLNumberField`、`LookupNameEditorSheet` 的 key 參數為 `LocalizedStringResource`；`CustomerTier.DisplayTitle`、`QuoteInputsCard.Unit` 區分 key 與 verbatim。
- 移除的 API：`localized(_: String.LocalizationValue)`、`localizedString(forKey:arguments:)`、`localizedString(forKey:_:)`、`static format(_:_:locale:)`、`extractKeyAndArgs`、`BLStatusPill`／`BLProgressView` 的 `String` init；刪除零呼叫點的 `BLBadge`。

**失敗模式**

- 1.1 或 1.2 的試做結果與預期不符 (語言選擇錯誤、輸出格式不同、IDE 改寫 catalog 來源值) 時停止，回報使用者決定替代方案，不自行改走其他路徑。
- 漏改的 `String` key 引用在 3.1 移除舊 API 後無法編譯；以字串插值組 key 的寫法由掃描守門擋下。

**驗收**

- 見 Decisions「驗收方式」；各批另以該批列出的單元測試與 `.stringsdata` 檢查驗證。

**範圍**

- 範圍內：`AppLanguage`、第一類與第二類的所有引用處、`LookupKind`、Design System 圖表與 `BLFormatters` 的內部解析、`BLLoadFailureView`、「既有以 String 攜帶的列舉與元件」列出的列舉、元件與呼叫端、catalog 的 manual 清理、相關測試、`.claude/rules/ios-accessibility-localization.md`。
- 範圍外：key 改名、翻譯文案、新增 catalog key、圖表元件的介面重新設計 (「不以 `String` 攜帶 key」所需的參數型別調整除外)、以字面值建構的 `LocalizedStringKey`、`InfoPlist.xcstrings`、產生符號的使用。

## Risks / Trade-offs

- [`resource.locale` 在 iOS 上無法選到 App 語言] → 1.1 以系統 zh-Hant 的測試計畫驗證英文輸出，失敗即停止回報。
- [Xcode IDE 同步會把明確 key＋defaultValue 條目的來源語言值改寫成插值格式] → 1.2 以單一 key 試做並比對 catalog 雜湊，確認後才鋪開。
- [`String(localized:)` 與 `String(format:)` 對整數千分位、單複數的處理不同] → 1.1 固定 0、1、2、1234 與四參數位置重排的輸出。
- [參數插值順序與 catalog 位置標記不一致，編譯器不會發現] → 每個帶參數 key 的批次測試以兩種語言斷言完整文字。
- [測試改動面大 (2026-11-07 全文搜尋 31 個測試檔)] → 依功能分批，每批同時更新自己的測試並在批次結束時通過。
- [`LocalizedStringResource` 的相等比較含 defaultValue 與參數] → 帶參數的 resource 在測試中以 `.key` 加解析文字斷言，不比較整個值。
- [過渡期字面值呼叫端仍走共用元件的 `String` init，key 暫時抽不到] → 3.1 移除 `String` init 後字面值改走 resource init，3.2 的抽取差集在那之後才執行。
- [`Tab(LocalizedStringResource)` 的標籤在不重開 App 切換語言時是否即時更新沒有文件保證] → 4.3 實測根分頁列與側邊欄，不成立時回報使用者。
- [列舉 `title` 改型別牽動跨功能的呼叫端] → 每個列舉與全部呼叫端放在同一任務，任務間檔案重疊以 `[after:]` 串接。

## Open Questions

- 1.1、1.2 試做若失敗，替代方案 (保留 `localizedBundle` 查表、或對帶參數 key 維持 manual) 由使用者決定。
