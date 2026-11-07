## Context

`apps/ios/BuyLedger/Resources/Localizable.xcstrings` 共 492 筆，開啟 Xcode 27.2 時 Issue Navigator 回報 99 筆警告 (2026-11-07 實測)。專案開啟 `SWIFT_EMIT_LOC_STRINGS` 與 `STRING_CATALOG_GENERATE_SYMBOLS`：Xcode IDE 建置後以編譯器抽出的 `.stringsdata` 同步 catalog，抽到但 catalog 沒有的字面值會被新增，catalog 有但抽不到的 key 會被標 stale；manual 條目會另外產生 `LocalizedStringResource` 符號 (`GeneratedStringSymbols_Localizable.swift`，2026-11-07 為 105 個，與 105 筆 manual 一致)。

2026-11-07 以 `mobilebuildmcp` 命令列建置 Debug 後，catalog 位元組不變，即使當時仍有 96 筆 stale 與 11 種多餘字串：命令列建置不會同步 catalog，只有 Xcode IDE 會。同日以 `-BLUITestLanguage english` 在系統語言 zh-Hant-TW 的模擬器上實測，開團詳情以 `Text(LocalizedStringResource)` 呈現的收款狀態讀到 `Received`／`Pending Payment`：`Text(resource)` 跟隨畫面環境的 `\.locale` (根畫面已套用 App 語言)，不跟隨系統語言。

分類與筆數見 proposal 的 Root Cause。既有守門：`LocalizationCatalogTests` 檢查程式字面值皆已收錄 (`#Preview` 區塊排除)、key 須符合四段點記號且至少 475 筆、不得有 `shouldTranslate: false` 條目、死碼 key 清單不得復活；目前沒有 stale 與百分比的檢查。

## Goals / Non-Goals

**Goals:**

- Xcode 對 `Localizable.xcstrings` 的警告歸零，且 Xcode IDE 建置後 catalog 內容不變。
- 第三類 32 筆中 Release 也會編譯的 26 筆改由編譯器抽取，恢復 Xcode 對這些 key 的使用追蹤；另 6 筆位於 `#if DEBUG`，改型別後仍標 manual。
- 百分比數字改由 `FormatStyle` 依 App 語言的 locale 產生，畫面文案與修改前逐字相同。
- 以單元測試守住「不得有 stale 條目」與「翻譯值不得寫死百分比數字」。

**Non-Goals:**

- 第一、二類 53 筆的型別遷移與 `AppLanguage` API 收斂 (另開 change)。
- `LookupKind` 的 `String` 屬性改型別 (屬第二類性質，隨後續 change 處理)。
- 既有 105 筆 manual 中已被手寫程式碼抽取的 24 筆 (排除生成符號來源計算) 改回自動管理：由後續 change 統一清理。
- 不改 key 名稱 (例外：本 change 改寫的兩筆百分比 key，見「百分比改由 FormatStyle 依 App 語言格式化」；其他截句式命名的 key 另開 change 盤點，使用者 2026-11-07 決定)、不處理 `InfoPlist.xcstrings` (0 筆警告)、不新增建置期比對工具或 CI 步驟。

## Decisions

### 第一、二類延後到後續 change

**Supersedes**: string-catalog-warning-cleanup / 不全面改用 LocalizedStringKey

原先以「`LocalizedStringKey` 會把 key 變成 `key %lld`、無法解析成 `String`、不能放進 State」為由主張第一、二類無論如何都需要 manual。審查指出換成 `LocalizedStringResource` 這些限制都不成立：`LocalizedStringResource("key", defaultValue: "\(count)")` 保留結構化 key 且被抽取 (repo 先例：`QuoteRateFeature.userMessage(for:)`、`OrdersPresentationFeature+Destination` 的刪除通知)，它是 Foundation 型別、SDK 宣告 `Equatable`／`Codable`／`Sendable`，State 已有先例 (`QuoteRateFeature.State.errorMessage`)。

使用者 2026-11-07 決定拆成兩個 change：本 change 只做第三類，第一、二類與 `AppLanguage` 收斂另開 change。本 change 對這 53 筆的 manual 標記是過渡狀態，後續 change 遷移後要移除。

### 非抽取路徑引用的 key 標為 manual

第一類 32 筆、第二類 21 筆、`orders.general.label.model` 與第三類中 `SettingsView` AI 模型選擇器的 6 筆 `settings.preference.*` (皆在 `#if DEBUG` 內，Release 抽不到；6.1 實測後由主對話更正、使用者 2026-11-07 同意)，以及改走 `AppLanguage.format` 的兩筆百分比 key (`quote.calculator.message.targetMarginLimitNotice`、`orders.edit.message.feeRateInputNotice`)，在 catalog 加上 `"extractionState" : "manual"`。Xcode 不會把 manual 條目標 stale，也不會在建置時改動它。

- 判斷「抽得到」只看手寫程式碼的 `.stringsdata`，排除 `GeneratedStringSymbols_*` 來源：生成符號檔會把所有 manual key 都抽一次，算進去會變成循環證據。
- 已被手寫程式碼抽取的既有 manual 不在本 change 處理，由後續 change 統一清理 (使用者 2026-11-07 決定)。
- 替代方案「Remove from catalog」：會刪掉仍在使用的翻譯，英文模式露出 key。

### 第三類元件參數改用 LocalizedStringResource

使用者 2026-11-07 決定第三類 32 筆在本 change 改型別。選 `LocalizedStringResource` 而非 `LocalizedStringKey`：它是 Foundation 型別，可放進 `OrderCostBreakdown`、`InsightsCostSegment` 這類只 import Foundation 的模型；有公開 `.key` 可供識別值與測試；字面值呼叫端不用改 (它符合 `ExpressibleByStringLiteral`，字面值會被抽取)。

各元件的改法：

| 元件 | 改法 |
| --- | --- |
| `OptionPickerSheet` 與 `+Configuration` (`title`、`AddPrompt` 四欄、`ClearOption.title`、`EmptyState` 兩欄)、`OptionPickerList`、`OptionPickerAddSection`、`EmbeddedPaymentMethodEditor` | 全部改 resource 並一路傳遞，呈現直接 `Text(resource)`；選項、選取值、草稿與 `Labeling` 維持 `String` |
| `PaymentMethodEditorSheet` | `title`、`message`、`namePlaceholder`、`submitTitle` 與兩個 init 改 resource；`message` 改為可選，以 `nil` 表示沒有說明 (取代 `message.isEmpty`) |
| `BLTextField` | 標題改 `LocalizedStringResource`：9 個呼叫端中 7 個是字面值不用改，另 2 個 (`PaymentMethodEditorSheet`、`LookupNameEditorSheet`) 改傳 resource；不新增並存的同位置 overload，避免字面值呼叫產生歧義 |
| `LookupNameEditorSheet` | `message` 改可選 resource、`namePlaceholder` 改 resource；`title`、`submitTitle` 維持現行型別 |
| `LookupManagementPresentations` | `LookupKind` 的 `String` key 在畫面邊界以 `LocalizedStringResource(String.LocalizationValue(kind.x))` 轉換，這些 key 維持 manual (使用者決策 3a)；只用於已知是 catalog key 的值，不包裝使用者名稱 |
| `OrderCostBreakdown.Component.title`、`InsightsCostSegment.label` | 改 resource；`id` 改回傳 `.key` (resource 未宣告 `Hashable`，不能直接當識別值)；`OrderDetailCostView` 與 `InsightsCostStructureCard` 的圖例用 `Text(resource)`；圈狀圖的 `DonutSlice`／`CostSlice` 維持 `String` key，投影時取 `.key`，再由既有 `language.localizedString(forKey:)` 解析成無障礙需要的 `String` |
| `DashboardKPITile.label`、`LookupItemRow.classificationBadge(_:)`、`OrderDetailSummaryView.metric(_:value:)`、`OrderEditPercentField.title`、`OrderEditDecimalField.title` | 參數改 resource，呈現 `Text(resource)`；金額、格式化值與使用者資料維持 `String` |

改型別後，這些元件 `#Preview` 內傳入的中文示範文字 (例如 `OptionPickerSheet` 的「需要網路連線載入幣別清單，請稍後再試。」、`LookupNameEditorSheet` 的名稱提示) 會開始被抽取，一律改用語意相符的既有 key；沒有對應 key 時以 `LocalizedStringResource(String.LocalizationValue(常數))` 建構 (非字面值不被抽取)。

### 已被抽取的 stale 條目清除標記

移除 `extractionState` 的條目：第三類中 Release 也會編譯的 26 筆。

只在 `#Preview` 引用的 10 筆 (`campaigns.general.label.deleteData`、`common.ui.label.disabled`、`common.ui.label.primaryAction`、`common.ui.label.raisedCardShadow`、`common.ui.label.secondaryAction`、`common.ui.label.spendingMonth`、`common.ui.label.standardCardShadow`、`common.ui.label.textAction`、`fx.rates.message.exchangeRatesLoaded`、`orders.list.message.tryAnotherSearch`) 改為刪除：6.1 實測 Xcode IDE 建置後，即使編譯器的 `.stringsdata` (含 IDE 自己的 DerivedData) 抽得到這些字面值，catalog 同步仍把只在預覽引用的 key 標 stale；原先「預覽內的字面值視為有效引用、stale 是舊同步結果」的推論不成立。使用者 2026-11-07 決定比照決策 2a：預覽改 verbatim (或語意相符的 production key：`FxView` 預覽改用 `fx.rates.message.networkErrorOccurred`)，10 筆加入死碼守門清單。

### 無正式引用的 key 刪除並列入死碼守門

刪除 `common.action.confirm`、`orders.edit.button.saveAndContinue`、`orders.list.label.date`、`common.general.label.workspace`，以及只供 `BLCard` 預覽的 `common.ui.label.eightLowerThan` (使用者決策 2a，預覽改 `Text(verbatim: "較上月減少 8%")`)。`LocalizationCatalogAppLanguageTests` 的 `LocalizedKeyExample.examples` 把 `common.action.confirm` 換成 `common.action.button.done` (`Done`／`完成`)、`orders.edit.button.saveAndContinue` 換成 `common.action.button.retry` (`Retry`／`重試`)。五筆加入 `prunedDeadKeys_歷史廢棄與重複通用Key_不得存在於目錄` 的清單。連同上一節的 10 筆預覽 key，刪除後共 477 筆，高於結構化 key 下限 475。

最終筆數 (6.1 以 Debug 與 Release 的 `.stringsdata` 確認)：manual 167 (既有 105＋第一類 32＋第二類 21＋`orders.general.label.model`＋第三類中 `#if DEBUG` 的 6 筆＋兩筆百分比)、無 `extractionState` 310、stale 0、合計 477。

### 百分比改由 FormatStyle 依 App 語言格式化

兩筆字串的翻譯值改成格式字串，數字以 `FormatStyle` 搭配 `@Environment(\.locale)` 格式化後，經 `AppLanguage.format(_:_:locale:)` 帶入，`Text` 以 `String` (verbatim) 呈現，與 `InsightsHeatmapCard` 既有寫法一致：

| key | zh-Hant | en | 參數 |
| --- | --- | --- | --- |
| `quote.calculator.message.targetMarginLimitNotice` | `目標毛利需低於 %@ 才能計算建議售價。` | `The target margin must be below %@ to calculate a suggested price.` | 1 的百分比 |
| `orders.edit.message.feeRateInputNotice` | `輸入百分比例如 %1$@ 表示 %2$@；超出 %3$@ ~ %4$@ 範圍會自動限制。` | `Enter %1$@ for %2$@. Values outside %3$@ ~ %4$@ are automatically limited.` | 1.5 的數字、0.015、0、1 的百分比 |

- 改名：兩筆原名 `quote.calculator.message.targetMarginMust`、`orders.edit.message.enter1515` 是早期遷移時截取原句產生的名稱，數字移出翻譯值後更不描述用途，改為 `quote.calculator.message.targetMarginLimitNotice`、`orders.edit.message.feeRateInputNotice`，`QuoteFormatters` 的函式同步命名為 `targetMarginLimitMessage(locale:)` (使用者 2026-11-07 決定)。
- 精度：百分比用 `.percent.precision(.fractionLength(0...1))`，`0`、`1`、`0.015` 分別產生 `0%`、`100%`、`1.5%`；數字 1.5 用 `.number.precision(.fractionLength(0...1))`。不沿用 `BLFormatters.percent` (預設固定一位小數，會產生 `100.0%`)。
- 位置：新增 `QuoteFormatters` 的目標毛利上限提示函式與 `OrderFormatters` 的手續費輸入說明函式，皆接收 `locale: Locale`、回傳 `String`。這兩個新增的 `<Feature>Formatters` 靜態函式是使用者 2026-11-07 核准的個案例外 (決策 1a)：回傳的是完整句子，放在可單元測試的位置；數字本身仍以 `FormatStyle` 格式化。
- `QuoteStatusBanner` 與 `OrderEditFeesSection` 目前沒有 `@Environment(\.locale)`，要補上；`QuoteView` 已有。
- 替代方案 `Text("key \(value, format: .percent)")`：編譯器會抽出 `key %@` 這種帶空白的 key，違反結構化 key 守門。

### 消除建置後多餘抽取的寫法

原有 11 種多餘字串 (13 個位置)：

- 預覽示範文字 (`InsightsTrendCard`、`DashboardKPITile`、`FxStatusBanner`、`BLFilterChip`、`BLReadableContentLayout`、`BLReadableScrollContentLayout` 的 `#Preview`)：`Text` 改 `Text(verbatim:)`；參數型別是 `LocalizedStringKey` 時先存成 `String` 常數再以 `LocalizedStringKey(_:)` 包裝。
- `BLNumberField("")` 的空白標題 (`OrderEditPercentField`、`OrderEditDecimalField`、`OrderEditItemsSection`)：`BLNumberField` 新增不帶標題的初始化方式，內部以 `TextField(text:prompt:label:)` 搭配空的 label 建立，不寫 `TextField("", …)`，也不轉呼叫 `self.init("")`；保留 `Bool` 與列舉兩種焦點入口。
- `OrderEditFeature.State.campaignsDisplayText`：改成能區分「未歸團」與「已選開團名稱」兩種狀態的呈現資料，View 分別以 `Text("orders.detail.label.unassigned")` 與 `Text(verbatim:)` 顯示。不以開團名稱建構 `LocalizedStringResource`：名稱恰好等於某個 key 時會被翻譯 (既有測試 `campaignsDisplayText_英文開團名稱等於本地化鍵_保留原始名稱` 守住此情境)。
- `OrdersListQuery.navigationTitle(isSelecting:count:)` 以字面值組 `String.LocalizationValue.StringInterpolation` 被抽成 `orders.batch.message.selectedCount %lld`：先改以非字面值常數組 key 並檢查 `.stringsdata`；仍被抽取時，改為回傳 key 與筆數由 `AppLanguage.localizedString(forKey:_:)` 解析，`OrdersCompactView`、`OrdersRegularListColumn` 與相關測試同步調整。不在本 change 引入 resource 版的多選標題，避免與後續 change 重工。

### 新增 stale 與百分比守門測試

檢查邏輯寫成接受 catalog 字典的 static 純函式 (例如 `staleKeys(in:)`、`literalPercentageKeys(in:)`)，測試分兩層：以測試內自帶的合成字典驗證正反例 (不碰 repo 的 catalog)，再以讀取真實 catalog 的測試斷言結果為空。

- 百分比判定遞迴走訪所有 `stringUnit` 值 (含 `variations`、`substitutions`)，不沿用只讀 `other`／`one` 的既有 `stringValue` helper。
- 規則排除格式指定符：「數字後接 `%`，且該 `%` 不是格式指定符的開頭」才算違規。正例 (必須判違規)：`100%`、`1.5%`、`0% ~ 100%`、`8 %`；反例 (不得判違規)：`1 %1$@ = %2$@ TWD` (`fx.rates.label.conversionRate` 的現值)、`%1$lld 筆`、`%@`。
- 測試只能讀 catalog 檔案，無法得知編譯器抽取結果，manual 標記是否正確由建置驗收確認。

### 驗收以 Xcode IDE 建置與抽取差集比對

命令列建置不會同步 catalog，`git status` 也分不出本 change 預期的 catalog 修改與 Xcode 的改寫，因此驗收改為：

- 抽取差集：以 `mobilebuildmcp` 建置 Debug 與 Release，讀兩份 `.stringsdata` 的 `Localizable` 表，排除 `source` 為 `GeneratedStringSymbols_*` 的檔案，要求 (a) 抽出的 key 全部在 catalog 內、(b) catalog 內沒有 `extractionState` 的 key 在兩種建置都被抽出。
- IDE 建置：記錄 catalog 的 SHA-256 後在 Xcode IDE 建置 Debug，建置後雜湊不變、Issue Navigator 對該檔 0 筆警告；完成後以 `git status --short` 確認 `Package.resolved` 未被刪除。

### 平行分工

實作者依 2026-11-07 `hc ls` 結果由主對話代選：`claude-haiku-max-impl` 負責 catalog 文字編輯、預覽寫法與守門測試；`codex-impl` 負責百分比、數字欄位與成本／分析／小型元件的型別遷移；`claude-sonnet-xhigh-impl` 負責選擇器與編輯表單元件、開團名稱與多選標題。審查 (含逐檔逐條的 style 閘門) 依根目錄 `CLAUDE.md`，由開工時 `hc ls` 查到的審查用終端 (例如右側 Codex) 與主對話同步進行，沒有審查用終端時改派未參與實作的 agent：使用者 2026-11-07 決定，因 `claude-haiku-max-impl` 本身就是 `haiku-max-implementer`，參與實作後不能再當 style 閘門。

## Implementation Contract

**行為**

- 英文與正體中文模式下，報價計算「目標毛利過高」提示與訂單編輯手續費區塊說明的文案與修改前逐字相同 (見 spec Example)，百分比由 `FormatStyle` 產生。
- 第三類元件 (選擇器、付款方式與名稱編輯表單、成本明細、分析成本結構、KPI 卡、主檔分類標籤、數字欄位標題) 的文字與無障礙朗讀和修改前相同，在不重開 App 的情況下 zh-Hant → en → zh-Hant 切換即時更新。
- 開團名稱等於某個 key 時仍顯示原文。
- 開發者在 Xcode IDE 建置後，Issue Navigator 對 `Localizable.xcstrings` 的警告為 0，catalog 不被改寫。

**資料形狀**

- catalog：26 筆 stale 移除 `extractionState` (第三類)、56 筆 stale 改為 `"manual"` (第一類 28＋第二類 21＋`orders.general.label.model`＋第三類中 `#if DEBUG` 的 6 筆)、6 筆無狀態條目加上 `"manual"` (4 筆潛在＋兩筆百分比)、刪除 15 個條目 (5 筆無正式引用＋10 筆只在預覽引用)、改寫 2 筆翻譯值；manual 合計 167，其餘條目文字不變。編輯一律以文字層級的行內修改完成 (逐行改 `extractionState`、刪除整個條目區塊)，不以 JSON 解析後整檔重寫。
- 第三類元件的對外參數型別由 `String` 改為 `LocalizedStringResource` (`PaymentMethodEditorSheet`、`LookupNameEditorSheet` 的 `message` 為可選)；`BLTextField` 標題改 `LocalizedStringResource`；`OrderCostBreakdown.Component`、`InsightsCostSegment` 的 `id` 仍為原 key 字串。
- 新增 `QuoteFormatters`、`OrderFormatters` 各一個回傳 `String` 的函式；`BLNumberField` 新增不帶標題的初始化方式。

**失敗模式**

- manual key 少了翻譯時 `AppLanguage.localizedString` 回傳 key 本身，由既有 `LocalizationCatalogAppLanguageTests` 與 UI 實測涵蓋。
- 漏改任一第三類呼叫端或新增 key 時忘記處理抽取狀態，IDE 建置會標 stale 並改寫 catalog：抽取差集比對與 stale 守門測試會失敗。

**驗收**

- 抽取差集與 IDE 建置：見 Decisions「驗收以 Xcode IDE 建置與抽取差集比對」。
- 單元測試：全部跑 iPhone 17 iOS 26.5 模擬器 (淺色)，最後完整單元回歸；snapshot 不重錄。
- UI 測試：使用者 2026-11-07 同意不跑完整 UI 回歸，改跑受影響的類別 (iPhone 17 (iOS 26.5) 與 iPad Air 11-inch (M4) (iPadOS 27.0) 模擬器各一次)，並以 `mobilebuildmcp ui-automation` 做英文與正體中文實測，含不重開 App 的雙向語言切換。

**範圍**

- 範圍內：`Localizable.xcstrings`、兩筆百分比的呼叫端與 Formatters、第三類 32 筆所在元件與其下游、多餘抽取來源、`LocalizationCatalog` 守門測試、`.claude/rules/ios-accessibility-localization.md`。
- 範圍外：第一、二類遷移、`AppLanguage` API 收斂、`LookupKind` 改型別、既有 manual 的正規化、兩筆百分比 key 以外的 key 改名、`InfoPlist.xcstrings`。

## Risks / Trade-offs

- [manual 條目不會被 Xcode 標 stale，日後真的沒人用時無法自動發現] → 本 change 已把能抽取的第三類改回自動管理；第一、二類由後續 change 處理，期間刪除程式碼時以 key 全文搜尋確認。
- [`OptionPicker`、`PaymentMethodEditorSheet`、`LookupNameEditorSheet`、`BLTextField` 型別連動，分開改會中途編不過] → 放在同一個 task 由同一位實作者完成。
- [`LocalizedStringResource` 的相等比較包含 table 與 bundle，字面值建構與生成符號建構不相等] → 測試一律以 `.key` 比對 key 身分，翻譯文字另以 `AppLanguage` 解析驗證。
- [`OrdersListQuery` 改寫後多選標題可能退回顯示 key] → 既有 `navigationTitleKey_各選取狀態_依所選語言解析`、`localizedString_選取筆數_依單複數解析` 與 UI 實測多選標題。
- [預覽改 verbatim 後預覽不再跟隨語言] → 只影響開發者預覽。

## 實作與審查取捨

- 三個數字欄位 (`OrderEditPercentField`、`OrderEditDecimalField`、`OrderEditItemsSection` 的單價欄) 實作時曾加上 `.accessibilityLabel`，主對話移除：修改前以 `snapshot-ui` 實測，手續費與金額欄的無障礙標籤皆為空，契約要求與修改前相同。標籤為空是既有狀態，補標籤留給後續 change (主對話決定)。
- 參數化測試的案例型別原放在 `private extension` (等同 fileprivate) 而編譯失敗，主對話改放到 `// MARK: - Nested Types` 的 extension。
- 6.4 由 t17 (Codex，未參與實作) 唯讀審查並逐檔逐條做 style 閘門，主對話同步審查；依「改到的檔整檔對齊」修正本次新增與檔案既有的違規，以下例外不在本 change 處理：
  - `DashboardKPITile` 色點尺寸未用 `@ScaledMetric`、`InsightsCostStructureCard` 圖例列在輔助字級未改直排且色點尺寸寫死：修正會改變輔助字級的 snapshot 基準圖，與本 change 不重錄的契約衝突；使用者 2026-11-07 決定延後。
  - `OptionPickerSheet.Addition` 的 case 第一個 associated value 沒有 label：修正會波及 `SettingsView`、`OrderEditPickerDestination` 並連帶整檔對齊；使用者 2026-11-07 決定延後。
  - `OptionPickerSheet+Configuration.swift` 以跨檔 extension 放巢狀型別：沿用使用者 2026-10-17 的裁決 (View 需要拆檔時先把巢狀型別拆到 `+Configuration`)，不視為違規。
  - `BLButtonStyle` 的 `reduceMotion` 不改成 `is` 開頭：`AccessibilityConventionScanTests` 以這個識別字辨識 `.animation(` 是否已處理減少動態效果，改名會讓守門失效 (主對話決定)。
  - `OptionPickerSheet` 兩個含 `clear:` 的 `.single(selected:onSelect:clear:)` 預覽維持括號內 closure：`onSelect` 不是最後一個參數，trailing closure 規則不適用 (主對話判斷)。
- `OrderEditFeatureCampaignsTests` 的 `campaignsDisplayText_英文開團名稱等於本地化鍵_保留原始名稱` 只驗證資料層帶原文，畫面以 `Text(verbatim:)` 顯示由 6.3 的 UI 實測確認；名稱沿用 task 4.1 指定的測試名 (主對話決定)。

## Open Questions

- `OrdersListQuery` 以非字面值常數組 key 是否仍會被編譯器常數折疊抽出：實作時以 Release 建置的 `.stringsdata` 確認，結果決定採用 Decisions 中的哪一種寫法，並記錄於此。
  - 結論 (2026-11-07 實測)：採第一種寫法。key 改由 `private static let selectedCountKey` 傳給 `appendLiteral` 後，Debug 與 Release 的 `OrdersListQuery.stringsdata` 都只剩 `common.action.label.all`、`orders.edit.label.selectOrders`、`orders.list.title`，不再抽出 `orders.batch.message.selectedCount %lld`，回傳型別不變，不需要退路。

## 驗收結果 (2026-11-07 至 11-08)

- 抽取差集 (Debug 與 Release 的 `.stringsdata`，排除生成符號來源)：抽出 366／358 個 key 全在 catalog 內；catalog 477 筆 (manual 167、無狀態 310、stale 0)，無狀態的 key 兩種建置都被抽出。
- Xcode IDE 建置 Debug：catalog SHA-256 建置前後同為 `16f3cc82…1a9e`；Issue Navigator 顯示 No Issues；`Package.resolved` 未被刪除。
- 單元測試 (iPhone 17、iOS 26.5、淺色)：完整回歸 2004 通過、0 失敗，snapshot 未重錄。變異檢查：catalog 加一筆 stale 與寫死的 `100%`、兩個 Formatter 精度改固定一位後，stale 守門、百分比守門與兩個 Formatter 測試都轉紅，還原後雜湊一致。
- UI 測試：iPhone 17 受影響 12 類 83 條全數通過；iPad Air 11-inch (M4) 先單跑 `KeyboardDismissTests` 2 條通過，其餘 81 條 76 通過、4 條為設計上的 skip (3 條只適用窄版、1 條 iPad 數字 Popover)、1 條 (`testFocusCardlessDeduction_超過實付金額_保留輸入並提示調整`) 超過 10 分鐘時限且無斷言失敗，單獨重跑通過，依 iPad 閒置等待雜訊判讀。
- 語言實測 (iPad、系統語言 zh-Hant-TW，`ui-automation`)：正體中文 → 英文 → 正體中文不重開 App，KPI 卡標題、成本明細圖例與圈狀圖無障礙描述 (英文為 `Donut chart, 2 categories…highest share is Item Cost…`)、多選標題 (`已選 1 筆`、`1 Selected`、`2 Selected`)、手續費說明、類別新增提示、付款方式編輯表單、主檔分類標籤與新增說明皆隨語言即時更新，使用者資料維持原文；選擇器空狀態以 `empty` 情境分別以兩種語言確認。報價目標毛利提示以暫時 XCUITest 確認兩種語言逐字相符 (主畫面與狀態橫幅各一次)，測試量完即刪。
- 數字欄位無障礙標籤：修改前 (以修改前建置的 App 實測) 與修改後的手續費率、金額、商品單價欄標籤皆為空。

- verify／review 後續 (task 6.6，使用者 2026-11-08 決定)：新增 catalog 規格範例測試；四處百分比格式收成 `Core/Formatters/PercentUpToOneFractionDigitFormatStyle` (依 `ios-design-system.md`「單一來源」)；`OrderFormatters.feePercentInputMessage` 改名 `feeRateInputMessage` 與 key 對齊；`SnapshotOrderEditSectionsTests` 新增英文開團列兩張基準圖 (未歸團顯示 `Unassigned`、名稱等於 key 時顯示原文)，目視確認後錄製。變異檢查：FormatStyle 精度改固定一位、revenue 條目暫標 manual 後，新增的四組測試都轉紅，還原後雜湊一致。
- `PercentUpToOneFractionDigitFormatStyle` 不依 ios-dev-kit FormatStyle 樣板給 `Locale` 預設值、也不測預設 locale：專案規定 production 不讀 `Locale.current`，預設值只能寫死某個地區，漏傳 App 語言時會靜默顯示錯誤語言；改為強制注入，漏傳即編譯失敗，測試以 `AppLanguage` 的兩種語言驗證 (使用者 2026-11-08 核准為 kit 個案例外)。
