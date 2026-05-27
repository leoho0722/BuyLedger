## 1. 套件相依與金鑰基礎

- [x] 1.1 [P] 加入 Textual SPM 套件 (gonzalezreal/textual, upToNextMajor 0.1.0) 並連結至 app target，對應設計決策「以 Textual 套件渲染串流 Markdown」；先以 Context7 / get_platform_compatibility 確認其最低部署版本 ≤ 專案 min OS。行為：app target 可 `import Textual` 並使用 `StructuredText`。驗證：macOS 與 iOS Simulator build 通過；若部署版本高於 min OS 則停並回報使用者。
- [x] 1.2 [P] 新增外部金鑰 `OLLAMA_API_KEY` 注入鏈，對應設計決策「新增 OLLAMA_API_KEY 金鑰注入鏈」(Config.xcconfig、Config.example.xcconfig、Info.plist、APIKeyProvider.ollamaAPIKey)。行為：APIKeyProvider 能從 Info.plist 取得已注入的 key，未設定時回 nil 且不誤把 `$(OLLAMA_API_KEY)` 當成 key。驗證：新增 APIKeyProviderTests 斷言 trim/空值/未替換 token 皆回 nil，build 通過。

## 2. Ollama 串流依賴

- [x] 2.1 撰寫 OllamaClientTests 對純函式 `OllamaClient.parse(line:)` 驗 NDJSON 解析 (正常行取出 `message.content`、壞行回 nil 略過、`done:true` 標記結束)。行為：解析函式契約被測試固定。驗證：`OllamaClientTests` 通過。
- [x] 2.2 實作 `OllamaClient` (Sendable struct + DependencyKey + 純函式 `parse(line:)`)，對應設計決策「以 OllamaClient 依賴封裝 Ollama Cloud streaming」；liveValue 以 `URLSession.shared.bytes(for:)` 串流 NDJSON、累加 `message.content` yield 至 `done`，`onTermination` 取消網路 Task；testValue/previewValue 提供注入縫。行為：`streamSummary(prompt:model:apiKey:)` 回傳逐段增量文字的 `AsyncThrowingStream<String, Error>`，非 2xx/401/403/連線錯誤對應 `APIError`。驗證：2.1 測試通過且 build 通過 (型別以 `@Dependency(OllamaClient.self)` 取用)。

## 3. 設定欄位與持久化

- [x] 3.1 [P] 擴充 SettingsFeatureTests，涵蓋需求「AI summary setting and model configuration」：驗 `useAiSummary` (預設 false) 與 `aiSummaryModel` (預設 `gemma4:31b-cloud`) 的預設值、`.task` 載入與 `.binding` 寫回快照。行為：兩設定欄位之讀寫契約被測試固定。驗證：`SettingsFeatureTests` 通過。
- [x] 3.2 [P] 在 SettingsFeature.State/init、SettingsSnapshot (含 `.default`/`.testDefault`)、SettingsStorage load/save、SettingsStorageKeys 全數加入 `useAiSummary` 與 `aiSummaryModel`，對應設計決策「設定頁新增 AI 開關與模型，Debug 才可換模型」(資料層部分)。行為：兩欄位透過 UserDefaults 持久化並於啟動還原。驗證：3.1 測試通過。

## 4. AI 總結 feature 與 sheet

- [x] 4.1 撰寫 AISummaryFeatureTests：注入回傳 canned chunk 的 `OllamaClient.streamSummary` 與假金鑰，驗 streaming→finished 累加，與 `APIError.invalidKey`/transport→failed；涵蓋需求「Streaming Markdown summary sheet」與「Failure handling shows empty/error state without fake data」。行為：串流累加與失敗態轉換契約被固定。驗證：`AISummaryFeatureTests` 通過。
- [x] 4.2 實作 `AISummaryFeature` reducer，對應設計決策「以 AISummaryFeature 管理串流總結 sheet」：`task`/`retryTapped` 啟動串流並以 `.cancellable(cancelInFlight:)` 管理，`chunkReceived` 累加、`streamFinished`→finished、`streamFailed`→failed、`closeTapped` 取消並 dismiss；缺金鑰直接失敗態。行為滿足需求「Streaming Markdown summary sheet」與「Failure handling shows empty/error state without fake data」。驗證：4.1 測試通過。
- [x] 4.3 實作 `AISummaryView` sheet (NavigationStack + toolbar 完成鍵、iOS presentationDetents、macOS 固定 frame)，依 phase 以 `StructuredText(markdown:)` 漸進渲染、ProgressView 與失敗態 + 重試，滿足需求「Streaming Markdown summary sheet」的區塊式 Markdown 呈現。驗證：`#Preview` (以 OllamaClient.previewValue) 可見串流渲染；iOS build 通過。

## 5. 訂單商品類別篩選

- [x] 5.1 擴充 OrdersFeatureTests，涵蓋需求「Category filter on the orders list」與「Category filter combines with existing filters」：驗 `categoryFilterSelected` 設值並重算 `selectedOrderID`，且 `filteredOrders(referenceDate:)` 與狀態/日期/搜尋取交集 (注入固定 `\.date`)。行為：類別篩選與既有篩選之交集契約被固定。驗證：`OrdersFeatureTests` 通過。
- [x] 5.2 在 OrdersFeature 新增 `selectedCategory: String?` 與 `categoryFilterSelected(String?)`、擴充 `filteredOrders` 的 `matchesCategory` 條件，選項重用 `availableCategories`，對應設計決策「訂單列表新增商品類別篩選器」。行為滿足需求「Category filter combines with existing filters」。驗證：5.1 測試通過。
- [x] 5.3 在 OrdersCompactView、OrdersView (iPad listHeader)、OrdersMacView 各新增與既有狀態/日期同款的商品類別 chip strip (含「全部」選項、不同 tint)，滿足需求「Category filter on the orders list」的三平台呈現。驗證：三平台 build 通過，手動切換類別後列表收斂。

## 6. AI 入口、gating 與 sheet / alert 串接

- [x] 6.1 擴充 OrdersFeatureTests 驗 `aiSummaryTapped` 兩分支 (注入 SettingsStorage)：`useAiSummary` 開→設 `aiSummary` 且 prompt 非空、關→設 `aiDisabledAlert` 且不呼叫服務，涵蓋需求「AI summary entry point gated by setting」與「AI summary setting and model configuration」。行為：開關 gating 契約被固定。驗證：`OrdersFeatureTests` 通過。
- [x] 6.2 在 OrdersFeature 加入 `@Dependency(SettingsStorage.self)`、`aiSummaryTapped` 分支、`aiItemsDigest`/`aiSummaryPrompt` (品項名稱/數量/單價+幣別/類別、品項數設上限) 與 `@Presents aiSummary`/`aiDisabledAlert`，對應設計決策「AI 開關 gating 與未開啟提示 alert」；滿足需求「Summary input scope is the filtered list's product details」與「AI summary entry point gated by setting」。驗證：6.1 測試通過。
- [x] 6.3 在 OrdersView 外層掛 `aiSummary` sheet 與 `aiDisabledAlert`，並於三平台工具列既有「新增」旁加入 sparkles「AI 總結」按鈕 (列表為空時 disable)，滿足需求「AI summary entry point gated by setting」入口與「Streaming Markdown summary sheet」呈現。驗證：三平台 build 通過，手動點按鈕在開/關設定下分別出現 sheet/alert。

## 7. 深連結到設定頁

- [x] 7.1 擴充 RootFeatureTests (`#if !os(macOS)`) 驗送出 `.orders(.aiDisabledAlert(.presented(.goToAISettings)))` 後 `selectedTab == .more` 且 `showsSettingsFromDeepLink == true`，涵蓋需求「Disabled-state prompt alert with deep link to settings」。行為：iOS 深連結狀態轉換契約被固定。驗證：`RootFeatureTests` 通過。
- [x] 7.2 在 RootFeature 攔截 `goToAISettings` 並做平台分流 (iOS/iPadOS 設分頁+`showsSettingsFromDeepLink`；macOS 於 MainActor 呼叫 `showSettingsWindow:`)，並讓 MoreView 的 iOS NavigationStack 以 `.navigationDestination(isPresented:)` push SettingsView，對應設計決策「深連結到設定頁並做平台分流」，滿足需求「Disabled-state prompt alert with deep link to settings」。驗證：7.1 測試通過，實機點「前往開啟」導向設定頁。

## 8. 設定頁 UI

- [x] 8.1 在 SettingsView (iOS) 與 SettingsMacView (macOS) 加入「啟用 AI 總結」Toggle，並以 `#if DEBUG` 提供模型選擇 sheet (重用 OptionPickerSheet、候選清單 + 自訂模型)，對應設計決策「設定頁新增 AI 開關與模型，Debug 才可換模型」，滿足需求「AI summary setting and model configuration」(UI 部分：Debug 有切換、Release 無)。驗證：Debug build 可換模型並即時生效；Release build 無切換 UI；三平台 build 通過。

## 9. 整合與端到端驗證

- [x] 9.1 序列化建置 macOS 與 iOS Simulator (共用 build.db，`cmd1 && cmd2` 串接)，詳細錯誤加 `--log-level error`。行為：三平台皆可編譯與連結含 Textual 套件。驗證：兩平台 build 皆成功。
- [x] 9.2 執行 BuyLedgerTests (OllamaClient、AISummaryFeature、OrdersFeature、RootFeature、SettingsFeature 新增/擴充測試)。行為：全部單元測試綠燈。驗證：test 通過無 failure。
- [x] 9.3 實機端到端驗證 (liveValue 為空狀態，先建幾筆訂單)：開關關→alert→前往開啟導向設定頁；開→sheet 串流 Markdown 正確渲染；切類別後總結收斂；中途關閉 sheet 取消串流；Debug 換模型生效；缺金鑰/錯誤顯示失敗態不顯示假資料。驗證：六項流程逐一手動通過。
