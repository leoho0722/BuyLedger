## Context

- 訂單清單的「AI 商品明細總結」由 `AISummaryFeature` 讀取金鑰、呼叫 `AISummaryService.streamSummary(prompt, model, apiKey)`，並以 30 秒整體上限與失敗訊息處理串流；Service 正式實作直接以 App 的 `HTTPClient.stream` 打 `https://ollama.com/api/chat`，自己解析 NDJSON。
- 模型名稱由設定頁保存在 `settings.aiSummaryModel`，預設值與 Debug 候選清單來自 `AISummaryModelCatalog` (Ollama 名稱)；Root 把開關與模型投影成 `OrderAISummarySettings` 給訂單容器，容器建立 `AISummaryFeature.State(prompt:model:)`。
- 金鑰 `OLLAMA_API_KEY` 由 xcconfig 注入 `Info.plist`，執行期經 `AppConfigurationStore` 讀取，以 `Authorization: Bearer` 送出。
- LKAIKit 0.1.0 (使用者自有套件，2026-11-24 發佈) 提供 `LKAIChatClientProtocol.stream(_:) -> LKAIChatStream`，事件為 `textDelta(String)` 與 `finished(LKAIChatCompletion)`，錯誤統一為 `LKAIError`；`LKAnthropicClient(apiKey:urlSession:refusalFallback:)` 固定打 `https://api.anthropic.com/v1/messages`、`anthropic-version: 2026-10-21`、金鑰放 `x-api-key` 標頭，一律以串流送出。`LKAIError`、`LKAIChatStreamEvent`、`LKAIFinishReason` 標示 `@nonexhaustive`，`switch` 必須寫 `@unknown default`。套件最低平台 iOS 26，與 App 相同。
- Claude Haiku 5.5 (`claude-haiku-5-5`) 預設開啟 adaptive thinking，thinking token 計入 `max_tokens`；沒有伺服器端拒答備援。LKAIKit 0.1.0 的 `LKAIChatRequest` 只有 `model`、`messages`、`systemPrompt`、`maxOutputTokens`，不能調整 thinking 或 effort。

## Goals / Non-Goals

**Goals:**

- AI 摘要改由 LKAIKit 的 Anthropic client 串流產生，預設模型 `claude-haiku-5-5`，畫面行為 (逐段顯示、30 秒上限、失敗與重試、關閉即取消) 不變。
- 「供應商」成為摘要流程與設定中的值：加入新供應商時，只需在 `AISummaryProvider` 加 case (編譯器會指出每個要補的對應) 並補上金鑰設定，畫面與 reducer 不必改。
- Ollama 時期儲存的模型名稱不會被送到新供應商。
- 金鑰仍只放在請求標頭，網址、log 與錯誤訊息不含金鑰。

**Non-Goals:**

- 不提供切換供應商的 UI (Debug 也沒有)；這次只有 `anthropic` 一個供應商，OpenAI／Gemini 雖然 LKAIKit 已支援也不接入。
- 不改摘要 prompt 內容、送出的欄位與第三方傳送揭露文字 (仍是第三方雲端服務)。
- 不新增系統指示、thinking 或 effort 設定 (LKAIKit 0.1.0 不支援)；不開啟拒答備援。
- 不新增依結束原因 (輸出長度上限、context 上限) 呈現的畫面訊息。
- 不改 `HTTPClient`、`APIError` 的定義與匯率服務。

## Decisions

### 以 Swift Package 釘選 LKAIKit 0.1.0，只連結 LKAIKit library product

`project.xcproj` 的 `packages` 新增 `https://github.com/leoho0722/LKAIKit` 精確版本 `0.1.0` (與現有套件同樣用精確版本)，只有 App target 連結 `LKAIKit` product：測試經 `@testable import BuyLedger` 與 stub `URLProtocol` 驗證行為，不直接使用 LKAIKit 型別 (第二輪審查後移除測試 target 的連結，以建置確認)；不連結 `lkai` 可執行檔。`Package.resolved` 由解析結果更新並提交。替代方案是以 `from: "0.1.0"` 範圍相依，但 0.x 版的次版號可能破壞 API，升級要另開 change。

### `AISummaryProvider` 是唯一的供應商清單，建立 client 的對應只在 Service

新增 `AISummaryProvider: String, CaseIterable, Sendable` (放 `Features/AISummary/Domain/`，不 import LKAIKit)：

- `case anthropic`，`static let default: Self = .anthropic`
- `apiKeyConfigurationKey` (`anthropic` → `ANTHROPIC_API_KEY`)
- `defaultModel` (`anthropic` → `claude-haiku-5-5`)
- `candidateModels` (`anthropic` → `claude-haiku-5-5`、`claude-sonnet-5-5`、`claude-opus-5-5`，第一個等於預設模型)

`AISummaryService` 的 `streamSummary` closure 內先宣告 `let client: any LKAIChatClientProtocol`，再以 `switch provider` 賦值 (`anthropic` → `LKAnthropicClient(apiKey:urlSession:)`，拒答備援維持 `.disabled`，因為 Haiku 5.5 沒有伺服器端備援)；不另寫建立 client 的 static 工廠 (ios-dev-kit 禁止正式程式碼以 static 成員建立或回傳 Client)。這是 App 唯一 import LKAIKit 的正式程式檔。`AISummaryModelCatalog` 刪除，引用改為 `AISummaryProvider`。替代方案是比照 LKAIKit CLI 的 `LKAIChatProvider` 把建立 client 放在 enum 上，但那會讓 Domain 依賴 LKAIKit。

### Service 介面帶供應商，Feature 只看 App 的錯誤類別

- `streamSummary: @Sendable (_ prompt: String, _ provider: AISummaryProvider, _ model: String, _ apiKey: String) -> AsyncThrowingStream<String, any Error>`
- `apiKey: @Sendable (_ provider: AISummaryProvider) -> String?`，讀 `AppConfigurationStore` 的 `provider.apiKeyConfigurationKey`
- `AISummaryFeature.State` 新增 `let provider: AISummaryProvider` (與 `model` 一起由建立者傳入)；缺金鑰時的 log 寫出缺少的設定名稱 (畫面訊息不變、不含設定名稱)。

正式實作送出 `LKAIChatRequest(model:messages: [LKAIMessage(role: .user, text: prompt)], maxOutputTokens: 16_000)` (沒有系統指示，與現在只送一則 user 訊息相同)，迭代 `client.stream(_:)`：`textDelta` 非空才交出，`finished` 時結束串流 (結束原因不是 `.completed` 時以 `AppLogger.inference` 記一筆 warning，只記原因)，`@unknown default` 略過；失敗時先以 `AppLogger.inference` 依錯誤種類記錄摘要再對應：連線失敗只記 `URLError` 的代碼，`invalidRequest`／`refused` 記種類加 private 細節 (拒答原因可能引用使用者內容)，其餘只記種類；不以 `String(describing:)` 攤平錯誤，因為 `URLError` 的 userInfo 含完整請求網址 (`apps/ios/CLAUDE.md` 禁止診斷輸出內插完整 URL)；取消不記。串流迭代所在的 `Task` 由 `onTermination` 取消，迭代被取消時 LKAIKit 正常結束，Service 也正常結束 (沿用現在「關閉 sheet 不算失敗」)。

### `LKAIError` 在 Service 內一次對應成 `APIError`

| `LKAIError` | 交給 Feature 的 `APIError` | 畫面訊息 (既有) |
| --- | --- | --- |
| `invalidAPIKey`、`permissionDenied` | `.invalidKey` | AI 服務驗證失敗 |
| `quotaExceeded` | `.quotaExceeded` | API 配額已用罄 |
| `rateLimited` | `.http(statusCode: 429)` | 伺服器回應錯誤 (429) |
| `serviceUnavailable(statusCode, _)` | `.http(statusCode:)` | 伺服器回應錯誤 (狀態碼) |
| `invalidRequest` | `.apiError(code: "invalid_request")` | 服務發生錯誤 (invalid_request) |
| `refused` | `.apiError(code: "refused")` | 服務發生錯誤 (refused) |
| `transport(underlying:)` | `.transport(underlying: urlError as NSError)` | 連線發生問題 |
| `invalidResponse` | `.decoding(underlying: error as NSError)` | 回應格式無法解析 |
| `cancelled` | 不丟錯誤，正常結束 | (無) |
| `@unknown default` | `.apiError(code: "unknown")` | 服務發生錯誤 (unknown) |

這維持現在的行為 (Ollama 的 401／403 是 `.invalidKey`、其他非 2xx 是 `.http`)，畫面、在地化字串與 `AISummaryFeature.summaryFailureMessage(for:)` 都不變；`URLError` 橋接成 `NSError`，符合 `network-error-handling` 對框架錯誤的規定。AI 摘要的 `APIError` 由 `AISummaryService` 產生、不經 `HTTPClient`；`.decoding` 的 underlying 是橋接後的 `LKAIError` (關聯值不保留，診斷內容靠上述 log)。對應以 `private static func apiError(from:)` (回傳 `nil` 代表取消) 實作：它和呼叫它的 `relay` 都在 `liveValue` 建立的 closure 內被呼叫，沒有能承載方法的實例，屬 ios-dev-kit `coding-style.md`「`static` 的使用時機」第 4 步「由框架要求的 `static` 成員或它建立的 closure 直接或間接呼叫、沿途沒有能承載這個方法的 `self`」(編譯實驗也確認 instance 方法報 `instance member 'relay' cannot be used on type 'AISummaryService'`)；依同一規範「不為測試放寬存取層級」維持 private，測試經 stub 串流驗證對應結果 (3.2 審查後使用者決定)。替代方案 (Feature 直接用 `LKAIError`、或新增 `AISummaryError` 與新的在地化訊息) 見 proposal。

### 輸出上限 16,000 token，實際上限仍由 30 秒整體時限決定

`max_tokens` 是 Anthropic 必填欄位；Haiku 5.5 的 thinking 會計入上限，設太低會在文字出現前就用完 (估計，依 claude-api 參考資料「串流不要壓低 `max_tokens`」)。摘要在 30 秒內就會被截斷，16,000 只作為單次成本上限 (估計最壞約 0.008 美元 = 16,000 × 0.5 美元／百萬 token)。是否在 30 秒內完成一般摘要尚未實測，由任務的實機或模擬器實呼叫驗證；結果寫入 tasks 紀錄。

### 供應商與模型成對保存，沒有供應商的舊模型改讀預設值

`SettingsSnapshot` 新增 `aiSummaryProvider: AISummaryProvider` (預設 `.default`)，`SettingsService` 以 `settings.aiSummaryProvider` 字串保存其 raw value，與 `settings.aiSummaryModel` 一起寫入。讀取規則：

- 讀得到且認得的供應商：用它；模型讀 `settings.aiSummaryModel`，空字串或沒有值時用該供應商的 `defaultModel`。
- 沒有供應商值 (Ollama 時期寫入) 或不認得的 raw value：供應商用 `.default`，**不讀**已存的模型，改用 `.default.defaultModel`。

儲存時模型等於該供應商的 `defaultModel` 就寫入空字串，讀取時跟隨供應商當下的預設模型：之後更換預設模型或供應商下架模型時，沒有明確選過模型的安裝不需要另寫遷移 (3.2 審查 t2q 建議，主對話採納)。

`SettingsFeature.State` 持有並回寫 `aiSummaryProvider` (沒有畫面控制項)，Debug 模型選單的候選改讀 `aiSummaryProvider.candidateModels`，自訂模型說明改為不提特定服務名稱。Root 把 `provider` 加進 `OrderAISummarySettings` 投影，訂單容器建立 `AISummaryFeature.State(prompt:provider:model:)`。替代方案 (依模型前綴判斷、不保存供應商) 見 proposal。

### 金鑰改名 `ANTHROPIC_API_KEY`，標頭規則改寫成「放在請求標頭」

xcconfig 範本與 `Info.plist` 改為 `ANTHROPIC_API_KEY`，`OLLAMA_API_KEY` 移除。Anthropic 用 `x-api-key` 標頭而非 `Authorization: Bearer`；`api-key-handling` spec 只要求「放在標頭、不進網址」，不需改，但 `.claude/rules/ios-integrations.md` 寫死 Bearer，要改成「金鑰一律放請求標頭 (匯率服務用 `Authorization: Bearer`，AI 摘要由 LKAIKit 依供應商放標頭)，網址不帶金鑰；新增供應商前確認它的 client 不把金鑰放進網址」。`URLSession` 由 `liveValue` 以 `@Dependency(\.urlSession)` 取得 (swift-dependencies 內建：正式為 `URLSession.shared`，測試預設值掛未實作的 `URLProtocol`，漏注入即失敗)；測試以 `withDependencies` 換成掛 stub `URLProtocol` 的 session，與其他 Service 測試同一個寫法 (3.2 審查 t2q／t2p 指出原先的 `live(urlSession:)` 是第二條建構路徑且違反 ios-dev-kit 的 static 規則，主對話採納改寫)。

### 沒有內容就結束或逾時的串流顯示失敗與重試

`AISummaryFeature` 收到 `streamFinished` 或 `streamTimedOut` 時，若 `summaryText` 去除空白與換行後為空，改為 `phase = .failed`、`errorMessage = "ai.summary.message.summaryFailedTry"`，畫面沿用既有失敗狀態與重試鈕，並以 `AppLogger.inference` 記一筆 warning 區分「結束」與「逾時」(不含內容)，方便分辨使用者回報的失敗原因；有內容時行為不變。30 秒上限是 `startStream` 內的區域常數 (只有該函式使用，依 ios-dev-kit 寫區域 `let`；Feature 本體只放 State／Action／Dependencies／Body)，測試以字面值 30 秒推進 `TestClock`。原本畫面只看文字是否為空，`.finished` 卻沒有文字時會一直顯示進度指示，違反「結束時停止進度指示」；Haiku 5.5 的 thinking 可能在 30 秒內還沒送出文字，讓這個情況更常見。改在 reducer 判斷，不改畫面與在地化字串 (3.2 審查 t2p 指出，主對話採納)。

## Implementation Contract

**行為**

- AI 摘要開啟時，訂單清單的 AI 摘要 sheet 以設定中的供應商與模型 (預設 `anthropic`／`claude-haiku-5-5`) 經 LKAIKit 串流，逐段顯示 Markdown；30 秒上限、取消、失敗訊息與重試行為與現在相同。
- 未設定 `ANTHROPIC_API_KEY` 時顯示既有的「AI 總結尚未完成設定」失敗狀態，不送出網路請求。
- 升級前存過設定的使用者 (有 `settings.aiSummaryModel`、沒有 `settings.aiSummaryProvider`)，讀到的供應商是 `anthropic`、模型是 `claude-haiku-5-5`；之後儲存設定時兩個 key 一起寫入，模型等於供應商預設時存空字串。
- 串流結束或逾時時若沒有收到任何內容 (去除空白後為空)，sheet 顯示既有的失敗狀態「總結失敗，請稍後再試。」與重試鈕，不停在進度指示 (3.2 審查 t2p 指出 Haiku 5.5 的 thinking 會讓這個既有缺陷更容易出現)。
- Debug 設定頁的模型選單列出 `claude-haiku-5-5`、`claude-sonnet-5-5`、`claude-opus-5-5` 與自訂選項；Release 沒有模型選單。

**介面與資料形狀**

- `AISummaryProvider` (cases、`default`、`apiKeyConfigurationKey`、`defaultModel`、`candidateModels`) 如 Decisions。
- `AISummaryService.streamSummary(prompt, provider, model, apiKey)`、`AISummaryService.apiKey(provider)`；`liveValue` 依賴 `\.urlSession` 與 `\.appConfigurationStore`。
- `AISummaryFeature.State(prompt:provider:model:)`、`OrderAISummarySettings(isEnabled:provider:model:)`、`SettingsSnapshot.aiSummaryProvider`、`SettingsFeature.State.aiSummaryProvider`。
- 儲存 key：`settings.aiSummaryProvider` (字串，raw value `anthropic`)；既有 key 不變。
- 送出的請求：`POST https://api.anthropic.com/v1/messages`，`x-api-key` 為金鑰，本文 `model` 為設定模型、`max_tokens` 為 16000、`messages` 只有一則 user 訊息內容為 prompt、`stream` 為 `true`；網址不含金鑰。

**失敗模式**：依 Decisions 的對應表；取消不是失敗；結束原因不是 `.completed` 時只記 log、照常完成。

**驗收**

- 單元測試：以 stub `URLProtocol` 經串流驗證錯誤對應 (狀態碼 400／401／402／403／429／500／529、拒答、缺結束事件、斷線)；驗證請求契約、SSE 文字依序交出並在 `message_stop` 結束、401 為 `.invalidKey`、500 為 `.http(statusCode: 500)`、`NSURLErrorDomain` 失敗為 `.transport`；`apiKey(.anthropic)` 讀 `ANTHROPIC_API_KEY`；`SettingsService` 的舊值重設與成對保存；Root 投影帶出供應商；`AISummaryFeature` 把 provider 與 model 傳給 Service。
- 完整單元測試在 iPhone 17 iOS 26.5 模擬器通過；受影響 UI 測試類別 (AI 摘要與設定頁) 在 iPhone 17 iOS 26.5 與 iPad Air 11-inch (M4) iOS 27.2 通過。
- 在 `apps/ios/BuyLedger` (`*.swift`、`Info.plist`、`Config.example.xcconfig`、`Localizable.xcstrings`)、`BuyLedgerTests`、`apps/ios/README.md`、`apps/ios/CLAUDE.md`、`.claude/rules/` 內搜尋 `ollama` (不分大小寫) 為 0 筆。
- 使用者提供 `ANTHROPIC_API_KEY` 後以實際 API 產生一次摘要並記錄是否在 30 秒內完成；未提供時在紀錄寫明未驗證。

**範圍**：包含上述 Service、Domain、設定、投影、測試替身、測試與文件；不含供應商切換 UI、其他供應商、prompt 調整、`openspec/changes/archive/`、`.archify/` 與 spec `@trace` 區塊中的 Ollama 字樣。

## Risks / Trade-offs

- [LKAIKit 0.1.0 剛發佈，尚無 App 端使用經驗] → 精確釘選版本；Service 測試以 stub `URLProtocol` 走過真實的 LKAIKit 串流與錯誤分類，不只測替身。
- [Haiku 5.5 預設 thinking，LKAIKit 0.1.0 無法調整，第一段文字前可能有延遲、30 秒內完成的比例未知] → 30 秒上限仍保留已收到內容並標示截斷；以實際呼叫量測，結果不理想時另開 change (需 LKAIKit 支援 effort)。
- [錯誤對應有損：`refused`、`invalidRequest` 以代碼字串呈現] → 與現在 `.apiError(code:)` 的呈現一致；之後要更友善的訊息時再新增在地化字串。
- [降級回舊版 App 時，Debug 選過非預設模型的安裝會把該模型名稱送給 Ollama] → 預設模型存空字串，一般安裝降級後回到舊版自己的預設；只影響開發者自有裝置，接受。
- [Firebase Performance 會記錄 `api.anthropic.com` 的請求網址] → 網址不含金鑰，標頭不被收集；行為與現在相同。

## Migration Plan

- 儲存格式：新增 `settings.aiSummaryProvider`；第一次讀取沒有此 key 時視為舊資料，模型改用預設值，不改寫儲存值，下一次儲存設定時才寫入兩個 key。
- 本機設定：開發者在 `apps/ios/BuyLedger/Resources/Config.xcconfig` 新增 `ANTHROPIC_API_KEY = <key>` 並刪除 `OLLAMA_API_KEY`，重新建置安裝後生效 (README 說明)。
- 回復：還原本 change 的 commit 即可；已寫入的 `settings.aiSummaryProvider` 會被舊版忽略。

## 審查後的後續事項

3.2 審查 (t2p、t2q) 中主對話決定不在本 change 處理、記錄待觸發的項目：

- `import LKAI` 只允許出現在 `AISummaryService.swift` 的掃描守門 (`LayerBoundaryScanner`)：加入第二個供應商時一併加入。
- 加入第二個供應商時：`MockChatURLProtocol` (以 `x-api-key` 索引) 與既有 `MockURLProtocol` 合併成可指定索引標頭的版本；`relay`／`apiError` 是 private、client 在 `streamSummary` closure 內建立，目前沒有注入事件替身的接縫，屆時把「依供應商建立 chat client」抽成以 `DependencyKey` 註冊的技術相依 (內含供應商 switch 與 `\.urlSession`)，測試注入回傳 `LKAIChatStream(_:)` 事件替身的工廠，仍經 `streamSummary` 驗證，不放寬存取層級。
- 加入供應商切換 UI 時：供應商與模型收成一個值型別；切換供應商時模型必須重設為新供應商的預設 (空字串語意下，沿用舊供應商的預設模型名稱會被當成明確選擇送給新供應商)。
- `Package.resolved` 因 LKAIKit 套件層宣告而多出 `swift-argument-parser` (只給它的 CLI，App 不連結)：其他相依要求較舊版本時會解析衝突，根治要在 LKAIKit 把 CLI 拆成獨立套件。
- archive 後 `app-settings` 主規格的 Purpose 仍只列「AI summary toggle and model」，手動補上 provider (delta 改不到 Purpose)。
- `APIError.decoding` 多了 `AISummaryService` 這個產生者 (underlying 是 LKAIKit 錯誤)：有人依 underlying 的 domain／code 診斷，或第二個 Feature 借用 `APIError` 時，補進 `network-error-handling` 或改走 `AISummaryError`。
- 要針對拒答、限流或輸出上限截斷給專屬訊息時，在 `AISummary/Domain` 建立 `AISummaryError` 並讓串流帶出結束原因，不在 Feature 比對 `"refused"` 等代碼字串。
- `HTTPClientProtocol.stream`／`bytes(for:)` 在正式程式已無呼叫端，另開 change 移除。
- `AISummaryView` 既有的 `.padding(.vertical, 7)`／`.padding(.horizontal, 14)` 原始值沒有對應的 `BLSpacing` token，改 token 會改外觀與 snapshot，待使用者裁定。
