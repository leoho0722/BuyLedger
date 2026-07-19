## 1. 語言偏好與設定資料流

- [x] 1.1 實作「AppLanguage 偏好沿用設定資料流」與 Language preference persistence：AppLanguage、SettingsFeature.State、SettingsSnapshot、SettingsStorage 讓缺值或未知 raw value 回退正體中文，並以 SettingsFeatureTests 的預設、binding save、task restore 測試驗證
- [x] 1.2 在 SettingsView 加入與外觀 Picker 同型的語言 Picker，交付 Language selection in Settings 的「正體中文／English」即時選擇行為，並以 SwiftUI code review 與 SettingsFeatureTests 驗證 binding 不重置其他 state

## 2. 根層語系套用

- [x] 2.1 實作「RootView 以 environment locale 即時套用」與 Locale-aware presentation follows App language：根 layout 根據 AppLanguage 注入 Locale，既有 presentation path 不再呼叫 Locale.preferred() 繞過偏好；以 source search、unit tests 與 simulator build 驗證
- [x] 2.2 實作「App 啟動載入持久化設定」：RootFeature.task 在使用者進入 Settings 前載入 SettingsSnapshot，保留現有 refresh effect；以 RootFeatureTests 驗證啟動 action flow 與已儲存英文的 root state

## 3. String Catalog 完整本地化

- [x] 3.1 實作「String Catalog 涵蓋完整使用者可見介面」與 Supported App languages：建立 zh-Hant sourceLanguage 的 Localizable.xcstrings，讓所有 shipped static UI key 同時具有非空 zh-Hant 與 en 值，並以 catalog JSON validator 與 Swift source 靜態掃描驗證沒有缺少英文翻譯或未 catalog 化字串
- [x] 3.2 更新 Xcode localization metadata 與由程式組成的顯示字串，使正體中文為預設且 English build 可載入 catalog；以 xcodebuildmcp CLI iPhone 與 iPad simulator build、SwiftUI review 驗證

## 4. 驗收

- [x] 4.1 執行 SettingsFeatureTests、RootFeatureTests、flutter analyze 以外的 iOS analyze、spectra analyze 與 spectra validate，確認 Implementation Contract 的測試與規格檢查全部通過
- [x] 4.2 完成 Device acceptance：用 xcodebuildmcp CLI 對連線的 iPhone 15 Plus 執行 device build-and-run，確認 App 已安裝並在裝置上啟動，且設定頁可觀察正體中文與英文切換

## 5. English 全頁面 runtime 覆蓋驗證與實機回歸

- [x] 5.1 以 TDD 強化「Supported App languages」與「English mode has no shipped static Chinese residue」的 catalog contract：先讓 LocalizationCatalogTests 對 Chinese source key 的錯誤同值 en translation 與已知漏翻 key 產生 RED，再加入只涵蓋品牌、格式符號與不可翻譯值的明確 allowlist，使 validator 能阻止非空但仍為中文的 English catalog 回歸
- [x] 5.2 實作「English 全頁面 runtime 覆蓋驗證」修正：盤點總覽、訂單、開團、分析、更多、設定與所有可到達子頁面的 SwiftUI literals、程式組合 display strings 及 locale-aware 日期／格式化器，修正 Localizable.xcstrings 與 presentation boundaries，確保 English 模式無 shipped static 中文且 user/external data 不被翻譯；以 iPhone simulator runtime traversal、iPad sidebar 抽查與 targeted tests 驗證
- [x] 5.3 完成全頁面實機回歸：執行完整 iOS tests、Xcode analyze、spectra analyze/validate，並用 xcodebuildmcp CLI 對 iPhone 15 Plus build-and-run 後巡覽所有主要分頁與可到達子頁面，確認 English 截圖沒有 shipped static 中文、日期採 English locale，切回正體中文後全頁恢復中文

## 6. 訂單流程回報漏翻修正

- [x] 6.1 以 TDD 擴充「English 全頁面 runtime 覆蓋驗證」的 LocalizationCatalogTests：先對 More、幣別／AI 模型、收款／到貨進度、來源／類別／付款方式選擇器及其新增說明建立缺翻 RED keys，再確認英文翻譯不含 CJK 且使用者資料不在靜態翻譯範圍內
- [x] 6.2 實作「訂單流程的具名覆蓋矩陣」：修正 More、Lookup 選擇器、訂單新增／編輯與詳情的 static SwiftUI presentation boundaries 和 Localizable.xcstrings，使 English 模式的控制項、欄位、進度與 helper text 全部為英文；以 6.1 tests、SwiftUI code review 與 simulator build 驗證
- [x] 6.3 完成「Reported order-flow controls use English consistently」runtime 回歸：以 English 狀態巡覽 More、所有回報選擇器及有資料訂單的新增／編輯／詳情頁，確認靜態文案均為英文且切回正體中文後恢復中文；以 iPhone simulator traversal、完整 iOS tests 和 spectra analyze/validate 驗證

## 7. 根分頁 navigation title 語系回歸修正

- [x] 7.1 以 TDD 擴充「Root navigation titles follow the selected App language」的 LocalizationCatalogTests：先對總覽、訂單、開團、分析、更多建立 root navigation title presentation boundary 的 RED 原始碼回歸檢查與兩種語言 catalog 斷言，證明 title 必須經 AppLanguage bundle 解析
- [x] 7.2 實作「根分頁 navigation title 跟隨選定 App 語言」：修正 DashboardView、OrdersCompactView／OrdersView、CampaignListView、InsightsView 與 MoreView 的 title presentation，讓正體中文與英文切換均立即使用正確 title；以 7.1 tests、SwiftUI navigation review、iPhone runtime traversal 及 spectra analyze/validate 驗證

## 8. 審查回饋修正

- [x] 8.1 以行為測試取代脆弱的根標題原始碼字面比對：保留 `AppLanguage.localized(_:)` 的雙語根標題斷言，新增 `OrdersFeature.State.navigationTitleKey` 三態雙語斷言，並只掃描傳給原生 `.navigationTitle` 的本地化字面，放行 `Text(verbatim:)` 與變數名稱；以 LocalizationCatalogTests 驗證
- [x] 8.2 實作「根分頁 navigation title 使用顯式 AppLanguage 參數解析」：刪除 `AppLanguageEnvironment.swift` 與 RootView 的自訂 environment 注入，新增 `rootNavigationTitle(_:language:)`，根分頁與 Settings 顯式傳入語言；Orders 的三態 title key 改為 State 計算屬性並由 RootTabLayout／RootSidebarLayout 傳遞語言；同步設計、proposal、tasks 與 iOS gotcha，並以 simulator build、LocalizationCatalogTests、SwiftUI review 與 spectra analyze/validate 驗證
