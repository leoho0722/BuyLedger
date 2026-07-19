## Context

BuyLedger 的 SwiftUI 畫面目前大量以正體中文字串常值呈現，專案尚無 String Catalog。設定功能已用 TCA state 與 SettingsStorage 持久化介面外觀，RootView 也會根據該偏好套用 preferredColorScheme；語言切換可沿用相同資料流，但必須在根層套用 locale，並確保既有明確讀取系統語言的格式化程式改用 SwiftUI environment locale。

首次 iPhone 15 Plus 實機驗收顯示 English 模式仍有跨頁面中英混用：總覽／訂單的大標題、日期、篩選摘要與部分卡片欄位保留中文，但分頁、狀態與部分卡片標題已切成英文。這證明「catalog key 具非空 en value」不足以驗證 runtime 完整性；修正範圍必須涵蓋所有可到達頁面，而非只處理兩張回報截圖。

後續實機回報指出 More、Lookup 選擇器、訂單新增／編輯和訂單詳情仍有殘留：幣別與 AI 模型選擇器、收款／到貨進度、來源／類別／付款方式選擇與新增文字，以及訂單表單和詳情的靜態欄位。這些是既有「所有可到達頁面」契約的具體漏網路徑，必須以可回歸的 key 清單和 runtime traversal 補強。

## Goals / Non-Goals

**Goals:**

- 以 Localizable.xcstrings 提供完整的正體中文與英文 UI 字串，正體中文為 source language 與 App 預設語言
- 在設定頁以 Picker 切換語言，互動與介面模式 Picker 一致
- 將選擇寫入 SettingsStorage，重新啟動後恢復
- 切換後立即更新整個 App 的 SwiftUI 文案與 locale-aware 顯示，不要求重新啟動
- English 模式下所有可到達頁面的 shipped static UI 文案均為英文，不殘留正體中文；使用者輸入與外部資料維持原值
- 五個根分頁的 navigation title 在正體中文與英文模式下均立即呈現所選語言的翻譯
- 以 TestStore、catalog 完整性檢查、analyze、build 與 iPhone 15 Plus 實機執行驗收

**Non-Goals:**

- 不跟隨系統語言；未儲存偏好一律使用正體中文
- 不支援正體中文與英文以外的語言
- 不修改伺服器資料、使用者輸入內容、幣別 ISO code、模型名稱或品牌名稱
- 不以寫入 AppleLanguages 或重啟 App 的方式切換語言

## Decisions

### String Catalog 涵蓋完整使用者可見介面

新增 Localizable.xcstrings，以 zh-Hant 為 sourceLanguage 並為每個使用者可見 key 提供 en localization。現有 SwiftUI 可本地化字串常值保留為 source key，以降低大規模 view API 改寫風險；由程式組成或 enum 回傳的顯示字串改用 LocalizedStringResource 或 String(localized:) 進入 catalog。這比建立兩套 view 或散落語言分支更能維持單一 UI 結構，也符合 Xcode 原生擷取流程。

### AppLanguage 偏好沿用設定資料流

新增 AppLanguage enum，固定 traditionalChinese 與 english 兩個 case，提供 localeIdentifier 與可本地化 title。SettingsFeature.State、SettingsSnapshot、SettingsStorage 一併新增 language，UserDefaults key 使用 settings.language；無值或未知 raw value 均回退 traditionalChinese。這與 AppearancePreference 的 state → binding → persist 模式一致，且不需要新增第三方依賴。

### RootView 以 environment locale 即時套用

RootView 根據 store.settings.language 建立 Locale，對根 layout 套用 environment locale。語言 binding 改變時 SwiftUI 重新計算環境，所有 LocalizedStringKey、LocalizedStringResource 與 locale-aware FormatStyle 立即更新。現有 Locale.preferred() 呼叫改為讀取 environment locale 或由 caller 傳入，避免繞過 App 內偏好。

### App 啟動載入持久化設定

RootFeature 的啟動 task 同步觸發 SettingsFeature.task，讓使用者不必先進入設定頁即可恢復語言與外觀。設定頁再次出現時載入同一快照仍具冪等性。

### English 全頁面 runtime 覆蓋驗證

catalog validator 除了檢查值非空，還要辨識 shipped Chinese source key 是否被錯誤地以相同中文填入 en localization；對品牌、格式符號、使用者資料等刻意不翻譯內容維持明確 allowlist。UI presentation boundaries 必須區分 static display key 與 user/external data，靜態 key 透過 LocalizedStringKey、LocalizedStringResource 或帶 selected locale 的 String(localized:) 解析，日期與格式化器一律使用根層 environment locale。

驗收不能只抽查設定頁或單一畫面：需在 English 模式依序巡覽 iPhone 的總覽、訂單、開團、分析、更多、設定與其可到達子頁面，並抽查 iPad sidebar layout。每個頁面都要確認 navigation title、section header、button、picker、empty/error state、status、filter summary 與 locale-aware 日期／數字沒有 shipped static 中文殘留。這比只靠 source extraction 更能捕捉 runtime 文字建構與 locale 傳遞缺口。

### 訂單流程的具名覆蓋矩陣

LocalizationCatalogTests 必須鎖定本次回報的 source keys，包含「更多」、三個選擇器標題、收款／到貨進度與狀態、來源／類別／付款方式選擇器及其新增說明。訂單新增／編輯和詳情 View 的靜態 `Text`、`Label`、`TextField` placeholder 與 navigation title 必須由 String Catalog 解析；選取中的使用者資料、既有來源／類別／付款方式名稱仍以 verbatim 呈現。英文 runtime traversal 必須以有訂單資料的狀態開啟新增／編輯與詳情，確認欄位和進度文字均為英文，並在切回正體中文後恢復 source 文案。

### 根分頁 navigation title 使用顯式 AppLanguage 參數解析

iOS 18+ 的 `navigationTitle` 不會在執行期可靠地隨 SwiftUI `\.locale` 重新解析 String Catalog (FB16124687)。`AppLanguage.swift` 提供 `rootNavigationTitle(_:language:)`，呼叫端必須顯式傳入 `AppLanguage`，由選定的 `en.lproj` 或 `zh-Hant.lproj` bundle 先解析 title，再直接傳給原生 `.navigationTitle(_:)`。Dashboard、Campaigns、Insights 與 More 從 `store.settings.language` 傳值，Settings 從 `store.language` 傳值；OrdersView 與 OrdersCompactView 以儲存屬性接收 root layout 傳入的語言。`OrdersFeature.State.navigationTitleKey` 是由多選狀態衍生的計算屬性，涵蓋「訂單／選擇訂單／已選 N 筆」三態。RootView 保留 locale 注入給一般 SwiftUI 文案與格式化器，不注入自訂 EnvironmentKey。

## Implementation Contract

**Observable behavior**

- 第一次安裝或 UserDefaults 沒有有效 settings.language 時，App 全介面以正體中文呈現
- 「更多 → 設定」包含「語言」section 與「App 語言」Picker，選項為「正體中文」及「English」
- 使用者選擇 English 後，目前 navigation stack 不重置，畫面文字與 locale-aware 顯示立即改為英文；選回 Traditional Chinese 時立即恢復正體中文
- English 模式下，總覽、訂單、開團、分析、更多、設定及其可到達子頁面的 navigation title、section、control、status、filter、empty/error state 與日期／格式化文字全部以英文呈現
- English 模式下，More、來源幣別／預設幣別／AI 模型選擇器、收款／到貨進度、來源／類別／付款方式選擇器、訂單新增／編輯及詳情頁的 shipped static 文案全部以英文呈現
- 正體中文模式下，總覽、訂單、開團、分析與更多的 navigation title 全部以正體中文呈現；英文模式下，同五個 title 全部以英文呈現
- App 終止並重新啟動後仍使用上次選擇的語言
- 深淺色偏好既有行為保持不變

**Interface and data shape**

- AppLanguage 為 String-backed、CaseIterable、Identifiable、Sendable enum，raw values 為 traditionalChinese 與 english
- AppLanguage.localeIdentifier 分別回傳 zh-Hant 與 en
- SettingsSnapshot.language 與 SettingsFeature.State.language 承載選擇
- SettingsStorage 以 settings.language 儲存 raw value
- Localizable.xcstrings 的 sourceLanguage 為 zh-Hant；catalog 中每個 shipped key 具有 zh-Hant source value與 en translation

**Failure and fallback behavior**

- 缺少、空白或未識別的 settings.language 值安靜回退正體中文，不清除其他設定
- 外部資料或使用者輸入沒有翻譯時維持原值；UI 不顯示 translation key 或空白文案
- 任一 catalog key 缺少英文翻譯、Chinese source key 的 en value 仍為中文且不在明確 allowlist、或任一 runtime 頁面仍有 shipped static 中文，均視為驗收失敗

**Acceptance criteria**

- SettingsFeatureTests 驗證預設語言、binding 持久化、task 還原與無效值回退
- 靜態 catalog 檢查證明 sourceLanguage、兩種 localization 及 key 完整性
- English runtime traversal 覆蓋所有主要分頁與可到達子頁面；實機截圖不得出現 shipped static 中文，且日期使用 English locale
- LocalizationCatalogTests 對本次回報的具名 keys 驗證英文翻譯，並以有資料的訂單流程 runtime traversal 驗證新增／編輯和詳情 UI；使用者或外部提供的名稱維持原樣
- LocalizationCatalogTests 以原始碼回歸檢查鎖定根分頁與 Settings 的 navigation title 均由 `rootNavigationTitle(_:language:)` 呈現，並驗證其 catalog 英文翻譯
- LocalizationCatalogTests 直接驗證 `AppLanguage.english.localized("總覽") == "Overview"`、Orders 三態 key 的雙語解析，並僅掃描傳給原生 `.navigationTitle` 的本地化字面，放行 `Text(verbatim:)` 與變數名稱
- spectra analyze 與 spectra validate 無 Critical 或 Warning
- flutter 以外不相關平台不受影響；iOS 測試與 analyze 通過
- xcodebuildmcp CLI 對連線中的 iPhone 15 Plus 執行 device build-and-run 成功，裝置上可由設定頁切換並觀察英文與正體中文畫面

**Scope boundaries**

- In scope: iOS/iPadOS target 的靜態 UI 文案、設定持久化、SwiftUI locale environment、相關測試與 Xcode localization metadata
- Out of scope: 後端內容翻譯、使用者資料翻譯、新語言、系統 Settings App 的 per-app language 選項、App Store metadata

## Risks / Trade-offs

- [大量現有字串可能漏入 catalog] → 以 Swift source 掃描、catalog key/translation 驗證與英文實機畫面共同檢查
- [部分 helper 直接讀系統 locale 導致切換不完整] → 搜尋 Locale.preferred/current 並將顯示路徑改為 environment locale
- [啟動時先短暫顯示預設語言再恢復偏好] → RootFeature.task 於根畫面首次 task 載入；此單次非同步 state 更新不阻塞啟動，且 UserDefaults load 為同步
- [source-key 文案日後修改會形成新 key] → 本次以完整 catalog 鎖定；未來新增文案須同時補 zh-Hant 與 en
- [非空但錯誤的 en 值通過 validator] → validator 比對 Chinese source 與 en value，僅允許明確列出的不可翻譯 key 保持相同
- [單頁抽查漏掉其他頁面的 runtime 缺口] → 以 iPhone 全分頁／子頁 traversal 與 iPad sidebar 抽查作為封存前必要驗收
- [選擇器與有資料流程未被空狀態驗證覆蓋] → 將回報的 key 放入 catalog contract，並在有訂單資料時巡覽表單、詳情與所有選擇器
