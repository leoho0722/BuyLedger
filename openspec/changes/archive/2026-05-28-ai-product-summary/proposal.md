## Why

訂單列表累積大量訂單與商品明細後，使用者難以快速掌握「目前這批訂單賣了什麼、哪些品項熱門、數量金額分佈」。本變更在訂單列表提供一鍵 AI 總結，依目前篩選後列表的商品明細呼叫 Ollama Cloud streaming API，即時串流出一份正體中文 Markdown 摘要，降低人工彙整成本。

## What Changes

- 訂單列表新增「AI 總結」工具列按鈕 (sparkles)，三平台 (iOS/iPadOS/macOS) 並列於既有「新增」按鈕旁；列表為空時停用。
- 點擊按鈕時先檢查設定開關 `useAiSummary`：
  - 開啟 → 以 sheet (樣式比照新增付款方式 sheet) 呼叫 Ollama Cloud streaming API，逐段串流渲染具 Markdown highlight 的總結。
  - 關閉 → 顯示兩按鈕提示 alert：左「關閉」、右「前往開啟」；右鈕深連結到設定頁 (iOS/iPadOS 切到「更多」分頁並 push 設定頁；macOS 開啟標準偏好設定視窗)。
- 訂單列表新增「商品類別」篩選器，與既有狀態/日期/搜尋篩選並列；AI 總結一律涵蓋目前篩選後列表的商品明細，選定某類別時列表與總結同步收斂到該類別。
- 設定頁新增 `useAiSummary` 開關與 `aiSummaryModel` 模型名 (預設 `gemma4:31b-cloud`)；模型名持久化，僅 Debug build 提供 sheet 可於執行期更換模型，Release build 固定預設值。
- 新增 Ollama Cloud streaming 串接：以新的依賴 client 透過 NDJSON 逐行串流，累加 `message.content` 直到 `done`。
- 引入 Markdown 渲染：新增 SPM 套件 Textual (`https://github.com/gonzalezreal/textual`) 渲染串流中的 Markdown 字串。
- 新增外部 API 金鑰 `OLLAMA_API_KEY`，比照既有 `EXCHANGE_RATE_API_KEY` 的 xcconfig → Info.plist → APIKeyProvider 注入鏈。

## Non-Goals

- 不做離線/本機 LLM 推論；僅串接 Ollama Cloud。
- 不在 Release build 提供模型切換 UI；Release 固定使用預設模型。
- 不對訂單金額、毛利或匯率做 AI 分析；總結範圍限於商品明細 (品項名稱、數量、單價、幣別、類別)。
- 不新增聊天式多輪對話；單次請求、單次總結，僅提供重試。
- 不快取或持久化總結結果；每次開啟 sheet 重新串流。

## Capabilities

### New Capabilities

- `ai-order-summary`: 訂單列表的 AI 商品明細總結，含按鈕入口、`useAiSummary` 開關 gating、Ollama Cloud streaming sheet、未開啟時的提示 alert 與深連結至設定頁、設定頁的開關與模型設定 (含 Debug 模型切換)。
- `order-category-filter`: 訂單列表的商品類別篩選器，與既有狀態/日期/搜尋篩選並存，並界定 AI 總結的資料範圍。

### Modified Capabilities

(none)

## Impact

- Affected specs: 新增 `ai-order-summary`、`order-category-filter` 兩個 capability spec。
- Affected code:
  - New:
    - apps/apple/BuyLedger/Core/Networking/OllamaClient.swift
    - apps/apple/BuyLedger/Features/AISummary/AISummaryFeature.swift
    - apps/apple/BuyLedger/Features/AISummary/AISummaryView.swift
  - Modified:
    - apps/apple/BuyLedger/Core/Networking/APIKeyProvider.swift
    - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
    - apps/apple/BuyLedger/Features/Orders/OrdersView.swift
    - apps/apple/BuyLedger/Features/Orders/OrdersCompactView.swift
    - apps/apple/BuyLedger/Features/Orders/OrdersMacView.swift
    - apps/apple/BuyLedger/Features/Settings/SettingsFeature.swift
    - apps/apple/BuyLedger/Features/Settings/SettingsView.swift
    - apps/apple/BuyLedger/Features/Settings/SettingsMacView.swift
    - apps/apple/BuyLedger/Features/App/RootFeature.swift
    - apps/apple/BuyLedger/Features/More/MoreView.swift
    - apps/apple/BuyLedger/Resources/Config.xcconfig
    - apps/apple/BuyLedger/Resources/Config.example.xcconfig
    - apps/apple/BuyLedger/Resources/Info.plist
    - apps/apple/BuyLedger.xcodeproj/project.pbxproj
  - Removed: (none)
- Dependencies: 新增 SPM 套件 Textual (gonzalezreal/textual)，連結至 app target；新增外部服務 Ollama Cloud (chat streaming) 與金鑰 OLLAMA_API_KEY。
- Platforms: iOS / iPadOS / macOS 三平台皆受影響 (深連結與模型切換有平台分流)。
