## Context

BuyLedger 訂單列表 (OrdersFeature) 目前提供狀態、日期、搜尋三種篩選，每筆訂單 (LedgerOrder) 含 `items: [LedgerOrderItem]` (名稱、數量、單價) 與 `category: String`。專案以 TCA 管理狀態與副作用、依賴以 `@Dependency` 注入；外部 API 以「client struct + DependencyKey」封裝 (參考 ExchangeRateClient)，金鑰走 Config.xcconfig → Info.plist → APIKeyProvider。現有 `HTTPClient` 僅支援非串流 `data(for:)`，專案尚無任何 Markdown 渲染套件。設定頁 (SettingsFeature) 以 SettingsStorage 將偏好持久化到 UserDefaults。

本變更要在此基礎上加入 AI 商品明細總結 (串流) 與訂單列表的商品類別篩選器。

## Goals / Non-Goals

**Goals:**

- 訂單列表一鍵產生「目前篩選後列表商品明細」的串流式 Markdown 總結。
- 以設定開關 gate 功能；未開啟時以提示 alert 深連結到設定頁。
- 新增商品類別篩選器界定總結資料範圍，並與既有篩選並存。
- 模型可設定 (預設 `gemma4:31b-cloud`)，Debug build 可於執行期更換。
- 三平台 (iOS/iPadOS/macOS) 一致；以 TestStore 與純函式單元測試覆蓋核心邏輯。

**Non-Goals:**

- 不做本機/離線 LLM；僅串接 Ollama Cloud。
- 不分析金額/毛利/匯率；總結僅限商品明細欄位。
- 不做多輪對話、不快取總結結果。
- Release build 不提供模型切換 UI。

## Decisions

### 以 OllamaClient 依賴封裝 Ollama Cloud streaming

新增 `OllamaClient` (Sendable struct + DependencyKey)，核心為 `streamSummary: @Sendable (_ prompt: String, _ model: String, _ apiKey: String) -> AsyncThrowingStream<String, Error>`。liveValue 以 `URLSession.shared.bytes(for:)` 取得 NDJSON 串流，`for try await line in bytes.lines` 逐行解碼，累加 `message.content` 並 yield，遇 `done==true` 結束。

- 為何不擴充既有 HTTPClient：HTTPClient 抽象的是 `(Data, HTTPURLResponse)`，與逐位元組串流模型不同；硬塞會污染既有合約。改以獨立 client，可注入的 `streamSummary` closure 即測試縫。
- 為何用 type-based `@Dependency(OllamaClient.self)`：CLAUDE.md 規定新依賴用 type-based，不再加 DependencyValues keyPath (ExchangeRateClient 的 keyPath 為既有慣例，不沿用於新依賴)。
- 抽出純函式 `static func parse(line:) -> (content: String, done: Bool)?` 以便對 NDJSON 解析做直接單元測試 (壞行略過、`done:true`、partial content)。
- `continuation.onTermination` 取消內部 URLSession Task，確保 sheet 關閉時連帶取消網路。

### 以 Textual 套件渲染串流 Markdown

新增 SPM 套件 Textual (`https://github.com/gonzalezreal/textual`, upToNextMajor from 0.1.0)，連結至 app target；以 `StructuredText(markdown:)` (主題 `.gitHub`) 渲染。它吃純 markdown 字串，串流時重綁 `summaryText` 即重繪，天然支援漸進渲染。

- 為何不用 Foundation `AttributedString(markdown:)`：SwiftUI Text 僅渲染行內樣式 (粗體/斜體/連結)，不渲染標題與清單等區塊結構，無法滿足「Markdown highlight」。
- 動工前以 Context7 / Apple docs 對照確認 `StructuredText` API 拼法與 theme modifier，並確認 Textual 最低部署版本 ≤ 專案 min OS (高於即為 blocker，須回報使用者)。

### 以 AISummaryFeature 管理串流總結 sheet

新增 `AISummaryFeature` (TCA reducer) 與 `AISummaryView` (sheet)：

- State：`let prompt`、`let model`、`var summaryText`、`var phase` (`idle/streaming/finished/failed`)、`var errorMessage`。Action 全 `Equatable` (payload 皆 String)：`task`、`chunkReceived(String)`、`streamFinished`、`streamFailed(String)`、`retryTapped`、`closeTapped`。
- `task`/`retryTapped`：無金鑰 → `failed`；否則 `streaming` 並以 `.run` 迭代 `streamSummary`，每段 send `chunkReceived`，正常結束 send `streamFinished`，catch `CancellationError` 靜默、`APIError` 轉友善訊息。以 `.cancellable(id:cancelInFlight:true)`；`closeTapped` 合併 `.cancel` 與 `dismiss`。
- View：依 `phase` 顯示 ProgressView / `StructuredText(markdown:)` / 失敗態 (ContentUnavailableView + 重試)；NavigationStack + toolbar `.cancellationAction`「完成」；iOS `.presentationDetents([.medium,.large])`、macOS `.frame(minWidth:480,minHeight:520)` (比照 PaymentMethodEditorSheet)。

### 訂單列表新增商品類別篩選器

OrdersFeature.State 新增 `selectedCategory: String?` (nil=全部)，Action 新增 `categoryFilterSelected(String?)`，`filteredOrders(referenceDate:)` 加 `matchesCategory` 條件。選項清單重用既有 `availableCategories`。三平台依各自既有狀態/日期 chip 樣式新增一條類別 chip strip (用不同 tint 區隔)。AI 總結一律以 `filteredOrders` 為輸入，故選類別後總結自動收斂。

### AI 開關 gating 與未開啟提示 alert

OrdersFeature 新增 `@Dependency(SettingsStorage.self)`；`aiSummaryTapped` 時 `load()`：`useAiSummary==false` → 設 `aiDisabledAlert` (AlertState，左「關閉」cancel、右「前往開啟」action `.goToAISettings`)；否則以 `aiSummaryPrompt(referenceDate:)` 建 prompt 與 `snapshot.aiSummaryModel` 設 `aiSummary` presentation state。

- 沿用 AlertState (非 confirmationDialog)：與既有 `deletionConfirmation` 一致，跨 iOS 版本/平台位置穩定。
- prompt 由 State 上 `aiItemsDigest` (逐筆列品項：名稱/數量/單價+幣別/類別，並對品項數設上限避免 token 爆量) 與 `aiSummaryPrompt` (指示模型以正體中文 Markdown 總結、勿杜撰) 組成；屬可測試的 feature 層邏輯。

### 深連結到設定頁並做平台分流

RootFeature 攔截 `.orders(.aiDisabledAlert(.presented(.goToAISettings)))`：iOS/iPadOS 設 `selectedTab = .more` 並設 `showsSettingsFromDeepLink = true`；macOS 於 MainActor 呼叫 `NSApp.sendAction(Selector(("showSettingsWindow:")), ...)` 開啟標準偏好設定視窗。MoreView 的 iOS NavigationStack 加 `.navigationDestination(isPresented:)` (binding 綁 `showsSettingsFromDeepLink`，set 經新 action `setShowsSettingsFromDeepLink`) push SettingsView，保留既有手動 NavigationLink。

- 為何放 RootFeature：導覽 (切分頁 + push) 是 root 層責任，OrdersFeature 僅清自身 alert；沿用 root 攔截 child action 的既有模式。

### 設定頁新增 AI 開關與模型，Debug 才可換模型

SettingsFeature 的 State/init、SettingsSnapshot (含 `.default`/`.testDefault`)、SettingsStorage load/save、SettingsStorageKeys、`.task` load 與 `.binding` save 全數加入 `useAiSummary: Bool` (預設 false) 與 `aiSummaryModel: String` (預設 `gemma4:31b-cloud`)。SettingsView (iOS) 與 SettingsMacView (macOS) 加「啟用 AI 總結」Toggle；`#if DEBUG` 加「模型」列，開啟模型選擇 sheet (重用既有 OptionPickerSheet，`allowsAdd: true` 支援候選清單 + 自訂模型)。Release build 模型列與 sheet 編譯排除，模型固定預設值。

### 新增 OLLAMA_API_KEY 金鑰注入鏈

比照 EXCHANGE_RATE_API_KEY：Config.xcconfig (真實值，gitignored) 與 Config.example.xcconfig (空值) 加 `OLLAMA_API_KEY`；Info.plist 加 `OLLAMA_API_KEY = $(OLLAMA_API_KEY)`；APIKeyProvider 加 `ollamaAPIKey` closure (liveValue 從 Info.plist 讀並 trim、拒空與未替換的 `$(...)`；testValue 回 nil；previewValue 回 stub)。macOS network.client entitlement 已具備，不需變更。

## Implementation Contract

**Behavior:**

- 訂單列表三平台工具列出現「AI 總結」(sparkles) 按鈕；列表為空時停用。
- 點按鈕：`useAiSummary` 關 → 出現含「關閉 / 前往開啟」的 alert，點「前往開啟」導向設定頁 (iOS/iPadOS push 設定頁；macOS 開偏好設定視窗)。`useAiSummary` 開 → 開啟 sheet 並逐段顯示串流 Markdown，標題/清單/粗體正確渲染；結束顯示完整總結；錯誤顯示失敗態 + 重試；中途關閉 sheet 取消串流與網路。
- 商品類別篩選器選定某類別後，列表僅顯示該類別訂單，AI 總結內容亦限於該類別。
- 設定頁有「啟用 AI 總結」開關，狀態持久化；Debug build 可開 sheet 更換模型並即時生效，Release build 無此 UI。

**Interface / data shape:**

- `OllamaClient.streamSummary(_ prompt: String, _ model: String, _ apiKey: String) -> AsyncThrowingStream<String, Error>`，每段為增量 `message.content`。
- HTTP：`POST https://ollama.com/api/chat`，header `Authorization: Bearer <key>` 與 `Content-Type: application/json`，body `{"model","messages":[{"role":"user","content"}],"stream":true}`；回應 NDJSON，逐行含 `message.content` 與 `done`。
- `AISummaryFeature.State`(prompt, model, summaryText, phase, errorMessage)；`OrdersFeature.State` 新增 `selectedCategory`、`@Presents aiSummary`、`@Presents aiDisabledAlert`。
- 設定新增 `useAiSummary: Bool`、`aiSummaryModel: String`，UserDefaults keys `settings.useAiSummary`、`settings.aiSummaryModel`。

**Failure modes:**

- 缺 `OLLAMA_API_KEY` → 失敗態顯示「尚未設定 OLLAMA_API_KEY。」，不顯示假資料。
- HTTP 401/403 → `APIError.invalidKey`；其他非 2xx → `APIError.http`；連線錯誤 → `APIError.transport`；皆轉成失敗態友善訊息並提供重試。
- 取消 (關閉 sheet) → 靜默結束，不視為錯誤，且網路 Task 被取消。

**Acceptance criteria:**

- 單元測試：`OllamaClient.parse(line:)` NDJSON 解析；`AISummaryFeature` 以注入 stream 驗 streaming→finished 與錯誤→failed；`OrdersFeature` 驗 `categoryFilterSelected`/`filteredOrders` 收斂與 `aiSummaryTapped` on/off 兩分支；`RootFeature` 驗 goToAISettings 設 `selectedTab=.more`、`showsSettingsFromDeepLink=true` (`#if !os(macOS)`)；`SettingsFeature` 驗兩新欄位之預設、load、save。
- 建置：macOS + iOS Simulator build 通過 (序列化執行)。
- 手動：依 proposal 的開/關、串流、類別收斂、取消、Debug 換模型、錯誤態流程驗證。

**Scope boundaries:**

- In scope：上述 capability 範圍內的 UI、reducer、依賴、設定、金鑰、Textual 套件與測試。
- Out of scope：訂單金額/毛利/匯率分析、多輪對話、結果快取、Release 模型切換、本機 LLM、其他分頁的 AI 功能。

## Risks / Trade-offs

- [Textual 最低部署版本可能高於專案 min OS] → 動工前以 Context7 / get_platform_compatibility 確認；高於即停並回報使用者。
- [Textual API 拼法 (StructuredText / theme modifier) 與套件版本不符] → 以 Context7 對照安裝版本後再寫 view。
- [切 `.more` 分頁與 push 設定頁同一 pass 可能有一幀 race (類似既有 startNewOrder)] → 若實機 flaky 改為先切分頁、下一 runloop 再 push；列為實機驗證項。
- [串流未取消造成孤兒網路 Task] → 以 `.cancellable(cancelInFlight:)` + `.cancel`(closeTapped) + `continuation.onTermination` 三重保險；實機驗證關閉後無殘留。
- [Swift 6 Sendable] → `AsyncThrowingStream<String,Error>` 為 Sendable；`OllamaClient` (含 closure) 不得放入任何 Equatable/State 型別；`AISummaryFeature.Action` 維持 String payload。
- [篩選後品項過多導致 prompt 過大/成本高] → `aiItemsDigest` 設品項數上限或截斷註記。
- [macOS `showSettingsWindow:` 為 Ventura+ selector] → 確認 macOS 部署版本；於 MainActor 呼叫。
- [pbxproj 變更僅限 SPM 套件] → 其餘新增 .swift 檔位於 file-system-synchronized group，自動納入；Info.plist/xcconfig 變更不動 pbxproj。
