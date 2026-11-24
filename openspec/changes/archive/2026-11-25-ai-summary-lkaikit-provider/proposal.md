## Summary

把訂單「AI 商品明細總結」的串流來源從 Ollama Cloud 換成 LKAIKit 0.1.0，供應商用 Anthropic、模型用 `claude-haiku-5-5`，並讓「供應商」成為設定與摘要流程中的一個值，之後加入其他供應商只需擴充一個型別與一處建立 client 的對應。

## Motivation

- 現在 `AISummaryService` 自己組 Ollama 的 NDJSON 請求、逐行解析回應 (`OllamaChatRequest`、`OllamaChatResponse`、`AISummaryService.parse(line:)`)，網址、金鑰名稱 (`OLLAMA_API_KEY`) 與模型目錄 (`gemma4:31b-cloud`) 都寫死為 Ollama；換供應商就要重寫整個 Service。
- 使用者新開發的 LKAIKit 已把 Anthropic、OpenAI、Gemini 收斂成同一個 `LKAIChatClientProtocol` 串流介面與 `LKAIError` 錯誤分類，App 不必再維護各家的傳輸格式。
- 使用者指定這次改用 Anthropic 的 Claude Haiku 5.5，並要求保留之後切換多個供應商的擴充性。
- 已儲存的模型名稱是 Ollama 的名稱：設定頁一旦儲存過，`settings.aiSummaryModel` 就存著 `gemma4:31b-cloud`，換供應商後若原樣送給 Anthropic 會一律失敗，因此需要定義舊值如何處理。

## Proposed Solution

- 以 Swift Package 加入 LKAIKit `0.1.0` (只連結 `LKAIKit` library product)，`AISummaryService` 的正式實作改為依供應商建立 `any LKAIChatClientProtocol` (這次只有 `LKAnthropicClient`)，把串流的文字片段交給既有的 `AISummaryFeature`，並把 `LKAIError` 對應成畫面已在使用的錯誤類別。
- 新增領域型別 `AISummaryProvider` (目前只有 `anthropic`)，集中「供應商 → 金鑰設定名稱、預設模型、Debug 候選模型」；取代 `AISummaryModelCatalog`。
- 設定新增「AI 摘要供應商」並與模型一起保存；沒有存過供應商的舊模型值 (Ollama 時期寫入) 不再使用，改讀目前供應商的預設模型。供應商與模型一起經 Root 投影到訂單容器與 AI 摘要畫面。
- 金鑰改為 `ANTHROPIC_API_KEY` (xcconfig → `Info.plist` → `AppConfigurationStore`)，由 LKAIKit 放進 `x-api-key` 標頭，網址不含金鑰。
- 刪除 Ollama 專屬型別與解析，同步 README、`CLAUDE.md`、`.claude/rules/ios-integrations.md` 與設定頁的自訂模型說明文字。

## Alternatives Considered

- **保留 App 自己的 HTTP 串流，只改成打 Anthropic Messages API**：可行但等於重做 LKAIKit 已完成且有測試的 SSE 解析與錯誤分類，之後每加一家又要再做一次，與使用者要求的多供應商擴充性相反。
- **直接把 `LKAIError` 交給 `AISummaryFeature`**：畫面層會依賴第三方套件的錯誤型別；改為在 Service 內一次對應成 App 既有的錯誤類別，畫面與既有在地化訊息不變。
- **不保存供應商、只用程式常數**：無法分辨已儲存的模型屬於哪個供應商，舊的 Ollama 模型名稱會被送給 Anthropic；之後加入供應商切換時也要再改一次儲存格式。
- **依模型名稱前綴 (如 `claude-`) 判斷舊值是否可用**：規則隨供應商命名而變，Debug 自訂模型也可能不符前綴，不採用。

## Impact

- Affected specs: `ai-order-summary`、`app-settings`
- Affected code:
  - Modified:
    - apps/ios/BuyLedger.xcodeproj/project.xcproj
    - apps/ios/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
    - apps/ios/BuyLedger/Resources/Info.plist
    - apps/ios/BuyLedger/Resources/Config.example.xcconfig
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings
    - apps/ios/BuyLedger/Features/AISummary/Data/AISummaryService.swift
    - apps/ios/BuyLedger/Features/AISummary/Presentation/Root/AISummaryFeature.swift
    - apps/ios/BuyLedger/Features/AISummary/Presentation/Root/AISummaryView.swift
    - apps/ios/BuyLedger/Features/Settings/Domain/SettingsSnapshot.swift
    - apps/ios/BuyLedger/Features/Settings/Data/SettingsService.swift
    - apps/ios/BuyLedger/Features/Settings/Presentation/Root/SettingsFeature.swift
    - apps/ios/BuyLedger/Features/Settings/Presentation/Root/SettingsView.swift
    - apps/ios/BuyLedger/Features/Orders/Domain/OrderAISummarySettings.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/Root/OrdersFeature.swift
    - apps/ios/BuyLedger/Features/Orders/Presentation/Root/Plans/OrdersContainerPlan+Requests.swift
    - apps/ios/BuyLedger/Features/App/Presentation/Root/RootFeature.swift
    - apps/ios/BuyLedger/App/Testing/TestDoubles/BLUITestStubs.swift
    - apps/ios/BuyLedgerTests/Features/AISummary/AISummaryServiceTests.swift
    - apps/ios/BuyLedgerTests/Features/AISummary/AISummaryServiceTransportTests.swift
    - apps/ios/BuyLedgerTests/Features/AISummary/AISummaryServiceTestSupport.swift
    - apps/ios/BuyLedgerTests/Features/AISummary/AISummaryFeatureTests.swift
    - apps/ios/BuyLedgerTests/Features/Settings/SettingsServiceTests.swift
    - apps/ios/BuyLedgerTests/Features/Settings/SettingsFeatureTests.swift
    - apps/ios/BuyLedgerTests/Features/Settings/SettingsFeatureAppLockTests.swift
    - apps/ios/BuyLedgerTests/Features/App/RootFeatureDeepLinksTests.swift
    - apps/ios/BuyLedgerTests/Features/App/RootFeatureAISummaryProjectionTests.swift
    - apps/ios/BuyLedgerTests/Features/More/MoreFeatureTests.swift
    - apps/ios/BuyLedgerTests/Features/More/MoreFeatureRelaysTests.swift
    - apps/ios/BuyLedgerTests/Features/Orders/OrdersContainerPlanCategoriesTests.swift
    - apps/ios/BuyLedgerTests/Features/Orders/OrdersContainerPlanRequestPresentationTests.swift
    - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureAISummaryProjectionTests.swift
    - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureFailureTimingTests.swift
    - apps/ios/BuyLedgerTests/Features/Orders/OrdersFeatureLoadAndSummaryTests.swift
    - apps/ios/BuyLedgerTests/SnapshotTests/SnapshotSharedTests.swift
    - apps/ios/BuyLedgerTests/SnapshotTests/__Snapshots__/SnapshotMoreTests/ (設定頁兩張基準圖，模型列改顯示 `claude-haiku-5-5`)
    - apps/ios/BuyLedgerTests/Core/Storage/AppConfigurationStoreTests.swift
    - apps/ios/README.md
    - apps/ios/CLAUDE.md
    - .claude/rules/ios-integrations.md
    - .claude/rules/ios-unit-tests.md
  - New:
    - apps/ios/BuyLedger/Features/AISummary/Domain/AISummaryProvider.swift
    - apps/ios/BuyLedgerTests/Mocks/MockChatURLProtocol.swift
  - Removed:
    - apps/ios/BuyLedger/Features/AISummary/Data/OllamaChatRequest.swift
    - apps/ios/BuyLedger/Features/AISummary/Data/OllamaChatResponse.swift
    - apps/ios/BuyLedger/Features/Settings/Domain/AISummaryModelCatalog.swift
